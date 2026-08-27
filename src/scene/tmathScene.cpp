#include <cmath>
#include <cstring>
#include <limits>
#include <new>

#include "tmath.h"
#include "tmathScene.h"

namespace tmath
{

static constexpr uint32_t MAX_OBJECTS = 1048576;
static constexpr uint32_t MAX_ANIMATION_GROUP = 4096;
static constexpr uint32_t MAX_OBJECT_DEPTH = 64;
static constexpr uint32_t MAX_VIEWPORTS = 64;
static constexpr uint32_t MAX_VIEWPORT_DEPTH = 16;
static constexpr auto SOURCE_SERIF_FONT = "Source Serif 4";
static constexpr auto KOREAN_FONT = "IBM Plex Sans KR";

static char* _duplicate(const char* text)
{
    if (!text) return nullptr;
    auto size = std::strlen(text) + 1u;
    auto copy = new (std::nothrow) char[size];
    if (copy) std::memcpy(copy, text, size);
    return copy;
}

static bool _equal(const Color& first, const Color& second)
{
    return first.r == second.r && first.g == second.g && first.b == second.b
           && first.a == second.a;
}

static const TextTheme& _textTheme(const Theme& theme, TextRole role)
{
    switch (role) {
        case TextRole::H1: return theme.h1;
        case TextRole::H2: return theme.h2;
        case TextRole::H3: return theme.h3;
        case TextRole::Text: return theme.text;
        case TextRole::Code: return theme.code;
    }
    return theme.text;
}

static bool _hangul(const char* text)
{
    auto cursor = reinterpret_cast<const uint8_t*>(text);
    while (cursor && *cursor) {
        uint32_t codepoint = 0u;
        uint32_t length = 0u;
        if (*cursor < 0x80u) {
            codepoint = *cursor;
            length = 1u;
        } else if ((*cursor & 0xe0u) == 0xc0u) {
            codepoint = *cursor & 0x1fu;
            length = 2u;
        } else if ((*cursor & 0xf0u) == 0xe0u) {
            codepoint = *cursor & 0x0fu;
            length = 3u;
        } else if ((*cursor & 0xf8u) == 0xf0u) {
            codepoint = *cursor & 0x07u;
            length = 4u;
        } else {
            cursor++;
            continue;
        }
        auto valid = true;
        for (auto i = 1u; i < length; i++) {
            if ((cursor[i] & 0xc0u) != 0x80u) {
                valid = false;
                break;
            }
            codepoint = (codepoint << 6u) | (cursor[i] & 0x3fu);
        }
        if (!valid) {
            cursor++;
            continue;
        }
        if ((codepoint >= 0x1100u && codepoint <= 0x11ffu)
            || (codepoint >= 0x3130u && codepoint <= 0x318fu)
            || (codepoint >= 0xa960u && codepoint <= 0xa97fu)
            || (codepoint >= 0xac00u && codepoint <= 0xd7ffu)
            || (codepoint >= 0xffa0u && codepoint <= 0xffdcu)) {
            return true;
        }
        cursor += length;
    }
    return false;
}

static const char* _textFont(const TextTheme& theme, const Text* text)
{
    if (std::strcmp(theme.font, SOURCE_SERIF_FONT) == 0 && _hangul(text->text())) return KOREAN_FONT;
    return theme.font;
}

static bool _valid(const TextTheme& text)
{
    return text.font && text.font[0] && std::isfinite(text.size) && text.size > 0.0f;
}

static bool _valid(const Theme& theme)
{
    return theme.objectCount && theme.objectCount <= Theme::ColorLimit
           && std::isfinite(theme.objectWidth) && theme.objectWidth > 0.0f
           && _valid(theme.h1) && _valid(theme.h2) && _valid(theme.h3)
           && _valid(theme.text) && _valid(theme.code);
}

static bool _palette(Type type)
{
    return type != Type::Space && type != Type::Text && type != Type::Svg
           && type != Type::Image && type != Type::Cell && type != Type::Group;
}

static Style _defaultStyle(Type type)
{
    Style style;
    if (type == Type::Point) {
        style.fill = style.stroke;
    } else if (type == Type::Text) {
        style.fill = style.stroke;
        style.stroke.a = 0;
    } else if (type == Type::Space) {
        style.stroke = {55, 65, 81, 180};
        style.width = 1.0f;
    } else if (type == Type::Group) {
        style.stroke.a = 0;
        style.fill.a = 0;
        style.width = 0.0f;
    } else if (type == Type::SurfaceMesh) {
        style.fill = {91, 141, 239, 255};
        style.stroke = {35, 55, 84, 255};
        style.width = 1.0f;
    }
    return style;
}

static bool _colorChanged(const Object* object)
{
    auto style = _defaultStyle(object->type());
    return !_equal(object->style.stroke, style.stroke)
           || !_equal(object->style.fill, style.fill);
}

static void _hash(uint64_t& hash, const void* data, size_t size)
{
    auto bytes = static_cast<const uint8_t*>(data);
    for (auto i = 0u; i < size; i++) {
        hash ^= bytes[i];
        hash *= 1099511628211ull;
    }
}

template<typename T>
static void _hash(uint64_t& hash, const T& value)
{
    _hash(hash, &value, sizeof(value));
}

static void _hash(uint64_t& hash, const Vec2& value)
{
    _hash(hash, value.x);
    _hash(hash, value.y);
}

static void _hash(uint64_t& hash, const Vec3& value)
{
    _hash(hash, value.x);
    _hash(hash, value.y);
    _hash(hash, value.z);
}

static void _hash(uint64_t& hash, const Color& value)
{
    _hash(hash, value.r);
    _hash(hash, value.g);
    _hash(hash, value.b);
    _hash(hash, value.a);
}

static void _hash(uint64_t& hash, const Range& value)
{
    _hash(hash, value.min);
    _hash(hash, value.max);
    _hash(hash, value.step);
}

static void _hash(uint64_t& hash, const char* value)
{
    if (!value) {
        auto empty = uint8_t{0};
        _hash(hash, empty);
        return;
    }
    _hash(hash, value, std::strlen(value) + 1u);
}

uint64_t fingerprint(const Object* object) noexcept
{
    auto hash = 14695981039346656037ull;
    auto type = object->type();
    _hash(hash, type);
    _hash(hash, object->style.stroke);
    _hash(hash, object->style.fill);
    _hash(hash, object->style.gradientEnd);
    _hash(hash, object->style.width);
    _hash(hash, object->style.radius);
    _hash(hash, object->style.dashCount);
    _hash(hash, object->style.dashOffset);
    _hash(hash, object->style.gradient);
    for (auto i = 0u; i < object->style.dashCount && i < Style::DashLimit; i++) {
        _hash(hash, object->style.dash[i]);
    }
    _hash(hash, object->layer);
    _hash(hash, object->opacity);
    _hash(hash, object->progress);
    for (auto value : object->model.e)
        _hash(hash, value);
    switch (type) {
        case Type::Line: {
            auto value = static_cast<const Line*>(object);
            _hash(hash, value->from);
            _hash(hash, value->to);
            break;
        }
        case Type::Arrow: {
            auto value = static_cast<const Arrow*>(object);
            _hash(hash, value->from);
            _hash(hash, value->to);
            _hash(hash, value->tail);
            _hash(hash, value->tip);
            break;
        }
        case Type::Point: _hash(hash, static_cast<const Point*>(object)->point); break;
        case Type::Text: {
            auto value = static_cast<const Text*>(object);
            _hash(hash, value->point);
            _hash(hash, value->size);
            _hash(hash, value->align);
            _hash(hash, value->orientation);
            _hash(hash, value->role);
            _hash(hash, value->text());
            _hash(hash, value->font());
            break;
        }
        case Type::Vector: {
            auto value = static_cast<const Vector*>(object);
            _hash(hash, value->value);
            _hash(hash, value->origin);
            _hash(hash, value->tail);
            _hash(hash, value->tip);
            break;
        }
        case Type::Space: {
            auto value = static_cast<const Space*>(object);
            _hash(hash, value->x);
            _hash(hash, value->y);
            _hash(hash, value->z);
            _hash(hash, value->axisX);
            _hash(hash, value->axisY);
            _hash(hash, value->axisZ);
            _hash(hash, value->numberColor);
            _hash(hash, value->numberMode);
            _hash(hash, value->numberSize);
            _hash(hash, value->numbers);
            break;
        }
        case Type::Circle: {
            auto value = static_cast<const Circle*>(object);
            _hash(hash, value->center);
            _hash(hash, value->radius);
            break;
        }
        case Type::Polygon: {
            auto value = static_cast<const Polygon*>(object);
            _hash(hash, value->count());
            for (auto i = 0u; i < value->count(); i++)
                _hash(hash, value->points()[i]);
            break;
        }
        case Type::Plot: {
            auto value = static_cast<const Plot*>(object);
            _hash(hash, value->count());
            for (auto i = 0u; i < value->count(); i++)
                _hash(hash, value->points()[i]);
            break;
        }
        case Type::Route: {
            auto value = static_cast<const DirectedRoute*>(object);
            _hash(hash, value->count());
            _hash(hash, value->tail);
            _hash(hash, value->tip);
            for (auto i = 0u; i < value->count(); i++)
                _hash(hash, value->points()[i]);
            break;
        }
        case Type::Path: {
            auto value = static_cast<const Path*>(object);
            _hash(hash, value->count());
            _hash(hash, value->closed());
            for (auto i = 0u; i < value->count(); i++)
                _hash(hash, value->points()[i]);
            break;
        }
        case Type::Curve: {
            auto value = static_cast<const Curve*>(object);
            _hash(hash, value->count());
            for (auto i = 0u; i < value->count(); i++)
                _hash(hash, value->points()[i]);
            break;
        }
        case Type::Ruler: {
            auto value = static_cast<const Ruler*>(object);
            _hash(hash, value->from);
            _hash(hash, value->to);
            _hash(hash, value->step);
            _hash(hash, value->tick);
            break;
        }
        case Type::Svg: {
            auto value = static_cast<const Svg*>(object);
            _hash(hash, value->center);
            _hash(hash, value->width);
            _hash(hash, value->path());
            break;
        }
        case Type::Image: {
            auto value = static_cast<const Image*>(object);
            _hash(hash, value->center);
            _hash(hash, value->width);
            _hash(hash, value->filter);
            _hash(hash, value->pixelWidth());
            _hash(hash, value->pixelHeight());
            break;
        }
        case Type::Cell: {
            auto value = static_cast<const Cell*>(object);
            _hash(hash, value->origin);
            _hash(hash, value->depth);
            _hash(hash, value->mode);
            _hash(hash, value->padding);
            _hash(hash, value->columns());
            _hash(hash, value->rows());
            _hash(hash, sampleFrames(value));
            _hash(hash, sampleDuration(value));
            break;
        }
        case Type::Group: break;
        case Type::Rectangle: {
            auto value = static_cast<const Rectangle*>(object);
            _hash(hash, value->center);
            _hash(hash, value->size);
            _hash(hash, value->corner);
            break;
        }
        case Type::Connector: {
            auto value = static_cast<const Connector*>(object);
            _hash(hash, value->from());
            _hash(hash, value->to());
            _hash(hash, value->padding);
            _hash(hash, value->tail);
            _hash(hash, value->tip);
            break;
        }
        case Type::SurfaceMesh: {
            auto value = static_cast<const SurfaceMesh*>(object);
            _hash(hash, value->mode);
            _hash(hash, value->shading);
            _hash(hash, value->columns());
            _hash(hash, value->rows());
            auto count = value->columns() * value->rows();
            for (auto i = 0u; i < count; i++)
                _hash(hash, value->points()[i]);
            break;
        }
    }
    return hash;
}

static bool _finite(const Vec2& value)
{
    return std::isfinite(value.x) && std::isfinite(value.y);
}

static bool _finite(const Vec3& value)
{
    return std::isfinite(value.x) && std::isfinite(value.y) && std::isfinite(value.z);
}

static bool _finite(const Range& value)
{
    return std::isfinite(value.min) && std::isfinite(value.max) && std::isfinite(value.step) && value.min <= value.max && value.step > 0.0f;
}

static bool _finite(const Mat4& value)
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

static bool _identity(const Mat4& value)
{
    auto identity = Mat4::identity();
    for (auto i = 0u; i < 16u; i++) {
        if (value.e[i] != identity.e[i]) return false;
    }
    return true;
}

static bool _equal(const Mat4& first, const Mat4& second)
{
    for (auto i = 0u; i < 16u; i++) {
        if (first.e[i] != second.e[i]) return false;
    }
    return true;
}

bool valid(const Config& config) noexcept
{
    if (!config.width || !config.height || !config.fps) return false;
    if (config.cameraMode != CameraMode::Fixed && config.cameraMode != CameraMode::Interactive) return false;
    if (config.cameraView != CameraView::TwoD && config.cameraView != CameraView::ThreeD) return false;
    auto& camera = config.camera;
    if (!_finite(camera.eye) || !_finite(camera.target) || !_finite(camera.up)) return false;
    if (camera.projection != Projection::Perspective && camera.projection != Projection::Orthographic) return false;
    if (!std::isfinite(camera.near) || !std::isfinite(camera.far) || camera.near <= 0.0f || camera.far <= camera.near) {
        return false;
    }
    if (!std::isfinite(camera.fov) || camera.fov <= 0.0f || camera.fov >= 3.14159265359f) return false;
    if (!std::isfinite(camera.orthoHeight) || camera.orthoHeight <= 0.0f) return false;
    if (config.cameraView == CameraView::TwoD && (camera.projection != Projection::Orthographic || camera.eye.x != camera.target.x || camera.eye.y != camera.target.y || camera.eye.z <= camera.target.z || camera.up.x != 0.0f || camera.up.y <= 0.0f || camera.up.z != 0.0f)) {
        return false;
    }
    auto fx = static_cast<double>(camera.target.x) - camera.eye.x;
    auto fy = static_cast<double>(camera.target.y) - camera.eye.y;
    auto fz = static_cast<double>(camera.target.z) - camera.eye.z;
    auto forwardScale = std::fmax(std::fmax(std::fabs(fx), std::fabs(fy)), std::fabs(fz));
    auto upScale = std::fmax(std::fmax(std::fabs(camera.up.x), std::fabs(camera.up.y)), std::fabs(camera.up.z));
    if (!std::isfinite(forwardScale) || !std::isfinite(upScale) || forwardScale == 0.0 || upScale == 0.0) return false;
    fx /= forwardScale;
    fy /= forwardScale;
    fz /= forwardScale;
    auto forwardLength = std::hypot(fx, fy, fz);
    auto ux = static_cast<double>(camera.up.x) / upScale;
    auto uy = static_cast<double>(camera.up.y) / upScale;
    auto uz = static_cast<double>(camera.up.z) / upScale;
    auto upLength = std::hypot(ux, uy, uz);
    fx /= forwardLength;
    fy /= forwardLength;
    fz /= forwardLength;
    ux /= upLength;
    uy /= upLength;
    uz /= upLength;
    return std::hypot(fy * uz - fz * uy, fz * ux - fx * uz, fx * uy - fy * ux) > 1.0e-6;
}

bool valid(const Object* object) noexcept
{
    if (!object || static_cast<uint8_t>(object->type()) > static_cast<uint8_t>(Type::Route) || !std::isfinite(object->style.width) || object->style.width < 0.0f || !std::isfinite(object->style.radius) || object->style.radius <= 0.0f || object->style.dashCount > Style::DashLimit || !std::isfinite(object->style.dashOffset) || !std::isfinite(object->opacity) || object->opacity < 0.0f || object->opacity > 1.0f || !std::isfinite(object->progress) || object->progress < 0.0f || object->progress > 1.0f) {
        return false;
    }
    auto dashVisible = !object->style.dashCount;
    for (auto i = 0u; i < object->style.dashCount; i++) {
        if (!std::isfinite(object->style.dash[i]) || object->style.dash[i] < 0.0f) return false;
        if (object->style.dash[i] > 0.0f) dashVisible = true;
    }
    if (!dashVisible) return false;
    if (!_affine(object->model)) return false;
    switch (object->type()) {
        case Type::Line: {
            auto value = static_cast<const Line*>(object);
            return _finite(value->from) && _finite(value->to);
        }
        case Type::Arrow: {
            auto value = static_cast<const Arrow*>(object);
            return _finite(value->from) && _finite(value->to) && std::isfinite(value->tail) && value->tail >= 0.0f && std::isfinite(value->tip) && value->tip >= 0.0f;
        }
        case Type::Point: return _finite(static_cast<const Point*>(object)->point);
        case Type::Text: {
            auto value = static_cast<const Text*>(object);
            return value->text() && _finite(value->point) && std::isfinite(value->size)
                   && value->size > 0.0f && _finite(value->align)
                   && (value->orientation == TextOrientation::Billboard
                       || value->orientation == TextOrientation::Plane)
                   && static_cast<uint8_t>(value->role)
                          <= static_cast<uint8_t>(TextRole::Code);
        }
        case Type::Vector: {
            auto value = static_cast<const Vector*>(object);
            return _finite(value->value) && _finite(value->origin) && std::isfinite(value->tail) && value->tail >= 0.0f && std::isfinite(value->tip) && value->tip >= 0.0f;
        }
        case Type::Space: {
            auto value = static_cast<const Space*>(object);
            return _finite(value->x) && _finite(value->y) && _finite(value->z)
                   && (value->numberMode == NumberMode::Fixed || value->numberMode == NumberMode::Relative)
                   && std::isfinite(value->numberSize) && value->numberSize > 0.0f;
        }
        case Type::Circle: {
            auto value = static_cast<const Circle*>(object);
            return _finite(value->center) && std::isfinite(value->radius) && value->radius > 0.0f;
        }
        case Type::Polygon: {
            auto value = static_cast<const Polygon*>(object);
            if (!value->points() || value->count() < 3) return false;
            for (auto i = 0u; i < value->count(); i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
        case Type::Plot: {
            auto value = static_cast<const Plot*>(object);
            if (!value->points() || value->count() < 2) return false;
            for (auto i = 0u; i < value->count(); i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
        case Type::Route: {
            auto value = static_cast<const DirectedRoute*>(object);
            if (!value->points() || value->count() < 2 || !std::isfinite(value->tail)
                || value->tail < 0.0f || !std::isfinite(value->tip) || value->tip < 0.0f) {
                return false;
            }
            for (auto i = 0u; i < value->count(); i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
        case Type::Path: {
            auto value = static_cast<const Path*>(object);
            if (!value->points() || value->count() < (value->closed() ? 3u : 2u)) return false;
            for (auto i = 0u; i < value->count(); i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
        case Type::Curve: {
            auto value = static_cast<const Curve*>(object);
            if (!value->points() || value->count() < 2u) return false;
            for (auto i = 0u; i < value->count(); i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
        case Type::Ruler: {
            auto value = static_cast<const Ruler*>(object);
            return _finite(value->from) && _finite(value->to) && (value->to - value->from).length() > 1e-7f && std::isfinite(value->step) && value->step > 0.0f && std::isfinite(value->tick) && value->tick > 0.0f;
        }
        case Type::Svg: {
            auto value = static_cast<const Svg*>(object);
            return value->path() && _finite(value->center) && std::isfinite(value->width) && value->width > 0.0f;
        }
        case Type::Image: {
            auto value = static_cast<const Image*>(object);
            return value->pixels() && value->pixelWidth() && value->pixelHeight() && _finite(value->center) && std::isfinite(value->width) && value->width > 0.0f && (value->filter == ImageFilter::Bilinear || value->filter == ImageFilter::Nearest);
        }
        case Type::Cell: {
            auto value = static_cast<const Cell*>(object);
            auto frames = sampleFrames(value);
            auto duration = sampleDuration(value);
            return value->colors() && value->columns() && value->rows()
                   && value->rows() <= 16384u / value->columns()
                   && frames && std::isfinite(duration) && duration >= 0.0f
                   && (frames == 1u) == (duration == 0.0f)
                   && _finite(value->origin) && std::isfinite(value->depth)
                   && value->depth > 0.0f
                   && (value->mode == CellMode::Full || value->mode == CellMode::Padd)
                   && std::isfinite(value->padding) && value->padding >= 0.0f
                   && value->padding < 0.5f;
        }
        case Type::Group: return true;
        case Type::Rectangle: {
            auto value = static_cast<const Rectangle*>(object);
            return _finite(value->center) && _finite(value->size) && value->size.x > 0.0f && value->size.y > 0.0f
                   && std::isfinite(value->corner) && value->corner >= 0.0f
                   && value->corner <= std::fmin(value->size.x, value->size.y) * 0.5f;
        }
        case Type::Connector: {
            auto value = static_cast<const Connector*>(object);
            return _identity(value->model) && value->from() && value->to() && value->from() != value->to()
                   && std::isfinite(value->padding) && value->padding >= 0.0f
                   && std::isfinite(value->tail) && value->tail >= 0.0f
                   && std::isfinite(value->tip) && value->tip >= 0.0f;
        }
        case Type::SurfaceMesh: {
            auto value = static_cast<const SurfaceMesh*>(object);
            if (!value->points() || value->columns() < 2u || value->rows() < 2u
                || value->rows() > 65536u / value->columns()
                || (value->mode != SurfaceMode::Solid && value->mode != SurfaceMode::Mesh
                    && value->mode != SurfaceMode::SolidMesh)) {
                return false;
            }
            auto count = value->columns() * value->rows();
            for (auto i = 0u; i < count; i++) {
                if (!_finite(value->points()[i])) return false;
            }
            return true;
        }
    }
    return false;
}

static float _clamp(float value)
{
    if (value < 0.0f) return 0.0f;
    if (value > 1.0f) return 1.0f;
    return value;
}

static uint8_t _lerp(uint8_t from, uint8_t to, float progress)
{
    auto value = static_cast<float>(from) + (static_cast<float>(to) - static_cast<float>(from)) * progress;
    return static_cast<uint8_t>(value + 0.5f);
}

static Color _lerp(const Color& from, const Color& to, float progress)
{
    return {
        _lerp(from.r, to.r, progress),
        _lerp(from.g, to.g, progress),
        _lerp(from.b, to.b, progress),
        _lerp(from.a, to.a, progress)};
}

static Mat4 _lerp(const Mat4& from, const Mat4& to, float progress)
{
    Mat4 result;
    for (auto i = 0; i < 16; i++) {
        result.e[i] = static_cast<float>(static_cast<double>(from.e[i]) + (static_cast<double>(to.e[i]) - from.e[i]) * progress);
    }
    return result;
}

struct Rotation
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    double w = 1.0;
};

struct Vector64
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

static bool _normalize(double x, double y, double z, Vector64& output)
{
    auto scale = std::fmax(std::fmax(std::fabs(x), std::fabs(y)), std::fabs(z));
    if (!std::isfinite(scale) || scale == 0.0) return false;
    x /= scale;
    y /= scale;
    z /= scale;
    auto length = std::hypot(x, y, z);
    if (!std::isfinite(length) || length == 0.0) return false;
    output = {x / length, y / length, z / length};
    return true;
}

static bool _normalize(Rotation& value)
{
    auto length = std::sqrt(value.x * value.x + value.y * value.y
                            + value.z * value.z + value.w * value.w);
    if (!std::isfinite(length) || length == 0.0) return false;
    value = {value.x / length, value.y / length, value.z / length, value.w / length};
    return true;
}

static bool _frame(const Camera& camera, Rotation& rotation, double& distance)
{
    auto dx = static_cast<double>(camera.target.x) - camera.eye.x;
    auto dy = static_cast<double>(camera.target.y) - camera.eye.y;
    auto dz = static_cast<double>(camera.target.z) - camera.eye.z;
    Vector64 forward;
    Vector64 sourceUp;
    if (!_normalize(dx, dy, dz, forward)
        || !_normalize(camera.up.x, camera.up.y, camera.up.z, sourceUp)) {
        return false;
    }
    Vector64 right;
    if (!_normalize(forward.y * sourceUp.z - forward.z * sourceUp.y,
                    forward.z * sourceUp.x - forward.x * sourceUp.z,
                    forward.x * sourceUp.y - forward.y * sourceUp.x, right)) {
        return false;
    }
    Vector64 up;
    if (!_normalize(right.y * forward.z - right.z * forward.y,
                    right.z * forward.x - right.x * forward.z,
                    right.x * forward.y - right.y * forward.x, up)) {
        return false;
    }
    auto m00 = right.x;
    auto m01 = up.x;
    auto m02 = -forward.x;
    auto m10 = right.y;
    auto m11 = up.y;
    auto m12 = -forward.y;
    auto m20 = right.z;
    auto m21 = up.z;
    auto m22 = -forward.z;
    auto trace = m00 + m11 + m22;
    if (trace > 0.0) {
        auto scale = std::sqrt(trace + 1.0) * 2.0;
        rotation = {(m21 - m12) / scale, (m02 - m20) / scale,
                    (m10 - m01) / scale, scale * 0.25};
    } else if (m00 > m11 && m00 > m22) {
        auto scale = std::sqrt(1.0 + m00 - m11 - m22) * 2.0;
        rotation = {scale * 0.25, (m01 + m10) / scale,
                    (m02 + m20) / scale, (m21 - m12) / scale};
    } else if (m11 > m22) {
        auto scale = std::sqrt(1.0 + m11 - m00 - m22) * 2.0;
        rotation = {(m01 + m10) / scale, scale * 0.25,
                    (m12 + m21) / scale, (m02 - m20) / scale};
    } else {
        auto scale = std::sqrt(1.0 + m22 - m00 - m11) * 2.0;
        rotation = {(m02 + m20) / scale, (m12 + m21) / scale,
                    scale * 0.25, (m10 - m01) / scale};
    }
    distance = std::hypot(dx, dy, dz);
    return std::isfinite(distance) && distance > 0.0 && _normalize(rotation);
}

static bool _lerp(const Rotation& from, const Rotation& to, float progress, Rotation& output)
{
    auto destination = to;
    auto cosine = from.x * to.x + from.y * to.y + from.z * to.z + from.w * to.w;
    if (cosine < 0.0) {
        destination = {-to.x, -to.y, -to.z, -to.w};
        cosine = -cosine;
    }
    cosine = std::fmax(-1.0, std::fmin(1.0, cosine));
    if (cosine > 0.9995) {
        output = {from.x + (destination.x - from.x) * progress,
                  from.y + (destination.y - from.y) * progress,
                  from.z + (destination.z - from.z) * progress,
                  from.w + (destination.w - from.w) * progress};
        return _normalize(output);
    }
    auto angle = std::acos(cosine);
    auto sine = std::sin(angle);
    if (!std::isfinite(sine) || sine == 0.0) return false;
    auto fromWeight = std::sin((1.0 - progress) * angle) / sine;
    auto toWeight = std::sin(progress * angle) / sine;
    output = {from.x * fromWeight + destination.x * toWeight,
              from.y * fromWeight + destination.y * toWeight,
              from.z * fromWeight + destination.z * toWeight,
              from.w * fromWeight + destination.w * toWeight};
    return _normalize(output);
}

static bool _rotate(const Rotation& rotation, const Vector64& value, Vector64& output)
{
    auto tx = 2.0 * (rotation.y * value.z - rotation.z * value.y);
    auto ty = 2.0 * (rotation.z * value.x - rotation.x * value.z);
    auto tz = 2.0 * (rotation.x * value.y - rotation.y * value.x);
    return _normalize(value.x + rotation.w * tx + rotation.y * tz - rotation.z * ty,
                      value.y + rotation.w * ty + rotation.z * tx - rotation.x * tz,
                      value.z + rotation.w * tz + rotation.x * ty - rotation.y * tx,
                      output);
}

static bool _narrow(const Vector64& value, Vec3& output)
{
    auto limit = static_cast<double>(std::numeric_limits<float>::max());
    if (!std::isfinite(value.x) || !std::isfinite(value.y) || !std::isfinite(value.z)
        || std::fabs(value.x) > limit || std::fabs(value.y) > limit || std::fabs(value.z) > limit) {
        return false;
    }
    output = {static_cast<float>(value.x), static_cast<float>(value.y), static_cast<float>(value.z)};
    return true;
}

static bool _animationSafe(const Camera& camera)
{
    Rotation rotation;
    double distance;
    if (!_frame(camera, rotation, distance)) return false;
    auto limit = static_cast<double>(std::numeric_limits<float>::max());
    return std::fabs(static_cast<double>(camera.target.x)) + distance <= limit
           && std::fabs(static_cast<double>(camera.target.y)) + distance <= limit
           && std::fabs(static_cast<double>(camera.target.z)) + distance <= limit;
}

static double _spacing(float value)
{
    value = std::fabs(value);
    auto adjacent = std::nextafter(value, std::numeric_limits<float>::infinity());
    if (std::isfinite(adjacent)) return static_cast<double>(adjacent) - value;
    return static_cast<double>(value) - std::nextafter(value, 0.0f);
}

static bool _samePose(const Camera& from, const Camera& to)
{
    return from.eye.x == to.eye.x && from.eye.y == to.eye.y && from.eye.z == to.eye.z
           && from.target.x == to.target.x && from.target.y == to.target.y
           && from.target.z == to.target.z && from.up.x == to.up.x && from.up.y == to.up.y
           && from.up.z == to.up.z;
}

static bool _poseSafe(const Camera& from, const Camera& to)
{
    if (_samePose(from, to)) return true;
    Rotation fromRotation;
    Rotation toRotation;
    double fromDistance;
    double toDistance;
    if (!_frame(from, fromRotation, fromDistance) || !_frame(to, toRotation, toDistance)) return false;
    auto envelope = [](const Camera& camera, double distance) {
        return std::fmax(std::fmax(std::fabs(static_cast<double>(camera.target.x)) + distance,
                                   std::fabs(static_cast<double>(camera.target.y)) + distance),
                         std::fabs(static_cast<double>(camera.target.z)) + distance);
    };
    auto maximum = std::fmax(envelope(from, fromDistance), envelope(to, toDistance));
    auto upper = static_cast<float>(maximum);
    if (static_cast<double>(upper) < maximum) {
        upper = std::nextafter(upper, std::numeric_limits<float>::infinity());
    }
    constexpr auto precisionMargin = 6.928203230275509;  // 4 * sqrt(3)
    return std::fmin(fromDistance, toDistance) > precisionMargin * _spacing(upper);
}

static bool _planesSafe(const Camera& from, const Camera& to)
{
    if (from.near == to.near && from.far == to.far) return true;
    auto maximum = std::fmax(std::fmax(from.near, from.far), std::fmax(to.near, to.far));
    auto fromGap = static_cast<double>(from.far) - from.near;
    auto toGap = static_cast<double>(to.far) - to.near;
    return std::fmin(fromGap, toGap) > _spacing(maximum);
}

static bool _lerp(const Camera& from, const Camera& to, float progress, Camera& camera)
{
    if (progress <= 0.0f) {
        camera = from;
        return true;
    }
    if (progress >= 1.0f) {
        camera = to;
        return true;
    }
    camera = from;
    if (!_samePose(from, to)) {
        Rotation fromRotation;
        Rotation toRotation;
        double fromDistance;
        double toDistance;
        if (!_frame(from, fromRotation, fromDistance) || !_frame(to, toRotation, toDistance)) return false;
        Rotation rotation;
        if (!_lerp(fromRotation, toRotation, progress, rotation)) return false;
        Vector64 backward;
        Vector64 up;
        if (!_rotate(rotation, {0.0, 0.0, 1.0}, backward)
            || !_rotate(rotation, {0.0, 1.0, 0.0}, up)) {
            return false;
        }
        auto target = Vector64{
            static_cast<double>(from.target.x) + (static_cast<double>(to.target.x) - from.target.x) * progress,
            static_cast<double>(from.target.y) + (static_cast<double>(to.target.y) - from.target.y) * progress,
            static_cast<double>(from.target.z) + (static_cast<double>(to.target.z) - from.target.z) * progress};
        auto distance = fromDistance + (toDistance - fromDistance) * progress;
        if (!_narrow(target, camera.target)
            || !_narrow({target.x + backward.x * distance,
                         target.y + backward.y * distance,
                         target.z + backward.z * distance}, camera.eye)
            || !_narrow(up, camera.up)) {
            return false;
        }
    }
    camera.fov = static_cast<float>(static_cast<double>(from.fov) + (static_cast<double>(to.fov) - from.fov) * progress);
    camera.orthoHeight = static_cast<float>(static_cast<double>(from.orthoHeight) + (static_cast<double>(to.orthoHeight) - from.orthoHeight) * progress);
    camera.near = static_cast<float>(static_cast<double>(from.near) + (static_cast<double>(to.near) - from.near) * progress);
    camera.far = static_cast<float>(static_cast<double>(from.far) + (static_cast<double>(to.far) - from.far) * progress);
    return true;
}

static VisualState _state(const Object* object)
{
    VisualState state;
    state.model = object->model;
    state.stroke = object->style.stroke;
    state.fill = object->style.fill;
    state.gradientEnd = object->style.gradientEnd;
    state.width = object->style.width;
    state.radius = object->style.radius;
    state.dashOffset = object->style.dashOffset;
    switch (object->type()) {
        case Type::Arrow: {
            auto directed = static_cast<const Arrow*>(object);
            state.markerTail = directed->tail;
            state.markerTip = directed->tip;
            break;
        }
        case Type::Vector: {
            auto directed = static_cast<const Vector*>(object);
            state.markerTail = directed->tail;
            state.markerTip = directed->tip;
            break;
        }
        case Type::Connector: {
            auto directed = static_cast<const Connector*>(object);
            state.markerTail = directed->tail;
            state.markerTip = directed->tip;
            break;
        }
        case Type::Route: {
            auto directed = static_cast<const DirectedRoute*>(object);
            state.markerTail = directed->tail;
            state.markerTip = directed->tip;
            break;
        }
        default: break;
    }
    state.opacity = object->opacity;
    state.progress = object->progress;
    state.fillProgress = 1.0f;
    state.pixelScale = 1.0f;
    state.gradient = object->style.gradient;
    state.direction = DrawDirection::Forward;
    state.morph = nullptr;
    state.morphProgress = 0.0f;
    return state;
}

static void _state(Object* object, const VisualState& state)
{
    object->style.stroke = state.stroke;
    object->style.fill = state.fill;
    object->style.gradientEnd = state.gradientEnd;
    object->style.width = state.width;
    object->style.radius = state.radius;
    object->style.dashOffset = state.dashOffset;
    switch (object->type()) {
        case Type::Arrow: {
            auto directed = static_cast<Arrow*>(object);
            directed->tail = state.markerTail;
            directed->tip = state.markerTip;
            break;
        }
        case Type::Vector: {
            auto directed = static_cast<Vector*>(object);
            directed->tail = state.markerTail;
            directed->tip = state.markerTip;
            break;
        }
        case Type::Connector: {
            auto directed = static_cast<Connector*>(object);
            directed->tail = state.markerTail;
            directed->tip = state.markerTip;
            break;
        }
        case Type::Route: {
            auto directed = static_cast<DirectedRoute*>(object);
            directed->tail = state.markerTail;
            directed->tip = state.markerTip;
            break;
        }
        default: break;
    }
    object->style.gradient = state.gradient;
    object->opacity = state.opacity;
    object->progress = state.progress;
    object->model = state.model;
}

static void _inherit(ObjectEntry& entry, Clip* clips, uint32_t count,
                     const Style& source, bool inheritColor, bool inheritGradient)
{
    auto authoredStroke = entry.object->style.stroke;
    auto authoredFill = entry.object->style.fill;
    auto authoredGradientEnd = entry.object->style.gradientEnd;
    auto authoredGradient = entry.object->style.gradient;
    if (inheritColor) {
        entry.object->style.stroke = source.stroke;
        entry.object->style.fill = source.fill;
        if (_equal(entry.base.stroke, authoredStroke)) entry.base.stroke = source.stroke;
        if (_equal(entry.base.fill, authoredFill)) entry.base.fill = source.fill;
    }
    if (inheritGradient) {
        entry.object->style.gradient = source.gradient;
        entry.object->style.gradientEnd = source.gradientEnd;
        if (entry.base.gradient == authoredGradient) entry.base.gradient = source.gradient;
        if (_equal(entry.base.gradientEnd, authoredGradientEnd)) {
            entry.base.gradientEnd = source.gradientEnd;
        }
    }
    for (auto i = 0u; i < count; i++) {
        auto& clip = clips[i];
        if (clip.object != entry.object) continue;
        if (inheritColor) {
            if (_equal(clip.from.stroke, authoredStroke)) clip.from.stroke = source.stroke;
            if (_equal(clip.to.stroke, authoredStroke)) clip.to.stroke = source.stroke;
            if (_equal(clip.from.fill, authoredFill)) clip.from.fill = source.fill;
            if (_equal(clip.to.fill, authoredFill)) clip.to.fill = source.fill;
        }
        if (inheritGradient) {
            if (clip.from.gradient == authoredGradient) clip.from.gradient = source.gradient;
            if (clip.to.gradient == authoredGradient) clip.to.gradient = source.gradient;
            if (_equal(clip.from.gradientEnd, authoredGradientEnd)) {
                clip.from.gradientEnd = source.gradientEnd;
            }
            if (_equal(clip.to.gradientEnd, authoredGradientEnd)) {
                clip.to.gradientEnd = source.gradientEnd;
            }
        }
    }
    entry.fingerprint = fingerprint(entry.object);
}

static VisualState _lerp(const VisualState& from, const VisualState& to, float progress)
{
    auto bounded = _clamp(progress);
    VisualState state;
    state.model = _lerp(from.model, to.model, progress);
    state.stroke = _lerp(from.stroke, to.stroke, bounded);
    state.fill = _lerp(from.fill, to.fill, bounded);
    state.gradientEnd = _lerp(from.gradientEnd, to.gradientEnd, bounded);
    state.width = static_cast<float>(static_cast<double>(from.width) + (static_cast<double>(to.width) - from.width) * bounded);
    state.radius = static_cast<float>(static_cast<double>(from.radius) + (static_cast<double>(to.radius) - from.radius) * bounded);
    state.dashOffset = static_cast<float>(static_cast<double>(from.dashOffset) + (static_cast<double>(to.dashOffset) - from.dashOffset) * bounded);
    state.markerTail = static_cast<float>(static_cast<double>(from.markerTail) + (static_cast<double>(to.markerTail) - from.markerTail) * bounded);
    state.markerTip = static_cast<float>(static_cast<double>(from.markerTip) + (static_cast<double>(to.markerTip) - from.markerTip) * bounded);
    state.opacity = static_cast<float>(static_cast<double>(from.opacity) + (static_cast<double>(to.opacity) - from.opacity) * bounded);
    state.progress = static_cast<float>(static_cast<double>(from.progress) + (static_cast<double>(to.progress) - from.progress) * bounded);
    state.fillProgress = static_cast<float>(static_cast<double>(from.fillProgress) + (static_cast<double>(to.fillProgress) - from.fillProgress) * bounded);
    state.pixelScale = static_cast<float>(static_cast<double>(from.pixelScale) + (static_cast<double>(to.pixelScale) - from.pixelScale) * progress);
    if (state.pixelScale < 0.0f) state.pixelScale = 0.0f;
    state.gradient = bounded < 0.5f ? from.gradient : to.gradient;
    state.traceFill = bounded < 1.0f ? from.traceFill : to.traceFill;
    state.direction = bounded < 1.0f ? from.direction : to.direction;
    state.morph = nullptr;
    state.morphProgress = 0.0f;
    return state;
}

SceneSequence::~SceneSequence()
{
    if (owned) {
        for (auto i = 0u; i < count; i++)
            delete stages[i].scene;
    }
    if (transitions) {
        for (auto i = 0u; i + 1u < count; i++)
            delete[] transitions[i].matches;
    }
    delete[] stages;
    delete[] transitions;
}

StyleGroup::Impl::~Impl()
{
    delete[] members;
}

bool StyleGroup::Impl::grow(uint32_t amount) noexcept
{
    if (amount > UINT32_MAX - count) return false;
    auto required = count + amount;
    if (required <= capacity) return true;
    auto next = capacity ? capacity * 2u : 4u;
    if (next < capacity || next < required) next = required;
    auto grown = new (std::nothrow) StyleMember[next];
    if (!grown) return false;
    for (auto i = 0u; i < count; i++)
        grown[i] = members[i];
    delete[] members;
    members = grown;
    capacity = next;
    return true;
}

Scene::Impl::~Impl()
{
    for (auto i = 0u; i < objectCnt; i++) {
        if (objects[i].object->parent()) objects[i].object = nullptr;
    }
    for (auto i = 0u; i < objectCnt; i++)
        delete objects[i].object;
    delete[] objects;
    delete[] clips;
    delete[] cameras;
    for (auto i = 0u; i < viewportCnt; i++)
        delete viewports[i].scene;
    delete[] viewports;
    delete[] styleGroups;
    delete sequence;
    for (auto font : themeFonts)
        delete[] font;
}

bool Scene::Impl::assign(const Theme& theme) noexcept
{
    const char* names[] = {
        theme.h1.font,
        theme.h2.font,
        theme.h3.font,
        theme.text.font,
        theme.code.font,
    };
    char* copies[5] = {};
    for (auto i = 0u; i < 5u; i++) {
        copies[i] = _duplicate(names[i]);
        if (copies[i]) continue;
        for (auto copy : copies)
            delete[] copy;
        return false;
    }
    for (auto font : themeFonts)
        delete[] font;
    for (auto i = 0u; i < 5u; i++)
        themeFonts[i] = copies[i];
    sceneTheme = theme;
    sceneTheme.h1.font = themeFonts[0];
    sceneTheme.h2.font = themeFonts[1];
    sceneTheme.h3.font = themeFonts[2];
    sceneTheme.text.font = themeFonts[3];
    sceneTheme.code.font = themeFonts[4];
    cfg.background = theme.background;
    colorCursor = 0u;
    return true;
}

bool Scene::Impl::growObjects(uint32_t count) noexcept
{
    if (count > UINT32_MAX - objectCnt) return false;
    auto required = objectCnt + count;
    if (required <= objectCap) return true;
    auto capacity = objectCap ? objectCap * 2u : 8u;
    if (capacity < objectCap) capacity = required;
    while (capacity < required) {
        if (capacity > UINT32_MAX / 2u) {
            capacity = required;
            break;
        }
        capacity *= 2u;
    }
    auto grown = new (std::nothrow) ObjectEntry[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < objectCnt; i++)
        grown[i] = objects[i];
    delete[] objects;
    objects = grown;
    objectCap = capacity;
    return true;
}

bool Scene::Impl::growClips(uint32_t count) noexcept
{
    if (count > UINT32_MAX - clipCnt) return false;
    auto required = clipCnt + count;
    if (required <= clipCap) return true;
    auto capacity = clipCap ? clipCap * 2 : 16;
    if (capacity < clipCap) capacity = required;
    while (capacity < required) {
        if (capacity > UINT32_MAX / 2u) {
            capacity = required;
            break;
        }
        capacity *= 2;
    }
    auto grown = new (std::nothrow) Clip[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < clipCnt; i++)
        grown[i] = clips[i];
    delete[] clips;
    clips = grown;
    clipCap = capacity;
    return true;
}

bool Scene::Impl::growCameras() noexcept
{
    if (cameraCnt < cameraCap) return true;
    auto capacity = cameraCap ? cameraCap * 2u : 4u;
    if (capacity < cameraCap) return false;
    auto grown = new (std::nothrow) CameraClip[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < cameraCnt; i++)
        grown[i] = cameras[i];
    delete[] cameras;
    cameras = grown;
    cameraCap = capacity;
    return true;
}

bool Scene::Impl::growViewports() noexcept
{
    if (viewportCnt < viewportCap) return true;
    auto capacity = viewportCap ? viewportCap * 2u : 4u;
    if (capacity < viewportCap || capacity > MAX_VIEWPORTS) capacity = MAX_VIEWPORTS;
    if (capacity <= viewportCnt) return false;
    auto grown = new (std::nothrow) ViewportEntry[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < viewportCnt; i++)
        grown[i] = viewports[i];
    delete[] viewports;
    viewports = grown;
    viewportCap = capacity;
    return true;
}

bool Scene::Impl::growStyleGroups() noexcept
{
    if (styleGroupCnt < styleGroupCap) return true;
    auto capacity = styleGroupCap ? styleGroupCap * 2u : 4u;
    if (capacity < styleGroupCap) return false;
    auto grown = new (std::nothrow) StyleGroup*[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < styleGroupCnt; i++)
        grown[i] = styleGroups[i];
    delete[] styleGroups;
    styleGroups = grown;
    styleGroupCap = capacity;
    return true;
}

ObjectEntry* Scene::Impl::entry(const Object* object) const noexcept
{
    for (auto i = 0u; i < objectCnt; i++) {
        if (objects[i].object == object) return objects + i;
    }
    return nullptr;
}

bool Scene::Impl::sample(const ObjectEntry& entry, float time, VisualState& state) const noexcept
{
    if (time < entry.born) return false;
    if (entry.dead >= 0.0f && time >= entry.dead) return false;

    state = entry.base;
    for (auto i = 0u; i < clipCnt; i++) {
        auto& clip = clips[i];
        if (clip.object != entry.object || time < clip.begin) continue;
        if (time >= clip.end) {
            state = clip.kind == AnimationKind::Indicate ? clip.from : clip.to;
            continue;
        }
        auto progress = (time - clip.begin) / (clip.end - clip.begin);
        auto eased = ease(clip.curve, progress);
        if (clip.kind == AnimationKind::Indicate) eased = std::sin(3.14159265359f * _clamp(eased));
        state = _lerp(clip.from, clip.to, eased);
        if (clip.kind == AnimationKind::DrawBorderThenFill) {
            constexpr auto BorderPhase = 2.0f / 3.0f;
            state.progress = _clamp(eased / BorderPhase);
            state.fillProgress = _clamp((eased - BorderPhase) / (1.0f - BorderPhase));
        }
        if (clip.kind == AnimationKind::Morph) {
            state.morph = clip.related;
            state.morphProgress = _clamp(eased);
        }
        break;
    }
    return true;
}

Result Scene::Impl::sample(float time, Camera& camera, CameraView& view) const noexcept
{
    if (!cameraCnt) {
        camera = cfg.camera;
        view = cfg.cameraView;
    } else {
        camera = initialCamera;
        view = initialView;
        for (auto i = 0u; i < cameraCnt; i++) {
            auto& clip = cameras[i];
            if (time < clip.begin) break;
            if (time >= clip.end) {
                camera = clip.to;
                view = clip.toView;
                continue;
            }
            auto progress = (time - clip.begin) / (clip.end - clip.begin);
            if (!_lerp(clip.from, clip.to, _clamp(ease(clip.curve, progress)), camera)) {
                return Result::InvalidArguments;
            }
            view = clip.fromView;
            if (clip.fromView == CameraView::TwoD && clip.toView == CameraView::ThreeD
                && progress > 0.0f) {
                camera.projection = clip.to.projection;
                view = clip.toView;
            } else if (clip.fromView == clip.toView && progress >= 0.5f) {
                camera.projection = clip.to.projection;
            }
            break;
        }
    }
    auto sampled = cfg;
    sampled.camera = camera;
    sampled.cameraView = view;
    if (!valid(sampled)) return Result::InvalidArguments;
    for (auto i = 0u; i < runtimeModifierCnt; i++) {
        auto& modifier = runtimeModifiers[i];
        if (!modifier.camera) continue;
        auto result = modifier.camera(time, camera, view, modifier.data);
        if (result != Result::Success) return result;
    }
    sampled.camera = camera;
    sampled.cameraView = view;
    return valid(sampled) ? Result::Success : Result::InvalidArguments;
}

Animation Animation::create(Object* target, DrawDirection direction) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Create;
    animation.direction = direction;
    return animation;
}

Animation Animation::uncreate(Object* target, DrawDirection direction) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Uncreate;
    animation.direction = direction;
    return animation;
}

Animation Animation::fillReveal(Object* target) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::FillReveal;
    return animation;
}

Animation Animation::drawBorderThenFill(Object* target, DrawDirection direction) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::DrawBorderThenFill;
    animation.direction = direction;
    return animation;
}

Animation Animation::write(Object* target, DrawDirection direction) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Write;
    animation.direction = direction;
    return animation;
}

Animation Animation::fade(Object* target, float opacity) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Fade;
    animation.value = _clamp(opacity);
    return animation;
}

Animation Animation::fadeIn(Object* target, const Vec3& shift, float scale) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::FadeIn;
    animation.offset = shift;
    animation.scale = scale;
    return animation;
}

Animation Animation::fadeOut(Object* target, const Vec3& shift, float scale) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::FadeOut;
    animation.offset = shift;
    animation.scale = scale;
    return animation;
}

Animation Animation::growFromCenter(Object* target) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Grow;
    return animation;
}

Animation Animation::growFromEdge(Object* target, GrowthEdge edge) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::GrowFromEdge;
    animation.growthEdge = edge;
    return animation;
}

