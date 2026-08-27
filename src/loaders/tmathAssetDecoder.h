#ifndef _TMATH_ASSET_DECODER_H_
#define _TMATH_ASSET_DECODER_H_

#include <cstdint>

#include "tmath.h"

namespace tmath::asset
{

Result decode(const char* path, uint32_t*& pixels, uint32_t& width,
              uint32_t& height) noexcept;
Result decode(const void* data, uint32_t size, const char* mime,
              uint32_t*& pixels, uint32_t& width, uint32_t& height) noexcept;

}  // namespace tmath::asset

#endif
