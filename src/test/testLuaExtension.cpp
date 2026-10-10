#include <cstdio>
#include <cstring>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

#include "tmathLuaExtension.h"

using namespace tmath;

static int failures = 0;

static void check(bool condition, const char* expression, int line)
{
    if (condition) return;
    std::fprintf(stderr, "%s:%d: CHECK(%s) failed\n", __FILE__, line, expression);
    failures++;
}

#define CHECK(condition) check((condition), #condition, __LINE__)

struct HookContext
{
    uint32_t openOrder = 0;
    uint32_t loadedOrder = 0;
    bool failLoaded = false;
};

static int addTree(lua_State* lua)
{
    detail::luaScene(lua, 1);
    auto root = Group::gen();
    auto body = Rectangle::gen({0.0f, 0.0f, 0.0f}, {3.0f, 1.5f});
    auto label = Text::gen("extension tree");
    if (!root || !body || !label) {
        delete root;
        delete body;
        delete label;
        return luaL_error(lua, "could not allocate extension tree");
    }
    root->tag("extension-root");
    body->tag("extension-body");
    label->tag("extension-label");
    if (root->add(body) != Result::Success) {
        delete root;
        delete body;
        delete label;
        return luaL_error(lua, "could not attach extension body");
    }
    if (root->add(label) != Result::Success) {
        delete root;
        delete label;
        return luaL_error(lua, "could not attach extension label");
    }
    return detail::luaAdoptObject(lua, 1, root, "extension tree");
}

static int firstChild(lua_State* lua)
{
    auto scene = detail::luaScene(lua, 1);
    auto root = detail::luaObject(lua, scene, 2);
    if (!root->childCount()) return luaL_error(lua, "extension tree is empty");
    return detail::luaPushObject(lua, 1, root->childAt(0));
}

static int addOversizedTree(lua_State* lua)
{
    detail::luaScene(lua, 1);
    auto root = Group::gen();
    if (!root) return luaL_error(lua, "could not allocate oversized tree");
    for (auto i = 0u; i < 4096u; i++) {
        auto child = Point::gen({static_cast<float>(i), 0.0f, 0.0f});
        if (!child || root->add(child) != Result::Success) {
            delete child;
            delete root;
            return luaL_error(lua, "could not assemble oversized tree");
        }
    }
    return detail::luaAdoptObject(lua, 1, root, "oversized tree");
}

static int openFirst(lua_State*, void* data)
{
    auto context = static_cast<HookContext*>(data);
    if (context->openOrder != 0u) return 0;
    context->openOrder = 1u;
    return 0;
}

static int openSecond(lua_State* lua, void* data)
{
    auto context = static_cast<HookContext*>(data);
    if (context->openOrder != 1u) return luaL_error(lua, "extension hook order mismatch");
    context->openOrder = 2u;
    lua_getglobal(lua, "tmath");
    lua_pushcfunction(lua, addTree);
    lua_setfield(lua, -2, "test_tree");
    lua_pushcfunction(lua, firstChild);
    lua_setfield(lua, -2, "test_child");
    lua_pushcfunction(lua, addOversizedTree);
    lua_setfield(lua, -2, "test_oversized_tree");
    lua_pop(lua, 1);
    return 0;
}

static Result loadedFirst(lua_State*, Scene*, void* data) noexcept
{
    auto context = static_cast<HookContext*>(data);
    if (context->openOrder != 2u || context->loadedOrder != 0u) return Result::Unknown;
    context->loadedOrder = 1u;
    return Result::Success;
}

static Result loadedSecond(lua_State*, Scene*, void* data) noexcept
{
    auto context = static_cast<HookContext*>(data);
    if (context->loadedOrder != 1u) return Result::Unknown;
    context->loadedOrder = 2u;
    return context->failLoaded ? Result::InvalidArguments : Result::Success;
}

static detail::LuaHookSpan hooks(HookContext& context, detail::LuaHooks (&storage)[2])
{
    storage[0] = {openFirst, loadedFirst, &context};
    storage[1] = {openSecond, loadedSecond, &context};
    return {storage, 2u};
}

int main()
{
    static constexpr char source[] = R"lua(
local scene = tmath.scene {width = 320, height = 180}
local root = tmath.test_tree(scene)
local child = tmath.test_child(scene, root)
scene:fade_in(root, {duration = 0.2})
scene:indicate(child, {duration = 0.2})
return scene
)lua";
    HookContext context;
    detail::LuaHooks storage[2];
    Scene* scene = nullptr;
    char error[512] = {};
    auto status = detail::luaLoad(source, sizeof(source) - 1u, "extension.lua", &scene,
                                  error, sizeof(error), nullptr, nullptr, nullptr, 0u,
                                  nullptr, nullptr, hooks(context, storage));
    CHECK(status == Result::Success);
    CHECK(scene != nullptr);
    CHECK(context.openOrder == 2u);
    CHECK(context.loadedOrder == 2u);
    CHECK(scene && scene->object("extension-root"));
    CHECK(scene && scene->object("extension-body"));
    delete scene;

    context = {};
    context.failLoaded = true;
    scene = nullptr;
    status = detail::luaLoad(source, sizeof(source) - 1u, "extension-fail.lua", &scene,
                             error, sizeof(error), nullptr, nullptr, nullptr, 0u,
                             nullptr, nullptr, hooks(context, storage));
    CHECK(status == Result::InvalidArguments);
    CHECK(scene == nullptr);
    CHECK(context.loadedOrder == 2u);

    static constexpr char oversized[] = R"lua(
local scene = tmath.scene {width = 320, height = 180}
tmath.test_oversized_tree(scene)
return scene
)lua";
    context = {};
    status = detail::luaLoad(oversized, sizeof(oversized) - 1u, "extension-limit.lua",
                             &scene, error, sizeof(error), nullptr, nullptr, nullptr, 0u,
                             nullptr, nullptr, hooks(context, storage));
    CHECK(status == Result::ScriptError);
    CHECK(scene == nullptr);
    CHECK(std::strstr(error, "scene object limit exceeded") != nullptr);
    return failures ? 1 : 0;
}
