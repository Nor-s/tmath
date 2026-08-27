#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#include <thorvg.h>

#include "tmath.h"
#include "tmathDisplayList.h"
#include "tmathRendererBackend.h"
#include "tmathRendererData.h"
#include "tmathScene.h"
#include "tmathTvgRenderer.h"

namespace tmath
{

struct SwRenderer::Impl
{
    tvg::SwCanvas* canvas = nullptr;
    bool active = false;
    bool initialized = false;
    bool antialiasing = true;
};

SwRenderer::SwRenderer() noexcept
{
    pImpl = new (std::nothrow) Impl;
    if (!pImpl) return;
    pImpl->initialized = renderer::tvgInit();
    if (!pImpl->initialized) return;
    pImpl->canvas = tvg::SwCanvas::gen();
}

SwRenderer::~SwRenderer()
{
    auto initialized = pImpl && pImpl->initialized;
    if (pImpl) {
        if (pImpl->canvas && pImpl->active) pImpl->canvas->remove();
        delete pImpl->canvas;
    }
    delete pImpl;
    if (initialized) renderer::tvgTerm();
}

SwRenderer* SwRenderer::gen() noexcept
{
    auto renderer = new (std::nothrow) SwRenderer;
    if (!renderer || (renderer->pImpl && renderer->pImpl->canvas)) return renderer;
    delete renderer;
    return nullptr;
}

Result SwRenderer::font(const char* path) noexcept
{
    if (!path) return Result::InvalidArguments;
    return renderer::tvgSuccess(tvg::Text::load(path)) ? Result::Success : Result::NonSupport;
}

Result SwRenderer::font(const char* name, const void* data, uint32_t size, const char* mime) noexcept
{
    if (!name || !name[0] || !data || !size || !mime || !mime[0]) return Result::InvalidArguments;
    return renderer::tvgSuccess(tvg::Text::load(name, static_cast<const char*>(data), size, mime, true)) ? Result::Success
                                                                                             : Result::NonSupport;
}

static bool _family(const Object* object, const Object* ancestor)
{
    while (object) {
        if (object == ancestor) return true;
        object = object->parent();
    }
    return false;
}

struct SamplePaint
{
    tvg::Paint* paint = nullptr;
    uint32_t order = 0u;
};

static Result _sampleFamily(tvg::SwCanvas* canvas, Surface& surface,
                            const DisplayList& list, const Object* candidate,
                            uint32_t pixelRatio, uint32_t pixelX, uint32_t pixelY,
                            SamplePaint* paints, Color& color, uint32_t& order,
                            bool& hit)
{
    hit = false;
    color = {0, 0, 0, 0};
    auto root = tvg::Scene::gen();
    if (!root) return Result::OutOfMemory;
    auto paintCount = 0u;
    for (auto i = 0u; i < list.count; i++) {
        auto& command = list.commands[i];
        if (!_family(command.object, candidate) || !renderer::tvgVisible(command)) continue;
        auto paint = renderer::tvgPaint(command);
        if (!paint) {
            renderer::tvgRelease(root);
            return Result::NonSupport;
        }
        paints[paintCount++] = {paint, i};
        if (renderer::tvgAdd(root, paint)) continue;
        renderer::tvgRelease(root);
        return Result::Unknown;
    }
    if (!paintCount) {
        renderer::tvgRelease(root);
        return Result::Success;
    }

    auto scale = static_cast<float>(pixelRatio);
    tvg::Matrix matrix = {
        scale, 0.0f, -static_cast<float>(pixelX),
        0.0f, scale, -static_cast<float>(pixelY),
        0.0f, 0.0f, 1.0f};
    if (!renderer::tvgSuccess(root->transform(matrix))) {
        renderer::tvgRelease(root);
        return Result::Unknown;
    }
    surface.data()[0] = 0u;
    if (!renderer::tvgSuccess(canvas->add(root))) {
        renderer::tvgRelease(root);
        return Result::Unknown;
    }
    auto result = Result::Success;
    if (!renderer::tvgSuccess(canvas->update()) || !renderer::tvgSuccess(canvas->draw(true)) || !renderer::tvgSuccess(canvas->sync())) {
        result = Result::Unknown;
    } else {
        auto rgba = reinterpret_cast<const uint8_t*>(surface.data());
        color = {rgba[0], rgba[1], rgba[2], rgba[3]};
        if (color.a) {
            if (paintCount == 1u) {
                order = paints[0].order;
                hit = true;
            } else {
                for (auto i = 0u; i < paintCount; i++) {
                    if (!renderer::tvgSuccess(paints[i].paint->visible(false))) {
                        result = Result::Unknown;
                        break;
                    }
                }
                for (auto i = paintCount; result == Result::Success && i > 0u; i--) {
                    auto paint = paints[i - 1u].paint;
                    if (!paint->intersects(0, 0, 1, 1)) continue;
                    surface.data()[0] = 0u;
                    if (!renderer::tvgSuccess(paint->visible(true)) || !renderer::tvgSuccess(canvas->update())
                        || !renderer::tvgSuccess(canvas->draw(true)) || !renderer::tvgSuccess(canvas->sync())) {
                        result = Result::Unknown;
                        break;
                    }
                    auto isolated = reinterpret_cast<const uint8_t*>(surface.data());
                    if (isolated[3]) {
                        order = paints[i - 1u].order;
                        hit = true;
                        break;
                    }
                    if (!renderer::tvgSuccess(paint->visible(false))) {
                        result = Result::Unknown;
                        break;
                    }
                }
            }
        }
    }
    if (!renderer::tvgSuccess(canvas->remove()) && result == Result::Success) result = Result::Unknown;
    return result;
}

Result SwRenderer::sample(const Scene* scene, float time, const Vec2& position,
                          const Object* const* candidates, uint32_t count,
                          PixelSample& output, uint32_t pixelRatio) noexcept
{
    output = {};
    if (!pImpl || !pImpl->initialized || !scene || !scene->pImpl || !candidates
        || !count || count > 64u || !pixelRatio || !std::isfinite(time) || time < 0.0f
        || !std::isfinite(position.x) || !std::isfinite(position.y)) {
        return Result::InvalidArguments;
    }
    auto& config = scene->pImpl->cfg;
    if (config.width > UINT32_MAX / pixelRatio || config.height > UINT32_MAX / pixelRatio
        || position.x < 0.0f || position.y < 0.0f
        || position.x >= static_cast<float>(config.width)
        || position.y >= static_cast<float>(config.height)) {
        return Result::InvalidArguments;
    }
    for (auto i = 0u; i < count; i++) {
        if (!candidates[i] || !scene->pImpl->entry(candidates[i])) {
            return Result::InvalidArguments;
        }
        for (auto j = 0u; j < i; j++) {
            if (_family(candidates[i], candidates[j]) || _family(candidates[j], candidates[i])) {
                return Result::InvalidArguments;
            }
        }
    }

    DisplayList list;
    auto result = scene->pImpl->build(time, list);
    if (result != Result::Success) return result;
    auto paints = new (std::nothrow) SamplePaint[list.count ? list.count : 1u];
    if (!paints) return Result::OutOfMemory;
    auto canvas = tvg::SwCanvas::gen(config.antialiasing ? tvg::EngineOption::Default
                                                         : tvg::EngineOption::Aliased);
    Surface surface;
    if (!canvas) {
        delete[] paints;
        return Result::OutOfMemory;
    }
    result = surface.resize(1u, 1u);
    if (result == Result::Success
        && !renderer::tvgSuccess(canvas->target(surface.data(), surface.stride(), 1u, 1u,
                                    tvg::ColorSpace::ABGR8888S))) {
        result = Result::NonSupport;
    }

    auto found = false;
    auto selectedOrder = 0u;
    if (result == Result::Success) {
        auto pixelX = static_cast<uint32_t>(std::floor(position.x * pixelRatio));
        auto pixelY = static_cast<uint32_t>(std::floor(position.y * pixelRatio));
        for (auto i = 0u; i < count; i++) {
            Color color;
            uint32_t order = 0u;
            bool hit = false;
            result = _sampleFamily(canvas, surface, list, candidates[i], pixelRatio,
                                   pixelX, pixelY, paints, color, order, hit);
            if (result != Result::Success) break;
            if (!hit || (found && order <= selectedOrder)) continue;
            found = true;
            selectedOrder = order;
            output.object = candidates[i];
            output.position = position;
            output.color = color;
        }
    }
    delete canvas;
    delete[] paints;
    if (result != Result::Success) return result;
    return found ? Result::Success : Result::InsufficientCondition;
}

static Result _paintBounds(const DisplayList& list, const Object* object, bool family,
                           BBox& output)
{
    auto root = tvg::Scene::gen();
    if (!root) return Result::OutOfMemory;
    auto found = false;
    for (auto i = 0u; i < list.count; i++) {
        auto& command = list.commands[i];
        if ((family ? !_family(command.object, object) : command.object != object)
            || !renderer::tvgVisible(command)) {
            continue;
        }
        auto paint = renderer::tvgPaint(command);
        if (!paint) {
            renderer::tvgRelease(root);
            return Result::NonSupport;
        }
        if (!renderer::tvgAdd(root, paint)) {
            renderer::tvgRelease(root);
            return Result::Unknown;
        }
        found = true;
    }
    if (!found) {
        renderer::tvgRelease(root);
        return Result::InsufficientCondition;
    }
    float x;
    float y;
    float width;
    float height;
    auto status = root->bounds(&x, &y, &width, &height);
    renderer::tvgRelease(root);
    if (!renderer::tvgSuccess(status) || !std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width)
        || !std::isfinite(height) || width <= 0.0f || height <= 0.0f) {
        return Result::InsufficientCondition;
    }
    output = {x, y, width, height};
    return Result::Success;
}

