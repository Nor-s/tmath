#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#include <thorvg.h>

#include "tmath.h"
#include "tmathDisplayList.h"
#include "tmathTvgRenderer.h"
#include "tmathScene.h"

namespace tmath
{

static bool _success(tvg::Result result)
{
    return result == tvg::Result::Success;
}

static void _release(tvg::Paint* paint)
{
    paint->unref();
}

static bool _add(tvg::Scene* scene, tvg::Paint* paint)
{
    if (!paint) return false;
    if (_success(scene->add(paint))) return true;
    _release(paint);
    return false;
}

static tvg::LinearGradient* _gradient(const DrawCommand& command, Color start)
{
    Vec2 from;
    Vec2 to;
    if (command.type == CommandType::Circle) {
        from = {command.center.x - command.radius, command.center.y - command.radius};
        to = {command.center.x + command.radius, command.center.y + command.radius};
    } else if (command.count) {
        if (!command.closed && command.count > 1u) {
            from = command.points[0];
            to = command.points[command.count - 1u];
        }
        if (command.closed || (std::fabs(to.x - from.x) < 1e-6f
                               && std::fabs(to.y - from.y) < 1e-6f)) {
            from = command.points[0];
            to = command.points[0];
            for (auto i = 1u; i < command.count; i++) {
                from.x = std::fmin(from.x, command.points[i].x);
                from.y = std::fmin(from.y, command.points[i].y);
                to.x = std::fmax(to.x, command.points[i].x);
                to.y = std::fmax(to.y, command.points[i].y);
            }
        }
    }
    if (std::fabs(to.x - from.x) < 1e-6f && std::fabs(to.y - from.y) < 1e-6f) {
        to.x = from.x + 1.0f;
    }

    auto gradient = tvg::LinearGradient::gen();
    if (!gradient) return nullptr;
    auto end = command.style.gradientEnd;
    end.a = start.a;
    tvg::Fill::ColorStop stops[] = {
        {0.0f, start.r, start.g, start.b, start.a},
        {1.0f, end.r, end.g, end.b, end.a},
    };
    if (!_success(gradient->linear(from.x, from.y, to.x, to.y))
        || !_success(gradient->colorStops(stops, 2u))) {
        delete gradient;
        return nullptr;
    }
    return gradient;
}

static bool _stroke(tvg::Shape* shape, const DrawCommand& command)
{
    if (!command.style.stroke.a || command.style.width <= 0.0f) return true;
    if (!_success(shape->strokeWidth(command.style.width))
        || !_success(shape->strokeCap(command.cap == PathCap::Butt
                                      ? tvg::StrokeCap::Butt
                                      : tvg::StrokeCap::Round))
        || !_success(shape->strokeJoin(tvg::StrokeJoin::Round))
        || (command.style.dashCount
            && !_success(shape->strokeDash(command.style.dash, command.style.dashCount,
                                            command.style.dashOffset)))) {
        return false;
    }
    if (!command.style.gradient) {
        auto& color = command.style.stroke;
        return _success(shape->strokeFill(color.r, color.g, color.b, color.a));
    }
    auto gradient = _gradient(command, command.style.stroke);
    if (!gradient) return false;
    if (_success(shape->strokeFill(gradient))) return true;
    delete gradient;
    return false;
}

static bool _fill(tvg::Shape* shape, const DrawCommand& command)
{
    auto& color = command.style.fill;
    if (!command.style.gradient || !color.a) {
        return _success(shape->fill(color.r, color.g, color.b, color.a));
    }
    auto gradient = _gradient(command, color);
    if (!gradient) return false;
    if (_success(shape->fill(gradient))) return true;
    delete gradient;
    return false;
}

static tvg::Shape* _path(const DrawCommand& command)
{
    auto shape = tvg::Shape::gen();
    if (!shape) return nullptr;
    if (!_success(shape->moveTo(command.points[0].x, command.points[0].y))) {
        _release(shape);
        return nullptr;
    }
    for (auto i = 1u; i < command.count; i++) {
        if (!_success(shape->lineTo(command.points[i].x, command.points[i].y))) {
            _release(shape);
            return nullptr;
        }
    }
    if (command.closed && !_success(shape->close())) {
        _release(shape);
        return nullptr;
    }
    if (!_stroke(shape, command) || !_fill(shape, command)) {
        _release(shape);
        return nullptr;
    }
    return shape;
}

static tvg::Shape* _circle(const DrawCommand& command)
{
    auto shape = tvg::Shape::gen();
    if (!shape) return nullptr;
    if (!_success(shape->appendCircle(command.center.x, command.center.y, command.radius, command.radius))) {
        _release(shape);
        return nullptr;
    }
    if (!_stroke(shape, command) || !_fill(shape, command)) {
        _release(shape);
        return nullptr;
    }
    return shape;
}

static tvg::Text* _text(const DrawCommand& command)
{
    auto text = tvg::Text::gen();
    if (!text) return nullptr;
    if (!_success(text->font(command.font)) || !_success(text->size(command.size)) || !_success(text->text(command.text))) {
        _release(text);
        return nullptr;
    }
    if (!_success(text->align(command.align.x, command.align.y)) || !_success(text->fill(command.style.fill.r, command.style.fill.g, command.style.fill.b)) || !_success(text->opacity(command.style.fill.a))) {
        _release(text);
        return nullptr;
    }
    if (command.transformed) {
        auto& source = command.transform.e;
        tvg::Matrix matrix = {
            source[0], source[1], source[2],
            source[3], source[4], source[5],
            source[6], source[7], source[8]};
        if (!_success(text->transform(matrix))) {
            _release(text);
            return nullptr;
        }
    } else if (!_success(text->translate(command.center.x, command.center.y))) {
        _release(text);
        return nullptr;
    }
    return text;
}

static tvg::Text* _number(const DrawCommand& command)
{
    char value[64];
    auto converted = std::to_chars(value, value + sizeof(value) - 1u, command.number,
                                   std::chars_format::general);
    if (converted.ec != std::errc{}) return nullptr;
    *converted.ptr = '\0';
    auto copy = command;
    copy.text = value;
    copy.font = nullptr;
    return _text(copy);
}

static tvg::Picture* _svg(const DrawCommand& command)
{
    auto picture = tvg::Picture::gen();
    if (!picture) return nullptr;
    if (!_success(picture->load(command.path))) {
        _release(picture);
        return nullptr;
    }
    float width;
    float height;
    if (!_success(picture->size(&width, &height)) || width <= 0.0f || height <= 0.0f) {
        _release(picture);
        return nullptr;
    }
    if (!_success(picture->size(command.size, command.size * height / width)) || !_success(picture->origin(0.5f, 0.5f)) || !_success(picture->rotate(command.rotation)) || !_success(picture->opacity(command.opacity)) || !_success(picture->translate(command.center.x, command.center.y))) {
        _release(picture);
        return nullptr;
    }
    return picture;
}

static tvg::Picture* _image(const DrawCommand& command)
{
    auto picture = tvg::Picture::gen();
    if (!picture) return nullptr;
    if (!_success(picture->load(command.pixels, command.pixelWidth, command.pixelHeight,
                                tvg::ColorSpace::ABGR8888S, false))
        || !_success(picture->filter(command.filter == ImageFilter::Nearest ? tvg::FilterMethod::Nearest
                                                                            : tvg::FilterMethod::Bilinear))) {
        _release(picture);
        return nullptr;
    }
    auto& origin = command.points[0];
    auto matrix = tvg::Matrix{
        (command.points[1].x - origin.x) / static_cast<float>(command.pixelWidth),
        (command.points[2].x - origin.x) / static_cast<float>(command.pixelHeight), origin.x,
        (command.points[1].y - origin.y) / static_cast<float>(command.pixelWidth),
        (command.points[2].y - origin.y) / static_cast<float>(command.pixelHeight), origin.y,
        0.0f, 0.0f, 1.0f};
    if (!_success(picture->transform(matrix)) || !_success(picture->opacity(command.opacity))) {
        _release(picture);
        return nullptr;
    }
    return picture;
}

static tvg::Paint* _paint(const DrawCommand& command)
{
    switch (command.type) {
        case CommandType::Path: return _path(command);
        case CommandType::Circle: return _circle(command);
        case CommandType::Text: return _text(command);
        case CommandType::Number: return _number(command);
        case CommandType::Svg: return _svg(command);
        case CommandType::Image: return _image(command);
    }
    return nullptr;
}

static bool _visible(const DrawCommand& command)
{
    switch (command.type) {
        case CommandType::Path:
        case CommandType::Circle:
            return command.style.fill.a || (command.style.stroke.a && command.style.width > 0.0f);
        case CommandType::Text:
        case CommandType::Number: return command.style.fill.a;
        case CommandType::Svg:
        case CommandType::Image: return command.opacity;
    }
    return false;
}

static Result _localPaints(const Config& config, const DisplayList& list, tvg::Scene*& output)
{
    auto root = tvg::Scene::gen();
    if (!root) return Result::OutOfMemory;

    auto background = tvg::Shape::gen();
    if (!background) {
        _release(root);
        return Result::OutOfMemory;
    }
    if (!_success(background->appendRect(0.0f, 0.0f, static_cast<float>(config.width),
                                         static_cast<float>(config.height)))) {
        _release(background);
        _release(root);
        return Result::Unknown;
    }
    auto& color = config.background;
    if (!_success(background->fill(color.r, color.g, color.b, color.a))) {
        _release(background);
        _release(root);
        return Result::Unknown;
    }
    if (!_add(root, background)) {
        _release(root);
        return Result::Unknown;
    }

    for (auto i = 0u; i < list.count; i++) {
        auto& command = list.commands[i];
        auto paint = _paint(command);
        if (paint && _add(root, paint)) continue;
        _release(root);
        return paint ? Result::Unknown : Result::NonSupport;
    }
    output = root;
    return Result::Success;
}

static Color _mix(const Color& from, const Color& to, float progress)
{
    auto channel = [progress](uint8_t first, uint8_t second) {
        auto value = static_cast<float>(first)
                   + (static_cast<float>(second) - first) * progress;
        if (value < 0.0f) value = 0.0f;
        if (value > 255.0f) value = 255.0f;
        return static_cast<uint8_t>(value + 0.5f);
    };
    return {
        channel(from.r, to.r), channel(from.g, to.g),
        channel(from.b, to.b), channel(from.a, to.a)};
}

static Result _mount(tvg::Scene* root, tvg::Scene* child, const Config& childConfig,
                     const Config& config, const Viewport& viewport, uint8_t opacity = 255u)
{
    auto x = viewport.x * static_cast<float>(config.width);
    auto y = viewport.y * static_cast<float>(config.height);
    auto width = viewport.width * static_cast<float>(config.width);
    auto height = viewport.height * static_cast<float>(config.height);
    tvg::Matrix matrix = {
        width / static_cast<float>(childConfig.width), 0.0f, x,
        0.0f, height / static_cast<float>(childConfig.height), y,
        0.0f, 0.0f, 1.0f};
    if (!_success(child->transform(matrix))) {
        _release(child);
        return Result::Unknown;
    }

    auto wrapper = tvg::Scene::gen();
    auto clipper = tvg::Shape::gen();
    if (!wrapper || !clipper) {
        if (wrapper) _release(wrapper);
        if (clipper) _release(clipper);
        _release(child);
        return Result::OutOfMemory;
    }
    if (!_add(wrapper, child)) {
        _release(clipper);
        _release(wrapper);
        return Result::Unknown;
    }
    if (!_success(clipper->appendRect(x, y, width, height))
        || !_success(wrapper->clip(clipper)) || !_success(wrapper->opacity(opacity))) {
        if (!clipper->parent()) _release(clipper);
        _release(wrapper);
        return Result::Unknown;
    }
    return _add(root, wrapper) ? Result::Success : Result::Unknown;
}

struct RendererBuilder
{
    static Result paints(const Scene* scene, float time, tvg::Scene*& output)
    {
        auto commands = 0u;
        return paints(scene, time, output, commands);
    }

