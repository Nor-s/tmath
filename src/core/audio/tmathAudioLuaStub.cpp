#include <cstdio>

#include "tmath_audio.h"

namespace tmath::audio
{

Result Lua::load(const char*, uint32_t, const char*, Scene** scene,
                 Soundscape** soundscape, char* error, uint32_t errorSize,
                 tmath::Lua::AssetResolver, void*, const Theme*,
                 bool* adaptiveThemeUsed) noexcept
{
    if (scene) *scene = nullptr;
    if (soundscape) *soundscape = nullptr;
    if (adaptiveThemeUsed) *adaptiveThemeUsed = false;
    if (error && errorSize) std::snprintf(error, errorSize, "Lua support is disabled");
    return scene ? Result::NonSupport : Result::InvalidArguments;
}

}  // namespace tmath::audio
