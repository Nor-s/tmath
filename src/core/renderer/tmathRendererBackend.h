#ifndef _TMATH_RENDERER_BACKEND_H_
#define _TMATH_RENDERER_BACKEND_H_

namespace tmath
{

struct SwRenderer;
struct GlRenderer;

namespace renderer
{

bool cpuEnabled() noexcept;
bool glEnabled() noexcept;
SwRenderer* genCpu() noexcept;
GlRenderer* genGl() noexcept;

}  // namespace renderer

}  // namespace tmath

#endif
