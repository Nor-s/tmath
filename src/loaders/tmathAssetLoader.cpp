#include <cstring>
#include <new>

#include "tmath.h"
#include "tmathAssetDecoder.h"

namespace tmath
{

static constexpr uint32_t MAX_ASSET_PIXELS = 16777216;

Asset::Asset(uint32_t* pixels, uint32_t width, uint32_t height) noexcept :
    pixels(pixels), pixelWidth(width), pixelHeight(height)
{
}

Asset::~Asset()
{
    delete[] pixels;
}

uint32_t Asset::width() const noexcept
{
    return pixelWidth;
}

uint32_t Asset::height() const noexcept
{
    return pixelHeight;
}

const uint32_t* Asset::data() const noexcept
{
    return pixels;
}

Result AssetLoader::load(const char* path, Asset*& output) noexcept
{
    output = nullptr;
    uint32_t* pixels = nullptr;
    uint32_t width = 0;
    uint32_t height = 0;
    auto result = asset::decode(path, pixels, width, height);
    if (result != Result::Success) return result;
    output = new (std::nothrow) Asset(pixels, width, height);
    if (output) return Result::Success;
    delete[] pixels;
    return Result::OutOfMemory;
}

Result AssetLoader::load(const void* data, uint32_t size, const char* mime,
                         Asset*& output) noexcept
{
    output = nullptr;
    uint32_t* pixels = nullptr;
    uint32_t width = 0;
    uint32_t height = 0;
    auto result = asset::decode(data, size, mime, pixels, width, height);
    if (result != Result::Success) return result;
    output = new (std::nothrow) Asset(pixels, width, height);
    if (output) return Result::Success;
    delete[] pixels;
    return Result::OutOfMemory;
}

Result AssetLoader::load(const uint32_t* pixels, uint32_t width, uint32_t height, Asset*& output) noexcept
{
    output = nullptr;
    if (!pixels || !width || !height || height > MAX_ASSET_PIXELS / width) return Result::InvalidArguments;
    auto copy = new (std::nothrow) uint32_t[static_cast<size_t>(width) * height];
    if (!copy) return Result::OutOfMemory;
    std::memcpy(copy, pixels, static_cast<size_t>(width) * height * sizeof(uint32_t));
    output = new (std::nothrow) Asset(copy, width, height);
    if (output) return Result::Success;
    delete[] copy;
    return Result::OutOfMemory;
}

}  // namespace tmath
