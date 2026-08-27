#include "tmathAssetDecoder.h"

namespace tmath::asset
{

Result decode(const char* path, uint32_t*& pixels, uint32_t& width,
              uint32_t& height) noexcept
{
    pixels = nullptr;
    width = 0;
    height = 0;
    return path && path[0] ? Result::NonSupport : Result::InvalidArguments;
}

Result decode(const void* data, uint32_t size, const char* mime,
              uint32_t*& pixels, uint32_t& width, uint32_t& height) noexcept
{
    pixels = nullptr;
    width = 0;
    height = 0;
    if (!data || !size || !mime || !mime[0]) return Result::InvalidArguments;
    return Result::NonSupport;
}

}  // namespace tmath::asset
