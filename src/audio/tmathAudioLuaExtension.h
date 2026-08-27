#ifndef TMATH_AUDIO_LUA_EXTENSION_H
#define TMATH_AUDIO_LUA_EXTENSION_H

#include "../bindings/lua/tmathLuaExtension.h"

namespace tmath::audio
{

struct Soundscape;

namespace lua_extension
{

struct LuaContext
{
    Soundscape* soundscape = nullptr;
    Scene* scene = nullptr;
};

tmath::detail::LuaHooks luaHooks(LuaContext& context) noexcept;

}  // namespace lua_extension

}  // namespace tmath::audio

#endif