Result SwRenderer::bounds(const Scene* scene, const Object* object, float time, BBox& output) noexcept
{
    if (!pImpl || !pImpl->canvas || !scene || !scene->pImpl || !object || !std::isfinite(time)
        || time < 0.0f || !scene->pImpl->entry(object)) {
        return Result::InvalidArguments;
    }
    DisplayList list;
    auto result = scene->pImpl->build(time, list, false);
    if (result != Result::Success) return result;
    return _paintBounds(list, object, true, output);
}

Result SwRenderer::intersects(const Scene* scene, const Object* first, const Object* second,
                              float time, bool& output, float padding) noexcept
{
    output = false;
    if (!first || !second || first == second || !std::isfinite(padding) || padding < 0.0f) {
        return Result::InvalidArguments;
    }
    BBox firstBounds;
    BBox secondBounds;
    auto result = bounds(scene, first, time, firstBounds);
    if (result != Result::Success) return result;
    result = bounds(scene, second, time, secondBounds);
    if (result != Result::Success) return result;
    output = firstBounds.intersects(secondBounds, padding);
    return Result::Success;
}

struct LayoutTransform
{
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    float x = 0.0f;
    float y = 0.0f;
};

static BBox _layoutMap(const BBox& bounds, const LayoutTransform& transform)
{
    return {
        transform.x + bounds.x * transform.scaleX,
        transform.y + bounds.y * transform.scaleY,
        bounds.width * transform.scaleX,
        bounds.height * transform.scaleY,
    };
}

