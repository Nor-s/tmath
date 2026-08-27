#include <cmath>
#include <clocale>
#include <cstdio>
#include <cstring>

#include "tmath.h"

using namespace tmath;

static auto _failures = 0;

static void _check(bool condition, const char* expression, int line)
{
    if (condition) return;
    std::fprintf(stderr, "%s:%d: CHECK(%s) failed\n", __FILE__, line, expression);
    _failures++;
}

#define CHECK(condition) _check((condition), #condition, __LINE__)

static constexpr auto _scene2d = R"lua(
if type(table) ~= "table" or type(string) ~= "table" or type(math) ~= "table" or type(utf8) ~= "table" then
    error("safe libraries are unavailable")
end
if io or os or package or debug or dofile or loadfile or load or pairs or next or pcall or xpcall or print or warn or collectgarbage or getmetatable or setmetatable or math.randomseed then error("unsafe library is available") end
if string.find or string.match or string.gmatch or string.gsub then error("unbounded pattern library is available") end
if tostring(1.5) ~= "1.5" or string.format("%.1f", 1.5) ~= "1.5" then error("deterministic formatting is unavailable") end
local s = tmath.scene {
    width = 320, height = 180, fps = 24, loop = true, background = "#0d1117",
    camera = {mode = "fixed", view = "2d", target = {0, 0}, height = 6}
}
local space = s:space {
    x = {-5, 5, 1}, y = {-3, 3, 1}, axis_x = "#ef5350", axis_y = "#66bb6a", id = "plane"
}
local arrow = space:arrow {
    from = {0, 0}, to = {2.5, 1.5}, tail = 8, tip = 10,
    color = "#ffd166", width = 4, id = "vector"
}
local point = space:point {
    point = {2.5, 1.5}, fill = "#4cc9f0", radius = 7, id = "tip"
}
s:create({space, arrow, point}, 0.75, "linear", 0.1)
s:shift(arrow, {0.5, -0.25}, 0.5, "smooth")
s:fade(point, 0.5, 0.25, "ease_out")
s:wait(0.25)
if math.abs(s:duration() - 1.9) > 0.0001 then error("duration mismatch") end
return s
)lua";

static constexpr auto _scene3d = R"lua(
local s = tmath.scene {
    width = 320, height = 180, background = "#0d1117",
    camera = {mode = "fixed", view = "3d",
        eye = {6, 5, 7}, target = {0, 0, 0}, up = {0, 1, 0},
        projection = "perspective", fov = 0.8, near = 0.1, far = 100
    }
}
local space = s:space {
    x = {-3, 3, 1}, y = {-3, 3, 1}, z = {-3, 3, 1}, id = "space"
}
local vector = space:vector {
    value = {2.5, 1.5, 2}, tail = 9, tip = 14,
    color = "#ffd166", width = 4, id = "space-vector"
}
local line = space:line {
    from = {-2, -1, -1}, to = {2, 1, 1}, color = "#4cc9f0", id = "diagonal"
}
s:create({space, vector, line}, 0.6, "smooth", 0.2)
s:shift(vector, {0, 0.5, 0}, 0.4, "linear")
return s
)lua";

static constexpr auto _plot = R"lua(
local s = tmath.scene {
    width = 320, height = 180, background = "#0d1117",
    camera = {view = "2d", height = 6}
}
local axes = s:space {x = {-4, 4, 1}, y = {-3, 3, 1}}
local sine = axes:plot {
    fn = function(x) return math.sin(x) end,
    x_range = {-3.14, 3.14, 0.08}, color = "#4cc9f0", width = 3, id = "sine"
}
local samples = axes:plot {
    points = {{-2, 2}, {-1, 0.5}, {0, 0}, {1, 0.5}, {2, 2}},
    color = "#ffd166", width = 2, id = "samples"
}
s:create({axes, sine, samples}, 0.5, "ease_in_out", 0.1)
return s
)lua";

static constexpr auto _route = R"lua(
local s = tmath.scene {
    width = 320, height = 180, background = "#0d1117",
    camera = {view = "2d", height = 6}
}
local axes = s:space {x = {-4, 4, 1}, y = {-3, 3, 1}}
local route = axes:route {
    points = {{-3, 1}, {0, 1}, {0, -1}, {3, -1}},
    tail = 10, tip = 18, stroke = "#4cc9f0", width = 4,
    dash = {10, 6}, dash_offset = 0, id = "route"
}
local marker = axes:point {point = {0, 0}, radius = 4, fill = "#ffd166"}
s:create({axes, route, marker}, 0.5, "linear")
s:play({target = route, dash_offset = -8, tail = 14, tip = 22}, 0.5, "linear")
return s
)lua";

static constexpr auto _path = R"lua(
local s = tmath.scene {
    width = 320, height = 180, background = "#0d1117",
    camera = {view = "2d", height = 6}
}
local axes = s:space {x = {-4, 4, 1}, y = {-3, 3, 1}}
local outline = axes:path {
    commands = {
        {type = "move", to = {-2.5, -1}},
        {type = "line", to = {-1.7, 1}},
        {type = "quadratic", control = {-0.7, 2}, to = {0, 1}},
        {type = "cubic", control1 = {0.7, 0.2}, control2 = {1.4, -1.7}, to = {2.5, -0.8}},
        {type = "close"}
    },
    samples = 16, stroke = "#4cc9f0", fill = "#4cc9f044", width = 3, id = "outline"
}
local bezier = axes:curve {
    from = {-2.4, -1.8}, control1 = {-0.8, 0.8}, control2 = {0.8, -0.8}, to = {2.4, 1.8},
    samples = 32, stroke = "#ffd166", width = 4, id = "bezier"
}
s:create({axes, outline, bezier}, 0.5, "ease_in_out", 0.1)
return s
)lua";

static constexpr auto _surface = R"lua(
local s = tmath.scene {
    width = 320, height = 180, background = "#f7f8fc",
    camera = {view = "3d", eye = {4, 3, 5}, target = {0, 0, 0},
        up = {0, 1, 0}, projection = "perspective", near = 0.1, far = 100}
}
local surface = s:surface {
    points = {{-1, 0, -1}, {1, 0, -1}, {-1, 0.5, 1}, {1, 0.5, 1}},
    size = {2, 2}, mode = "solid", shading = false, fill = "#5271e8", id = "surface"
}
local label = s:text {
    text = "plane", point = {0, -0.2, 1.3}, orientation = "plane",
    size = 0.4, fill = "#172033", id = "plane-label"
}
local contour = s:path {
    commands = {{type="move", to={-1, -1}}, {type="line", to={1, -1}},
        {type="line", to={1, 1}}, {type="line", to={-1, 1}}, {type="close"}},
    fill = "#ef6461", stroke = "#ef6461", id = "contour"
}
s:create(surface, 0.2, "linear")
s:write(contour, 0.4, "gentle")
return s
)lua";

static uint32_t _changed(const Surface& surface, Color background);
static bool _near(float lhs, float rhs);

static void _dash(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 200, height = 100, background = "#0d1117",
    camera = {view = "2d", height = 4}
}
scene:line {
    from = {-3, 0}, to = {3, 0}, stroke = "#ffffff", width = 2,
    dash = {8, 4}, dash_offset = 2, id = "dashed-line"
}
return scene
)lua";
    char error[256] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "dash.lua",
                            &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "dash.lua: %s\n", error);
    if (scene) {
        auto line = scene->object("dashed-line");
        CHECK(line != nullptr);
        if (line) {
            CHECK(line->style.dashCount == 2u);
            CHECK(_near(line->style.dash[0], 8.0f));
            CHECK(_near(line->style.dash[1], 4.0f));
            CHECK(_near(line->style.dashOffset, 2.0f));
        }
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
    }
    delete scene;

}

static uint32_t _changed(const Surface& surface, Color background)
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

static uint32_t _pixel(Color color)
{
    return static_cast<uint32_t>(color.a) << 24 | static_cast<uint32_t>(color.b) << 16
        | static_cast<uint32_t>(color.g) << 8 | color.r;
}

static bool _near(float lhs, float rhs)
{
    return std::fabs(lhs - rhs) < 1.0e-4f;
}

static void _render(SwRenderer* renderer, const char* source, const char* name, const char* tag,
                    Type type, float duration, bool loop, const char* output)
{
    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), name, &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success || !scene) {
        std::fprintf(stderr, "%s: %s\n", name, error);
        delete scene;
        return;
    }

    CHECK(std::fabs(scene->duration() - duration) < 1.0e-4f);
    CHECK(scene->config().loop == loop);
    CHECK(scene->count() == 3);
    auto object = scene->object(tag);
    CHECK(object != nullptr);
    if (object) CHECK(object->type() == type);

    Surface surface;
    status = renderer->render(scene, scene->duration(), surface);
    CHECK(status == Result::Success);
    if (status == Result::Success) {
        CHECK(surface.width() == scene->config().width);
        CHECK(surface.height() == scene->config().height);
        CHECK(_changed(surface, scene->config().background) > 100);
        CHECK(Saver::png(surface, output) == Result::Success);
    }
    delete scene;
}

