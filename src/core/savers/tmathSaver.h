#ifndef _TMATH_SAVER_H_
#define _TMATH_SAVER_H_

#include "tmath.h"

namespace tmath::saver
{

bool ends(const char* value, const char* suffix) noexcept;
Result timeline(const Scene* scene, uint32_t& fps, uint32_t& frames) noexcept;
Result frames(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps,
              const char* options, bool evenDimensions) noexcept;
Result gif(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps) noexcept;
Result video(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps) noexcept;

}  // namespace tmath::saver

#endif
