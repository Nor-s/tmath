#ifndef TMATH_DIAGRAM_LUA_EXTENSION_H
#define TMATH_DIAGRAM_LUA_EXTENSION_H

#include "../lua/tmathLuaExtension.h"

namespace tmath::diagram::lua_extension
{

tmath::detail::LuaHooks luaHooks() noexcept;

}  // namespace tmath::diagram::lua_extension

#endif