static void _error(const char* source, const char* name, Lua::AssetResolver resolver = nullptr,
                   void* resolverData = nullptr)
{
    char error[512] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), name, &scene, error,
                            sizeof(error), resolver, resolverData);
    CHECK(status == Result::ScriptError);
    CHECK(scene == nullptr);
    CHECK(error[0] != '\0');
    auto location = std::strstr(error, name);
    CHECK(location != nullptr);
    if (location) CHECK(location[std::strlen(name)] == ':');
    delete scene;
}

static void _directRoot()
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {}
scene:point {point = {1, 2}, id = "root-point"}
return scene
)lua";
    char error[256] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "scene-object.lua",
                            &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "scene-object.lua: %s\n", error);
    if (scene) {
        CHECK(scene->count() == 1);
        auto point = scene->object("root-point");
        CHECK(point && point->type() == Type::Point);
        if (point) CHECK(point->parent() == nullptr && point->space() == nullptr);
    }
    delete scene;
}

static void _styleGroups()
{
    static constexpr auto source = R"lua(
local s = tmath.scene {}
local mark = s:line {from = {-1, 0}, to = {1, 0}, id = "mark"}
local label = s:text {text = "identity", point = {0, 0.5}, id = "label"}
local identity = s:style_group {
    members = {
        {target = mark, channel = "stroke"},
        {target = label, channel = "fill"}
    }
}
local copy = s:circle {center = {0, -0.5}, radius = 0.2, id = "copy"}
s:style_bind(identity, copy, "fill")
s:style(identity, "#ef5350", 0.4, "linear")
return s
)lua";
    char error[256] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                            "style-group.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    if (status != Result::Success) std::fprintf(stderr, "style-group.lua: %s\n", error);
    CHECK(scene != nullptr);
    if (scene) {
        auto mark = scene->object("mark");
        auto label = scene->object("label");
        auto copy = scene->object("copy");
        CHECK(mark && label && copy);
        if (mark && label && copy) {
            auto color = Color::hex("#ef5350");
            CHECK(mark->style.stroke.r == color.r && mark->style.stroke.g == color.g);
            CHECK(label->style.fill.r == color.r && label->style.fill.g == color.g);
            CHECK(copy->style.fill.r == color.r && copy->style.fill.g == color.g);
        }
    }
    delete scene;
}

static void _deterministic()
{
    static constexpr auto source = R"lua(
local s = tmath.scene {}
local world = s:space {}
world:point {point = {math.random(), math.random()}, id = "random"}
return s
)lua";
    char error[256] = {};
    Scene* first = nullptr;
    Scene* second = nullptr;
    auto size = static_cast<uint32_t>(std::strlen(source));
    CHECK(Lua::load(source, size, "random.lua", &first, error, sizeof(error)) == Result::Success);
    CHECK(Lua::load(source, size, "random.lua", &second, error, sizeof(error)) == Result::Success);
    if (first && second) {
        auto a = static_cast<Point*>(first->object("random"));
        auto b = static_cast<Point*>(second->object("random"));
        CHECK(a && b);
        if (a && b) CHECK(a->point.x == b->point.x && a->point.y == b->point.y);
    }
    delete first;
    delete second;

    static constexpr auto scaledCameraSource = R"lua(
return tmath.scene {
    camera = {view = "3d",
        eye = {0, 0, 0}, target = {0, 0, -1e-7}, up = {0, 1e-7, 0},
        near = 1e-8, far = 2
    }
}
)lua";
    Scene* scaledCamera = nullptr;
    size = static_cast<uint32_t>(std::strlen(scaledCameraSource));
    CHECK(Lua::load(scaledCameraSource, size, "scaled-camera.lua", &scaledCamera, error, sizeof(error)) == Result::Success);
    CHECK(scaledCamera != nullptr);
    delete scaledCamera;

    static constexpr auto inclusivePlotSource = R"lua(
local s = tmath.scene {}
local world = s:space {}
world:plot {fn = function(x) return x end, x_range = {0, 1, 0.1}, id = "inclusive"}
return s
)lua";
    Scene* inclusivePlot = nullptr;
    size = static_cast<uint32_t>(std::strlen(inclusivePlotSource));
    CHECK(Lua::load(inclusivePlotSource, size, "inclusive-plot.lua", &inclusivePlot, error, sizeof(error)) == Result::Success);
    CHECK(inclusivePlot != nullptr);
    if (inclusivePlot) {
        auto plot = static_cast<Plot*>(inclusivePlot->object("inclusive"));
        CHECK(plot != nullptr);
        if (plot) {
            CHECK(plot->count() == 11);
            CHECK(plot->points()[10].x == 1.0f && plot->points()[10].y == 1.0f);
        }
    }
    delete inclusivePlot;

    static constexpr auto nestedSource = R"lua(
local s = tmath.scene {}
local world = s:space {id = "world"}
local frame = world:space {id = "frame", opacity = 0}
frame:point {point = {1, 2, 3}, id = "joint"}
return s
)lua";
    Scene* nested = nullptr;
    size = static_cast<uint32_t>(std::strlen(nestedSource));
    CHECK(Lua::load(nestedSource, size, "nested.lua", &nested, error, sizeof(error)) == Result::Success);
    CHECK(nested != nullptr);
    if (nested) {
        auto world = nested->object("world");
        auto frame = nested->object("frame");
        auto joint = nested->object("joint");
        CHECK(world && frame && joint);
        if (world && frame && joint) CHECK(frame->space() == world && joint->space() == frame);
    }
    delete nested;

    static constexpr auto numberedSource = R"lua(
local s = tmath.scene {}
local world = s:space {
    numbers = true, number_mode = "relative", number_size = 13,
    number_color = "#123456", id = "numbered"
}
return s
)lua";
    Scene* numbered = nullptr;
    size = static_cast<uint32_t>(std::strlen(numberedSource));
    CHECK(Lua::load(numberedSource, size, "numbered.lua", &numbered, error, sizeof(error)) == Result::Success);
    CHECK(numbered != nullptr);
    if (numbered) {
        auto space = static_cast<Space*>(numbered->object("numbered"));
        CHECK(space != nullptr);
        if (space) {
            CHECK(space->numbers);
            CHECK(space->numberMode == NumberMode::Relative);
            CHECK(space->numberSize == 13.0f);
            CHECK(space->numberColor.r == 0x12 && space->numberColor.g == 0x34 && space->numberColor.b == 0x56);
        }
    }
    delete numbered;
}

static void _localeIndependent()
{
    auto current = std::setlocale(LC_NUMERIC, nullptr);
    if (!current || std::strlen(current) >= 128) return;
    char previous[128];
    std::memcpy(previous, current, std::strlen(current) + 1);

    const char* candidates[] = {"de_DE.UTF-8", "fr_FR.UTF-8", "fr_BE.UTF-8", nullptr};
    auto changed = false;
    for (auto candidate = candidates; *candidate; candidate++) {
        if (!std::setlocale(LC_NUMERIC, *candidate)) continue;
        auto info = std::localeconv();
        if (info && info->decimal_point && std::strcmp(info->decimal_point, ".")) {
            changed = true;
            break;
        }
    }
    if (!changed) {
        std::setlocale(LC_NUMERIC, previous);
        return;
    }

    static constexpr auto source = R"lua(
if tostring(1.5) ~= "1.5" then error("localized tostring") end
if "" .. 1.5 ~= "1.5" then error("localized concatenation") end
if string.format("%.1f", 1.5) ~= "1.5" then error("localized format") end
return tmath.scene {}
)lua";
    char error[256] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "locale.lua",
                            &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "locale.lua: %s\n", error);
    delete scene;
    CHECK(std::localeconv() && std::strcmp(std::localeconv()->decimal_point, "."));
    std::setlocale(LC_NUMERIC, previous);
}

static const Asset* _asset(const char* name, void* data)
{
    return std::strcmp(name, "pixels") == 0 ? static_cast<const Asset*>(data) : nullptr;
}