    static Result paints(const Scene* scene, float time, tvg::Scene*& output, uint32_t& commands)
    {
        DisplayList list;
        auto result = scene->pImpl->build(time, list);
        if (result != Result::Success) return result;
        if (list.count > DISPLAY_COMMAND_LIMIT - commands) return Result::InsufficientCondition;
        commands += list.count;
        auto& config = scene->pImpl->cfg;
        tvg::Scene* root = nullptr;
        result = _localPaints(config, list, root);
        if (result != Result::Success) return result;
        result = viewports(scene, time, root, config, 255u, commands);
        if (result == Result::Success) result = sequence(scene, time, root, config, commands);
        if (result != Result::Success) {
            _release(root);
            return result;
        }
        output = root;
        return Result::Success;
    }

    static Result viewports(const Scene* scene, float time, tvg::Scene* root,
                            const Config& config, uint8_t opacity, uint32_t& commands)
    {
        for (auto i = 0u; i < scene->pImpl->viewportCnt; i++) {
            auto& entry = scene->pImpl->viewports[i];
            tvg::Scene* child = nullptr;
            auto result = paints(entry.scene, time, child, commands);
            if (result != Result::Success) return result;
            result = _mount(root, child, entry.scene->pImpl->cfg, config,
                            entry.viewport, opacity);
            if (result != Result::Success) return result;
        }
        return Result::Success;
    }

