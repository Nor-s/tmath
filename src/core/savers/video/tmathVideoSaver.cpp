#include "tmathSaver.h"

namespace tmath::saver
{

Result video(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps) noexcept
{
    static constexpr auto OPTIONS = "-an -c:v libx264 -pix_fmt yuv420p -f mp4";
    return frames(scene, renderer, path, fps, OPTIONS, true);
}

}  // namespace tmath::saver