static void _assets(SwRenderer* renderer)
{
    uint32_t pixels[] = {0xff5040ff, 0xffffa040, 0xff66bb66, 0xffffd166};
    Asset* asset = nullptr;
    CHECK(AssetLoader::load(pixels, 2, 2, asset) == Result::Success);
    if (!asset) return;
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 320, height = 180, antialiasing = false,
    camera = {view = "2d", height = 6}
}
local world = scene:space {x = {-3, 3, 1}, y = {-2, 2, 1}, opacity = 0}
local image = world:image {
    asset = "pixels", center = {1.5, 0}, width = 2, id = "image"
}
local buffer = world:image {
    pixels = {"#ff4050", "#40a0ff", "#66bb66", "#ffd166"}, size = {2, 2},
    center = {0, 0}, width = 2, filter = "nearest", id = "buffer"
}
local cells = world:cell {
    origin = {-2.5, -1}, size = {2, 2}, padding = 0.05,
    texture = "pixels", source = {0, 0, 2, 2}, destination = {0, 0, 2, 2}, id = "cells"
}
scene:create({image, cells}, 0.4, "linear")
return scene
)lua";
    char error[512] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "assets.lua",
                            &scene, error, sizeof(error), _asset, asset);
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "assets.lua: %s\n", error);
    if (scene) {
        CHECK(!scene->config().antialiasing);
        CHECK(scene->object("image") && scene->object("image")->type() == Type::Image);
        CHECK(scene->object("buffer") && scene->object("buffer")->type() == Type::Image);
        auto buffer = static_cast<Image*>(scene->object("buffer"));
        CHECK(buffer && buffer->pixelWidth() == 2u && buffer->pixelHeight() == 2u);
        CHECK(buffer && buffer->pixels()[0] == _pixel(Color::hex("#ff4050")));
        CHECK(buffer && buffer->pixels()[3] == _pixel(Color::hex("#ffd166")));
        CHECK(scene->object("cells") && scene->object("cells")->type() == Type::Cell);
        Surface surface;
        CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 2000);
    }
    delete scene;

    _error("local s=tmath.scene{}; s:image{asset='pixels',filter={}}; return s",
           "image-filter.lua", _asset, asset);
    _error("local s=tmath.scene{}; s:image{asset='pixels',pixels={'#fff'},size={1,1}}; return s",
           "image-source.lua", _asset, asset);
    _error("local s=tmath.scene{}; s:image{pixels={'#fff'}}; return s",
           "image-size.lua");
    _error("local s=tmath.scene{}; s:image{pixels={'#fff'},size={2,1}}; return s",
           "image-pixels.lua");
    _error("local s=tmath.scene{}; s:cell{size={2,2},texture='pixels',source={'bad'}}; return s",
           "cell-region.lua", _asset, asset);
    _error("local s=tmath.scene{}; s:cell{size={2,2},patches={42}}; return s",
           "cell-patch.lua");
    delete asset;
}

static void _viewports(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local root = tmath.scene {width = 200, height = 100, background = "#101820"}
local left = tmath.scene {width = 100, height = 100, background = "#d84040", camera = {height = 4}}
local leftSpace = left:space {x = {-2, 2, 1}, y = {-2, 2, 1}, opacity = 0}
local leftVector = leftSpace:vector {value = {1.5, 1}, color = "#ffffff", width = 3}
left:create(leftVector, 0.5, "linear")
local right = tmath.scene {width = 100, height = 100, background = "#4080d8", camera = {height = 8}}
local rightSpace = right:space {x = {-4, 4, 1}, y = {-4, 4, 1}, opacity = 0}
local rightVector = rightSpace:vector {value = {-2, 2}, color = "#ffffff", width = 3}
right:create(rightVector, 1.2, "linear")
local edge = tmath.scene {width = 20, height = 20, background = "#00000000"}
root:viewport(left, {x = 0, y = 0, width = 0.5, height = 1})
root:viewport(right, {x = 0.5, y = 0, width = 0.5, height = 1})
root:viewport(edge, {x = 0.8, y = 0, width = 0.2, height = 0.2})
for i = 4, 64 do
    local child = tmath.scene {width = 1, height = 1, background = "#00000000"}
    root:viewport(child, {x = 0, y = 0, width = 0.01, height = 0.01})
end
return root
)lua";
    char error[512] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "viewports.lua",
                            &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "viewports.lua: %s\n", error);
    if (scene) {
        CHECK(scene->viewportCount() == 64);
        CHECK(scene->count() == 0);
        CHECK(scene->sceneAt(0) && scene->sceneAt(0)->count() == 2);
        CHECK(scene->sceneAt(1) && scene->sceneAt(1)->count() == 2);
        CHECK(std::fabs(scene->duration() - 1.2f) < 1.0e-4f);
        Surface surface;
        CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
        if (surface.data()) {
            CHECK(surface.data()[50u * surface.stride() + 20u] == _pixel(Color::hex("#d84040")));
            CHECK(surface.data()[50u * surface.stride() + 180u] == _pixel(Color::hex("#4080d8")));
        }
    }
    delete scene;

}