    static Result transition(const Scene* from, const Scene* to,
                             const SceneTransition& transition, float progress,
                             tvg::Scene*& output, Config& config, uint32_t& commands)
    {
        DisplayList first;
        DisplayList second;
        DisplayList blended;
        auto fromTime = from->duration();
        auto toTime = to->duration();
        auto result = from->pImpl->build(fromTime, first, false);
        if (result != Result::Success) return result;
        result = to->pImpl->build(toTime, second, false);
        if (result != Result::Success) return result;
        auto& fromConfig = from->pImpl->cfg;
        auto& toConfig = to->pImpl->cfg;
        result = blended.blend(first, second, transition.matches,
                               from->pImpl->objectCnt, to->pImpl->objectCnt,
                               {static_cast<float>(fromConfig.width), static_cast<float>(fromConfig.height)},
                               {static_cast<float>(toConfig.width), static_cast<float>(toConfig.height)},
                               progress);
        if (result != Result::Success) return result;
        if (blended.count > DISPLAY_COMMAND_LIMIT - commands) return Result::InsufficientCondition;
        commands += blended.count;
        config = fromConfig;
        auto bounded = progress;
        if (bounded < 0.0f) bounded = 0.0f;
        if (bounded > 1.0f) bounded = 1.0f;
        config.background = _mix(fromConfig.background, toConfig.background, bounded);
        result = _localPaints(config, blended, output);
        if (result != Result::Success) return result;
        auto fromOpacity = static_cast<uint8_t>((1.0f - bounded) * 255.0f + 0.5f);
        auto toOpacity = static_cast<uint8_t>(bounded * 255.0f + 0.5f);
        result = viewports(from, fromTime, output, config, fromOpacity, commands);
        if (result == Result::Success) {
            result = viewports(to, toTime, output, config, toOpacity, commands);
        }
        if (result == Result::Success) {
            result = sequence(from, fromTime, output, config, commands, fromOpacity);
        }
        if (result == Result::Success) {
            result = sequence(to, toTime, output, config, commands, toOpacity);
        }
        if (result == Result::Success) return result;
        _release(output);
        output = nullptr;
        return result;
    }