Animation Animation::shrinkToCenter(Object* target) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Shrink;
    return animation;
}

Animation Animation::indicate(Object* target, Color color, float scale) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Indicate;
    animation.color = color;
    animation.scale = scale;
    return animation;
}

Animation Animation::morph(Object* source, Object* target) noexcept
{
    Animation animation;
    animation.target = source;
    animation.related = target;
    animation.kind = AnimationKind::Morph;
    return animation;
}

Animation Animation::replacementTransform(Object* source, Object* target) noexcept
{
    return morph(source, target);
}

Animation Animation::shift(Object* target, const Vec3& by) noexcept
{
    if (!target) return {};
    auto animation = transform(target, Mat4::translate(by) * target->model);
    return animation;
}

Animation Animation::transform(Object* target, const Mat4& model) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Transform;
    animation.model = model;
    return animation;
}

Animation Animation::stroke(Object* target, Color color) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Stroke;
    animation.color = color;
    return animation;
}

Animation Animation::fill(Object* target, Color color) noexcept
{
    Animation animation;
    animation.target = target;
    animation.kind = AnimationKind::Fill;
    animation.color = color;
    return animation;
}

static constexpr uint8_t TARGET_MODEL = 1u << 0u;
static constexpr uint8_t TARGET_OPACITY = 1u << 1u;
static constexpr uint8_t TARGET_STROKE = 1u << 2u;
static constexpr uint8_t TARGET_FILL = 1u << 3u;
static constexpr uint8_t TARGET_DASH_OFFSET = 1u << 4u;
static constexpr uint8_t TARGET_TAIL = 1u << 5u;
static constexpr uint8_t TARGET_TIP = 1u << 6u;