static void _sceneTransitions(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local root = tmath.scene {width = 200, height = 100, background = "#080d14", antialiasing = false}
local first = tmath.scene {width = 100, height = 100, background = "#101820", camera = {height = 4}}
first:circle {center = {-0.8, 0}, radius = 0.65, fill = "#4cc9f0", id = "hero"}
first:line {from = {-1.6, -1.2}, to = {0, -1.2}, stroke = "#7bd88f", width = 3, id = "guide-a"}
local second = tmath.scene {width = 200, height = 100, background = "#1c1730", camera = {height = 5}}
second:rectangle {center = {1.1, 0.2}, size = {1.8, 1.2}, corner = 0.16,
    fill = "#f72585", id = "hero"}
second:line {from = {0.2, -1.5}, to = {2, -1.5}, stroke = "#ffd166", width = 3, id = "guide-b"}
root:scene_transition({first, second}, {
    duration = 0.6, hold = 0.2, curve = "linear",
    viewport = {x = 0.1, y = 0.1, width = 0.8, height = 0.8}
})
if math.abs(root:duration() - 1.0) > 0.0001 then error("transition duration mismatch") end
return root
)lua";
    char error[512] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                            "scene-transition.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "scene-transition.lua: %s\n", error);
    if (scene) {
        CHECK(scene->count() == 0u);
        CHECK(std::fabs(scene->duration() - 1.0f) < 1.0e-4f);
        Surface surface;
        CHECK(renderer->render(scene, 0.1f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
        CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
        CHECK(renderer->render(scene, 0.9f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
    }
    delete scene;
}

static void _sceneTree(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 240, height = 160, background = "#101820", antialiasing = false,
    camera = {view = "2d", height = 10}
}

local root = scene:group {id = "root"}
local box = root:rectangle {
    center = {-2, 2}, size = {1.4, 0.8}, corner = 0.15,
    stroke = "#ef5350", fill = "#ef535044", width = 3, id = "box"
}
root:text {
    text = "root", point = {-2, 2}, fill = "#ffffff", progress = 0, id = "label"
}
local object_label = box:label {
    text = "box", point = {-2, 2.65}, fill = "#ffd166", role = "text",
    align = {0.5, 1}, size = 18, layer = 31, id = "object-label"
}
object_label:move_to({-2, 2.65})
box:circle {
    center = {-2, 2}, radius = 0.18, stroke = "#00000000", fill = "#ffd166", id = "shape-child"
}

local outer = scene:group {id = "outer"}
local coordinates = outer:space {
    x = {-3, 3, 1}, y = {-3, 3, 1}, opacity = 0, id = "coordinates"
}
local inner = coordinates:group {id = "inner"}
local mixed = inner:rectangle {
    center = {2, 2}, size = {0.8, 0.8}, stroke = "#42a5f5",
    fill = "#42a5f544", id = "mixed"
}

local pair = scene:group {id = "pair"}
local anchor = pair:rectangle {
    center = {-2, -1}, size = {1, 1}, fill = "#40d890", id = "anchor"
}
local moving = pair:rectangle {
    center = {2, -1}, size = {0.8, 1.4}, fill = "#b060e8", id = "moving"
}
moving:move_to({0, -1})
moving:next_to(anchor, {1, 0}, 0.3)
moving:align_to(anchor, {0, 1})

local row = scene:group {id = "row"}
local row_a = row:rectangle {size = {1, 0.6}, fill = "#ef5350", id = "row-a"}
local row_b = row:rectangle {size = {1.5, 0.6}, fill = "#66bb6a", id = "row-b"}
local row_c = row:rectangle {size = {0.5, 0.6}, fill = "#42a5f5", id = "row-c"}
row:arrange({1, 0}, 0.2)
row:move_to({2.5, -1.5})

local grid = scene:group {id = "grid"}
local grid_a = grid:rectangle {size = {1, 0.6}, fill = "#ef5350", id = "grid-a"}
local grid_b = grid:rectangle {size = {1, 0.6}, fill = "#66bb6a", id = "grid-b"}
local grid_c = grid:rectangle {size = {1, 0.6}, fill = "#42a5f5", id = "grid-c"}
local grid_d = grid:rectangle {size = {1, 0.6}, fill = "#ffd166", id = "grid-d"}
grid:arrange_grid(2, 0.25, 0.4)
grid:move_to({-3, -3})

scene:connector {
    from = anchor, to = moving, padding = 0.05,
    stroke = "#ffffff", width = 3, id = "connector"
}

scene:play({
    {target = box, shift = {0.5, 0}, opacity = 0.6,
     stroke = "#ffd166", fill = "#40d890"},
    {target = mixed, shift = {-0.5, 0}, fill = "#b060e8"}
}, 1.2, "linear", 0.25)
if math.abs(scene:duration() - 1.5) > 0.0001 then error("composite duration mismatch") end
return scene
)lua";

    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)), "scene-tree.lua",
                            &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "scene-tree.lua: %s\n", error);
    if (!scene) return;

    CHECK(scene->count() == 22);
    CHECK(_near(scene->duration(), 1.5f));
    auto root = scene->object("root");
    auto box = scene->object("box");
    auto label = scene->object("label");
    auto objectLabel = scene->object("object-label");
    auto shapeChild = scene->object("shape-child");
    auto outer = scene->object("outer");
    auto coordinates = scene->object("coordinates");
    auto inner = scene->object("inner");
    auto mixed = scene->object("mixed");
    CHECK(root && box && label && objectLabel && shapeChild && outer && coordinates && inner && mixed);
    if (root && box && label && objectLabel && shapeChild && outer && coordinates && inner && mixed) {
        CHECK(root->type() == Type::Group && root->parent() == nullptr && root->space() == nullptr);
        CHECK(box->type() == Type::Rectangle && box->parent() == root && box->space() == nullptr);
        CHECK(label->type() == Type::Text && label->parent() == root && label->space() == nullptr);
        CHECK(objectLabel->type() == Type::Text && objectLabel->parent() == box
              && objectLabel->space() == nullptr);
        auto text = static_cast<Text*>(objectLabel);
        CHECK(std::strcmp(text->text(), "box") == 0 && text->role == TextRole::Text);
        CHECK(_near(text->point.x, -2.0f) && _near(text->point.y, 2.65f));
        CHECK(_near(text->align.x, 0.5f) && _near(text->align.y, 1.0f));
        CHECK(_near(text->size, 18.0f) && text->layer == 31);
        CHECK(text->style.fill.r == 255u && text->style.fill.g == 209u
              && text->style.fill.b == 102u && text->style.fill.a == 255u);
        CHECK(shapeChild->type() == Type::Circle && shapeChild->parent() == box
              && shapeChild->space() == nullptr);
        CHECK(outer->type() == Type::Group && outer->parent() == nullptr);
        CHECK(coordinates->type() == Type::Space && coordinates->parent() == outer
              && coordinates->space() == nullptr);
        CHECK(inner->type() == Type::Group && inner->parent() == coordinates
              && inner->space() == coordinates);
        CHECK(mixed->type() == Type::Rectangle && mixed->parent() == inner
              && mixed->space() == coordinates);
        CHECK(_near(box->model.e[3], 0.5f) && _near(box->opacity, 0.6f));
        CHECK(box->style.stroke.r == 0xff && box->style.stroke.g == 0xd1);
        CHECK(box->style.fill.g == 0xd8 && box->style.fill.b == 0x90);
        CHECK(_near(mixed->model.e[3], -0.5f));
        CHECK(mixed->style.fill.r == 0xb0 && mixed->style.fill.b == 0xe8);
    }

    auto anchor = scene->object("anchor");
    auto moving = scene->object("moving");
    auto connector = scene->object("connector");
    CHECK(anchor && moving && connector);
    if (anchor && moving) {
        Bounds anchorBounds;
        Bounds movingBounds;
        CHECK(anchor->bounds(anchorBounds) && moving->bounds(movingBounds));
        CHECK(_near(movingBounds.min.x - anchorBounds.max.x, 0.3f));
        CHECK(_near(movingBounds.max.y, anchorBounds.max.y));
    }
    if (connector) {
        CHECK(connector->type() == Type::Connector);
        auto value = static_cast<Connector*>(connector);
        CHECK(value->from() == anchor && value->to() == moving);
        CHECK(_near(value->padding, 0.05f));
    }

    auto rowA = scene->object("row-a");
    auto rowB = scene->object("row-b");
    auto rowC = scene->object("row-c");
    CHECK(rowA && rowB && rowC);
    if (rowA && rowB && rowC) {
        Bounds a;
        Bounds b;
        Bounds c;
        CHECK(rowA->bounds(a) && rowB->bounds(b) && rowC->bounds(c));
        CHECK(_near(b.min.x - a.max.x, 0.2f));
        CHECK(_near(c.min.x - b.max.x, 0.2f));
    }

    auto gridA = scene->object("grid-a");
    auto gridB = scene->object("grid-b");
    auto gridC = scene->object("grid-c");
    auto gridD = scene->object("grid-d");
    CHECK(gridA && gridB && gridC && gridD);
    if (gridA && gridB && gridC && gridD) {
        Bounds a;
        Bounds b;
        Bounds c;
        Bounds d;
        CHECK(gridA->bounds(a) && gridB->bounds(b) && gridC->bounds(c) && gridD->bounds(d));
        CHECK(_near(b.min.x - a.max.x, 0.25f));
        CHECK(_near(d.min.x - c.max.x, 0.25f));
        CHECK(_near(a.min.y - c.max.y, 0.4f));
        CHECK(_near(b.min.y - d.max.y, 0.4f));
    }

    Surface surface;
    CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
    CHECK(_changed(surface, scene->config().background) > 500);
    delete scene;
}

static void _animationMethods(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 320, height = 180, background = "#101820", antialiasing = false,
    camera = {view = "2d", height = 8}
}

local forward = scene:line {from = {-3, 3}, to = {-1, 3}, stroke = "#4cc9f0", id = "forward"}
local reverse = scene:line {from = {1, 3}, to = {3, 3}, stroke = "#f72585", id = "reverse"}
scene:create({forward, reverse}, 0.1, "linear", 0.5, "forward")
scene:uncreate({forward, reverse}, 0.1, "linear", 0.5, "reverse")

local circle = scene:circle {center = {0, 2}, radius = 0.6, stroke = "#ffd166", id = "circle"}
scene:create(circle, 0.1, "linear", 0, "clockwise")
scene:uncreate(circle, 0.1, "linear", 0, "counterclockwise")

local fill_reveal = scene:rectangle {
    center = {-2.5, 2}, size = {0.8, 0.8}, fill = "#4cc9f0", stroke = "#f4f7fb",
    id = "fill-reveal"
}
scene:create(fill_reveal, 0.1, "linear")
scene:fill_reveal(fill_reveal, 0.1, "linear")

local border_fill = scene:rectangle {
    center = {2.5, 2}, size = {0.8, 0.8}, fill = "#f72585", stroke = "#f4f7fb",
    id = "border-fill"
}
scene:draw_border_then_fill(border_fill, 0.2, "linear", 0, "reverse")

local default_fade = scene:rectangle {
    center = {-2.5, 0.5}, size = {1.2, 0.7}, fill = "#4cc9f0", id = "default-fade"
}
scene:fade_in(default_fade)
scene:fade_out(default_fade)

local shifted_fade = scene:rectangle {
    center = {-0.8, 0.5}, size = {1.2, 0.7}, fill = "#f72585", id = "shifted-fade"
}
scene:fade_in(shifted_fade, {
    shift = {0, -0.4}, scale = 0.8, duration = 0.15,
    curve = {preset = "snappy", strength = 0.8}
})
scene:fade_out(shifted_fade, {
    shift = {0, 0.4}, scale = 1.1, duration = 0.15,
    curve = {bezier = {0.42, 0, 0.58, 1}, strength = 1.0, reverse = true}
})

local growing = scene:circle {
    center = {1, 0.5}, radius = 0.5, fill = "#7bd88f", id = "growing"
}
scene:grow_from_center(growing, 0.1, "smooth")
scene:grow_from_edge(growing, "bottom", 0.1, "smooth")
scene:shrink_to_center(growing, 0.1, "smooth")

local indicated = scene:rectangle {
    center = {2.5, 0.5}, size = {1.0, 0.7}, fill = "#4cc9f0", id = "indicated"
}
scene:indicate(indicated, {color = "#ffd166", scale = 1.25, duration = 0.2, easing = "smooth"})

local morph_source = scene:polygon {
    points = {{-3, -2.5}, {-1.8, -2.5}, {-2.4, -1.3}},
    fill = "#4cc9f055", stroke = "#4cc9f0", id = "morph-source"
}
local morph_target = scene:polygon {
    points = {{-3, -2.5}, {-1.8, -2.5}, {-1.8, -1.3}},
    fill = "#7bd88f55", stroke = "#7bd88f", id = "morph-target"
}
scene:morph(morph_source, morph_target, 0.2, "ease_in_out")
scene:indicate(morph_target, {duration = 0.1, scale = 1.1})

