#include <cmath>
#include <cstdio>
#include <cstring>
#include <new>

#include "tmath_chart.h"

namespace tmath::chart
{

namespace
{

struct SeriesData
{
    char* id = nullptr;
    char* label = nullptr;
    Mark mark = Mark::Line;
    Point* points = nullptr;
    uint32_t count = 0u;
    int32_t colorIndex = -1;
};

static bool _finite(float value) noexcept
{
    return std::isfinite(value);
}

static bool _finite(const Vec2& value) noexcept
{
    return _finite(value.x) && _finite(value.y);
}

static bool _validText(const char* text, uint32_t limit, bool empty = false) noexcept
{
    if (!text) return false;
    auto length = 0u;
    while (length <= limit && text[length]) length++;
    return length <= limit && (empty || length > 0u);
}

static char* _copy(const char* text, uint32_t limit) noexcept
{
    if (!text) return nullptr;
    auto length = 0u;
    while (length <= limit && text[length]) length++;
    if (length > limit) return nullptr;
    auto output = new (std::nothrow) char[length + 1u];
    if (!output) return nullptr;
    std::memcpy(output, text, length + 1u);
    return output;
}

static bool _valid(const Range& range) noexcept
{
    return _finite(range.min) && _finite(range.max) && range.min < range.max
           && _finite(range.max - range.min);
}

static bool _valid(const Config& config) noexcept
{
    if (!_validText(config.id, Chart::IdLimit) || !_finite(config.frame.center)
        || !_finite(config.frame.size) || config.frame.size.x <= 0.0f
        || config.frame.size.y <= 0.0f || !_valid(config.x) || !_valid(config.y)
        || !_finite(config.padding) || !_finite(config.lineWidth)
        || !_finite(config.barGap) || config.padding <= 0.0f
        || config.lineWidth <= 0.0f || config.barGap < 0.0f
        || config.padding * 2.0f >= config.frame.size.x
        || config.padding * 2.0f >= config.frame.size.y
        || config.xTicks > Chart::TickLimit || config.yTicks > Chart::TickLimit) {
        return false;
    }
    if (!_finite(config.frame.center.x - config.frame.size.x * 0.5f)
        || !_finite(config.frame.center.x + config.frame.size.x * 0.5f)
        || !_finite(config.frame.center.y - config.frame.size.y * 0.5f)
        || !_finite(config.frame.center.y + config.frame.size.y * 0.5f)) {
        return false;
    }
    if ((config.xTicks == 1u) || (config.yTicks == 1u)) return false;
    return true;
}

static bool _valid(const Theme& theme) noexcept
{
    return theme.objectCount > 0u && theme.objectCount <= Theme::ColorLimit
           && _finite(theme.objectWidth) && theme.objectWidth > 0.0f
           && theme.code.font && theme.code.font[0] && _finite(theme.code.size)
           && theme.code.size > 0.0f;
}

static void _clear(SeriesData& series) noexcept
{
    delete[] series.id;
    delete[] series.label;
    delete[] series.points;
    series = {};
}

static bool _tag(Object* object, const char* value) noexcept
{
    if (!object || !value) return false;
    object->tag(value);
    return object->tag() && std::strcmp(object->tag(), value) == 0;
}

static bool _tag(Object* object, const char* prefix, const char* section,
                 const char* id = nullptr, int32_t index = -1) noexcept
{
    char value[320];
    int length = 0;
    if (id && index >= 0) {
        length = std::snprintf(value, sizeof(value), "%s/%s/%s/%d", prefix, section, id,
                               index);
    } else if (id) {
        length = std::snprintf(value, sizeof(value), "%s/%s/%s", prefix, section, id);
    } else if (index >= 0) {
        length = std::snprintf(value, sizeof(value), "%s/%s/%d", prefix, section, index);
    } else {
        length = std::snprintf(value, sizeof(value), "%s/%s", prefix, section);
    }
    return length > 0 && static_cast<size_t>(length) < sizeof(value) && _tag(object, value);
}

static Result _attach(Object* parent, Object* child) noexcept
{
    if (!parent || !child) {
        delete child;
        return Result::OutOfMemory;
    }
    auto result = parent->add(child);
    if (result != Result::Success) delete child;
    return result;
}

static float _map(float value, const Range& domain, float start, float extent) noexcept
{
    auto progress = (value - domain.min) / (domain.max - domain.min);
    return start + progress * extent;
}

static float _tick(const Range& range, uint32_t index, uint32_t count) noexcept
{
    if (count <= 1u) return range.min;
    return range.min + (range.max - range.min)
                           * (static_cast<float>(index) / static_cast<float>(count - 1u));
}

static bool _seriesTag(Object* object, const char* prefix, const char* id) noexcept
{
    return _tag(object, prefix, "series", id);
}

}  // namespace

struct Chart::Impl
{
    Config config;
    char* id = nullptr;
    SeriesData* series = nullptr;
    uint32_t count = 0u;
    uint32_t capacity = 0u;