AnimationTarget AnimationTarget::from(Object* target) noexcept
{
    AnimationTarget state;
    state.target = target;
    if (!target) return state;
    state.targetModel = target->model;
    state.targetStroke = target->style.stroke;
    state.targetFill = target->style.fill;
    state.targetOpacity = target->opacity;
    state.targetDashOffset = target->style.dashOffset;
    auto sampled = _state(target);
    state.targetTail = sampled.markerTail;
    state.targetTip = sampled.markerTip;
    return state;
}

AnimationTarget& AnimationTarget::shift(const Vec3& by) noexcept
{
    targetModel = Mat4::translate(by) * targetModel;
    properties |= TARGET_MODEL;
    return *this;
}

AnimationTarget& AnimationTarget::transform(const Mat4& model) noexcept
{
    targetModel = model;
    properties |= TARGET_MODEL;
    return *this;
}

AnimationTarget& AnimationTarget::opacity(float value) noexcept
{
    targetOpacity = value;
    properties |= TARGET_OPACITY;
    return *this;
}

AnimationTarget& AnimationTarget::stroke(Color color) noexcept
{
    targetStroke = color;
    properties |= TARGET_STROKE;
    return *this;
}

AnimationTarget& AnimationTarget::fill(Color color) noexcept
{
    targetFill = color;
    properties |= TARGET_FILL;
    return *this;
}

