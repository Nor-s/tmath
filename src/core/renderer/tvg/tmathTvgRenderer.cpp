#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <limits>
#include <new>

#include <thorvg.h>

#include "tmath.h"
#include "tmathDisplayList.h"
#include "tmathTvgRenderer.h"
#include "tmathScene.h"

namespace tmath
{

static bool _success(tvg::Result result)
{
    return result == tvg::Result::Success;
}

static void _release(tvg::Paint* paint)
{
    paint->unref();
}

static bool _add(tvg::Scene* scene, tvg::Paint* paint)
{
    if (!paint) return false;
    if (_success(scene->add(paint))) return true;
    _release(paint);
    return false;
}

static void _extent(const DrawCommand& command, Vec2& min, Vec2& max)
{
    if (command.type == CommandType::Circle) {
        min = {command.center.x - command.radius, command.center.y - command.radius};
        max = {command.center.x + command.radius, command.center.y + command.radius};
        return;
    }
    min = max = command.count ? command.points[0] : Vec2{};
    for (auto i = 1u; i < command.count; i++) {
        min.x = std::fmin(min.x, command.points[i].x);
        min.y = std::fmin(min.y, command.points[i].y);
        max.x = std::fmax(max.x, command.points[i].x);
        max.y = std::fmax(max.y, command.points[i].y);
    }
}

static void _linearAxis(const DrawCommand& command, Vec2& from, Vec2& to)
{
    auto& gradient = command.style.gradient;
    if (gradient.line) {
        from = {gradient.from.x, gradient.from.y};
        to = {gradient.to.x, gradient.to.y};
    } else if (command.type == CommandType::Circle) {
        _extent(command, from, to);
    } else if (command.count) {
        if (!command.closed && command.count > 1u) {
            from = command.points[0];
            to = command.points[command.count - 1u];
        }
        if (command.closed || (std::fabs(to.x - from.x) < 1e-6f
                               && std::fabs(to.y - from.y) < 1e-6f)) {
            _extent(command, from, to);
        }
    }
    if (std::fabs(to.x - from.x) < 1e-6f && std::fabs(to.y - from.y) < 1e-6f) {
        to.x = from.x + 1.0f;
    }
}

static uint32_t _stops(const DrawCommand& command, Color paint,
                       tvg::Fill::ColorStop (&stops)[Gradient::StopLimit])
{
    auto& gradient = command.style.gradient;
    if (!gradient.stopCount) {
        // Legacy ramp: paint color to Style::gradientEnd, end alpha follows the paint.
        auto end = command.style.gradientEnd;
        stops[0] = {0.0f, paint.r, paint.g, paint.b, paint.a};
        stops[1] = {1.0f, end.r, end.g, end.b, paint.a};
        return 2u;
    }
    auto count = gradient.stopCount < Gradient::StopLimit ? gradient.stopCount
                                                          : Gradient::StopLimit;
    for (auto i = 0u; i < count; i++) {
        auto& stop = gradient.stops[i];
        auto alpha = (static_cast<uint32_t>(stop.color.a) * paint.a + 127u) / 255u;
        stops[i] = {stop.offset, stop.color.r, stop.color.g, stop.color.b,
                    static_cast<uint8_t>(alpha)};
    }
    return count;
}

// Resolved gradient parameters. Comparing two specs tells the retained tree whether a
// shape's Fill must be regenerated; generating from a spec matches the immediate builder.
struct FillSpec
{
    tvg::Fill::ColorStop stops[Gradient::StopLimit];
    float values[6];
    uint32_t count;
    GradientType type;

