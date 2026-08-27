#include <cstdlib>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <limits>
#include <type_traits>

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
#include <sys/stat.h>
#include <unistd.h>
#endif

#include "tmath.h"

using namespace tmath;

static_assert(!std::is_copy_constructible<Object>::value, "Object owns its tag");
static_assert(!std::is_copy_constructible<Scene>::value, "Scene owns its object graph");
static_assert(!std::is_copy_constructible<SwRenderer>::value, "SwRenderer owns a canvas");
static_assert(!std::is_copy_constructible<GlRenderer>::value, "GlRenderer owns a canvas");
static_assert(!std::is_constructible<Object, Type>::value, "Object hierarchy is closed");

static int failures = 0;

struct RuntimeProbe
{
    uint32_t objects = 0;
    uint32_t cameras = 0;
    uint32_t inputs = 0;
    bool invalidateObject = false;
    bool invalidateCamera = false;
};

static Result runtimeObject(const Object*, float, Mat4&, float& opacity, float&,
                            void* data) noexcept
{
    auto probe = static_cast<RuntimeProbe*>(data);
    probe->objects++;
    if (probe->invalidateObject) opacity = std::numeric_limits<float>::quiet_NaN();
    return Result::Success;
}

static Result runtimeCamera(float, Camera& camera, CameraView&, void* data) noexcept
{
    auto probe = static_cast<RuntimeProbe*>(data);
    probe->cameras++;
    if (probe->invalidateCamera) camera.near = -1.0f;
    return Result::Success;
}

static Result runtimeInput(const CameraInput&, void* data) noexcept
{
    static_cast<RuntimeProbe*>(data)->inputs++;
    return Result::Success;
}

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

static uint32_t changed(const Surface& surface, Color background)
{
    auto pixel = static_cast<uint32_t>(background.a) << 24 | static_cast<uint32_t>(background.b) << 16 | static_cast<uint32_t>(background.g) << 8 | background.r;
    auto count = 0u;
    for (auto y = 0u; y < surface.height(); y++) {
        for (auto x = 0u; x < surface.width(); x++) {
            if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] != pixel) count++;
        }
    }
    return count;
}

static uint64_t checksum(const Surface& surface)
{
    auto hash = 14695981039346656037ull;
    for (auto i = 0u; i < surface.width() * surface.height(); i++) {
        hash ^= surface.data()[i];
        hash *= 1099511628211ull;
    }
    return hash;
}

static uint32_t pixel(Color color)
{
    return static_cast<uint32_t>(color.a) << 24 | static_cast<uint32_t>(color.b) << 16
        | static_cast<uint32_t>(color.g) << 8 | color.r;
}

static bool same(Color first, Color second)
{
    return first.r == second.r && first.g == second.g && first.b == second.b
           && first.a == second.a;
}

static bool near(float lhs, float rhs, float epsilon = 1.0e-4f)
{
    return std::fabs(lhs - rhs) <= epsilon;
}