    ~Impl()
    {
        for (auto i = 0u; i < count; i++) _clear(series[i]);
        delete[] series;
        delete[] id;
    }

    bool grow() noexcept
    {
        if (count < capacity) return true;
        auto nextCapacity = capacity ? capacity * 2u : 4u;
        if (nextCapacity > Chart::SeriesLimit) nextCapacity = Chart::SeriesLimit;
        auto next = new (std::nothrow) SeriesData[nextCapacity]{};
        if (!next) return false;
        for (auto i = 0u; i < count; i++) next[i] = series[i];
        delete[] series;
        series = next;
        capacity = nextCapacity;
        return true;
    }
};

struct Built::Impl
{
    struct SeriesEntry
    {
        Object* object = nullptr;
        Object** marks = nullptr;
        uint32_t count = 0u;
        Text* legend = nullptr;
    };

    Group* root = nullptr;
    Group* axes = nullptr;
    Group* grid = nullptr;
    Group* labels = nullptr;
    SeriesEntry* series = nullptr;
    uint32_t seriesCount = 0u;
    Text** xTicks = nullptr;
    uint32_t xTickCount = 0u;
    Text** yTicks = nullptr;
    uint32_t yTickCount = 0u;

    ~Impl()
    {
        delete root;
        for (auto i = 0u; i < seriesCount; i++) delete[] series[i].marks;
        delete[] series;
        delete[] xTicks;
        delete[] yTicks;
    }