local replacement_source = scene:plot {
    points = {{0.5, -2.5}, {1.2, -1.3}, {1.9, -2.5}},
    stroke = "#ff6b6b", id = "replacement-source"
}
local replacement_target = scene:plot {
    points = {{0.5, -1.3}, {1.2, -2.5}, {1.9, -1.3}},
    stroke = "#7bd88f", id = "replacement-target"
}
scene:replacement_transform(replacement_source, replacement_target, 0.2, "ease_in_out")
scene:indicate(replacement_target, {color = "#ffd166", scale = 1.1, duration = 0.1})

local fade_source = scene:rectangle {
    center = {2.4, -2.0}, size = {0.8, 0.6}, fill = "#ff6b6b", id = "fade-source"
}
local fade_target = scene:circle {
    center = {2.4, -2.0}, radius = 0.4, fill = "#4cc9f0", id = "fade-target"
}
scene:fade_transform(fade_source, fade_target, 0.2, "gentle")

local batch_source_a = scene:plot {
    points = {{-3, -3.2}, {-2.4, -2.8}, {-1.8, -3.2}},
    stroke = "#4cc9f0", id = "batch-source-a"
}
local batch_source_b = scene:plot {
    points = {{0.5, -3.2}, {1.2, -2.8}, {1.9, -3.2}},
    stroke = "#f72585", id = "batch-source-b"
}
local batch_target_a = scene:plot {
    points = {{-3, -2.8}, {-2.4, -3.2}, {-1.8, -2.8}},
    stroke = "#7bd88f", id = "batch-target-a"
}
local batch_target_b = scene:plot {
    points = {{0.5, -2.8}, {1.2, -3.2}, {1.9, -2.8}},
    stroke = "#ffd166", id = "batch-target-b"
}
scene:morph(
    {batch_source_a, batch_source_b},
    {batch_target_a, batch_target_b},
    0.2, "ease_in_out", 0.25
)

if math.abs(scene:duration() - 4.75) > 0.0001 then error("animation duration mismatch") end
return scene
)lua";

    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                            "animation-methods.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "animation-methods.lua: %s\n", error);
    if (scene) {
        CHECK(scene->count() == 19u);
        CHECK(_near(scene->duration(), 4.75f));
        CHECK(scene->object("morph-target") != nullptr);
        CHECK(scene->object("replacement-target") != nullptr);
        CHECK(scene->object("fade-target") != nullptr);
        CHECK(scene->object("batch-target-a") != nullptr);
        CHECK(scene->object("batch-target-b") != nullptr);
        Surface surface;
        CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
    }
    delete scene;
}

static uint64_t _surfaceHash(const Surface& surface)
{
    auto hash = uint64_t{1469598103934665603ull};
    for (auto y = 0u; y < surface.height(); y++) {
        for (auto x = 0u; x < surface.width(); x++) {
            hash ^= surface.data()[static_cast<size_t>(y) * surface.stride() + x];
            hash *= 1099511628211ull;
        }
    }
    return hash;
}

static void _dashTimeline(SwRenderer* renderer)
{
    static constexpr char source[] = R"lua(
local scene = tmath.scene {
    width = 320, height = 180, background = "#101820", antialiasing = false,
    camera = {view = "2d", height = 4}
}
local flow = scene:line {
    from = {-2, 0}, to = {2, 0}, stroke = "#4cc9f0", width = 8,
    dash = {20, 12}, dash_offset = 0, id = "flow"
}
scene:play({target = flow, dash_offset = -32}, 1, "linear")
return scene
)lua";
    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, sizeof(source) - 1u, "dash-timeline.lua", &scene,
                            error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "dash-timeline.lua: %s\n", error);
    if (scene) {
        auto flow = scene->object("flow");
        CHECK(flow != nullptr);
        CHECK(flow && _near(flow->style.dashOffset, -32.0f));
        Surface middle;
        Surface end;
        CHECK(renderer->render(scene, 0.5f, middle) == Result::Success);
        auto middleChecksum = _surfaceHash(middle);
        CHECK(renderer->render(scene, 1.0f, end) == Result::Success);
        auto endChecksum = _surfaceHash(end);
        CHECK(middleChecksum != endChecksum);
    }
    delete scene;
}

static void _themes(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 320, height = 180, background = "#fafafa",
    theme = {
        preset = "pro_white",
        background = "#101426",
        objects = {"#112233", "#445566"},
        object_width = 3.25,
        gradient = true,
        end_gradient_stop = "#778899",
        text = {
            h1 = {font = "Pretendard", size = 33, color = "#17191d"},
            code = {font = "Pretendard", size = 14, color = "#8a3b12"},
        },
        axis = {x = "#aa3311", y = "#227744", z = "#335599",
            grid = "#d6d8dc", label = "#555b64"},
    },
    camera = {view = "2d", height = 6},
}
local title = scene:text {text = "Theme", role = "h1", point = {0, 2}, id = "title"}
local code = scene:text {text = "f(x) = x^2", role = "code", point = {0, 1.4}, id = "code"}
local axes = scene:space {numbers = true, id = "axes"}
local first = scene:line {from = {-2, 0.5}, to = {2, 0.5}, id = "first"}
local explicit = scene:line {from = {-2, 0}, to = {2, 0}, stroke = "#abcdef", width = 5, id = "explicit"}
local second = scene:circle {center = {-1, -1}, id = "second"}
local wrapped = scene:point {point = {1, -1}, id = "wrapped"}
local custom_gradient = scene:line {from = {-2, -1.5}, to = {0, -1.5}, gradient = "#fedcba", id = "custom-gradient"}
local solid = scene:line {from = {0, -1.5}, to = {2, -1.5}, gradient = false, id = "solid"}
return scene
)lua";

    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                            "theme.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "theme.lua: %s\n", error);
    if (scene) {
        CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#fafafa")));
        CHECK(scene->theme().objectCount == 2u);
        auto title = static_cast<Text*>(scene->object("title"));
        auto code = static_cast<Text*>(scene->object("code"));
        auto axes = static_cast<Space*>(scene->object("axes"));
        auto first = scene->object("first");
        auto explicitLine = scene->object("explicit");
        auto second = scene->object("second");
        auto wrapped = scene->object("wrapped");
        auto customGradient = scene->object("custom-gradient");
        auto solid = scene->object("solid");
        CHECK(title && code && axes && first && explicitLine && second && wrapped
              && customGradient && solid);
        if (title && code && axes && first && explicitLine && second && wrapped
            && customGradient && solid) {
            CHECK(title->role == TextRole::H1 && _near(title->size, 33.0f));
            CHECK(code->role == TextRole::Code && _near(code->size, 14.0f));
            CHECK(std::strcmp(title->font(), "Pretendard") == 0);
            CHECK(_pixel(title->style.fill) == _pixel(Color::hex("#17191d")));
            CHECK(_pixel(code->style.fill) == _pixel(Color::hex("#8a3b12")));
            CHECK(_pixel(axes->axisX) == _pixel(Color::hex("#aa3311")));
            CHECK(_pixel(axes->axisY) == _pixel(Color::hex("#227744")));
            CHECK(_pixel(axes->axisZ) == _pixel(Color::hex("#335599")));
            CHECK(_pixel(first->style.stroke) == _pixel(Color::hex("#112233")));
            CHECK(_near(first->style.width, 3.25f));
            CHECK(_pixel(explicitLine->style.stroke) == _pixel(Color::hex("#abcdef")));
            CHECK(_near(explicitLine->style.width, 5.0f));
            CHECK(_pixel(second->style.stroke) == _pixel(Color::hex("#445566")));
            CHECK(_near(second->style.width, 3.25f));
            CHECK(_pixel(wrapped->style.stroke) == _pixel(Color::hex("#112233")));
            CHECK(_pixel(wrapped->style.fill) == _pixel(Color::hex("#112233")));
            CHECK(first->style.gradient);
            CHECK(_pixel(first->style.gradientEnd) == _pixel(Color::hex("#778899")));
            CHECK(customGradient->style.gradient);
            CHECK(_pixel(customGradient->style.gradientEnd)
                  == _pixel(Color::hex("#fedcba")));
            CHECK(!solid->style.gradient);
        }
        Surface surface;
        CHECK(renderer->render(scene, 0.0f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 100u);
    }
    delete scene;

    static constexpr auto blackSource = R"lua(
local scene = tmath.scene {theme = "pro_black"}
scene:point {point = {0, 0}, id = "point"}
local legacy = tmath.scene {theme = "pro"}
legacy:point {point = {0, 0}, id = "legacy-point"}
scene:viewport(legacy, {x = 0, y = 0, width = 1, height = 1})
return scene
)lua";
    error[0] = '\0';
    scene = nullptr;
    status = Lua::load(blackSource, static_cast<uint32_t>(std::strlen(blackSource)),
                       "theme-pro-black.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "theme-pro-black.lua: %s\n", error);
    if (scene) {
        CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#000000")));
        auto point = scene->object("point");
        CHECK(point != nullptr);
        if (point) {
            CHECK(_pixel(point->style.stroke) == _pixel(Color::hex("#f28e2b")));
            CHECK(_pixel(point->style.fill) == _pixel(Color::hex("#f28e2b")));
        }
        auto legacy = scene->sceneAt(0);
        CHECK(legacy != nullptr);
        if (legacy) {
            CHECK(_pixel(legacy->config().background) == _pixel(Color::hex("#ffffff")));
            auto legacyPoint = legacy->object("legacy-point");
            CHECK(legacyPoint != nullptr);
            if (legacyPoint) {
                CHECK(_pixel(legacyPoint->style.stroke) == _pixel(Color::hex("#b45f06")));
                CHECK(_pixel(legacyPoint->style.fill) == _pixel(Color::hex("#b45f06")));
            }
        }
    }
    delete scene;

    static constexpr auto adaptiveSource = R"lua(
local scene = tmath.scene {theme = "adaptive_vscode"}
scene:text {text = "Adaptive", role = "h1", id = "title"}
scene:line {from = {-1, 0}, to = {1, 0}, id = "line"}
return scene
)lua";
    auto adaptive = Theme::preset(ThemePreset::ProBlack);
    adaptive.background = Color::hex("#101820");
    adaptive.h1.color = Color::hex("#e8edf2");
    adaptive.objects[0] = Color::hex("#62b0ff");
    adaptive.objectCount = 1u;
    bool adaptiveUsed = false;
    error[0] = '\0';
    scene = nullptr;
    status = Lua::load(adaptiveSource, static_cast<uint32_t>(std::strlen(adaptiveSource)),
                       "theme-adaptive-vscode.lua", &scene, error, sizeof(error), nullptr,
                       nullptr, &adaptive, &adaptiveUsed);
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    CHECK(adaptiveUsed);
    if (scene) {
        CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#101820")));
        auto title = static_cast<Text*>(scene->object("title"));
        auto line = scene->object("line");
        CHECK(title && line);
        if (title) CHECK(_pixel(title->style.fill) == _pixel(Color::hex("#e8edf2")));
        if (line) CHECK(_pixel(line->style.stroke) == _pixel(Color::hex("#62b0ff")));
    }
    delete scene;

    adaptiveUsed = false;
    scene = nullptr;
    status = Lua::load(adaptiveSource, static_cast<uint32_t>(std::strlen(adaptiveSource)),
                       "theme-adaptive-fallback.lua", &scene, error, sizeof(error), nullptr,
                       nullptr, nullptr, &adaptiveUsed);
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    CHECK(adaptiveUsed);
    if (scene) CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#ffffff")));
    delete scene;

    static constexpr auto namedSource = R"lua(