static void renderBounds(SwRenderer* renderer)
{
    BBox first = {10.0f, 10.0f, 20.0f, 20.0f};
    BBox second = {35.0f, 10.0f, 20.0f, 20.0f};
    CHECK(near(first.center().x, 20.0f) && near(first.center().y, 20.0f));
    CHECK(near(first.size().x, 20.0f) && near(first.size().y, 20.0f));
    CHECK(!first.intersects(second));
    CHECK(first.intersects(second, 6.0f));
    CHECK(!first.intersects(second, -1.0f));

    Config config;
    config.width = 200;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    auto scene = Scene::gen(config);
    auto left = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto overlap = Rectangle::gen({-0.25f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto right = Rectangle::gen({0.2f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto text = Text::gen("layout", {0.0f, 1.0f, 0.0f});
    CHECK(scene && left && overlap && right && text);
    if (scene && left && overlap && right && text) {
        left->fill(Color::hex("#ffffff"));
        overlap->fill(Color::hex("#ffffff"));
        right->fill(Color::hex("#ffffff"));
        text->fill(Color::hex("#ffffff"));
        text->size = 20.0f;
        CHECK(text->font("Pretendard") == Result::Success);
        CHECK(scene->add(left) == Result::Success);
        CHECK(scene->add(overlap) == Result::Success);
        CHECK(scene->add(right) == Result::Success);
        CHECK(scene->add(text) == Result::Success);
        BBox leftBounds;
        BBox textBounds;
        CHECK(renderer->bounds(scene, left, 0.0f, leftBounds) == Result::Success);
        CHECK(renderer->bounds(scene, text, 0.0f, textBounds) == Result::Success);
        CHECK(leftBounds.width > 20.0f && leftBounds.height > 20.0f);
        CHECK(textBounds.width > 20.0f && textBounds.height > 10.0f);
        auto intersects = false;
        CHECK(renderer->intersects(scene, left, overlap, 0.0f, intersects) == Result::Success);
        CHECK(intersects);
        CHECK(renderer->intersects(scene, left, right, 0.0f, intersects) == Result::Success);
        CHECK(!intersects);
        CHECK(renderer->intersects(scene, left, right, 0.0f, intersects, 6.0f) == Result::Success);
        CHECK(intersects);
        CHECK(renderer->intersects(scene, left, left, 0.0f, intersects) == Result::InvalidArguments);
    } else {
        delete left;
        delete overlap;
        delete right;
        delete text;
    }
    delete scene;

    Config rootConfig;
    rootConfig.width = 200;
    rootConfig.height = 100;
    rootConfig.camera.orthoHeight = 2.0f;
    Config childConfig;
    childConfig.width = 100;
    childConfig.height = 100;
    childConfig.camera.orthoHeight = 2.0f;
    auto root = Scene::gen(rootConfig);
    auto child = Scene::gen(childConfig);
    auto rootBox = Rectangle::gen({1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto childBox = Rectangle::gen({0.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto panel = Rectangle::gen({0.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto clippedText = Text::gen("overflow", {0.8f, 0.0f, 0.0f});
    CHECK(root && child && rootBox && childBox && panel && clippedText);
    if (root && child && rootBox && childBox && panel && clippedText) {
        rootBox->tag("root-box").fill(Color::hex("#ffffff"));
        childBox->tag("child-box").fill(Color::hex("#ffffff"));
        panel->tag("panel").fill(Color::hex("#ffffff"));
        clippedText->tag("clipped-text").fill(Color::hex("#ffffff"));
        clippedText->size = 16.0f;
        CHECK(clippedText->font("Pretendard") == Result::Success);
        CHECK(root->add(rootBox) == Result::Success);
        CHECK(child->add(childBox) == Result::Success);
        CHECK(panel->add(clippedText) == Result::Success);
        CHECK(child->add(panel) == Result::Success);
        CHECK(root->viewport(child, {0.5f, 0.0f, 0.5f, 1.0f}) == Result::Success);

        LayoutReport report;
        CHECK(renderer->layout(root, 0.0f, report, 4.0f) == Result::Success);
        CHECK(near(report.time(), 0.0f) && near(report.padding(), 4.0f));
        CHECK(report.sceneCount() == 2u && report.objectCount() == 4u);
        auto rootLayout = report.sceneAt(0);
        auto childLayout = report.sceneAt(1);
        CHECK(rootLayout && childLayout);
        if (rootLayout && childLayout) {
            CHECK(std::strcmp(rootLayout->path, "root") == 0);
            CHECK(std::strcmp(childLayout->path, "root/viewport:0") == 0);
            CHECK(childLayout->parent == 0u && childLayout->depth == 1u);
            CHECK(childLayout->kind == LayoutSceneKind::Viewport);
            CHECK(!childLayout->stretched);
            CHECK(near(childLayout->bounds.x, 100.0f));
            CHECK(near(childLayout->bounds.width, 100.0f));
        }

        uint32_t rootIndex = UINT32_MAX;
        uint32_t childIndex = UINT32_MAX;
        uint32_t panelIndex = UINT32_MAX;
        uint32_t clippedIndex = UINT32_MAX;
        for (auto i = 0u; i < report.objectCount(); i++) {
            auto item = report.objectAt(i);
            auto tag = item && item->object ? item->object->tag() : nullptr;
            if (!tag) continue;
            if (std::strcmp(tag, "root-box") == 0) rootIndex = i;
            else if (std::strcmp(tag, "child-box") == 0) childIndex = i;
            else if (std::strcmp(tag, "panel") == 0) panelIndex = i;
            else if (std::strcmp(tag, "clipped-text") == 0) clippedIndex = i;
        }
        CHECK(rootIndex != UINT32_MAX && childIndex != UINT32_MAX && panelIndex != UINT32_MAX
              && clippedIndex != UINT32_MAX);
        if (clippedIndex != UINT32_MAX) {
            auto item = report.objectAt(clippedIndex);
            CHECK(item->visible && item->clipped);
            CHECK(item->paintBounds.x + item->paintBounds.width > 200.0f);
            CHECK(item->visibleBounds.x + item->visibleBounds.width <= 200.0f);
            CHECK(item->parent == panelIndex);
        }
        auto crossSceneCollision = false;
        for (auto i = 0u; i < report.collisionCount(); i++) {
            auto collision = report.collisionAt(i);
            if (!collision) continue;
            if ((collision->first == rootIndex && collision->second == childIndex)
                || (collision->first == childIndex && collision->second == rootIndex)) {
                crossSceneCollision = collision->overlapping;
                CHECK(std::fabs(collision->separation.x) > 0.0f
                      || std::fabs(collision->separation.y) > 0.0f);
            }
        }
        CHECK(crossSceneCollision);
        auto parentChildCompared = false;
        for (auto i = 0u; i < report.containmentCount(); i++) {
            auto containment = report.containmentAt(i);
            if (!containment || containment->container != panelIndex
                || containment->content != clippedIndex) {
                continue;
            }
            parentChildCompared = true;
            CHECK(containment->depth == 1u);
            CHECK(!containment->contained);
            CHECK(containment->overflowRight > 0.0f);
        }
        CHECK(parentChildCompared);
        CHECK(renderer->layout(root, -1.0f, report) == Result::InvalidArguments);
    } else {
        delete rootBox;
        delete childBox;
        delete panel;
        delete clippedText;
        delete child;
    }
    delete root;
}

static uint32_t strokePixels(SwRenderer* renderer, const float* pattern, uint32_t count)
{
    Config config;
    config.width = 200;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    auto scene = Scene::gen(config);
    auto line = Line::gen({-3.0f, 0.0f}, {3.0f, 0.0f});
    CHECK(scene && line);
    if (!scene || !line) {
        delete scene;
        delete line;
        return 0u;
    }
    line->stroke(Color::hex("#202124"), 2.0f);
    CHECK(line->dash(pattern, count, 2.0f) == Result::Success);
    CHECK(scene->add(line) == Result::Success);
    Surface surface;
    CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
    auto pixels = changed(surface, config.background);
    delete scene;
    return pixels;
}

static void dashedStrokes(SwRenderer* renderer)
{
    auto line = Line::gen({}, {1.0f, 0.0f});
    CHECK(line != nullptr);
    if (line) {
        float valid[] = {8.0f, 4.0f};
        float zero[] = {0.0f, 0.0f};
        float negative[] = {4.0f, -1.0f};
        float tooMany[] = {1.0f, 1.0f, 1.0f, 1.0f, 1.0f};
        CHECK(line->dash(valid, 2u, 2.0f) == Result::Success);
        CHECK(line->style.dashCount == 2u);
        CHECK(near(line->style.dashOffset, 2.0f));
        CHECK(line->dash(zero, 2u) == Result::InvalidArguments);
        CHECK(line->dash(negative, 2u) == Result::InvalidArguments);
        CHECK(line->dash(tooMany, 5u) == Result::InvalidArguments);
        CHECK(line->dash(nullptr, 1u) == Result::InvalidArguments);
        CHECK(line->dash(nullptr, 0u) == Result::Success);
    }
    delete line;

    float dashed[] = {8.0f, 8.0f};
    auto solidPixels = strokePixels(renderer, nullptr, 0u);
    auto dashedPixels = strokePixels(renderer, dashed, 2u);
    CHECK(solidPixels > 100u);
    CHECK(dashedPixels > solidPixels / 4u);
    CHECK(dashedPixels < solidPixels * 3u / 4u);
}

struct PixelExtent
{
    bool valid = false;
    uint32_t minX = 0;
    uint32_t minY = 0;
    uint32_t maxX = 0;
    uint32_t maxY = 0;
};

static PixelExtent extent(const Surface& surface, Color background)
{
    PixelExtent output;
    auto bg = pixel(background);
    for (auto y = 0u; y < surface.height(); y++) {
        for (auto x = 0u; x < surface.width(); x++) {
            if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] == bg) continue;
            if (!output.valid) {
                output = {true, x, y, x, y};
                continue;
            }
            if (x < output.minX) output.minX = x;
            if (y < output.minY) output.minY = y;
            if (x > output.maxX) output.maxX = x;
            if (y > output.maxY) output.maxY = y;
        }
    }
    return output;
}

static Space* _space()
{
    auto space = Space::gen({-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f});
    if (!space) return nullptr;
    space->style.stroke.a = 0;
    space->axisX.a = 0;
    space->axisY.a = 0;
    space->axisZ.a = 0;
    return space;
}

static void scene2D(SwRenderer* renderer)
{
    Config config;
    config.width = 640;
    config.height = 360;
    config.camera.orthoHeight = 7.0f;
    auto scene = Scene::gen(config);
    CHECK(scene != nullptr);

    auto space = Space::gen({-6.0f, 6.0f, 1.0f}, {-3.0f, 3.0f, 1.0f});
    auto vector = Vector::gen({3.0f, 2.0f});
    auto circle = Circle::gen({2.0f, -1.0f}, 0.6f);
    CHECK(space && vector && circle);
    vector->tail = 14.0f;
    vector->stroke(Color::hex("#ffd166"), 4.0f);
    circle->stroke(Color::hex("#4cc9f0"), 3.0f).fill(Color::hex("#4cc9f044"));
    CHECK(scene->add(space) == Result::Success);
    CHECK(scene->play(Animation::create(space), 0.5f, Easing::Linear) == Result::Success);
    CHECK(space->add(vector) == Result::Success);
    CHECK(space->add(circle) == Result::Success);
    Animation create[] = {Animation::create(vector), Animation::create(circle)};
    CHECK(scene->play(create, 2, 1.0f, Easing::Smooth) == Result::Success);
    CHECK(scene->play(Animation::transform(vector, Mat4::rotateZ(0.65f) * vector->model), 0.75f) == Result::Success);
    CHECK(scene->wait(0.25f) == Result::Success);
    CHECK(scene->duration() == 2.5f);
    CHECK(scene->object(vector->id()) == vector);
    CHECK(scene->play(Animation::transform(static_cast<Object*>(nullptr), Mat4::identity())) == Result::InvalidArguments);
    Animation wrong = Animation::create(vector);
    wrong.kind = static_cast<AnimationKind>(255);
    CHECK(scene->play(wrong) == Result::InvalidArguments);
    CHECK(scene->wait(std::numeric_limits<float>::quiet_NaN()) == Result::InvalidArguments);

    Surface surface;
    CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
    CHECK(renderer->render(scene, 1.0e-8f, surface) == Result::Success);
    CHECK(renderer->render(scene, std::numeric_limits<float>::quiet_NaN(), surface) == Result::InvalidArguments);
    auto atStart = changed(surface, config.background);
    CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
    auto atMiddle = changed(surface, config.background);
    CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
    auto atEnd = changed(surface, config.background);
    CHECK(atStart < atMiddle);
    CHECK(atMiddle < atEnd);
    CHECK(atEnd > 5000);
    Surface denseSurface;
    CHECK(renderer->render(scene, scene->duration(), denseSurface, 2u) == Result::Success);
    CHECK(denseSurface.width() == config.width * 2u);
    CHECK(denseSurface.height() == config.height * 2u);
    CHECK(changed(denseSurface, config.background) > atEnd * 3u);
    CHECK(scene->config().width == config.width && scene->config().height == config.height);
    CHECK(renderer->render(scene, 0.0f, denseSurface, 0u) == Result::InvalidArguments);
    CHECK(Saver::png(surface, "test-sw-2d.png") == Result::Success);
    delete scene;
}

static void coplanarDrawOrder(SwRenderer* renderer)
{
    Config config;
    config.width = 100;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto rectangle = Rectangle::gen({}, {2.0f, 2.0f}, 0.2f);
    Vec3 points[91];
    for (auto i = 0u; i < 91u; i++) {
        points[i] = {-0.8f + 1.6f * static_cast<float>(i) / 90.0f, 0.0f, 0.0f};
    }
    auto plot = Plot::gen(points, 91u);
    CHECK(scene && rectangle && plot);
    if (scene && rectangle && plot) {
        auto foreground = Color::hex("#4080d8");
        rectangle->stroke(Color::hex("#00000000"), 0.0f).fill(Color::hex("#d84040"));
        plot->stroke(foreground, 8.0f);
        auto rectangleResult = scene->add(rectangle);
        auto plotResult = scene->add(plot);
        CHECK(rectangleResult == Result::Success && plotResult == Result::Success);
        if (rectangleResult == Result::Success && plotResult == Result::Success) {
            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            if (surface.data()) {
                CHECK(surface.data()[50u * surface.stride() + 50u] == pixel(foreground));
            }
        } else {
            if (rectangleResult != Result::Success) delete rectangle;
            if (plotResult != Result::Success) delete plot;
        }
    } else {
        delete rectangle;
        delete plot;
    }
    delete scene;

}

static void rendererPixelSampling(SwRenderer* renderer)
{
    Config config;
    config.width = 100;
    config.height = 100;
    config.camera.orthoHeight = 2.0f;
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto background = Rectangle::gen({}, {1.2f, 1.2f});
    auto foreground = Rectangle::gen({}, {0.6f, 0.6f});
    CHECK(scene && background && foreground && renderer);
    if (!scene || !background || !foreground || !renderer) {
        delete scene;
        delete background;
        delete foreground;
        return;
    }
    background->fill(Color::hex("#e5484d"));
    foreground->fill(Color::hex("#30a46c"));
    foreground->layer = 1;
    CHECK(scene->add(background) == Result::Success);
    CHECK(scene->add(foreground) == Result::Success);
    const Object* candidates[] = {background, foreground};
    PixelSample sample;
    CHECK(renderer->sample(scene, 0.0f, {50.0f, 50.0f}, candidates, 2u, sample)
          == Result::Success);
    CHECK(sample.object == foreground && sample.color.r == 0x30 && sample.color.g == 0xa4
          && sample.color.b == 0x6c && sample.color.a == 0xff);
    CHECK(renderer->sample(scene, 0.0f, {25.0f, 50.0f}, candidates, 2u, sample, 2u)
          == Result::Success);
    CHECK(sample.object == background && sample.color.r == 0xe5 && sample.color.g == 0x48
          && sample.color.b == 0x4d && sample.color.a == 0xff);
    CHECK(renderer->sample(scene, 0.0f, {5.0f, 5.0f}, candidates, 2u, sample)
          == Result::InsufficientCondition);
    CHECK(!sample.object && sample.color.a == 0u);
    CHECK(renderer->sample(scene, 0.0f, {-1.0f, 5.0f}, candidates, 2u, sample)
          == Result::InvalidArguments);
    delete scene;
}

static Scene* _numberScene(NumberMode mode, bool numbers)
{
    Config config;
    config.width = 320;
    config.height = 180;
    config.camera.orthoHeight = 4.0f;
    auto scene = Scene::gen(config);
    auto space = Space::gen({0.0f, 3.0f, 1.0f}, {0.0f, 2.0f, 1.0f}, {0.0f, 0.0f, 1.0f});
    if (!scene || !space) {
        delete scene;
        delete space;
        return nullptr;
    }
    space->style.stroke.a = 0;
    space->axisX.a = 0;
    space->axisY.a = 0;
    space->axisZ.a = 0;
    space->numbers = numbers;
    space->numberMode = mode;
    space->numberSize = 15.0f;
    space->model = Mat4::scale({0.5f, 0.5f, 1.0f});
    if (scene->add(space) != Result::Success) {
        delete scene;
        delete space;
        return nullptr;
    }
    return scene;
}

static void spaceNumbers(SwRenderer* renderer)
{
#ifdef TMATH_TEST_FONT
    CHECK(renderer->font(TMATH_TEST_FONT) == Result::Success);
#endif
    auto hidden = _numberScene(NumberMode::Fixed, false);
    auto fixed = _numberScene(NumberMode::Fixed, true);
    auto relative = _numberScene(NumberMode::Relative, true);
    CHECK(hidden && fixed && relative);
    if (hidden && fixed && relative) {
        Surface hiddenSurface;
        Surface fixedSurface;
        Surface relativeSurface;
        CHECK(renderer->render(hidden, 0.0f, hiddenSurface) == Result::Success);
        CHECK(renderer->render(fixed, 0.0f, fixedSurface) == Result::Success);
        CHECK(renderer->render(relative, 0.0f, relativeSurface) == Result::Success);
        CHECK(changed(hiddenSurface, hidden->config().background) == 0);
        CHECK(changed(fixedSurface, fixed->config().background) > 50);
        CHECK(checksum(fixedSurface) != checksum(relativeSurface));
    }
    delete hidden;
    delete fixed;
    delete relative;
}

static void textAnimationRegression(SwRenderer* renderer)
{
    Config config;
    config.width = 160;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto rectangle = Rectangle::gen({-1.25f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto text = Text::gen("A", {1.25f, 0.0f, 0.0f});
    CHECK(scene && rectangle && text);
    if (scene && rectangle && text) {
        rectangle->stroke(Color::hex("#4cc9f0"), 3.0f).fill(Color::hex("#4cc9f044"));
        text->size = 30.0f;
        text->fill(Color::hex("#ffd166"));
        auto rectangleResult = scene->add(rectangle);
        auto textResult = scene->add(text);
        CHECK(rectangleResult == Result::Success && textResult == Result::Success);
        if (rectangleResult == Result::Success && textResult == Result::Success) {
            Animation prepare[] = {
                Animation::shift(rectangle, {0.25f, 0.0f, 0.0f}),
                Animation::shift(text, {0.25f, 0.0f, 0.0f})};
            CHECK(scene->play(prepare, 2u, 0.5f, Easing::Linear) == Result::Success);
            CHECK(scene->wait(0.5f) == Result::Success);
            Animation create[] = {Animation::create(rectangle), Animation::create(text)};
            CHECK(scene->play(create, 2u, 1.0f, Easing::Linear) == Result::Success);

            Surface surface;
            CHECK(renderer->render(scene, 0.25f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(scene, 0.75f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(scene, 1.5f, surface) == Result::Success);
            auto left = 0u;
            auto right = 0u;
            auto background = pixel(config.background);
            for (auto y = 0u; y < surface.height(); y++) {
                for (auto x = 0u; x < surface.width(); x++) {
                    if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] == background) continue;
                    if (x < surface.width() / 2u) left++;
                    else right++;
                }
            }
            CHECK(left > 0u);
            CHECK(right > 0u);
        } else {
            if (rectangleResult != Result::Success) delete rectangle;
            if (textResult != Result::Success) delete text;
        }
    } else {
        delete rectangle;
        delete text;
    }
    delete scene;

    auto motion = Scene::gen(config);
    auto group = Group::gen();
    auto body = Rectangle::gen({-1.25f, 0.0f, 0.0f}, {0.8f, 0.8f});
    auto label = Text::gen("A", {0.75f, 0.0f, 0.0f});
    CHECK(motion && group && body && label);
    if (motion && group && body && label) {
        auto bodyColor = Color::hex("#ef5350");
        auto labelColor = Color::hex("#42a5f5");
        body->style.stroke.a = 0;
        body->fill(bodyColor);
        label->size = 30.0f;
        label->fill(labelColor);
        auto bodyResult = group->add(body);
        auto labelResult = group->add(label);
        CHECK(bodyResult == Result::Success && labelResult == Result::Success);
        auto groupResult = bodyResult == Result::Success && labelResult == Result::Success
                         ? motion->add(group) : Result::InvalidArguments;
        CHECK(groupResult == Result::Success);
        if (groupResult == Result::Success) {
            CHECK(motion->play(Animation::shift(group, {1.0f, 0.0f, 0.0f}), 1.0f,
                               Easing::Linear) == Result::Success);
            auto centerX = [](const Surface& surface, Color color) {
                auto target = pixel(color);
                auto sum = 0u;
                auto count = 0u;
                for (auto y = 0u; y < surface.height(); y++) {
                    for (auto x = 0u; x < surface.width(); x++) {
                        if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] != target) continue;
                        sum += x;
                        count++;
                    }
                }
                return count ? static_cast<float>(sum) / static_cast<float>(count) : -1.0f;
            };
            Surface surface;
            CHECK(renderer->render(motion, 0.0f, surface) == Result::Success);
            auto bodyStart = centerX(surface, bodyColor);
            auto labelStart = centerX(surface, labelColor);
            CHECK(renderer->render(motion, 0.5f, surface) == Result::Success);
            auto bodyMiddle = centerX(surface, bodyColor);
            auto labelMiddle = centerX(surface, labelColor);
            CHECK(renderer->render(motion, 1.0f, surface) == Result::Success);
            auto bodyEnd = centerX(surface, bodyColor);
            auto labelEnd = centerX(surface, labelColor);
            CHECK(bodyStart >= 0.0f && labelStart >= 0.0f);
            CHECK(bodyMiddle >= 0.0f && labelMiddle >= 0.0f);
            CHECK(bodyEnd >= 0.0f && labelEnd >= 0.0f);
            CHECK(near(labelStart - bodyStart, labelMiddle - bodyMiddle, 1.0f));
            CHECK(near(labelMiddle - bodyMiddle, labelEnd - bodyEnd, 1.0f));
        } else {
            if (bodyResult != Result::Success) delete body;
            if (labelResult != Result::Success) delete label;
            delete group;
        }
    } else {
        delete group;
        delete body;
        delete label;
    }
    delete motion;
}

static void repeatedCreateRegression(SwRenderer* renderer)
{
    Config config;
    config.width = 96;
    config.height = 64;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto rectangle = Rectangle::gen({0.0f, 0.0f, 0.0f}, {1.5f, 1.0f});
    CHECK(scene && rectangle);
    if (scene && rectangle) {
        rectangle->style.stroke.a = 0;
        rectangle->fill(Color::hex("#4cc9f0"));
        auto addResult = scene->add(rectangle);
        CHECK(addResult == Result::Success);
        if (addResult == Result::Success) {
            CHECK(scene->play(Animation::create(rectangle), 0.5f, Easing::Linear) == Result::Success);
            CHECK(scene->wait(0.5f) == Result::Success);
            CHECK(scene->play(Animation::create(rectangle), 0.5f, Easing::Linear) == Result::Success);

            Surface surface;
            CHECK(renderer->render(scene, 0.75f, surface) == Result::Success);
            CHECK(changed(surface, config.background) > 0u);
        } else {
            delete rectangle;
        }
    } else {
        delete rectangle;
    }
    delete scene;
}

static void drawDirectionAnimations(SwRenderer* renderer)
{
    Config config;
    config.width = 160;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;

    auto circles = Scene::gen(config);
    auto forward = Circle::gen({-1.1f, 0.0f, 0.0f}, 0.7f);
    auto clockwise = Circle::gen({1.1f, 0.0f, 0.0f}, 0.7f);
    CHECK(circles && forward && clockwise);
    if (circles && forward && clockwise) {
        forward->stroke(Color::hex("#f5f5f5"), 4.0f);
        forward->style.fill.a = 0;
        clockwise->stroke(Color::hex("#f5f5f5"), 4.0f);
        clockwise->style.fill.a = 0;
        auto forwardResult = circles->add(forward);
        auto clockwiseResult = circles->add(clockwise);
        CHECK(forwardResult == Result::Success && clockwiseResult == Result::Success);
        if (forwardResult == Result::Success && clockwiseResult == Result::Success) {
            Animation animations[] = {
                Animation::create(forward, DrawDirection::Forward),
                Animation::create(clockwise, DrawDirection::Clockwise)};
            CHECK(circles->play(animations, 2u, 1.0f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(circles, 0.25f, surface) == Result::Success);
            auto background = pixel(config.background);
            auto forwardUpper = 0u;
            auto forwardLower = 0u;
            auto clockwiseUpper = 0u;
            auto clockwiseLower = 0u;
            for (auto y = 0u; y < surface.height(); y++) {
                for (auto x = 0u; x < surface.width(); x++) {
                    if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] == background) continue;
                    if (x < surface.width() / 2u) {
                        if (y < surface.height() / 2u) forwardUpper++;
                        else forwardLower++;
                    } else {
                        if (y < surface.height() / 2u) clockwiseUpper++;
                        else clockwiseLower++;
                    }
                }
            }
            CHECK(forwardUpper > forwardLower + 10u);
            CHECK(clockwiseLower > clockwiseUpper + 10u);
        } else {
            if (forwardResult != Result::Success) delete forward;
            if (clockwiseResult != Result::Success) delete clockwise;
        }
    } else {
        delete forward;
        delete clockwise;
    }
    delete circles;

    auto reverseScene = Scene::gen(config);
    auto reverse = Line::gen({-1.5f, 0.0f, 0.0f}, {1.5f, 0.0f, 0.0f});
    CHECK(reverseScene && reverse);
    if (reverseScene && reverse) {
        reverse->stroke(Color::hex("#4cc9f0"), 5.0f);
        auto result = reverseScene->add(reverse);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(reverseScene->play(Animation::create(reverse, DrawDirection::Reverse), 1.0f,
                                     Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(reverseScene, 0.25f, surface) == Result::Success);
            auto background = pixel(config.background);
            auto left = 0u;
            auto right = 0u;
            for (auto y = 0u; y < surface.height(); y++) {
                for (auto x = 0u; x < surface.width(); x++) {
                    if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] == background) continue;
                    if (x < surface.width() / 2u) left++;
                    else right++;
                }
            }
            CHECK(left == 0u);
            CHECK(right > 20u);
        } else {
            delete reverse;
        }
    } else {
        delete reverse;
    }
    delete reverseScene;

    auto frames = [&](Object* object, DrawDirection direction, uint64_t& middle,
                      uint64_t& end, uint32_t& pixels) {
        auto scene = Scene::gen(config);
        if (!scene || !object) {
            delete object;
            delete scene;
            return false;
        }
        if (scene->add(object) != Result::Success) {
            delete object;
            delete scene;
            return false;
        }
        if (scene->play(Animation::create(object, direction), 1.0f, Easing::Linear)
            != Result::Success) {
            delete scene;
            return false;
        }
        Surface surface;
        if (renderer->render(scene, 0.25f, surface) != Result::Success) {
            delete scene;
            return false;
        }
        middle = checksum(surface);
        if (renderer->render(scene, 1.0f, surface) != Result::Success) {
            delete scene;
            return false;
        }
        end = checksum(surface);
        pixels = changed(surface, config.background);
        delete scene;
        return true;
    };
    auto arrow = []() {
        auto object = Arrow::gen({-1.5f, -0.4f, 0.0f}, {1.5f, 0.5f, 0.0f});
        if (!object) return object;
        object->tail = 7.0f;
        object->tip = 19.0f;
        object->stroke(Color::hex("#ffd166"), 4.0f);
        return object;
    };
    auto vector = []() {
        auto object = Vector::gen({3.0f, 0.9f, 0.0f}, {-1.5f, -0.4f, 0.0f});
        if (!object) return object;
        object->tail = 9.0f;
        object->tip = 17.0f;
        object->stroke(Color::hex("#4cc9f0"), 4.0f);
        return object;
    };
    auto forwardMiddle = uint64_t{0};
    auto forwardEnd = uint64_t{0};
    auto forwardPixels = 0u;
    auto reverseMiddle = uint64_t{0};
    auto reverseEnd = uint64_t{0};
    auto reversePixels = 0u;
    CHECK(frames(arrow(), DrawDirection::Forward, forwardMiddle, forwardEnd, forwardPixels));
    CHECK(frames(arrow(), DrawDirection::Reverse, reverseMiddle, reverseEnd, reversePixels));
    CHECK(forwardMiddle != reverseMiddle);
    CHECK(forwardEnd == reverseEnd);
    CHECK(forwardPixels > 0u && forwardPixels == reversePixels);
    CHECK(frames(vector(), DrawDirection::Forward, forwardMiddle, forwardEnd, forwardPixels));
    CHECK(frames(vector(), DrawDirection::Reverse, reverseMiddle, reverseEnd, reversePixels));
    CHECK(forwardMiddle != reverseMiddle);
    CHECK(forwardEnd == reverseEnd);
    CHECK(forwardPixels > 0u && forwardPixels == reversePixels);

    auto revealScene = Scene::gen(config);
    auto line = Line::gen({-1.5f, 0.0f, 0.0f}, {1.5f, 0.0f, 0.0f});
    CHECK(revealScene && line);
    if (revealScene && line) {
        line->stroke(Color::hex("#ffd166"), 5.0f);
        auto result = revealScene->add(line);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(revealScene->play(Animation::create(line), 1.0f, Easing::Linear) == Result::Success);
            CHECK(revealScene->play(Animation::uncreate(line), 1.0f, Easing::Linear) == Result::Success);
            CHECK(revealScene->play(Animation::create(line), 1.0f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(revealScene, 0.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(revealScene, 0.5f, surface) == Result::Success);
            auto creating = changed(surface, config.background);
            CHECK(renderer->render(revealScene, 1.0f, surface) == Result::Success);
            auto created = changed(surface, config.background);
            CHECK(renderer->render(revealScene, 1.5f, surface) == Result::Success);
            auto uncreating = changed(surface, config.background);
            CHECK(renderer->render(revealScene, 2.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(revealScene, 2.5f, surface) == Result::Success);
            auto recreated = changed(surface, config.background);
            CHECK(creating > 0u && creating < created);
            CHECK(uncreating > 0u && uncreating < created);
            CHECK(recreated > 0u && recreated < created);
        } else {
            delete line;
        }
    } else {
        delete line;
    }
    delete revealScene;
}

static void arrowCompositing(SwRenderer* renderer)
{
    Config config;
    config.width = 200u;
    config.height = 100u;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#ffffff");
    config.antialiasing = false;

    auto scene = Scene::gen(config);
    auto arrow = Arrow::gen({-3.0f, 0.0f, 0.0f}, {3.0f, 0.0f, 0.0f});
    CHECK(scene && arrow);
    if (scene && arrow) {
        arrow->tip = 20.0f;
        arrow->stroke(Color::hex("#ff0000"), 8.0f);
        CHECK(scene->add(arrow) == Result::Success);
        CHECK(scene->play(Animation::fade(arrow, 0.5f), 1.0f, Easing::Linear)
              == Result::Success);
        Surface surface;
        CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
        auto shaft = surface.data()[50u * surface.stride() + 100u];
        auto junction = surface.data()[50u * surface.stride() + 158u];
        CHECK(shaft == junction);
    } else {
        delete arrow;
    }
    delete scene;

    scene = Scene::gen(config);
    arrow = Arrow::gen({-3.0f, 0.0f, 0.0f}, {3.0f, 0.0f, 0.0f});
    CHECK(scene && arrow);
    if (scene && arrow) {
        float pattern[] = {1000.0f, 1.0f};
        arrow->tail = 16.0f;
        arrow->tip = 20.0f;
        arrow->stroke(Color::hex("#2563eb"), 8.0f);
        CHECK(arrow->dash(pattern, 2u) == Result::Success);
        CHECK(scene->add(arrow) == Result::Success);
        CHECK(scene->play(Animation::fade(arrow, 0.5f), 1.0f, Easing::Linear)
              == Result::Success);
        Surface surface;
        CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
        auto shaft = surface.data()[50u * surface.stride() + 100u];
        auto tail = surface.data()[50u * surface.stride() + 31u];
        auto tip = surface.data()[50u * surface.stride() + 169u];
        CHECK(shaft == tail);
        CHECK(shaft == tip);
    } else {
        delete arrow;
    }
    delete scene;
}

static void directedRouteRendering(SwRenderer* renderer)
{
    Config config;
    config.width = 200u;
    config.height = 100u;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#ffffff");
    config.antialiasing = false;
    auto foreground = pixel(Color::hex("#2563eb"));

    auto scene = Scene::gen(config);
    auto arrow = Arrow::gen({-3.0f, 0.0f, 0.0f}, {3.0f, 0.0f, 0.0f});
    CHECK(scene && arrow);
    if (scene && arrow) {
        float pattern[] = {12.0f, 8.0f};
        arrow->tail = 12.0f;
        arrow->tip = 20.0f;
        arrow->stroke(Color::hex("#2563eb"), 4.0f);
        CHECK(arrow->dash(pattern, 2u) == Result::Success);
        CHECK(scene->add(arrow) == Result::Success);
        CHECK(scene->play(Animation::create(arrow), 1.0f, Easing::Linear)
              == Result::Success);
        auto phase = AnimationTarget::from(arrow);
        phase.dashOffset(-8.0f).tail(18.0f).tip(26.0f);
        CHECK(scene->play(phase, 1.0f, Easing::Linear) == Result::Success);
        CHECK(near(arrow->tail, 18.0f) && near(arrow->tip, 26.0f));
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, config.background) == 0u);
        CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
        auto partial = changed(surface, config.background);
        CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
        auto complete = changed(surface, config.background);
        auto firstPhase = checksum(surface);
        CHECK(surface.data()[50u * surface.stride() + 31u] == foreground);
        CHECK(surface.data()[50u * surface.stride() + 165u] == foreground);
        CHECK(renderer->render(scene, 2.0f, surface) == Result::Success);
        CHECK(checksum(surface) != firstPhase);
        CHECK(surface.data()[50u * surface.stride() + 31u] == foreground);
        CHECK(surface.data()[50u * surface.stride() + 165u] == foreground);
        CHECK(partial > 0u && partial < complete);
    } else {
        delete arrow;
    }
    delete scene;

    Vec3 points[] = {
        {-3.0f, 1.0f, 0.0f}, {0.0f, 1.0f, 0.0f},
        {0.0f, -1.0f, 0.0f}, {3.0f, -1.0f, 0.0f},
    };
    scene = Scene::gen(config);
    auto route = DirectedRoute::gen(points, 4u);
    CHECK(scene && route && route->type() == Type::Route && route->count() == 4u);
    if (scene && route) {
        float pattern[] = {10.0f, 6.0f};
        route->tail = 10.0f;
        route->tip = 18.0f;
        route->stroke(Color::hex("#2563eb"), 4.0f);
        CHECK(route->dash(pattern, 2u) == Result::Success);
        CHECK(scene->add(route) == Result::Success);
        CHECK(scene->play(Animation::create(route), 1.0f, Easing::Linear)
              == Result::Success);
        Surface surface;
        CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
        auto partial = changed(surface, config.background);
        CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
        auto complete = changed(surface, config.background);
        CHECK(partial > 0u && partial < complete);
        BBox bounds;
        CHECK(renderer->bounds(scene, route, 1.0f, bounds) == Result::Success);
        CHECK(bounds.width > 140.0f && bounds.height > 40.0f);
    } else {
        delete route;
    }
    delete scene;
}

static void fadeAnimations(SwRenderer* renderer)
{
    Config config;
    config.width = 160;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;

    auto entrance = Scene::gen(config);
    auto entering = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    CHECK(entrance && entering);
    if (entrance && entering) {
        entering->style.stroke.a = 0;
        entering->fill(Color::hex("#4cc9f0"));
        auto result = entrance->add(entering);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(entrance->play(Animation::shift(entering, {1.5f, 0.0f, 0.0f}), 0.5f,
                                 Easing::Linear) == Result::Success);
            CHECK(entrance->wait(0.5f) == Result::Success);
            CHECK(entrance->play(Animation::fadeIn(entering, {-0.5f, 0.0f, 0.0f}, 0.8f),
                                 1.0f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(entrance, 0.25f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(entrance, 0.75f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(entrance, 1.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(entrance, 1.5f, surface) == Result::Success);
            CHECK(changed(surface, config.background) > 0u);
            CHECK(renderer->render(entrance, 2.0f, surface) == Result::Success);
            auto finalExtent = extent(surface, config.background);
            CHECK(finalExtent.valid);
            if (finalExtent.valid) CHECK(finalExtent.minX >= surface.width() / 2u);
        } else {
            delete entering;
        }
    } else {
        delete entering;
    }
    delete entrance;

    auto exit = Scene::gen(config);
    auto exiting = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    CHECK(exit && exiting);
    if (exit && exiting) {
        exiting->style.stroke.a = 0;
        exiting->fill(Color::hex("#ef5350"));
        auto result = exit->add(exiting);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(exit->play(Animation::fadeOut(exiting, {2.0f, 0.0f, 0.0f}), 1.0f,
                             Easing::Linear) == Result::Success);
            CHECK(exit->play(Animation::fadeIn(exiting), 0.5f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(exit, 0.0f, surface) == Result::Success);
            auto start = extent(surface, config.background);
            CHECK(renderer->render(exit, 0.5f, surface) == Result::Success);
            auto middle = extent(surface, config.background);
            CHECK(renderer->render(exit, 1.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(exit, 1.5f, surface) == Result::Success);
            CHECK(changed(surface, config.background) > 0u);
            CHECK(start.valid && middle.valid);
            if (start.valid && middle.valid) {
                auto startCenter = (start.minX + start.maxX) / 2u;
                auto middleCenter = (middle.minX + middle.maxX) / 2u;
                CHECK(middleCenter > startCenter + 10u);
            }
        } else {
            delete exiting;
        }
    } else {
        delete exiting;
    }
    delete exit;

    auto handoff = Scene::gen(config);
    auto source = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto target = Circle::gen({1.0f, 0.0f, 0.0f}, 0.5f);
    CHECK(handoff && source && target);
    if (handoff && source && target) {
        source->style.stroke.a = 0;
        source->fill(Color::hex("#ef5350"));
        target->style.stroke.a = 0;
        target->fill(Color::hex("#42a5f5"));
        auto sourceResult = handoff->add(source);
        auto targetResult = handoff->add(target);
        CHECK(sourceResult == Result::Success && targetResult == Result::Success);
        if (sourceResult == Result::Success && targetResult == Result::Success) {
            CHECK(handoff->fadeTransform(source, target, 1.0f, Easing::Linear)
                  == Result::Success);
            CHECK(near(handoff->duration(), 1.0f));
            CHECK(handoff->play(Animation::fadeOut(source), 0.25f, Easing::Linear)
                  == Result::InvalidArguments);
            CHECK(handoff->play(Animation::indicate(target), 0.25f, Easing::Linear)
                  == Result::Success);

            Surface surface;
            auto halves = [&](float time) {
                CHECK(renderer->render(handoff, time, surface) == Result::Success);
                auto background = pixel(config.background);
                auto left = 0u;
                auto right = 0u;
                for (auto y = 0u; y < surface.height(); y++) {
                    for (auto x = 0u; x < surface.width(); x++) {
                        if (surface.data()[static_cast<size_t>(y) * surface.stride() + x]
                            == background) continue;
                        if (x < surface.width() / 2u) left++;
                        else right++;
                    }
                }
                return Vec2{static_cast<float>(left), static_cast<float>(right)};
            };
            auto start = halves(0.0f);
            auto middle = halves(0.5f);
            auto end = halves(1.0f);
            CHECK(start.x > 0.0f && start.y == 0.0f);
            CHECK(middle.x > 0.0f && middle.y > 0.0f);
            CHECK(end.x == 0.0f && end.y > 0.0f);
        } else {
            if (sourceResult != Result::Success) delete source;
            if (targetResult != Result::Success) delete target;
        }
    } else {
        delete source;
        delete target;
    }
    delete handoff;

    auto invalid = Scene::gen(config);
    auto staleSource = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto staleTarget = Circle::gen({1.0f, 0.0f, 0.0f}, 0.5f);
    auto foreignScene = Scene::gen(config);
    auto foreignTarget = Circle::gen({}, 0.5f);
    CHECK(invalid && staleSource && staleTarget && foreignScene && foreignTarget);
    if (invalid && staleSource && staleTarget && foreignScene && foreignTarget) {
        auto sourceResult = invalid->add(staleSource);
        auto targetResult = invalid->add(staleTarget);
        auto foreignResult = foreignScene->add(foreignTarget);
        CHECK(sourceResult == Result::Success && targetResult == Result::Success
              && foreignResult == Result::Success);
        if (sourceResult == Result::Success && targetResult == Result::Success
            && foreignResult == Result::Success) {
            CHECK(invalid->fadeTransform(staleSource, staleSource)
                  == Result::InvalidArguments);
            CHECK(invalid->fadeTransform(staleSource, foreignTarget)
                  == Result::InvalidArguments);
            CHECK(invalid->wait(0.1f) == Result::Success);
            CHECK(invalid->fadeTransform(staleSource, staleTarget)
                  == Result::InsufficientCondition);
            CHECK(near(invalid->duration(), 0.1f));
        } else {
            if (sourceResult != Result::Success) delete staleSource;
            if (targetResult != Result::Success) delete staleTarget;
            if (foreignResult != Result::Success) delete foreignTarget;
        }
    } else {
        delete staleSource;
        delete staleTarget;
        delete foreignTarget;
    }
    delete foreignScene;
    delete invalid;
}

static void scaleAndIndicateAnimations(SwRenderer* renderer)
{
    Config config;
    config.width = 200;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;

    auto scene = Scene::gen(config);
    auto group = Group::gen();
    auto body = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto label = Text::gen("A", {1.0f, 0.0f, 0.0f});
    CHECK(scene && group && body && label);
    if (scene && group && body && label) {
        body->style.stroke.a = 0;
        body->fill(Color::hex("#ef5350"));
        label->size = 36.0f;
        label->fill(Color::hex("#42a5f5"));
        auto bodyResult = group->add(body);
        auto labelResult = group->add(label);
        CHECK(bodyResult == Result::Success && labelResult == Result::Success);
        auto groupResult = bodyResult == Result::Success && labelResult == Result::Success
                         ? scene->add(group) : Result::InvalidArguments;
        CHECK(groupResult == Result::Success);
        if (groupResult == Result::Success) {
            CHECK(scene->play(Animation::growFromCenter(group), 1.0f, Easing::Linear)
                  == Result::Success);
            CHECK(scene->play(Animation::shrinkToCenter(group), 1.0f, Easing::Linear)
                  == Result::Success);
            auto halves = [&](const Surface& surface) {
                auto background = pixel(config.background);
                auto left = 0u;
                auto right = 0u;
                for (auto y = 0u; y < surface.height(); y++) {
                    for (auto x = 0u; x < surface.width(); x++) {
                        if (surface.data()[static_cast<size_t>(y) * surface.stride() + x] == background) continue;
                        if (x < surface.width() / 2u) left++;
                        else right++;
                    }
                }
                return Vec2{static_cast<float>(left), static_cast<float>(right)};
            };
            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
            auto growExtent = extent(surface, config.background);
            auto growHalves = halves(surface);
            CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
            auto fullExtent = extent(surface, config.background);
            auto fullHalves = halves(surface);
            CHECK(renderer->render(scene, 1.5f, surface) == Result::Success);
            auto shrinkExtent = extent(surface, config.background);
            auto shrinkHalves = halves(surface);
            CHECK(renderer->render(scene, 2.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(growExtent.valid && fullExtent.valid && shrinkExtent.valid);
            if (growExtent.valid && fullExtent.valid && shrinkExtent.valid) {
                CHECK(growExtent.maxX - growExtent.minX < fullExtent.maxX - fullExtent.minX);
                CHECK(shrinkExtent.maxX - shrinkExtent.minX < fullExtent.maxX - fullExtent.minX);
                CHECK(growExtent.maxY - growExtent.minY < fullExtent.maxY - fullExtent.minY);
                CHECK(shrinkExtent.maxY - shrinkExtent.minY < fullExtent.maxY - fullExtent.minY);
            }
            CHECK(growHalves.x > 0.0f && fullHalves.x > growHalves.x);
            CHECK(shrinkHalves.x > 0.0f && fullHalves.x > shrinkHalves.x);
            if (fullHalves.y > 0.0f) {
                CHECK(growHalves.y > 0.0f && fullHalves.y > growHalves.y);
                CHECK(shrinkHalves.y > 0.0f && fullHalves.y > shrinkHalves.y);
            }
        } else {
            if (bodyResult != Result::Success) delete body;
            if (labelResult != Result::Success) delete label;
            delete group;
        }
    } else {
        delete group;
        delete body;
        delete label;
    }
    delete scene;

    config.width = 160;
    config.height = 120;
    config.camera.orthoHeight = 4.0f;
    auto edgeScene = Scene::gen(config);
    auto edgeBar = Rectangle::gen({0.0f, 0.0f, 0.0f}, {1.0f, 2.0f});
    CHECK(edgeScene && edgeBar);
    if (edgeScene && edgeBar) {
        edgeBar->style.stroke.a = 0;
        edgeBar->fill(Color::hex("#40d890"));
        auto result = edgeScene->add(edgeBar);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(edgeScene->play(Animation::growFromEdge(edgeBar, GrowthEdge::Bottom),
                                  1.0f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(edgeScene, 0.5f, surface) == Result::Success);
            auto middleExtent = extent(surface, config.background);
            CHECK(renderer->render(edgeScene, 1.0f, surface) == Result::Success);
            auto finalExtent = extent(surface, config.background);
            CHECK(middleExtent.valid && finalExtent.valid);
            if (middleExtent.valid && finalExtent.valid) {
                auto nearPixel = [](uint32_t lhs, uint32_t rhs) {
                    return lhs > rhs ? lhs - rhs <= 1u : rhs - lhs <= 1u;
                };
                CHECK(nearPixel(middleExtent.maxY, finalExtent.maxY));
                CHECK(middleExtent.maxY - middleExtent.minY
                      < finalExtent.maxY - finalExtent.minY);
                CHECK(nearPixel(middleExtent.maxX, finalExtent.maxX));
                CHECK(nearPixel(middleExtent.minX, finalExtent.minX));
            }
        } else {
            delete edgeBar;
        }
    } else {
        delete edgeBar;
    }
    delete edgeScene;

    config.width = 160;
    config.height = 80;
    auto indicateScene = Scene::gen(config);
    auto indicated = Rectangle::gen({}, {1.4f, 0.8f});
    CHECK(indicateScene && indicated);
    if (indicateScene && indicated) {
        indicated->style.stroke.a = 0;
        indicated->fill(Color::hex("#40d890"));
        auto result = indicateScene->add(indicated);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(indicateScene->play(Animation::indicate(indicated, Color::hex("#ffd166"), 1.4f),
                                      1.0f, Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(indicateScene, 0.0f, surface) == Result::Success);
            auto startHash = checksum(surface);
            auto startPixels = changed(surface, config.background);
            auto startExtent = extent(surface, config.background);
            CHECK(renderer->render(indicateScene, 0.5f, surface) == Result::Success);
            auto middleHash = checksum(surface);
            auto middlePixels = changed(surface, config.background);
            auto middleExtent = extent(surface, config.background);
            CHECK(renderer->render(indicateScene, 1.0f, surface) == Result::Success);
            auto endHash = checksum(surface);
            CHECK(startHash == endHash);
            CHECK(startHash != middleHash);
            CHECK(middlePixels > startPixels);
            CHECK(startExtent.valid && middleExtent.valid);
            if (startExtent.valid && middleExtent.valid) {
                CHECK(middleExtent.maxX - middleExtent.minX > startExtent.maxX - startExtent.minX);
                CHECK(middleExtent.maxY - middleExtent.minY > startExtent.maxY - startExtent.minY);
            }
        } else {
            delete indicated;
        }
    } else {
        delete indicated;
    }
    delete indicateScene;
}

static void morphAnimations(SwRenderer* renderer)
{
    Config config;
    config.width = 160;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;

    Vec3 sourcePoints[] = {
        {-1.8f, -0.5f, 0.0f}, {-0.8f, -0.5f, 0.0f},
        {-0.8f, 0.5f, 0.0f}, {-1.8f, 0.5f, 0.0f}};
    Vec3 targetPoints[] = {
        {1.0f, -0.9f, 0.0f}, {1.8f, 0.0f, 0.0f},
        {1.0f, 0.9f, 0.0f}, {0.2f, 0.0f, 0.0f}};
    auto scene = Scene::gen(config);
    auto source = Polygon::gen(sourcePoints, 4u);
    auto target = Polygon::gen(targetPoints, 4u);
    CHECK(scene && source && target);
    if (scene && source && target) {
        auto sourceColor = Color::hex("#ef5350");
        auto targetColor = Color::hex("#42a5f5");
        source->style.stroke.a = 0;
        source->fill(sourceColor);
        target->style.stroke.a = 0;
        target->fill(targetColor);
        auto sourceResult = scene->add(source);
        auto targetResult = scene->add(target);
        CHECK(sourceResult == Result::Success && targetResult == Result::Success);
        if (sourceResult == Result::Success && targetResult == Result::Success) {
            CHECK(scene->play(Animation::replacementTransform(source, target), 1.0f,
                              Easing::Linear) == Result::Success);
            CHECK(near(scene->duration(), 1.0f));
            auto targetModel = target->model;
            auto targetFill = target->style.fill;
            target->model = Mat4::translate({0.25f, 0.0f, 0.0f}) * target->model;
            target->style.fill = Color::hex("#ffffff");
            Surface invalidSurface;
            CHECK(renderer->render(scene, 0.5f, invalidSurface) == Result::InvalidArguments);
            target->model = targetModel;
            target->style.fill = targetFill;
            CHECK(renderer->render(scene, 0.5f, invalidSurface) == Result::Success);
            CHECK(scene->play(Animation::fadeOut(source), 0.25f, Easing::Linear)
                  == Result::InvalidArguments);
            CHECK(near(scene->duration(), 1.0f));
            CHECK(scene->play(Animation::indicate(target), 0.5f, Easing::Linear)
                  == Result::Success);
            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            auto startHash = checksum(surface);
            auto start = extent(surface, config.background);
            auto startRed = 0u;
            for (auto i = 0u; i < surface.width() * surface.height(); i++) {
                if (surface.data()[i] == pixel(sourceColor)) startRed++;
            }
            CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
            auto middleHash = checksum(surface);
            auto middle = extent(surface, config.background);
            CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
            auto endHash = checksum(surface);
            auto end = extent(surface, config.background);
            auto endBlue = 0u;
            auto endRed = 0u;
            for (auto i = 0u; i < surface.width() * surface.height(); i++) {
                if (surface.data()[i] == pixel(targetColor)) endBlue++;
                if (surface.data()[i] == pixel(sourceColor)) endRed++;
            }
            CHECK(startHash != middleHash && middleHash != endHash && startHash != endHash);
            CHECK(startRed > 0u && endBlue > 0u && endRed == 0u);
            CHECK(start.valid && middle.valid && end.valid);
            if (start.valid && middle.valid && end.valid) {
                auto startCenter = (start.minX + start.maxX) / 2u;
                auto middleCenter = (middle.minX + middle.maxX) / 2u;
                auto endCenter = (end.minX + end.maxX) / 2u;
                CHECK(startCenter < middleCenter && middleCenter < endCenter);
            }
        } else {
            if (sourceResult != Result::Success) delete source;
            if (targetResult != Result::Success) delete target;
        }
    } else {
        delete source;
        delete target;
    }
    delete scene;

    Vec3 mismatchPoints[] = {
        {-0.5f, -0.5f, 0.0f}, {0.5f, -0.5f, 0.0f}, {0.0f, 0.5f, 0.0f}};
    auto atomic = Scene::gen(config);
    auto atomicSource = Polygon::gen(sourcePoints, 4u);
    auto atomicTarget = Polygon::gen(targetPoints, 4u);
    auto mismatch = Polygon::gen(mismatchPoints, 3u);
    auto unsupportedSource = Circle::gen({-2.5f, 0.0f, 0.0f}, 0.25f);
    auto unsupportedTarget = Circle::gen({2.5f, 0.0f, 0.0f}, 0.25f);
    auto foreignScene = Scene::gen(config);
    auto foreign = Polygon::gen(targetPoints, 4u);
    CHECK(atomic && atomicSource && atomicTarget && mismatch && unsupportedSource
          && unsupportedTarget && foreignScene && foreign);
    if (atomic && atomicSource && atomicTarget && mismatch && unsupportedSource
        && unsupportedTarget && foreignScene && foreign) {
        auto sourceResult = atomic->add(atomicSource);
        auto targetResult = atomic->add(atomicTarget);
        auto mismatchResult = atomic->add(mismatch);
        auto unsupportedSourceResult = atomic->add(unsupportedSource);
        auto unsupportedTargetResult = atomic->add(unsupportedTarget);
        auto foreignResult = foreignScene->add(foreign);
        CHECK(sourceResult == Result::Success && targetResult == Result::Success
              && mismatchResult == Result::Success
              && unsupportedSourceResult == Result::Success
              && unsupportedTargetResult == Result::Success
              && foreignResult == Result::Success);
        if (sourceResult == Result::Success && targetResult == Result::Success
            && mismatchResult == Result::Success
            && unsupportedSourceResult == Result::Success
            && unsupportedTargetResult == Result::Success
            && foreignResult == Result::Success) {
            Surface surface;
            CHECK(renderer->render(atomic, 0.0f, surface) == Result::Success);
            auto initial = checksum(surface);
            Animation unsupported[] = {
                Animation::fade(atomicTarget, 0.25f),
                Animation::morph(unsupportedSource, unsupportedTarget)};
            CHECK(atomic->play(unsupported, 2u, 1.0f, Easing::Linear)
                  == Result::NonSupport);
            CHECK(near(atomic->duration(), 0.0f));
            CHECK(near(atomicTarget->opacity, 1.0f));
            CHECK(renderer->render(atomic, 0.0f, surface) == Result::Success);
            CHECK(checksum(surface) == initial);
            CHECK(atomic->play(Animation::morph(atomicSource, atomicSource))
                  == Result::InvalidArguments);
            CHECK(atomic->play(Animation::morph(atomicSource, mismatch))
                  == Result::NonSupport);
            CHECK(atomic->play(Animation::morph(atomicSource, foreign))
                  == Result::InvalidArguments);
            CHECK(near(atomic->duration(), 0.0f));
            CHECK(renderer->render(atomic, 0.0f, surface) == Result::Success);
            CHECK(checksum(surface) == initial);
            CHECK(atomic->play(Animation::morph(atomicSource, atomicTarget), 1.0f,
                               Easing::Linear) == Result::Success);
        } else {
            if (sourceResult != Result::Success) delete atomicSource;
            if (targetResult != Result::Success) delete atomicTarget;
            if (mismatchResult != Result::Success) delete mismatch;
            if (unsupportedSourceResult != Result::Success) delete unsupportedSource;
            if (unsupportedTargetResult != Result::Success) delete unsupportedTarget;
            if (foreignResult != Result::Success) delete foreign;
        }
    } else {
        delete atomicSource;
        delete atomicTarget;
        delete mismatch;
        delete unsupportedSource;
        delete unsupportedTarget;
        delete foreign;
    }
    delete foreignScene;
    delete atomic;
}

static void boundaries(SwRenderer* renderer)
{
    auto invalid = Point::gen({0.0f, 0.0f});
    CHECK(invalid != nullptr);
    if (invalid) {
        invalid->opacity = std::numeric_limits<float>::quiet_NaN();
        auto scene = Scene::gen();
        CHECK(scene != nullptr);
        auto root = _space();
        CHECK(root != nullptr);
        if (root) CHECK(root->add(invalid) == Result::InvalidArguments);
        delete root;
        delete scene;
        delete invalid;
    }

    auto first = Scene::gen();
    auto second = Scene::gen();
    auto shared = Point::gen({0.0f, 0.0f});
    auto sharedSpace = _space();
    CHECK(first && second && shared && sharedSpace);
    if (first && second && shared && sharedSpace) {
        CHECK(sharedSpace->add(shared) == Result::Success);
        CHECK(first->add(sharedSpace) == Result::Success);
        CHECK(second->add(sharedSpace) == Result::InvalidArguments);
        auto animation = Animation::create(shared);
        CHECK(first->play(animation, 1.0f, static_cast<Easing>(255)) == Result::InvalidArguments);
        auto custom = AnimCurve::cubicBezier({0.2f, 0.8f}, {0.3f, 1.0f}, 0.9f);
        CHECK(first->play(Animation::shift(shared, {1.0f, 0.0f}), 1.0f, custom)
              == Result::Success);
        auto invalidCurve = AnimCurve::preset(AnimCurvePreset::Back);
        invalidCurve.strength = std::numeric_limits<float>::quiet_NaN();
        CHECK(first->play(Animation::shift(shared, {1.0f, 0.0f}), 1.0f, invalidCurve)
              == Result::InvalidArguments);
        animation = Animation::fade(shared, 0.5f);
        animation.value = std::numeric_limits<float>::quiet_NaN();
        CHECK(first->play(animation) == Result::InvalidArguments);
        shared->opacity = std::numeric_limits<float>::quiet_NaN();
        Surface surface;
        CHECK(renderer->render(first, 0.0f, surface) == Result::InvalidArguments);
    }
    delete second;
    delete first;

    auto frozenScene = Scene::gen();
    auto frozen = Line::gen({-1.0f, 0.0f}, {1.0f, 0.0f});
    auto frozenSpace = _space();
    CHECK(frozenScene && frozen && frozenSpace);
    if (frozenScene && frozen && frozenSpace) {
        auto red = Color::hex("#ff0000");
        auto green = Color::hex("#00ff00");
        frozen->stroke(red, 3.0f);
        CHECK(frozenSpace->add(frozen) == Result::Success);
        CHECK(frozenScene->add(frozenSpace) == Result::Success);
        frozen->stroke(green, 7.0f);
        frozen->shift({2.0f, 0.0f});
        CHECK(frozen->style.stroke.r == red.r && frozen->style.width == 3.0f);
        CHECK(frozen->model.e[3] == 0.0f);
        frozen->layer = 1;
        Surface surface;
        CHECK(renderer->render(frozenScene, 0.0f, surface) == Result::InvalidArguments);
        frozen->layer = 0;
        CHECK(renderer->render(frozenScene, 0.0f, surface) == Result::Success);
    }
    delete frozenScene;

    auto textScene = Scene::gen();
    auto frozenText = Text::gen("before");
    auto textSpace = _space();
    CHECK(textScene && frozenText && textSpace);
    if (textScene && frozenText && textSpace) {
        CHECK(textSpace->add(frozenText) == Result::Success);
        CHECK(textScene->add(textSpace) == Result::Success);
        CHECK(frozenText->text("after") == Result::Success);
        CHECK(std::strcmp(frozenText->text(), "after") == 0);
        CHECK(textScene->wait(0.0f) == Result::Success);
        CHECK(frozenText->text("sealed") == Result::InsufficientCondition);
        CHECK(std::strcmp(frozenText->text(), "after") == 0);
    }
    delete textScene;

    auto limits = Scene::gen();
    CHECK(limits != nullptr);
    if (limits) {
        CHECK(limits->wait(std::numeric_limits<float>::max()) == Result::Success);
        CHECK(limits->wait(1.0f) == Result::InvalidArguments);
        delete limits;
    }

    auto precisionTimeline = Scene::gen();
    auto precisionPoint = Point::gen({0.0f, 0.0f});
    CHECK(precisionTimeline && precisionPoint);
    if (precisionTimeline && precisionPoint) {
        auto addResult = precisionTimeline->add(precisionPoint);
        CHECK(addResult == Result::Success);
        if (addResult == Result::Success) {
            CHECK(precisionTimeline->wait(1.0e30f) == Result::Success);
            auto duration = precisionTimeline->duration();
            CHECK(precisionTimeline->wait(1.0f) == Result::InvalidArguments);
            CHECK(precisionTimeline->duration() == duration);
            CHECK(precisionTimeline->play(Animation::fade(precisionPoint, 0.5f), 1.0f)
                  == Result::InvalidArguments);
            auto target = AnimationTarget::from(precisionPoint).opacity(0.5f);
            CHECK(precisionTimeline->play(target, 1.0f) == Result::InvalidArguments);
            CHECK(precisionTimeline->look(precisionTimeline->config().camera, CameraView::TwoD, 1.0f)
                  == Result::InvalidArguments);
            CHECK(precisionTimeline->duration() == duration);
        } else {
            delete precisionPoint;
        }
    } else {
        delete precisionPoint;
    }
    delete precisionTimeline;

    auto interpolation = Scene::gen();
    auto line = Line::gen({-1.0f, 0.0f}, {1.0f, 0.0f});
    auto interpolationSpace = _space();
    CHECK(interpolation && line && interpolationSpace);
    if (interpolation && line && interpolationSpace) {
        line->model = Mat4::translate({-std::numeric_limits<float>::max(), 0.0f, 0.0f});
        CHECK(interpolationSpace->add(line) == Result::Success);
        CHECK(interpolation->add(interpolationSpace) == Result::Success);
        auto target = Mat4::translate({std::numeric_limits<float>::max(), 0.0f, 0.0f});
        CHECK(interpolation->play(Animation::transform(line, target), 1.0f, Easing::Linear) == Result::Success);
        Surface surface;
        CHECK(renderer->render(interpolation, 0.5f, surface) == Result::Success);
    }
    delete interpolation;

    auto projectiveScene = Scene::gen();
    auto projectiveLine = Line::gen({-1.0f, 1.0f}, {1.0f, 1.0f});
    auto projectiveSpace = _space();
    CHECK(projectiveScene && projectiveLine && projectiveSpace);
    if (projectiveScene && projectiveLine && projectiveSpace) {
        projectiveLine->model.e[12] = 1.0f;
        CHECK(projectiveSpace->add(projectiveLine) == Result::InvalidArguments);
        projectiveLine->model = Mat4::identity();
        CHECK(projectiveSpace->add(projectiveLine) == Result::Success);
        CHECK(projectiveScene->add(projectiveSpace) == Result::Success);
        auto projective = Mat4::identity();
        projective.e[12] = 1.0f;
        CHECK(projectiveScene->play(Animation::transform(projectiveLine, projective)) == Result::InvalidArguments);
    }
    delete projectiveScene;

    auto rulerScene = Scene::gen();
    auto ruler = Ruler::gen({-2.0f, 0.0f}, {2.0f, 0.0f}, 0.5f);
    auto rulerSpace = _space();
    CHECK(rulerScene && ruler && rulerSpace);
    if (rulerScene && ruler && rulerSpace) {
        CHECK(rulerSpace->add(ruler) == Result::Success);
        CHECK(rulerScene->add(rulerSpace) == Result::Success);
        CHECK(rulerScene->play(Animation::create(ruler), 1.0f, Easing::Linear) == Result::Success);
        Surface surface;
        CHECK(renderer->render(rulerScene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, rulerScene->config().background) == 0);
        CHECK(renderer->render(rulerScene, 0.5f, surface) == Result::Success);
        CHECK(changed(surface, rulerScene->config().background) > 0);
    }
    delete rulerScene;

    Config subnormalConfig;
    subnormalConfig.camera.orthoHeight = 1.0e-40f;
    auto subnormalScene = Scene::gen(subnormalConfig);
    auto subnormalPoint = Point::gen({});
    auto subnormalSpace = _space();
    CHECK(subnormalScene && subnormalPoint && subnormalSpace);
    if (subnormalScene && subnormalPoint && subnormalSpace) {
        CHECK(subnormalSpace->add(subnormalPoint) == Result::Success);
        CHECK(subnormalScene->add(subnormalSpace) == Result::Success);
        Surface surface;
        CHECK(renderer->render(subnormalScene, 0.0f, surface) == Result::Success);
    }
    delete subnormalScene;

    Config scaledCameraConfig;
    scaledCameraConfig.camera.target = {0.0f, 0.0f, -1.0e-7f};
    scaledCameraConfig.camera.up = {0.0f, 1.0e-7f, 0.0f};
    scaledCameraConfig.camera.near = 1.0e-8f;
    auto scaledCameraScene = Scene::gen(scaledCameraConfig);
    CHECK(scaledCameraScene != nullptr);
    delete scaledCameraScene;

    Config invalidPlanar;
    invalidPlanar.camera.projection = Projection::Perspective;
    CHECK(Scene::gen(invalidPlanar) == nullptr);

    Config oddConfig;
    oddConfig.width = 321;
    oddConfig.height = 181;
    auto odd = Scene::gen(oddConfig);
    CHECK(odd != nullptr);
    if (odd) {
        CHECK(Saver::video(odd, renderer, "invalid.mp4") == Result::InvalidArguments);
        CHECK(Saver::video(odd, renderer, "invalid.webm") == Result::InvalidArguments);
        delete odd;
    }

#ifndef TMATH_EXPECT_GL
    CHECK(GlRenderer::gen() == nullptr);
#endif
}

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
static void videoCadence(SwRenderer* renderer)
{
    char directory[64];
    std::snprintf(directory, sizeof(directory), "tmath-video-%ld", static_cast<long>(getpid()));
    auto created = mkdir(directory, 0700);
    CHECK(created == 0);
    if (created != 0) return;
    char executable[96];
    char countPath[96];
    std::snprintf(executable, sizeof(executable), "%s/ffmpeg", directory);
    std::snprintf(countPath, sizeof(countPath), "%s/bytes", directory);
    auto script = std::fopen(executable, "wb");
    CHECK(script != nullptr);
    if (!script) return;
    CHECK(std::fputs("#!/bin/sh\nwc -c > \"$TMATH_FRAME_BYTES\"\n", script) >= 0);
    CHECK(std::fclose(script) == 0);
    CHECK(chmod(executable, 0700) == 0);

    auto oldPath = std::getenv("PATH");
    auto oldSize = oldPath ? std::strlen(oldPath) : 0u;
    auto savedPath = static_cast<char*>(std::malloc(oldSize + 1u));
    CHECK(savedPath != nullptr);
    if (!savedPath) return;
    if (oldPath) std::memcpy(savedPath, oldPath, oldSize);
    savedPath[oldSize] = '\0';
    auto directorySize = std::strlen(directory);
    auto joinedPath = static_cast<char*>(std::malloc(directorySize + (oldSize ? oldSize + 1u : 0u) + 1u));
    CHECK(joinedPath != nullptr);
    if (!joinedPath) {
        std::free(savedPath);
        return;
    }
    std::memcpy(joinedPath, directory, directorySize);
    auto joinedSize = directorySize;
    if (oldSize) {
        joinedPath[joinedSize++] = ':';
        std::memcpy(joinedPath + joinedSize, savedPath, oldSize);
        joinedSize += oldSize;
    }
    joinedPath[joinedSize] = '\0';
    CHECK(setenv("PATH", joinedPath, 1) == 0);
    std::free(joinedPath);
    CHECK(setenv("TMATH_FRAME_BYTES", countPath, 1) == 0);

    Config config;
    config.width = 16;
    config.height = 16;
    auto scene = Scene::gen(config);
    CHECK(scene != nullptr);
    if (scene) {
        CHECK(scene->wait(0.1f) == Result::Success);
        CHECK(Saver::video(scene, renderer, "cadence.mp4", 30) == Result::Success);
        CHECK(Saver::video(scene, renderer, "cadence.gif", 30) == Result::Success);
        delete scene;
    }

    auto count = std::fopen(countPath, "rb");
    CHECK(count != nullptr);
    unsigned long long bytes = 0;
    if (count) {
        CHECK(std::fscanf(count, "%llu", &bytes) == 1);
        CHECK(std::fclose(count) == 0);
    }
    CHECK(bytes == 3ull * config.width * config.height * 4ull);

    auto preserved = std::fopen("preserved.mp4", "wb");
    CHECK(preserved != nullptr);
    if (preserved) {
        CHECK(std::fputs("KEEP-ME", preserved) >= 0);
        CHECK(std::fclose(preserved) == 0);
    }
    auto invalidScene = Scene::gen(config);
    auto invalidPoint = Point::gen({});
    auto invalidSpace = _space();
    CHECK(invalidScene && invalidPoint && invalidSpace);
    if (invalidScene && invalidPoint && invalidSpace) {
        CHECK(invalidSpace->add(invalidPoint) == Result::Success);
        CHECK(invalidScene->add(invalidSpace) == Result::Success);
        invalidPoint->point.x = std::numeric_limits<float>::quiet_NaN();
        CHECK(Saver::video(invalidScene, renderer, "preserved.mp4", 30) == Result::InvalidArguments);
    }
    delete invalidScene;
    preserved = std::fopen("preserved.mp4", "rb");
    CHECK(preserved != nullptr);
    char contents[8] = {};
    if (preserved) {
        CHECK(std::fread(contents, 1, 7, preserved) == 7);
        CHECK(std::fclose(preserved) == 0);
    }
    CHECK(std::strcmp(contents, "KEEP-ME") == 0);

    if (oldPath) CHECK(setenv("PATH", savedPath, 1) == 0);
    else CHECK(unsetenv("PATH") == 0);
    CHECK(unsetenv("TMATH_FRAME_BYTES") == 0);
    std::free(savedPath);

    CHECK(std::remove("cadence.mp4") == 0);
    CHECK(std::remove("cadence.gif") == 0);
    CHECK(std::remove("preserved.mp4") == 0);
    CHECK(std::remove(countPath) == 0);
    CHECK(std::remove(executable) == 0);
    CHECK(rmdir(directory) == 0);
}
#endif

static void scene3D(SwRenderer* renderer)
{
    Config config;
    config.width = 640;
    config.height = 360;
    config.cameraView = CameraView::ThreeD;
    config.camera.projection = Projection::Perspective;
    config.camera.eye = {6.0f, 5.0f, 7.0f};
    auto scene = Scene::gen(config);
    auto space = Space::gen({-3.0f, 3.0f, 1.0f}, {-3.0f, 3.0f, 1.0f}, {-3.0f, 3.0f, 1.0f});
    auto x = Vector::gen({2.5f, 0.0f, 0.0f});
    auto y = Vector::gen({0.0f, 2.5f, 0.0f});
    auto z = Vector::gen({0.0f, 0.0f, 2.5f});
    CHECK(scene && space && x && y && z);
    x->tail = 12.0f;
    z->tip = 0.0f;
    x->stroke(Color::hex("#ef5350"), 4.0f);
    y->stroke(Color::hex("#66bb6a"), 4.0f);
    z->stroke(Color::hex("#42a5f5"), 4.0f);
    CHECK(space->add(x) == Result::Success);
    CHECK(space->add(y) == Result::Success);
    CHECK(space->add(z) == Result::Success);
    CHECK(scene->add(space) == Result::Success);
    Animation create[] = {Animation::create(space), Animation::create(x), Animation::create(y), Animation::create(z)};
    CHECK(scene->play(create, 4, 1.2f, Easing::Smooth, 0.08f) == Result::Success);

    Surface surface;
    CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
    CHECK(changed(surface, config.background) > 3500);
    CHECK(Saver::png(surface, "test-sw-3d.png") == Result::Success);
    delete scene;
}

static void assetsAndCells(SwRenderer* renderer)
{
    static constexpr char svg[] = "<svg xmlns='http://www.w3.org/2000/svg' width='4' height='2'>"
                                  "<rect width='2' height='2' fill='#ff4050'/><rect x='2' width='2' height='2' fill='#40a0ff'/>"
                                  "</svg>";
    Asset* decoded = nullptr;
    CHECK(AssetLoader::load(svg, sizeof(svg) - 1u, "svg", decoded) == Result::Success);
    CHECK(decoded && decoded->width() == 4 && decoded->height() == 2);
    delete decoded;

    uint32_t pixels[] = {0xff5040ff, 0xffffa040, 0xff66bb66, 0xffffd166};
    Asset* asset = nullptr;
    CHECK(AssetLoader::load(pixels, 2, 2, asset) == Result::Success);
    CHECK(asset && asset->width() == 2 && asset->height() == 2);
    if (!asset) return;

    Config config;
    config.width = 320;
    config.height = 180;
    config.camera.orthoHeight = 6.0f;
    auto scene = Scene::gen(config);
    auto space = _space();
    auto image = Image::gen(asset, {1.5f, 0.0f, 0.0f}, 2.0f);
    auto cells = Cell::gen({-2.5f, -1.0f, 0.0f}, 2, 2, {}, CellMode::Padd);
    CHECK(scene && space && image && cells);
    if (scene && space && image && cells) {
        image->filter = ImageFilter::Nearest;
        CHECK(cells->texture(asset) == Result::Success);
        CHECK(cells->fill({0, 0, 1, 1}, Color::hex("#ffffff")) == Result::Success);
        CHECK(space->add(image) == Result::Success);
        CHECK(space->add(cells) == Result::Success);
        CHECK(scene->add(space) == Result::Success);
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, config.background) > 3000);
        scene->config().antialiasing = false;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, config.background) > 3000);
        CHECK(Saver::png(surface, "test-sw-assets-cells.png") == Result::Success);
    } else {
        delete space;
        delete image;
        delete cells;
    }
    delete scene;

    config.cameraView = CameraView::ThreeD;
    config.camera.projection = Projection::Perspective;
    config.camera.eye = {5.0f, 4.0f, 6.0f};
    config.antialiasing = true;
    auto voxelScene = Scene::gen(config);
    auto voxelSpace = _space();
    auto voxels = Cell::gen({-1.0f, -1.0f, -0.5f}, 2, 2, {}, CellMode::Padd);
    CHECK(voxelScene && voxelSpace && voxels);
    if (voxelScene && voxelSpace && voxels) {
        CHECK(voxels->texture(asset) == Result::Success);
        CHECK(voxelSpace->add(voxels) == Result::Success);
        CHECK(voxelScene->add(voxelSpace) == Result::Success);
        Surface surface;
        CHECK(renderer->render(voxelScene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, config.background) > 1500);
        CHECK(Saver::png(surface, "test-sw-voxels.png") == Result::Success);
    } else {
        delete voxelSpace;
        delete voxels;
    }
    delete voxelScene;
    delete asset;
}

struct SampleContext
{
    uint32_t calls = 0;
    float firstTime = -1.0f;
    float lastTime = -1.0f;
};

static bool _cellSample(float x, float y, float time, Color& color, void* data) noexcept
{
    auto context = static_cast<SampleContext*>(data);
    if (!context->calls) context->firstTime = time;
    context->lastTime = time;
    context->calls++;
    color = {
        static_cast<uint8_t>((x + 1.0f) * 80.0f),
        static_cast<uint8_t>(y * 80.0f),
        40,
        255};
    return true;
}

static bool _voxelSample(float x, float y, float z, float time, Color& color,
                         void* data) noexcept
{
    auto context = static_cast<SampleContext*>(data);
    if (!context->calls) context->firstTime = time;
    context->lastTime = time;
    context->calls++;
    color = {
        static_cast<uint8_t>((x + 1.0f) * 80.0f),
        static_cast<uint8_t>(y * 80.0f),
        static_cast<uint8_t>((z + 1.0f) * 80.0f),
        255};
    return true;
}

static bool _rejectVoxel(float, float, float, float, Color&, void*) noexcept
{
    return false;
}

static bool _solidCell(float, float, float, Color& color, void* data) noexcept
{
    color = *static_cast<Color*>(data);
    return true;
}

struct ReentrantVoxelContext
{
    Space* space = nullptr;
    Result nested = Result::Success;
    Result added = Result::Success;
};

static bool _reentrantVoxel(float, float, float, float, Color& color,
                            void* data) noexcept
{
    auto context = static_cast<ReentrantVoxelContext*>(data);
    Group* nested = nullptr;
    context->nested = context->space->voxel(_rejectVoxel, nested);
    auto child = Group::gen();
    context->added = context->space->add(child);
    if (context->added != Result::Success) delete child;
    color = Color::hex("#2563eb");
    return true;
}

static void voxelSamples(SwRenderer* renderer)
{
    auto space = Space::gen({-1.0f, 1.0f, 1.0f}, {0.0f, 1.0f, 1.0f},
                            {-1.0f, 1.0f, 1.0f});
    SampleContext context;
    Group* voxels = nullptr;
    CHECK(space != nullptr);
    if (!space) return;
    CHECK(space->voxel(_voxelSample, voxels, &context, CellMode::Padd, 0.1f)
          == Result::Success);
    CHECK(voxels != nullptr);
    CHECK(context.calls == 18u);
    CHECK(context.firstTime == 0.0f && context.lastTime == 0.0f);
    CHECK(space->count() == 1u);
    CHECK(voxels && voxels->parent() == space);
    CHECK(voxels && voxels->childCount() == 3u);
    if (voxels && voxels->childCount() == 3u) {
        auto first = static_cast<Cell*>(voxels->childAt(0));
        auto last = static_cast<Cell*>(voxels->childAt(2));
        CHECK(first->type() == Type::Cell);
        CHECK(first->columns() == 3u);
        CHECK(first->rows() == 2u);
        CHECK(same(first->colors()[0], Color{0, 0, 0, 255}));
        CHECK(same(first->colors()[5], Color{160, 80, 0, 255}));
        CHECK(same(last->colors()[0], Color{0, 0, 160, 255}));
        auto center = first->model * Vec3{0.5f, 0.5f, 0.5f};
        CHECK(near(center.x, -1.0f));
        CHECK(near(center.y, 0.0f));
        CHECK(near(center.z, -1.0f));
    }

    Group* rejected = nullptr;
    CHECK(space->voxel(_rejectVoxel, rejected) == Result::InvalidArguments);
    CHECK(rejected == nullptr);
    CHECK(space->count() == 1u);
    CHECK(space->voxel(nullptr, rejected) == Result::InvalidArguments);
    CHECK(space->voxel(_voxelSample, rejected, &context, CellMode::Padd, 0.5f)
          == Result::InvalidArguments);

    Config config;
    config.width = 320u;
    config.height = 180u;
    config.cameraView = CameraView::ThreeD;
    config.camera.projection = Projection::Perspective;
    config.camera.eye = {5.0f, 4.0f, 6.0f};
    auto scene = Scene::gen(config);
    CHECK(scene != nullptr);
    if (scene) {
        CHECK(scene->add(space) == Result::Success);
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(changed(surface, config.background) > 1000u);
    } else {
        delete space;
    }
    delete scene;

    auto oversized = Space::gen({-100.0f, 100.0f, 1.0f},
                                {-100.0f, 100.0f, 1.0f}, {0.0f, 0.0f, 1.0f});
    Group* output = nullptr;
    CHECK(oversized != nullptr);
    if (oversized) {
        CHECK(oversized->voxel(_voxelSample, output, &context)
              == Result::InsufficientCondition);
    }
    CHECK(output == nullptr);
    delete oversized;

    auto guarded = Space::gen({0.0f, 0.0f, 1.0f}, {0.0f, 0.0f, 1.0f},
                              {0.0f, 0.0f, 1.0f});
    auto reentrant = ReentrantVoxelContext{guarded};
    output = nullptr;
    CHECK(guarded != nullptr);
    if (guarded) {
        CHECK(guarded->voxel(_reentrantVoxel, output, &reentrant)
              == Result::Success);
        CHECK(reentrant.nested == Result::InsufficientCondition);
        CHECK(reentrant.added == Result::InsufficientCondition);
        CHECK(output && guarded->count() == 1u);
    }
    delete guarded;
}

static void cellSamples()
{
    auto space = Space::gen({-1.0f, 1.0f, 1.0f}, {0.0f, 1.0f, 1.0f},
                            {-100.0f, 100.0f, 1.0f});
    SampleContext context;
    Group* cells = nullptr;
    CHECK(space != nullptr);
    if (!space) return;
    CHECK(space->cell(_cellSample, cells, &context, CellMode::Padd, 0.1f)
          == Result::Success);
    CHECK(cells != nullptr);
    CHECK(context.calls == 6u);
    CHECK(context.firstTime == 0.0f && context.lastTime == 0.0f);
    CHECK(cells && cells->childCount() == 1u);
    if (cells && cells->childCount() == 1u) {
        auto cell = static_cast<Cell*>(cells->childAt(0));
        CHECK(cell->columns() == 3u);
        CHECK(cell->rows() == 2u);
        CHECK(same(cell->colors()[0], Color{0, 0, 40, 255}));
        CHECK(same(cell->colors()[5], Color{160, 80, 40, 255}));
        auto center = cell->model * Vec3{0.5f, 0.5f, 0.5f};
        CHECK(near(center.x, -1.0f));
        CHECK(near(center.y, 0.0f));
        CHECK(near(center.z, 0.0f));
    }
    Group* rejected = nullptr;
    CHECK(space->cell(nullptr, rejected) == Result::InvalidArguments);
    CHECK(rejected == nullptr);
    delete space;
}

struct TemporalSampleContext
{
    uint32_t calls = 0u;
    float firstTime = -1.0f;
    float lastTime = -1.0f;
};

static bool _temporalCell(float, float, float time, Color& color,
                          void* data) noexcept
{
    auto context = static_cast<TemporalSampleContext*>(data);
    if (!context->calls) context->firstTime = time;
    context->lastTime = time;
    context->calls++;
    color = {
        static_cast<uint8_t>(255.0f * (1.0f - time) + 0.5f),
        0u,
        static_cast<uint8_t>(255.0f * time + 0.5f),
        255u};
    return true;
}

static bool _temporalVoxel(float, float, float, float time, Color& color,
                           void* data) noexcept
{
    auto context = static_cast<TemporalSampleContext*>(data);
    if (!context->calls) context->firstTime = time;
    context->lastTime = time;
    context->calls++;
    color = time < 0.5f ? Color::hex("#2563eb") : Color::hex("#7c3aed");
    return true;
}

static void sampleTime(SwRenderer* renderer)
{
    Config config;
    config.width = 80u;
    config.height = 80u;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto space = Space::gen({0.0f, 0.0f, 1.0f}, {0.0f, 0.0f, 1.0f},
                            {0.0f, 0.0f, 1.0f});
    CHECK(scene && space);
    if (!scene || !space) {
        delete scene;
        delete space;
        return;
    }
    space->style.stroke.a = 0u;
    space->axisX.a = 0u;
    space->axisY.a = 0u;
    space->axisZ.a = 0u;
    TemporalSampleContext context;
    Group* field = nullptr;
    CHECK(space->cell(_temporalCell, field, &context, CellMode::Full,
                      0.0f, {1.0f, 2u}) == Result::Success);
    CHECK(field != nullptr);
    CHECK(context.calls == 3u);
    CHECK(near(context.firstTime, 0.0f) && near(context.lastTime, 1.0f));
    CHECK(scene->add(space) == Result::Success);
    CHECK(near(scene->duration(), 1.0f));

    Surface surface;
    auto center = static_cast<size_t>(config.height / 2u) * config.width
                + config.width / 2u;
    CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
    CHECK(surface.data()[center] == pixel(Color::hex("#ff0000")));
    CHECK(renderer->render(scene, 0.25f, surface) == Result::Success);
    CHECK(surface.data()[center] == pixel(Color::hex("#c00040")));
    CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
    CHECK(surface.data()[center] == pixel(Color::hex("#800080")));
    BBox bounds;
    CHECK(renderer->bounds(scene, field, 0.5f, bounds) == Result::Success);
    CHECK(bounds.width > 0.0f && bounds.height > 0.0f);
    CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
    CHECK(surface.data()[center] == pixel(Color::hex("#0000ff")));
    CHECK(context.calls == 3u);

    auto blue = Color::hex("#2563eb");
    Group* target = nullptr;
    CHECK(space->cell(_solidCell, target, &blue, CellMode::Full)
          == Result::Success);
    CHECK(scene->play(Animation::morph(field, target), 1.0f, Easing::Linear)
          == Result::NonSupport);
    delete scene;

    auto volume = Space::gen({0.0f, 0.0f, 1.0f}, {0.0f, 0.0f, 1.0f},
                             {0.0f, 0.0f, 1.0f});
    context = {};
    field = nullptr;
    CHECK(volume != nullptr);
    if (volume) {
        CHECK(volume->voxel(_temporalVoxel, field, &context, CellMode::Padd,
                            0.05f, {0.5f, 2u}) == Result::Success);
        CHECK(field != nullptr && context.calls == 2u);
        CHECK(near(context.firstTime, 0.0f) && near(context.lastTime, 0.5f));
        Group* invalid = nullptr;
        CHECK(volume->voxel(_temporalVoxel, invalid, &context, CellMode::Padd,
                            0.05f, {-1.0f, 30u}) == Result::InvalidArguments);
        CHECK(volume->voxel(_temporalVoxel, invalid, &context, CellMode::Padd,
                            0.05f, {1.0f, 0u}) == Result::InvalidArguments);
        CHECK(volume->voxel(_temporalVoxel, invalid, &context, CellMode::Padd,
                            0.05f, {200.0f, 30u}) == Result::InsufficientCondition);
        CHECK(invalid == nullptr);
    }
    delete volume;
}

static void dimensionTransition(SwRenderer* renderer)
{
    Config config;
    config.width = 320;
    config.height = 180;
    config.cameraMode = CameraMode::Fixed;
    auto scene = Scene::gen(config);
    auto space = Space::gen({-4.0f, 4.0f, 1.0f}, {-3.0f, 3.0f, 1.0f}, {-3.0f, 3.0f, 1.0f});
    auto vector = Vector::gen({2.0f, 1.5f, 1.0f});
    CHECK(scene && space && vector);
    if (!scene || !space || !vector) {
        delete scene;
        delete space;
        delete vector;
        return;
    }
    space->model = Mat4::scale({1.0f, 2.0f, 0.5f});
    CHECK(space->add(vector) == Result::Success);
    CHECK(scene->add(space) == Result::Success);
    CHECK(space->count() == 1);
    CHECK(space->objectAt(0) == vector);
    CHECK(space->c2w({1.0f, 1.0f, 1.0f}).x == 1.0f);
    CHECK(space->c2w({1.0f, 1.0f, 1.0f}).y == 2.0f);
    CHECK(space->c2w({1.0f, 1.0f, 1.0f}).z == 0.5f);
    Vec3 coordinate;
    CHECK(space->w2c({1.0f, 2.0f, 0.5f}, coordinate));
    CHECK(coordinate.x == 1.0f && coordinate.y == 1.0f && coordinate.z == 1.0f);
    auto child = Space::gen({-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f}, {-1.0f, 1.0f, 1.0f});
    auto childPoint = Point::gen({1.0f, 1.0f, 1.0f});
    CHECK(child && childPoint);
    if (child && childPoint) {
        child->model = Mat4::translate({1.0f, 0.0f, 0.0f});
        CHECK(child->add(childPoint) == Result::Success);
        CHECK(space->add(child) == Result::Success);
        CHECK(child->space() == space && childPoint->space() == child);
        auto world = child->c2w({1.0f, 1.0f, 1.0f});
        CHECK(world.x == 2.0f && world.y == 2.0f && world.z == 0.5f);
    }
    auto second = _space();
    CHECK(second != nullptr);
    if (second) {
        second->model = Mat4::translate({-3.0f, 0.0f, 0.0f});
        CHECK(scene->add(second) == Result::Success);
        CHECK(second->space() == nullptr);
    }
    auto singular = Space::gen();
    CHECK(singular != nullptr);
    if (singular) {
        singular->model = Mat4::scale({1.0f, 0.0f, 1.0f});
        CHECK(!singular->w2c({}, coordinate));
    }
    delete singular;

    Surface surface;
    CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
    CHECK(changed(surface, config.background) > 1000);
    auto planar = checksum(surface);
    auto planarCamera = scene->config().camera;
    auto spatialCamera = planarCamera;
    spatialCamera.eye = {6.0f, 4.0f, 7.0f};
    spatialCamera.projection = Projection::Perspective;
    CHECK(scene->look(spatialCamera, CameraView::ThreeD, 1.0f, Easing::Smooth) == Result::Success);
    CHECK(scene->view(0.0f) == CameraView::TwoD);
    CHECK(scene->view(0.5f) == CameraView::ThreeD);
    CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
    CHECK(changed(surface, config.background) > 1000);
    CHECK(checksum(surface) != planar);
    CHECK(scene->look(planarCamera, CameraView::TwoD, 1.0f, Easing::Smooth) == Result::Success);
    CHECK(scene->view(scene->duration()) == CameraView::TwoD);
    CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
    CHECK(changed(surface, config.background) > 1000);
    CHECK(checksum(surface) == planar);
    delete scene;

    Config cameraPathConfig;
    cameraPathConfig.width = 64;
    cameraPathConfig.height = 64;
    cameraPathConfig.cameraView = CameraView::ThreeD;
    cameraPathConfig.camera.projection = Projection::Perspective;
    auto cameraPath = Scene::gen(cameraPathConfig);
    CHECK(cameraPath != nullptr);
    if (cameraPath) {
        auto opposite = cameraPathConfig.camera;
        opposite.eye = {0.0f, 0.0f, -10.0f};
        CHECK(cameraPath->look(opposite, CameraView::ThreeD, 1.0f, Easing::Linear) == Result::Success);
        Surface pathSurface;
        CHECK(renderer->render(cameraPath, 0.5f, pathSurface) == Result::Success);

        auto rolled = opposite;
        rolled.up = {0.0f, -1.0f, 0.0f};
        CHECK(cameraPath->look(rolled, CameraView::ThreeD, 1.0f, Easing::Linear) == Result::Success);
        CHECK(renderer->render(cameraPath, 1.5f, pathSurface) == Result::Success);
    }
    delete cameraPath;

    Config extremeCameraConfig;
    extremeCameraConfig.width = 32;
    extremeCameraConfig.height = 32;
    extremeCameraConfig.cameraView = CameraView::ThreeD;
    extremeCameraConfig.camera.projection = Projection::Perspective;
    auto limit = std::numeric_limits<float>::max();
    extremeCameraConfig.camera.eye = {limit, 0.0f, 0.0f};
    extremeCameraConfig.camera.target = {-limit, 0.0f, 0.0f};
    auto extremeCamera = Scene::gen(extremeCameraConfig);
    CHECK(extremeCamera != nullptr);
    if (extremeCamera) {
        auto ordinary = Camera{};
        ordinary.projection = Projection::Perspective;
        CHECK(extremeCamera->look(ordinary, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(near(extremeCamera->duration(), 0.0f));
        Surface extremeSurface;
        CHECK(renderer->render(extremeCamera, 0.0f, extremeSurface) == Result::Success);
        auto extremeLens = extremeCameraConfig.camera;
        extremeLens.fov = 0.9f;
        CHECK(extremeCamera->look(extremeLens, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::Success);
        CHECK(renderer->render(extremeCamera, 0.5f, extremeSurface) == Result::Success);
    }
    delete extremeCamera;

    Config boundaryCameraConfig;
    boundaryCameraConfig.width = 32;
    boundaryCameraConfig.height = 32;
    boundaryCameraConfig.cameraView = CameraView::ThreeD;
    boundaryCameraConfig.camera.projection = Projection::Perspective;
    boundaryCameraConfig.camera.eye = {limit, 0.0f, 0.0f};
    auto boundaryTargetX = limit;
    for (auto i = 0u; i < 7u; i++) boundaryTargetX = std::nextafter(boundaryTargetX, 0.0f);
    boundaryCameraConfig.camera.target = {boundaryTargetX, 0.0f, 0.0f};
    auto boundaryCamera = Scene::gen(boundaryCameraConfig);
    CHECK(boundaryCamera != nullptr);
    if (boundaryCamera) {
        auto boundaryTarget = boundaryCameraConfig.camera;
        boundaryTarget.target.x = std::nextafter(boundaryCameraConfig.camera.target.x, 0.0f);
        CHECK(boundaryCamera->look(boundaryTarget, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::Success);
        Surface boundarySurface;
        CHECK(renderer->render(boundaryCamera, 0.5f, boundarySurface) == Result::Success);
    }
    delete boundaryCamera;

    Config clipPlaneConfig;
    clipPlaneConfig.width = 32;
    clipPlaneConfig.height = 32;
    clipPlaneConfig.camera.near = 1.0f;
    clipPlaneConfig.camera.far = std::nextafter(1.0f, std::numeric_limits<float>::infinity());
    auto clipPlaneScene = Scene::gen(clipPlaneConfig);
    CHECK(clipPlaneScene != nullptr);
    if (clipPlaneScene) {
        auto clipPlaneTarget = clipPlaneConfig.camera;
        clipPlaneTarget.near = std::nextafter(2.0f, 0.0f);
        clipPlaneTarget.far = 2.0f;
        CHECK(clipPlaneScene->look(clipPlaneTarget, CameraView::TwoD, 1.0f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(near(clipPlaneScene->duration(), 0.0f));
        Surface clipPlaneSurface;
        CHECK(renderer->render(clipPlaneScene, 0.0f, clipPlaneSurface) == Result::Success);
    }
    delete clipPlaneScene;

    Config precisionCameraConfig;
    precisionCameraConfig.width = 32;
    precisionCameraConfig.height = 32;
    precisionCameraConfig.cameraView = CameraView::ThreeD;
    precisionCameraConfig.camera.projection = Projection::Perspective;
    precisionCameraConfig.camera.target = {1073741824.0f, 0.0f, 0.0f};
    precisionCameraConfig.camera.eye = {1073741824.0f, 1.0f, 0.0f};
    precisionCameraConfig.camera.up = {0.0f, 0.0f, 1.0f};
    auto precisionCamera = Scene::gen(precisionCameraConfig);
    CHECK(precisionCamera != nullptr);
    if (precisionCamera) {
        auto collapsed = precisionCameraConfig.camera;
        collapsed.target = {0.0f, 1073741824.0f, 0.0f};
        collapsed.eye = {1.0f, 1073741824.0f, 0.0f};
        CHECK(precisionCamera->look(collapsed, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(near(precisionCamera->duration(), 0.0f));
        auto fixedPose = precisionCameraConfig.camera;
        fixedPose.fov = 0.9f;
        CHECK(precisionCamera->look(fixedPose, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::Success);
        Surface precisionSurface;
        CHECK(renderer->render(precisionCamera, 0.5f, precisionSurface) == Result::Success);
    }
    delete precisionCamera;

    auto invalidCurrentCamera = Scene::gen();
    CHECK(invalidCurrentCamera != nullptr);
    if (invalidCurrentCamera) {
        invalidCurrentCamera->config().camera.near = -1.0f;
        CHECK(invalidCurrentCamera->look(Camera{}, CameraView::TwoD, 1.0f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(near(invalidCurrentCamera->duration(), 0.0f));
    }
    delete invalidCurrentCamera;

    Config authoredCameraConfig;
    authoredCameraConfig.width = 64;
    authoredCameraConfig.height = 64;
    auto authoredCamera = Scene::gen(authoredCameraConfig);
    auto authoredRectangle = Rectangle::gen({}, {2.0f, 2.0f});
    CHECK(authoredCamera && authoredRectangle);
    if (authoredCamera && authoredRectangle) {
        authoredRectangle->style.stroke.a = 0;
        authoredRectangle->fill(Color::hex("#4cc9f0"));
        auto rectangleResult = authoredCamera->add(authoredRectangle);
        CHECK(rectangleResult == Result::Success);
        if (rectangleResult == Result::Success) {
            authoredCamera->config().camera.orthoHeight = 4.0f;
            CHECK(authoredCamera->wait(1.0f) == Result::Success);
            Surface authoredSurface;
            CHECK(renderer->render(authoredCamera, 0.5f, authoredSurface) == Result::Success);
            auto authoredFrame = checksum(authoredSurface);
            auto wider = authoredCamera->config().camera;
            wider.orthoHeight = 8.0f;
            CHECK(authoredCamera->look(wider, CameraView::TwoD, 1.0f, Easing::Linear)
                  == Result::Success);
            CHECK(renderer->render(authoredCamera, 0.5f, authoredSurface) == Result::Success);
            CHECK(checksum(authoredSurface) == authoredFrame);
            CHECK(renderer->render(authoredCamera, 1.5f, authoredSurface) == Result::Success);
            CHECK(checksum(authoredSurface) != authoredFrame);
        } else {
            delete authoredRectangle;
        }
    } else {
        delete authoredRectangle;
    }
    delete authoredCamera;

    auto authoredView = Scene::gen();
    CHECK(authoredView != nullptr);
    if (authoredView) {
        authoredView->config().cameraView = CameraView::ThreeD;
        authoredView->config().camera.projection = Projection::Perspective;
        authoredView->config().camera.eye = {6.0f, 4.0f, 7.0f};
        CHECK(authoredView->wait(1.0f) == Result::Success);
        CHECK(authoredView->view(0.0f) == CameraView::ThreeD);
        auto lens = authoredView->config().camera;
        lens.fov = 0.9f;
        CHECK(authoredView->look(lens, CameraView::ThreeD, 1.0f, Easing::Linear)
              == Result::Success);
        CHECK(authoredView->view(0.0f) == CameraView::ThreeD);
    }
    delete authoredView;

    config.cameraMode = CameraMode::Interactive;
    auto interactive = Scene::gen(config);
    CHECK(interactive != nullptr);
    if (interactive) {
        CHECK(interactive->camera({CameraAction::View3D, {}}) == Result::NonSupport);
        CHECK(interactive->camera({CameraAction::Orbit, {0.1f, -0.05f}})
              == Result::NonSupport);
        CHECK(interactive->look(spatialCamera, CameraView::ThreeD) == Result::InsufficientCondition);
    }
    delete interactive;
}

static void viewports(SwRenderer* renderer)
{
    auto parent = Scene::gen();
    auto child = Scene::gen();
    auto other = Scene::gen();
    auto childObject = Rectangle::gen();
    CHECK(parent && child && other && childObject);
    if (parent && child && other && childObject) {
        CHECK(child->add(childObject) == Result::Success);
        Viewport viewport;
        viewport.width = 0.0f;
        CHECK(parent->viewport(child, viewport) == Result::InvalidArguments);
        viewport.width = 0.5f;
        viewport.x = std::numeric_limits<float>::quiet_NaN();
        CHECK(parent->viewport(child, viewport) == Result::InvalidArguments);
        viewport.x = 0.75f;
        CHECK(parent->viewport(child, viewport) == Result::InvalidArguments);
        viewport = {0.25f, 0.25f, 0.5f, 0.5f};
        CHECK(parent->viewport(parent, viewport) == Result::InvalidArguments);
        CHECK(parent->viewport(child, viewport) == Result::Success);
        CHECK(parent->viewportCount() == 1);
        CHECK(parent->sceneAt(0) == child);
        CHECK(child->update(childObject) == Result::InsufficientCondition);
        CHECK(child->wait(0.1f) == Result::InsufficientCondition);
        CHECK(child->play(Animation::create(childObject)) == Result::InsufficientCondition);
        auto lateObject = Rectangle::gen();
        CHECK(lateObject != nullptr);
        if (lateObject) {
            auto result = child->add(lateObject);
            CHECK(result == Result::InsufficientCondition);
            if (result != Result::Success) delete lateObject;
        }
        auto lateScene = Scene::gen();
        CHECK(lateScene != nullptr);
        if (lateScene) {
            auto result = child->viewport(lateScene, {});
            CHECK(result == Result::InsufficientCondition);
            if (result != Result::Success) delete lateScene;
        }
        Viewport actual;
        CHECK(parent->viewportAt(0, actual));
        CHECK(actual.x == 0.25f);
        CHECK(!parent->viewportAt(1, actual));
        auto boundary = Scene::gen();
        CHECK(boundary != nullptr);
        if (boundary) {
            auto result = parent->viewport(boundary, {0.8f, 0.0f, 0.2f, 1.0f});
            CHECK(result == Result::Success);
            if (result != Result::Success) delete boundary;
        }
        auto thirds = Scene::gen();
        CHECK(thirds != nullptr);
        if (thirds) {
            auto result = parent->viewport(thirds, {2.0f / 3.0f, 0.0f, 1.0f / 3.0f, 1.0f});
            CHECK(result == Result::Success);
            if (result != Result::Success) delete thirds;
        }
        CHECK(other->viewport(child, viewport) == Result::InvalidArguments);
        CHECK(child->viewport(parent, viewport) == Result::InsufficientCondition);
    }
    delete other;
    delete parent;
    if (!parent || !child || !other || !childObject) {
        delete child;
        delete childObject;
        return;
    }

    Config rootConfig;
    rootConfig.width = 240;
    rootConfig.height = 120;
    rootConfig.background = Color::hex("#111820");
    auto root = Scene::gen(rootConfig);
    Config leftConfig;
    leftConfig.width = 120;
    leftConfig.height = 120;
    leftConfig.background = Color::hex("#d84040");
    leftConfig.camera.orthoHeight = 4.0f;
    auto left = Scene::gen(leftConfig);
    Config rightConfig = leftConfig;
    rightConfig.background = Color::hex("#4080d8");
    rightConfig.camera.orthoHeight = 8.0f;
    auto right = Scene::gen(rightConfig);
    CHECK(root && left && right);
    if (root && left && right) {
        CHECK(root->wait(0.2f) == Result::Success);
        CHECK(left->wait(0.8f) == Result::Success);
        CHECK(right->wait(1.4f) == Result::Success);
        CHECK(root->viewport(left, {0.0f, 0.0f, 0.5f, 1.0f}) == Result::Success);
        CHECK(root->viewport(right, {0.5f, 0.0f, 0.5f, 1.0f}) == Result::Success);
        CHECK(root->duration() == 1.4f);
        CHECK(root->sceneAt(0)->config().camera.orthoHeight == 4.0f);
        CHECK(root->sceneAt(1)->config().camera.orthoHeight == 8.0f);
        Surface surface;
        CHECK(renderer->render(root, root->duration(), surface) == Result::Success);
        if (surface.data()) {
            CHECK(surface.data()[60u * surface.stride() + 30u] == pixel(leftConfig.background));
            CHECK(surface.data()[60u * surface.stride() + 210u] == pixel(rightConfig.background));
        }
        root->config().width = 120;
        root->config().height = 60;
        CHECK(renderer->render(root, root->duration(), surface) == Result::Success);
        CHECK(surface.width() == 120 && surface.height() == 60);
        if (surface.data()) {
            CHECK(surface.data()[30u * surface.stride() + 15u] == pixel(leftConfig.background));
            CHECK(surface.data()[30u * surface.stride() + 105u] == pixel(rightConfig.background));
        }
    } else {
        delete left;
        delete right;
    }
    delete root;

    Config clipConfig;
    clipConfig.width = 100;
    clipConfig.height = 100;
    clipConfig.background = Color::hex("#101010");
    auto clipRoot = Scene::gen(clipConfig);
    auto clipChild = Scene::gen(clipConfig);
    auto clipSpace = _space();
    auto circle = Circle::gen({}, 10.0f);
    CHECK(clipRoot && clipChild && clipSpace && circle);
    if (clipRoot && clipChild && clipSpace && circle) {
        clipChild->config().background.a = 0;
        circle->style.stroke.a = 0;
        circle->fill(Color::hex("#40d8a0"));
        CHECK(clipSpace->add(circle) == Result::Success);
        CHECK(clipChild->add(clipSpace) == Result::Success);
        CHECK(clipRoot->viewport(clipChild, {0.25f, 0.25f, 0.5f, 0.5f}) == Result::Success);
        Surface surface;
        CHECK(renderer->render(clipRoot, 0.0f, surface) == Result::Success);
        if (surface.data()) {
            CHECK(surface.data()[50u * surface.stride() + 10u] == pixel(clipConfig.background));
            CHECK(surface.data()[50u * surface.stride() + 50u] == pixel(Color::hex("#40d8a0")));
            CHECK(surface.data()[50u * surface.stride() + 90u] == pixel(clipConfig.background));
        }
    } else {
        delete clipChild;
        delete clipSpace;
        delete circle;
    }
    delete clipRoot;

    Config groupConfig;
    groupConfig.width = 64;
    groupConfig.height = 64;
    groupConfig.background = Color::hex("#101010");
    groupConfig.camera.orthoHeight = 4.0f;
    auto groupRoot = Scene::gen(groupConfig);
    auto first = Scene::gen(groupConfig);
    auto second = Scene::gen(groupConfig);
    auto firstSpace = _space();
    auto secondSpace = _space();
    auto firstCircle = Circle::gen({}, 1.5f);
    auto secondCircle = Circle::gen({}, 1.0f);
    CHECK(groupRoot && first && second && firstSpace && secondSpace && firstCircle && secondCircle);
    if (groupRoot && first && second && firstSpace && secondSpace && firstCircle && secondCircle) {
        first->config().background.a = 0;
        second->config().background.a = 0;
        firstCircle->style.stroke.a = 0;
        secondCircle->style.stroke.a = 0;
        firstCircle->fill(Color::hex("#d84040"));
        secondCircle->fill(Color::hex("#4080d8"));
        firstCircle->layer = 100;
        secondCircle->layer = -100;
        CHECK(firstSpace->add(firstCircle) == Result::Success);
        CHECK(secondSpace->add(secondCircle) == Result::Success);
        CHECK(first->add(firstSpace) == Result::Success);
        CHECK(second->add(secondSpace) == Result::Success);
        CHECK(groupRoot->viewport(first, {}) == Result::Success);
        CHECK(groupRoot->viewport(second, {}) == Result::Success);
        Surface surface;
        CHECK(renderer->render(groupRoot, 0.0f, surface) == Result::Success);
        if (surface.data()) {
            CHECK(surface.data()[32u * surface.stride() + 32u] == pixel(Color::hex("#4080d8")));
            CHECK(surface.data()[2u * surface.stride() + 2u] == pixel(groupConfig.background));
        }
    } else {
        delete first;
        delete second;
        delete firstSpace;
        delete secondSpace;
        delete firstCircle;
        delete secondCircle;
    }
    delete groupRoot;

    auto nestedRoot = Scene::gen(clipConfig);
    auto middle = Scene::gen(clipConfig);
    auto leaf = Scene::gen(clipConfig);
    CHECK(nestedRoot && middle && leaf);
    if (nestedRoot && middle && leaf) {
        middle->config().background.a = 0;
        leaf->config().background = Color::hex("#7bd88f");
        CHECK(middle->viewport(leaf, {0.5f, 0.5f, 0.5f, 0.5f}) == Result::Success);
        CHECK(nestedRoot->viewport(middle, {0.0f, 0.0f, 0.5f, 0.5f}) == Result::Success);
        Surface surface;
        CHECK(renderer->render(nestedRoot, 0.0f, surface) == Result::Success);
        if (surface.data()) {
            CHECK(surface.data()[37u * surface.stride() + 37u] == pixel(Color::hex("#7bd88f")));
            CHECK(surface.data()[10u * surface.stride() + 10u] == pixel(clipConfig.background));
            CHECK(surface.data()[60u * surface.stride() + 60u] == pixel(clipConfig.background));
        }
    } else {
        delete middle;
        delete leaf;
    }
    delete nestedRoot;

    auto timedRoot = Scene::gen(groupConfig);
    auto timedChild = Scene::gen(groupConfig);
    auto timedSpace = _space();
    auto timedCircle = Circle::gen({}, 1.25f);
    CHECK(timedRoot && timedChild && timedSpace && timedCircle);
    if (timedRoot && timedChild && timedSpace && timedCircle) {
        timedChild->config().background.a = 0;
        timedCircle->style.stroke.a = 0;
        timedCircle->fill(Color::hex("#ffd166"));
        CHECK(timedSpace->add(timedCircle) == Result::Success);
        CHECK(timedChild->add(timedSpace) == Result::Success);
        CHECK(timedChild->play(Animation::create(timedCircle), 1.0f, Easing::Linear) == Result::Success);
        CHECK(timedRoot->viewport(timedChild, {}) == Result::Success);
        CHECK(timedRoot->duration() == 1.0f);
        Surface surface;
        CHECK(renderer->render(timedRoot, 0.0f, surface) == Result::Success);
        auto begin = checksum(surface);
        CHECK(renderer->render(timedRoot, 1.0f, surface) == Result::Success);
        CHECK(checksum(surface) != begin);
    } else {
        delete timedChild;
        delete timedSpace;
        delete timedCircle;
    }
    delete timedRoot;

    auto capacityRoot = Scene::gen();
    CHECK(capacityRoot != nullptr);
    if (capacityRoot) {
        for (auto i = 0u; i < 64u; i++) {
            auto item = Scene::gen();
            CHECK(item != nullptr);
            if (!item) break;
            auto result = capacityRoot->viewport(item, {});
            CHECK(result == Result::Success);
            if (result != Result::Success) delete item;
        }
        auto overflow = Scene::gen();
        CHECK(overflow != nullptr);
        if (overflow) {
            auto result = capacityRoot->viewport(overflow, {});
            CHECK(result == Result::InsufficientCondition);
            if (result != Result::Success) delete overflow;
        }
    }
    delete capacityRoot;

    auto chain = Scene::gen();
    CHECK(chain != nullptr);
    if (chain) {
        for (auto i = 0u; i < 15u; i++) {
            auto wrapper = Scene::gen();
            CHECK(wrapper != nullptr);
            if (!wrapper) break;
            auto result = wrapper->viewport(chain, {});
            CHECK(result == Result::Success);
            if (result != Result::Success) {
                delete wrapper;
                break;
            }
            chain = wrapper;
        }
        auto tooDeep = Scene::gen();
        CHECK(tooDeep != nullptr);
        if (tooDeep) {
            auto result = tooDeep->viewport(chain, {});
            CHECK(result == Result::InsufficientCondition);
            if (result == Result::Success) chain = nullptr;
            delete tooDeep;
        }
    }
    delete chain;

    auto budgetRoot = Scene::gen(groupConfig);
    auto sparse = Scene::gen(groupConfig);
    auto dense = Scene::gen(groupConfig);
    auto sparseSpace = _space();
    auto denseSpace = _space();
    auto sparseCircle = Circle::gen({}, 1.0f);
    auto cellA = Cell::gen({}, 128, 128, Color::hex("#ffffff"));
    auto cellB = Cell::gen({}, 128, 128, Color::hex("#ffffff"));
    auto cellC = Cell::gen({}, 128, 128, Color::hex("#ffffff"));
    auto cellD = Cell::gen({}, 128, 128, Color::hex("#ffffff"));
    CHECK(budgetRoot && sparse && dense && sparseSpace && denseSpace && sparseCircle
          && cellA && cellB && cellC && cellD);
    if (budgetRoot && sparse && dense && sparseSpace && denseSpace && sparseCircle
        && cellA && cellB && cellC && cellD) {
        sparseSpace->progress = 0.0f;
        denseSpace->progress = 0.0f;
        CHECK(sparseSpace->add(sparseCircle) == Result::Success);
        CHECK(denseSpace->add(cellA) == Result::Success);
        CHECK(denseSpace->add(cellB) == Result::Success);
        CHECK(denseSpace->add(cellC) == Result::Success);
        CHECK(denseSpace->add(cellD) == Result::Success);
        CHECK(sparse->add(sparseSpace) == Result::Success);
        CHECK(dense->add(denseSpace) == Result::Success);
        CHECK(budgetRoot->viewport(sparse, {}) == Result::Success);
        CHECK(budgetRoot->viewport(dense, {}) == Result::Success);
        Surface surface;
        CHECK(renderer->render(budgetRoot, 0.0f, surface) == Result::InsufficientCondition);
    } else {
        delete sparse;
        delete dense;
        delete sparseSpace;
        delete denseSpace;
        delete sparseCircle;
        delete cellA;
        delete cellB;
        delete cellC;
        delete cellD;
    }
    delete budgetRoot;
}

static void sceneTransitions(SwRenderer* renderer)
{
    Config config;
    config.width = 240;
    config.height = 120;
    config.camera.orthoHeight = 4.0f;
    config.antialiasing = false;
    auto root = Scene::gen(config);
    auto first = Scene::gen(config);
    auto second = Scene::gen(config);
    auto circle = Circle::gen({-1.4f, 0.0f, 0.0f}, 0.7f);
    auto rectangle = Rectangle::gen({1.25f, 0.0f, 0.0f}, {1.6f, 1.2f}, 0.18f);
    auto oldLabel = Text::gen("SCENE", {-1.4f, -1.25f, 0.0f});
    auto newLabel = Text::gen("SCENE", {1.25f, -1.25f, 0.0f});
    CHECK(root && first && second && circle && rectangle && oldLabel && newLabel);
    if (root && first && second && circle && rectangle && oldLabel && newLabel) {
        first->config().background = Color::hex("#111827");
        second->config().background = Color::hex("#172033");
        circle->fill(Color::hex("#4cc9f0")).stroke(Color::hex("#4cc9f0"), 3.0f).tag("hero");
        rectangle->fill(Color::hex("#f72585")).stroke(Color::hex("#f72585"), 3.0f).tag("hero");
        oldLabel->fill(Color::hex("#f4f7fb")).tag("label");
        newLabel->fill(Color::hex("#f4f7fb")).tag("label");
        CHECK(first->add(circle) == Result::Success);
        CHECK(first->add(oldLabel) == Result::Success);
        CHECK(second->add(rectangle) == Result::Success);
        CHECK(second->add(newLabel) == Result::Success);
        Scene* stages[] = {first, second};
        Scene* duplicate[] = {first, first};
        CHECK(root->transition(nullptr, 2u, {}, 1.0f, 0.25f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(root->transition(stages, 1u, {}, 1.0f, 0.25f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(root->transition(duplicate, 2u, {}, 1.0f, 0.25f, Easing::Linear)
              == Result::InvalidArguments);
        CHECK(root->transition(stages, 2u, {}, 1.0f, 0.25f, Easing::Linear)
              == Result::Success);
        CHECK(near(root->duration(), 1.5f));
        CHECK(root->transitionCount() == 2u);
        CHECK(root->transitionAt(0u) == first);
        CHECK(root->transitionAt(1u) == second);
        CHECK(root->transitionAt(2u) == nullptr);
        CHECK(first->wait(0.1f) == Result::InsufficientCondition);
        Surface surface;
        CHECK(renderer->render(root, 0.1f, surface) == Result::Success);
        auto from = checksum(surface);
        CHECK(renderer->render(root, 0.75f, surface) == Result::Success);
        auto middle = checksum(surface);
        CHECK(renderer->render(root, 1.4f, surface) == Result::Success);
        auto to = checksum(surface);
        CHECK(from != middle && middle != to && from != to);
    } else {
        delete first;
        delete second;
        delete circle;
        delete rectangle;
        delete oldLabel;
        delete newLabel;
    }
    delete root;
}

static void objectTree(SwRenderer* renderer)
{
    auto labelScene = Scene::gen();
    auto labelParent = Rectangle::gen({}, {2.0f, 1.0f});
    auto label = Text::gen("semantic label", {0.0f, 0.75f, 0.0f});
    auto labelOtherParent = Group::gen();
    CHECK(labelScene && labelParent && label && labelOtherParent);
    if (labelScene && labelParent && label && labelOtherParent) {
        label->tag("semantic-label");
        label->role = TextRole::H3;
        label->align = {0.5f, 1.0f};
        CHECK(labelParent->label(nullptr) == Result::InvalidArguments);
        auto parentResult = labelScene->add(labelParent);
        CHECK(parentResult == Result::Success);
        if (parentResult == Result::Success) {
            auto result = labelParent->label(label);
            CHECK(result == Result::Success);
            if (result == Result::Success) {
                CHECK(labelParent->childCount() == 1u && labelParent->childAt(0u) == label);
                CHECK(label->parent() == labelParent && labelScene->object("semantic-label") == label);
                CHECK(labelOtherParent->label(label) == Result::InvalidArguments);
            } else {
                delete label;
            }
        } else {
            delete labelParent;
            delete label;
        }
    } else {
        delete labelParent;
        delete label;
    }
    delete labelOtherParent;
    delete labelScene;

    Config config;
    config.width = 160;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto rectangle = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {1.0f, 1.0f});
    auto circle = Circle::gen({1.0f, 0.0f, 0.0f}, 0.5f);
    CHECK(scene && rectangle && circle);
    if (scene && rectangle && circle) {
        rectangle->style.stroke.a = 0;
        rectangle->fill(Color::hex("#ef5350"));
        circle->style.stroke.a = 0;
        circle->fill(Color::hex("#42a5f5"));
        auto rectangleResult = scene->add(rectangle);
        auto circleResult = scene->add(circle);
        CHECK(rectangleResult == Result::Success);
        CHECK(circleResult == Result::Success);
        if (rectangleResult == Result::Success && circleResult == Result::Success) {
            CHECK(scene->count() == 2);
            CHECK(scene->objectAt(0) == rectangle);
            CHECK(scene->objectAt(1) == circle);
            CHECK(rectangle->parent() == nullptr && rectangle->space() == nullptr);
            CHECK(circle->parent() == nullptr && circle->space() == nullptr);
            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) > 1000);
        }
        if (rectangleResult != Result::Success) delete rectangle;
        if (circleResult != Result::Success) delete circle;
    } else {
        delete rectangle;
        delete circle;
    }
    delete scene;

    auto outer = Group::gen();
    auto coordinates = Space::gen({0.0f, 1.0f, 1.0f}, {0.0f, 1.0f, 1.0f}, {0.0f, 0.0f, 1.0f});
    auto inner = Group::gen();
    auto item = Rectangle::gen({1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    CHECK(outer && coordinates && inner && item);
    if (outer && coordinates && inner && item) {
        outer->model = Mat4::translate({1.0f, 0.0f, 0.0f});
        coordinates->model = Mat4::scale({2.0f, 2.0f, 1.0f});
        inner->model = Mat4::translate({0.0f, 1.0f, 0.0f});
        coordinates->style.stroke.a = 0;
        coordinates->axisX.a = 0;
        coordinates->axisY.a = 0;
        coordinates->axisZ.a = 0;
        item->style.stroke.a = 0;
        item->fill(Color::hex("#ffd166"));
        auto itemResult = inner->add(item);
        CHECK(itemResult == Result::Success);
        if (itemResult == Result::Success) {
            auto innerResult = coordinates->add(inner);
            CHECK(innerResult == Result::Success);
            if (innerResult == Result::Success) {
                auto coordinatesResult = outer->add(coordinates);
                CHECK(coordinatesResult == Result::Success);
                if (coordinatesResult == Result::Success) {
                    CHECK(coordinates->parent() == outer);
                    CHECK(coordinates->space() == nullptr);
                    CHECK(inner->parent() == coordinates && inner->space() == coordinates);
                    CHECK(item->parent() == inner && item->space() == coordinates);
                    CHECK(outer->childCount() == 1 && outer->childAt(0) == coordinates);
                    CHECK(coordinates->count() == 1 && coordinates->objectAt(0) == inner);
                    auto world = coordinates->c2w({1.0f, 1.0f, 0.0f});
                    CHECK(near(world.x, 3.0f) && near(world.y, 2.0f));
                    Bounds bounds;
                    CHECK(item->bounds(bounds));
                    CHECK(near(bounds.center().x, 1.0f) && near(bounds.center().y, 0.0f));
                    CHECK(near(bounds.size().x, 0.5f) && near(bounds.size().y, 0.5f));
                    CHECK(inner->bounds(bounds));
                    CHECK(near(bounds.center().x, 1.0f) && near(bounds.center().y, 1.0f));
                    CHECK(outer->bounds(bounds));
                    CHECK(near(bounds.min.x, 1.0f) && near(bounds.min.y, 0.0f));
                    CHECK(near(bounds.max.x, 3.5f) && near(bounds.max.y, 2.5f));
                    auto mixedScene = Scene::gen(config);
                    CHECK(mixedScene != nullptr);
                    if (mixedScene) {
                        auto result = mixedScene->add(outer);
                        CHECK(result == Result::Success);
                        if (result == Result::Success) {
                            CHECK(mixedScene->count() == 4);
                            Surface surface;
                            CHECK(renderer->render(mixedScene, 0.0f, surface) == Result::Success);
                            CHECK(changed(surface, config.background) > 0);
                        } else {
                            delete outer;
                        }
                        delete mixedScene;
                        outer = nullptr;
                    }
                }
            }
        }
    }
    delete outer;

    auto self = Group::gen();
    CHECK(self != nullptr);
    if (self) {
        CHECK(self->add(self) == Result::InvalidArguments);
        CHECK(self->childCount() == 0);
    }
    delete self;

    auto ancestor = Group::gen();
    auto descendant = Group::gen();
    CHECK(ancestor && descendant);
    if (ancestor && descendant) {
        auto result = ancestor->add(descendant);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(descendant->add(ancestor) == Result::InvalidArguments);
            CHECK(descendant->childCount() == 0);
        } else {
            delete descendant;
        }
    }
    delete ancestor;

    auto firstParent = Group::gen();
    auto secondParent = Group::gen();
    auto reused = Circle::gen({}, 0.5f);
    CHECK(firstParent && secondParent && reused);
    if (firstParent && secondParent && reused) {
        auto result = firstParent->add(reused);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(secondParent->add(reused) == Result::InvalidArguments);
            CHECK(reused->parent() == firstParent);
        } else {
            delete reused;
        }
    }
    delete firstParent;
    delete secondParent;

    auto firstScene = Scene::gen();
    auto secondScene = Scene::gen();
    auto crossScene = Rectangle::gen();
    CHECK(firstScene && secondScene && crossScene);
    if (firstScene && secondScene && crossScene) {
        auto result = firstScene->add(crossScene);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(secondScene->add(crossScene) == Result::InvalidArguments);
        } else {
            delete crossScene;
        }
    }
    delete secondScene;
    delete firstScene;

    auto deadScene = Scene::gen();
    auto deadParent = Group::gen();
    CHECK(deadScene && deadParent);
    if (deadScene && deadParent) {
        auto result = deadScene->add(deadParent);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(deadScene->remove(deadParent) == Result::Success);
            auto late = Point::gen({});
            CHECK(late != nullptr);
            if (late) {
                CHECK(deadParent->add(late) == Result::InvalidArguments);
                delete late;
            }
        } else {
            delete deadParent;
        }
    }
    delete deadScene;

    auto depthScene = Scene::gen();
    auto depthRoot = Group::gen();
    CHECK(depthScene && depthRoot);
    if (depthScene && depthRoot) {
        auto result = depthScene->add(depthRoot);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            auto cursor = depthRoot;
            auto complete = true;
            for (auto i = 0u; i < 64u; i++) {
                auto next = Group::gen();
                CHECK(next != nullptr);
                if (!next) {
                    complete = false;
                    break;
                }
                auto added = cursor->add(next);
                CHECK(added == Result::Success);
                if (added != Result::Success) {
                    delete next;
                    complete = false;
                    break;
                }
                cursor = next;
            }
            if (complete) {
                auto overflow = Point::gen({});
                CHECK(overflow != nullptr);
                if (overflow) {
                    auto count = depthScene->count();
                    CHECK(cursor->add(overflow) == Result::InsufficientCondition);
                    CHECK(depthScene->count() == count);
                    CHECK(cursor->childCount() == 0);
                    delete overflow;
                }
            }
        } else {
            delete depthRoot;
        }
    }
    delete depthScene;
}

static void boundsAndLayout()
{
    auto group = Group::gen();
    auto anchor = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {2.0f, 1.0f});
    auto moving = Rectangle::gen({3.0f, 2.0f, 0.0f}, {1.0f, 2.0f});
    CHECK(group && anchor && moving);
    if (group && anchor && moving) {
        auto anchorResult = group->add(anchor);
        auto movingResult = group->add(moving);
        CHECK(anchorResult == Result::Success);
        CHECK(movingResult == Result::Success);
        if (anchorResult == Result::Success && movingResult == Result::Success) {
            Bounds anchorBounds;
            Bounds movingBounds;
            CHECK(anchor->bounds(anchorBounds));
            CHECK(near(anchorBounds.min.x, -2.0f) && near(anchorBounds.max.x, 0.0f));
            CHECK(near(anchorBounds.min.y, -0.5f) && near(anchorBounds.max.y, 0.5f));
            CHECK(near(anchorBounds.center().x, -1.0f));
            CHECK(near(anchorBounds.size().x, 2.0f) && near(anchorBounds.size().y, 1.0f));

            CHECK(moving->moveTo({0.0f, 1.0f, 0.0f}) == Result::Success);
            CHECK(moving->bounds(movingBounds));
            CHECK(near(movingBounds.center().x, 0.0f) && near(movingBounds.center().y, 1.0f));

            CHECK(moving->nextTo(anchor, {1.0f, 0.0f, 0.0f}, 0.5f) == Result::Success);
            CHECK(moving->bounds(movingBounds));
            CHECK(near(movingBounds.min.x, anchorBounds.max.x + 0.5f));
            CHECK(near(movingBounds.center().y, anchorBounds.center().y));

            CHECK(moving->alignTo(anchor, {0.0f, 1.0f, 0.0f}) == Result::Success);
            CHECK(moving->bounds(movingBounds));
            CHECK(near(movingBounds.max.y, anchorBounds.max.y));
            CHECK(moving->nextTo(anchor, {}, 0.5f) == Result::InvalidArguments);
            CHECK(moving->nextTo(anchor, {1.0f, 0.0f, 0.0f}, -0.1f) == Result::InvalidArguments);
            CHECK(moving->alignTo(anchor, {}) == Result::InvalidArguments);

            auto outsider = Rectangle::gen();
            CHECK(outsider != nullptr);
            if (outsider) {
                CHECK(moving->nextTo(outsider, {1.0f, 0.0f, 0.0f}) == Result::InvalidArguments);
                CHECK(moving->alignTo(outsider, {1.0f, 0.0f, 0.0f}) == Result::InvalidArguments);
            }
            delete outsider;

            Bounds groupBounds;
            CHECK(group->bounds(groupBounds));
            CHECK(groupBounds.min.x <= anchorBounds.min.x);
            CHECK(groupBounds.max.x >= movingBounds.max.x);
        }
        if (anchorResult != Result::Success) delete anchor;
        if (movingResult != Result::Success) delete moving;
    } else {
        delete anchor;
        delete moving;
    }
    delete group;

    auto row = Group::gen();
    auto rowA = Rectangle::gen({}, {1.0f, 1.0f});
    auto rowB = Rectangle::gen({}, {2.0f, 1.0f});
    auto rowC = Rectangle::gen({}, {0.5f, 1.0f});
    CHECK(row && rowA && rowB && rowC);
    if (row && rowA && rowB && rowC) {
        auto addedA = row->add(rowA);
        auto addedB = row->add(rowB);
        auto addedC = row->add(rowC);
        CHECK(addedA == Result::Success && addedB == Result::Success && addedC == Result::Success);
        if (addedA == Result::Success && addedB == Result::Success && addedC == Result::Success) {
            CHECK(row->arrange({1.0f, 0.0f, 0.0f}, 0.4f) == Result::Success);
            Bounds a;
            Bounds b;
            Bounds c;
            CHECK(rowA->bounds(a) && rowB->bounds(b) && rowC->bounds(c));
            CHECK(near(b.min.x - a.max.x, 0.4f));
            CHECK(near(c.min.x - b.max.x, 0.4f));
            CHECK(near(a.center().y, b.center().y) && near(b.center().y, c.center().y));
            CHECK(row->arrange({}, 0.4f) == Result::InvalidArguments);
            CHECK(row->arrange({1.0f, 0.0f, 0.0f}, -1.0f) == Result::InvalidArguments);
        }
        if (addedA != Result::Success) delete rowA;
        if (addedB != Result::Success) delete rowB;
        if (addedC != Result::Success) delete rowC;
    } else {
        delete rowA;
        delete rowB;
        delete rowC;
    }
    delete row;

    auto grid = Group::gen();
    auto gridA = Rectangle::gen();
    auto gridB = Rectangle::gen();
    auto gridC = Rectangle::gen();
    auto gridD = Rectangle::gen();
    CHECK(grid && gridA && gridB && gridC && gridD);
    if (grid && gridA && gridB && gridC && gridD) {
        auto addedA = grid->add(gridA);
        auto addedB = grid->add(gridB);
        auto addedC = grid->add(gridC);
        auto addedD = grid->add(gridD);
        CHECK(addedA == Result::Success && addedB == Result::Success
              && addedC == Result::Success && addedD == Result::Success);
        if (addedA == Result::Success && addedB == Result::Success
            && addedC == Result::Success && addedD == Result::Success) {
            CHECK(grid->arrangeGrid(0) == Result::InvalidArguments);
            CHECK(grid->arrangeGrid(2, -0.1f, 0.5f) == Result::InvalidArguments);
            CHECK(grid->arrangeGrid(2, 0.25f, 0.5f) == Result::Success);
            Bounds a;
            Bounds b;
            Bounds c;
            Bounds d;
            CHECK(gridA->bounds(a) && gridB->bounds(b) && gridC->bounds(c) && gridD->bounds(d));
            CHECK(near(b.min.x - a.max.x, 0.25f));
            CHECK(near(d.min.x - c.max.x, 0.25f));
            CHECK(near(a.min.y - c.max.y, 0.5f));
            CHECK(near(b.min.y - d.max.y, 0.5f));
            CHECK(near(a.center().x, c.center().x));
            CHECK(near(b.center().x, d.center().x));
        }
        if (addedA != Result::Success) delete gridA;
        if (addedB != Result::Success) delete gridB;
        if (addedC != Result::Success) delete gridC;
        if (addedD != Result::Success) delete gridD;
    } else {
        delete gridA;
        delete gridB;
        delete gridC;
        delete gridD;
    }
    delete grid;

    auto empty = Group::gen();
    CHECK(empty != nullptr);
    if (empty) {
        Bounds bounds;
        CHECK(!empty->bounds(bounds));
    }
    delete empty;
}

static void sceneUpdate(SwRenderer* renderer)
{
    Config config;
    config.width = 100;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto rectangle = Rectangle::gen({}, {1.0f, 1.0f});
    auto foreign = Rectangle::gen();
    CHECK(scene && rectangle && foreign);
    if (scene && rectangle && foreign) {
        rectangle->style.stroke.a = 0;
        rectangle->fill(Color::hex("#7bd88f"));
        auto result = scene->add(rectangle);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            auto original = checksum(surface);
            rectangle->center.x = 1.0f;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::InvalidArguments);
            CHECK(scene->update(nullptr) == Result::InvalidArguments);
            CHECK(scene->update(foreign) == Result::InvalidArguments);
            CHECK(scene->update(rectangle) == Result::Success);
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            CHECK(checksum(surface) != original);

            rectangle->layer = 4;
            CHECK(scene->update(rectangle) == Result::Success);
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);

            CHECK(scene->wait(0.0f) == Result::Success);
            rectangle->center.x = 1.5f;
            CHECK(scene->update(rectangle) == Result::InsufficientCondition);
            CHECK(renderer->render(scene, scene->duration(), surface) == Result::InvalidArguments);
            rectangle->center.x = 1.0f;
            CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
        } else {
            delete rectangle;
        }
    } else {
        delete rectangle;
    }
    delete foreign;
    delete scene;

    auto historical = Scene::gen(config);
    auto historicalRectangle = Rectangle::gen({}, {1.0f, 1.0f});
    CHECK(historical && historicalRectangle);
    if (historical && historicalRectangle) {
        historicalRectangle->style.stroke.a = 0;
        historicalRectangle->fill(Color::hex("#7bd88f"));
        auto result = historical->add(historicalRectangle);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            Surface surface;
            CHECK(renderer->render(historical, 0.0f, surface) == Result::Success);
            auto visible = checksum(surface);
            CHECK(historical->wait(1.0f) == Result::Success);
            CHECK(historical->play(Animation::create(historicalRectangle), 1.0f, Easing::Linear)
                  == Result::Success);
            CHECK(renderer->render(historical, 0.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(historical, 1.0f, surface) == Result::Success);
            CHECK(changed(surface, config.background) == 0u);
            CHECK(renderer->render(historical, 2.0f, surface) == Result::Success);
            CHECK(checksum(surface) == visible);
        } else {
            delete historicalRectangle;
        }
    } else {
        delete historicalRectangle;
    }
    delete historical;

    auto sealed = Scene::gen();
    auto removed = Rectangle::gen();
    auto retained = Rectangle::gen();
    CHECK(sealed && removed && retained);
    if (sealed && removed && retained) {
        CHECK(sealed->add(removed) == Result::Success);
        CHECK(sealed->add(retained) == Result::Success);
        CHECK(sealed->remove(removed) == Result::Success);
        retained->center.x = 1.0f;
        CHECK(sealed->update(retained) == Result::InsufficientCondition);
    } else {
        delete removed;
        delete retained;
    }
    delete sealed;
}

static void groupAndRectangleRendering(SwRenderer* renderer)
{
    Config config;
    config.width = 120;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto visible = Group::gen();
    auto hidden = Group::gen();
    auto visibleRectangle = Rectangle::gen({}, {1.0f, 1.0f});
    auto hiddenRectangle = Rectangle::gen({}, {1.0f, 1.0f});
    CHECK(scene && visible && hidden && visibleRectangle && hiddenRectangle);
    if (scene && visible && hidden && visibleRectangle && hiddenRectangle) {
        visible->model = Mat4::translate({1.5f, 0.0f, 0.0f});
        visible->opacity = 0.5f;
        hidden->model = Mat4::translate({-1.5f, 0.0f, 0.0f});
        hidden->progress = 0.0f;
        visibleRectangle->style.stroke.a = 0;
        hiddenRectangle->style.stroke.a = 0;
        visibleRectangle->fill(Color::hex("#f04040"));
        hiddenRectangle->fill(Color::hex("#40f040"));
        auto visibleChild = visible->add(visibleRectangle);
        auto hiddenChild = hidden->add(hiddenRectangle);
        CHECK(visibleChild == Result::Success && hiddenChild == Result::Success);
        if (visibleChild == Result::Success && hiddenChild == Result::Success) {
            auto visibleRoot = scene->add(visible);
            auto hiddenRoot = scene->add(hidden);
            CHECK(visibleRoot == Result::Success && hiddenRoot == Result::Success);
            if (visibleRoot == Result::Success && hiddenRoot == Result::Success) {
                Surface surface;
                CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
                if (surface.data()) {
                    auto background = pixel(config.background);
                    auto visiblePixel = surface.data()[40u * surface.stride() + 90u];
                    auto red = static_cast<uint8_t>(visiblePixel);
                    auto green = static_cast<uint8_t>(visiblePixel >> 8u);
                    CHECK(surface.data()[40u * surface.stride() + 30u] == background);
                    CHECK(surface.data()[40u * surface.stride() + 60u] == background);
                    CHECK(visiblePixel != background);
                    CHECK(red > 80u && red < 230u && red > green + 40u);
                }
            } else {
                if (visibleRoot != Result::Success) delete visible;
                if (hiddenRoot != Result::Success) delete hidden;
            }
        } else {
            if (visibleChild != Result::Success) delete visibleRectangle;
            if (hiddenChild != Result::Success) delete hiddenRectangle;
            delete visible;
            delete hidden;
        }
    } else {
        delete visible;
        delete hidden;
        delete visibleRectangle;
        delete hiddenRectangle;
    }
    delete scene;

    config.width = 100;
    config.height = 100;
    auto roundedScene = Scene::gen(config);
    auto rounded = Rectangle::gen({}, {2.0f, 2.0f}, 0.6f);
    CHECK(roundedScene && rounded);
    if (roundedScene && rounded) {
        rounded->style.stroke.a = 0;
        auto fill = Color::hex("#40d8a0");
        rounded->fill(fill);
        auto result = roundedScene->add(rounded);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            Surface surface;
            CHECK(renderer->render(roundedScene, 0.0f, surface) == Result::Success);
            if (surface.data()) {
                CHECK(surface.data()[50u * surface.stride() + 50u] == pixel(fill));
                CHECK(surface.data()[27u * surface.stride() + 73u] == pixel(config.background));
                CHECK(surface.data()[27u * surface.stride() + 50u] == pixel(fill));
            }
        } else {
            delete rounded;
        }
    } else {
        delete rounded;
    }
    delete roundedScene;
}

static void connectorAnimation(SwRenderer* renderer)
{
    Config config;
    config.width = 100;
    config.height = 100;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto source = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    auto destination = Rectangle::gen({1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    CHECK(scene && source && destination);
    if (scene && source && destination) {
        source->style.stroke.a = 0;
        source->style.fill.a = 0;
        destination->style.stroke.a = 0;
        destination->style.fill.a = 0;
        auto sourceResult = scene->add(source);
        auto destinationResult = scene->add(destination);
        CHECK(sourceResult == Result::Success && destinationResult == Result::Success);
        if (sourceResult == Result::Success && destinationResult == Result::Success) {
            auto transformedConnector = Connector::gen(source, destination);
            CHECK(transformedConnector != nullptr);
            if (transformedConnector) {
                transformedConnector->model = Mat4::translate({1.0f, 0.0f, 0.0f});
                CHECK(scene->add(transformedConnector) == Result::InvalidArguments);
                delete transformedConnector;
            }
            auto transformedGroup = Group::gen();
            auto transformedChild = Connector::gen(source, destination);
            CHECK(transformedGroup && transformedChild);
            if (transformedGroup && transformedChild) {
                transformedGroup->model = Mat4::translate({1.0f, 0.0f, 0.0f});
                auto childResult = transformedGroup->add(transformedChild);
                CHECK(childResult == Result::Success);
                if (childResult == Result::Success) {
                    CHECK(scene->add(transformedGroup) == Result::InvalidArguments);
                    delete transformedGroup;
                } else {
                    delete transformedChild;
                    delete transformedGroup;
                }
            } else {
                delete transformedChild;
                delete transformedGroup;
            }
            auto attachedEdgeGroup = Group::gen();
            CHECK(attachedEdgeGroup != nullptr);
            if (attachedEdgeGroup) {
                attachedEdgeGroup->model = Mat4::translate({1.0f, 0.0f, 0.0f});
                auto attachedResult = scene->add(attachedEdgeGroup);
                CHECK(attachedResult == Result::Success);
                if (attachedResult == Result::Success) {
                    auto rejected = Connector::gen(source, destination);
                    CHECK(rejected != nullptr);
                    if (rejected) {
                        CHECK(attachedEdgeGroup->add(rejected) == Result::InvalidArguments);
                        delete rejected;
                    }
                    auto originalModel = attachedEdgeGroup->model;
                    attachedEdgeGroup->model = Mat4::identity();
                    auto stale = Connector::gen(source, destination);
                    CHECK(stale != nullptr);
                    if (stale) {
                        CHECK(attachedEdgeGroup->add(stale) == Result::InvalidArguments);
                        delete stale;
                    }
                    attachedEdgeGroup->model = originalModel;
                } else {
                    delete attachedEdgeGroup;
                }
            }
            auto attachedNode = Group::gen();
            auto attachedEndpoint = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
            CHECK(attachedNode && attachedEndpoint);
            if (attachedNode && attachedEndpoint) {
                attachedNode->model = Mat4::translate({0.25f, 0.0f, 0.0f});
                attachedEndpoint->opacity = 0.0f;
                auto endpointResult = attachedNode->add(attachedEndpoint);
                CHECK(endpointResult == Result::Success);
                auto nodeResult = endpointResult == Result::Success ? scene->add(attachedNode) : Result::InvalidArguments;
                CHECK(nodeResult == Result::Success);
                if (nodeResult == Result::Success) {
                    auto outgoing = Connector::gen(attachedEndpoint, destination);
                    CHECK(outgoing != nullptr);
                    if (outgoing) {
                        outgoing->opacity = 0.0f;
                        auto outgoingResult = attachedNode->add(outgoing);
                        CHECK(outgoingResult == Result::Success);
                        if (outgoingResult != Result::Success) delete outgoing;
                    }
                } else {
                    if (endpointResult != Result::Success) delete attachedEndpoint;
                    delete attachedNode;
                }
            } else {
                delete attachedEndpoint;
                delete attachedNode;
            }
            auto edgeGroup = Group::gen();
            auto edgeChild = Connector::gen(source, destination);
            CHECK(edgeGroup && edgeChild);
            if (edgeGroup && edgeChild) {
                auto childResult = edgeGroup->add(edgeChild);
                CHECK(childResult == Result::Success);
                auto groupResult = childResult == Result::Success ? scene->add(edgeGroup) : Result::InvalidArguments;
                CHECK(groupResult == Result::Success);
                if (groupResult == Result::Success) {
                    auto originalModel = edgeGroup->model;
                    edgeGroup->model = Mat4::translate({1.0f, 0.0f, 0.0f});
                    CHECK(scene->update(edgeGroup) == Result::InvalidArguments);
                    edgeGroup->model = originalModel;
                    CHECK(scene->update(edgeGroup) == Result::Success);
                    CHECK(scene->play(Animation::shift(edgeGroup, {0.5f, 0.0f, 0.0f}))
                          == Result::InvalidArguments);
                    auto edgeTarget = AnimationTarget::from(edgeGroup);
                    edgeTarget.shift({0.5f, 0.0f, 0.0f});
                    CHECK(scene->play(edgeTarget) == Result::InvalidArguments);
                    CHECK(near(scene->duration(), 0.0f));
                } else {
                    if (childResult != Result::Success) delete edgeChild;
                    delete edgeGroup;
                }
            } else {
                delete edgeChild;
                delete edgeGroup;
            }
            auto connector = Connector::gen(source, destination);
            CHECK(connector != nullptr);
            if (connector) {
                connector->stroke(Color::hex("#ffd166"), 4.0f);
                connector->tail = 0.0f;
                connector->tip = 0.0f;
                CHECK(connector->from() == source && connector->to() == destination);
                auto connectorResult = scene->add(connector);
                CHECK(connectorResult == Result::Success);
                if (connectorResult == Result::Success) {
                    CHECK(scene->play(Animation::shift(connector, {0.5f, 0.0f, 0.0f}))
                          == Result::InvalidArguments);
                    auto connectorTarget = AnimationTarget::from(connector);
                    connectorTarget.shift({0.5f, 0.0f, 0.0f});
                    CHECK(scene->play(connectorTarget) == Result::InvalidArguments);
                    CHECK(near(scene->duration(), 0.0f));
                    auto target = AnimationTarget::from(destination);
                    target.shift({0.0f, 1.5f, 0.0f});
                    CHECK(scene->play(target, 1.0f, Easing::Linear) == Result::Success);
                    Surface surface;
                    CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
                    auto start = extent(surface, config.background);
                    CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
                    auto middle = extent(surface, config.background);
                    CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
                    auto end = extent(surface, config.background);
                    CHECK(start.valid && middle.valid && end.valid);
                    if (start.valid && middle.valid && end.valid) {
                        auto startHeight = start.maxY - start.minY;
                        auto middleHeight = middle.maxY - middle.minY;
                        auto endHeight = end.maxY - end.minY;
                        CHECK(start.minY > middle.minY && middle.minY > end.minY);
                        CHECK(startHeight + 4u < middleHeight);
                        CHECK(middleHeight + 4u < endHeight);
                    }
                } else {
                    delete connector;
                }
            }
        } else {
            if (sourceResult != Result::Success) delete source;
            if (destinationResult != Result::Success) delete destination;
        }
    } else {
        delete source;
        delete destination;
    }
    delete scene;

    auto graphScene = Scene::gen(config);
    auto graph = Group::gen();
    auto graphSource = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    auto graphDestination = Rectangle::gen({1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    auto graphConnector = Connector::gen(graphSource, graphDestination);
    CHECK(graphScene && graph && graphSource && graphDestination && graphConnector);
    if (graphScene && graph && graphSource && graphDestination && graphConnector) {
        CHECK(graph->add(graphSource) == Result::Success);
        CHECK(graph->add(graphDestination) == Result::Success);
        CHECK(graph->add(graphConnector) == Result::Success);
        graph->model = Mat4::translate({0.25f, 0.0f, 0.0f});
        auto graphResult = graphScene->add(graph);
        CHECK(graphResult == Result::Success);
        if (graphResult == Result::Success) {
            CHECK(graphScene->play(Animation::shift(graph, {0.5f, 0.0f, 0.0f}), 1.0f,
                                   Easing::Linear) == Result::Success);
            Surface surface;
            CHECK(renderer->render(graphScene, 0.5f, surface) == Result::Success);
        } else {
            delete graph;
        }
    } else {
        delete graphConnector;
        delete graphDestination;
        delete graphSource;
        delete graph;
    }
    delete graphScene;

    auto outgoingScene = Scene::gen(config);
    auto outside = Rectangle::gen({1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    auto node = Group::gen();
    auto inside = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {0.5f, 0.5f});
    auto outgoing = Connector::gen(inside, outside);
    CHECK(outgoingScene && outside && node && inside && outgoing);
    if (outgoingScene && outside && node && inside && outgoing) {
        auto outsideResult = outgoingScene->add(outside);
        CHECK(outsideResult == Result::Success);
        CHECK(node->add(inside) == Result::Success);
        CHECK(node->add(outgoing) == Result::Success);
        node->model = Mat4::translate({0.25f, 0.0f, 0.0f});
        auto nodeResult = outsideResult == Result::Success ? outgoingScene->add(node) : Result::InvalidArguments;
        CHECK(nodeResult == Result::Success);
        if (nodeResult == Result::Success) {
            CHECK(outgoingScene->play(Animation::shift(node, {0.5f, 0.0f, 0.0f}), 1.0f,
                                      Easing::Linear) == Result::Success);
        } else {
            delete node;
        }
        if (outsideResult != Result::Success) delete outside;
    } else {
        delete outgoing;
        delete inside;
        delete node;
        delete outside;
    }
    delete outgoingScene;
}

static void animationTargets(SwRenderer* renderer)
{
    Config config;
    config.width = 120;
    config.height = 80;
    config.camera.orthoHeight = 4.0f;
    config.antialiasing = false;
    auto scene = Scene::gen(config);
    auto first = Rectangle::gen({-1.0f, 0.0f, 0.0f}, {0.8f, 0.8f});
    auto second = Rectangle::gen({1.0f, 0.0f, 0.0f}, {0.8f, 0.8f});
    auto foreign = Rectangle::gen();
    CHECK(scene && first && second && foreign);
    if (scene && first && second && foreign) {
        first->fill(Color::hex("#ef5350"));
        second->fill(Color::hex("#42a5f5"));
        const float dash[] = {6.0f, 4.0f};
        CHECK(second->dash(dash, 2u) == Result::Success);
        auto firstResult = scene->add(first);
        auto secondResult = scene->add(second);
        CHECK(firstResult == Result::Success && secondResult == Result::Success);
        if (firstResult == Result::Success && secondResult == Result::Success) {
            auto firstModel = first->model;
            auto firstFill = first->style.fill;
            auto firstOpacity = first->opacity;

            auto atomicValid = AnimationTarget::from(first);
            atomicValid.shift({3.0f, 0.0f, 0.0f});
            auto atomicInvalid = AnimationTarget::from(second);
            atomicInvalid.opacity(std::numeric_limits<float>::quiet_NaN());
            AnimationTarget atomic[] = {atomicValid, atomicInvalid};
            CHECK(scene->play(atomic, 2, 1.0f, Easing::Linear, 0.25f) == Result::InvalidArguments);
            CHECK(near(scene->duration(), 0.0f));
            CHECK(near(first->model.e[3], firstModel.e[3]));
            CHECK(near(first->opacity, firstOpacity));
            CHECK(first->style.fill.r == firstFill.r && first->style.fill.g == firstFill.g
                  && first->style.fill.b == firstFill.b && first->style.fill.a == firstFill.a);

            auto duplicateShift = AnimationTarget::from(first);
            duplicateShift.shift({1.0f, 0.0f, 0.0f});
            auto duplicateOpacity = AnimationTarget::from(first);
            duplicateOpacity.opacity(0.5f);
            AnimationTarget duplicate[] = {duplicateShift, duplicateOpacity};
            CHECK(scene->play(duplicate, 2, 1.0f, Easing::Linear, 0.0f) == Result::InvalidArguments);
            CHECK(near(scene->duration(), 0.0f));
            CHECK(near(first->model.e[3], firstModel.e[3]) && near(first->opacity, firstOpacity));

            auto noProperties = AnimationTarget::from(first);
            CHECK(scene->play(noProperties) == Result::InvalidArguments);
            auto foreignTarget = AnimationTarget::from(foreign);
            foreignTarget.fill(Color::hex("#ffffff"));
            CHECK(scene->play(foreignTarget) == Result::InvalidArguments);
            auto nullTarget = AnimationTarget::from(nullptr);
            nullTarget.shift({1.0f, 0.0f, 0.0f});
            CHECK(scene->play(nullTarget) == Result::InvalidArguments);
            auto projective = Mat4::identity();
            projective.e[12] = 1.0f;
            auto invalidTransform = AnimationTarget::from(second);
            invalidTransform.transform(projective);
            CHECK(scene->play(invalidTransform) == Result::InvalidArguments);
            auto invalidShift = AnimationTarget::from(second);
            invalidShift.shift({std::numeric_limits<float>::quiet_NaN(), 0.0f, 0.0f});
            CHECK(scene->play(invalidShift) == Result::InvalidArguments);
            auto invalidDashTarget = AnimationTarget::from(first);
            invalidDashTarget.dashOffset(4.0f);
            CHECK(scene->play(invalidDashTarget) == Result::InvalidArguments);
            auto invalidDashValue = AnimationTarget::from(second);
            invalidDashValue.dashOffset(std::numeric_limits<float>::quiet_NaN());
            CHECK(scene->play(invalidDashValue) == Result::InvalidArguments);
            auto invalidMarkerTarget = AnimationTarget::from(first);
            invalidMarkerTarget.tip(8.0f);
            CHECK(scene->play(invalidMarkerTarget) == Result::InvalidArguments);
            CHECK(scene->play(static_cast<const AnimationTarget*>(nullptr), 1, 1.0f,
                              Easing::Linear, 0.0f) == Result::InvalidArguments);
            CHECK(scene->play(&noProperties, 0, 1.0f, Easing::Linear, 0.0f) == Result::InvalidArguments);
            CHECK(near(scene->duration(), 0.0f));

            Surface surface;
            CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
            auto start = checksum(surface);

            auto firstTarget = AnimationTarget::from(first);
            firstTarget.shift({2.0f, 0.0f, 0.0f})
                .opacity(0.4f)
                .stroke(Color::hex("#ffd166"))
                .fill(Color::hex("#40d890"));
            auto secondTarget = AnimationTarget::from(second);
            secondTarget.shift({-1.0f, 1.0f, 0.0f})
                .fill(Color::hex("#b060e8"))
                .dashOffset(-10.0f);
            AnimationTarget targets[] = {firstTarget, secondTarget};
            CHECK(scene->play(targets, 2, 2.0f, Easing::Linear, 0.25f) == Result::Success);
            CHECK(near(scene->duration(), 2.5f));
            CHECK(near(first->model.e[3], 2.0f) && near(first->model.e[7], 0.0f));
            CHECK(near(first->opacity, 0.4f));
            CHECK(first->style.stroke.r == Color::hex("#ffd166").r);
            CHECK(first->style.fill.g == Color::hex("#40d890").g);
            CHECK(near(second->model.e[3], -1.0f) && near(second->model.e[7], 1.0f));
            CHECK(second->style.fill.b == Color::hex("#b060e8").b);
            CHECK(near(second->style.dashOffset, -10.0f));

            CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
            auto middle = checksum(surface);
            CHECK(renderer->render(scene, 2.0f, surface) == Result::Success);
            auto staggered = checksum(surface);
            CHECK(renderer->render(scene, 2.5f, surface) == Result::Success);
            auto end = checksum(surface);
            CHECK(start != middle);
            CHECK(middle != end);
            CHECK(staggered != end);
        } else {
            if (firstResult != Result::Success) delete first;
            if (secondResult != Result::Success) delete second;
        }
    } else {
        delete first;
        delete second;
    }
    delete foreign;
    delete scene;
}

static void styleGroups(SwRenderer* renderer)
{
    auto inferredScene = Scene::gen();
    auto inferredMark = Line::gen({-1.0f, 0.0f}, {1.0f, 0.0f});
    auto inferredLabel = Text::gen("cycle", {0.0f, 0.5f});
    CHECK(inferredScene && inferredMark && inferredLabel);
    if (inferredScene && inferredMark && inferredLabel) {
        CHECK(inferredScene->add(inferredMark) == Result::Success);
        CHECK(inferredScene->add(inferredLabel) == Result::Success);
        auto automatic = inferredMark->style.stroke;
        StyleTarget inferredMembers[] = {
            {inferredMark, StyleChannel::Stroke},
            {inferredLabel, StyleChannel::Fill},
        };
        auto inferred = inferredScene->styleGroup(inferredMembers, 2u);
        CHECK(inferred != nullptr);
        CHECK(inferred && same(inferred->color(), automatic));
        CHECK(same(inferredLabel->style.fill, automatic));
        auto ambiguousMark = Line::gen({-1.0f, -0.5f}, {1.0f, -0.5f});
        CHECK(ambiguousMark != nullptr);
        if (ambiguousMark) {
            ambiguousMark->style.fill = Color::hex("#123456");
            CHECK(inferredScene->add(ambiguousMark) == Result::Success);
            StyleTarget ambiguous = {ambiguousMark, StyleChannel::Both};
            CHECK(inferredScene->styleGroup(&ambiguous, 1u) == nullptr);
        }
    } else {
        delete inferredMark;
        delete inferredLabel;
    }
    delete inferredScene;

    auto scene = Scene::gen();
    auto line = Line::gen({-1.0f, 0.0f}, {1.0f, 0.0f});
    auto label = Text::gen("identity", {0.0f, 0.5f});
    CHECK(scene && line && label);
    if (scene && line && label) {
        CHECK(scene->add(line) == Result::Success);
        CHECK(scene->add(label) == Result::Success);
        StyleTarget members[] = {
            {line, StyleChannel::Stroke},
            {label, StyleChannel::Fill},
        };
        auto group = scene->styleGroup(Color::hex("#4cc9f0"), members, 2u);
        CHECK(group != nullptr);
        if (group) {
            CHECK(group->count() == 2u);
            CHECK(same(line->style.stroke, Color::hex("#4cc9f0")));
            CHECK(same(label->style.fill, Color::hex("#4cc9f0")));
            CHECK(scene->style(group, Color::hex("#ef5350"), 0.5f, Easing::Linear)
                  == Result::Success);
            CHECK(same(group->color(), Color::hex("#ef5350")));
            CHECK(same(line->style.stroke, Color::hex("#ef5350")));
            CHECK(same(label->style.fill, Color::hex("#ef5350")));

            Surface surface;
            CHECK(renderer->render(scene, 0.25f, surface) == Result::Success);
            CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
        }
        CHECK(scene->styleGroup(Color::hex("#ffffff"), members, 2u) == nullptr);
        auto late = Circle::gen({0.0f, -0.5f}, 0.2f);
        CHECK(late != nullptr);
        if (late) {
            CHECK(scene->add(late) == Result::Success);
            CHECK(scene->styleBind(group, late, StyleChannel::Fill) == Result::Success);
            CHECK(same(late->style.fill, Color::hex("#ef5350")));
            CHECK(scene->remove(late) == Result::Success);
            CHECK(group && group->count() == 2u);
        }
    } else {
        delete line;
        delete label;
    }
    delete scene;

    scene = Scene::gen();
    Vec3 sourcePoints[] = {{-1.0f, -1.0f}, {1.0f, -1.0f}, {0.0f, 1.0f}};
    Vec3 targetPoints[] = {{-1.0f, 0.0f}, {1.0f, -1.0f}, {1.0f, 1.0f}};
    auto source = Polygon::gen(sourcePoints, 3u);
    auto target = Polygon::gen(targetPoints, 3u);
    CHECK(scene && source && target);
    if (scene && source && target) {
        target->stroke(Color::hex("#00ff00")).fill(Color::hex("#00ff00"));
        CHECK(scene->add(source) == Result::Success);
        CHECK(scene->add(target) == Result::Success);
        StyleTarget member = {source, StyleChannel::Both};
        auto group = scene->styleGroup(Color::hex("#ffd166"), &member, 1u);
        CHECK(group != nullptr);
        CHECK(scene->play(Animation::morph(source, target), 0.5f, Easing::Linear)
              == Result::Success);
        CHECK(group && group->count() == 1u && group->objectAt(0u) == target);
        CHECK(same(target->style.stroke, Color::hex("#ffd166")));
        CHECK(same(target->style.fill, Color::hex("#ffd166")));
        CHECK(scene->style(group, Color::hex("#42a5f5"), 0.5f, Easing::Linear)
              == Result::Success);
        CHECK(same(target->style.stroke, Color::hex("#42a5f5")));
        CHECK(same(target->style.fill, Color::hex("#42a5f5")));
    } else {
        delete source;
        delete target;
    }
    delete scene;

    scene = Scene::gen();
    auto badge = Circle::gen({}, 0.5f);
    auto resultText = Text::gen("result", {});
    CHECK(scene && badge && resultText);
    if (scene && badge && resultText) {
        CHECK(scene->add(badge) == Result::Success);
        StyleTarget member = {badge, StyleChannel::Fill};
        auto group = scene->styleGroup(Color::hex("#f72585"), &member, 1u);
        CHECK(group != nullptr);
        CHECK(scene->add(resultText) == Result::Success);
        CHECK(scene->fadeTransform(badge, resultText, 0.25f, Easing::Linear)
              == Result::Success);
        CHECK(group && group->count() == 1u && group->objectAt(0u) == resultText);
        CHECK(group && group->channelAt(0u) == StyleChannel::Fill);
        CHECK(same(resultText->style.fill, Color::hex("#f72585")));
    } else {
        delete badge;
        delete resultText;
    }
    delete scene;
}

static void pathAndCurveShapes(SwRenderer* renderer)
{
    Config config;
    config.width = 240;
    config.height = 120;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    PathCommand commands[] = {
        PathCommand::move({-2.4f, -0.6f, 0.0f}),
        PathCommand::line({-1.7f, 0.7f, 0.0f}),
        PathCommand::quadratic({-1.1f, 1.5f, 0.0f}, {-0.5f, 0.7f, 0.0f}),
        PathCommand::cubic({-0.1f, -0.2f, 0.0f}, {0.2f, -1.2f, 0.0f},
                           {0.7f, -0.6f, 0.0f}),
        PathCommand::close()};
    PathCommand invalid[] = {
        PathCommand::line({0.0f, 0.0f, 0.0f}),
        PathCommand::line({1.0f, 1.0f, 0.0f})};
    CHECK(Path::gen(invalid, 2u, 8u) == nullptr);
    CHECK(Path::gen(commands, 5u, 0u) == nullptr);
    CHECK(Curve::gen({}, {}, {}, {}, 0u) == nullptr);

    auto scene = Scene::gen(config);
    auto path = Path::gen(commands, 5u, 16u);
    auto curve = Curve::gen({0.9f, -0.7f, 0.0f}, {1.2f, 1.3f, 0.0f},
                            {2.0f, -1.3f, 0.0f}, {2.5f, 0.7f, 0.0f}, 24u);
    CHECK(scene && path && curve);
    if (scene && path && curve) {
        CHECK(path->type() == Type::Path && path->closed() && path->count() == 34u);
        CHECK(curve->type() == Type::Curve && curve->count() == 25u);
        Bounds bounds;
        CHECK(path->bounds(bounds));
        CHECK(bounds.min.x <= -2.4f && bounds.max.x >= 0.7f);
        path->stroke(Color::hex("#4cc9f0"), 3.0f).fill(Color::hex("#4cc9f044"));
        curve->stroke(Color::hex("#ffd166"), 4.0f);
        auto pathResult = scene->add(path);
        auto curveResult = scene->add(curve);
        CHECK(pathResult == Result::Success && curveResult == Result::Success);
        if (pathResult == Result::Success && curveResult == Result::Success) {
            Animation create[] = {Animation::create(path), Animation::create(curve)};
            CHECK(scene->play(create, 2u, 0.8f, Easing::Linear, 0.1f) == Result::Success);
            auto curveTarget = Curve::gen({0.9f, 0.7f, 0.0f}, {1.4f, -1.3f, 0.0f},
                                          {2.0f, 1.3f, 0.0f}, {2.5f, -0.7f, 0.0f}, 24u);
            PathCommand targetCommands[] = {
                PathCommand::move({-2.4f, 0.6f, 0.0f}),
                PathCommand::line({-1.7f, -0.7f, 0.0f}),
                PathCommand::quadratic({-1.1f, -1.5f, 0.0f}, {-0.5f, -0.7f, 0.0f}),
                PathCommand::cubic({-0.1f, 0.2f, 0.0f}, {0.2f, 1.2f, 0.0f},
                                   {0.7f, 0.6f, 0.0f}),
                PathCommand::close()};
            auto pathTarget = Path::gen(targetCommands, 5u, 16u);
            CHECK(curveTarget && pathTarget);
            if (curveTarget && pathTarget) {
                curveTarget->stroke(Color::hex("#7bd88f"), 4.0f);
                pathTarget->stroke(Color::hex("#f72585"), 3.0f).fill(Color::hex("#f7258544"));
                auto curveTargetResult = scene->add(curveTarget);
                CHECK(curveTargetResult == Result::Success);
                if (curveTargetResult == Result::Success) {
                    CHECK(scene->play(Animation::morph(curve, curveTarget), 0.5f,
                                      Easing::Linear) == Result::Success);
                } else {
                    delete curveTarget;
                }
                auto pathTargetResult = scene->add(pathTarget);
                CHECK(pathTargetResult == Result::Success);
                if (pathTargetResult == Result::Success) {
                    CHECK(scene->play(Animation::morph(path, pathTarget), 0.5f,
                                      Easing::Linear) == Result::Success);
                } else {
                    delete pathTarget;
                }
            } else {
                delete curveTarget;
                delete pathTarget;
            }
            Surface surface;
            CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
            CHECK(changed(surface, config.background) > 300u);
        } else {
            if (pathResult != Result::Success) delete path;
            if (curveResult != Result::Success) delete curve;
        }
    } else {
        delete path;
        delete curve;
    }
    delete scene;
}

static void pathFillAnimations(SwRenderer* renderer)
{
    Config config;
    config.width = 120;
    config.height = 120;
    config.camera.orthoHeight = 4.0f;
    config.background = Color::hex("#101010");
    PathCommand commands[] = {
        PathCommand::move({-1.0f, -1.0f, 0.0f}),
        PathCommand::line({1.0f, -1.0f, 0.0f}),
        PathCommand::line({1.0f, 1.0f, 0.0f}),
        PathCommand::line({-1.0f, 1.0f, 0.0f}),
        PathCommand::close()};
    auto scene = Scene::gen(config);
    auto path = Path::gen(commands, 5u, 8u);
    CHECK(scene && path);
    if (scene && path) {
        auto fill = Color::hex("#f72585");
        path->stroke(Color::hex("#f4f7fb"), 3.0f).fill(fill);
        auto result = scene->add(path);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(scene->play(Animation::drawBorderThenFill(path), 1.0f, Easing::Linear)
                  == Result::Success);
            Surface surface;
            auto center = static_cast<size_t>(60u) * 120u + 60u;
            CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
            CHECK(surface.data()[center] == pixel(config.background));
            CHECK(renderer->render(scene, 0.84f, surface) == Result::Success);
            auto partial = surface.data()[center];
            CHECK(partial != pixel(config.background));
            CHECK(partial != pixel(fill));
            CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
            CHECK(surface.data()[center] == pixel(fill));
        } else {
            delete path;
        }
    } else {
        delete path;
    }
    delete scene;

    scene = Scene::gen(config);
    path = Path::gen(commands, 5u, 8u);
    CHECK(scene && path);
    if (scene && path) {
        auto fill = Color::hex("#4cc9f0");
        path->stroke(Color::hex("#f4f7fb"), 3.0f).fill(fill);
        auto result = scene->add(path);
        CHECK(result == Result::Success);
        if (result == Result::Success) {
            CHECK(scene->play(Animation::create(path), 0.6f, Easing::Linear)
                  == Result::Success);
            CHECK(scene->play(Animation::fillReveal(path), 0.4f, Easing::Linear)
                  == Result::Success);
            Surface surface;
            auto center = static_cast<size_t>(60u) * 120u + 60u;
            CHECK(renderer->render(scene, 0.6f, surface) == Result::Success);
            CHECK(surface.data()[center] == pixel(config.background));
            CHECK(renderer->render(scene, 0.8f, surface) == Result::Success);
            auto partial = surface.data()[center];
            CHECK(partial != pixel(config.background));
            CHECK(partial != pixel(fill));
            CHECK(renderer->render(scene, 1.0f, surface) == Result::Success);
            CHECK(surface.data()[center] == pixel(fill));
        } else {
            delete path;
        }
    } else {
        delete path;
    }
    delete scene;
}

static void surfacePlaneTextAndWrite(SwRenderer* renderer)
{
    Vec3 points[] = {
        {-1.5f, 0.0f, -1.5f}, {0.0f, 0.4f, -1.5f}, {1.5f, 0.0f, -1.5f},
        {-1.5f, 0.2f, 0.0f}, {0.0f, 0.9f, 0.0f}, {1.5f, 0.2f, 0.0f},
        {-1.5f, 0.0f, 1.5f}, {0.0f, 0.4f, 1.5f}, {1.5f, 0.0f, 1.5f}};
    CHECK(SurfaceMesh::gen(nullptr, 3u, 3u) == nullptr);
    CHECK(SurfaceMesh::gen(points, 1u, 3u) == nullptr);
    auto surface = SurfaceMesh::gen(points, 3u, 3u);
    CHECK(surface != nullptr);
    if (surface) {
        CHECK(surface->type() == Type::SurfaceMesh);
        CHECK(surface->columns() == 3u && surface->rows() == 3u);
        CHECK(std::strcmp(type(surface->type()), "surface") == 0);
        surface->mode = SurfaceMode::Solid;
        Bounds bounds;
        CHECK(surface->bounds(bounds));
        CHECK(bounds.min.x == -1.5f && bounds.max.y == 0.9f && bounds.max.z == 1.5f);
    }

    Config config;
    config.width = 180;
    config.height = 140;
    config.cameraView = CameraView::ThreeD;
    config.camera.eye = {4.0f, 3.4f, 5.0f};
    config.camera.target = {};
    config.camera.projection = Projection::Perspective;
    config.camera.near = 0.1f;
    config.camera.far = 100.0f;
    config.background = Color::hex("#f7f8fc");
    auto scene = Scene::gen(config);
    auto text = Text::gen("plane", {0.0f, -0.1f, 1.8f});
    CHECK(scene && surface && text);
    if (scene && surface && text) {
        text->orientation = TextOrientation::Plane;
        text->size = 0.45f;
        text->fill(Color::hex("#172033"));
        CHECK(scene->add(surface) == Result::Success);
        CHECK(scene->add(text) == Result::Success);
        CHECK(scene->play(Animation::create(surface), 0.6f, Easing::Linear)
              == Result::Success);
        CHECK(scene->play(Animation::fadeIn(text), 0.2f, Easing::Linear)
              == Result::Success);
        Surface frame;
        CHECK(renderer->render(scene, scene->duration(), frame) == Result::Success);
        CHECK(changed(frame, config.background) > 400u);
        BBox textBounds;
        CHECK(renderer->bounds(scene, text, scene->duration(), textBounds) == Result::Success);
        CHECK(textBounds.width > 0.0f && textBounds.height > 0.0f);
    } else {
        delete surface;
        delete text;
    }
    delete scene;

    config.cameraView = CameraView::TwoD;
    config.camera = {};
    config.camera.orthoHeight = 4.0f;
    config.width = 120;
    config.height = 120;
    config.background = Color::hex("#101010");
    PathCommand commands[] = {
        PathCommand::move({-1.0f, -1.0f, 0.0f}),
        PathCommand::line({1.0f, -1.0f, 0.0f}),
        PathCommand::line({1.0f, 1.0f, 0.0f}),
        PathCommand::line({-1.0f, 1.0f, 0.0f}),
        PathCommand::close()};
    scene = Scene::gen(config);
    auto path = Path::gen(commands, 5u, 8u);
    CHECK(scene && path);
    if (scene && path) {
        auto fill = Color::hex("#ef6461");
        path->stroke(Color::hex("#ef6461"), 3.0f).fill(fill);
        CHECK(scene->add(path) == Result::Success);
        CHECK(scene->play(Animation::write(path), 1.0f, Easing::Linear)
              == Result::Success);
        Surface frame;
        auto center = static_cast<size_t>(60u) * 120u + 60u;
        CHECK(renderer->render(scene, 0.20f, frame) == Result::Success);
        CHECK(frame.data()[center] == pixel(config.background));
        CHECK(renderer->render(scene, 0.65f, frame) == Result::Success);
        CHECK(frame.data()[center] != pixel(config.background));
        CHECK(renderer->render(scene, 1.0f, frame) == Result::Success);
        CHECK(frame.data()[center] == pixel(fill));
    } else {
        delete path;
    }
    delete scene;
}

static void sceneThemes(SwRenderer* renderer)
{
    auto threeBlueOneEyes = Theme::preset(ThemePreset::ThreeBlueOneEyes);
    auto proWhite = Theme::preset(ThemePreset::ProWhite);
    auto proBlack = Theme::preset(ThemePreset::ProBlack);
    auto adaptiveVscode = Theme::preset(ThemePreset::AdaptiveVscode);
    auto legacyPro = Theme::preset(ThemePreset::Pro);
    CHECK(Theme::ColorLimit == 10u);
    Theme implicit;
    CHECK(threeBlueOneEyes.objectCount == 8u);
    CHECK(proWhite.objectCount == 8u);
    CHECK(proBlack.objectCount == 8u);
    CHECK(near(threeBlueOneEyes.objectWidth, 2.0f));
    CHECK(near(proWhite.objectWidth, 1.25f));
    CHECK(near(proBlack.objectWidth, 1.25f));
    CHECK(same(threeBlueOneEyes.background, Color::hex("#0d1117")));
    CHECK(same(adaptiveVscode.background, proWhite.background));
    CHECK(same(adaptiveVscode.objects[0], proWhite.objects[0]));
    CHECK(same(implicit.background, proWhite.background));
    CHECK(same(implicit.objects[0], proWhite.objects[0]));
    CHECK(same(proWhite.background, Color::hex("#ffffff")));
    CHECK(same(proWhite.objects[0], Color::hex("#b45f06")));
    CHECK(same(proBlack.background, Color::hex("#000000")));
    CHECK(same(proBlack.objects[0], Color::hex("#f28e2b")));
    CHECK(same(proBlack.h1.color, Color::hex("#ffffff")));
    CHECK(same(threeBlueOneEyes.color(ThemeColorRole::Accent), Color::hex("#4cc9f0")));
    CHECK(same(threeBlueOneEyes.color(ThemeColorRole::Warning), Color::hex("#ffd166")));
    CHECK(same(proWhite.color(ThemeColorRole::Danger), Color::hex("#b3261e")));
    CHECK(same(proBlack.color(ThemeColorRole::Success), Color::hex("#7ee787")));
    CHECK(same(proWhite.color(ThemeColorRole::Result), Color::hex("#8a6500")));
    CHECK(same(proBlack.color(ThemeColorRole::Focus), Color::hex("#6ea8fe")));
    CHECK(same(proBlack.color(ThemeColorRole::Background), proBlack.background));
    CHECK(same(legacyPro.background, proWhite.background));
    CHECK(same(legacyPro.objects[0], proWhite.objects[0]));
    CHECK(same(proWhite.axis.x, proWhite.axis.grid));
    CHECK(same(proWhite.axis.y, proWhite.axis.grid));
    CHECK(same(proWhite.axis.z, proWhite.axis.grid));
    CHECK(same(proWhite.axis.grid, Color::hex("#d8dadd")));
    CHECK(same(proBlack.axis.x, proBlack.axis.grid));
    CHECK(same(proBlack.axis.y, proBlack.axis.grid));
    CHECK(same(proBlack.axis.z, proBlack.axis.grid));
    CHECK(same(proBlack.axis.grid, Color::hex("#d8dadd")));
    CHECK(!threeBlueOneEyes.gradient && !proWhite.gradient && !proBlack.gradient);
    CHECK(same(threeBlueOneEyes.endGradientStop, Color::hex("#f72585")));
    CHECK(same(proWhite.endGradientStop, Color::hex("#666666")));
    CHECK(same(proBlack.endGradientStop, Color::hex("#999999")));

    Config config;
    CHECK(same(config.background, proWhite.background));
    auto scene = Scene::gen(config);
    CHECK(scene != nullptr);
    if (!scene) return;
    CHECK(same(scene->theme().background, proWhite.background));
    CHECK(same(scene->theme().objects[0], proWhite.objects[0]));
    CHECK(scene->theme(threeBlueOneEyes) == Result::Success);
    CHECK(same(scene->config().background, threeBlueOneEyes.background));
    CHECK(scene->theme(proWhite) == Result::Success);
    CHECK(same(scene->config().background, proWhite.background));
    CHECK(std::strcmp(scene->theme().h1.font, "Pretendard") == 0);

    auto title = Text::gen("Theme");
    auto axes = Space::gen();
    auto explicitLine = Line::gen({-1.0f, 0.0f}, {1.0f, 0.0f});
    CHECK(title && axes && explicitLine);
    if (!title || !axes || !explicitLine) {
        delete title;
        delete axes;
        delete explicitLine;
        delete scene;
        return;
    }
    title->role = TextRole::H1;
    explicitLine->stroke(Color::hex("#010203"));
    CHECK(scene->add(title) == Result::Success);
    CHECK(scene->add(axes) == Result::Success);
    CHECK(scene->add(explicitLine) == Result::Success);
    CHECK(title->size == proWhite.h1.size);
    CHECK(std::strcmp(title->font(), proWhite.h1.font) == 0);
    CHECK(same(title->style.fill, proWhite.h1.color));
    CHECK(same(axes->axisX, proWhite.axis.x));
    CHECK(same(axes->axisY, proWhite.axis.y));
    CHECK(same(axes->axisZ, proWhite.axis.z));
    CHECK(same(axes->style.stroke, proWhite.axis.grid));
    CHECK(same(axes->numberColor, proWhite.axis.label));
    CHECK(same(explicitLine->style.stroke, Color::hex("#010203")));
    CHECK(near(explicitLine->style.width, proWhite.objectWidth));

    Line* lines[7] = {};
    for (auto i = 0u; i < 7u; i++) {
        lines[i] = Line::gen({-1.0f, static_cast<float>(i)},
                             {1.0f, static_cast<float>(i)});
        CHECK(lines[i] != nullptr);
        if (lines[i]) CHECK(scene->add(lines[i]) == Result::Success);
    }
    if (lines[6]) {
        CHECK(same(lines[0]->style.stroke, proWhite.objects[0]));
        CHECK(same(lines[5]->style.stroke, proWhite.objects[5]));
        CHECK(same(lines[6]->style.stroke, proWhite.objects[6]));
        CHECK(near(lines[0]->style.width, proWhite.objectWidth));
    }

    auto filled = Point::gen({0.0f, 0.0f});
    auto authoredWidth = Line::gen({-1.0f, -1.0f}, {1.0f, -1.0f});
    Vec3 fillPoints[] = {
        {-1.0f, -1.0f}, {1.0f, -1.0f},
        {-1.0f, 1.0f}, {1.0f, 1.0f},
    };
    auto filledSurface = SurfaceMesh::gen(fillPoints, 2u, 2u);
    CHECK(filled && authoredWidth && filledSurface);
    if (filled) {
        CHECK(scene->add(filled) == Result::Success);
        CHECK(same(filled->style.stroke, proWhite.objects[7]));
        CHECK(same(filled->style.fill, proWhite.objects[7]));
        CHECK(filled->style.fill.a == 255u);
    }
    if (authoredWidth) {
        authoredWidth->strokeWidth(3.5f);
        CHECK(scene->add(authoredWidth) == Result::Success);
        CHECK(near(authoredWidth->style.width, 3.5f));
    }
    if (filledSurface) {
        filledSurface->shading = false;
        CHECK(scene->add(filledSurface) == Result::Success);
        CHECK(same(filledSurface->style.stroke, proWhite.objects[1]));
        CHECK(same(filledSurface->style.fill, proWhite.objects[1]));
        CHECK(filledSurface->style.fill.a == 255u);
    }
    CHECK(scene->theme(threeBlueOneEyes) == Result::InsufficientCondition);
    delete scene;

    auto editorial = proWhite;
    editorial.h1.font = "Source Serif 4";
    editorial.h2.font = "Source Serif 4";
    editorial.h3.font = "Source Serif 4";
    editorial.text.font = "Source Serif 4";
    editorial.code.font = "Source Serif 4";
    scene = Scene::gen();
    auto english = Text::gen("English explanation");
    auto korean = Text::gen(u8"한글 설명");
    auto explicitKorean = Text::gen(u8"사용자 폰트");
    CHECK(scene && english && korean && explicitKorean);
    if (scene && english && korean && explicitKorean) {
        CHECK(scene->theme(editorial) == Result::Success);
        english->role = TextRole::Code;
        korean->role = TextRole::H2;
        CHECK(explicitKorean->font("Pretendard") == Result::Success);
        CHECK(scene->add(english) == Result::Success);
        CHECK(scene->add(korean) == Result::Success);
        CHECK(scene->add(explicitKorean) == Result::Success);
        CHECK(std::strcmp(english->font(), "Source Serif 4") == 0);
        CHECK(std::strcmp(korean->font(), "IBM Plex Sans KR") == 0);
        CHECK(std::strcmp(explicitKorean->font(), "Pretendard") == 0);
    } else {
        delete english;
        delete korean;
        delete explicitKorean;
    }
    delete scene;

    auto invalid = threeBlueOneEyes;
    invalid.objectCount = 0u;
    scene = Scene::gen();
    CHECK(scene != nullptr);
    if (scene) CHECK(scene->theme(invalid) == Result::InvalidArguments);
    delete scene;

    invalid = threeBlueOneEyes;
    invalid.objectWidth = 0.0f;
    scene = Scene::gen();
    CHECK(scene != nullptr);
    if (scene) CHECK(scene->theme(invalid) == Result::InvalidArguments);
    delete scene;

    Config gradientConfig;
    gradientConfig.width = 200u;
    gradientConfig.height = 100u;
    gradientConfig.camera.orthoHeight = 4.0f;
    gradientConfig.background = Color::hex("#ffffff");
    auto gradientTheme = threeBlueOneEyes;
    gradientTheme.objects[0] = Color::hex("#ff0000");
    gradientTheme.objectCount = 1u;
    gradientTheme.gradient = true;
    gradientTheme.endGradientStop = Color::hex("#0000ff");
    scene = Scene::gen(gradientConfig);
    auto gradientRectangle = Rectangle::gen({}, {2.0f, 2.0f});
    auto explicitGradient = Line::gen({-1.0f, -1.5f}, {1.0f, -1.5f});
    auto disabledGradient = Line::gen({-1.0f, 1.5f}, {1.0f, 1.5f});
    auto directGradient = Line::gen({-1.0f, 1.8f}, {1.0f, 1.8f});
    CHECK(scene && gradientRectangle && explicitGradient && disabledGradient && directGradient);
    if (scene && gradientRectangle && explicitGradient && disabledGradient && directGradient) {
        CHECK(scene->theme(gradientTheme) == Result::Success);
        gradientRectangle->stroke(Color::hex("#00000000"), 0.0f)
                         .fill(Color::hex("#ff0000"));
        explicitGradient->gradient(Color::hex("#00ff00"));
        disabledGradient->gradient(false);
        directGradient->style.gradient = true;
        directGradient->style.gradientEnd = Color::hex("#00ffff");
        CHECK(scene->add(gradientRectangle) == Result::Success);
        CHECK(scene->add(explicitGradient) == Result::Success);
        CHECK(scene->add(disabledGradient) == Result::Success);
        CHECK(scene->add(directGradient) == Result::Success);
        CHECK(gradientRectangle->style.gradient);
        CHECK(same(gradientRectangle->style.gradientEnd, Color::hex("#0000ff")));
        CHECK(explicitGradient->style.gradient);
        CHECK(same(explicitGradient->style.gradientEnd, Color::hex("#00ff00")));
        CHECK(!disabledGradient->style.gradient);
        CHECK(directGradient->style.gradient);
        CHECK(same(directGradient->style.gradientEnd, Color::hex("#00ffff")));
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        auto left = surface.data()[50u * surface.stride() + 85u];
        auto right = surface.data()[50u * surface.stride() + 115u];
        CHECK(left != right);
        CHECK((left & 0xffu) > (right & 0xffu));
        CHECK(((left >> 16) & 0xffu) < ((right >> 16) & 0xffu));
    } else {
        delete gradientRectangle;
        delete explicitGradient;
        delete disabledGradient;
        delete directGradient;
    }
    delete scene;

    scene = Scene::gen();
    Vec3 sourcePoints[] = {{-1.0f, -1.0f}, {1.0f, -1.0f}, {0.0f, 1.0f}};
    Vec3 targetPoints[] = {{-1.0f, 0.0f}, {1.0f, -1.0f}, {1.0f, 1.0f}};
    auto source = Polygon::gen(sourcePoints, 3u);
    auto target = Polygon::gen(targetPoints, 3u);
    CHECK(scene && source && target);
    if (scene && source && target) {
        CHECK(scene->add(source) == Result::Success);
        auto sourceColor = source->style.stroke;
        CHECK(scene->add(target) == Result::Success);
        CHECK(!same(target->style.stroke, sourceColor));
        CHECK(scene->play(Animation::morph(source, target), 0.5f) == Result::Success);
        CHECK(same(target->style.stroke, sourceColor));
    } else {
        delete source;
        delete target;
    }
    delete scene;
}

static void runtimeModifiers(SwRenderer* renderer)
{
    Config config;
    config.cameraMode = CameraMode::Interactive;
    auto scene = Scene::gen(config);
    auto object = Rectangle::gen({}, {1.0f, 1.0f});
    RuntimeProbe probe;
    RuntimeModifier modifier;
    modifier.object = runtimeObject;
    modifier.camera = runtimeCamera;
    modifier.input = runtimeInput;
    modifier.data = &probe;
    CHECK(scene && object);
    if (scene && object) {
        CHECK(scene->add(object) == Result::Success);
        CHECK(scene->runtime(&modifier) == Result::Success);
        auto invalidAction = CameraInput{static_cast<CameraAction>(255u), {}};
        CHECK(scene->camera(invalidAction) == Result::InvalidArguments);
        CHECK(scene->camera({CameraAction::Pan,
                             {std::numeric_limits<float>::quiet_NaN(), 0.0f}})
              == Result::InvalidArguments);
        CHECK(probe.inputs == 0u);
        CHECK(scene->camera({CameraAction::Pan, {0.1f, 0.0f}}) == Result::Success);
        CHECK(probe.inputs == 1u);

        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(probe.cameras == 1u && probe.objects == 1u);
        probe.invalidateCamera = true;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::InvalidArguments);
        CHECK(probe.cameras == 2u);
        probe.invalidateCamera = false;
        scene->config().camera.near = -1.0f;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::InvalidArguments);
        CHECK(probe.cameras == 2u);
    } else {
        delete object;
    }
    delete scene;

    scene = Scene::gen(config);
    object = Rectangle::gen({}, {1.0f, 1.0f});
    probe = {};
    RuntimeProbe secondProbe;
    modifier = {};
    modifier.object = runtimeObject;
    modifier.camera = runtimeCamera;
    modifier.input = runtimeInput;
    modifier.data = &probe;
    uint8_t firstKey = 0u;
    uint8_t secondKey = 0u;
    modifier.key = &firstKey;
    auto second = modifier;
    second.data = &secondProbe;
    second.key = &secondKey;
    CHECK(scene && object);
    if (scene && object) {
        CHECK(scene->add(object) == Result::Success);
        CHECK(scene->runtime(&modifier) == Result::Success);
        CHECK(scene->runtime(&second) == Result::InsufficientCondition);
        CHECK(scene->runtimeAdd(&second) == Result::Success);
        CHECK(scene->runtimeAdd(&second) == Result::Success);
        auto conflicting = second;
        conflicting.key = &firstKey;
        CHECK(scene->runtimeAdd(&conflicting) == Result::InsufficientCondition);
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(probe.objects == 1u && secondProbe.objects == 1u);
        CHECK(probe.cameras == 1u && secondProbe.cameras == 1u);
        CHECK(scene->camera({CameraAction::Pan, {0.1f, 0.0f}}) == Result::Success);
        CHECK(probe.inputs == 1u && secondProbe.inputs == 0u);
        CHECK(scene->runtimeRemove(&probe) == Result::Success);
        CHECK(scene->camera({CameraAction::Pan, {0.1f, 0.0f}}) == Result::Success);
        CHECK(secondProbe.inputs == 1u);
        CHECK(scene->runtimeRemove(&probe) == Result::InsufficientCondition);
    } else {
        delete object;
    }
    delete scene;

    scene = Scene::gen();
    object = Rectangle::gen({}, {1.0f, 1.0f});
    probe = {};
    modifier = {};
    modifier.object = runtimeObject;
    modifier.data = &probe;
    CHECK(scene && object);
    if (scene && object) {
        CHECK(scene->add(object) == Result::Success);
        CHECK(scene->runtime(&modifier) == Result::Success);
        object->opacity = 2.0f;
        BBox bounds;
        CHECK(renderer->bounds(scene, object, 0.0f, bounds) == Result::InvalidArguments);
        CHECK(probe.objects == 0u);
    } else {
        delete object;
    }
    delete scene;

    scene = Scene::gen();
    object = Rectangle::gen({}, {1.0f, 1.0f});
    probe = {};
    probe.invalidateObject = true;
    modifier = {};
    modifier.object = runtimeObject;
    modifier.data = &probe;
    CHECK(scene && object);
    if (scene && object) {
        CHECK(scene->add(object) == Result::Success);
        CHECK(scene->runtime(&modifier) == Result::Success);
        BBox bounds;
        CHECK(renderer->bounds(scene, object, 0.0f, bounds) == Result::InvalidArguments);
        CHECK(probe.objects == 1u);
    } else {
        delete object;
    }
    delete scene;
}

int main()
{
    auto renderer = SwRenderer::gen();
    CHECK(renderer != nullptr);
    if (renderer) {
        scene2D(renderer);
        coplanarDrawOrder(renderer);
        rendererPixelSampling(renderer);
        spaceNumbers(renderer);
        renderBounds(renderer);
        dashedStrokes(renderer);
        textAnimationRegression(renderer);
        repeatedCreateRegression(renderer);
        drawDirectionAnimations(renderer);
        arrowCompositing(renderer);
        directedRouteRendering(renderer);
        fadeAnimations(renderer);
        scaleAndIndicateAnimations(renderer);
        morphAnimations(renderer);
        scene3D(renderer);
        assetsAndCells(renderer);
        voxelSamples(renderer);
        cellSamples();
        sampleTime(renderer);
        dimensionTransition(renderer);
        viewports(renderer);
        sceneTransitions(renderer);
        objectTree(renderer);
        boundsAndLayout();
        sceneUpdate(renderer);
        groupAndRectangleRendering(renderer);
        connectorAnimation(renderer);
        animationTargets(renderer);
        styleGroups(renderer);
        pathAndCurveShapes(renderer);
        pathFillAnimations(renderer);
        surfacePlaneTextAndWrite(renderer);
        sceneThemes(renderer);
        runtimeModifiers(renderer);
        boundaries(renderer);
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
        videoCadence(renderer);
#endif
    }
    delete renderer;
    if (failures) std::fprintf(stderr, "%d checks failed\n", failures);
    return failures ? 1 : 0;
}
