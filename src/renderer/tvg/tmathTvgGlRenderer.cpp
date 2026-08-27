#include <cmath>
#include <new>

#include <thorvg.h>

#include "tmath.h"
#include "tmathRendererBackend.h"
#include "tmathScene.h"
#include "tmathTvgRenderer.h"

namespace tmath
{

struct GlRenderer::Impl
{
    tvg::GlCanvas* canvas = nullptr;
    bool active = false;
    bool initialized = false;
    bool antialiasing = true;
};

GlRenderer::GlRenderer() noexcept
{
    pImpl = new (std::nothrow) Impl;
    if (!pImpl) return;
    pImpl->initialized = renderer::tvgInit();
}

GlRenderer::~GlRenderer()
{
    if (pImpl) {
        if (pImpl->canvas && pImpl->active) pImpl->canvas->remove();
        delete pImpl->canvas;
    }
    if (pImpl && pImpl->initialized) renderer::tvgTerm();
    delete pImpl;
}

GlRenderer* GlRenderer::gen() noexcept
{
    auto renderer = new (std::nothrow) GlRenderer;
    if (!renderer || (renderer->pImpl && renderer->pImpl->initialized)) return renderer;
    delete renderer;
    return nullptr;
}

Result GlRenderer::font(const char* path) noexcept
{
    if (!path) return Result::InvalidArguments;
    return renderer::tvgSuccess(tvg::Text::load(path)) ? Result::Success : Result::NonSupport;
}

Result GlRenderer::font(const char* name, const void* data, uint32_t size, const char* mime) noexcept
{
    if (!name || !name[0] || !data || !size || !mime || !mime[0]) return Result::InvalidArguments;
    return renderer::tvgSuccess(tvg::Text::load(name, static_cast<const char*>(data), size, mime, true)) ? Result::Success
                                                                                             : Result::NonSupport;
}

Result GlRenderer::render(const Scene* scene, float time, const GlTarget& target) noexcept
{
    if (!pImpl || !pImpl->initialized || !scene || !scene->pImpl
        || !std::isfinite(time) || time < 0.0f) {
        return Result::InvalidArguments;
    }
    if (!target.context || target.id < 0 || !target.width || !target.height) {
        return Result::InvalidArguments;
    }
    if (target.width != scene->pImpl->cfg.width || target.height != scene->pImpl->cfg.height) return Result::InvalidArguments;
    if (pImpl->active) {
        if (!renderer::tvgSuccess(pImpl->canvas->remove())) return Result::Unknown;
        pImpl->active = false;
    }
    if (!pImpl->canvas || pImpl->antialiasing != scene->pImpl->cfg.antialiasing) {
        delete pImpl->canvas;
        pImpl->canvas = tvg::GlCanvas::gen(scene->pImpl->cfg.antialiasing ? tvg::EngineOption::Default
                                                                          : tvg::EngineOption::Aliased);
        pImpl->antialiasing = scene->pImpl->cfg.antialiasing;
        if (!pImpl->canvas) return Result::NonSupport;
    }
    if (!renderer::tvgSuccess(pImpl->canvas->target(target.display, target.surface, target.context, target.id, target.width, target.height, tvg::ColorSpace::ABGR8888S))) {
        return Result::NonSupport;
    }
    tvg::Scene* root = nullptr;
    auto result = renderer::tvgPaints(scene, time, root);
    if (result != Result::Success) return result;
    if (!renderer::tvgSuccess(pImpl->canvas->add(root))) {
        renderer::tvgRelease(root);
        return Result::Unknown;
    }
    pImpl->active = true;
    if (!renderer::tvgSuccess(pImpl->canvas->update())) return Result::Unknown;
    if (!renderer::tvgSuccess(pImpl->canvas->draw(true))) return Result::Unknown;
    if (!renderer::tvgSuccess(pImpl->canvas->sync())) return Result::Unknown;
    return Result::Success;
}

namespace renderer
{

bool glEnabled() noexcept
{
    return true;
}

GlRenderer* genGl() noexcept
{
    return GlRenderer::gen();
}

}  // namespace renderer

}  // namespace tmath