    bool operator==(const FillSpec& other) const noexcept
    {
        return std::memcmp(this, &other, sizeof(FillSpec)) == 0;
    }
};

static void _spec(const DrawCommand& command, Color paint, FillSpec& spec)
{
    std::memset(&spec, 0, sizeof(FillSpec));
    auto& gradient = command.style.gradient;
    spec.count = _stops(command, paint, spec.stops);
    Vec2 min;
    Vec2 max;
    _extent(command, min, max);
    auto mid = Vec2{(min.x + max.x) * 0.5f, (min.y + max.y) * 0.5f};
    auto center = gradient.centered ? Vec2{gradient.center.x, gradient.center.y}
                  : command.type == CommandType::Circle ? command.center
                                                        : mid;
    switch (gradient.type) {
        case GradientType::Radial: {
            spec.type = GradientType::Radial;
            auto radius = gradient.sized ? gradient.radius
                          : command.type == CommandType::Circle ? command.radius
                                                                : (max - min).length() * 0.5f;
            if (radius < 1e-3f) radius = 1.0f;
            auto focal = gradient.focused ? Vec2{gradient.focal.x, gradient.focal.y} : center;
            spec.values[0] = center.x;
            spec.values[1] = center.y;
            spec.values[2] = radius;
            spec.values[3] = focal.x;
            spec.values[4] = focal.y;
            spec.values[5] = gradient.focalRadius;
            break;
        }
        case GradientType::Conic: {
            spec.type = GradientType::Conic;
            spec.values[0] = center.x;
            spec.values[1] = center.y;
            spec.values[2] = gradient.angle;
            break;
        }
        default: {
            spec.type = GradientType::Linear;
            Vec2 from;
            Vec2 to;
            _linearAxis(command, from, to);
            spec.values[0] = from.x;
            spec.values[1] = from.y;
            spec.values[2] = to.x;
            spec.values[3] = to.y;
            break;
        }
    }
}

static tvg::Fill* _gradient(const FillSpec& spec)
{
    tvg::Fill* fill = nullptr;
    auto result = tvg::Result::Unknown;
    auto& v = spec.values;
    switch (spec.type) {
        case GradientType::Radial: {
            auto radial = tvg::RadialGradient::gen();
            if (!radial) return nullptr;
            result = radial->radial(v[0], v[1], v[2], v[3], v[4], v[5]);
            fill = radial;
            break;
        }
        case GradientType::Conic: {
            auto conic = tvg::ConicGradient::gen();
            if (!conic) return nullptr;
            result = conic->conic(v[0], v[1], v[2]);
            fill = conic;
            break;
        }
        default: {
            auto linear = tvg::LinearGradient::gen();
            if (!linear) return nullptr;
            result = linear->linear(v[0], v[1], v[2], v[3]);
            fill = linear;
            break;
        }
    }
    if (!_success(result) || !_success(fill->colorStops(spec.stops, spec.count))) {
        delete fill;
        return nullptr;
    }
    return fill;
}

static tvg::Fill* _gradient(const DrawCommand& command, Color paint)
{
    FillSpec spec;
    _spec(command, paint, spec);
    return _gradient(spec);
}

static bool _stroke(tvg::Shape* shape, const DrawCommand& command)
{
    if (!command.style.stroke.a || command.style.width <= 0.0f) return true;
    if (!_success(shape->strokeWidth(command.style.width))
        || !_success(shape->strokeCap(command.cap == PathCap::Butt
                                      ? tvg::StrokeCap::Butt
                                      : tvg::StrokeCap::Round))
        || !_success(shape->strokeJoin(tvg::StrokeJoin::Round))
        || (command.style.dashCount
            && !_success(shape->strokeDash(command.style.dash, command.style.dashCount,
                                            command.style.dashOffset)))) {
        return false;
    }
    if (!command.style.gradient.enabled()) {
        auto& color = command.style.stroke;
        return _success(shape->strokeFill(color.r, color.g, color.b, color.a));
    }
    auto gradient = _gradient(command, command.style.stroke);
    if (!gradient) return false;
    if (_success(shape->strokeFill(gradient))) return true;
    delete gradient;
    return false;
}

static bool _fill(tvg::Shape* shape, const DrawCommand& command)
{
    auto& color = command.style.fill;
    if (!command.style.gradient.enabled() || !color.a) {
        return _success(shape->fill(color.r, color.g, color.b, color.a));
    }
    auto gradient = _gradient(command, color);
    if (!gradient) return false;
    if (_success(shape->fill(gradient))) return true;
    delete gradient;
    return false;
}

static tvg::Shape* _path(const DrawCommand& command)
{
    auto shape = tvg::Shape::gen();
    if (!shape) return nullptr;
    if (!_success(shape->moveTo(command.points[0].x, command.points[0].y))) {
        _release(shape);
        return nullptr;
    }
    for (auto i = 1u; i < command.count; i++) {
        if (!_success(shape->lineTo(command.points[i].x, command.points[i].y))) {
            _release(shape);
            return nullptr;
        }
    }
    if (command.closed && !_success(shape->close())) {
        _release(shape);
        return nullptr;
    }
    if (!_stroke(shape, command) || !_fill(shape, command)) {
        _release(shape);
        return nullptr;
    }
    return shape;
}

static tvg::Shape* _circle(const DrawCommand& command)
{
    auto shape = tvg::Shape::gen();
    if (!shape) return nullptr;
    if (!_success(shape->appendCircle(command.center.x, command.center.y, command.radius, command.radius))) {
        _release(shape);
        return nullptr;
    }
    if (!_stroke(shape, command) || !_fill(shape, command)) {
        _release(shape);
        return nullptr;
    }
    return shape;
}

static tvg::Matrix _textMatrix(const DrawCommand& command)
{
    auto& source = command.transform.e;
    return {source[0], source[1], source[2],
            source[3], source[4], source[5],
            source[6], source[7], source[8]};
}

static tvg::Matrix _pictureMatrix(const DrawCommand& command)
{
    auto& source = command.picture;
    auto& origin = command.points[0];
    return {(command.points[1].x - origin.x) / static_cast<float>(source.width),
            (command.points[2].x - origin.x) / static_cast<float>(source.height), origin.x,
            (command.points[1].y - origin.y) / static_cast<float>(source.width),
            (command.points[2].y - origin.y) / static_cast<float>(source.height), origin.y,
            0.0f, 0.0f, 1.0f};
}

static tvg::Text* _text(const DrawCommand& command)
{
    auto text = tvg::Text::gen();
    if (!text) return nullptr;
    if (!_success(text->font(command.font)) || !_success(text->size(command.size)) || !_success(text->text(command.text))) {
        _release(text);
        return nullptr;
    }
    if (!_success(text->align(command.align.x, command.align.y)) || !_success(text->fill(command.style.fill.r, command.style.fill.g, command.style.fill.b)) || !_success(text->opacity(command.style.fill.a))) {
        _release(text);
        return nullptr;
    }
    if (command.transformed) {
        if (!_success(text->transform(_textMatrix(command)))) {
            _release(text);
            return nullptr;
        }
    } else if (!_success(text->translate(command.center.x, command.center.y))) {
        _release(text);
        return nullptr;
    }
    return text;
}

static bool _numberText(const DrawCommand& command, char (&value)[64])
{
    auto converted = std::to_chars(value, value + sizeof(value) - 1u, command.number,
                                   std::chars_format::general);
    if (converted.ec != std::errc{}) return false;
    *converted.ptr = '\0';
    return true;
}

static tvg::Text* _number(const DrawCommand& command)
{
    char value[64];
    if (!_numberText(command, value)) return nullptr;
    auto copy = command;
    copy.text = value;
    copy.font = nullptr;
    return _text(copy);
}

static tvg::Picture* _picture(const DrawCommand& command)
{
    auto& source = command.picture;
    auto picture = tvg::Picture::gen();
    if (!picture) return nullptr;
    // Encoded bytes are owned by the Picture object, so ThorVG may reference them without copying.
    auto loaded = source.encoded
        ? _success(picture->load(reinterpret_cast<const char*>(source.encoded), source.encodedSize, source.mime, nullptr, false))
          && _success(picture->size(static_cast<float>(source.width), static_cast<float>(source.height)))
        : _success(picture->load(source.pixels, source.width, source.height, tvg::ColorSpace::ABGR8888S, false));
    if (!loaded || !_success(picture->filter(command.filter == ImageFilter::Nearest ? tvg::FilterMethod::Nearest
                                                                                     : tvg::FilterMethod::Bilinear))) {
        _release(picture);
        return nullptr;
    }
    if (!_success(picture->transform(_pictureMatrix(command))) || !_success(picture->opacity(command.opacity))) {
        _release(picture);
        return nullptr;
    }
    return picture;
}

static tvg::Paint* _paint(const DrawCommand& command)
{
    switch (command.type) {
        case CommandType::Path: return _path(command);
        case CommandType::Circle: return _circle(command);
        case CommandType::Text: return _text(command);
        case CommandType::Number: return _number(command);
        case CommandType::Picture: return _picture(command);
    }
    return nullptr;
}

static bool _visible(const DrawCommand& command)
{
    switch (command.type) {
        case CommandType::Path:
        case CommandType::Circle:
            return command.style.fill.a || (command.style.stroke.a && command.style.width > 0.0f);
        case CommandType::Text:
        case CommandType::Number: return command.style.fill.a;
        case CommandType::Picture: return command.opacity;
    }
    return false;
}

static Color _mix(const Color& from, const Color& to, float progress)
{
    auto channel = [progress](uint8_t first, uint8_t second) {
        auto value = static_cast<float>(first)
                   + (static_cast<float>(second) - first) * progress;
        if (value < 0.0f) value = 0.0f;
        if (value > 255.0f) value = 255.0f;
        return static_cast<uint8_t>(value + 0.5f);
    };
    return {
        channel(from.r, to.r), channel(from.g, to.g),
        channel(from.b, to.b), channel(from.a, to.a)};
}

/************************************************************************/
/* Retained paint tree                                                  */
/************************************************************************/

// Bitwise comparisons: a retained property is reapplied whenever its bits change, so the
// retained paint always carries exactly the values a freshly generated paint would.
template<typename T>
static bool _same(const T& first, const T& second)
{
    return std::memcmp(&first, &second, sizeof(T)) == 0;
}

static bool _sameText(const char* first, const char* second)
{
    if (!first || !second) return first == second;
    return std::strcmp(first, second) == 0;
}

static bool _sameColor(const Color& first, const Color& second)
{
    return first.r == second.r && first.g == second.g && first.b == second.b && first.a == second.a;
}

static char* _dup(const char* text)
{
    if (!text) return nullptr;
    auto size = std::strlen(text) + 1u;
    auto copy = new (std::nothrow) char[size];
    if (copy) std::memcpy(copy, text, size);
    return copy;
}

template<typename T>
static bool _reserve(T*& values, uint32_t& capacity, uint32_t count)
{
    if (count <= capacity) return true;
    auto next = capacity ? capacity : 16u;
    while (next < count) {
        if (next > UINT32_MAX / 2u) return false;
        next *= 2u;
    }
    auto grown = new (std::nothrow) T[next];
    if (!grown) return false;
    for (auto i = 0u; i < capacity; i++)
        grown[i] = values[i];
    delete[] values;
    values = grown;
    capacity = next;
    return true;
}

static uint32_t _hash(const void* first, const void* second, uint32_t extra)
{
    auto value = static_cast<uint64_t>(reinterpret_cast<uintptr_t>(first)) * 0x9E3779B97F4A7C15ull;
    value ^= static_cast<uint64_t>(reinterpret_cast<uintptr_t>(second)) * 0xC2B2AE3D27D4EB4Full
             + (value << 6) + (value >> 2);
    value ^= static_cast<uint64_t>(extra) * 0x165667B19E3779F9ull;
    value ^= value >> 31;
    value *= 0xD6E8FEB86659FD93ull;
    value ^= value >> 32;
    return static_cast<uint32_t>(value);
}

// Stable identity of a draw command across frames: the object that emitted it (and its
// morph/blend counterpart), the command type and its rank among the commands that object
// emitted, counted in emission order so depth sorting does not change identities.
struct SlotKey
{
    const Object* object = nullptr;
    const Object* counterpart = nullptr;
    uint32_t rank = 0;
    CommandType type = CommandType::Path;

