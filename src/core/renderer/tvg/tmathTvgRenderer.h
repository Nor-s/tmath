#ifndef _TMATH_TVG_RENDERER_H_
#define _TMATH_TVG_RENDERER_H_

#include <thorvg.h>

#include "tmath.h"

namespace tmath
{

struct DrawCommand;

struct RetainedTree;

namespace renderer
{

using tmath::RetainedTree;

bool tvgSuccess(tvg::Result result) noexcept;
void tvgRelease(tvg::Paint* paint) noexcept;
bool tvgAdd(tvg::Scene* scene, tvg::Paint* paint) noexcept;
tvg::Paint* tvgPaint(const DrawCommand& command) noexcept;
bool tvgVisible(const DrawCommand& command) noexcept;
// Retained paint tree shared by the CPU and GL renderers. It keeps one tvg::Paint per
// stable draw-command identity across frames, attached to the canvas once, and applies
// only the changes of each new DisplayList (see docs/architecture.md, "Renderer").
RetainedTree* tvgRetainedGen() noexcept;
void tvgRetainedFree(RetainedTree* tree) noexcept;
void tvgRetainedReset(RetainedTree* tree) noexcept;
Result tvgRetainedSync(RetainedTree* tree, tvg::Canvas* canvas, const Scene* scene,
                       float time, float scale) noexcept;
bool tvgInit() noexcept;
void tvgTerm() noexcept;

}  // namespace renderer

}  // namespace tmath

#endif