    static Result sequence(const Scene* scene, float time, tvg::Scene* root,
                           const Config& config, uint32_t& commands, uint8_t opacity = 255u)
    {
        auto sequence = scene->pImpl->sequence;
        if (!sequence || time < sequence->begin) return Result::Success;
        tvg::Scene* child = nullptr;
        Config childConfig;
        auto result = Result::Success;
        for (auto i = 0u; i < sequence->count; i++) {
            auto& stage = sequence->stages[i];
            if (time < stage.end) {
                childConfig = stage.scene->pImpl->cfg;
                result = paints(stage.scene, stage.scene->duration(), child, commands);
                break;
            }
            if (i + 1u >= sequence->count) {
                childConfig = stage.scene->pImpl->cfg;
                result = paints(stage.scene, stage.scene->duration(), child, commands);
                break;
            }
            auto& clip = sequence->transitions[i];
            if (time >= clip.end) continue;
            auto progress = (time - clip.begin) / (clip.end - clip.begin);
            if (progress <= 0.0f) {
                childConfig = stage.scene->pImpl->cfg;
                result = paints(stage.scene, stage.scene->duration(), child, commands);
            } else {
                result = transition(stage.scene, sequence->stages[i + 1u].scene,
                                    clip, ease(clip.curve, progress), child,
                                    childConfig, commands);
            }
            break;
        }
        if (result != Result::Success) return result;
        if (!child) return Result::Unknown;
        return _mount(root, child, childConfig, config, sequence->viewport, opacity);
    }
};

static bool _init()
{
    return _success(tvg::Initializer::init(0));
}

static void _term()
{
    tvg::Initializer::term();
}

namespace renderer
{

bool tvgSuccess(tvg::Result result) noexcept
{
    return _success(result);
}

void tvgRelease(tvg::Paint* paint) noexcept
{
    _release(paint);
}

bool tvgAdd(tvg::Scene* scene, tvg::Paint* paint) noexcept
{
    return _add(scene, paint);
}

tvg::Paint* tvgPaint(const DrawCommand& command) noexcept
{
    return _paint(command);
}

bool tvgVisible(const DrawCommand& command) noexcept
{
    return _visible(command);
}

Result tvgPaints(const Scene* scene, float time, tvg::Scene*& output) noexcept
{
    return RendererBuilder::paints(scene, time, output);
}

bool tvgInit() noexcept
{
    return _init();
}

void tvgTerm() noexcept
{
    _term();
}

}  // namespace renderer

}  // namespace tmath
