#ifndef TMATH_INPUT_LUA_EXTENSION_H
#define TMATH_INPUT_LUA_EXTENSION_H

#include "../lua/tmathLuaExtension.h"

namespace tmath::input
{
struct Controller;
}

namespace tmath::input::lua_extension
{

struct LuaContext
{
    Controller* controller = nullptr;
    Scene* scene = nullptr;
};

tmath::detail::LuaHooks luaHooks(LuaContext& context) noexcept;

}  // namespace tmath::input::lua_extension

#endif