AnimationTarget& AnimationTarget::dashOffset(float value) noexcept
{
    targetDashOffset = value;
    properties |= TARGET_DASH_OFFSET;
    return *this;
}

AnimationTarget& AnimationTarget::tail(float value) noexcept
{
    targetTail = value;
    properties |= TARGET_TAIL;
    return *this;
}

AnimationTarget& AnimationTarget::tip(float value) noexcept
{
    targetTip = value;
    properties |= TARGET_TIP;
    return *this;
}

StyleGroup::StyleGroup(Scene* scene, Color color) noexcept
{
    pImpl = new (std::nothrow) Impl;
    if (pImpl) {
        pImpl->scene = scene;
        pImpl->color = color;
    }
}

StyleGroup::~StyleGroup()
{
    delete pImpl;
}

Color StyleGroup::color() const noexcept
{
    return pImpl ? pImpl->color : Color{};
}

uint32_t StyleGroup::count() const noexcept
{
    return pImpl ? pImpl->count : 0u;
}

Object* StyleGroup::objectAt(uint32_t index) const noexcept
{
    return pImpl && index < pImpl->count ? pImpl->members[index].object : nullptr;
}

StyleChannel StyleGroup::channelAt(uint32_t index) const noexcept
{
    return pImpl && index < pImpl->count ? pImpl->members[index].channel : StyleChannel::Both;
}

Scene::Scene(const Config& config) noexcept
{
    pImpl = new (std::nothrow) Impl;
    if (pImpl) {
        pImpl->cfg = config;
        pImpl->sceneTheme.background = config.background;
        pImpl->initialCamera = config.camera;
        pImpl->initialView = config.cameraView;
    }
}

Scene::~Scene()
{
    if (pImpl) {
        for (auto i = 0u; i < pImpl->styleGroupCnt; i++)
            delete pImpl->styleGroups[i];
    }
    delete pImpl;
}

Scene* Scene::gen(const Config& config) noexcept
{
    if (!valid(config)) return nullptr;
    auto scene = new (std::nothrow) Scene(config);
    if (!scene || scene->pImpl) return scene;
    delete scene;
    return nullptr;
}

Result Scene::theme(const Theme& theme) noexcept
{
    if (!pImpl || !_valid(theme)) return Result::InvalidArguments;
    if (pImpl->owner || pImpl->objectCnt || pImpl->viewportCnt || pImpl->sequence
        || pImpl->definitionsSealed) {
        return Result::InsufficientCondition;
    }
    if (!pImpl->assign(theme)) return Result::OutOfMemory;
    return Result::Success;
}

const Theme& Scene::theme() const noexcept
{
    if (pImpl) return pImpl->sceneTheme;
    static const Theme fallback;
    return fallback;
}

static bool _treeCount(Object* object, uint32_t& count, uint32_t depth)
{
    if (!object || depth > MAX_OBJECT_DEPTH || count >= MAX_OBJECTS) return false;
    count++;
    for (auto i = 0u; i < object->childCount(); i++) {
        if (!_treeCount(object->childAt(i), count, depth + 1u)) return false;
    }
    return true;
}

static void _tree(Object* object, Object** objects, uint32_t& count)
{
    objects[count++] = object;
    for (auto i = 0u; i < object->childCount(); i++)
        _tree(object->childAt(i), objects, count);
}

static bool _contains(Object* const* objects, uint32_t count, const Object* object)
{
    for (auto i = 0u; i < count; i++) {
        if (objects[i] == object) return true;
    }
    return false;
}

static const Object* _parent(const Object* object, const Object* root, const Object* proposedParent)
{
    if (object == root) return proposedParent;
    return object ? object->parent() : nullptr;
}

static bool _inside(const Object* object, const Object* ancestor, const Object* root = nullptr,
                    const Object* proposedParent = nullptr)
{
    for (auto current = object; current; current = _parent(current, root, proposedParent)) {
        if (current == ancestor) return true;
    }
    return false;
}

static bool _connectorAncestors(const Connector* connector, const Object* root,
                                const Object* proposedParent)
{
    for (auto ancestor = _parent(connector, root, proposedParent); ancestor;
         ancestor = _parent(ancestor, root, proposedParent)) {
        if (_identity(ancestor->model)) continue;
        if (!_inside(connector->from(), ancestor, root, proposedParent)
            && !_inside(connector->to(), ancestor, root, proposedParent)) {
            return false;
        }
    }
    return true;
}