static bool _layoutClip(const BBox& bounds, const BBox& clip, BBox& output)
{
    auto left = std::fmax(bounds.x, clip.x);
    auto top = std::fmax(bounds.y, clip.y);
    auto right = std::fmin(bounds.x + bounds.width, clip.x + clip.width);
    auto bottom = std::fmin(bounds.y + bounds.height, clip.y + clip.height);
    if (right <= left || bottom <= top) {
        output = {};
        return false;
    }
    output = {left, top, right - left, bottom - top};
    return true;
}

static bool _layoutDifferent(const BBox& first, const BBox& second)
{
    static constexpr auto Epsilon = 1.0e-3f;
    return std::fabs(first.x - second.x) > Epsilon
        || std::fabs(first.y - second.y) > Epsilon
        || std::fabs(first.width - second.width) > Epsilon
        || std::fabs(first.height - second.height) > Epsilon;
}

static float _layoutClearance(float first, float firstSize, float second, float secondSize)
{
    auto firstEnd = first + firstSize;
    auto secondEnd = second + secondSize;
    if (firstEnd <= second) return second - firstEnd;
    if (secondEnd <= first) return first - secondEnd;
    return -std::fmin(firstEnd, secondEnd) + std::fmax(first, second);
}

static char* _layoutPath(const char* parent, const char* kind, uint32_t index)
{
    auto parentSize = std::strlen(parent);
    char suffix[48];
    auto suffixSize = std::snprintf(suffix, sizeof(suffix), "/%s:%u", kind, index);
    if (suffixSize < 0 || static_cast<size_t>(suffixSize) >= sizeof(suffix)
        || parentSize > std::numeric_limits<size_t>::max() - static_cast<size_t>(suffixSize) - 1u) {
        return nullptr;
    }
    auto path = new (std::nothrow) char[parentSize + static_cast<size_t>(suffixSize) + 1u];
    if (!path) return nullptr;
    std::memcpy(path, parent, parentSize);
    std::memcpy(path + parentSize, suffix, static_cast<size_t>(suffixSize) + 1u);
    return path;
}