local named = tmath.scene {theme = "3_blue_1_eyes"}
named:point {point = {0, 0}, id = "named-point"}
return named
)lua";
    scene = nullptr;
    status = Lua::load(namedSource, static_cast<uint32_t>(std::strlen(namedSource)),
                       "theme-three-blue-one-eyes.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (scene) {
        CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#0d1117")));
        auto point = scene->object("named-point");
        CHECK(point && _pixel(point->style.fill) == _pixel(Color::hex("#f28e2b")));
    }
    delete scene;

    static constexpr auto implicitSource = "return tmath.scene {}";
    scene = nullptr;
    status = Lua::load(implicitSource, static_cast<uint32_t>(std::strlen(implicitSource)),
                       "theme-implicit.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (scene) {
        CHECK(_pixel(scene->config().background) == _pixel(Color::hex("#ffffff")));
        CHECK(_pixel(scene->theme().objects[0]) == _pixel(Color::hex("#b45f06")));
    }
    delete scene;

    static constexpr auto semanticSource = R"lua(
local scene = tmath.scene {
    theme = {
        preset = "pro_white",
        colors = {
            foreground = "#111111", muted = "#777777", accent = "#123456",
            secondary = "#654321", success = "#118833", warning = "#aa7700",
            danger = "#bb2233", info = "#2277aa", surface = "#f0f1f2", border = "#ccd0d4",
            result = "#886600", focus = "#336699",
        },
    },
}
local accent = scene:line {from = {-2, 1}, to = {2, 1}, stroke = "accent", gradient = "secondary", id = "accent"}
local animated = scene:line {from = {-2, 1.5}, to = {2, 1.5}, stroke = "foreground", id = "animated"}
scene:point {point = {0, 0}, color = "warning", id = "warning"}
scene:rectangle {center = {0, -1}, size = {2, 0.5}, fill = "surface", stroke = "border", id = "panel"}
scene:circle {center = {-1, -2}, radius = 0.25, stroke = "result", id = "result"}
scene:circle {center = {1, -2}, radius = 0.25, stroke = "focus", id = "focus"}
scene:space {axis_x = "danger", axis_y = "success", axis_z = "info", number_color = "muted", id = "semantic-space"}
scene:stroke(animated, "success", 0.1)
scene:indicate(accent, {duration = 0.1})
return scene
)lua";
    scene = nullptr;
    status = Lua::load(semanticSource, static_cast<uint32_t>(std::strlen(semanticSource)),
                       "theme-semantic.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "theme-semantic.lua: %s\n", error);
    if (scene) {
        CHECK(_pixel(scene->theme().colors.accent) == _pixel(Color::hex("#123456")));
        CHECK(_pixel(scene->theme().colors.danger) == _pixel(Color::hex("#bb2233")));
        CHECK(_pixel(scene->theme().colors.result) == _pixel(Color::hex("#886600")));
        CHECK(_pixel(scene->theme().colors.focus) == _pixel(Color::hex("#336699")));
        auto accent = scene->object("accent");
        auto warning = scene->object("warning");
        auto panel = scene->object("panel");
        auto semanticSpace = static_cast<Space*>(scene->object("semantic-space"));
        CHECK(accent && warning && panel && semanticSpace);
        if (accent) {
            CHECK(_pixel(accent->style.stroke) == _pixel(Color::hex("#123456")));
            CHECK(accent->style.gradient);
            CHECK(_pixel(accent->style.gradientEnd) == _pixel(Color::hex("#654321")));
        }
        if (warning) {
            CHECK(_pixel(warning->style.stroke) == _pixel(Color::hex("#aa7700")));
            CHECK(_pixel(warning->style.fill) == _pixel(Color::hex("#aa7700")));
        }
        if (panel) {
            CHECK(_pixel(panel->style.stroke) == _pixel(Color::hex("#ccd0d4")));
            CHECK(_pixel(panel->style.fill) == _pixel(Color::hex("#f0f1f2")));
        }
        if (semanticSpace) {
            CHECK(_pixel(semanticSpace->axisX) == _pixel(Color::hex("#bb2233")));
            CHECK(_pixel(semanticSpace->axisY) == _pixel(Color::hex("#118833")));
            CHECK(_pixel(semanticSpace->axisZ) == _pixel(Color::hex("#2277aa")));
            CHECK(_pixel(semanticSpace->numberColor) == _pixel(Color::hex("#777777")));
        }
        CHECK(_near(scene->duration(), 0.2f));
    }
    delete scene;
}

static void _cellVoxelBindings(SwRenderer* renderer)
{
    static constexpr auto source = R"lua(
local scene = tmath.scene {
    width = 320, height = 180, background = "#ffffff",
    camera = {view = "3d", eye = {5, 4, 6}, target = {0, 0, 0},
        projection = "perspective", near = 0.1, far = 100}
}
local space = scene:space {x = {-1, 1, 1}, y = {-1, 1, 1}, z = {-1, 1, 1}}
local calls = 0
local first_time = -1
local last_time = -1
local voxels = space:voxel(function(x, y, z, time)
    calls = calls + 1
    if calls == 1 then first_time = time end
    last_time = time
    if x == 0 and y == 0 and z == 0 then return "#00000000" end
    local radius = 0.8 + 0.35 * time
    if x*x + y*y + z*z > radius*radius then return "#00000000" end
    if z < 0 then return "#2563eb" end
    if z > 0 then return "#dc2626" end
    return "#7c3aed"
end, {mode = "padd", padding = 0.08, duration = 1, fps = 2})
if calls ~= 81 or first_time ~= 0 or last_time ~= 1 then
    error("voxel temporal samples mismatch")
end
local xy_calls = 0
local xy_first_time = -1
local xy_last_time = -1
local cells = space:cell(function(x, y, time)
    xy_calls = xy_calls + 1
    if xy_calls == 1 then xy_first_time = time end
    xy_last_time = time
    local a = 1 + 0.5 * time
    return x*x/(a*a) + y*y <= 1 and "#0891b2" or "#00000000"
end, {mode = "padd", padding = 0.08, duration = 1, fps = 2})
if xy_calls ~= 27 or xy_first_time ~= 0 or xy_last_time ~= 1 then
    error("cell temporal samples mismatch")
end
return scene
)lua";
    char error[1024] = {};
    Scene* scene = nullptr;
    auto status = Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                            "cell-voxel.lua", &scene, error, sizeof(error));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    if (status != Result::Success) std::fprintf(stderr, "cell-voxel.lua: %s\n", error);
    if (scene) {
        CHECK(scene->count() == 7u);
        CHECK(scene->duration() == 2.0f);
        auto space = static_cast<Space*>(scene->objectAt(0));
        CHECK(space && space->type() == Type::Space);
        auto voxels = space ? space->objectAt(0) : nullptr;
        CHECK(voxels && voxels->type() == Type::Group);
        CHECK(voxels && voxels->childCount() == 3u);
        auto cells = space ? space->objectAt(1) : nullptr;
        CHECK(cells && cells->type() == Type::Group);
        CHECK(cells && cells->childCount() == 1u);
        Surface surface;
        CHECK(renderer->render(scene, 0.5f, surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 1000u);
        CHECK(renderer->render(scene, scene->duration(), surface) == Result::Success);
        CHECK(_changed(surface, scene->config().background) > 1000u);
    }
    delete scene;
}