static bool _connectorTransform(const Object* object, const Object* target)
{
    if (object->type() == Type::Connector) {
        auto connector = static_cast<const Connector*>(object);
        if (!_inside(connector->from(), target) && !_inside(connector->to(), target)) return false;
    }
    for (auto i = 0u; i < object->childCount(); i++) {
        if (!_connectorTransform(object->childAt(i), target)) return false;
    }
    return true;
}

static bool _transformable(const Object* object)
{
    return object && object->type() != Type::Connector && _connectorTransform(object, object);
}

Result Scene::attach(Object* object, Object* parent) noexcept
{
    if (!pImpl || !object || object->objOwner || object->objParent) return Result::InvalidArguments;
    if (pImpl->owner) return Result::InsufficientCondition;
    auto depth = 0u;
    if (parent) {
        auto parentEntry = pImpl->entry(parent);
        if (parent->objOwner != this || !parentEntry || parentEntry->dead >= 0.0f) return Result::InvalidArguments;
        for (auto ancestor = parent; ancestor; ancestor = ancestor->parent()) {
            if (depth++ >= MAX_OBJECT_DEPTH) return Result::InsufficientCondition;
            auto ancestorEntry = pImpl->entry(ancestor);
            if (ancestor->objOwner != this || !ancestorEntry || ancestorEntry->dead >= 0.0f
                || !valid(ancestor) || ancestorEntry->fingerprint != fingerprint(ancestor)) {
                return Result::InvalidArguments;
            }
        }
    }

    auto count = 0u;
    if (!_treeCount(object, count, depth) || count > MAX_OBJECTS - pImpl->objectCnt) return Result::InsufficientCondition;
    auto tree = new (std::nothrow) Object*[count];
    if (!tree) return Result::OutOfMemory;
    auto index = 0u;
    _tree(object, tree, index);
    for (auto i = 0u; i < count; i++) {
        auto item = tree[i];
        if (!valid(item) || item->objOwner || pImpl->entry(item)) {
            delete[] tree;
            return Result::InvalidArguments;
        }
        auto tag = item->tag();
        if (!tag) continue;
        if (this->object(tag)) {
            delete[] tree;
            return Result::InvalidArguments;
        }
        for (auto j = 0u; j < i; j++) {
            auto previous = tree[j]->tag();
            if (previous && std::strcmp(previous, tag) == 0) {
                delete[] tree;
                return Result::InvalidArguments;
            }
        }
    }
    auto shaderSpan = 0.0f;
    for (auto i = 0u; i < count; i++) {
        auto span = sampleDuration(tree[i]);
        if (span > shaderSpan) shaderSpan = span;
    }
    auto nextCursor = pImpl->cursor;
    if (shaderSpan > 0.0f) {
        auto next = static_cast<double>(pImpl->cursor) + shaderSpan;
        if (!std::isfinite(next) || next > std::numeric_limits<float>::max()) {
            delete[] tree;
            return Result::InvalidArguments;
        }
        nextCursor = static_cast<float>(next);
        if (nextCursor <= pImpl->cursor) {
            delete[] tree;
            return Result::InvalidArguments;
        }
    }
    for (auto i = 0u; i < count; i++) {
        if (tree[i]->type() != Type::Connector) continue;
        auto connector = static_cast<Connector*>(tree[i]);
        Object* endpoints[2] = {connector->from(), connector->to()};
        for (auto endpoint : endpoints) {
            auto entry = pImpl->entry(endpoint);
            auto existing = endpoint && endpoint->objOwner == this && entry && entry->dead < 0.0f;
            if (!existing && !_contains(tree, count, endpoint)) {
                delete[] tree;
                return Result::InvalidArguments;
            }
        }
        if (!_connectorAncestors(connector, object, parent)) {
            delete[] tree;
            return Result::InvalidArguments;
        }
    }

    auto fonts = new (std::nothrow) char*[count]{};
    if (!fonts) {
        delete[] tree;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < count; i++) {
        if (tree[i]->type() != Type::Text) continue;
        auto text = static_cast<Text*>(tree[i]);
        if (text->font()) continue;
        auto& typography = _textTheme(pImpl->sceneTheme, text->role);
        fonts[i] = _duplicate(_textFont(typography, text));
        if (fonts[i]) continue;
        for (auto j = 0u; j < count; j++)
            delete[] fonts[j];
        delete[] fonts;
        delete[] tree;
        return Result::OutOfMemory;
    }
    if (!pImpl->growObjects(count)) {
        for (auto i = 0u; i < count; i++)
            delete[] fonts[i];
        delete[] fonts;
        delete[] tree;
        return Result::OutOfMemory;
    }

    auto colorCursor = pImpl->colorCursor;
    for (auto i = 0u; i < count; i++) {
        auto item = tree[i];
        if (item->type() == Type::Text) {
            auto text = static_cast<Text*>(item);
            auto& typography = _textTheme(pImpl->sceneTheme, text->role);
            if (fonts[i]) text->objFont = fonts[i];
            if (text->size == 28.0f) text->size = typography.size;
            if (!item->objColorAuthored && !_colorChanged(item)) {
                text->style.fill = typography.color;
                text->style.stroke.a = 0;
            }
            continue;
        }
        if (item->type() == Type::Space) {
            auto space = static_cast<Space*>(item);
            auto defaults = _defaultStyle(Type::Space);
            if (!item->objColorAuthored && _equal(space->style.stroke, defaults.stroke)) {
                space->style.stroke = pImpl->sceneTheme.axis.grid;
            }
            auto axes = AxisTheme{};
            if (_equal(space->axisX, axes.x)) space->axisX = pImpl->sceneTheme.axis.x;
            if (_equal(space->axisY, axes.y)) space->axisY = pImpl->sceneTheme.axis.y;
            if (_equal(space->axisZ, axes.z)) space->axisZ = pImpl->sceneTheme.axis.z;
            if (_equal(space->numberColor, axes.label)) {
                space->numberColor = pImpl->sceneTheme.axis.label;
            }
            continue;
        }
        if (_palette(item->type())) {
            auto defaults = _defaultStyle(item->type());
            if (!item->objWidthAuthored && item->style.width == defaults.width) {
                item->style.width = pImpl->sceneTheme.objectWidth;
            }
            if (!item->objGradientAuthored
                && (item->style.gradient != defaults.gradient
                    || !_equal(item->style.gradientEnd, defaults.gradientEnd))) {
                item->objGradientAuthored = true;
                item->objGradientEndAuthored =
                    !_equal(item->style.gradientEnd, defaults.gradientEnd);
            }
            if (!item->objGradientAuthored) {
                item->style.gradient = pImpl->sceneTheme.gradient;
                item->style.gradientEnd = pImpl->sceneTheme.endGradientStop;
                item->objThemeGradient = true;
            } else if (item->style.gradient && !item->objGradientEndAuthored) {
                item->style.gradientEnd = pImpl->sceneTheme.endGradientStop;
            }
        }
        if (!_palette(item->type()) || item->objColorAuthored || _colorChanged(item)) continue;
        auto color = pImpl->sceneTheme.objects[colorCursor];
        auto defaults = _defaultStyle(item->type());
        if (defaults.stroke.a) item->style.stroke = color;
        if (defaults.fill.a) item->style.fill = color;
        item->objThemeColor = true;
        colorCursor = (colorCursor + 1u) % pImpl->sceneTheme.objectCount;
    }
    pImpl->colorCursor = colorCursor;

    object->objParent = parent;
    for (auto i = 0u; i < count; i++) {
        auto item = tree[i];
        item->objId = pImpl->nextId++;
        item->objOwner = this;
        auto& entry = pImpl->objects[pImpl->objectCnt++];
        entry.object = item;
        entry.base = _state(item);
        entry.fingerprint = fingerprint(item);
        entry.born = pImpl->cursor;
    }
    if (shaderSpan > 0.0f) {
        pImpl->cursor = nextCursor;
        pImpl->definitionsSealed = true;
    }
    delete[] fonts;
    delete[] tree;
    return Result::Success;
}

Result Scene::add(Object* object) noexcept
{
    return attach(object, nullptr);
}

Result Scene::update(Object* object) noexcept
{
    if (!pImpl || !object) return Result::InvalidArguments;
    auto entry = pImpl->entry(object);
    if (!entry || object->objOwner != this || entry->dead >= 0.0f) return Result::InvalidArguments;
    if (pImpl->owner || pImpl->definitionsSealed) return Result::InsufficientCondition;
    if (!valid(object)) return Result::InvalidArguments;
    if (!_equal(entry->base.model, object->model) && !_transformable(object)) {
        return Result::InvalidArguments;
    }
    if (object->type() == Type::Connector) {
        auto connector = static_cast<Connector*>(object);
        auto from = pImpl->entry(connector->from());
        auto to = pImpl->entry(connector->to());
        if (!from || !to || from->dead >= 0.0f || to->dead >= 0.0f) return Result::InvalidArguments;
    }
    entry->base = _state(object);
    entry->fingerprint = fingerprint(object);
    return Result::Success;
}

static bool _valid(const Viewport& viewport)
{
    if (!std::isfinite(viewport.x) || !std::isfinite(viewport.y)
        || !std::isfinite(viewport.width) || !std::isfinite(viewport.height)) {
        return false;
    }
    if (viewport.x < 0.0f || viewport.y < 0.0f || viewport.width <= 0.0f || viewport.height <= 0.0f) {
        return false;
    }
    return viewport.x + viewport.width <= 1.0f && viewport.y + viewport.height <= 1.0f;
}

uint32_t Scene::depth(const Scene* scene) noexcept
{
    auto currentDepth = 1u;
    if (!scene) return currentDepth;
    for (auto i = 0u; i < scene->viewportCount(); i++) {
        auto child = depth(scene->sceneAt(i));
        if (child >= MAX_VIEWPORT_DEPTH) return child;
        if (child + 1u > currentDepth) currentDepth = child + 1u;
    }
    if (scene->pImpl && scene->pImpl->sequence) {
        auto sequence = scene->pImpl->sequence;
        for (auto i = 0u; i < sequence->count; i++) {
            auto child = depth(sequence->stages[i].scene);
            if (child >= MAX_VIEWPORT_DEPTH) return child;
            if (child + 1u > currentDepth) currentDepth = child + 1u;
        }
    }
    return currentDepth;
}

Result Scene::viewport(Scene* scene, const Viewport& viewport) noexcept
{
    if (!pImpl || !scene || !scene->pImpl || scene == this || scene->pImpl->owner || !_valid(viewport)) {
        return Result::InvalidArguments;
    }
    if (pImpl->owner) return Result::InsufficientCondition;
    auto ancestors = 1u;
    for (auto owner = pImpl->owner; owner; owner = owner->pImpl->owner) {
        if (owner == scene) return Result::InvalidArguments;
        if (++ancestors >= MAX_VIEWPORT_DEPTH) return Result::InsufficientCondition;
    }
    auto childDepth = depth(scene);
    if (childDepth > MAX_VIEWPORT_DEPTH - ancestors) return Result::InsufficientCondition;
    if (pImpl->viewportCnt >= MAX_VIEWPORTS) return Result::InsufficientCondition;
    if (!pImpl->growViewports()) return Result::OutOfMemory;
    auto& entry = pImpl->viewports[pImpl->viewportCnt++];
    entry.scene = scene;
    entry.viewport = viewport;
    scene->pImpl->owner = this;
    scene->pImpl->definitionsSealed = true;
    return Result::Success;
}

