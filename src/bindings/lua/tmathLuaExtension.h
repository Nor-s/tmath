#ifndef TMATH_LUA_EXTENSION_H
#define TMATH_LUA_EXTENSION_H

#include <cstddef>
#include <cstdint>

#include "tmath.h"

struct lua_State;

namespace tmath::detail
{

struct LuaHooks
{
    using Open = int (*)(lua_State*, void*);
    using Loaded = Result (*)(lua_State*, Scene*, void*) noexcept;

    Open open = nullptr;
    Loaded loaded = nullptr;
    void* data = nullptr;
};

struct LuaHookSpan
{
    const LuaHooks* data = nullptr;
    uint32_t count = 0;
};

Result luaLoad(const char* source, uint32_t size, const char* name, Scene** output,
               char* error, uint32_t errorSize, Lua::AssetResolver resolver,
               void* resolverData, const char* sourcePath, size_t sourceRoot,
               const Theme* adaptiveTheme, bool* adaptiveThemeUsed,
               const LuaHookSpan& hooks = {}, lua_State** retained = nullptr) noexcept;
Result luaLoadFile(const char* path, Scene** output, char* error, uint32_t errorSize,
                   const LuaHookSpan& hooks = {}, lua_State** retained = nullptr) noexcept;
bool luaAuthoring(lua_State* lua) noexcept;
void luaClose(lua_State* lua) noexcept;

Scene* luaScene(lua_State* lua, int index);
Object* luaObject(lua_State* lua, Scene* scene, int index);
AnimCurve luaAnimCurve(lua_State* lua, int index);
using LuaObjectTransfer = void (*)(void* data) noexcept;
// The optional transfer callback runs only after a protected Lua owner exists.
// It lets a module relinquish a detached builder tree without leaking on Lua OOM
// or leaving two native owners during budget/Scene-attachment failures.
int luaAdoptObject(lua_State* lua, int sceneIndex, Object* root, const char* kind,
                   LuaObjectTransfer transfer = nullptr, void* transferData = nullptr);
int luaPushObject(lua_State* lua, int sceneIndex, Object* object);

}  // namespace tmath::detail

#endif
