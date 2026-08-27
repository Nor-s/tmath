#ifndef TMATH_LUA_RUNTIME_EXTENSION_H
#define TMATH_LUA_RUNTIME_EXTENSION_H

#include "../bindings/lua/tmathLuaExtension.h"

namespace tmath::lua_runtime
{
struct Runtime;
}

namespace tmath::lua_runtime::lua_extension
{

struct LuaContext
{
    Runtime* runtime = nullptr;
    Scene* scene = nullptr;
};

tmath::detail::LuaHooks luaHooks(LuaContext& context) noexcept;
Result retain(LuaContext& context, lua_State* lua) noexcept;

}  // namespace tmath::lua_runtime::lua_extension

#endif