Result Scene::remove(Object* object) noexcept
{
    if (!pImpl || !object) return Result::InvalidArguments;
    if (pImpl->owner) return Result::InsufficientCondition;
    auto entry = pImpl->entry(object);
    if (!entry || entry->dead >= 0.0f) return Result::InsufficientCondition;
    if (!valid(object) || entry->fingerprint != fingerprint(object)) return Result::InvalidArguments;
    detachStyle(object);
    entry->dead = pImpl->cursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

static AnimCurve _legacyCurve(Easing easing) noexcept
{
    if (static_cast<uint8_t>(easing) > static_cast<uint8_t>(Easing::EaseInOut)) {
        auto curve = AnimCurve::preset(AnimCurvePreset::Linear);
        curve.kind = static_cast<AnimCurvePreset>(UINT8_MAX);
        return curve;
    }
    return AnimCurve::preset(static_cast<AnimCurvePreset>(easing));
}

static bool _timeline(float cursor, float duration, float lag, uint32_t count,
                      float& nextCursor) noexcept;

Result Scene::transition(Scene* const* scenes, uint32_t count, const Viewport& viewport,
                         float duration, float hold, Easing easing) noexcept
{
    return transition(scenes, count, viewport, duration, hold, _legacyCurve(easing));
}

Result Scene::transition(Scene* const* scenes, uint32_t count, const Viewport& viewport,
                         float duration, float hold, const AnimCurve& curve) noexcept
{
    if (!pImpl || !scenes || count < 2u || count > MAX_VIEWPORTS || !_valid(viewport)
        || !std::isfinite(duration) || duration <= 0.0f || !std::isfinite(hold)
        || hold < 0.0f || !curve.valid()) {
        return Result::InvalidArguments;
    }
    if (pImpl->owner || pImpl->sequence) return Result::InsufficientCondition;
    for (auto i = 0u; i < count; i++) {
        auto scene = scenes[i];
        if (!scene || !scene->pImpl || scene == this || scene->pImpl->owner
            || !valid(scene->pImpl->cfg) || depth(scene) >= MAX_VIEWPORT_DEPTH) {
            return Result::InvalidArguments;
        }
        for (auto j = i + 1u; j < count; j++) {
            if (scene == scenes[j]) return Result::InvalidArguments;
        }
    }

    auto sequence = new (std::nothrow) SceneSequence;
    if (!sequence) return Result::OutOfMemory;
    sequence->stages = new (std::nothrow) SceneStage[count];
    sequence->transitions = new (std::nothrow) SceneTransition[count - 1u];
    sequence->count = count;
    if (!sequence->stages || !sequence->transitions) {
        delete sequence;
        return Result::OutOfMemory;
    }

    auto cursor = pImpl->cursor;
    sequence->begin = cursor;
    sequence->viewport = viewport;
    for (auto i = 0u; i < count; i++) {
        auto& stage = sequence->stages[i];
        stage.scene = scenes[i];
        stage.begin = cursor;
        stage.end = cursor;
        if (hold > 0.0f && !_timeline(cursor, hold, 0.0f, 1u, stage.end)) {
            delete sequence;
            return Result::InvalidArguments;
        }
        cursor = stage.end;
        if (i + 1u >= count) continue;
        auto& transition = sequence->transitions[i];
        transition.begin = cursor;
        if (!_timeline(cursor, duration, 0.0f, 1u, transition.end)) {
            delete sequence;
            return Result::InvalidArguments;
        }
        transition.curve = curve;
        auto objects = scenes[i]->pImpl->objectCnt;
        if (objects) {
            transition.matches = new (std::nothrow) uint32_t[objects];
            if (!transition.matches) {
                delete sequence;
                return Result::OutOfMemory;
            }
            for (auto j = 0u; j < objects; j++) {
                transition.matches[j] = UINT32_MAX;
                auto tag = scenes[i]->pImpl->objects[j].object->tag();
                auto target = tag && tag[0] ? scenes[i + 1u]->object(tag) : nullptr;
                auto entry = target ? scenes[i + 1u]->pImpl->entry(target) : nullptr;
                if (entry) {
                    transition.matches[j] = static_cast<uint32_t>(
                        entry - scenes[i + 1u]->pImpl->objects);
                }
            }
        }
        cursor = transition.end;
    }

    for (auto i = 0u; i + 1u < count; i++) {
        auto& transition = sequence->transitions[i];
        auto from = scenes[i]->pImpl;
        auto to = scenes[i + 1u]->pImpl;
        for (auto j = 0u; j < from->objectCnt; j++) {
            auto target = transition.matches ? transition.matches[j] : UINT32_MAX;
            if (target >= to->objectCnt) continue;
            auto& sourceEntry = from->objects[j];
            auto& targetEntry = to->objects[target];
            if (!targetEntry.object->objThemeColor
                && !targetEntry.object->objThemeGradient) continue;
            _inherit(targetEntry, to->clips, to->clipCnt, sourceEntry.object->style,
                     targetEntry.object->objThemeColor,
                     targetEntry.object->objThemeGradient);
        }
    }

    sequence->owned = true;
    for (auto i = 0u; i < count; i++) {
        scenes[i]->pImpl->owner = this;
        scenes[i]->pImpl->definitionsSealed = true;
    }
    pImpl->sequence = sequence;
    pImpl->cursor = cursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

Result Scene::play(const Animation& animation, float duration, Easing easing) noexcept
{
    return play(animation, duration, _legacyCurve(easing));
}

Result Scene::play(const Animation& animation, float duration, const AnimCurve& curve) noexcept
{
    return play(&animation, 1, duration, curve, 0.0f);
}

static bool _timeline(float cursor, float duration, float lag, uint32_t count,
                      float& nextCursor) noexcept
{
    auto span = static_cast<double>(duration) * (1.0 + static_cast<double>(lag) * (count - 1u));
    auto next = static_cast<double>(cursor) + span;
    if (!std::isfinite(span) || next > std::numeric_limits<float>::max()) return false;
    nextCursor = static_cast<float>(next);
    if (nextCursor <= cursor) return false;
    for (auto i = 0u; i < count; i++) {
        auto begin = static_cast<float>(static_cast<double>(cursor)
                     + static_cast<double>(duration) * lag * i);
        auto end = static_cast<float>(static_cast<double>(cursor)
                   + static_cast<double>(duration) * (1.0 + static_cast<double>(lag) * i));
        if (!std::isfinite(begin) || !std::isfinite(end) || end <= begin) return false;
    }
    return true;
}

static bool _effectModel(const Object* object, const Mat4& model, float scale,
                         const Vec3& offset, Mat4& output)
{
    Bounds bounds;
    if (!object || !object->bounds(bounds)) return false;
    auto center = bounds.center();
    auto scaling = Mat4::translate(center) * Mat4::scale({scale, scale, scale})
                 * Mat4::translate(center * -1.0f);
    output = Mat4::translate(offset) * scaling * model;
    return _affine(output);
}

static bool _growthModel(const Object* object, const Mat4& model, GrowthEdge edge,
                         Mat4& output)
{
    Bounds bounds;
    if (!object || !object->bounds(bounds)) return false;
    auto anchor = bounds.center();
    auto scaling = Vec3{1.0f, 1.0f, 1.0f};
    switch (edge) {
        case GrowthEdge::Left:
            anchor.x = bounds.min.x;
            scaling = {0.0f, 1.0f, 1.0f};
            break;
        case GrowthEdge::Right:
            anchor.x = bounds.max.x;
            scaling = {0.0f, 1.0f, 1.0f};
            break;
        case GrowthEdge::Bottom:
            anchor.y = bounds.min.y;
            scaling = {1.0f, 0.0f, 1.0f};
            break;
        case GrowthEdge::Top:
            anchor.y = bounds.max.y;
            scaling = {1.0f, 0.0f, 1.0f};
            break;
        default: return false;
    }
    auto effect = Mat4::translate(anchor) * Mat4::scale(scaling)
                * Mat4::translate(anchor * -1.0f);
    output = effect * model;
    return _affine(output);
}

static bool _morphGeometry(const Object* source, const Object* target)
{
    if (!source || !target || source->type() != target->type()) return false;
    if (source->type() == Type::Polygon) {
        return static_cast<const Polygon*>(source)->count()
            == static_cast<const Polygon*>(target)->count();
    }
    if (source->type() == Type::Plot) {
        return static_cast<const Plot*>(source)->count()
            == static_cast<const Plot*>(target)->count();
    }
    if (source->type() == Type::Path) {
        auto from = static_cast<const Path*>(source);
        auto to = static_cast<const Path*>(target);
        return from->count() == to->count() && from->closed() == to->closed();
    }
    if (source->type() == Type::Curve) {
        return static_cast<const Curve*>(source)->count()
            == static_cast<const Curve*>(target)->count();
    }
    return false;
}

static bool _hasClip(const Clip* clips, uint32_t count, const Object* object)
{
    for (auto i = 0u; i < count; i++) {
        if (clips[i].object == object) return true;
    }
    return false;
}

static uint8_t _channels(StyleChannel channel)
{
    return static_cast<uint8_t>(channel);
}

static bool _valid(StyleChannel channel)
{
    auto value = _channels(channel);
    return value && !(value & ~_channels(StyleChannel::Both));
}

static bool _overlaps(StyleChannel first, StyleChannel second)
{
    return (_channels(first) & _channels(second)) != 0u;
}

static StyleChannel _merge(StyleChannel first, StyleChannel second)
{
    return static_cast<StyleChannel>(_channels(first) | _channels(second));
}

static void _applyStyle(Object* object, ObjectEntry& entry, Clip* clips,
                        uint32_t clipCount, Color color, StyleChannel channel)
{
    auto stroke = _overlaps(channel, StyleChannel::Stroke);
    auto fill = _overlaps(channel, StyleChannel::Fill);
    if (stroke) {
        object->style.stroke = color;
        entry.base.stroke = color;
    }
    if (fill) {
        object->style.fill = color;
        entry.base.fill = color;
    }
    for (auto i = 0u; i < clipCount; i++) {
        auto& clip = clips[i];
        if (clip.object != object) continue;
        if (stroke) {
            clip.from.stroke = color;
            clip.to.stroke = color;
        }
        if (fill) {
            clip.from.fill = color;
            clip.to.fill = color;
        }
    }
    entry.fingerprint = fingerprint(object);
}

StyleGroup* Scene::styleGroup(Color color, const StyleTarget* targets,
                              uint32_t count) noexcept
{
    if (!pImpl || !targets || !count || count > MAX_ANIMATION_GROUP || pImpl->owner) return nullptr;
    for (auto i = 0u; i < count; i++) {
        auto target = targets[i].target;
        auto entry = target ? pImpl->entry(target) : nullptr;
        if (!entry || entry->dead >= 0.0f || !_valid(targets[i].channel)
            || !valid(target) || entry->fingerprint != fingerprint(target)
            || _hasClip(pImpl->clips, pImpl->clipCnt, target)) {
            return nullptr;
        }
        for (auto j = i + 1u; j < count; j++) {
            if (target == targets[j].target && _overlaps(targets[i].channel, targets[j].channel)) {
                return nullptr;
            }
        }
        for (auto groupIndex = 0u; groupIndex < pImpl->styleGroupCnt; groupIndex++) {
            auto impl = pImpl->styleGroups[groupIndex]->pImpl;
            for (auto memberIndex = 0u; memberIndex < impl->count; memberIndex++) {
                auto& member = impl->members[memberIndex];
                if (member.object == target && _overlaps(member.channel, targets[i].channel)) return nullptr;
            }
        }
    }

    auto group = new (std::nothrow) StyleGroup(this, color);
    if (!group || !group->pImpl || !group->pImpl->grow(count) || !pImpl->growStyleGroups()) {
        delete group;
        return nullptr;
    }
    for (auto i = 0u; i < count; i++) {
        auto merged = false;
        for (auto j = 0u; j < group->pImpl->count; j++) {
            auto& member = group->pImpl->members[j];
            if (member.object != targets[i].target) continue;
            member.channel = _merge(member.channel, targets[i].channel);
            merged = true;
            break;
        }
        if (!merged) group->pImpl->members[group->pImpl->count++] = {targets[i].target, targets[i].channel};
    }
    for (auto i = 0u; i < group->pImpl->count; i++) {
        auto& member = group->pImpl->members[i];
        _applyStyle(member.object, *pImpl->entry(member.object), pImpl->clips,
                    pImpl->clipCnt, color, member.channel);
    }
    pImpl->styleGroups[pImpl->styleGroupCnt++] = group;
    return group;
}

StyleGroup* Scene::styleGroup(const StyleTarget* targets, uint32_t count) noexcept
{
    if (!pImpl || !targets || !count || !_valid(targets[0].channel)) return nullptr;
    auto target = targets[0].target;
    auto entry = target ? pImpl->entry(target) : nullptr;
    if (!entry || entry->dead >= 0.0f || !valid(target)
        || entry->fingerprint != fingerprint(target)) {
        return nullptr;
    }

    Color color;
    if (targets[0].channel == StyleChannel::Stroke) {
        color = target->style.stroke;
    } else if (targets[0].channel == StyleChannel::Fill) {
        color = target->style.fill;
    } else {
        if (!_equal(target->style.stroke, target->style.fill)) return nullptr;
        color = target->style.stroke;
    }
    return styleGroup(color, targets, count);
}

Result Scene::styleBind(StyleGroup* group, Object* target, StyleChannel channel) noexcept
{
    if (!pImpl || !group || !group->pImpl || group->pImpl->scene != this || !target
        || !_valid(channel)) {
        return Result::InvalidArguments;
    }
    if (pImpl->owner) return Result::InsufficientCondition;
    auto entry = pImpl->entry(target);
    if (!entry || entry->dead >= 0.0f || !valid(target)
        || entry->fingerprint != fingerprint(target)) {
        return Result::InvalidArguments;
    }
    if (_hasClip(pImpl->clips, pImpl->clipCnt, target)) return Result::InsufficientCondition;

    StyleMember* existing = nullptr;
    for (auto groupIndex = 0u; groupIndex < pImpl->styleGroupCnt; groupIndex++) {
        auto candidate = pImpl->styleGroups[groupIndex];
        for (auto i = 0u; i < candidate->pImpl->count; i++) {
            auto& member = candidate->pImpl->members[i];
            if (member.object != target || !_overlaps(member.channel, channel)) continue;
            return Result::InsufficientCondition;
        }
    }
    for (auto i = 0u; i < group->pImpl->count; i++) {
        if (group->pImpl->members[i].object == target) {
            existing = group->pImpl->members + i;
            break;
        }
    }
    if (!existing && !group->pImpl->grow()) return Result::OutOfMemory;
    if (existing) existing->channel = _merge(existing->channel, channel);
    else group->pImpl->members[group->pImpl->count++] = {target, channel};
    _applyStyle(target, *entry, pImpl->clips, pImpl->clipCnt, group->pImpl->color, channel);
    return Result::Success;
}

Result Scene::style(StyleGroup* group, Color color, float duration, Easing easing) noexcept
{
    return style(group, color, duration, _legacyCurve(easing));
}

Result Scene::style(StyleGroup* group, Color color, float duration,
                    const AnimCurve& curve) noexcept
{
    if (!pImpl || !group || !group->pImpl || group->pImpl->scene != this) {
        return Result::InvalidArguments;
    }
    if (!group->pImpl->count) return Result::InsufficientCondition;
    auto targets = new (std::nothrow) AnimationTarget[group->pImpl->count];
    if (!targets) return Result::OutOfMemory;
    for (auto i = 0u; i < group->pImpl->count; i++) {
        auto& member = group->pImpl->members[i];
        targets[i] = AnimationTarget::from(member.object);
        if (_overlaps(member.channel, StyleChannel::Stroke)) targets[i].stroke(color);
        if (_overlaps(member.channel, StyleChannel::Fill)) targets[i].fill(color);
    }
    auto result = play(targets, group->pImpl->count, duration, curve, 0.0f);
    delete[] targets;
    if (result == Result::Success) group->pImpl->color = color;
    return result;
}

bool Scene::styleTransferValid(Object* source, Object* target) const noexcept
{
    if (!pImpl || !source || !target || source == target) return false;
    for (auto i = 0u; i < pImpl->styleGroupCnt; i++) {
        auto sourceGroup = pImpl->styleGroups[i];
        for (auto sourceIndex = 0u; sourceIndex < sourceGroup->pImpl->count; sourceIndex++) {
            auto& sourceMember = sourceGroup->pImpl->members[sourceIndex];
            if (sourceMember.object != source) continue;
            for (auto j = 0u; j < pImpl->styleGroupCnt; j++) {
                if (i == j) continue;
                auto targetGroup = pImpl->styleGroups[j];
                for (auto targetIndex = 0u; targetIndex < targetGroup->pImpl->count; targetIndex++) {
                    auto& targetMember = targetGroup->pImpl->members[targetIndex];
                    if (targetMember.object == target
                        && _overlaps(sourceMember.channel, targetMember.channel)) return false;
                }
            }
        }
    }
    return true;
}

void Scene::transferStyle(Object* source, Object* target) noexcept
{
    if (!pImpl || !source || !target) return;
    auto targetEntry = pImpl->entry(target);
    if (!targetEntry) return;
    for (auto i = 0u; i < pImpl->styleGroupCnt; i++) {
        auto group = pImpl->styleGroups[i];
        auto sourceIndex = UINT32_MAX;
        auto targetIndex = UINT32_MAX;
        for (auto j = 0u; j < group->pImpl->count; j++) {
            if (group->pImpl->members[j].object == source) sourceIndex = j;
            if (group->pImpl->members[j].object == target) targetIndex = j;
        }
        if (sourceIndex == UINT32_MAX) continue;
        auto channel = group->pImpl->members[sourceIndex].channel;
        _applyStyle(target, *targetEntry, pImpl->clips, pImpl->clipCnt,
                    group->pImpl->color, channel);
        if (targetIndex == UINT32_MAX) {
            group->pImpl->members[sourceIndex].object = target;
            continue;
        }
        group->pImpl->members[targetIndex].channel =
            _merge(group->pImpl->members[targetIndex].channel, channel);
        group->pImpl->members[sourceIndex] = group->pImpl->members[--group->pImpl->count];
    }
}

void Scene::detachStyle(Object* object) noexcept
{
    if (!pImpl || !object) return;
    for (auto i = 0u; i < pImpl->styleGroupCnt; i++) {
        auto impl = pImpl->styleGroups[i]->pImpl;
        for (auto j = 0u; j < impl->count;) {
            if (impl->members[j].object != object) {
                j++;
                continue;
            }
            impl->members[j] = impl->members[--impl->count];
        }
    }
}

Result Scene::fadeTransform(Object* source, Object* target, float duration,
                            Easing easing) noexcept
{
    return fadeTransform(source, target, duration, _legacyCurve(easing));
}

Result Scene::fadeTransform(Object* source, Object* target, float duration,
                            const AnimCurve& curve) noexcept
{
    if (!pImpl || !source || !target || source == target
        || _inside(source, target) || _inside(target, source)) {
        return Result::InvalidArguments;
    }
    if (pImpl->owner) return Result::InsufficientCondition;
    auto sourceEntry = pImpl->entry(source);
    auto targetEntry = pImpl->entry(target);
    if (!sourceEntry || !targetEntry || sourceEntry->dead >= 0.0f || targetEntry->dead >= 0.0f
        || !valid(source) || !valid(target)
        || sourceEntry->fingerprint != fingerprint(source)
        || targetEntry->fingerprint != fingerprint(target)) {
        return Result::InvalidArguments;
    }
    if (targetEntry->born != pImpl->cursor || _hasClip(pImpl->clips, pImpl->clipCnt, target)) {
        return Result::InsufficientCondition;
    }
    if (!styleTransferValid(source, target)) return Result::InsufficientCondition;

    Animation animations[] = {Animation::fadeOut(source), Animation::fadeIn(target)};
    auto result = play(animations, 2u, duration, curve, 0.0f);
    if (result != Result::Success) return result;
    transferStyle(source, target);
    return remove(source);
}

static bool _connectorReferences(const ObjectEntry* objects, uint32_t count,
                                 const Object* object)
{
    for (auto i = 0u; i < count; i++) {
        auto candidate = objects[i].object;
        if (candidate->type() != Type::Connector) continue;
        auto connector = static_cast<const Connector*>(candidate);
        if (connector->from() == object || connector->to() == object) return true;
    }
    return false;
}

static bool _sameAnimationObject(const Animation& lhs, const Animation& rhs)
{
    if (lhs.target == rhs.target || lhs.target == rhs.related || lhs.related == rhs.target) return true;
    return lhs.related && lhs.related == rhs.related;
}

static void _hideBefore(ObjectEntry& entry, Clip* clips, uint32_t count, bool progress)
{
    if (entry.revealScheduled) return;
    if (progress) entry.base.progress = 0.0f;
    else entry.base.opacity = 0.0f;
    for (auto i = 0u; i < count; i++) {
        auto& previous = clips[i];
        if (previous.object != entry.object) continue;
        if (progress) {
            previous.from.progress = 0.0f;
            previous.to.progress = 0.0f;
        } else {
            previous.from.opacity = 0.0f;
            previous.to.opacity = 0.0f;
        }
    }
    entry.revealScheduled = true;
}

static void _hideFillBefore(ObjectEntry& entry, Clip* clips, uint32_t count)
{
    if (entry.fillRevealScheduled) return;
    entry.base.fillProgress = 0.0f;
    for (auto i = 0u; i < count; i++) {
        auto& previous = clips[i];
        if (previous.object != entry.object) continue;
        previous.from.fillProgress = 0.0f;
        previous.to.fillProgress = 0.0f;
    }
    entry.fillRevealScheduled = true;
}

Result Scene::play(const Animation* animations, uint32_t count, float duration, Easing easing, float lag) noexcept
{
    return play(animations, count, duration, _legacyCurve(easing), lag);
}

Result Scene::play(const Animation* animations, uint32_t count, float duration,
                   const AnimCurve& curve, float lag) noexcept
{
    if (!pImpl || !animations || !count || !std::isfinite(duration) || !std::isfinite(lag)) return Result::InvalidArguments;
    if (pImpl->owner) return Result::InsufficientCondition;
    if (duration <= 0.0f || lag < 0.0f) return Result::InvalidArguments;
    if (count > MAX_ANIMATION_GROUP) return Result::InvalidArguments;
    if (!curve.valid()) return Result::InvalidArguments;
    float nextCursor;
    if (!_timeline(pImpl->cursor, duration, lag, count, nextCursor)) return Result::InvalidArguments;
    for (auto i = 0u; i < count; i++) {
        auto target = animations[i].target;
        auto entry = target ? pImpl->entry(target) : nullptr;
        if (!entry || entry->dead >= 0.0f || !valid(target) || entry->fingerprint != fingerprint(target)) {
            return Result::InvalidArguments;
        }
        auto& animation = animations[i];
        switch (animation.kind) {
            case AnimationKind::Transform:
                if (animation.related || !_transformable(target) || !_affine(animation.model)) {
                    return Result::InvalidArguments;
                }
                break;
            case AnimationKind::Create:
            case AnimationKind::Uncreate:
            case AnimationKind::DrawBorderThenFill:
            case AnimationKind::Write:
                if (animation.related || static_cast<uint8_t>(animation.direction)
                    > static_cast<uint8_t>(DrawDirection::CounterClockwise)) {
                    return Result::InvalidArguments;
                }
                break;
            case AnimationKind::FillReveal:
                if (animation.related) return Result::InvalidArguments;
                break;
            case AnimationKind::Fade:
                if (animation.related || !std::isfinite(animation.value)
                    || animation.value < 0.0f || animation.value > 1.0f) {
                    return Result::InvalidArguments;
                }
                break;
            case AnimationKind::FadeIn:
            case AnimationKind::FadeOut: {
                if (animation.related || !_finite(animation.offset) || !std::isfinite(animation.scale)
                    || animation.scale <= 0.0f) {
                    return Result::InvalidArguments;
                }
                auto moves = animation.offset.length() > 0.0f || animation.scale != 1.0f;
                Mat4 effect;
                if (moves && (!_transformable(target)
                    || !_effectModel(target, target->model, animation.scale, animation.offset, effect))) {
                    return Result::InvalidArguments;
                }
                break;
            }
            case AnimationKind::Grow:
            case AnimationKind::GrowFromEdge:
            case AnimationKind::Shrink: {
                Mat4 effect;
                if (animation.related || !_transformable(target)
                    || (animation.kind == AnimationKind::GrowFromEdge
                        ? !_growthModel(target, target->model, animation.growthEdge, effect)
                        : !_effectModel(target, target->model, 0.0f, {}, effect))) {
                    return Result::InvalidArguments;
                }
                break;
            }
            case AnimationKind::Indicate: {
                Mat4 effect;
                if (animation.related || !_transformable(target) || !std::isfinite(animation.scale)
                    || animation.scale <= 1.0f
                    || !_effectModel(target, target->model, animation.scale, {}, effect)) {
                    return Result::InvalidArguments;
                }
                break;
            }
            case AnimationKind::Morph: {
                auto related = animation.related;
                auto relatedEntry = related ? pImpl->entry(related) : nullptr;
                if (!related || related == target || !relatedEntry || relatedEntry->dead >= 0.0f
                    || !valid(related) || relatedEntry->fingerprint != fingerprint(related)) {
                    return Result::InvalidArguments;
                }
                if (!_morphGeometry(target, related)) return Result::NonSupport;
                if (target->childCount() || related->childCount()
                    || target->parent() != related->parent()
                    || relatedEntry->born != pImpl->cursor
                    || _hasClip(pImpl->clips, pImpl->clipCnt, related)
                    || _connectorReferences(pImpl->objects, pImpl->objectCnt, target)
                    || _connectorReferences(pImpl->objects, pImpl->objectCnt, related)) {
                    return Result::InsufficientCondition;
                }
                if (!styleTransferValid(target, related)) return Result::InsufficientCondition;
                break;
            }
            case AnimationKind::Stroke:
            case AnimationKind::Fill:
                if (animation.related) return Result::InvalidArguments;
                break;
            default: return Result::InvalidArguments;
        }
        for (auto j = i + 1; j < count; j++) {
            if (_sameAnimationObject(animation, animations[j])) return Result::InvalidArguments;
        }
    }
    if (!pImpl->growClips(count)) return Result::OutOfMemory;
    auto previousClipCount = pImpl->clipCnt;

    for (auto i = 0u; i < count; i++) {
        auto& animation = animations[i];
        auto entry = pImpl->entry(animation.target);
        auto from = _state(animation.target);
        auto to = from;
        auto begin = static_cast<float>(static_cast<double>(pImpl->cursor)
                   + static_cast<double>(duration) * lag * i);
        auto end = static_cast<float>(static_cast<double>(pImpl->cursor)
                 + static_cast<double>(duration) * (1.0 + static_cast<double>(lag) * i));
        switch (animation.kind) {
            case AnimationKind::Transform: to.model = animation.model; break;
            case AnimationKind::Create: {
                from.progress = 0.0f;
                to.progress = 1.0f;
                from.direction = animation.direction;
                to.direction = animation.direction;
                _hideBefore(*entry, pImpl->clips, previousClipCount, true);
                break;
            }
            case AnimationKind::Uncreate:
                to.progress = 0.0f;
                from.direction = animation.direction;
                to.direction = animation.direction;
                entry->revealScheduled = true;
                break;
            case AnimationKind::FillReveal:
                from.fillProgress = 0.0f;
                to.fillProgress = 1.0f;
                _hideFillBefore(*entry, pImpl->clips, previousClipCount);
                break;
            case AnimationKind::DrawBorderThenFill:
                from.progress = 0.0f;
                from.fillProgress = 0.0f;
                to.progress = 1.0f;
                to.fillProgress = 1.0f;
                from.direction = animation.direction;
                to.direction = animation.direction;
                _hideBefore(*entry, pImpl->clips, previousClipCount, true);
                _hideFillBefore(*entry, pImpl->clips, previousClipCount);
                break;
            case AnimationKind::Write:
                from.progress = 0.0f;
                to.progress = 1.0f;
                from.traceFill = true;
                to.traceFill = true;
                from.direction = animation.direction;
                to.direction = animation.direction;
                _hideBefore(*entry, pImpl->clips, previousClipCount, true);
                break;
            case AnimationKind::Fade:
                to.opacity = animation.value;
                entry->revealScheduled = true;
                break;
            case AnimationKind::FadeIn:
                from.opacity = 0.0f;
                to.opacity = 1.0f;
                if (animation.scale != 1.0f || animation.offset.length() > 0.0f) {
                    _effectModel(animation.target, to.model, animation.scale, animation.offset, from.model);
                    from.pixelScale = animation.scale;
                }
                _hideBefore(*entry, pImpl->clips, previousClipCount, false);
                break;
            case AnimationKind::FadeOut:
                to.opacity = 0.0f;
                if (animation.scale != 1.0f || animation.offset.length() > 0.0f) {
                    _effectModel(animation.target, from.model, animation.scale, animation.offset, to.model);
                    to.pixelScale = animation.scale;
                }
                entry->revealScheduled = true;
                break;
            case AnimationKind::Grow:
            case AnimationKind::GrowFromEdge:
                if (animation.kind == AnimationKind::GrowFromEdge) {
                    _growthModel(animation.target, to.model, animation.growthEdge, from.model);
                } else {
                    _effectModel(animation.target, to.model, 0.0f, {}, from.model);
                }
                from.opacity = 0.0f;
                from.pixelScale = 0.0f;
                to.opacity = 1.0f;
                _hideBefore(*entry, pImpl->clips, previousClipCount, false);
                break;
            case AnimationKind::Shrink:
                _effectModel(animation.target, from.model, 0.0f, {}, to.model);
                to.opacity = 0.0f;
                to.pixelScale = 0.0f;
                entry->revealScheduled = true;
                break;
            case AnimationKind::Indicate:
                _effectModel(animation.target, from.model, animation.scale, {}, to.model);
                to.pixelScale = animation.scale;
                if (from.stroke.a) {
                    to.stroke = animation.color;
                    to.stroke.a = from.stroke.a;
                }
                if (from.fill.a) {
                    to.fill = animation.color;
                    to.fill.a = from.fill.a;
                }
                entry->revealScheduled = true;
                break;
            case AnimationKind::Morph: {
                auto targetEntry = pImpl->entry(animation.related);
                if (animation.related->objThemeColor
                    || animation.related->objThemeGradient) {
                    _inherit(*targetEntry, pImpl->clips, pImpl->clipCnt,
                             animation.target->style,
                             animation.related->objThemeColor,
                             animation.related->objThemeGradient);
                }
                transferStyle(animation.target, animation.related);
                to = _state(animation.related);
                targetEntry->born = end;
                targetEntry->revealScheduled = true;
                entry->dead = end;
                break;
            }
            case AnimationKind::Stroke: to.stroke = animation.color; break;
            case AnimationKind::Fill: to.fill = animation.color; break;
        }

        auto& clip = pImpl->clips[pImpl->clipCnt++];
        clip.object = animation.target;
        clip.from = from;
        clip.to = to;
        clip.begin = begin;
        clip.end = end;
        clip.curve = curve;
        clip.kind = animation.kind;
        clip.related = animation.related;
        if (animation.kind == AnimationKind::Indicate || animation.kind == AnimationKind::Morph) continue;
        if (animation.kind == AnimationKind::FadeOut || animation.kind == AnimationKind::Shrink) {
            auto authored = from;
            authored.opacity = 0.0f;
            _state(animation.target, authored);
        } else {
            _state(animation.target, to);
        }
        entry->fingerprint = fingerprint(animation.target);
    }
    pImpl->cursor = nextCursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

Result Scene::play(const AnimationTarget& target, float duration, Easing easing) noexcept
{
    return play(target, duration, _legacyCurve(easing));
}

Result Scene::play(const AnimationTarget& target, float duration, const AnimCurve& curve) noexcept
{
    return play(&target, 1u, duration, curve, 0.0f);
}

Result Scene::play(const AnimationTarget* targets, uint32_t count, float duration,
                   Easing easing, float lag) noexcept
{
    return play(targets, count, duration, _legacyCurve(easing), lag);
}

Result Scene::play(const AnimationTarget* targets, uint32_t count, float duration,
                   const AnimCurve& curve, float lag) noexcept
{
    if (!pImpl || !targets || !count || !std::isfinite(duration) || !std::isfinite(lag)) {
        return Result::InvalidArguments;
    }
    if (pImpl->owner) return Result::InsufficientCondition;
    if (duration <= 0.0f || lag < 0.0f || count > MAX_ANIMATION_GROUP || !curve.valid()) {
        return Result::InvalidArguments;
    }
    float nextCursor;
    if (!_timeline(pImpl->cursor, duration, lag, count, nextCursor)) return Result::InvalidArguments;
    for (auto i = 0u; i < count; i++) {
        auto& target = targets[i];
        auto entry = target.target ? pImpl->entry(target.target) : nullptr;
        if (!entry || entry->dead >= 0.0f || !target.properties
            || (target.properties & ~(TARGET_MODEL | TARGET_OPACITY | TARGET_STROKE
                                      | TARGET_FILL | TARGET_DASH_OFFSET | TARGET_TAIL
                                      | TARGET_TIP))
            || !valid(target.target) || entry->fingerprint != fingerprint(target.target)) {
            return Result::InvalidArguments;
        }
        if ((target.properties & TARGET_MODEL)
            && (!_transformable(target.target) || !_affine(target.targetModel))) {
            return Result::InvalidArguments;
        }
        if ((target.properties & TARGET_OPACITY)
            && (!std::isfinite(target.targetOpacity) || target.targetOpacity < 0.0f || target.targetOpacity > 1.0f)) {
            return Result::InvalidArguments;
        }
        if ((target.properties & TARGET_DASH_OFFSET)
            && (!target.target->style.dashCount || !std::isfinite(target.targetDashOffset))) {
            return Result::InvalidArguments;
        }
        if ((target.properties & (TARGET_TAIL | TARGET_TIP))
            && (target.target->type() != Type::Arrow
                && target.target->type() != Type::Vector
                && target.target->type() != Type::Connector
                && target.target->type() != Type::Route)) {
            return Result::InvalidArguments;
        }
        if ((target.properties & TARGET_TAIL)
            && (!std::isfinite(target.targetTail) || target.targetTail < 0.0f)) {
            return Result::InvalidArguments;
        }
        if ((target.properties & TARGET_TIP)
            && (!std::isfinite(target.targetTip) || target.targetTip < 0.0f)) {
            return Result::InvalidArguments;
        }
        for (auto j = i + 1u; j < count; j++) {
            if (target.target == targets[j].target) return Result::InvalidArguments;
        }
    }
    if (!pImpl->growClips(count)) return Result::OutOfMemory;

    for (auto i = 0u; i < count; i++) {
        auto& target = targets[i];
        auto entry = pImpl->entry(target.target);
        auto from = _state(target.target);
        auto to = from;
        if (target.properties & TARGET_MODEL) to.model = target.targetModel;
        if (target.properties & TARGET_OPACITY) to.opacity = target.targetOpacity;
        if (target.properties & TARGET_STROKE) to.stroke = target.targetStroke;
        if (target.properties & TARGET_FILL) to.fill = target.targetFill;
        if (target.properties & TARGET_DASH_OFFSET) to.dashOffset = target.targetDashOffset;
        if (target.properties & TARGET_TAIL) to.markerTail = target.targetTail;
        if (target.properties & TARGET_TIP) to.markerTip = target.targetTip;

        auto& clip = pImpl->clips[pImpl->clipCnt++];
        clip.object = target.target;
        clip.from = from;
        clip.to = to;
        clip.begin = static_cast<float>(static_cast<double>(pImpl->cursor)
                     + static_cast<double>(duration) * lag * i);
        clip.end = static_cast<float>(static_cast<double>(pImpl->cursor)
                   + static_cast<double>(duration) * (1.0 + static_cast<double>(lag) * i));
        clip.curve = curve;
        _state(target.target, to);
        entry->fingerprint = fingerprint(target.target);
    }
    pImpl->cursor = nextCursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

Result Scene::runtime(const RuntimeModifier* modifier) noexcept
{
    if (!pImpl) return Result::InvalidArguments;
    if (!modifier) {
        for (auto i = 0u; i < pImpl->runtimeModifierCnt; i++) {
            pImpl->runtimeModifiers[i] = {};
        }
        pImpl->runtimeModifierCnt = 0u;
        return Result::Success;
    }
    if (!modifier->object && !modifier->fill && !modifier->camera && !modifier->input) {
        return Result::InvalidArguments;
    }
    if (pImpl->runtimeModifierCnt > 1u
        || (pImpl->runtimeModifierCnt == 1u
            && pImpl->runtimeModifiers[0].data != modifier->data)) {
        return Result::InsufficientCondition;
    }
    pImpl->runtimeModifiers[0] = *modifier;
    pImpl->runtimeModifierCnt = 1u;
    return Result::Success;
}

Result Scene::runtimeAdd(const RuntimeModifier* modifier) noexcept
{
    if (!pImpl || !modifier || !modifier->data
        || (!modifier->object && !modifier->fill && !modifier->camera && !modifier->input)) {
        return Result::InvalidArguments;
    }
    for (auto i = 0u; i < pImpl->runtimeModifierCnt; i++) {
        if (pImpl->runtimeModifiers[i].data != modifier->data) continue;
        if (modifier->key) {
            for (auto j = 0u; j < pImpl->runtimeModifierCnt; j++) {
                if (j != i && pImpl->runtimeModifiers[j].key == modifier->key) {
                    return Result::InsufficientCondition;
                }
            }
        }
        pImpl->runtimeModifiers[i] = *modifier;
        return Result::Success;
    }
    if (modifier->key) {
        for (auto i = 0u; i < pImpl->runtimeModifierCnt; i++) {
            if (pImpl->runtimeModifiers[i].key == modifier->key) {
                return Result::InsufficientCondition;
            }
        }
    }
    if (pImpl->runtimeModifierCnt >= RuntimeLimit) return Result::InsufficientCondition;
    pImpl->runtimeModifiers[pImpl->runtimeModifierCnt++] = *modifier;
    return Result::Success;
}

Result Scene::runtimeRemove(void* data) noexcept
{
    if (!pImpl || !data) return Result::InvalidArguments;
    for (auto i = 0u; i < pImpl->runtimeModifierCnt; i++) {
        if (pImpl->runtimeModifiers[i].data != data) continue;
        for (auto j = i + 1u; j < pImpl->runtimeModifierCnt; j++) {
            pImpl->runtimeModifiers[j - 1u] = pImpl->runtimeModifiers[j];
        }
        pImpl->runtimeModifiers[--pImpl->runtimeModifierCnt] = {};
        return Result::Success;
    }
    return Result::InsufficientCondition;
}

Result Scene::camera(const CameraInput& input) noexcept
{
    if (!pImpl || pImpl->cfg.cameraMode != CameraMode::Interactive) {
        return Result::InsufficientCondition;
    }
    if (static_cast<uint8_t>(input.action) > static_cast<uint8_t>(CameraAction::View3D)
        || !std::isfinite(input.delta.x) || !std::isfinite(input.delta.y)) {
        return Result::InvalidArguments;
    }
    for (auto i = 0u; i < pImpl->runtimeModifierCnt; i++) {
        auto& modifier = pImpl->runtimeModifiers[i];
        if (!modifier.input) continue;
        auto result = modifier.input(input, modifier.data);
        if (result == Result::Success) return result;
        if (result != Result::NonSupport && result != Result::InsufficientCondition) {
            return result;
        }
    }
    return Result::NonSupport;
}

Result Scene::look(const Camera& camera, CameraView view, float duration, Easing easing) noexcept
{
    return look(camera, view, duration, _legacyCurve(easing));
}

Result Scene::look(const Camera& camera, CameraView view, float duration,
                   const AnimCurve& curve) noexcept
{
    if (!pImpl || pImpl->cfg.cameraMode != CameraMode::Fixed) return Result::InsufficientCondition;
    if (pImpl->owner) return Result::InsufficientCondition;
    if (!std::isfinite(duration) || duration <= 0.0f || !curve.valid()) {
        return Result::InvalidArguments;
    }
    auto config = pImpl->cfg;
    config.camera = camera;
    config.cameraView = view;
    auto poseChanged = !_samePose(pImpl->cfg.camera, camera);
    float nextCursor;
    if (!valid(pImpl->cfg) || !valid(config)
        || (poseChanged && (!_animationSafe(pImpl->cfg.camera) || !_animationSafe(camera)
                            || !_poseSafe(pImpl->cfg.camera, camera)))
        || !_planesSafe(pImpl->cfg.camera, camera)
        || !_timeline(pImpl->cursor, duration, 0.0f, 1u, nextCursor)) {
        return Result::InvalidArguments;
    }
    if (!pImpl->growCameras()) return Result::OutOfMemory;
    if (!pImpl->cameraCnt) {
        pImpl->initialCamera = pImpl->cfg.camera;
        pImpl->initialView = pImpl->cfg.cameraView;
    }
    auto& clip = pImpl->cameras[pImpl->cameraCnt++];
    clip.from = pImpl->cfg.camera;
    clip.to = camera;
    clip.fromView = pImpl->cfg.cameraView;
    clip.toView = view;
    clip.begin = pImpl->cursor;
    clip.end = nextCursor;
    clip.curve = curve;
    pImpl->cfg.camera = camera;
    pImpl->cfg.cameraView = view;
    pImpl->cursor = nextCursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

Result Scene::wait(float duration) noexcept
{
    if (!pImpl || !std::isfinite(duration) || duration < 0.0f) return Result::InvalidArguments;
    if (pImpl->owner) return Result::InsufficientCondition;
    auto nextCursor = pImpl->cursor;
    if (duration > 0.0f && !_timeline(pImpl->cursor, duration, 0.0f, 1u, nextCursor)) {
        return Result::InvalidArguments;
    }
    pImpl->cursor = nextCursor;
    pImpl->definitionsSealed = true;
    return Result::Success;
}

float Scene::duration() const noexcept
{
    if (!pImpl) return 0.0f;
    auto value = pImpl->cursor;
    for (auto i = 0u; i < pImpl->viewportCnt; i++) {
        auto duration = pImpl->viewports[i].scene->duration();
        if (duration > value) value = duration;
    }
    return value;
}

CameraView Scene::view(float time) const noexcept
{
    if (!pImpl || !std::isfinite(time) || time < 0.0f) return CameraView::TwoD;
    Camera camera;
    CameraView view;
    if (pImpl->sample(time, camera, view) != Result::Success) return CameraView::TwoD;
    return view;
}

uint32_t Scene::count() const noexcept
{
    return pImpl ? pImpl->objectCnt : 0;
}

Object* Scene::object(uint32_t id) const noexcept
{
    if (!pImpl || !id) return nullptr;
    for (auto i = 0u; i < pImpl->objectCnt; i++) {
        if (pImpl->objects[i].object->id() == id) return pImpl->objects[i].object;
    }
    return nullptr;
}

Object* Scene::objectAt(uint32_t index) const noexcept
{
    if (!pImpl || index >= pImpl->objectCnt) return nullptr;
    return pImpl->objects[index].object;
}

Object* Scene::object(const char* tag) const noexcept
{
    if (!pImpl || !tag) return nullptr;
    for (auto i = 0u; i < pImpl->objectCnt; i++) {
        auto value = pImpl->objects[i].object->tag();
        if (value && std::strcmp(value, tag) == 0) return pImpl->objects[i].object;
    }
    return nullptr;
}

uint32_t Scene::viewportCount() const noexcept
{
    return pImpl ? pImpl->viewportCnt : 0;
}

Scene* Scene::sceneAt(uint32_t index) const noexcept
{
    if (!pImpl || index >= pImpl->viewportCnt) return nullptr;
    return pImpl->viewports[index].scene;
}

bool Scene::viewportAt(uint32_t index, Viewport& viewport) const noexcept
{
    if (!pImpl || index >= pImpl->viewportCnt) return false;
    viewport = pImpl->viewports[index].viewport;
    return true;
}

uint32_t Scene::transitionCount() const noexcept
{
    return pImpl && pImpl->sequence ? pImpl->sequence->count : 0u;
}

Scene* Scene::transitionAt(uint32_t index) const noexcept
{
    if (!pImpl || !pImpl->sequence || index >= pImpl->sequence->count) return nullptr;
    return pImpl->sequence->stages[index].scene;
}

Config& Scene::config() noexcept
{
    return pImpl->cfg;
}

const Config& Scene::config() const noexcept
{
    return pImpl->cfg;
}

}  // namespace tmath