Result SwRenderer::layout(const Scene* scene, float time, LayoutReport& output,
                          float padding) noexcept
{
    if (!pImpl || !pImpl->canvas || !scene || !scene->pImpl || !output.pImpl
        || !std::isfinite(time) || time < 0.0f || !std::isfinite(padding) || padding < 0.0f) {
        return Result::InvalidArguments;
    }

    auto report = output.pImpl;
    report->reset();
    report->sampleTime = time;
    report->samplePadding = padding;

    auto visit = [&](auto&& self, const Scene* current, float sampleTime,
                     const LayoutTransform& transform, const BBox& sceneBounds,
                     const BBox& clipBounds, char* path, uint32_t parent, uint32_t depth,
                     LayoutSceneKind kind, bool stretched) -> Result {
        if (!current || !path) {
            delete[] path;
            return current ? Result::OutOfMemory : Result::InvalidArguments;
        }
        auto sceneIndex = report->sceneCnt;
        LayoutScene sceneEntry;
        sceneEntry.scene = current;
        sceneEntry.path = path;
        sceneEntry.bounds = sceneBounds;
        sceneEntry.clipBounds = clipBounds;
        sceneEntry.scaleX = transform.scaleX;
        sceneEntry.scaleY = transform.scaleY;
        sceneEntry.parent = parent;
        sceneEntry.depth = depth;
        sceneEntry.kind = kind;
        sceneEntry.clipped = _layoutDifferent(sceneBounds, clipBounds);
        sceneEntry.stretched = stretched;
        if (!report->add(sceneEntry)) {
            delete[] path;
            return Result::OutOfMemory;
        }

        DisplayList list;
        auto buildResult = current->pImpl->build(sampleTime, list, false);
        if (buildResult != Result::Success) return buildResult;
        auto objectBegin = report->objectCnt;
        for (auto i = 0u; i < current->count(); i++) {
            auto object = current->objectAt(i);
            LayoutObject objectEntry;
            objectEntry.object = object;
            objectEntry.scene = sceneIndex;
            objectEntry.layer = object->layer;
            objectEntry.clipBounds = clipBounds;
            if (object->parent()) {
                for (auto parent = 0u; parent < i; parent++) {
                    if (current->objectAt(parent) == object->parent()) {
                        objectEntry.parent = objectBegin + parent;
                        break;
                    }
                }
            }

            BBox localBounds;
            auto result = _paintBounds(list, object, false, localBounds);
            if (result == Result::Success) {
                objectEntry.paintBounds = _layoutMap(localBounds, transform);
                objectEntry.visible = _layoutClip(objectEntry.paintBounds, clipBounds,
                                                  objectEntry.visibleBounds);
                objectEntry.clipped = !objectEntry.visible
                                   || _layoutDifferent(objectEntry.paintBounds,
                                                       objectEntry.visibleBounds);
            } else if (result != Result::InsufficientCondition) {
                return result;
            }

            result = _paintBounds(list, object, true, localBounds);
            if (result == Result::Success) {
                objectEntry.familyBounds = _layoutMap(localBounds, transform);
                objectEntry.familyVisible = _layoutClip(objectEntry.familyBounds, clipBounds,
                                                        objectEntry.visibleFamilyBounds);
                objectEntry.familyClipped = !objectEntry.familyVisible
                                         || _layoutDifferent(objectEntry.familyBounds,
                                                             objectEntry.visibleFamilyBounds);
            } else if (result != Result::InsufficientCondition) {
                return result;
            }
            if (!report->add(objectEntry)) return Result::OutOfMemory;
        }

        auto& parentConfig = current->config();
        auto mount = [&](const Scene* child, const Viewport& viewport, char* childPath,
                         LayoutSceneKind childKind) -> Result {
            if (!child) {
                delete[] childPath;
                return Result::InvalidArguments;
            }
            auto& childConfig = child->config();
            auto localX = viewport.x * static_cast<float>(parentConfig.width);
            auto localY = viewport.y * static_cast<float>(parentConfig.height);
            auto localWidth = viewport.width * static_cast<float>(parentConfig.width);
            auto localHeight = viewport.height * static_cast<float>(parentConfig.height);
            LayoutTransform childTransform = {
                transform.scaleX * localWidth / static_cast<float>(childConfig.width),
                transform.scaleY * localHeight / static_cast<float>(childConfig.height),
                transform.x + transform.scaleX * localX,
                transform.y + transform.scaleY * localY,
            };
            BBox childBounds = {
                childTransform.x,
                childTransform.y,
                transform.scaleX * localWidth,
                transform.scaleY * localHeight,
            };
            BBox childClip;
            _layoutClip(childBounds, clipBounds, childClip);
            auto relativeX = localWidth / static_cast<float>(childConfig.width);
            auto relativeY = localHeight / static_cast<float>(childConfig.height);
            auto tolerance = std::fmax(std::fabs(relativeX), std::fabs(relativeY)) * 1.0e-3f;
            auto childStretched = std::fabs(relativeX - relativeY) > tolerance;
            auto childTime = childKind == LayoutSceneKind::Transition
                           ? child->duration() : sampleTime;
            return self(self, child, childTime, childTransform, childBounds, childClip,
                        childPath, sceneIndex, depth + 1u, childKind, childStretched);
        };

        for (auto i = 0u; i < current->viewportCount(); i++) {
            Viewport viewport;
            if (!current->viewportAt(i, viewport)) return Result::Unknown;
            auto childPath = _layoutPath(path, "viewport", i);
            auto result = mount(current->sceneAt(i), viewport, childPath,
                                LayoutSceneKind::Viewport);
            if (result != Result::Success) return result;
        }

        auto sequence = current->pImpl->sequence;
        if (!sequence || sampleTime < sequence->begin) return Result::Success;
        auto active = sequence->count - 1u;
        for (auto i = 0u; i < sequence->count; i++) {
            auto& stage = sequence->stages[i];
            if (sampleTime < stage.end || i + 1u >= sequence->count) {
                active = i;
                break;
            }
            auto& transition = sequence->transitions[i];
            if (sampleTime >= transition.end) continue;
            auto progress = (sampleTime - transition.begin) / (transition.end - transition.begin);
            active = progress < 0.5f ? i : i + 1u;
            break;
        }
        auto childPath = _layoutPath(path, "transition", active);
        return mount(sequence->stages[active].scene, sequence->viewport, childPath,
                     LayoutSceneKind::Transition);
    };

    auto rootPath = new (std::nothrow) char[5];
    if (!rootPath) return Result::OutOfMemory;
    std::memcpy(rootPath, "root", 5);
    auto rootBounds = BBox{0.0f, 0.0f, static_cast<float>(scene->config().width),
                           static_cast<float>(scene->config().height)};
    auto result = visit(visit, scene, time, {}, rootBounds, rootBounds, rootPath,
                        0xffffffffu, 0u, LayoutSceneKind::Root, false);
    if (result != Result::Success) {
        report->reset();
        return result;
    }

    for (auto i = 0u; i < report->objectCnt; i++) {
        auto& first = report->objects[i];
        for (auto j = i + 1u; j < report->objectCnt; j++) {
            auto& second = report->objects[j];
            auto firstContainsSecond = first.scene == second.scene
                                    && _family(second.object, first.object);
            auto secondContainsFirst = first.scene == second.scene
                                    && _family(first.object, second.object);
            if (firstContainsSecond || secondContainsFirst) {
                auto containerIndex = firstContainsSecond ? i : j;
                auto contentIndex = firstContainsSecond ? j : i;
                auto& container = report->objects[containerIndex];
                auto& content = report->objects[contentIndex];
                if (container.paintBounds.width <= 0.0f || container.paintBounds.height <= 0.0f
                    || content.familyBounds.width <= 0.0f || content.familyBounds.height <= 0.0f) {
                    continue;
                }
                LayoutContainment containment;
                containment.container = containerIndex;
                containment.content = contentIndex;
                containment.inset = padding;
                for (auto ancestor = content.object; ancestor && ancestor != container.object;
                     ancestor = ancestor->parent()) {
                    containment.depth++;
                }
                auto innerLeft = container.paintBounds.x + padding;
                auto innerTop = container.paintBounds.y + padding;
                auto innerRight = container.paintBounds.x + container.paintBounds.width - padding;
                auto innerBottom = container.paintBounds.y + container.paintBounds.height - padding;
                containment.overflowLeft = std::fmax(0.0f, innerLeft - content.familyBounds.x);
                containment.overflowTop = std::fmax(0.0f, innerTop - content.familyBounds.y);
                containment.overflowRight = std::fmax(
                    0.0f, content.familyBounds.x + content.familyBounds.width - innerRight);
                containment.overflowBottom = std::fmax(
                    0.0f, content.familyBounds.y + content.familyBounds.height - innerBottom);
                containment.contained = containment.overflowLeft <= 0.0f
                                     && containment.overflowTop <= 0.0f
                                     && containment.overflowRight <= 0.0f
                                     && containment.overflowBottom <= 0.0f;
                if (!report->add(containment)) {
                    report->reset();
                    return Result::OutOfMemory;
                }
                continue;
            }
            if (!first.visible || !second.visible) continue;
            if (!first.visibleBounds.intersects(second.visibleBounds, padding)) continue;

            LayoutCollision collision;
            collision.first = i;
            collision.second = j;
            collision.clearance = {
                _layoutClearance(first.visibleBounds.x, first.visibleBounds.width,
                                 second.visibleBounds.x, second.visibleBounds.width),
                _layoutClearance(first.visibleBounds.y, first.visibleBounds.height,
                                 second.visibleBounds.y, second.visibleBounds.height),
            };
            collision.overlapping = collision.clearance.x < 0.0f
                                 && collision.clearance.y < 0.0f;
            if (collision.overlapping) {
                auto left = std::fmax(first.visibleBounds.x, second.visibleBounds.x);
                auto top = std::fmax(first.visibleBounds.y, second.visibleBounds.y);
                auto right = std::fmin(first.visibleBounds.x + first.visibleBounds.width,
                                       second.visibleBounds.x + second.visibleBounds.width);
                auto bottom = std::fmin(first.visibleBounds.y + first.visibleBounds.height,
                                        second.visibleBounds.y + second.visibleBounds.height);
                collision.overlap = {left, top, right - left, bottom - top};
            }
            auto horizontal = padding - collision.clearance.x;
            auto vertical = padding - collision.clearance.y;
            if (horizontal <= vertical) {
                collision.separation.x = second.visibleBounds.center().x
                                       < first.visibleBounds.center().x ? -horizontal : horizontal;
            } else {
                collision.separation.y = second.visibleBounds.center().y
                                       < first.visibleBounds.center().y ? -vertical : vertical;
            }
            if (!report->add(collision)) {
                report->reset();
                return Result::OutOfMemory;
            }
        }
    }
    return Result::Success;
}

