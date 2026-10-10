#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
#include <new>

#include "tmath.h"
#include "tmathDisplayList.h"
#include "tmathScene.h"

namespace tmath
{

static constexpr float PI2 = 6.28318530718f;
static constexpr uint32_t MAX_SPACE_NUMBERS = 256;

static float _clamp(float value)
{
    if (!std::isfinite(value)) return 0.0f;
    if (value < 0.0f) return 0.0f;
    if (value > 1.0f) return 1.0f;
    return value;
}

static bool _finite(const Vec2& value)
{
    return std::isfinite(value.x) && std::isfinite(value.y);
}

static bool _finite(const Mat4& value)
{
    for (auto item : value.e) {
        if (!std::isfinite(item)) return false;
    }
    return true;
}

static bool _finite(const Mat3& value)
{
    for (auto item : value.e) {
        if (!std::isfinite(item)) return false;
    }
    return true;
}

static bool _affine(const Mat4& value)
{
    return _finite(value) && value.e[12] == 0.0f && value.e[13] == 0.0f && value.e[14] == 0.0f && value.e[15] == 1.0f;
}

static Color _opacity(Color color, float opacity)
{
    auto alpha = static_cast<float>(color.a) * _clamp(opacity);
    color.a = static_cast<uint8_t>(alpha + 0.5f);
    return color;
}

static Color _shade(Color color, float factor, float opacity)
{
    factor = _clamp(factor);
    color.r = static_cast<uint8_t>(static_cast<float>(color.r) * factor + 0.5f);
    color.g = static_cast<uint8_t>(static_cast<float>(color.g) * factor + 0.5f);
    color.b = static_cast<uint8_t>(static_cast<float>(color.b) * factor + 0.5f);
    return _opacity(color, opacity);
}

static Style _style(const Object* object, const VisualState& state)
{
    auto style = object->style;
    style.stroke = _opacity(state.stroke, state.opacity);
    style.fill = _opacity(state.fill, state.opacity * state.fillProgress);
    style.gradientEnd = state.gradientEnd;
    style.gradient = state.gradient;
    style.width = state.width * state.pixelScale;
    style.radius = state.radius * state.pixelScale;
    for (auto i = 0u; i < style.dashCount; i++) style.dash[i] *= state.pixelScale;
    style.dashOffset = state.dashOffset * state.pixelScale;
    return style;
}

static Vec2 _pixel(const Vec3& ndc, const Config& config)
{
    return {
        (ndc.x + 1.0f) * 0.5f * static_cast<float>(config.width),
        (1.0f - ndc.y) * 0.5f * static_cast<float>(config.height)};
}

static bool _point(const Vec3& point, const Mat4& model, const Config& config, Vec2& pixel, float& depth)
{
    Vec3 ndc;
    auto aspect = static_cast<float>(config.width) / static_cast<float>(config.height);
    if (!config.camera.project(model * point, aspect, ndc)) return false;
    pixel = _pixel(ndc, config);
    depth = ndc.z;
    return true;
}

static bool _lineWorld(Vec3 from, Vec3 to, const Mat4& model, const Config& config, Vec2& a, Vec2& b, float& depth)
{
    from = model * from;
    to = model * to;
    if (!config.camera.segment(from, to)) return false;
    Vec3 fromNdc;
    Vec3 toNdc;
    auto aspect = static_cast<float>(config.width) / static_cast<float>(config.height);
    if (!config.camera.project(from, aspect, fromNdc)) return false;
    if (!config.camera.project(to, aspect, toNdc)) return false;
    a = _pixel(fromNdc, config);
    b = _pixel(toNdc, config);
    depth = (fromNdc.z + toNdc.z) * 0.5f;
    return true;
}

static float _pixelLength(const Vec3& point, float length, const Mat4& model,
                          const Config& config, const Vec2& pixel)
{
    if (length <= 0.0f) return 0.0f;
    Vec2 x;
    Vec2 y;
    float depth;
    if (!_point(point + Vec3{length, 0.0f, 0.0f}, model, config, x, depth)
        || !_point(point + Vec3{0.0f, length, 0.0f}, model, config, y, depth)) {
        return -1.0f;
    }
    return ((x - pixel).length() + (y - pixel).length()) * 0.5f;
}

// Moves explicit gradient geometry from local coordinates into output pixels with the
// same model/camera projection as the Shape points. Geometry that cannot be projected
// falls back to the renderer's automatic shape-derived placement.
static void _project(Gradient& gradient, const Mat4& model, const Config& config)
{
    if (!gradient.enabled()) return;
    float depth;
    if (gradient.line) {
        Vec2 a;
        Vec2 b;
        if (_point(gradient.from, model, config, a, depth)
            && _point(gradient.to, model, config, b, depth)) {
            gradient.from = {a.x, a.y, 0.0f};
            gradient.to = {b.x, b.y, 0.0f};
        } else {
            gradient.line = false;
        }
    }
    Vec2 center;
    auto anchor = gradient.centered ? gradient.center : Vec3{};
    auto anchored = _point(anchor, model, config, center, depth);
    if (gradient.type == GradientType::Conic && anchored) {
        constexpr auto RADIANS = 3.14159265358979f / 180.0f;
        auto angle = gradient.angle * RADIANS;
        Vec2 direction;
        // Clockwise as seen on screen: negate the local y component of the start direction.
        if (_point(anchor + Vec3{std::cos(angle), -std::sin(angle), 0.0f}, model, config,
                   direction, depth)) {
            auto delta = direction - center;
            gradient.angle = std::atan2(delta.y, delta.x) / RADIANS;
        }
    }
    if (gradient.type == GradientType::Radial) {
        if (gradient.sized) {
            auto radius = anchored ? _pixelLength(anchor, gradient.radius, model, config, center)
                                   : -1.0f;
            if (radius > 0.0f) gradient.radius = radius;
            else gradient.sized = false;
        }
        if (gradient.focused) {
            Vec2 focal;
            if (_point(gradient.focal, model, config, focal, depth)) {
                gradient.focal = {focal.x, focal.y, 0.0f};
            } else {
                gradient.focused = false;
            }
        }
        if (gradient.focalRadius > 0.0f) {
            auto radius = anchored
                              ? _pixelLength(anchor, gradient.focalRadius, model, config, center)
                              : -1.0f;
            gradient.focalRadius = radius > 0.0f ? radius : 0.0f;
        }
    }
    if (gradient.centered) {
        if (anchored) gradient.center = {center.x, center.y, 0.0f};
        else gradient.centered = false;
    }
}

static bool _reverse(DrawDirection direction, const Vec2* points = nullptr, uint32_t count = 0,
                     bool closed = false)
{
    if (direction == DrawDirection::Reverse) return true;
    if (direction == DrawDirection::Forward) return false;
    if (!closed || !points || count < 3u) return direction == DrawDirection::Clockwise;
    auto area = 0.0;
    for (auto i = 0u; i < count; i++) {
        auto& from = points[i];
        auto& to = points[(i + 1u) % count];
        area += static_cast<double>(from.x) * to.y - static_cast<double>(from.y) * to.x;
    }
    if (direction == DrawDirection::Clockwise) return area < 0.0;
    return area > 0.0;
}

static Result _line(DisplayList& list, const Vec2& from, const Vec2& to, float progress,
                    DrawDirection direction, const Style& style, int32_t layer,
                    float depth = 0.0f)
{
    auto value = _clamp(progress);
    if (value <= 0.0f) return Result::Success;
    auto reverse = _reverse(direction);
    auto start = reverse ? to : from;
    auto end = reverse ? from : to;
    Vec2 points[2] = {start, start + (end - start) * value};
    return list.path(points, 2, false, style, layer, depth);
}

static float _arrowHalfWidth(float length, const Style& style)
{
    return std::fmin(length * 0.55f,
                     std::fmax(length * 0.46f, style.width * 0.75f));
}

static Result _routeMarker(DisplayList& list, const Vec2& point, const Vec2& direction,
                           float length, bool start, const Style& style, int32_t layer,
                           float depth)
{
    if (length <= 0.0f) return Result::Success;
    auto normal = Vec2{-direction.y, direction.x};
    auto base = start ? point + direction * length : point - direction * length;
    auto half = _arrowHalfWidth(length, style);
    Vec2 points[] = {point, base + normal * half, base - normal * half};
    auto marker = style;
    marker.fill = style.stroke;
    marker.stroke.a = 0u;
    marker.width = 0.0f;
    marker.dashCount = 0u;
    marker.dashOffset = 0.0f;
    return list.path(points, 3u, true, marker, layer, depth);
}

static uint32_t _trimRoute(Vec2* points, uint32_t count, float start, float end)
{
    auto first = 0u;
    while (first + 1u < count && start > 1e-6f) {
        auto segment = points[first + 1u] - points[first];
        auto length = segment.length();
        if (length <= 1e-6f) {
            first++;
            continue;
        }
        if (start < length) {
            points[first] = points[first] + segment * (start / length);
            start = 0.0f;
            break;
        }
        start -= length;
        first++;
    }
    if (first) {
        count -= first;
        for (auto i = 0u; i < count; i++) points[i] = points[i + first];
    }

    while (count > 1u && end > 1e-6f) {
        auto segment = points[count - 1u] - points[count - 2u];
        auto length = segment.length();
        if (length <= 1e-6f) {
            count--;
            continue;
        }
        if (end < length) {
            points[count - 1u] = points[count - 1u] - segment * (end / length);
            end = 0.0f;
            break;
        }
        end -= length;
        count--;
    }
    return count;
}

static Result _route(DisplayList& list, const Vec2* points, uint32_t count, float progress,
                     DrawDirection drawDirection, float tail, float tip, const Style& style,
                     int32_t layer, float depth = 0.0f)
{
    if (!points || count < 2u) return Result::InvalidArguments;
    auto value = _clamp(progress);
    if (value <= 0.0f) return Result::Success;
    auto reverse = value < 1.0f - 1e-6f && _reverse(drawDirection, points, count, false);
    auto point = [&](uint32_t index) {
        return reverse ? points[count - 1u - index] : points[index];
    };
    auto total = 0.0f;
    for (auto i = 1u; i < count; i++) total += (point(i) - point(i - 1u)).length();
    if (!std::isfinite(total) || total <= 1e-6f) return Result::Success;

    auto remaining = total * value;
    auto output = new (std::nothrow) Vec2[count];
    if (!output) return Result::OutOfMemory;
    auto outputCount = 1u;
    output[0] = point(0u);
    for (auto i = 1u; i < count && remaining > 1e-6f; i++) {
        auto from = point(i - 1u);
        auto to = point(i);
        auto segment = to - from;
        auto length = segment.length();
        if (!std::isfinite(length)) {
            delete[] output;
            return Result::InvalidArguments;
        }
        if (length <= 1e-6f) continue;
        if (remaining >= length) {
            output[outputCount++] = to;
            remaining -= length;
        } else {
            output[outputCount++] = from + segment * (remaining / length);
            remaining = 0.0f;
        }
    }
    if (outputCount < 2u) {
        delete[] output;
        return Result::Success;
    }

    auto firstDelta = output[1u] - output[0u];
    auto firstLength = firstDelta.length();
    auto lastDelta = output[outputCount - 1u] - output[outputCount - 2u];
    auto lastLength = lastDelta.length();
    if (firstLength <= 1e-6f || lastLength <= 1e-6f) {
        delete[] output;
        return Result::Success;
    }
    auto firstDirection = firstDelta * (1.0f / firstLength);
    auto lastDirection = lastDelta * (1.0f / lastLength);
    auto visibleLength = total * value;
    auto startMarker = std::fmin(reverse ? tip : tail, visibleLength * 0.45f);
    auto endMarker = std::fmin(reverse ? tail : tip, visibleLength * 0.45f);

    auto startPoint = output[0u];
    auto endPoint = output[outputCount - 1u];
    auto shaftCount = _trimRoute(output, outputCount, startMarker, endMarker);

    auto shaft = style;
    shaft.fill.a = 0u;
    auto result = shaftCount >= 2u
                ? list.path(output, shaftCount, false, shaft, layer, depth, PathCap::Butt)
                : Result::Success;
    if (result == Result::Success) {
        result = _routeMarker(list, startPoint, firstDirection, startMarker, true, style,
                              layer, depth);
    }
    if (result == Result::Success) {
        result = _routeMarker(list, endPoint, lastDirection, endMarker,
                              false, style, layer, depth);
    }
    delete[] output;
    return result;
}

static Result _path(DisplayList& list, const Vec2* points, uint32_t count, bool closed,
                    float progress, DrawDirection direction, const Style& style,
                    int32_t layer, float depth = 0.0f, bool traceFill = false)
{
    if (!points || count < 2) return Result::InvalidArguments;
    auto value = _clamp(progress);
    if (value <= 0.0f) return Result::Success;
    auto segments = closed ? count : count - 1;
    auto scaled = value * static_cast<float>(segments);
    if (scaled <= 1e-6f) return Result::Success;
    auto complete = static_cast<uint32_t>(scaled);
    if (complete > segments) complete = segments;
    auto outputCnt = complete + 1;
    auto partial = scaled - static_cast<float>(complete);
    if (complete < segments && partial > 1e-6f) outputCnt++;
    if (outputCnt > count + 1) outputCnt = count + 1;

    auto output = new (std::nothrow) Vec2[outputCnt];
    if (!output) return Result::OutOfMemory;
    auto reverse = _reverse(direction, points, count, closed);
    auto point = [&](uint32_t index) {
        if (!reverse) return points[index % count];
        if (closed) return points[(count - index % count) % count];
        return points[count - 1u - index];
    };
    for (auto i = 0u; i <= complete && i < outputCnt; i++) output[i] = point(i);
    if (complete < segments && partial > 1e-6f) {
        auto from = point(complete);
        auto to = point(complete + 1u);
        output[outputCnt - 1] = from + (to - from) * partial;
    }
    auto finished = value >= 1.0f - 1e-6f;
    auto result = Result::Success;
    if (traceFill && closed && !finished && outputCnt >= 3u && style.fill.a) {
        auto fillStyle = style;
        fillStyle.stroke.a = 0;
        fillStyle.width = 0.0f;
        result = list.path(output, outputCnt, true, fillStyle, layer, depth);
    }
    if (result == Result::Success) {
        auto strokeStyle = style;
        if (!finished) {
            strokeStyle.fill.a = 0;
            if (traceFill && !strokeStyle.stroke.a && style.fill.a) {
                strokeStyle.stroke = style.fill;
                if (strokeStyle.width <= 0.0f) strokeStyle.width = 2.0f;
            }
        }
        result = list.path(output, outputCnt, closed && finished, strokeStyle, layer, depth);
    }
    delete[] output;
    return result;
}

static Result _gridLine(DisplayList& list, const Vec3& from, const Vec3& to, const VisualState& state, const Config& config, const Style& style, int32_t layer)
{
    Vec2 a;
    Vec2 b;
    float depth;
    if (!_lineWorld(from, to, state.model, config, a, b, depth)) return Result::Success;
    return _line(list, a, b, state.progress, state.direction, style, layer, depth);
}

static float _basisLength(const Mat4& model, uint8_t axis)
{
    auto x = static_cast<double>(model.e[axis]);
    auto y = static_cast<double>(model.e[axis + 4u]);
    auto z = static_cast<double>(model.e[axis + 8u]);
    auto length = std::hypot(x, y, z);
    if (!std::isfinite(length) || length > std::numeric_limits<float>::max()) return 0.0f;
    return static_cast<float>(length);
}

static Result _spaceNumbers(DisplayList& list, const Space* space, const VisualState& state,
                            const Config& config, int32_t layer)
{
    if (!space->numbers) return Result::Success;
    auto style = Style{};
    style.stroke.a = 0;
    style.fill = _opacity(space->numberColor, state.opacity * state.progress);
    auto numberSize = space->numberSize * state.pixelScale;
    if (numberSize <= 0.0f) return Result::Success;
    auto count = 0u;
    auto addAxis = [&](const Range& range, uint8_t axis, const Vec2& offset) {
        auto scale = space->numberMode == NumberMode::Relative ? _basisLength(state.model, axis) : 1.0f;
        if (scale <= 0.0f) return Result::Success;
        auto index = 0u;
        for (auto value = std::ceil(range.min / range.step) * range.step;
             value <= range.max + range.step * 0.001f && index++ < 4096 && count < MAX_SPACE_NUMBERS;
             value += range.step) {
            if (std::fabs(value) < range.step * 0.001f) continue;
            auto point = Vec3{};
            if (axis == 0u) point.x = value;
            else if (axis == 1u) point.y = value;
            else point.z = value;
            Vec2 pixel;
            float depth;
            if (!_point(point, state.model, config, pixel, depth)) continue;
            auto result = list.number(pixel + offset * state.pixelScale, value * scale, numberSize,
                                      {0.5f, 0.5f}, style, layer, depth);
            if (result != Result::Success) return result;
            count++;
        }
        return Result::Success;
    };
    auto result = addAxis(space->x, 0u, {0.0f, space->numberSize * 0.9f});
    if (result != Result::Success) return result;
    result = addAxis(space->y, 1u, {-space->numberSize * 0.9f, 0.0f});
    if (result != Result::Success || config.cameraView != CameraView::ThreeD) return result;
    return addAxis(space->z, 2u, {space->numberSize * 0.75f, -space->numberSize * 0.55f});
}

DisplayList::~DisplayList()
{
    for (auto i = 0u; i < count; i++)
        delete[] commands[i].points;
    delete[] commands;
}

DrawCommand* DisplayList::append() noexcept
{
    if (count >= DISPLAY_COMMAND_LIMIT) return nullptr;
    if (count < capacity) {
        commands[count] = {};
        commands[count].object = object;
        commands[count].counterpart = counterpart;
        commands[count].order = count;
        commands[count].visualKind = visualKind;
        commands[count].visualOpacity = visualOpacity;
        return commands + count++;
    }
    auto grownCapacity = capacity ? capacity * 2 : 32;
    auto grown = new (std::nothrow) DrawCommand[grownCapacity];
    if (!grown) return nullptr;
    for (auto i = 0u; i < count; i++)
        grown[i] = commands[i];
    delete[] commands;
    commands = grown;
    capacity = grownCapacity;
    commands[count].object = object;
    commands[count].counterpart = counterpart;
    commands[count].order = count;
    commands[count].visualKind = visualKind;
    commands[count].visualOpacity = visualOpacity;
    return commands + count++;
}

Result DisplayList::path(const Vec2* points, uint32_t count, bool closed, const Style& style,
                         int32_t layer, float depth, PathCap cap) noexcept
{
    if (!points || count < 2 || !std::isfinite(depth)) return Result::InvalidArguments;
    for (auto i = 0u; i < count; i++) {
        if (!_finite(points[i])) return Result::InvalidArguments;
    }
    auto command = append();
    if (!command) return Result::OutOfMemory;
    command->points = new (std::nothrow) Vec2[count];
    if (!command->points) {
        this->count--;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < count; i++)
        command->points[i] = points[i];
    command->type = CommandType::Path;
    command->count = count;
    command->style = style;
    command->layer = layer;
    command->depth = depth;
    command->closed = closed;
    command->cap = cap;
    return Result::Success;
}

Result DisplayList::circle(const Vec2& center, float radius, const Style& style, int32_t layer, float depth) noexcept
{
    if (!_finite(center) || !std::isfinite(radius) || radius <= 0.0f || !std::isfinite(depth)) return Result::InvalidArguments;
    auto command = append();
    if (!command) return Result::OutOfMemory;
    command->type = CommandType::Circle;
    command->center = center;
    command->radius = radius;
    command->style = style;
    command->layer = layer;
    command->depth = depth;
    return Result::Success;
}

Result DisplayList::text(const Vec2& point, const char* value, const char* font, float size,
                         const Vec2& align, const Style& style, int32_t layer, float depth,
                         const Mat3* transform) noexcept
{
    if (!_finite(point) || !value || !std::isfinite(size) || size <= 0.0f || !_finite(align)
        || !std::isfinite(depth) || (transform && !_finite(*transform))) {
        return Result::InvalidArguments;
    }
    auto command = append();
    if (!command) return Result::OutOfMemory;
    command->type = CommandType::Text;
    command->center = point;
    command->text = value;
    command->font = font;
    command->size = size;
    command->align = align;
    command->style = style;
    command->layer = layer;
    command->depth = depth;
    if (transform) {
        command->transform = *transform;
        command->transformed = true;
    }
    return Result::Success;
}

Result DisplayList::number(const Vec2& point, float value, float size, const Vec2& align,
                           const Style& style, int32_t layer, float depth) noexcept
{
    if (!_finite(point) || !std::isfinite(value) || !std::isfinite(size) || size <= 0.0f
        || !_finite(align) || !std::isfinite(depth)) {
        return Result::InvalidArguments;
    }
    auto command = append();
    if (!command) return Result::OutOfMemory;
    command->type = CommandType::Number;
    command->center = point;
    command->number = value;
    command->size = size;
    command->align = align;
    command->style = style;
    command->layer = layer;
    command->depth = depth;
    return Result::Success;
}

Result DisplayList::picture(const Vec2* corners, const PictureSource& source, ImageFilter filter,
                            uint8_t opacity, int32_t layer, float depth) noexcept
{
    auto encoded = source.encoded && source.encodedSize && source.mime;
    if (!corners || (!encoded && !source.pixels) || !source.width || !source.height || !std::isfinite(depth) || (filter != ImageFilter::Bilinear && filter != ImageFilter::Nearest)) {
        return Result::InvalidArguments;
    }
    for (auto i = 0u; i < 3u; i++) {
        if (!_finite(corners[i])) return Result::InvalidArguments;
    }
    auto command = append();
    if (!command) return Result::OutOfMemory;
    command->points = new (std::nothrow) Vec2[3];
    if (!command->points) {
        count--;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < 3u; i++)
        command->points[i] = corners[i];
    command->type = CommandType::Picture;
    command->count = 3;
    command->picture = source;
    command->filter = filter;
    command->opacity = opacity;
    command->layer = layer;
    command->depth = depth;
    return Result::Success;
}

struct CommandSpan
{
    uint32_t begin = UINT32_MAX;
    uint32_t count = 0;
};

static bool _same(const char* first, const char* second)
{
    if (first == second) return true;
    return first && second && std::strcmp(first, second) == 0;
}

static bool _same(const PictureSource& first, const PictureSource& second)
{
    if (first.width != second.width || first.height != second.height) return false;
    if (first.encoded || second.encoded) {
        return first.encoded && second.encoded && first.encodedSize == second.encodedSize
               && _same(first.mime, second.mime)
               && (first.encoded == second.encoded
                   || std::memcmp(first.encoded, second.encoded, first.encodedSize) == 0);
    }
    return first.pixels == second.pixels;
}

static float _mix(float from, float to, float progress)
{
    return static_cast<float>(static_cast<double>(from)
           + (static_cast<double>(to) - from) * progress);
}

static uint8_t _mix(uint8_t from, uint8_t to, float progress)
{
    return static_cast<uint8_t>(_mix(static_cast<float>(from), static_cast<float>(to),
                                     _clamp(progress)) + 0.5f);
}

static Color _mix(const Color& from, const Color& to, float progress)
{
    return {
        _mix(from.r, to.r, progress),
        _mix(from.g, to.g, progress),
        _mix(from.b, to.b, progress),
        _mix(from.a, to.a, progress)};
}

static float _scale(const Vec2& from, const Vec2& to)
{
    return (to.x / from.x + to.y / from.y) * 0.5f;
}

static Vec2 _scale(const Vec2& point, const Vec2& from, const Vec2& to)
{
    return {point.x * to.x / from.x, point.y * to.y / from.y};
}

static Mat3 _scale(const Mat3& matrix, const Vec2& from, const Vec2& to)
{
    auto output = matrix;
    auto x = to.x / from.x;
    auto y = to.y / from.y;
    output.e[0] *= x;
    output.e[1] *= x;
    output.e[2] *= x;
    output.e[3] *= y;
    output.e[4] *= y;
    output.e[5] *= y;
    return output;
}

static Mat3 _mix(const Mat3& from, const Mat3& to, float progress)
{
    auto output = Mat3{};
    for (auto i = 0u; i < 9u; i++) output.e[i] = _mix(from.e[i], to.e[i], progress);
    return output;
}

static Style _scale(const Style& style, const Vec2& from, const Vec2& to, float opacity)
{
    auto output = style;
    auto factor = _scale(from, to);
    output.stroke = _opacity(output.stroke, opacity);
    output.fill = _opacity(output.fill, opacity);
    output.width *= factor;
    output.radius *= factor;
    for (auto i = 0u; i < output.dashCount; i++) output.dash[i] *= factor;
    output.dashOffset *= factor;
    auto& gradient = output.gradient;
    auto point = [&](Vec3& value) {
        auto pixel = _scale(Vec2{value.x, value.y}, from, to);
        value = {pixel.x, pixel.y, 0.0f};
    };
    point(gradient.from);
    point(gradient.to);
    point(gradient.center);
    point(gradient.focal);
    gradient.radius *= factor;
    gradient.focalRadius *= factor;
    return output;
}

static Style _mix(const Style& from, const Style& to, float progress)
{
    auto bounded = _clamp(progress);
    auto output = bounded < 0.5f ? from : to;
    output.stroke = _mix(from.stroke, to.stroke, progress);
    output.fill = _mix(from.fill, to.fill, progress);
    output.gradientEnd = _mix(from.gradientEnd, to.gradientEnd, progress);
    output.width = _mix(from.width, to.width, bounded);
    output.radius = _mix(from.radius, to.radius, bounded);
    output.gradient = mix(from.gradient, to.gradient, bounded);
    if (from.dashCount == to.dashCount) {
        output.dashCount = from.dashCount;
        output.dashOffset = _mix(from.dashOffset, to.dashOffset, bounded);
        for (auto i = 0u; i < output.dashCount; i++) {
            output.dash[i] = _mix(from.dash[i], to.dash[i], bounded);
        }
    }
    return output;
}

static Result _copy(DisplayList& list, const DrawCommand& command, const Vec2& from,
                    const Vec2& to, float opacity, LayoutVisualKind kind,
                    const Object* counterpart)
{
    list.object = command.object;
    list.counterpart = counterpart;
    list.visualKind = kind;
    list.visualOpacity = static_cast<uint8_t>(_clamp(opacity) * 255.0f + 0.5f);
    auto style = _scale(command.style, from, to, opacity);
    auto layer = command.layer;
    auto depth = command.depth;
    switch (command.type) {
        case CommandType::Path: {
            auto points = new (std::nothrow) Vec2[command.count];
            if (!points) return Result::OutOfMemory;
            for (auto i = 0u; i < command.count; i++)
                points[i] = _scale(command.points[i], from, to);
            auto result = list.path(points, command.count, command.closed, style, layer, depth,
                                    command.cap);
            delete[] points;
            return result;
        }
        case CommandType::Circle:
            return list.circle(_scale(command.center, from, to),
                               command.radius * _scale(from, to), style, layer, depth);
        case CommandType::Text: {
            auto transform = _scale(command.transform, from, to);
            return list.text(_scale(command.center, from, to), command.text, command.font,
                             command.transformed ? command.size : command.size * _scale(from, to),
                             command.align, style, layer, depth,
                             command.transformed ? &transform : nullptr);
        }
        case CommandType::Number:
            return list.number(_scale(command.center, from, to), command.number,
                               command.size * _scale(from, to), command.align, style, layer, depth);
        case CommandType::Picture: {
            Vec2 corners[3];
            for (auto i = 0u; i < 3u; i++)
                corners[i] = _scale(command.points[i], from, to);
            return list.picture(corners, command.picture, command.filter, static_cast<uint8_t>(static_cast<float>(command.opacity)
                              * _clamp(opacity) + 0.5f), layer, depth);
        }
    }
    return Result::NonSupport;
}

static bool _compatible(const DrawCommand& from, const DrawCommand& to)
{
    if (from.type != to.type) return false;
    switch (from.type) {
        case CommandType::Path: return from.closed == to.closed;
        case CommandType::Text:
            return from.transformed == to.transformed && _same(from.text, to.text)
                   && _same(from.font, to.font);
        case CommandType::Picture: return _same(from.picture, to.picture);
        default: return true;
    }
}

static Vec2 _point(const DrawCommand& command, uint32_t index, const Vec2& from,
                   const Vec2& to)
{
    return _scale(command.points[index % command.count], from, to);
}

static bool _sample(const DrawCommand& command, const Vec2& from, const Vec2& to,
                    Vec2* output, uint32_t count)
{
    auto segments = command.closed ? command.count : command.count - 1u;
    auto total = 0.0;
    for (auto i = 0u; i < segments; i++) {
        auto a = _point(command, i, from, to);
        auto b = _point(command, i + 1u, from, to);
        total += static_cast<double>((b - a).length());
    }
    if (!std::isfinite(total)) return false;
    if (total <= 1.0e-7) {
        auto point = _point(command, 0u, from, to);
        for (auto i = 0u; i < count; i++) output[i] = point;
        return true;
    }
    auto segment = 0u;
    auto accumulated = 0.0;
    auto a = _point(command, 0u, from, to);
    auto b = _point(command, 1u, from, to);
    auto length = static_cast<double>((b - a).length());
    auto denominator = command.closed ? count : count - 1u;
    for (auto i = 0u; i < count; i++) {
        auto distance = total * static_cast<double>(i) / denominator;
        while (segment + 1u < segments && accumulated + length < distance) {
            accumulated += length;
            segment++;
            a = _point(command, segment, from, to);
            b = _point(command, segment + 1u, from, to);
            length = static_cast<double>((b - a).length());
        }
        auto progress = length > 1.0e-12 ? (distance - accumulated) / length : 0.0;
        output[i] = a + (b - a) * static_cast<float>(progress);
    }
    return true;
}

static uint32_t _target(uint32_t index, uint32_t offset, bool reverse, uint32_t count)
{
    return reverse ? (offset + count - index) % count : (offset + index) % count;
}

static void _align(const Vec2* from, const Vec2* to, uint32_t count,
                   uint32_t& offset, bool& reverse)
{
    auto best = std::numeric_limits<double>::infinity();
    offset = 0u;
    reverse = false;
    for (auto direction = 0u; direction < 2u; direction++) {
        for (auto candidate = 0u; candidate < count; candidate++) {
            auto distance = 0.0;
            for (auto i = 0u; i < count; i++) {
                auto delta = to[_target(i, candidate, direction != 0u, count)] - from[i];
                distance += static_cast<double>(delta.dot(delta));
            }
            if (distance >= best) continue;
            best = distance;
            offset = candidate;
            reverse = direction != 0u;
        }
    }
}

static Result _blendPath(DisplayList& list, const DrawCommand& from,
                         const DrawCommand& to, const Vec2& fromSize,
                         const Vec2& toSize, float progress)
{
    constexpr auto count = 64u;
    Vec2 first[count];
    Vec2 second[count];
    Vec2 points[count];
    if (!_sample(from, fromSize, fromSize, first, count)
        || !_sample(to, toSize, fromSize, second, count)) {
        return Result::NonSupport;
    }
    auto offset = 0u;
    auto reverse = false;
    if (from.closed) _align(first, second, count, offset, reverse);
    for (auto i = 0u; i < count; i++) {
        auto target = from.closed ? _target(i, offset, reverse, count) : i;
        points[i] = first[i] + (second[target] - first[i]) * progress;
    }
    auto firstStyle = _scale(from.style, fromSize, fromSize, 1.0f);
    auto secondStyle = _scale(to.style, toSize, fromSize, 1.0f);
    auto style = _mix(firstStyle, secondStyle, progress);
    auto layer = _clamp(progress) < 0.5f ? from.layer : to.layer;
    auto cap = _clamp(progress) < 0.5f ? from.cap : to.cap;
    return list.path(points, count, from.closed, style, layer,
                     _mix(from.depth, to.depth, progress), cap);
}

static Result _blend(DisplayList& list, const DrawCommand& from, const DrawCommand& to,
                     const Vec2& fromSize, const Vec2& toSize, float progress)
{
    auto bounded = _clamp(progress);
    list.object = from.object;
    list.counterpart = to.object;
    list.visualKind = LayoutVisualKind::Morph;
    list.visualOpacity = 255u;
    if (from.type == CommandType::Path) {
        return _blendPath(list, from, to, fromSize, toSize, progress);
    }
    auto firstStyle = _scale(from.style, fromSize, fromSize, 1.0f);
    auto secondStyle = _scale(to.style, toSize, fromSize, 1.0f);
    auto style = _mix(firstStyle, secondStyle, progress);
    auto first = _scale(from.center, fromSize, fromSize);
    auto second = _scale(to.center, toSize, fromSize);
    auto center = first + (second - first) * progress;
    auto factor = _scale(toSize, fromSize);
    auto layer = _clamp(progress) < 0.5f ? from.layer : to.layer;
    auto depth = _mix(from.depth, to.depth, progress);
    switch (from.type) {
        case CommandType::Circle:
            return list.circle(center, _mix(from.radius, to.radius * factor, bounded),
                               style, layer, depth);
        case CommandType::Text: {
            auto firstTransform = from.transform;
            auto secondTransform = _scale(to.transform, toSize, fromSize);
            auto transform = _mix(firstTransform, secondTransform, progress);
            return list.text(center, from.text, from.font,
                             _mix(from.size, to.size * (from.transformed ? 1.0f : factor), bounded),
                             from.align + (to.align - from.align) * progress,
                             style, layer, depth, from.transformed ? &transform : nullptr);
        }
        case CommandType::Number:
            return list.number(center, _mix(from.number, to.number, progress),
                               _mix(from.size, to.size * factor, bounded),
                               from.align + (to.align - from.align) * progress,
                               style, layer, depth);
        case CommandType::Picture: {
            Vec2 corners[3];
            for (auto i = 0u; i < 3u; i++) {
                auto first = _scale(from.points[i], fromSize, fromSize);
                auto second = _scale(to.points[i], toSize, fromSize);
                corners[i] = first + (second - first) * progress;
            }
            return list.picture(corners, from.picture, from.filter,
                                _mix(from.opacity, to.opacity, progress), layer, depth);
        }
        default: return Result::NonSupport;
    }
}

static bool _compatible(const DisplayList& from, const CommandSpan& fromSpan,
                        const DisplayList& to, const CommandSpan& toSpan)
{
    if (!fromSpan.count || fromSpan.count != toSpan.count) return false;
    for (auto i = 0u; i < fromSpan.count; i++) {
        if (!_compatible(from.commands[fromSpan.begin + i], to.commands[toSpan.begin + i])) {
            return false;
        }
    }
    return true;
}

static bool _text(const DisplayList& list, const CommandSpan& span)
{
    if (!span.count) return false;
    for (auto i = 0u; i < span.count; i++) {
        if (list.commands[span.begin + i].type != CommandType::Text) return false;
    }
    return true;
}

static Result _copy(DisplayList& output, const DisplayList& input, const CommandSpan& span,
                    const Vec2& from, const Vec2& to, float opacity,
                    LayoutVisualKind kind, const Object* counterpart)
{
    if (!span.count) return Result::Success;
    for (auto i = 0u; i < span.count; i++) {
        auto result = _copy(output, input.commands[span.begin + i], from, to, opacity,
                            kind, counterpart);
        if (result != Result::Success) return result;
    }
    return Result::Success;
}

Result DisplayList::blend(const DisplayList& from, const DisplayList& to,
                          const uint32_t* matches, uint32_t fromObjects,
                          uint32_t toObjects, const Vec2& fromSize,
                          const Vec2& toSize, float progress) noexcept
{
    if ((fromObjects && !matches) || fromSize.x <= 0.0f || fromSize.y <= 0.0f
        || toSize.x <= 0.0f || toSize.y <= 0.0f || !std::isfinite(progress)) {
        return Result::InvalidArguments;
    }
    auto fromSpans = fromObjects ? new (std::nothrow) CommandSpan[fromObjects] : nullptr;
    auto toSpans = toObjects ? new (std::nothrow) CommandSpan[toObjects] : nullptr;
    auto morphed = toObjects ? new (std::nothrow) bool[toObjects] : nullptr;
    auto counterparts = toObjects ? new (std::nothrow) const Object*[toObjects] : nullptr;
    if ((fromObjects && !fromSpans)
        || (toObjects && (!toSpans || !morphed || !counterparts))) {
        delete[] fromSpans;
        delete[] toSpans;
        delete[] morphed;
        delete[] counterparts;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < toObjects; i++) {
        morphed[i] = false;
        counterparts[i] = nullptr;
    }
    auto spans = [](const DisplayList& list, CommandSpan* output, uint32_t size) {
        for (auto i = 0u; i < list.count; i++) {
            auto id = list.commands[i].object ? list.commands[i].object->id() : 0u;
            if (!id || id > size) continue;
            auto& span = output[id - 1u];
            if (!span.count) span.begin = i;
            span.count++;
        }
    };
    spans(from, fromSpans, fromObjects);
    spans(to, toSpans, toObjects);

    auto result = Result::Success;
    auto bounded = _clamp(progress);
    for (auto i = 0u; i < fromObjects; i++) {
        auto target = matches[i];
        if (target < toObjects && _compatible(from, fromSpans[i], to, toSpans[target])) {
            for (auto j = 0u; j < fromSpans[i].count; j++) {
                result = _blend(*this, from.commands[fromSpans[i].begin + j],
                                to.commands[toSpans[target].begin + j],
                                fromSize, toSize, progress);
                if (result != Result::Success) break;
            }
            if (result == Result::Success) morphed[target] = true;
        } else if (target < toObjects && _text(from, fromSpans[i])
                   && _text(to, toSpans[target])) {
            auto outgoing = _clamp(1.0f - bounded * 2.0f);
            auto incoming = _clamp(bounded * 2.0f - 1.0f);
            auto fromObject = fromSpans[i].count
                            ? from.commands[fromSpans[i].begin].object : nullptr;
            auto toObject = toSpans[target].count
                          ? to.commands[toSpans[target].begin].object : nullptr;
            result = _copy(*this, from, fromSpans[i], fromSize, fromSize, outgoing,
                           LayoutVisualKind::FadeOut, toObject);
            if (result == Result::Success) {
                result = _copy(*this, to, toSpans[target], toSize, fromSize, incoming,
                               LayoutVisualKind::FadeIn, fromObject);
            }
            if (result == Result::Success) morphed[target] = true;
        } else {
            auto counterpart = target < toObjects && toSpans[target].count
                             ? to.commands[toSpans[target].begin].object : nullptr;
            result = _copy(*this, from, fromSpans[i], fromSize, fromSize,
                           1.0f - bounded, LayoutVisualKind::FadeOut, counterpart);
            if (target < toObjects) {
                counterparts[target] = fromSpans[i].count
                                     ? from.commands[fromSpans[i].begin].object : nullptr;
            }
        }
        if (result != Result::Success) break;
    }
    for (auto i = 0u; result == Result::Success && i < toObjects; i++) {
        if (morphed[i]) continue;
        result = _copy(*this, to, toSpans[i], toSize, fromSize, bounded,
                       LayoutVisualKind::FadeIn, counterparts[i]);
    }
    delete[] fromSpans;
    delete[] toSpans;
    delete[] morphed;
    delete[] counterparts;
    object = nullptr;
    counterpart = nullptr;
    visualKind = LayoutVisualKind::Stable;
    visualOpacity = 255u;
    if (result == Result::Success) sort();
    return result;
}

static Result _cellFace(DisplayList& list, const Vec3* local, const Mat4& model,
                        const Config& config, Color color, float opacity, int32_t layer)
{
    Vec3 world[4];
    auto center = Vec3{};
    for (auto i = 0u; i < 4u; i++) {
        world[i] = model * local[i];
        center = center + world[i] * 0.25f;
    }
    auto normal = (world[1] - world[0]).cross(world[2] - world[0]).normalized();
    auto view = config.camera.projection == Projection::Perspective ? config.camera.eye - center
                                                                    : config.camera.eye - config.camera.target;
    auto facing = normal.dot(view.normalized());
    if (!std::isfinite(facing) || facing <= 0.0f) return Result::Success;
    Vec2 points[4];
    auto depth = 0.0;
    auto aspect = static_cast<float>(config.width) / static_cast<float>(config.height);
    for (auto i = 0u; i < 4u; i++) {
        Vec3 ndc;
        if (!config.camera.project(world[i], aspect, ndc)) return Result::Success;
        points[i] = _pixel(ndc, config);
        depth += ndc.z;
    }
    Style style;
    style.stroke = _shade(color, 0.32f, opacity * 0.65f);
    style.fill = _shade(color, 0.52f + 0.48f * facing, opacity);
    style.width = 0.75f;
    return list.path(points, 4, true, style, layer, static_cast<float>(depth / 4.0));
}

static Result _surfaceFace(DisplayList& list, const Vec3* local, const Mat4& model,
                           const Config& config, const Style& authored,
                           SurfaceMode mode, bool shading, int32_t layer)
{
    Vec3 world[4];
    auto center = Vec3{};
    for (auto i = 0u; i < 4u; i++) {
        world[i] = model * local[i];
        center = center + world[i] * 0.25f;
    }
    auto normal = (world[1] - world[0]).cross(world[2] - world[0]).normalized();
    auto view = config.camera.projection == Projection::Perspective ? config.camera.eye - center
                                                                    : config.camera.eye - config.camera.target;
    auto facing = std::fabs(normal.dot(view.normalized()));
    if (!std::isfinite(facing)) return Result::Success;

    Vec2 points[4];
    auto depth = 0.0;
    auto aspect = static_cast<float>(config.width) / static_cast<float>(config.height);
    for (auto i = 0u; i < 4u; i++) {
        Vec3 ndc;
        if (!config.camera.project(world[i], aspect, ndc)) return Result::Success;
        points[i] = _pixel(ndc, config);
        depth += ndc.z;
    }

    auto style = authored;
    if (mode == SurfaceMode::Mesh) {
        style.fill.a = 0;
    } else {
        auto shade = 0.58f + 0.42f * facing;
        style.fill = shading ? _shade(authored.fill, shade, 1.0f) : authored.fill;
        if (shading && style.gradient.enabled()) {
            style.gradientEnd = _shade(authored.gradientEnd, shade, 1.0f);
            for (auto i = 0u; i < style.gradient.stopCount; i++) {
                style.gradient.stops[i].color =
                    _shade(authored.gradient.stops[i].color, shade, 1.0f);
            }
        }
        if (mode == SurfaceMode::Solid) {
            style.stroke = style.fill;
            style.width = 0.9f;
            style.dashCount = 0;
        }
    }
    return list.path(points, 4, true, style, layer, static_cast<float>(depth / 4.0));
}

static Result _voxel(DisplayList& list, const Vec3& origin, float padding, float depth,
                     const Mat4& model, const Config& config, Color color, float opacity,
                     int32_t layer)
{
    auto x0 = origin.x + padding;
    auto x1 = origin.x + 1.0f - padding;
    auto y0 = origin.y + padding;
    auto y1 = origin.y + 1.0f - padding;
    auto z0 = origin.z + padding * depth;
    auto z1 = origin.z + depth * (1.0f - padding);
    Vec3 corners[8] = {
        {x0, y0, z0}, {x1, y0, z0}, {x1, y1, z0}, {x0, y1, z0}, {x0, y0, z1}, {x1, y0, z1}, {x1, y1, z1}, {x0, y1, z1}};
    static constexpr uint8_t faces[6][4] = {
        {0, 3, 2, 1}, {4, 5, 6, 7}, {0, 1, 5, 4}, {3, 7, 6, 2}, {0, 4, 7, 3}, {1, 2, 6, 5}};
    for (auto& face : faces) {
        Vec3 points[4] = {corners[face[0]], corners[face[1]], corners[face[2]], corners[face[3]]};
        auto result = _cellFace(list, points, model, config, color, opacity, layer);
        if (result != Result::Success) return result;
    }
    return Result::Success;
}

void DisplayList::sort() noexcept
{
    if (count < 2) return;
    std::sort(commands, commands + count, [](const DrawCommand& a, const DrawCommand& b) {
        if (a.layer != b.layer) return a.layer < b.layer;
        if (a.depth != b.depth) return a.depth > b.depth;
        return a.order < b.order;
    });
}

Result Scene::Impl::world(const Object* object, float time, VisualState& state, bool& visible) const noexcept
{
    visible = false;
    auto item = entry(object);
    if (!item) return Result::InvalidArguments;
    if (!sample(*item, time, state)) return Result::Success;
    if (!valid(object) || item->fingerprint != fingerprint(object) || !_affine(state.model)
        || !std::isfinite(state.width) || state.width < 0.0f
        || !std::isfinite(state.radius) || state.radius < 0.0f
        || !std::isfinite(state.dashOffset)
        || !std::isfinite(state.opacity) || !std::isfinite(state.progress)
        || !std::isfinite(state.fillProgress)
        || !std::isfinite(state.pixelScale) || state.pixelScale < 0.0f) {
        return Result::InvalidArguments;
    }
    if (state.morph) {
        auto morphEntry = entry(state.morph);
        if (!morphEntry || !valid(state.morph)
            || morphEntry->fingerprint != fingerprint(state.morph)) {
            return Result::InvalidArguments;
        }
    }
    for (auto i = 0u; i < runtimeModifierCnt; i++) {
        auto& modifier = runtimeModifiers[i];
        if (!modifier.object) continue;
        auto result = modifier.object(object, time, state.model, state.opacity,
                                      state.progress, modifier.data);
        if (result != Result::Success) return result;
        if (!_affine(state.model) || !std::isfinite(state.opacity)
            || state.opacity < 0.0f || state.opacity > 1.0f
            || !std::isfinite(state.progress) || state.progress < 0.0f
            || state.progress > 1.0f) {
            return Result::InvalidArguments;
        }
    }
    for (auto i = 0u; i < runtimeModifierCnt; i++) {
        auto& modifier = runtimeModifiers[i];
        if (!modifier.fill) continue;
        auto result = modifier.fill(object, time, state.fill, modifier.data);
        if (result != Result::Success) return result;
    }
    for (auto parentObject = object->parent(); parentObject; parentObject = parentObject->parent()) {
        auto parent = entry(parentObject);
        VisualState parentState;
        if (!parent || !sample(*parent, time, parentState)) return Result::Success;
        if (!valid(parentObject) || parent->fingerprint != fingerprint(parentObject)
            || !_affine(parentState.model) || !std::isfinite(parentState.width)
            || parentState.width < 0.0f || !std::isfinite(parentState.radius)
            || parentState.radius < 0.0f || !std::isfinite(parentState.dashOffset)
            || !std::isfinite(parentState.opacity)
            || !std::isfinite(parentState.progress) || !std::isfinite(parentState.fillProgress)
            || !std::isfinite(parentState.pixelScale)
            || parentState.pixelScale < 0.0f) {
            return Result::InvalidArguments;
        }
        for (auto i = 0u; i < runtimeModifierCnt; i++) {
            auto& modifier = runtimeModifiers[i];
            if (!modifier.object) continue;
            auto result = modifier.object(parentObject, time, parentState.model,
                                          parentState.opacity, parentState.progress,
                                          modifier.data);
            if (result != Result::Success) return result;
            if (!_affine(parentState.model) || !std::isfinite(parentState.opacity)
                || parentState.opacity < 0.0f || parentState.opacity > 1.0f
                || !std::isfinite(parentState.progress) || parentState.progress < 0.0f
                || parentState.progress > 1.0f) {
                return Result::InvalidArguments;
            }
        }
        state.model = parentState.model * state.model;
        if (parentObject->type() == Type::Group) {
            state.opacity *= parentState.opacity;
            state.progress *= parentState.progress;
            state.fillProgress *= parentState.fillProgress;
            state.pixelScale *= parentState.pixelScale;
            state.traceFill = state.traceFill || parentState.traceFill;
            if (parentState.progress < 1.0f) state.direction = parentState.direction;
        }
    }
    if (!_affine(state.model) || !std::isfinite(state.opacity) || !std::isfinite(state.progress)
        || !std::isfinite(state.fillProgress)
        || !std::isfinite(state.pixelScale) || state.pixelScale < 0.0f) {
        return Result::InvalidArguments;
    }
    visible = true;
    return Result::Success;
}

static void _include(Bounds& bounds, bool& defined, const Vec3& point)
{
    if (!defined) {
        bounds.min = point;
        bounds.max = point;
        defined = true;
        return;
    }
    bounds.min.x = std::fmin(bounds.min.x, point.x);
    bounds.min.y = std::fmin(bounds.min.y, point.y);
    bounds.min.z = std::fmin(bounds.min.z, point.z);
    bounds.max.x = std::fmax(bounds.max.x, point.x);
    bounds.max.y = std::fmax(bounds.max.y, point.y);
    bounds.max.z = std::fmax(bounds.max.z, point.z);
}

static void _bounds(const Bounds& local, const Mat4& model, Bounds& bounds, bool& defined)
{
    for (auto x = 0u; x < 2u; x++) {
        for (auto y = 0u; y < 2u; y++) {
            for (auto z = 0u; z < 2u; z++) {
                _include(bounds, defined, model * Vec3{
                    x ? local.max.x : local.min.x,
                    y ? local.max.y : local.min.y,
                    z ? local.max.z : local.min.z});
            }
        }
    }
}

static bool _morphPoints(const Object* source, const Object* target, const Vec3*& from,
                         const Vec3*& to, uint32_t& count, bool& closed)
{
    if (!source || !target || source->type() != target->type()) return false;
    if (source->type() == Type::Polygon) {
        auto sourcePolygon = static_cast<const Polygon*>(source);
        auto targetPolygon = static_cast<const Polygon*>(target);
        if (sourcePolygon->count() != targetPolygon->count()) return false;
        from = sourcePolygon->points();
        to = targetPolygon->points();
        count = sourcePolygon->count();
        closed = true;
        return true;
    }
    if (source->type() == Type::Plot) {
        auto sourcePlot = static_cast<const Plot*>(source);
        auto targetPlot = static_cast<const Plot*>(target);
        if (sourcePlot->count() != targetPlot->count()) return false;
        from = sourcePlot->points();
        to = targetPlot->points();
        count = sourcePlot->count();
        closed = false;
        return true;
    }
    if (source->type() == Type::Path) {
        auto sourcePath = static_cast<const Path*>(source);
        auto targetPath = static_cast<const Path*>(target);
        if (sourcePath->count() != targetPath->count()
            || sourcePath->closed() != targetPath->closed()) {
            return false;
        }
        from = sourcePath->points();
        to = targetPath->points();
        count = sourcePath->count();
        closed = sourcePath->closed();
        return true;
    }
    if (source->type() == Type::Curve) {
        auto sourceCurve = static_cast<const Curve*>(source);
        auto targetCurve = static_cast<const Curve*>(target);
        if (sourceCurve->count() != targetCurve->count()) return false;
        from = sourceCurve->points();
        to = targetCurve->points();
        count = sourceCurve->count();
        closed = false;
        return true;
    }
    return false;
}

static Result _morph(DisplayList& list, const Object* source, const VisualState& state,
                     const Config& config, const Style& style)
{
    const Vec3* from;
    const Vec3* to;
    uint32_t count;
    bool closed;
    if (!_morphPoints(source, state.morph, from, to, count, closed)) return Result::NonSupport;
    auto projected = new (std::nothrow) Vec2[count];
    if (!projected) return Result::OutOfMemory;
    auto depth = 0.0;
    auto visible = true;
    for (auto i = 0u; i < count; i++) {
        auto local = from[i] + (to[i] - from[i]) * state.morphProgress;
        auto pointDepth = 0.0f;
        if (!_point(local, state.model, config, projected[i], pointDepth)) {
            visible = false;
            break;
        }
        depth += pointDepth;
    }
    auto result = Result::Success;
    if (visible) {
        result = _path(list, projected, count, closed, state.progress, state.direction,
                       style, source->layer, static_cast<float>(depth / count), state.traceFill);
    }
    delete[] projected;
    return result;
}

static Vec3 _edge(const Bounds& bounds, const Vec3& direction)
{
    auto half = bounds.size() * 0.5f;
    auto distance = std::numeric_limits<float>::infinity();
    if (std::fabs(direction.x) > 1.0e-7f) distance = std::fmin(distance, half.x / std::fabs(direction.x));
    if (std::fabs(direction.y) > 1.0e-7f) distance = std::fmin(distance, half.y / std::fabs(direction.y));
    if (std::fabs(direction.z) > 1.0e-7f) distance = std::fmin(distance, half.z / std::fabs(direction.z));
    if (!std::isfinite(distance)) distance = 0.0f;
    return bounds.center() + direction * distance;
}

Result Scene::Impl::bounds(const Object* object, float time, Bounds& bounds, bool& defined) const noexcept
{
    VisualState state;
    auto visible = false;
    auto result = world(object, time, state, visible);
    if (result != Result::Success) return result;
    if (visible && state.opacity > 0.0f && state.progress > 0.0f && object->type() != Type::Connector) {
        if (state.morph) {
            const Vec3* from;
            const Vec3* to;
            uint32_t count;
            bool closed;
            if (!_morphPoints(object, state.morph, from, to, count, closed)) return Result::NonSupport;
            for (auto i = 0u; i < count; i++) {
                auto point = from[i] + (to[i] - from[i]) * state.morphProgress;
                _include(bounds, defined, state.model * point);
            }
        } else {
            Bounds local;
            if (localBounds(object, local)) _bounds(local, state.model, bounds, defined);
        }
    }
    for (auto i = 0u; i < object->childCount(); i++) {
        result = this->bounds(object->childAt(i), time, bounds, defined);
        if (result != Result::Success) return result;
    }
    return Result::Success;
}

Result Scene::Impl::build(float time, DisplayList& list, bool sorted) const noexcept
{
    if (!std::isfinite(time) || time < 0.0f) return Result::InvalidArguments;
    auto config = cfg;
    auto cameraResult = sample(time, config.camera, config.cameraView);
    if (cameraResult != Result::Success) return cameraResult;
    if (!valid(config)) return Result::InvalidArguments;
    for (auto i = 0u; i < objectCnt; i++) {
        VisualState state;
        auto object = objects[i].object;
        list.object = object;
        auto visible = false;
        auto sampled = world(object, time, state, visible);
        if (sampled != Result::Success) return sampled;
        if (!visible) continue;
        auto style = _style(object, state);
        _project(style.gradient, state.model, config);
        auto progress = _clamp(state.progress);
        if (progress <= 0.0f || state.pixelScale <= 0.0f) continue;
        Result result = Result::Success;

        if (state.morph) {
            result = _morph(list, object, state, config, style);
            if (result != Result::Success) return result;
            continue;
        }

        switch (object->type()) {
            case Type::Line: {
                auto line = static_cast<Line*>(object);
                Vec2 fromPixel;
                Vec2 toPixel;
                float depth;
                if (_lineWorld(line->from, line->to, state.model, config, fromPixel, toPixel, depth)) {
                    result = _line(list, fromPixel, toPixel, progress, state.direction,
                                   style, object->layer, depth);
                }
                break;
            }
            case Type::Arrow: {
                auto arrow = static_cast<Arrow*>(object);
                Vec2 fromPixel;
                Vec2 toPixel;
                float depth;
                if (_lineWorld(arrow->from, arrow->to, state.model, config, fromPixel, toPixel, depth)) {
                    Vec2 points[] = {fromPixel, toPixel};
                    result = _route(list, points, 2u, progress, state.direction,
                                    state.markerTail * state.pixelScale,
                                    state.markerTip * state.pixelScale, style, object->layer,
                                    depth);
                }
                break;
            }
            case Type::Point: {
                auto point = static_cast<Point*>(object);
                Vec2 pixel;
                float depth;
                if (progress > 0.0f && _point(point->point, state.model, config, pixel, depth)) {
                    result = list.circle(pixel, style.radius * progress, style, object->layer, depth);
                }
                break;
            }
            case Type::Text: {
                auto text = static_cast<Text*>(object);
                Vec2 pixel;
                float depth;
                if (_point(text->point, state.model, config, pixel, depth)) {
                    style.fill = _opacity(style.fill, progress);
                    if (text->orientation == TextOrientation::Plane) {
                        constexpr auto ReferenceSize = 100.0f;
                        auto worldSize = text->size * state.pixelScale;
                        Vec2 x;
                        Vec2 y;
                        float xDepth;
                        float yDepth;
                        if (_point(text->point + Vec3{worldSize, 0.0f, 0.0f}, state.model,
                                   config, x, xDepth)
                            && _point(text->point + Vec3{0.0f, -worldSize, 0.0f}, state.model,
                                      config, y, yDepth)) {
                            Mat3 transform = {{
                                (x.x - pixel.x) / ReferenceSize,
                                (y.x - pixel.x) / ReferenceSize, pixel.x,
                                (x.y - pixel.y) / ReferenceSize,
                                (y.y - pixel.y) / ReferenceSize, pixel.y,
                                0.0f, 0.0f, 1.0f}};
                            result = list.text(pixel, text->text(), text->font(), ReferenceSize,
                                               text->align, style, object->layer,
                                               (depth + xDepth + yDepth) / 3.0f, &transform);
                        }
                    } else {
                        result = list.text(pixel, text->text(), text->font(),
                                           text->size * state.pixelScale, text->align, style,
                                           object->layer, depth);
                    }
                }
                break;
            }
            case Type::Vector: {
                auto vector = static_cast<Vector*>(object);
                Vec2 fromPixel;
                Vec2 toPixel;
                float depth;
                if (_lineWorld(vector->origin, vector->origin + vector->value, state.model,
                               config, fromPixel, toPixel, depth)) {
                    Vec2 points[] = {fromPixel, toPixel};
                    result = _route(list, points, 2u, progress, state.direction,
                                    state.markerTail * state.pixelScale,
                                    state.markerTip * state.pixelScale, style, object->layer,
                                    depth);
                }
                break;
            }
            case Type::Space: {
                auto space = static_cast<Space*>(object);
                {
                    auto index = 0u;
                    for (auto x = std::ceil(space->x.min / space->x.step) * space->x.step; x <= space->x.max + space->x.step * 0.001f && index++ < 4096; x += space->x.step) {
                        if (std::fabs(x) < space->x.step * 0.001f) continue;
                        result = _gridLine(list, {x, space->y.min, 0.0f}, {x, space->y.max, 0.0f}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                    index = 0;
                    for (auto y = std::ceil(space->y.min / space->y.step) * space->y.step; y <= space->y.max + space->y.step * 0.001f && index++ < 4096; y += space->y.step) {
                        if (std::fabs(y) < space->y.step * 0.001f) continue;
                        result = _gridLine(list, {space->x.min, y, 0.0f}, {space->x.max, y, 0.0f}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                }
                if (config.cameraView == CameraView::ThreeD) {
                    auto index = 0u;
                    for (auto x = std::ceil(space->x.min / space->x.step) * space->x.step; x <= space->x.max + space->x.step * 0.001f && index++ < 4096; x += space->x.step) {
                        if (std::fabs(x) < space->x.step * 0.001f) continue;
                        result = _gridLine(list, {x, 0.0f, space->z.min}, {x, 0.0f, space->z.max}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                    index = 0;
                    for (auto z = std::ceil(space->z.min / space->z.step) * space->z.step; z <= space->z.max + space->z.step * 0.001f && index++ < 4096; z += space->z.step) {
                        if (std::fabs(z) < space->z.step * 0.001f) continue;
                        result = _gridLine(list, {space->x.min, 0.0f, z}, {space->x.max, 0.0f, z}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                }
                if (config.cameraView == CameraView::ThreeD) {
                    auto index = 0u;
                    for (auto y = std::ceil(space->y.min / space->y.step) * space->y.step; y <= space->y.max + space->y.step * 0.001f && index++ < 4096; y += space->y.step) {
                        if (std::fabs(y) < space->y.step * 0.001f) continue;
                        result = _gridLine(list, {0.0f, y, space->z.min}, {0.0f, y, space->z.max}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                    index = 0;
                    for (auto z = std::ceil(space->z.min / space->z.step) * space->z.step; z <= space->z.max + space->z.step * 0.001f && index++ < 4096; z += space->z.step) {
                        if (std::fabs(z) < space->z.step * 0.001f) continue;
                        result = _gridLine(list, {0.0f, space->y.min, z}, {0.0f, space->y.max, z}, state, config, style, object->layer);
                        if (result != Result::Success) return result;
                    }
                }
                auto axisStyle = style;
                auto axisLayer = object->layer == std::numeric_limits<int32_t>::max() ? object->layer : object->layer + 1;
                axisStyle.width = style.width < 1.5f ? 1.5f : style.width;
                axisStyle.stroke = _opacity(space->axisX, state.opacity);
                result = _gridLine(list, {space->x.min, 0.0f, 0.0f}, {space->x.max, 0.0f, 0.0f}, state, config, axisStyle, axisLayer);
                if (result != Result::Success) return result;
                axisStyle.stroke = _opacity(space->axisY, state.opacity);
                result = _gridLine(list, {0.0f, space->y.min, 0.0f}, {0.0f, space->y.max, 0.0f}, state, config, axisStyle, axisLayer);
                if (result != Result::Success) return result;
                if (config.cameraView == CameraView::ThreeD) {
                    axisStyle.stroke = _opacity(space->axisZ, state.opacity);
                    result = _gridLine(list, {0.0f, 0.0f, space->z.min}, {0.0f, 0.0f, space->z.max}, state, config, axisStyle, axisLayer);
                }
                if (result == Result::Success) {
                    auto numberLayer = axisLayer == std::numeric_limits<int32_t>::max() ? axisLayer : axisLayer + 1;
                    result = _spaceNumbers(list, space, state, config, numberLayer);
                }
                break;
            }
            case Type::Circle: {
                auto circle = static_cast<Circle*>(object);
                constexpr auto count = 64u;
                Vec2 points[count];
                auto depth = 0.0;
                auto visible = true;
                for (auto j = 0u; j < count; j++) {
                    auto angle = PI2 * static_cast<float>(j) / static_cast<float>(count);
                    auto point = circle->center + Vec3{std::cos(angle) * circle->radius, std::sin(angle) * circle->radius, 0.0f};
                    auto pointDepth = 0.0f;
                    if (!_point(point, state.model, config, points[j], pointDepth)) {
                        visible = false;
                        break;
                    }
                    depth += pointDepth;
                }
                if (visible) result = _path(list, points, count, true, progress, state.direction,
                                            style, object->layer, static_cast<float>(depth / count),
                                            state.traceFill);
                break;
            }
            case Type::Polygon:
            case Type::Plot:
            case Type::Path:
            case Type::Curve: {
                auto points = static_cast<const Vec3*>(nullptr);
                auto count = 0u;
                auto closed = false;
                if (object->type() == Type::Polygon) {
                    auto polygon = static_cast<Polygon*>(object);
                    points = polygon->points();
                    count = polygon->count();
                    closed = true;
                } else if (object->type() == Type::Plot) {
                    auto plot = static_cast<Plot*>(object);
                    points = plot->points();
                    count = plot->count();
                } else if (object->type() == Type::Path) {
                    auto path = static_cast<Path*>(object);
                    points = path->points();
                    count = path->count();
                    closed = path->closed();
                } else {
                    auto curve = static_cast<Curve*>(object);
                    points = curve->points();
                    count = curve->count();
                }
                auto projected = new (std::nothrow) Vec2[count];
                if (!projected) return Result::OutOfMemory;
                auto depth = 0.0;
                auto visible = true;
                for (auto j = 0u; j < count; j++) {
                    auto pointDepth = 0.0f;
                    if (!_point(points[j], state.model, config, projected[j], pointDepth)) {
                        visible = false;
                        break;
                    }
                    depth += pointDepth;
                }
                if (visible) result = _path(list, projected, count, closed, progress, state.direction,
                                            style, object->layer, static_cast<float>(depth / count),
                                            state.traceFill);
                delete[] projected;
                break;
            }
            case Type::Route: {
                auto route = static_cast<DirectedRoute*>(object);
                auto count = route->count();
                auto projected = new (std::nothrow) Vec2[count];
                if (!projected) return Result::OutOfMemory;
                auto depth = 0.0;
                auto visible = true;
                for (auto j = 0u; j < count; j++) {
                    auto pointDepth = 0.0f;
                    if (!_point(route->points()[j], state.model, config, projected[j],
                                pointDepth)) {
                        visible = false;
                        break;
                    }
                    depth += pointDepth;
                }
                if (visible) {
                    result = _route(list, projected, count, progress, state.direction,
                                    state.markerTail * state.pixelScale,
                                    state.markerTip * state.pixelScale, style, object->layer,
                                    static_cast<float>(depth / count));
                }
                delete[] projected;
                break;
            }
            case Type::Picture: {
                auto image = static_cast<Picture*>(object);
                auto height = image->width * static_cast<float>(image->pixelHeight()) / static_cast<float>(image->pixelWidth());
                Vec3 local[3] = {
                    image->center + Vec3{-image->width * 0.5f, height * 0.5f, 0.0f},
                    image->center + Vec3{image->width * 0.5f, height * 0.5f, 0.0f},
                    image->center + Vec3{-image->width * 0.5f, -height * 0.5f, 0.0f}};
                Vec2 corners[3];
                auto depth = 0.0;
                auto visible = true;
                for (auto i = 0u; i < 3u; i++) {
                    auto pointDepth = 0.0f;
                    if (!_point(local[i], state.model, config, corners[i], pointDepth)) {
                        visible = false;
                        break;
                    }
                    depth += pointDepth;
                }
                auto opacity = static_cast<uint8_t>(_clamp(state.opacity * progress) * 255.0f + 0.5f);
                if (visible && opacity) {
                    PictureSource source;
                    source.encoded = image->encoded();
                    source.encodedSize = image->encodedSize();
                    source.mime = image->mime();
                    source.pixels = image->pixels();
                    source.width = image->pixelWidth();
                    source.height = image->pixelHeight();
                    result = list.picture(corners, source, image->filter, opacity, object->layer,
                                        static_cast<float>(depth / 3.0));
                }
                break;
            }
            case Type::Cell: {
                auto cell = static_cast<Cell*>(object);
                auto total = cell->columns() * cell->rows();
                auto visible = static_cast<uint32_t>(std::ceil(static_cast<float>(total) * progress));
                if (visible > total) visible = total;
                auto colors = cell->colors();
                auto nextColors = colors;
                auto colorProgress = 0.0f;
                auto frames = sampleFrames(cell);
                if (frames > 1u) {
                    auto duration = sampleDuration(cell);
                    auto position = _clamp((time - objects[i].born) / duration)
                                  * static_cast<float>(frames - 1u);
                    auto frame = static_cast<uint32_t>(std::floor(position));
                    if (frame >= frames - 1u) {
                        frame = frames - 1u;
                    } else {
                        colorProgress = position - static_cast<float>(frame);
                        nextColors = sampleColors(cell, frame + 1u);
                    }
                    colors = sampleColors(cell, frame);
                }
                auto padding = cell->mode == CellMode::Padd ? cell->padding : 0.0f;
                auto reverse = _reverse(state.direction);
                for (auto shown = 0u; shown < visible; shown++) {
                    auto index = reverse ? total - 1u - shown : shown;
                    auto color = colors[index];
                    if (colorProgress > 0.0f) color = _mix(color, nextColors[index], colorProgress);
                    if (!color.a) continue;
                    auto x = index % cell->columns();
                    auto y = index / cell->columns();
                    auto origin = cell->origin + Vec3{static_cast<float>(x), static_cast<float>(y), 0.0f};
                    if (config.cameraView == CameraView::ThreeD) {
                        result = _voxel(list, origin, padding, cell->depth, state.model, config,
                                        color, state.opacity, object->layer);
                    } else {
                        Vec3 local[4] = {
                            origin + Vec3{padding, padding, 0.0f},
                            origin + Vec3{1.0f - padding, padding, 0.0f},
                            origin + Vec3{1.0f - padding, 1.0f - padding, 0.0f},
                            origin + Vec3{padding, 1.0f - padding, 0.0f}};
                        Vec2 points[4];
                        auto depth = 0.0;
                        auto projected = true;
                        for (auto j = 0u; j < 4u; j++) {
                            auto pointDepth = 0.0f;
                            if (!_point(local[j], state.model, config, points[j], pointDepth)) {
                                projected = false;
                                break;
                            }
                            depth += pointDepth;
                        }
                        if (projected) {
                            Style cellStyle;
                            cellStyle.stroke.a = 0;
                            cellStyle.fill = _opacity(color, state.opacity);
                            cellStyle.width = 0.0f;
                            result = list.path(points, 4, true, cellStyle, object->layer,
                                               static_cast<float>(depth / 4.0));
                        }
                    }
                    if (result != Result::Success) return result;
                }
                break;
            }
            case Type::SurfaceMesh: {
                auto surface = static_cast<SurfaceMesh*>(object);
                auto columns = surface->columns();
                auto rows = surface->rows();
                auto cellColumns = columns - 1u;
                auto total = cellColumns * (rows - 1u);
                auto visible = static_cast<uint32_t>(std::ceil(static_cast<float>(total) * progress));
                if (visible > total) visible = total;
                auto reverse = _reverse(state.direction);
                for (auto shown = 0u; shown < visible; shown++) {
                    auto index = reverse ? total - 1u - shown : shown;
                    auto x = index % cellColumns;
                    auto y = index / cellColumns;
                    auto row = y * columns;
                    auto next = row + columns;
                    Vec3 points[4] = {
                        surface->points()[row + x], surface->points()[row + x + 1u],
                        surface->points()[next + x + 1u], surface->points()[next + x]};
                    result = _surfaceFace(list, points, state.model, config, style,
                                          surface->mode, surface->shading, object->layer);
                    if (result != Result::Success) return result;
                }
                break;
            }
            case Type::Group: break;
            case Type::Rectangle: {
                auto rectangle = static_cast<Rectangle*>(object);
                constexpr auto segments = 8u;
                Vec3 local[segments * 4u];
                auto count = 0u;
                auto half = Vec2{rectangle->size.x * 0.5f, rectangle->size.y * 0.5f};
                if (rectangle->corner <= 0.0f) {
                    local[0] = rectangle->center + Vec3{-half.x, -half.y, 0.0f};
                    local[1] = rectangle->center + Vec3{half.x, -half.y, 0.0f};
                    local[2] = rectangle->center + Vec3{half.x, half.y, 0.0f};
                    local[3] = rectangle->center + Vec3{-half.x, half.y, 0.0f};
                    count = 4u;
                } else {
                    auto radius = rectangle->corner;
                    Vec2 centers[4] = {
                        {half.x - radius, half.y - radius},
                        {-half.x + radius, half.y - radius},
                        {-half.x + radius, -half.y + radius},
                        {half.x - radius, -half.y + radius}};
                    for (auto corner = 0u; corner < 4u; corner++) {
                        for (auto j = 0u; j < segments; j++) {
                            auto angle = PI2 * (static_cast<float>(corner) * 0.25f
                                               + static_cast<float>(j) / (segments * 4.0f));
                            local[count++] = rectangle->center + Vec3{
                                centers[corner].x + std::cos(angle) * radius,
                                centers[corner].y + std::sin(angle) * radius, 0.0f};
                        }
                    }
                }
                Vec2 points[segments * 4u];
                auto depth = 0.0;
                auto projected = true;
                for (auto j = 0u; j < count; j++) {
                    auto pointDepth = 0.0f;
                    if (!_point(local[j], state.model, config, points[j], pointDepth)) {
                        projected = false;
                        break;
                    }
                    depth += pointDepth;
                }
                if (projected) result = _path(list, points, count, true, progress, state.direction,
                                              style, object->layer, static_cast<float>(depth / count),
                                              state.traceFill);
                break;
            }
            case Type::Connector: {
                auto connector = static_cast<Connector*>(object);
                Bounds source;
                Bounds destination;
                auto sourceDefined = false;
                auto destinationDefined = false;
                result = this->bounds(connector->from(), time, source, sourceDefined);
                if (result != Result::Success) return result;
                result = this->bounds(connector->to(), time, destination, destinationDefined);
                if (result != Result::Success) return result;
                if (!sourceDefined || !destinationDefined) break;
                auto delta = destination.center() - source.center();
                auto length = delta.length();
                if (!std::isfinite(length) || length <= 1.0e-7f) break;
                auto direction = delta / length;
                auto from = _edge(source, direction) + direction * connector->padding;
                auto to = _edge(destination, direction * -1.0f) - direction * connector->padding;
                if ((to - from).dot(direction) <= 1.0e-7f) break;
                Vec2 fromPixel;
                Vec2 toPixel;
                float depth;
                if (!_lineWorld(from, to, Mat4::identity(), config, fromPixel, toPixel, depth)) break;
                if (state.markerTip > 0.0f || state.markerTail > 0.0f) {
                    Vec2 points[] = {fromPixel, toPixel};
                    result = _route(list, points, 2u, progress, state.direction,
                                    state.markerTail * state.pixelScale,
                                    state.markerTip * state.pixelScale, style, object->layer,
                                    depth);
                } else {
                    result = _line(list, fromPixel, toPixel, progress, state.direction,
                                   style, object->layer, depth);
                }
                break;
            }
        }
        if (result != Result::Success) return result;
    }
    list.object = nullptr;
    if (sorted) list.sort();
    return Result::Success;
}

}  // namespace tmath