    bool operator==(const SlotKey& other) const
    {
        return object == other.object && counterpart == other.counterpart
               && rank == other.rank && type == other.type;
    }

    uint32_t hash() const
    {
        return _hash(object, counterpart, rank * 8u + static_cast<uint32_t>(type));
    }
};

// One retained ThorVG paint plus the command state last applied to it.
struct Slot
{
    SlotKey key;
    tvg::Paint* paint = nullptr;  // holds one reference owned by the slot
    bool used = false;
    // Shape
    Vec2* points = nullptr;
    uint32_t count = 0;
    uint32_t capacity = 0;
    float radius = 0.0f;
    bool closed = false;
    bool stroked = false;
    bool fillGradient = false;
    bool strokeGradient = false;
    bool dashed = false;
    float width = 0.0f;
    PathCap cap = PathCap::Round;
    float dash[Style::DashLimit] = {};
    float dashOffset = 0.0f;
    uint8_t dashCount = 0;
    Color fill;
    Color stroke;
    FillSpec fillSpec;
    FillSpec strokeSpec;
    // Shape (circle) and Text (translation)
    Vec2 center;
    // Text and Number
    char* text = nullptr;
    char* font = nullptr;
    float size = 0.0f;
    Vec2 align;
    bool transformed = false;
    // Text and Picture
    tvg::Matrix matrix = {};
    uint8_t opacity = 255;
    // Picture
    PictureSource source;
    ImageFilter filter = ImageFilter::Bilinear;

    Slot() = default;
    Slot(const Slot&) = delete;
    Slot& operator=(const Slot&) = delete;

