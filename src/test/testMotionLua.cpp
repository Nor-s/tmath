#include <cmath>
#include <cstdio>
#include <cstring>

#include "tmathLuaHost.h"
#include "tmath_motion.h"
#if defined(TMATH_LUA_RUNTIME)
#include "tmath_lua_runtime.h"
#endif

using namespace tmath;

static int failures = 0;

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition);     \
            failures++;                                                                            \
        }                                                                                          \
    } while (false)

static bool _near(float lhs, float rhs, float epsilon = 1.0e-4f)
{
    return std::fabs(lhs - rhs) <= epsilon;
}

static void _standalone()
{
    static constexpr char source[] = R"lua(
if not tmath.motion then error("motion module missing") end
local scene = tmath.scene {width = 320, height = 180}
local target = scene:rectangle {id = "target", center = {1, 0}, size = {2, 1}}
local motion = tmath.motion(scene)
motion:define(target, "idle", {})
motion:define(target, "focused", {
    shift = {2, 1}, rotation = 0.2, scale = {1.5, 1.25},
    opacity = 0.75, progress = 0.5,
})
motion:transition(target, "focused", 1, "linear")
motion:advance(0.25)
local state = motion:sample(target)
if math.abs(state.shift[1] - 0.5) > 0.0001 then error("sample mismatch") end
if math.abs(state.scale[3] - 1) > 0.0001 then error("2D scale changed Z") end
if motion:definition_count() ~= 2 then error("definition count mismatch") end
if motion:event_count() ~= 1 then error("event count mismatch") end
local event = motion:event(1)
if event.object ~= 1 or event.state ~= "focused" then error("event mismatch") end
if event.transaction ~= "1" or event.curve.preset ~= "linear" then
    error("event record mismatch")
end
return scene
)lua";
    Scene* scene = nullptr;
    motion::Controller* controller = nullptr;
    char error[1024] = {};
    auto result = motion::Lua::load(source, static_cast<uint32_t>(std::strlen(source)),
                                    "motion.lua", &scene, &controller, error, sizeof(error));
    CHECK(result == Result::Success);
    CHECK(scene && controller && controller->scene() == scene);
    if (result != Result::Success) std::fprintf(stderr, "standalone motion: %s\n", error);
    if (scene && controller) {
        motion::State state;
        auto object = scene->object("target");
        CHECK(object != nullptr);
        CHECK(controller->sample(object, state) == Result::Success);
        CHECK(_near(state.shift.x, 0.5f));
        CHECK(controller->eventCount() == 1u);
    }
    delete scene;
}

static void _failures()
{
    static constexpr char unknownField[] = R"lua(
local scene = tmath.scene {}
local target = scene:circle {id = "target"}
local motion = tmath.motion(scene)
motion:define(target, "idle", {unknown = true})
return scene
)lua";
    Scene* scene = nullptr;
    motion::Controller* controller = nullptr;
    char error[1024] = {};
    auto result =
        motion::Lua::load(unknownField, static_cast<uint32_t>(std::strlen(unknownField)),
                          "invalid-motion.lua", &scene, &controller, error, sizeof(error));
    CHECK(result == Result::ScriptError);
    CHECK(scene == nullptr && controller == nullptr);
    CHECK(std::strstr(error, "unknown motion state field") != nullptr);

    static constexpr char duplicate[] = R"lua(
local scene = tmath.scene {}
tmath.motion(scene)
tmath.motion(scene)
return scene
)lua";
    result = motion::Lua::load(duplicate, static_cast<uint32_t>(std::strlen(duplicate)),
                               "duplicate-motion.lua", &scene, &controller, error, sizeof(error));
    CHECK(result == Result::ScriptError);
    CHECK(scene == nullptr && controller == nullptr);
    CHECK(std::strstr(error, "only one motion controller") != nullptr);

    static constexpr char aborted[] = R"lua(
local scene = tmath.scene {}
tmath.motion(scene)
error("abort after motion creation")
return scene
)lua";
    detail::LuaHostContext context;
    result = detail::luaHostLoad(aborted, static_cast<uint32_t>(std::strlen(aborted)),
                                 "aborted-motion.lua", &scene, error, sizeof(error), nullptr,
                                 nullptr, nullptr, nullptr, context);
    CHECK(result == Result::ScriptError);
    CHECK(scene == nullptr);
    CHECK(context.motion.controller == nullptr && context.motion.scene == nullptr);
}

#if defined(TMATH_LUA_RUNTIME)
static void _retainedRuntime()
{
    static constexpr char source[] = R"lua(
if not tmath.motion then error("motion module missing") end
if not tmath.runtime then error("runtime module missing") end
local scene = tmath.scene {width = 320, height = 180}
local target = scene:rectangle {id = "target", size = {1, 1}}
local motion = tmath.motion(scene)
motion:define(target, "right", {shift = {2, 0}})
motion:define(target, "up", {shift = {1, 2}})
motion:transition(target, "right", 1, "linear")
tmath.runtime(scene, {
    fixed_step = 0.25,
    max_steps = 4,
    update = function(ctx, dt, time, tick)
        motion:advance(dt)
        if tick == 2 then
            local current = motion:sample(target)
            if math.abs(current.shift[1] - 1) > 0.0001 then
                error("capture-current mismatch")
            end
            motion:transition(target, "up", 1, "linear")
        end
    end,
})
return scene
)lua";
    Scene* scene = nullptr;
    char error[1024] = {};
    detail::LuaHostContext context;
    auto result = detail::luaHostLoad(source, static_cast<uint32_t>(std::strlen(source)),
                                      "motion-runtime.lua", &scene, error, sizeof(error), nullptr,
                                      nullptr, nullptr, nullptr, context);
    CHECK(result == Result::Success);
    CHECK(scene && context.motion.controller && context.runtime.runtime);
    if (result != Result::Success) std::fprintf(stderr, "retained motion: %s\n", error);
    if (result == Result::Success) {
        CHECK(context.runtime.runtime->advance(0.5f) == Result::Success);
        motion::State state;
        auto object = scene->object("target");
        CHECK(context.motion.controller->sample(object, state) == Result::Success);
        CHECK(_near(state.shift.x, 1.0f));
        CHECK(_near(state.shift.y, 0.0f));
        CHECK(context.runtime.runtime->advance(0.5f) == Result::Success);
        CHECK(context.motion.controller->sample(object, state) == Result::Success);
        CHECK(_near(state.shift.x, 1.0f));
        CHECK(_near(state.shift.y, 1.0f));
        CHECK(context.motion.controller->eventCount() == 2u);
    }
    delete scene;
}
#endif

int main()
{
    _standalone();
    _failures();
#if defined(TMATH_LUA_RUNTIME)
    _retainedRuntime();
#endif
    if (failures) std::fprintf(stderr, "%d motion Lua test(s) failed\n", failures);
    return failures ? 1 : 0;
}
