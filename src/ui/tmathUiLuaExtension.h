#ifndef TMATH_UI_LUA_EXTENSION_H
#define TMATH_UI_LUA_EXTENSION_H

#include "../bindings/lua/tmathLuaExtension.h"

namespace tmath::ui
{
struct Panel;
}

namespace tmath::ui::lua_extension
{

struct LuaContext
{
    Panel* panel = nullptr;
    Scene* scene = nullptr;
};

tmath::detail::LuaHooks luaHooks(LuaContext& context) noexcept;

}  // namespace tmath::ui::lua_extension

#endif
