#ifndef _TMATH_TVG_RENDERER_H_
#define _TMATH_TVG_RENDERER_H_

#include <thorvg.h>

#include "tmath.h"

namespace tmath
{

struct DrawCommand;

namespace renderer
{

bool tvgSuccess(tvg::Result result) noexcept;
void tvgRelease(tvg::Paint* paint) noexcept;
bool tvgAdd(tvg::Scene* scene, tvg::Paint* paint) noexcept;
tvg::Paint* tvgPaint(const DrawCommand& command) noexcept;
bool tvgVisible(const DrawCommand& command) noexcept;
Result tvgPaints(const Scene* scene, float time, tvg::Scene*& output) noexcept;
bool tvgInit() noexcept;
void tvgTerm() noexcept;

}  // namespace renderer

}  // namespace tmath

#endif