    bool allocate(uint32_t count, uint32_t xCount, uint32_t yCount) noexcept
    {
        seriesCount = count;
        xTickCount = xCount;
        yTickCount = yCount;
        series = new (std::nothrow) SeriesEntry[count]{};
        if (!series) return false;
        if (xCount) {
            xTicks = new (std::nothrow) Text*[xCount]{};
            if (!xTicks) return false;
        }
        if (yCount) {
            yTicks = new (std::nothrow) Text*[yCount]{};
            if (!yTicks) return false;
        }
        return true;
    }
};

Chart::Chart(Impl* impl) noexcept : pImpl(impl)
{
}

Chart::~Chart()
{
    delete pImpl;
}

Chart* Chart::gen(const Config& config) noexcept
{
    if (!_valid(config)) return nullptr;
    auto impl = new (std::nothrow) Impl;
    if (!impl) return nullptr;
    impl->config = config;
    impl->id = _copy(config.id, IdLimit);
    if (!impl->id) {
        delete impl;
        return nullptr;
    }
    impl->config.id = impl->id;
    auto chart = new (std::nothrow) Chart(impl);
    if (!chart) delete impl;
    return chart;
}

Result Chart::add(const SeriesSpec& spec, Series& output) noexcept
{
    if (!pImpl || output || !_validText(spec.id, IdLimit)
        || (spec.label && !_validText(spec.label, LabelLimit, true))
        || static_cast<uint8_t>(spec.mark) > static_cast<uint8_t>(Mark::Bar)
        || !spec.data || !spec.count || spec.count > PointLimit
        || (spec.mark == Mark::Line && spec.count < 2u)
        || spec.colorIndex < -1 || spec.colorIndex >= static_cast<int32_t>(Theme::ColorLimit)) {
        return Result::InvalidArguments;
    }
    if (pImpl->count >= SeriesLimit) return Result::InsufficientCondition;
    for (auto i = 0u; i < pImpl->count; i++) {
        if (std::strcmp(pImpl->series[i].id, spec.id) == 0) return Result::InvalidArguments;
    }
    for (auto i = 0u; i < spec.count; i++) {
        if (!_finite(spec.data[i].x) || !_finite(spec.data[i].y)) {
            return Result::InvalidArguments;
        }
    }

    SeriesData next;
    next.id = _copy(spec.id, IdLimit);
    next.label = spec.label ? _copy(spec.label, LabelLimit) : nullptr;
    next.points = new (std::nothrow) Point[spec.count];
    if (!next.id || (spec.label && !next.label) || !next.points) {
        _clear(next);
        return Result::OutOfMemory;
    }
    std::memcpy(next.points, spec.data, sizeof(Point) * spec.count);
    next.mark = spec.mark;
    next.count = spec.count;
    next.colorIndex = spec.colorIndex;
    if (!pImpl->grow()) {
        _clear(next);
        return Result::OutOfMemory;
    }
    auto index = pImpl->count++;
    pImpl->series[index] = next;
    output.index = index;
    return Result::Success;
}

uint32_t Chart::count() const noexcept
{
    return pImpl ? pImpl->count : 0u;
}

Built::Built(Impl* impl) noexcept : pImpl(impl)
{
}

Built::~Built()
{
    delete pImpl;
}

Group* Built::root() const noexcept
{
    return pImpl ? pImpl->root : nullptr;
}

Group* Built::axes() const noexcept
{
    return pImpl ? pImpl->axes : nullptr;
}

Group* Built::grid() const noexcept
{
    return pImpl ? pImpl->grid : nullptr;
}

Group* Built::labels() const noexcept
{
    return pImpl ? pImpl->labels : nullptr;
}

Object* Built::series(Series handle) const noexcept
{
    if (!pImpl || !handle || handle.index >= pImpl->seriesCount) return nullptr;
    return pImpl->series[handle.index].object;
}

uint32_t Built::markCount(Series handle) const noexcept
{
    if (!pImpl || !handle || handle.index >= pImpl->seriesCount) return 0u;
    return pImpl->series[handle.index].count;
}

Object* Built::mark(Series handle, uint32_t index) const noexcept
{
    if (!pImpl || !handle || handle.index >= pImpl->seriesCount) return nullptr;
    auto& entry = pImpl->series[handle.index];
    return index < entry.count ? entry.marks[index] : nullptr;
}

Text* Built::legend(Series handle) const noexcept
{
    if (!pImpl || !handle || handle.index >= pImpl->seriesCount) return nullptr;
    return pImpl->series[handle.index].legend;
}

uint32_t Built::xTickCount() const noexcept
{
    return pImpl ? pImpl->xTickCount : 0u;
}

Text* Built::xTick(uint32_t index) const noexcept
{
    return pImpl && index < pImpl->xTickCount ? pImpl->xTicks[index] : nullptr;
}

uint32_t Built::yTickCount() const noexcept
{
    return pImpl ? pImpl->yTickCount : 0u;
}

Text* Built::yTick(uint32_t index) const noexcept
{
    return pImpl && index < pImpl->yTickCount ? pImpl->yTicks[index] : nullptr;
}

Group* Built::release() noexcept
{
    if (!pImpl) return nullptr;
    auto root = pImpl->root;
    pImpl->root = nullptr;
    return root;
}

Result Chart::build(const Theme& theme, Built*& output) const noexcept
{
    if (!pImpl || output || !_valid(theme)) return Result::InvalidArguments;
    if (!pImpl->count) return Result::InsufficientCondition;
    for (auto i = 0u; i < pImpl->count; i++) {
        auto colorIndex = pImpl->series[i].colorIndex;
        if (colorIndex >= static_cast<int32_t>(theme.objectCount)) {
            return Result::InvalidArguments;
        }
        if (pImpl->series[i].mark == Mark::Bar
            && (pImpl->config.frame.size.x - 2.0f * pImpl->config.padding)
                       / static_cast<float>(pImpl->series[i].count)
                   <= pImpl->config.barGap) {
            return Result::InsufficientCondition;
        }
    }

    auto impl = new (std::nothrow) Built::Impl;
    if (!impl) return Result::OutOfMemory;
    auto xLabelCount = pImpl->config.ticks ? pImpl->config.xTicks : 0u;
    auto yLabelCount = pImpl->config.ticks ? pImpl->config.yTicks : 0u;
    if (!impl->allocate(pImpl->count, xLabelCount, yLabelCount)) {
        delete impl;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < pImpl->count; i++) {
        auto markCount = pImpl->series[i].mark == Mark::Line ? 1u : pImpl->series[i].count;
        impl->series[i].marks = new (std::nothrow) Object*[markCount]{};
        if (!impl->series[i].marks) {
            delete impl;
            return Result::OutOfMemory;
        }
        impl->series[i].count = markCount;
    }

    auto built = new (std::nothrow) Built(impl);
    if (!built) {
        delete impl;
        return Result::OutOfMemory;
    }

    auto root = Group::gen();
    auto grid = Group::gen();
    auto axes = Group::gen();
    auto seriesRoot = Group::gen();
    auto labels = Group::gen();
    if (!root || !grid || !axes || !seriesRoot || !labels
        || !_tag(root, pImpl->id, "chart") || !_tag(grid, pImpl->id, "grid")
        || !_tag(axes, pImpl->id, "axes") || !_tag(seriesRoot, pImpl->id, "series")
        || !_tag(labels, pImpl->id, "labels")) {
        delete root;
        delete grid;
        delete axes;
        delete seriesRoot;
        delete labels;
        delete built;
        return Result::OutOfMemory;
    }
    impl->root = root;
    impl->grid = grid;
    impl->axes = axes;
    impl->labels = labels;
    auto result = _attach(root, grid);
    if (result != Result::Success) {
        delete axes;
        delete seriesRoot;
        delete labels;
        delete built;
        return result;
    }
    result = _attach(root, axes);
    if (result != Result::Success) {
        delete seriesRoot;
        delete labels;
        delete built;
        return result;
    }
    result = _attach(root, seriesRoot);
    if (result != Result::Success) {
        delete labels;
        delete built;
        return result;
    }
    result = _attach(root, labels);
    if (result != Result::Success) {
        delete built;
        return result;
    }

    auto& config = pImpl->config;
    auto left = config.frame.center.x - config.frame.size.x * 0.5f + config.padding;
    auto bottom = config.frame.center.y - config.frame.size.y * 0.5f + config.padding;
    auto width = config.frame.size.x - config.padding * 2.0f;
    auto height = config.frame.size.y - config.padding * 2.0f;
    auto baselineX = _map(std::fmax(config.x.min, std::fmin(config.x.max, 0.0f)),
                          config.x, left, width);
    auto baselineY = _map(std::fmax(config.y.min, std::fmin(config.y.max, 0.0f)),
                          config.y, bottom, height);
    auto tickSize = std::fmin(config.padding * 0.2f, 8.0f);

    if (config.grid) {
        for (auto i = 0u; i < config.xTicks; i++) {
            auto x = _map(_tick(config.x, i, config.xTicks), config.x, left, width);
            auto line = Line::gen({x, bottom, 0.0f}, {x, bottom + height, 0.0f});
            if (!line || !_tag(line, pImpl->id, "grid-x", nullptr, static_cast<int32_t>(i))) {
                delete line;
                delete built;
                return Result::OutOfMemory;
            }
            line->stroke(theme.axis.grid, config.lineWidth * 0.5f);
            line->layer = Built::GridLayer;
            result = _attach(grid, line);
            if (result != Result::Success) {
                delete built;
                return result;
            }
        }
        for (auto i = 0u; i < config.yTicks; i++) {
            auto y = _map(_tick(config.y, i, config.yTicks), config.y, bottom, height);
            auto line = Line::gen({left, y, 0.0f}, {left + width, y, 0.0f});
            if (!line || !_tag(line, pImpl->id, "grid-y", nullptr, static_cast<int32_t>(i))) {
                delete line;
                delete built;
                return Result::OutOfMemory;
            }
            line->stroke(theme.axis.grid, config.lineWidth * 0.5f);
            line->layer = Built::GridLayer;
            result = _attach(grid, line);
            if (result != Result::Success) {
                delete built;
                return result;
            }
        }
    }

    if (config.axes) {
        auto xAxis = Line::gen({left, baselineY, 0.0f}, {left + width, baselineY, 0.0f});
        auto yAxis = Line::gen({baselineX, bottom, 0.0f}, {baselineX, bottom + height, 0.0f});
        if (!xAxis || !yAxis || !_tag(xAxis, pImpl->id, "axis-x")
            || !_tag(yAxis, pImpl->id, "axis-y")) {
            delete xAxis;
            delete yAxis;
            delete built;
            return Result::OutOfMemory;
        }
        xAxis->stroke(theme.axis.x, config.lineWidth);
        yAxis->stroke(theme.axis.y, config.lineWidth);
        xAxis->layer = Built::AxisLayer;
        yAxis->layer = Built::AxisLayer;
        result = _attach(axes, xAxis);
        if (result != Result::Success) {
            delete yAxis;
            delete built;
            return result;
        }
        result = _attach(axes, yAxis);
        if (result != Result::Success) {
            delete built;
            return result;
        }
    }

    if (config.ticks) {
        for (auto i = 0u; i < config.xTicks; i++) {
            auto value = _tick(config.x, i, config.xTicks);
            auto x = _map(value, config.x, left, width);
            auto tick = Line::gen({x, baselineY - tickSize * 0.5f, 0.0f},
                                  {x, baselineY + tickSize * 0.5f, 0.0f});
            char text[32];
            std::snprintf(text, sizeof(text), "%.4g", static_cast<double>(value));
            auto label = Text::gen(text, {x, bottom - config.padding * 0.45f, 0.0f});
            if (!tick || !label
                || !_tag(tick, pImpl->id, "tick-x", nullptr, static_cast<int32_t>(i))
                || !_tag(label, pImpl->id, "label-x", nullptr, static_cast<int32_t>(i))) {
                delete tick;
                delete label;
                delete built;
                return Result::OutOfMemory;
            }
            tick->stroke(theme.axis.x, config.lineWidth);
            tick->layer = Built::AxisLayer;
            label->role = TextRole::Code;
            label->align = {0.5f, 0.5f};
            label->fill(theme.axis.label);
            label->layer = Built::LabelLayer;
            impl->xTicks[i] = label;
            result = _attach(labels, label);
            if (result != Result::Success) {
                delete tick;
                delete built;
                return result;
            }
            result = _attach(axes, tick);
            if (result != Result::Success) {
                delete built;
                return result;
            }
        }
        for (auto i = 0u; i < config.yTicks; i++) {
            auto value = _tick(config.y, i, config.yTicks);
            auto y = _map(value, config.y, bottom, height);
            auto tick = Line::gen({baselineX - tickSize * 0.5f, y, 0.0f},
                                  {baselineX + tickSize * 0.5f, y, 0.0f});
            char text[32];
            std::snprintf(text, sizeof(text), "%.4g", static_cast<double>(value));
            auto label = Text::gen(text, {left - config.padding * 0.25f, y, 0.0f});
            if (!tick || !label
                || !_tag(tick, pImpl->id, "tick-y", nullptr, static_cast<int32_t>(i))
                || !_tag(label, pImpl->id, "label-y", nullptr, static_cast<int32_t>(i))) {
                delete tick;
                delete label;
                delete built;
                return Result::OutOfMemory;
            }
            tick->stroke(theme.axis.y, config.lineWidth);
            tick->layer = Built::AxisLayer;
            label->role = TextRole::Code;
            label->align = {1.0f, 0.5f};
            label->fill(theme.axis.label);
            label->layer = Built::LabelLayer;
            impl->yTicks[i] = label;
            result = _attach(labels, label);
            if (result != Result::Success) {
                delete tick;
                delete built;
                return result;
            }
            result = _attach(axes, tick);
            if (result != Result::Success) {
                delete built;
                return result;
            }
        }
    }

    auto colorCursor = 0u;
    for (auto i = 0u; i < pImpl->count; i++) {
        auto& source = pImpl->series[i];
        auto colorIndex = source.colorIndex >= 0 ? static_cast<uint32_t>(source.colorIndex)
                                                  : colorCursor++ % theme.objectCount;
        auto color = theme.objects[colorIndex];
        if (source.mark == Mark::Line) {
            auto points = new (std::nothrow) Vec3[source.count];
            if (!points) {
                delete built;
                return Result::OutOfMemory;
            }
            for (auto j = 0u; j < source.count; j++) {
                points[j] = {_map(source.points[j].x, config.x, left, width),
                             _map(source.points[j].y, config.y, bottom, height), 0.0f};
                if (!_finite(points[j].x) || !_finite(points[j].y)) {
                    delete[] points;
                    delete built;
                    return Result::InvalidArguments;
                }
            }
            auto plot = Plot::gen(points, source.count);
            delete[] points;
            if (!plot || !_seriesTag(plot, pImpl->id, source.id)) {
                delete plot;
                delete built;
                return Result::OutOfMemory;
            }
            plot->stroke(color, config.lineWidth);
            plot->layer = Built::SeriesLayer;
            result = _attach(seriesRoot, plot);
            if (result != Result::Success) {
                delete built;
                return result;
            }
            impl->series[i].object = plot;
            impl->series[i].marks[0] = plot;
        } else {
            auto group = Group::gen();
            if (!group || !_seriesTag(group, pImpl->id, source.id)) {
                delete group;
                delete built;
                return Result::OutOfMemory;
            }
            result = _attach(seriesRoot, group);
            if (result != Result::Success) {
                delete built;
                return result;
            }
            impl->series[i].object = group;
            auto barWidth = width / static_cast<float>(source.count) - config.barGap;
            for (auto j = 0u; j < source.count; j++) {
                auto valueY = _map(source.points[j].y, config.y, bottom, height);
                auto valueX = _map(source.points[j].x, config.x, left, width);
                auto barHeight = std::fabs(valueY - baselineY);
                auto centerY = baselineY + (valueY - baselineY) * 0.5f;
                if (!_finite(valueX) || !_finite(valueY) || !_finite(barHeight)
                    || !_finite(centerY)) {
                    delete built;
                    return Result::InvalidArguments;
                }
                if (barHeight == 0.0f) barHeight = std::fmax(height * 1.0e-5f, 0.001f);
                auto bar = Rectangle::gen({valueX, centerY, 0.0f}, {barWidth, barHeight});
                if (!bar
                    || !_tag(bar, pImpl->id, "series", source.id, static_cast<int32_t>(j))) {
                    delete bar;
                    delete built;
                    return Result::OutOfMemory;
                }
                bar->fill(color);
                bar->stroke(color, theme.objectWidth * 0.5f);
                bar->layer = Built::SeriesLayer;
                result = _attach(group, bar);
                if (result != Result::Success) {
                    delete built;
                    return result;
                }
                impl->series[i].marks[j] = bar;
            }
        }

        if (config.legend && source.label && source.label[0]) {
            auto slot = width / static_cast<float>(pImpl->count);
            auto point = Vec3{left + slot * (static_cast<float>(i) + 0.5f),
                              config.frame.center.y + config.frame.size.y * 0.5f
                                  - config.padding * 0.3f,
                              0.0f};
            auto label = Text::gen(source.label, point);
            if (!label || !_tag(label, pImpl->id, "legend", source.id)) {
                delete label;
                delete built;
                return Result::OutOfMemory;
            }
            label->role = TextRole::Code;
            label->align = {0.5f, 0.5f};
            label->fill(color);
            label->layer = Built::LabelLayer;
            result = _attach(labels, label);
            if (result != Result::Success) {
                delete built;
                return result;
            }
            impl->series[i].legend = label;
        }
    }

    output = built;
    return Result::Success;
}

}  // namespace tmath::chart