int main()
{
    auto renderer = SwRenderer::gen();
    CHECK(renderer != nullptr);
    if (renderer) {
#ifdef TMATH_TEST_FONT
        CHECK(renderer->font(TMATH_TEST_FONT) == Result::Success);
#endif
        _render(renderer, _scene2d, "source-2d.lua", "vector", Type::Arrow, 1.9f, true, "test-lua-2d.png");
        _render(renderer, _scene3d, "source-3d.lua", "space-vector", Type::Vector, 1.24f, false, "test-lua-3d.png");
        _render(renderer, _plot, "source-plot.lua", "sine", Type::Plot, 0.6f, false, "test-lua-plot.png");
        _render(renderer, _route, "source-route.lua", "route", Type::Route, 1.0f, false, "test-lua-route.png");
        _render(renderer, _path, "source-path.lua", "outline", Type::Path, 0.6f, false, "test-lua-path.png");
        _render(renderer, _path, "source-curve.lua", "bezier", Type::Curve, 0.6f, false, "test-lua-curve.png");
        _render(renderer, _surface, "source-surface.lua", "surface", Type::SurfaceMesh, 0.6f, false, "test-lua-surface.png");
        _dash(renderer);
        _assets(renderer);
        _viewports(renderer);
        _sceneTransitions(renderer);
        _sceneTree(renderer);
        _animationMethods(renderer);
        _dashTimeline(renderer);
        _themes(renderer);
        _cellVoxelBindings(renderer);
    }
    delete renderer;

    _directRoot();

    _error("return tmath.scene {", "syntax.lua");
    _error("error('runtime sentinel')", "runtime.lua");
    _error("while true do end", "quota.lua");
    _error("return tmath.scene {camera={view='2d', heights=8}}", "camera-option.lua");
    _error("return tmath.scene {loop=1}", "loop-type.lua");
    _error("local s=tmath.scene{}; s:grid{}; return s", "legacy-grid.lua");
    _error("local s=tmath.scene{}; s:path{commands={{type='line',to={0,0}},{type='line',to={1,1}}}}; return s", "path-move.lua");
    _error("local s=tmath.scene{}; s:path{commands={{type='move',to={0,0}},{type='close'},{type='line',to={1,1}}}}; return s", "path-close.lua");
    _error("local s=tmath.scene{}; s:path{commands={{type='move',to={0,0}},{type='arc',to={1,1}}}}; return s", "path-verb.lua");
    _error("local s=tmath.scene{}; s:curve{from={0,0},control1={0,1},control2={1,1},to={1,0},samples=0}; return s", "curve-samples.lua");
    _error("local s=tmath.scene{}; s:surface{points={{0,0},{1,0}},size={2,1}}; return s", "surface-size.lua");
    _error("local s=tmath.scene{}; s:surface{points={{0,0},{1,0},{0,1},{1,1}},size={2,2},mode='cells'}; return s", "surface-mode.lua");
    _error("local s=tmath.scene{}; s:surface{points={{0,0},{1,0},{0,1},{1,1}},size={2,2},shading='flat'}; return s", "surface-shading.lua");
    _error("local s=tmath.scene{}; s:text{text='x',orientation='wall'}; return s", "text-orientation.lua");
    _error("local s=tmath.scene{}; s:text{text='x',role='caption'}; return s", "text-role.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; r:label{}; return s", "label-text.lua");
    _error("return tmath.scene{theme='editorial'}", "theme-preset.lua");
    _error("return tmath.scene{theme='default'}", "theme-default-renamed.lua");
    _error("return tmath.scene{theme={objects={}}}", "theme-palette-empty.lua");
    _error("return tmath.scene{theme={object_width=0}}", "theme-object-width.lua");
    _error("return tmath.scene{theme={gradient=1}}", "theme-gradient-type.lua");
    _error("return tmath.scene{theme={text={h1={font=''}}}}", "theme-font-empty.lua");
    _error("return tmath.scene{theme={axis={w='#fff'}}}", "theme-axis-option.lua");
    _error("local s=tmath.scene{}; s:line{from={0,0},to={1,0},width=-1}; return s", "width-negative.lua");
    _error("local s=tmath.scene{}; s:text{text='x',gradient=true}; return s", "text-gradient.lua");
    _error("local s=tmath.scene{}; s:circle{gradient=1}; return s", "shape-gradient-type.lua");
    _error("local s=tmath.scene{}; s:line{dash={}}; return s", "dash-empty.lua");
    _error("local s=tmath.scene{}; s:line{dash={1,2,3,4,5}}; return s", "dash-limit.lua");
    _error("local s=tmath.scene{}; s:line{dash={0,0}}; return s", "dash-zero.lua");
    _error("local s=tmath.scene{}; s:line{dash={4,-1}}; return s", "dash-negative.lua");
    _error("local s=tmath.scene{}; s:line{dash_offset=1}; return s", "dash-offset.lua");
    _error("local s=tmath.scene{}; s:route{points={{0,0},{1,0}},tip=-1}; return s", "route-tip.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:play({target=r,tip=2}); return s", "play-tip-target.lua");
    _error("local s=tmath.scene{}; local a=s:arrow{}; s:play({target=a,tail=-1}); return s", "play-tail-negative.lua");
    _error("local s=tmath.scene{}; local l=s:line{}; s:play({target=l,dash_offset=1}); return s", "dash-play-solid.lua");
    _error("local s=tmath.scene{}; s:space{matrixx={}}; return s", "object-option.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; g:arrow{from={0,0},to={1,0},tail=-1}; return s", "tail.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; local a=g:point{}; local b=g:point{}; s:transition(a,b); return s", "transition-opacity.lua");
    _error("local s=tmath.scene{}; local a=s:point{}; s:fade_transform(a,a); return s", "fade-transform-same.lua");
    _error("local s=tmath.scene{}; local a=s:point{}; local b=s:point{}; s:wait(0.1); s:fade_transform(a,b); return s", "fade-transform-stale.lua");
    _error("local s=tmath.scene{}; local r=s:circle{}; s:create(r,1,'linear',0,'sideways'); return s", "create-direction.lua");
    _error("local s=tmath.scene{}; local r=s:circle{}; s:uncreate(r,1,'linear',0,{}); return s", "uncreate-direction-type.lua");
    _error("local s=tmath.scene{}; local r=s:circle{}; s:create(r,1,'linear',0,'forward'..string.char(0)..'x'); return s", "create-direction-zero.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:fade_in(r,{scale=0}); return s", "fade-in-scale.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:fade_out(r,{unknown=true}); return s", "fade-out-option.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:fade_in(r,0.5); return s", "fade-in-options-type.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:indicate(r,{scale=1}); return s", "indicate-scale.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:indicate(r,{easing='warp'}); return s", "indicate-easing.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:shift(r,{1,0},1,{preset='back',strength=2.1}); return s", "curve-strength.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:shift(r,{1,0},1,{preset='back',reverse=1}); return s", "curve-reverse.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:shift(r,{1,0},1,'smooth'..string.char(0)..'x'); return s", "curve-zero.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:shift(r,{1,0},1,{bezier={-0.1,0,1,1}}); return s", "curve-bezier-x.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:shift(r,{1,0},1,{preset='back',bezier={0,0,1,1}}); return s", "curve-choice.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:fade_in(r,{easing='smooth',curve={preset='back'}}); return s", "curve-alias.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; s:grow_from_center(r,0); return s", "grow-duration.lua");
    _error(R"lua(
local s = tmath.scene {}
local a = s:polygon {points = {{0, 0}, {1, 0}, {0, 1}}}
local b = s:polygon {points = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}}
s:morph(a, b)
return s
)lua",
           "morph-point-count.lua");
    _error(R"lua(
local s = tmath.scene {}
local a = s:plot {points = {{0, 0}, {1, 1}}}
local b = s:plot {points = {{0, 0}, {1, -1}}}
s:morph({a}, {b, a})
return s
)lua",
           "morph-array-size.lua");
    _error(R"lua(
local s = tmath.scene {}
local a = s:plot {points = {{0, 0}, {1, 1}}}
local b = s:plot {points = {{0, 0}, {1, -1}}}
s:morph({a}, b)
return s
)lua",
           "morph-array-kind.lua");
    _error(R"lua(
local s = tmath.scene {}
local a = s:plot {points = {{0, 0}, {1, 1}}}
local b = s:plot {points = {{0, 0}, {1, -1}}}
local c = s:plot {points = {{0, 0}, {1, 0}}}
s:morph({a, a}, {b, c})
return s
)lua",
           "morph-array-duplicate.lua");
    _error(R"lua(
local a = tmath.scene {}
local b = tmath.scene {}
local source = a:plot {points = {{0, 0}, {1, 1}}}
local target = b:plot {points = {{0, 0}, {1, -1}}}
a:replacement_transform(source, target)
return a
)lua",
           "replacement-foreign-target.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:play({
    {target = r, shift = {1, 0}},
    {target = r, opacity = 0.5}
})
return s
)lua",
           "play-duplicate-target.lua");
    _error(R"lua(
local s = tmath.scene {}
s:play({{shift = {1, 0}}})
return s
)lua",
           "play-missing-target.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:play({target = r})