    ~Slot()
    {
        delete[] points;
        delete[] text;
        delete[] font;
    }
};

static bool _stroked(const DrawCommand& command)
{
    return command.style.stroke.a && command.style.width > 0.0f;
}

static bool _fillGradient(const DrawCommand& command)
{
    return command.style.gradient.enabled() && command.style.fill.a;
}

static bool _storePoints(Slot& slot, const DrawCommand& command)
{
    if (command.count > slot.capacity) {
        auto points = new (std::nothrow) Vec2[command.count];
        if (!points) return false;
        delete[] slot.points;
        slot.points = points;
        slot.capacity = command.count;
    }
    if (command.count) std::memcpy(slot.points, command.points, sizeof(Vec2) * command.count);
    slot.count = command.count;
    slot.closed = command.closed;
    return true;
}

static bool _storeText(char*& target, const char* text)
{
    if (_sameText(target, text)) return true;
    auto copy = _dup(text);
    if (text && !copy) return false;
    delete[] target;
    target = copy;
    return true;
}

static bool _geometry(tvg::Shape* shape, const DrawCommand& command)
{
    if (command.type == CommandType::Circle) {
        return _success(shape->appendCircle(command.center.x, command.center.y,
                                            command.radius, command.radius));
    }
    if (!_success(shape->moveTo(command.points[0].x, command.points[0].y))) return false;
    for (auto i = 1u; i < command.count; i++) {
        if (!_success(shape->lineTo(command.points[i].x, command.points[i].y))) return false;
    }
    return !command.closed || _success(shape->close());
}

// Records the state of a paint freshly generated by _paint(command).
static bool _capture(Slot& slot, const DrawCommand& command)
{
    auto& style = command.style;
    switch (command.type) {
        case CommandType::Path:
        case CommandType::Circle: {
            if (command.type == CommandType::Path && !_storePoints(slot, command)) return false;
            slot.center = command.center;
            slot.radius = command.radius;
            slot.stroked = _stroked(command);
            slot.fillGradient = _fillGradient(command);
            slot.strokeGradient = slot.stroked && style.gradient.enabled();
            slot.dashed = slot.stroked && style.dashCount;
            slot.width = style.width;
            slot.cap = command.cap;
            std::memcpy(slot.dash, style.dash, sizeof(slot.dash));
            slot.dashCount = style.dashCount;
            slot.dashOffset = style.dashOffset;
            slot.fill = style.fill;
            slot.stroke = style.stroke;
            if (slot.fillGradient) _spec(command, style.fill, slot.fillSpec);
            if (slot.strokeGradient) _spec(command, style.stroke, slot.strokeSpec);
            return true;
        }
        case CommandType::Text:
        case CommandType::Number: {
            char value[64];
            auto text = command.text;
            auto font = command.font;
            if (command.type == CommandType::Number) {
                if (!_numberText(command, value)) return false;
                text = value;
                font = nullptr;
            }
            if (!_storeText(slot.text, text) || !_storeText(slot.font, font)) return false;
            slot.size = command.size;
            slot.align = command.align;
            slot.fill = style.fill;
            slot.transformed = command.transformed;
            slot.center = command.center;
            if (command.transformed) slot.matrix = _textMatrix(command);
            return true;
        }
        case CommandType::Picture: {
            slot.source = command.picture;
            slot.filter = command.filter;
            slot.matrix = _pictureMatrix(command);
            slot.opacity = command.opacity;
            return true;
        }
    }
    return false;
}

// Applies only the properties that changed since the last frame. Returns false with
// replace == true when the paint must be regenerated (structural change).
static bool _updateShape(Slot& slot, const DrawCommand& command, bool& replace)
{
    auto& style = command.style;
    auto stroked = _stroked(command);
    auto fillGradient = _fillGradient(command);
    auto strokeGradient = stroked && style.gradient.enabled();
    auto dashed = stroked && style.dashCount;
    if (stroked != slot.stroked || fillGradient != slot.fillGradient
        || strokeGradient != slot.strokeGradient || dashed != slot.dashed) {
        replace = true;
        return false;
    }
    auto shape = static_cast<tvg::Shape*>(slot.paint);
    // The CPU engine derives the fill coverage (and its antialiasing, which depends on the
    // stroke width and stroke alpha) only when the path is marked dirty. Changes to those
    // inputs therefore re-append the path so the result matches a freshly generated shape.
    auto rebuild = (slot.fill.a == 0) != (style.fill.a == 0)
                   || (stroked && (slot.stroke.a != style.stroke.a || !_same(slot.width, style.width)));
    if (command.type == CommandType::Path) {
        auto same = slot.count == command.count && slot.closed == command.closed
                    && (!command.count
                        || std::memcmp(slot.points, command.points, sizeof(Vec2) * command.count) == 0);
        if (!same || rebuild) {
            if (!_success(shape->reset()) || !_geometry(shape, command) || !_storePoints(slot, command)) {
                return false;
            }
        }
    } else if (rebuild || !_same(slot.center, command.center) || !_same(slot.radius, command.radius)) {
        if (!_success(shape->reset()) || !_geometry(shape, command)) return false;
        slot.center = command.center;
        slot.radius = command.radius;
    }

    if (stroked) {
        if (!_same(slot.width, style.width)) {
            if (!_success(shape->strokeWidth(style.width))) return false;
            slot.width = style.width;
        }
        if (slot.cap != command.cap) {
            if (!_success(shape->strokeCap(command.cap == PathCap::Butt ? tvg::StrokeCap::Butt
                                                                         : tvg::StrokeCap::Round))) {
                return false;
            }
            slot.cap = command.cap;
        }
        if (dashed && (slot.dashCount != style.dashCount || !_same(slot.dash, style.dash)
                       || !_same(slot.dashOffset, style.dashOffset))) {
            if (!_success(shape->strokeDash(style.dash, style.dashCount, style.dashOffset))) return false;
            std::memcpy(slot.dash, style.dash, sizeof(slot.dash));
            slot.dashCount = style.dashCount;
            slot.dashOffset = style.dashOffset;
        }
        if (strokeGradient) {
            FillSpec spec;
            _spec(command, style.stroke, spec);
            if (!(spec == slot.strokeSpec)) {
                auto gradient = _gradient(spec);
                if (!gradient) return false;
                if (!_success(shape->strokeFill(gradient))) {
                    delete gradient;
                    return false;
                }
                slot.strokeSpec = spec;
            }
        } else if (!_sameColor(slot.stroke, style.stroke)) {
            if (!_success(shape->strokeFill(style.stroke.r, style.stroke.g, style.stroke.b, style.stroke.a))) {
                return false;
            }
        }
        slot.stroke = style.stroke;
    }

    if (fillGradient) {
        FillSpec spec;
        _spec(command, style.fill, spec);
        if (!(spec == slot.fillSpec)) {
            auto gradient = _gradient(spec);
            if (!gradient) return false;
            if (!_success(shape->fill(gradient))) {
                delete gradient;
                return false;
            }
            slot.fillSpec = spec;
        }
    } else if (!_sameColor(slot.fill, style.fill)) {
        if (!_success(shape->fill(style.fill.r, style.fill.g, style.fill.b, style.fill.a))) return false;
    }
    slot.fill = style.fill;
    return true;
}

static bool _updateText(Slot& slot, const DrawCommand& command, bool& replace)
{
    char value[64];
    auto text = command.text;
    auto font = command.font;
    if (command.type == CommandType::Number) {
        if (!_numberText(command, value)) return false;
        text = value;
        font = nullptr;
    }
    if (slot.transformed != command.transformed || !_sameText(slot.font, font)) {
        replace = true;
        return false;
    }
    auto paint = static_cast<tvg::Text*>(slot.paint);
    auto& fill = command.style.fill;
    // ThorVG lays glyphs out lazily and only text() reliably invalidates that layout (align()
    // and size() alone do not re-run it), so any layout input change resets the string too.
    auto relayout = false;
    if (!_same(slot.size, command.size)) {
        if (!_success(paint->size(command.size))) return false;
        slot.size = command.size;
        relayout = true;
    }
    if (!_same(slot.align, command.align)) {
        if (!_success(paint->align(command.align.x, command.align.y))) return false;
        slot.align = command.align;
        relayout = true;
    }
    if (relayout || !_sameText(slot.text, text)) {
        if (!_success(paint->text(text)) || !_storeText(slot.text, text)) return false;
    }
    if (slot.fill.r != fill.r || slot.fill.g != fill.g || slot.fill.b != fill.b) {
        if (!_success(paint->fill(fill.r, fill.g, fill.b))) return false;
    }
    if (slot.fill.a != fill.a && !_success(paint->opacity(fill.a))) return false;
    slot.fill = fill;
    if (command.transformed) {
        auto matrix = _textMatrix(command);
        if (!_same(slot.matrix, matrix)) {
            if (!_success(paint->transform(matrix))) return false;
            slot.matrix = matrix;
        }
    } else if (!_same(slot.center, command.center)) {
        if (!_success(paint->translate(command.center.x, command.center.y))) return false;
        slot.center = command.center;
    }
    return true;
}

static bool _updatePicture(Slot& slot, const DrawCommand& command, bool& replace)
{
    auto& source = command.picture;
    auto& last = slot.source;
    if (source.encoded != last.encoded || source.encodedSize != last.encodedSize
        || source.mime != last.mime || source.pixels != last.pixels
        || source.width != last.width || source.height != last.height) {
        replace = true;
        return false;
    }
    auto picture = static_cast<tvg::Picture*>(slot.paint);
    if (slot.filter != command.filter) {
        if (!_success(picture->filter(command.filter == ImageFilter::Nearest ? tvg::FilterMethod::Nearest
                                                                              : tvg::FilterMethod::Bilinear))) {
            return false;
        }
        slot.filter = command.filter;
    }
    auto matrix = _pictureMatrix(command);
    if (!_same(slot.matrix, matrix)) {
        if (!_success(picture->transform(matrix))) return false;
        slot.matrix = matrix;
    }
    if (slot.opacity != command.opacity) {
        if (!_success(picture->opacity(command.opacity))) return false;
        slot.opacity = command.opacity;
    }
    return true;
}

static bool _update(Slot& slot, const DrawCommand& command, bool& replace)
{
    replace = false;
    switch (command.type) {
        case CommandType::Path:
        case CommandType::Circle: return _updateShape(slot, command, replace);
        case CommandType::Text:
        case CommandType::Number: return _updateText(slot, command, replace);
        case CommandType::Picture: return _updatePicture(slot, command, replace);
    }
    return false;
}

struct RetainedNode;

// A child scene mounted into a parent node: wrapper(clip) -> child root(transform).
struct RetainedMount
{
    const Scene* first = nullptr;
    const Scene* second = nullptr;
    uint64_t firstSerial = 0;
    uint64_t secondSerial = 0;
    uint8_t kind = 0;
    tvg::Scene* wrapper = nullptr;  // holds one reference owned by the mount
    tvg::Shape* clipper = nullptr;  // owned by wrapper
    RetainedNode* child = nullptr;
    tvg::Matrix matrix = {};
    float rect[4] = {};
    uint8_t opacity = 255;
    bool placed = false;
};

struct RankEntry
{
    const Object* object;
    const Object* counterpart;
    uint32_t count;
};

// The retained tvg::Scene of one DisplayList: [background, command paints..., mounts...].
struct RetainedNode
{
    tvg::Scene* scene = nullptr;
    tvg::Shape* background = nullptr;
    float backgroundSize[2] = {-1.0f, -1.0f};
    Color backgroundColor = {0, 0, 0, 0};
    bool backgroundFilled = false;

