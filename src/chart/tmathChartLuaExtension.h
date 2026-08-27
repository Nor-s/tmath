#ifndef TMATH_CHART_LUA_EXTENSION_H
#define TMATH_CHART_LUA_EXTENSION_H

#include "../bindings/lua/tmathLuaExtension.h"

namespace tmath::chart::lua_extension
{

tmath::detail::LuaHooks luaHooks() noexcept;

}  // namespace tmath::chart::lua_extension

#endif