Result SwRenderer::render(const Scene* scene, float time, Surface& surface) noexcept
{
    return render(scene, time, surface, 1u);
}

Result SwRenderer::render(const Scene* scene, float time, Surface& surface,
                          uint32_t pixelRatio) noexcept
{
    if (!pImpl || !pImpl->canvas || !scene || !scene->pImpl || !std::isfinite(time)
        || time < 0.0f || !pixelRatio) {
        return Result::InvalidArguments;
    }
    auto& config = scene->pImpl->cfg;
    if (config.width > UINT32_MAX / pixelRatio || config.height > UINT32_MAX / pixelRatio) {
        return Result::InvalidArguments;
    }
    auto result = surface.resize(config.width * pixelRatio, config.height * pixelRatio);
    if (result != Result::Success) return result;

    if (pImpl->active) {
        if (!renderer::tvgSuccess(pImpl->canvas->remove())) return Result::Unknown;
        pImpl->active = false;
    }
    if (pImpl->antialiasing != config.antialiasing) {
        delete pImpl->canvas;
        pImpl->canvas = tvg::SwCanvas::gen(config.antialiasing ? tvg::EngineOption::Default
                                                               : tvg::EngineOption::Aliased);
        pImpl->antialiasing = config.antialiasing;
        if (!pImpl->canvas) return Result::NonSupport;
    }
    if (!renderer::tvgSuccess(pImpl->canvas->target(surface.data(), surface.stride(), surface.width(),
                                        surface.height(), tvg::ColorSpace::ABGR8888S))) {
        return Result::NonSupport;
    }

    tvg::Scene* root = nullptr;
    result = renderer::tvgPaints(scene, time, root);
    if (result != Result::Success) return result;
    if (pixelRatio > 1u) {
        auto scale = static_cast<float>(pixelRatio);
        tvg::Matrix matrix = {
            scale, 0.0f, 0.0f,
            0.0f, scale, 0.0f,
            0.0f, 0.0f, 1.0f};
        if (!renderer::tvgSuccess(root->transform(matrix))) {
            renderer::tvgRelease(root);
            return Result::Unknown;
        }
    }
    if (!renderer::tvgSuccess(pImpl->canvas->add(root))) {
        renderer::tvgRelease(root);
        return Result::Unknown;
    }
    pImpl->active = true;
    if (!renderer::tvgSuccess(pImpl->canvas->update())) return Result::Unknown;
    if (!renderer::tvgSuccess(pImpl->canvas->draw(true))) return Result::Unknown;
    if (!renderer::tvgSuccess(pImpl->canvas->sync())) return Result::Unknown;
    return Result::Success;
}

namespace renderer
{

bool cpuEnabled() noexcept
{
    return true;
}

SwRenderer* genCpu() noexcept
{
    return SwRenderer::gen();
}

}  // namespace renderer

}  // namespace tmath