    Slot** slots = nullptr;
    uint32_t slotCnt = 0;
    uint32_t slotCap = 0;
    Slot** table = nullptr;
    uint32_t tableCap = 0;

    RetainedMount** mounts = nullptr;
    uint32_t mountCnt = 0;
    uint32_t mountCap = 0;
    uint32_t mountUsed = 0;

    tvg::Paint** attached = nullptr;  // mirror of scene->paints()
    uint32_t attachedCnt = 0;
    uint32_t attachedCap = 0;
    tvg::Paint** desired = nullptr;
    uint32_t desiredCnt = 0;
    uint32_t desiredCap = 0;
    tvg::Paint** dead = nullptr;  // paints to detach and release this frame
    uint32_t deadCnt = 0;
    uint32_t deadCap = 0;
    RetainedMount** deadMounts = nullptr;
    uint32_t deadMountCnt = 0;
    uint32_t deadMountCap = 0;

    RankEntry* ranks = nullptr;
    uint32_t rankCap = 0;
    uint32_t* orderIndex = nullptr;
    uint32_t orderCap = 0;
    uint32_t* rankOf = nullptr;
    uint32_t rankOfCap = 0;

    ~RetainedNode();
};

static void _mountFree(RetainedMount* mount);

RetainedNode::~RetainedNode()
{
    if (scene) scene->remove();
    for (auto i = 0u; i < slotCnt; i++) {
        if (slots[i]->paint) slots[i]->paint->unref();
        delete slots[i];
    }
    if (background) background->unref();
    for (auto i = 0u; i < mountCnt; i++)
        _mountFree(mounts[i]);
    if (scene) scene->unref();
    delete[] slots;
    delete[] table;
    delete[] mounts;
    delete[] attached;
    delete[] desired;
    delete[] dead;
    delete[] deadMounts;
    delete[] ranks;
    delete[] orderIndex;
    delete[] rankOf;
}

// The mount's wrapper must already be detached from its parent scene.
static void _mountFree(RetainedMount* mount)
{
    if (!mount) return;
    if (mount->wrapper) mount->wrapper->unref();
    delete mount->child;
    delete mount;
}

static RetainedNode* _nodeGen()
{
    auto node = new (std::nothrow) RetainedNode;
    if (!node) return nullptr;
    node->scene = tvg::Scene::gen();
    node->background = tvg::Shape::gen();
    if (node->scene) node->scene->ref();
    if (node->background) node->background->ref();
    if (!node->scene || !node->background) {
        delete node;
        return nullptr;
    }
    return node;
}

static bool _push(tvg::Paint**& values, uint32_t& count, uint32_t& capacity, tvg::Paint* paint)
{
    if (!_reserve(values, capacity, count + 1u)) return false;
    values[count++] = paint;
    return true;
}

static bool _buildTable(RetainedNode* node)
{
    auto required = 16u;
    while (required < node->slotCnt * 2u) required *= 2u;
    if (required != node->tableCap) {
        auto table = new (std::nothrow) Slot*[required];
        if (!table) return false;
        delete[] node->table;
        node->table = table;
        node->tableCap = required;
    }
    for (auto i = 0u; i < node->tableCap; i++)
        node->table[i] = nullptr;
    auto mask = node->tableCap - 1u;
    for (auto i = 0u; i < node->slotCnt; i++) {
        auto slot = node->slots[i];
        auto index = slot->key.hash() & mask;
        while (node->table[index]) index = (index + 1u) & mask;
        node->table[index] = slot;
    }
    return true;
}

static Slot* _find(RetainedNode* node, const SlotKey& key)
{
    auto mask = node->tableCap - 1u;
    auto index = key.hash() & mask;
    while (auto slot = node->table[index]) {
        if (slot->key == key) return slot;
        index = (index + 1u) & mask;
    }
    return nullptr;
}

// rankOf[i] = number of commands the same (object, counterpart) emitted before command i.
static bool _ranks(RetainedNode* node, const DisplayList& list)
{
    auto count = list.count;
    if (!count) return true;
    if (!_reserve(node->orderIndex, node->orderCap, count) || !_reserve(node->rankOf, node->rankOfCap, count)) {
        return false;
    }
    auto required = 16u;
    while (required < count * 2u) required *= 2u;
    if (required > node->rankCap) {
        auto ranks = new (std::nothrow) RankEntry[required];
        if (!ranks) return false;
        delete[] node->ranks;
        node->ranks = ranks;
        node->rankCap = required;
    }
    auto mask = required - 1u;
    for (auto i = 0u; i < required; i++)
        node->ranks[i] = {nullptr, nullptr, 0u};

    // Emission order: commands carry their append index in `order`.
    auto valid = true;
    for (auto i = 0u; i < count; i++)
        node->orderIndex[i] = UINT32_MAX;
    for (auto i = 0u; i < count && valid; i++) {
        auto order = list.commands[i].order;
        if (order >= count || node->orderIndex[order] != UINT32_MAX) valid = false;
        else node->orderIndex[order] = i;
    }
    if (!valid) {
        for (auto i = 0u; i < count; i++)
            node->orderIndex[i] = i;
    }
    for (auto j = 0u; j < count; j++) {
        auto i = node->orderIndex[j];
        auto& command = list.commands[i];
        auto index = _hash(command.object, command.counterpart, 0u) & mask;
        while (true) {
            auto& entry = node->ranks[index];
            if (entry.count && entry.object == command.object && entry.counterpart == command.counterpart) {
                node->rankOf[i] = entry.count++;
                break;
            }
            if (!entry.count) {
                entry = {command.object, command.counterpart, 1u};
                node->rankOf[i] = 0u;
                break;
            }
            index = (index + 1u) & mask;
        }
    }
    return true;
}

static void _begin(RetainedNode* node)
{
    node->desiredCnt = 0;
    node->deadCnt = 0;
    node->deadMountCnt = 0;
    node->mountUsed = 0;
    for (auto i = 0u; i < node->slotCnt; i++)
        node->slots[i]->used = false;
}

static Result _local(RetainedNode* node, const Config& config, const DisplayList& list)
{
    auto background = node->background;
    auto width = static_cast<float>(config.width);
    auto height = static_cast<float>(config.height);
    if (!_same(node->backgroundSize[0], width) || !_same(node->backgroundSize[1], height)) {
        if (!_success(background->reset()) || !_success(background->appendRect(0.0f, 0.0f, width, height))) {
            return Result::Unknown;
        }
        node->backgroundSize[0] = width;
        node->backgroundSize[1] = height;
    }
    auto& color = config.background;
    if (!node->backgroundFilled || !_sameColor(node->backgroundColor, color)) {
        if (!_success(background->fill(color.r, color.g, color.b, color.a))) return Result::Unknown;
        node->backgroundColor = color;
        node->backgroundFilled = true;
    }
    if (!_push(node->desired, node->desiredCnt, node->desiredCap, background)) return Result::OutOfMemory;

    if (!_buildTable(node) || !_ranks(node, list)) return Result::OutOfMemory;
    for (auto i = 0u; i < list.count; i++) {
        auto& command = list.commands[i];
        SlotKey key = {command.object, command.counterpart, node->rankOf[i], command.type};
        auto slot = _find(node, key);
        if (slot && slot->used) slot = nullptr;
        if (slot) {
            auto replace = false;
            if (!_update(*slot, command, replace)) {
                if (!replace) return Result::Unknown;
                auto paint = _paint(command);
                if (!paint) return Result::NonSupport;
                paint->ref();
                if (!_push(node->dead, node->deadCnt, node->deadCap, slot->paint)) {
                    paint->unref();
                    return Result::OutOfMemory;
                }
                slot->paint = paint;
                if (!_capture(*slot, command)) return Result::OutOfMemory;
            }
        } else {
            if (!_reserve(node->slots, node->slotCap, node->slotCnt + 1u)) return Result::OutOfMemory;
            slot = new (std::nothrow) Slot;
            if (!slot) return Result::OutOfMemory;
            slot->key = key;
            slot->paint = _paint(command);
            if (!slot->paint) {
                delete slot;
                return Result::NonSupport;
            }
            slot->paint->ref();
            node->slots[node->slotCnt++] = slot;
            if (!_capture(*slot, command)) return Result::OutOfMemory;
        }
        slot->used = true;
        if (!_push(node->desired, node->desiredCnt, node->desiredCap, slot->paint)) return Result::OutOfMemory;
    }
    return Result::Success;
}

static RetainedMount* _mount(RetainedNode* node, uint8_t kind, const Scene* first, uint64_t firstSerial,
                             const Scene* second, uint64_t secondSerial)
{
    auto index = node->mountUsed;
    if (index < node->mountCnt) {
        auto mount = node->mounts[index];
        if (mount->kind == kind && mount->first == first && mount->second == second
            && mount->firstSerial == firstSerial && mount->secondSerial == secondSerial) {
            node->mountUsed++;
            return mount;
        }
        // A different scene now occupies this mount: release the old subtree.
        if (!_reserve(node->deadMounts, node->deadMountCap, node->deadMountCnt + 1u)) return nullptr;
        if (mount->wrapper && !_push(node->dead, node->deadCnt, node->deadCap, mount->wrapper)) return nullptr;
        node->deadMounts[node->deadMountCnt++] = mount;
        node->mounts[index] = nullptr;
    } else {
        if (!_reserve(node->mounts, node->mountCap, node->mountCnt + 1u)) return nullptr;
        node->mounts[node->mountCnt++] = nullptr;
    }
    auto mount = new (std::nothrow) RetainedMount;
    if (!mount) return nullptr;
    mount->kind = kind;
    mount->first = first;
    mount->second = second;
    mount->firstSerial = firstSerial;
    mount->secondSerial = secondSerial;
    mount->child = _nodeGen();
    if (!mount->child) {
        delete mount;
        return nullptr;
    }
    node->mounts[index] = mount;
    node->mountUsed++;
    return mount;
}

static Result _place(RetainedNode* node, RetainedMount* mount, const Config& childConfig,
                     const Config& config, const Viewport& viewport, uint8_t opacity)
{
    auto x = viewport.x * static_cast<float>(config.width);
    auto y = viewport.y * static_cast<float>(config.height);
    auto width = viewport.width * static_cast<float>(config.width);
    auto height = viewport.height * static_cast<float>(config.height);
    tvg::Matrix matrix = {
        width / static_cast<float>(childConfig.width), 0.0f, x,
        0.0f, height / static_cast<float>(childConfig.height), y,
        0.0f, 0.0f, 1.0f};
    float rect[4] = {x, y, width, height};
    auto child = mount->child->scene;
    if (!mount->placed || !_same(mount->matrix, matrix)) {
        if (!_success(child->transform(matrix))) return Result::Unknown;
        mount->matrix = matrix;
    }
    if (!mount->wrapper) {
        auto wrapper = tvg::Scene::gen();
        auto clipper = tvg::Shape::gen();
        if (!wrapper || !clipper) {
            if (wrapper) _release(wrapper);
            if (clipper) _release(clipper);
            return Result::OutOfMemory;
        }
        wrapper->ref();
        mount->wrapper = wrapper;
        if (!_success(wrapper->add(child))) {
            _release(clipper);
            return Result::Unknown;
        }
        if (!_success(clipper->appendRect(x, y, width, height)) || !_success(wrapper->clip(clipper))) {
            if (!clipper->parent() && wrapper->clip() != clipper) _release(clipper);
            return Result::Unknown;
        }
        mount->clipper = clipper;
        std::memcpy(mount->rect, rect, sizeof(rect));
    } else if (!_same(mount->rect, rect)) {
        if (!_success(mount->clipper->reset())
            || !_success(mount->clipper->appendRect(x, y, width, height))) {
            return Result::Unknown;
        }
        std::memcpy(mount->rect, rect, sizeof(rect));
    }
    if (!mount->placed || mount->opacity != opacity) {
        if (!_success(mount->wrapper->opacity(opacity))) return Result::Unknown;
        mount->opacity = opacity;
    }
    mount->placed = true;
    return _push(node->desired, node->desiredCnt, node->desiredCap, mount->wrapper) ? Result::Success
                                                                                   : Result::OutOfMemory;
}

static bool _contains(tvg::Paint* const* sorted, uint32_t count, tvg::Paint* paint)
{
    auto low = 0u;
    auto high = count;
    while (low < high) {
        auto mid = (low + high) / 2u;
        if (sorted[mid] == paint) return true;
        if (reinterpret_cast<uintptr_t>(sorted[mid]) < reinterpret_cast<uintptr_t>(paint)) low = mid + 1u;
        else high = mid;
    }
    return false;
}

static void _sortPaints(tvg::Paint** values, uint32_t count)
{
    // Insertion sort is enough: dead lists are short and usually empty.
    for (auto i = 1u; i < count; i++) {
        auto value = values[i];
        auto j = i;
        while (j > 0u && reinterpret_cast<uintptr_t>(values[j - 1u]) > reinterpret_cast<uintptr_t>(value)) {
            values[j] = values[j - 1u];
            j--;
        }
        values[j] = value;
    }
}

// Reorders the retained scene children to match the desired z-order with minimal edits.
static Result _reconcile(RetainedNode* node)
{
    auto scene = node->scene;
    auto& count = node->attachedCnt;
    auto attached = node->attached;
    auto desired = node->desired;
    auto total = node->desiredCnt;
    if (count == total) {
        auto same = true;
        for (auto i = 0u; i < total && same; i++)
            same = attached[i] == desired[i];
        if (same) return Result::Success;
    }
    auto prefix = 0u;
    while (prefix < count && prefix < total && attached[prefix] == desired[prefix]) prefix++;
    auto suffix = 0u;
    while (suffix < count - prefix && suffix < total - prefix
           && attached[count - 1u - suffix] == desired[total - 1u - suffix]) {
        suffix++;
    }
    if (!_reserve(node->attached, node->attachedCap, total)) return Result::OutOfMemory;
    attached = node->attached;

    if (total - prefix - suffix > 64u) {
        // Heavy reorder (e.g. depth sorting): detach the children (they stay alive, held by
        // their slots) and attach them again in order, all in linear time.
        if (!_success(scene->remove())) return Result::Unknown;
        count = 0;
        for (auto i = 0u; i < total; i++) {
            if (!_success(scene->add(desired[i]))) return Result::Unknown;
            attached[count++] = desired[i];
        }
        return Result::Success;
    }
    for (auto k = prefix; k < total; k++) {
        auto paint = desired[k];
        if (k < count && attached[k] == paint) continue;
        for (auto j = k + 1u; j < count; j++) {
            if (attached[j] != paint) continue;
            if (!_success(scene->remove(paint))) return Result::Unknown;
            for (auto m = j; m + 1u < count; m++)
                attached[m] = attached[m + 1u];
            count--;
            break;
        }
        auto at = k < count ? attached[k] : nullptr;
        if (!_success(scene->add(paint, at))) return Result::Unknown;
        for (auto m = count; m > k; m--)
            attached[m] = attached[m - 1u];
        attached[k] = paint;
        count++;
    }
    return Result::Success;
}

static Result _end(RetainedNode* node)
{
    // Slots that no command claimed this frame.
    auto kept = 0u;
    for (auto i = 0u; i < node->slotCnt; i++) {
        auto slot = node->slots[i];
        if (slot->used) {
            node->slots[kept++] = slot;
            continue;
        }
        if (!_push(node->dead, node->deadCnt, node->deadCap, slot->paint)) return Result::OutOfMemory;
        slot->paint = nullptr;
        delete slot;
    }
    node->slotCnt = kept;
    // Mounts no longer present (e.g. a sequence before it begins).
    for (auto i = node->mountUsed; i < node->mountCnt; i++) {
        auto mount = node->mounts[i];
        if (!_reserve(node->deadMounts, node->deadMountCap, node->deadMountCnt + 1u)) return Result::OutOfMemory;
        if (mount->wrapper && !_push(node->dead, node->deadCnt, node->deadCap, mount->wrapper)) {
            return Result::OutOfMemory;
        }
        node->deadMounts[node->deadMountCnt++] = mount;
    }
    node->mountCnt = node->mountUsed;

    if (node->deadCnt) {
        _sortPaints(node->dead, node->deadCnt);
        auto remain = 0u;
        for (auto i = 0u; i < node->attachedCnt; i++) {
            auto paint = node->attached[i];
            if (_contains(node->dead, node->deadCnt, paint)) {
                node->scene->remove(paint);
            } else {
                node->attached[remain++] = paint;
            }
        }
        node->attachedCnt = remain;
    }
    // Release detached paints first: a dead wrapper must drop its child root before the
    // child node releases that root.
    for (auto i = 0u; i < node->deadCnt; i++)
        node->dead[i]->unref();
    for (auto i = 0u; i < node->deadMountCnt; i++) {
        auto mount = node->deadMounts[i];
        mount->wrapper = nullptr;
        _mountFree(mount);
    }
    node->deadCnt = 0;
    node->deadMountCnt = 0;
    return _reconcile(node);
}

struct RendererBuilder
{
    static uint64_t serial(const Scene* scene)
    {
        return scene->pImpl->serial;
    }