return s
)lua",
           "play-no-property.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:play({
    target = r,
    shift = {1, 0},
    transform = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
})
return s
)lua",
           "play-shift-transform.lua");
    _error(R"lua(
local a = tmath.scene {}
local b = tmath.scene {}
local r = a:rectangle {}
b:play({target = r, shift = {1, 0}})
return b
)lua",
           "play-foreign-target.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:play({target = r, opacity = 0 / 0})
return s
)lua",
           "play-nonfinite.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:play({target = r, opacity = 1.1})
return s
)lua",
           "play-opacity.lua");
    _error(R"lua(
local a = tmath.scene {}
local b = tmath.scene {}
local left = a:rectangle {}
local right = b:rectangle {}
a:connector {from = left, to = right}
return a
)lua",
           "connector-cross-scene.lua");
    _error(R"lua(
local s = tmath.scene {}
local left = s:rectangle {center = {-1, 0}}
local right = s:rectangle {center = {1, 0}}
local connector = s:connector {from = left, to = right}
s:shift(connector, {1, 0})
return s
)lua",
           "connector-transform.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
r:arrange()
return s
)lua",
           "arrange-non-group.lua");
    _error(R"lua(
local s = tmath.scene {}
local r = s:rectangle {}
s:wait(0.1)
r:move_to({1, 0})
return s
)lua",
           "layout-after-timeline.lua");
    _error("local p=tmath.scene{}; local c=tmath.scene{}; p:viewport(c,{x=.8,width=.5}); return p", "viewport-bounds.lua");
    _error("local p=tmath.scene{}; local c=tmath.scene{}; p:viewport(c,{}); p:viewport(c,{}); return p", "viewport-owner.lua");
    _error("local p=tmath.scene{}; local c=tmath.scene{}; p:viewport(c,{}); c:wait(1); return p", "viewport-sealed.lua");
    _error(R"lua(
local parent = tmath.scene {}
local child = tmath.scene {}
local handle = child:rectangle {}
parent:viewport(child, {})
handle:move_to({1, 0})
return parent
)lua",
           "viewport-sealed-handle.lua");
    _error("local p=tmath.scene{}; local c=tmath.scene{}; p:viewport(c,{}); return c", "viewport-root.lua");
    _error("local p=tmath.scene{}; p:scene_transition({},{}); return p", "transition-empty.lua");
    _error("local p=tmath.scene{}; local c=tmath.scene{}; p:scene_transition({c,c},{}); return p", "transition-duplicate.lua");
    _error("local p=tmath.scene{}; local a=tmath.scene{}; local b=tmath.scene{}; p:scene_transition({a,b},{hold=-1}); return p", "transition-hold.lua");
    _error("local p=tmath.scene{}; local a=tmath.scene{}; local b=tmath.scene{}; p:scene_transition({a,b},{}); a:wait(1); return p", "transition-sealed.lua");
    _error(R"lua(
local root = tmath.scene {}
local left = tmath.scene {}
local right = tmath.scene {}
for i = 1, 32 do
    left:viewport(tmath.scene {}, {})
    right:viewport(tmath.scene {}, {})
end
root:viewport(left, {})
root:viewport(right, {})
return root
)lua",
           "viewport-limit.lua");
    _error(R"lua(
local scenes = {}
for i = 1, 66 do scenes[i] = tmath.scene {} end
return scenes[1]
)lua",
           "live-scene-limit.lua");
    _error(R"lua(
local s = tmath.scene {}
local cursor = s:group {}
for i = 1, 65 do
    cursor = cursor:group {}
end
return s
)lua",
           "incremental-depth.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
local p = g:point {point = {0, 0}}
s:shift(p, {1, 2, 3, 4})
return s
)lua",
           "dimension.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
g:point {point = {0, 0}, id = "same"}
g:point {point = {1, 1}, id = "same"}
return s
)lua",
           "duplicate-id.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
for i = 1, 4097 do g:point {point = {i, 0}} end
return s
)lua",
           "object-limit.lua");
    _error(R"lua(
local a = tmath.scene {}
local b = tmath.scene {}
local ga = a:space {}
local gb = b:space {}
for i = 1, 2500 do
    ga:point {point = {i, 0}}
    gb:point {point = {-i, 0}}
end
return a
)lua",
           "global-object-limit.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
local point = g:point {point = {0, 0}}
local group = {}
for i = 1, 1025 do group[i] = point end
s:create(group)
return s
)lua",
           "group-limit.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
g:svg {path = "formula.svg", color = "#fff"}
return s
)lua",
           "svg-style.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {}
g:point {point = {0, 0}, id = string.char(255)}
return s
)lua",
           "invalid-id.lua");
    _error("return tostring({})", "nondeterministic-tostring.lua");
    _error("return string.format('%p', 'value')", "pointer-format.lua");
    _error("return string.format('%s', {})", "nondeterministic-format.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; g:cell{size={0,2}}; return s", "cell-size.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; g:voxel(1); return s",
           "voxel-callback.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; g:cell(1); return s",
           "cell-callback.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:cell(function() return 1 end); return s", "cell-return.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:voxel(function() return 1 end); return s", "voxel-return.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:voxel(function() error('sample') end); return s", "voxel-error.lua");
    _error("local s=tmath.scene{}; local g=s:space{x={0,0,1},y={0,0,1},z={0,0,1}}; "
           "g:voxel(function() s:point{point={0,0}} return '#fff' end); return s",
           "voxel-authoring.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:voxel(function() return '#fff' end,{padding=.5}); return s",
           "voxel-padding.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:cell(function() return '#fff' end,{duration=-1}); return s",
           "cell-duration.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:voxel(function() return '#fff' end,{duration=1,fps=0}); return s",
           "voxel-fps.lua");
    _error("local s=tmath.scene{}; local g=s:space{}; "
           "g:voxel(function() return '#fff' end,{duration=200,fps=30}); return s",
           "voxel-frame-limit.lua");
    _error("local s=tmath.scene{}; local g=s:space{x={-25,25,1},y={-25,25,1}}; "
           "g:cell(function() return '#fff' end,{duration=4,fps=30}); return s",
           "cell-color-limit.lua");
    _error(R"lua(
local s = tmath.scene {}
local g = s:space {x = {0, 0, 1}, y = {0, 0, 1}}
local a = g:cell(function() return '#fff' end)
local b = g:cell(function() return '#000' end)
s:morph(a, b)
return s
)lua",
           "cell-morph.lua");
    _error("local s=tmath.scene{}; local g=s:group{}; "
           "g:voxel(function() return '#fff' end); return s", "voxel-space.lua");
    _error("local s=tmath.scene{}; "
           "local g=s:space{x={-100,100,1},y={-100,100,1},z={0,0,1}}; "
           "g:voxel(function() return '#fff' end); return s", "voxel-limit.lua");
    _error("local s=tmath.scene{}; s:space{number_mode='screen'}; return s", "number-mode.lua");
    _error("local s=tmath.scene{}; local r=s:rectangle{}; "
           "s:grow_from_edge(r,'center'); return s", "growth-edge.lua");
    _error("local s=tmath.scene{}; s:space{numbers=1}; return s", "numbers-type.lua");
    _error("local s=tmath.scene{}; s:line{from={0,0},to={1,1},stroke='unknown'}; return s",
           "theme-color-role.lua");
    _error("local s=tmath.scene{theme={colors={accent='red'}}}; return s",
           "theme-semantic-literal.lua");
    _deterministic();
    _styleGroups();
    _localeIndependent();

    if (_failures) std::fprintf(stderr, "%d Lua checks failed\n", _failures);
    return _failures ? 1 : 0;
}
