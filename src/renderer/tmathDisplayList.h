#ifndef _TMATH_DISPLAY_LIST_H_
#define _TMATH_DISPLAY_LIST_H_

#include "tmath.h"

namespace tmath
{

static constexpr uint32_t DISPLAY_COMMAND_LIMIT = 65536;

enum struct CommandType : uint8_t
{
    Path,
    Circle,
    Text,
    Number,
    Svg,
    Image
};

enum struct PathCap : uint8_t
{
    Round,
    Butt
};

struct DrawCommand
{
    const Object* object = nullptr;
    CommandType type = CommandType::Path;
    Vec2* points = nullptr;
    uint32_t count = 0;
    Style style;
    Vec2 center;
    Vec2 align;
    Mat3 transform = Mat3::identity();
    const char* text = nullptr;
    const char* font = nullptr;
    const char* path = nullptr;
    const uint32_t* pixels = nullptr;
    uint32_t pixelWidth = 0;
    uint32_t pixelHeight = 0;
    ImageFilter filter = ImageFilter::Bilinear;
    float radius = 0.0f;
    float size = 0.0f;
    float number = 0.0f;
    float rotation = 0.0f;
    float depth = 0.0f;
    int32_t layer = 0;
    uint32_t order = 0;
    uint8_t opacity = 255;
    bool closed = false;
    bool transformed = false;
    PathCap cap = PathCap::Round;
};

struct DisplayList
{
    DrawCommand* commands = nullptr;
    uint32_t count = 0;
    uint32_t capacity = 0;
    const Object* object = nullptr;

    DisplayList() = default;
    ~DisplayList();
    DisplayList(const DisplayList&) = delete;
    DisplayList& operator=(const DisplayList&) = delete;
    Result path(const Vec2* points, uint32_t count, bool closed, const Style& style,
                int32_t layer, float depth = 0.0f,
                PathCap cap = PathCap::Round) noexcept;
    Result circle(const Vec2& center, float radius, const Style& style, int32_t layer, float depth = 0.0f) noexcept;
    Result text(const Vec2& point, const char* value, const char* font, float size,
                const Vec2& align, const Style& style, int32_t layer,
                float depth = 0.0f, const Mat3* transform = nullptr) noexcept;
    Result number(const Vec2& point, float value, float size, const Vec2& align, const Style& style,
                  int32_t layer, float depth = 0.0f) noexcept;
    Result svg(const Vec2& center, const char* path, float width, float rotation, uint8_t opacity, int32_t layer) noexcept;
    Result image(const Vec2* corners, const uint32_t* pixels, uint32_t width, uint32_t height,
                 ImageFilter filter, uint8_t opacity, int32_t layer, float depth) noexcept;
    Result blend(const DisplayList& from, const DisplayList& to, const uint32_t* matches,
                 uint32_t fromObjects, uint32_t toObjects, const Vec2& fromSize,
                 const Vec2& toSize, float progress) noexcept;
    void sort() noexcept;

private:
    DrawCommand* append() noexcept;
};

}  // namespace tmath

#endif