    static Result scene(RetainedNode* node, const Scene* scene, float time, uint32_t& commands)
    {
        DisplayList list;
        auto result = scene->pImpl->build(time, list);
        if (result != Result::Success) return result;
        if (list.count > DISPLAY_COMMAND_LIMIT - commands) return Result::InsufficientCondition;
        commands += list.count;
        auto& config = scene->pImpl->cfg;
        _begin(node);
        result = _local(node, config, list);
        if (result == Result::Success) result = viewports(node, scene, time, config, 255u, commands);
        if (result == Result::Success) result = sequence(node, scene, time, config, commands);
        if (result == Result::Success) result = _end(node);
        return result;
    }

    static Result viewports(RetainedNode* node, const Scene* scene, float time,
                            const Config& config, uint8_t opacity, uint32_t& commands)
    {
        for (auto i = 0u; i < scene->pImpl->viewportCnt; i++) {
            auto& entry = scene->pImpl->viewports[i];
            auto mount = _mount(node, 1u, entry.scene, entry.scene->pImpl->serial, nullptr, 0u);
            if (!mount) return Result::OutOfMemory;
            auto result = RendererBuilder::scene(mount->child, entry.scene, time, commands);
            if (result != Result::Success) return result;
            result = _place(node, mount, entry.scene->pImpl->cfg, config, entry.viewport, opacity);
            if (result != Result::Success) return result;
        }
        return Result::Success;
    }

