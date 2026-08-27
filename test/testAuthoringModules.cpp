#include <cstdio>
#include <cstring>

#include "tmath.h"
#include "tmath_chart.h"
#include "tmath_diagram.h"
#include "tmathLuaHost.h"
#if defined(TMATH_UI)
#include "tmath_ui.h"
#endif

using namespace tmath;

static int failures = 0;

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

static Result load(const char* source, Scene*& scene, char* error,
                   uint32_t errorSize, detail::LuaHostContext& context)
{
    return detail::luaHostLoad(source, static_cast<uint32_t>(std::strlen(source)),
                               "authoring-modules.lua", &scene, error, errorSize,
                               nullptr, nullptr, nullptr, nullptr, context);
}

static void combinedModules()
{
    static constexpr char source[] = R"lua(
local scene = tmath.scene {
    width = 800, height = 450, loop = true,
    camera = {view = "2d", height = 10}
}

local diagram = tmath.diagram(scene, {
    id = "pipeline", direction = "lr", origin = {0, 2.2},
    node_size = {2.4, 0.9}, rank_gap = 1.2, node_gap = 0.4,
})
local parser = diagram:node {id = "parser", label = "Parser", detail = "source to AST"}
local lower = diagram:node {id = "lower", label = "Lower", detail = "AST to IR"}
local edge = diagram:connect {
    id = "parser-lower", from = parser, to = lower, label = "AST",
    route = "orthogonal", flow = true, flow_offset = 0,
}
diagram:zone {id = "frontend", label = "Frontend", members = {parser, lower}}
local built_diagram = diagram:build()
scene:fade_in(built_diagram:nodes(), {duration = 0.2})
scene:create(built_diagram:routes(), 0.2, "linear")
scene:play({target = built_diagram:edge(edge), dash_offset = -0.36}, 0.2, "linear")
scene:indicate(built_diagram:node(lower), {duration = 0.2, scale = 1.05})

local chart = tmath.chart(scene, {
    id = "latency", frame = {center = {0, -2.2}, size = {8, 3}},
    x = {0, 3}, y = {-2, 8}, x_ticks = 4, y_ticks = 3,
    padding = 0.4, line_width = 0.08, bar_gap = 0.08,
})
local p95 = chart:series {
    id = "p95", label = "p95", mark = "line",
    data = {{0, 1}, {1, 3}, {2, 2}, {3, 7}},
}
local errors = chart:series {
    id = "errors", label = "errors", mark = "bar",
    data = {{0.5, -1}, {1.5, 2}, {2.5, 4}},
}
local built_chart = chart:build()
scene:create(built_chart:series(p95), 0.2, "ease_out")
scene:fade_in(built_chart:series(errors), {duration = 0.2})
if built_chart:mark_count(errors) ~= 3 then error("bar mark count mismatch") end
if not built_chart:mark(errors, 1) then error("bar mark is unavailable") end

if tmath.ui then
    local panel = tmath.ui.panel(scene)
    panel:camera_reset()
end
return scene
)lua";
    Scene* scene = nullptr;
    char error[1024] = {};
    detail::LuaHostContext context;
    auto result = load(source, scene, error, sizeof(error), context);
    CHECK(result == Result::Success);
    CHECK(scene != nullptr);
    if (result != Result::Success) std::fprintf(stderr, "combined modules: %s\n", error);
    if (scene) {
        CHECK(scene->object("pipeline:root") != nullptr);
        CHECK(scene->object("pipeline:node:parser") != nullptr);
        CHECK(scene->object("pipeline:edge:parser-lower") != nullptr);
        CHECK(scene->object("pipeline:edge:parser-lower:flow") == nullptr);
        CHECK(scene->object("latency/series/p95") != nullptr);
        CHECK(scene->object("latency/series/errors/0") != nullptr);
        CHECK(scene->duration() > 0.9f);
#if defined(TMATH_UI)
        CHECK(context.ui.panel != nullptr);
        CHECK(context.ui.panel && context.ui.panel->scene() == scene);
#endif
    }
    delete scene;
}

static void scriptFailures()
{
    static constexpr char mutation[] = R"lua(
local scene = tmath.scene {}
local d = tmath.diagram(scene, {id = "once"})
d:node {id = "a"}
d:build()
d:node {id = "b"}
return scene
)lua";
    Scene* scene = nullptr;
    char error[1024] = {};
    detail::LuaHostContext context;
    auto result = load(mutation, scene, error, sizeof(error), context);
    CHECK(result == Result::ScriptError && scene == nullptr);
    CHECK(std::strstr(error, "already built") != nullptr);

    static constexpr char foreign[] = R"lua(
local scene = tmath.scene {}
local left = tmath.diagram(scene, {id = "left"})
local right = tmath.diagram(scene, {id = "right"})
local a = left:node {id = "a"}
local b = right:node {id = "b"}
left:connect {id = "bad", from = a, to = b}
return scene
)lua";
    context = {};
    result = load(foreign, scene, error, sizeof(error), context);
    CHECK(result == Result::ScriptError && scene == nullptr);
    CHECK(std::strstr(error, "another diagram") != nullptr);

    static constexpr char oversized[] = R"lua(
local scene = tmath.scene {}
local chart = tmath.chart(scene, {
    id = "oversized", frame = {center = {0, 0}, size = {800, 320}},
    x = {0, 4096}, y = {0, 2}, bar_gap = 0
})
local data = {}
for i = 1, 4096 do data[i] = {i - 1, 1} end
chart:series {id = "bars", mark = "bar", data = data}
chart:build()
return scene
)lua";
    context = {};
    result = load(oversized, scene, error, sizeof(error), context);
    CHECK(result == Result::ScriptError && scene == nullptr);
    CHECK(std::strstr(error, "scene object limit exceeded") != nullptr);
}

static void standaloneLoaders()
{
    static constexpr char diagramSource[] = R"lua(
local scene = tmath.scene {}
local diagram = tmath.diagram(scene, {id = "standalone-diagram"})
diagram:node {id = "node", label = "Node"}
diagram:build()
return scene
)lua";
    Scene* scene = nullptr;
    char error[1024] = {};
    auto result = diagram::Lua::load(
        diagramSource, static_cast<uint32_t>(std::strlen(diagramSource)),
        "standalone-diagram.lua", &scene, error, sizeof(error));
    CHECK(result == Result::Success && scene);
    CHECK(scene && scene->object("standalone-diagram:node:node"));
    delete scene;

    static constexpr char chartSource[] = R"lua(
local scene = tmath.scene {}
local chart = tmath.chart(scene, {id = "standalone-chart"})
chart:series {id = "line", data = {{0, 0}, {1, 1}}}
chart:build()
return scene
)lua";
    scene = nullptr;
    error[0] = '\0';
    result = chart::Lua::load(
        chartSource, static_cast<uint32_t>(std::strlen(chartSource)),
        "standalone-chart.lua", &scene, error, sizeof(error));
    CHECK(result == Result::Success && scene);
    CHECK(scene && scene->object("standalone-chart/series/line"));
    delete scene;
}

int main()
{
    combinedModules();
    scriptFailures();
    standaloneLoaders();
    if (failures) std::fprintf(stderr, "%d authoring module checks failed\n", failures);
    return failures ? 1 : 0;
}
