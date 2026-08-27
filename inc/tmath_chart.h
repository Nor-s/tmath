#ifndef _TMATH_CHART_H_
#define _TMATH_CHART_H_

#include "tmath.h"

namespace tmath::chart
{

enum struct Mark : uint8_t
{
    Line = 0,
    Bar
};

struct Frame
{
    Vec2 center;
    Vec2 size;
};

struct Point
{
    float x = 0.0f;
    float y = 0.0f;
};

struct Series
{
    static constexpr uint32_t Invalid = 0xffffffffu;

    uint32_t index = Invalid;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct SeriesSpec
{
    const char* id = nullptr;
    const char* label = nullptr;
    Mark mark = Mark::Line;
    const Point* data = nullptr;
    uint32_t count = 0;
    int32_t colorIndex = -1;
};

struct Config
{
    const char* id = "chart";
    Frame frame = {{0.0f, 0.0f}, {800.0f, 320.0f}};
    Range x = {0.0f, 1.0f, 1.0f};
    Range y = {0.0f, 1.0f, 1.0f};
    uint32_t xTicks = 5u;
    uint32_t yTicks = 5u;
    bool axes = true;
    bool grid = true;
    bool ticks = true;
    bool legend = true;
    float padding = 36.0f;
    float lineWidth = 3.0f;
    float barGap = 4.0f;
};

struct Built;

struct Chart
{
    static constexpr uint32_t SeriesLimit = 32u;
    static constexpr uint32_t PointLimit = 4096u;
    static constexpr uint32_t TickLimit = 32u;
    static constexpr uint32_t IdLimit = 96u;
    static constexpr uint32_t LabelLimit = 256u;

    ~Chart();
    Chart(const Chart&) = delete;
    Chart& operator=(const Chart&) = delete;

    static Chart* gen(const Config& config = {}) noexcept;
    Result add(const SeriesSpec& spec, Series& output) noexcept;
    uint32_t count() const noexcept;
    Result build(const Theme& theme, Built*& output) const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Chart(Impl* impl) noexcept;
};

struct Built
{
    static constexpr int32_t GridLayer = 0;
    static constexpr int32_t AxisLayer = 10;
    static constexpr int32_t SeriesLayer = 20;
    static constexpr int32_t LabelLayer = 30;

    ~Built();
    Built(const Built&) = delete;
    Built& operator=(const Built&) = delete;

    Group* root() const noexcept;
    Group* axes() const noexcept;
    Group* grid() const noexcept;
    Group* labels() const noexcept;
    Object* series(Series handle) const noexcept;
    uint32_t markCount(Series handle) const noexcept;
    Object* mark(Series handle, uint32_t index) const noexcept;
    Text* legend(Series handle) const noexcept;
    uint32_t xTickCount() const noexcept;
    Text* xTick(uint32_t index) const noexcept;
    uint32_t yTickCount() const noexcept;
    Text* yTick(uint32_t index) const noexcept;
    Group* release() noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Built(Impl* impl) noexcept;
    friend struct Chart;
};

struct Lua
{
    static Result load(const char* source, uint32_t size, const char* name,
                       Scene** scene, char* error, uint32_t errorSize,
                       tmath::Lua::AssetResolver resolver = nullptr,
                       void* resolverData = nullptr,
                       const Theme* adaptiveTheme = nullptr,
                       bool* adaptiveThemeUsed = nullptr) noexcept;
};

}  // namespace tmath::chart

#endif