    static Result transition(RetainedNode* node, const Scene* from, const Scene* to,
                             const SceneTransition& transition, float progress,
                             Config& config, uint32_t& commands)
    {
        DisplayList first;
        DisplayList second;
        DisplayList blended;
        auto fromTime = from->duration();
        auto toTime = to->duration();
        auto result = from->pImpl->build(fromTime, first, false);
        if (result != Result::Success) return result;
        result = to->pImpl->build(toTime, second, false);
        if (result != Result::Success) return result;
        auto& fromConfig = from->pImpl->cfg;
        auto& toConfig = to->pImpl->cfg;
        result = blended.blend(first, second, transition.matches,
                               from->pImpl->objectCnt, to->pImpl->objectCnt,
                               {static_cast<float>(fromConfig.width), static_cast<float>(fromConfig.height)},
                               {static_cast<float>(toConfig.width), static_cast<float>(toConfig.height)},
                               progress);
        if (result != Result::Success) return result;
        if (blended.count > DISPLAY_COMMAND_LIMIT - commands) return Result::InsufficientCondition;
        commands += blended.count;
        config = fromConfig;
        auto bounded = progress;
        if (bounded < 0.0f) bounded = 0.0f;
        if (bounded > 1.0f) bounded = 1.0f;
        config.background = _mix(fromConfig.background, toConfig.background, bounded);
        _begin(node);
        result = _local(node, config, blended);
        if (result != Result::Success) return result;
        auto fromOpacity = static_cast<uint8_t>((1.0f - bounded) * 255.0f + 0.5f);
        auto toOpacity = static_cast<uint8_t>(bounded * 255.0f + 0.5f);
        result = viewports(node, from, fromTime, config, fromOpacity, commands);
        if (result == Result::Success) result = viewports(node, to, toTime, config, toOpacity, commands);
        if (result == Result::Success) result = sequence(node, from, fromTime, config, commands, fromOpacity);
        if (result == Result::Success) result = sequence(node, to, toTime, config, commands, toOpacity);
        if (result == Result::Success) result = _end(node);
        return result;
    }

