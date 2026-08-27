#ifndef TMATH_LUA_HOST_H
#define TMATH_LUA_HOST_H

#include "tmathLuaExtension.h"

#if defined(TMATH_AUDIO)
#include "../../audio/tmathAudioLuaExtension.h"
#endif
#if defined(TMATH_DIAGRAM)
#include "../../diagram/tmathDiagramLuaExtension.h"
#endif
#if defined(TMATH_CHART)
#include "../../chart/tmathChartLuaExtension.h"
#endif
#if defined(TMATH_UI)
#include "../../ui/tmathUiLuaExtension.h"
#endif
#if defined(TMATH_INPUT)
#include "../../input/tmathInputLuaExtension.h"
#endif
#if defined(TMATH_LUA_RUNTIME)
#include "../../lua_runtime/tmathLuaRuntimeExtension.h"
#endif

namespace tmath::detail
{

struct LuaHostContext
{
#if defined(TMATH_AUDIO)
    audio::lua_extension::LuaContext audio;
#endif
#if defined(TMATH_UI)
    ui::lua_extension::LuaContext ui;
#endif
#if defined(TMATH_INPUT)
    input::lua_extension::LuaContext input;
#endif
#if defined(TMATH_LUA_RUNTIME)
    lua_runtime::lua_extension::LuaContext runtime;
#endif
};

inline LuaHookSpan luaHostHooks(LuaHostContext& context,
                                LuaHooks (&storage)[6]) noexcept
{
    uint32_t count = 0u;
#if defined(TMATH_AUDIO)
    storage[count++] = audio::lua_extension::luaHooks(context.audio);
#endif
#if defined(TMATH_DIAGRAM)
    storage[count++] = diagram::lua_extension::luaHooks();
#endif
#if defined(TMATH_CHART)
    storage[count++] = chart::lua_extension::luaHooks();
#endif
#if defined(TMATH_INPUT)
    storage[count++] = input::lua_extension::luaHooks(context.input);
#endif
#if defined(TMATH_UI)
    storage[count++] = ui::lua_extension::luaHooks(context.ui);
#endif
#if defined(TMATH_LUA_RUNTIME)
    storage[count++] = lua_runtime::lua_extension::luaHooks(context.runtime);
#endif
#if !defined(TMATH_AUDIO) && !defined(TMATH_UI) && !defined(TMATH_INPUT) && !defined(TMATH_LUA_RUNTIME)
    (void) context;
#endif
    return {storage, count};
}

inline Result luaHostLoad(const char* source, uint32_t size, const char* name,
                          Scene** output, char* error, uint32_t errorSize,
                          Lua::AssetResolver resolver, void* resolverData,
                          const Theme* adaptiveTheme, bool* adaptiveThemeUsed,
                          LuaHostContext& context) noexcept
{
    LuaHooks storage[6];
    auto hooks = luaHostHooks(context, storage);
#if defined(TMATH_LUA_RUNTIME)
    lua_State* retained = nullptr;
    auto result = luaLoad(source, size, name, output, error, errorSize, resolver,
                          resolverData, nullptr, 0u, adaptiveTheme,
                          adaptiveThemeUsed, hooks, &retained);
    if (result != Result::Success) return result;
    if (context.runtime.runtime) {
        result = lua_runtime::lua_extension::retain(context.runtime, retained);
        if (result == Result::Success) return result;
        luaClose(retained);
        delete *output;
        *output = nullptr;
        return result;
    }
    luaClose(retained);
    return result;
#else
    return luaLoad(source, size, name, output, error, errorSize, resolver,
                   resolverData, nullptr, 0u, adaptiveTheme, adaptiveThemeUsed, hooks);
#endif
}

inline Result luaHostLoadFile(const char* path, Scene** output, char* error,
                              uint32_t errorSize, LuaHostContext& context) noexcept
{
    LuaHooks storage[6];
    auto hooks = luaHostHooks(context, storage);
#if defined(TMATH_LUA_RUNTIME)
    lua_State* retained = nullptr;
    auto result = luaLoadFile(path, output, error, errorSize, hooks, &retained);
    if (result != Result::Success) return result;
    if (context.runtime.runtime) {
        result = lua_runtime::lua_extension::retain(context.runtime, retained);
        if (result == Result::Success) return result;
        luaClose(retained);
        delete *output;
        *output = nullptr;
        return result;
    }
    luaClose(retained);
    return result;
#else
    return luaLoadFile(path, output, error, errorSize, hooks);
#endif
}

}  // namespace tmath::detail

#endif
