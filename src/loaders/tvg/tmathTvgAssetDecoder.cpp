#include <cmath>
#include <limits>
#include <new>

#include <thorvg.h>

#include "tmath.h"
#include "tmathAssetDecoder.h"
#include "tmathTvgRenderer.h"

namespace tmath::asset
{

static constexpr uint32_t MAX_ASSET_PIXELS = 16777216;

static Result _result(tvg::Result result)
{
    switch (result) {
        case tvg::Result::Success: return Result::Success;
        case tvg::Result::InvalidArguments: return Result::InvalidArguments;
        case tvg::Result::InsufficientCondition: return Result::InsufficientCondition;
        case tvg::Result::FailedAllocation: return Result::OutOfMemory;
        case tvg::Result::NonSupport: return Result::NonSupport;
        default: return Result::Unknown;
    }
}

static Result _decode(tvg::Picture* picture, uint32_t*& output, uint32_t& outputWidth,
                      uint32_t& outputHeight)
{
    float sourceWidth;
    float sourceHeight;
    auto status = picture->size(&sourceWidth, &sourceHeight);
    if (status != tvg::Result::Success || !std::isfinite(sourceWidth) || !std::isfinite(sourceHeight) || sourceWidth <= 0.0f || sourceHeight <= 0.0f) {
        picture->unref();
        return status == tvg::Result::Success ? Result::InvalidArguments : _result(status);
    }
    auto widthValue = std::ceil(static_cast<double>(sourceWidth));
    auto heightValue = std::ceil(static_cast<double>(sourceHeight));
    if (widthValue > UINT32_MAX || heightValue > UINT32_MAX) {
        picture->unref();
        return Result::InvalidArguments;
    }
    auto width = static_cast<uint32_t>(widthValue);
    auto height = static_cast<uint32_t>(heightValue);
    if (!width || !height || height > MAX_ASSET_PIXELS / width) {
        picture->unref();
        return Result::InvalidArguments;
    }
    auto pixels = new (std::nothrow) uint32_t[static_cast<size_t>(width) * height]();
    if (!pixels) {
        picture->unref();
        return Result::OutOfMemory;
    }
    auto canvas = tvg::SwCanvas::gen();
    if (!canvas) {
        picture->unref();
        delete[] pixels;
        return Result::NonSupport;
    }
    if (picture->size(static_cast<float>(width), static_cast<float>(height)) != tvg::Result::Success || canvas->target(pixels, width, width, height, tvg::ColorSpace::ABGR8888S) != tvg::Result::Success) {
        picture->unref();
        delete canvas;
        delete[] pixels;
        return Result::NonSupport;
    }
    if (canvas->add(picture) != tvg::Result::Success) {
        picture->unref();
        delete canvas;
        delete[] pixels;
        return Result::NonSupport;
    }
    if (canvas->update() != tvg::Result::Success || canvas->draw(true) != tvg::Result::Success || canvas->sync() != tvg::Result::Success) {
        delete canvas;
        delete[] pixels;
        return Result::NonSupport;
    }
    delete canvas;
    output = pixels;
    outputWidth = width;
    outputHeight = height;
    return Result::Success;
}

Result decode(const char* path, uint32_t*& pixels, uint32_t& width,
              uint32_t& height) noexcept
{
    pixels = nullptr;
    width = 0;
    height = 0;
    if (!path || !path[0]) return Result::InvalidArguments;
    if (!renderer::tvgInit()) return Result::NonSupport;
    auto picture = tvg::Picture::gen();
    auto result = picture ? _result(picture->load(path)) : Result::OutOfMemory;
    if (result == Result::Success) result = _decode(picture, pixels, width, height);
    else if (picture) picture->unref();
    renderer::tvgTerm();
    return result;
}

Result decode(const void* data, uint32_t size, const char* mime,
              uint32_t*& pixels, uint32_t& width, uint32_t& height) noexcept
{
    pixels = nullptr;
    width = 0;
    height = 0;
    if (!data || !size || !mime || !mime[0]) return Result::InvalidArguments;
    if (!renderer::tvgInit()) return Result::NonSupport;
    auto picture = tvg::Picture::gen();
    auto result = picture ? _result(picture->load(static_cast<const char*>(data), size, mime, nullptr, true))
                          : Result::OutOfMemory;
    if (result == Result::Success) result = _decode(picture, pixels, width, height);
    else if (picture) picture->unref();
    renderer::tvgTerm();
    return result;
}

}  // namespace tmath::asset
