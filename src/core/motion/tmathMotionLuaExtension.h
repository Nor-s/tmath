#ifndef TMATH_MOTION_LUA_EXTENSION_H
#define TMATH_MOTION_LUA_EXTENSION_H

#include "../lua/tmathLuaExtension.h"

namespace tmath::motion
{

struct Controller;

namespace lua_extension
{

struct LuaContext
{
    Controller* controller = nullptr;
    Scene* scene = nullptr;
};

tmath::detail::LuaHooks luaHooks(LuaContext& context) noexcept;

}  // namespace lua_extension

}  // namespace tmath::motion

#endif