    static Result sequence(RetainedNode* node, const Scene* scene, float time,
                           const Config& config, uint32_t& commands, uint8_t opacity = 255u)
    {
        auto sequence = scene->pImpl->sequence;
        if (!sequence || time < sequence->begin) return Result::Success;
        const Scene* stageScene = nullptr;
        const Scene* nextScene = nullptr;
        const SceneTransition* clip = nullptr;
        auto progress = 0.0f;
        for (auto i = 0u; i < sequence->count; i++) {
            auto& stage = sequence->stages[i];
            if (time < stage.end || i + 1u >= sequence->count) {
                stageScene = stage.scene;
                break;
            }
            auto& transition = sequence->transitions[i];
            if (time >= transition.end) continue;
            progress = (time - transition.begin) / (transition.end - transition.begin);
            if (progress <= 0.0f) {
                stageScene = stage.scene;
            } else {
                stageScene = stage.scene;
                nextScene = sequence->stages[i + 1u].scene;
                clip = &transition;
            }
            break;
        }
        if (!stageScene) return Result::Unknown;
        Config childConfig;
        RetainedMount* mount = nullptr;
        auto result = Result::Success;
        if (clip) {
            mount = _mount(node, 3u, stageScene, stageScene->pImpl->serial, nextScene,
                           nextScene->pImpl->serial);
            if (!mount) return Result::OutOfMemory;
            result = transition(mount->child, stageScene, nextScene, *clip,
                                ease(clip->curve, progress), childConfig, commands);
        } else {
            mount = _mount(node, 2u, stageScene, stageScene->pImpl->serial, nullptr, 0u);
            if (!mount) return Result::OutOfMemory;
            childConfig = stageScene->pImpl->cfg;
            result = RendererBuilder::scene(mount->child, stageScene, stageScene->duration(), commands);
        }
        if (result != Result::Success) return result;
        return _place(node, mount, childConfig, config, sequence->viewport, opacity);
    }
};

struct RetainedTree
{
    tvg::Canvas* canvas = nullptr;
    RetainedNode* root = nullptr;
    const Scene* scene = nullptr;
    uint64_t serial = 0;
    float scale = 1.0f;

    ~RetainedTree()
    {
        reset();
    }

    void reset()
    {
        if (root) {
            if (canvas) canvas->remove(root->scene);
            delete root;
            root = nullptr;
        }
        canvas = nullptr;
        scene = nullptr;
        serial = 0;
        scale = 1.0f;
    }

    Result sync(tvg::Canvas* target, const Scene* source, float time, float ratio)
    {
        // Paints belong to one canvas and reference the scene's objects and picture bytes:
        // a different canvas or scene starts a fresh tree.
        if (target != canvas || source != scene || RendererBuilder::serial(source) != serial) reset();
        if (!root) {
            root = _nodeGen();
            if (!root) return Result::OutOfMemory;
            if (!_success(target->add(root->scene))) {
                delete root;
                root = nullptr;
                return Result::Unknown;
            }
            canvas = target;
            scene = source;
            serial = RendererBuilder::serial(source);
        }
        if (!_same(scale, ratio)) {
            tvg::Matrix matrix = {
                ratio, 0.0f, 0.0f,
                0.0f, ratio, 0.0f,
                0.0f, 0.0f, 1.0f};
            if (!_success(root->scene->transform(matrix))) {
                reset();
                return Result::Unknown;
            }
            scale = ratio;
        }
        auto commands = 0u;
        auto result = RendererBuilder::scene(root, source, time, commands);
        // A partially updated tree is not trusted: rebuild it on the next frame.
        if (result != Result::Success) reset();
        return result;
    }
};

static bool _init()
{
    return _success(tvg::Initializer::init(0));
}

static void _term()
{
    tvg::Initializer::term();
}

namespace renderer
{

bool tvgSuccess(tvg::Result result) noexcept
{
    return _success(result);
}

void tvgRelease(tvg::Paint* paint) noexcept
{
    _release(paint);
}

bool tvgAdd(tvg::Scene* scene, tvg::Paint* paint) noexcept
{
    return _add(scene, paint);
}

tvg::Paint* tvgPaint(const DrawCommand& command) noexcept
{
    return _paint(command);
}

bool tvgVisible(const DrawCommand& command) noexcept
{
    return _visible(command);
}

RetainedTree* tvgRetainedGen() noexcept
{
    return new (std::nothrow) RetainedTree;
}

void tvgRetainedFree(RetainedTree* tree) noexcept
{
    delete tree;
}

void tvgRetainedReset(RetainedTree* tree) noexcept
{
    if (tree) tree->reset();
}

Result tvgRetainedSync(RetainedTree* tree, tvg::Canvas* canvas, const Scene* scene,
                       float time, float scale) noexcept
{
    if (!tree || !canvas) return Result::InvalidArguments;
    return tree->sync(canvas, scene, time, scale);
}

bool tvgInit() noexcept
{
    return _init();
}

void tvgTerm() noexcept
{
    _term();
}

}  // namespace renderer

}  // namespace tmath
