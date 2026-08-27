#include <cmath>
#include <cstring>
#include <limits>
#include <new>

#include "tmath.h"
#include "tmathScene.h"

namespace tmath
{

static char* _copy(const char* text)
{
    if (!text) return nullptr;
    auto size = std::strlen(text) + 1;
    auto copy = new (std::nothrow) char[size];
    if (!copy) return nullptr;
    std::memcpy(copy, text, size);
    return copy;
}

static constexpr uint32_t MAX_OBJECT_DEPTH = 64;

const char* type(Type type) noexcept
{
    switch (type) {
        case Type::Space: return "space";
        case Type::Point: return "point";
        case Type::Line: return "line";
        case Type::Arrow: return "arrow";
        case Type::Vector: return "vector";
        case Type::Circle: return "circle";
        case Type::Polygon: return "polygon";
        case Type::Plot: return "plot";
        case Type::Route: return "route";
        case Type::Text: return "text";
        case Type::Ruler: return "ruler";
        case Type::Svg: return "svg";
        case Type::Image: return "image";
        case Type::Cell: return "cell";
        case Type::Group: return "group";
        case Type::Rectangle: return "rectangle";
        case Type::Connector: return "connector";
        case Type::Path: return "path";
        case Type::Curve: return "curve";
        case Type::SurfaceMesh: return "surface";
    }
    return "unknown";
}

Object::Object(Type type) noexcept : objType(type)
{
}

Object::~Object()
{
    for (auto i = 0u; i < childCnt; i++)
        delete children[i];
    delete[] children;
    delete[] objTag;
}

Type Object::type() const noexcept
{
    return objType;
}

uint32_t Object::id() const noexcept
{
    return objId;
}

Object* Object::parent() const noexcept
{
    return objParent;
}

Space* Object::space() const noexcept
{
    for (auto object = objParent; object; object = object->objParent) {
        if (object->type() == Type::Space) return static_cast<Space*>(object);
    }
    return nullptr;
}

bool Object::owned() const noexcept
{
    return objOwner;
}

bool Object::grow() noexcept
{
    if (childCnt < childCap) return true;
    auto capacity = childCap ? childCap * 2u : 8u;
    if (capacity < childCap) return false;
    auto grown = new (std::nothrow) Object*[capacity];
    if (!grown) return false;
    for (auto i = 0u; i < childCnt; i++)
        grown[i] = children[i];
    delete[] children;
    children = grown;
    childCap = capacity;
    return true;
}

static bool _height(const Object* object, uint32_t depth, uint32_t& height)
{
    if (!object || depth > MAX_OBJECT_DEPTH) return false;
    if (depth > height) height = depth;
    for (auto i = 0u; i < object->childCount(); i++) {
        if (!_height(object->childAt(i), depth + 1u, height)) return false;
    }
    return true;
}

Result Object::add(Object* object) noexcept
{
    if (!object || object == this || !valid(object) || object->objOwner || object->objParent) {
        return Result::InvalidArguments;
    }
    auto ancestors = 0u;
    for (auto parent = this; parent; parent = parent->objParent) {
        if (parent == object) return Result::InvalidArguments;
        if (ancestors++ >= MAX_OBJECT_DEPTH) return Result::InsufficientCondition;
    }
    auto height = 0u;
    if (!_height(object, 0u, height) || ancestors + height > MAX_OBJECT_DEPTH) {
        return Result::InsufficientCondition;
    }
    if (!grow()) return Result::OutOfMemory;
    if (objOwner) {
        auto result = objOwner->attach(object, this);
        if (result != Result::Success) return result;
    } else {
        object->objParent = this;
    }
    children[childCnt++] = object;
    return Result::Success;
}

uint32_t Object::childCount() const noexcept
{
    return childCnt;
}

Object* Object::childAt(uint32_t index) const noexcept
{
    if (index >= childCnt) return nullptr;
    return children[index];
}

Object& Object::tag(const char* value) noexcept
{
    if (objOwner) return *this;
    auto copy = _copy(value);
    if (value && !copy) return *this;
    delete[] objTag;
    objTag = copy;
    return *this;
}

const char* Object::tag() const noexcept
{
    return objTag;
}

Object& Object::stroke(Color color) noexcept
{
    if (owned()) return *this;
    style.stroke = color;
    objColorAuthored = true;
    return *this;
}

Object& Object::stroke(Color color, float width) noexcept
{
    stroke(color);
    return strokeWidth(width);
}

Object& Object::strokeWidth(float width) noexcept
{
    if (owned()) return *this;
    style.width = width < 0.0f ? 0.0f : width;
    objWidthAuthored = true;
    return *this;
}

Object& Object::gradient(bool enabled) noexcept
{
    if (owned()) return *this;
    style.gradient = enabled;
    objGradientAuthored = true;
    return *this;
}

Object& Object::gradient(Color end) noexcept
{
    if (owned()) return *this;
    style.gradient = true;
    style.gradientEnd = end;
    objGradientAuthored = true;
    objGradientEndAuthored = true;
    return *this;
}

Result Object::dash(const float* pattern, uint32_t count, float offset) noexcept
{
    if (owned()) return Result::InsufficientCondition;
    if ((pattern && !count) || (!pattern && count) || count > Style::DashLimit
        || !std::isfinite(offset)) {
        return Result::InvalidArguments;
    }
    auto visible = false;
    for (auto i = 0u; i < count; i++) {
        if (!std::isfinite(pattern[i]) || pattern[i] < 0.0f) return Result::InvalidArguments;
        if (pattern[i] > 0.0f) visible = true;
    }
    if (count && !visible) return Result::InvalidArguments;
    for (auto i = 0u; i < Style::DashLimit; i++) {
        style.dash[i] = i < count ? pattern[i] : 0.0f;
    }
    style.dashCount = static_cast<uint8_t>(count);
    style.dashOffset = count ? offset : 0.0f;
    return Result::Success;
}

Object& Object::fill(Color color) noexcept
{
    if (owned()) return *this;
    style.fill = color;
    objColorAuthored = true;
    return *this;
}

Object& Object::shift(const Vec3& by) noexcept
{
    if (owned()) return *this;
    model = Mat4::translate(by) * model;
    return *this;
}

Object& Object::scale(const Vec3& by) noexcept
{
    if (owned()) return *this;
    model = Mat4::scale(by) * model;
    return *this;
}

Object& Object::rotateX(float radians) noexcept
{
    if (owned()) return *this;
    model = Mat4::rotateX(radians) * model;
    return *this;
}

Object& Object::rotateY(float radians) noexcept
{
    if (owned()) return *this;
    model = Mat4::rotateY(radians) * model;
    return *this;
}

Object& Object::rotateZ(float radians) noexcept
{
    if (owned()) return *this;
    model = Mat4::rotateZ(radians) * model;
    return *this;
}

Object& Object::transform(const Mat4& by) noexcept
{
    if (owned()) return *this;
    model = by * model;
    return *this;
}

Line::Line(const Vec3& from, const Vec3& to) noexcept : Object(Type::Line), from(from), to(to)
{
}

Line* Line::gen(const Vec3& from, const Vec3& to) noexcept
{
    return new (std::nothrow) Line(from, to);
}

Arrow::Arrow(const Vec3& from, const Vec3& to) noexcept : Object(Type::Arrow), from(from), to(to)
{
}

Arrow* Arrow::gen(const Vec3& from, const Vec3& to) noexcept
{
    return new (std::nothrow) Arrow(from, to);
}

Point::Point(const Vec3& point) noexcept : Object(Type::Point), point(point)
{
    style.fill = style.stroke;
}

Point* Point::gen(const Vec3& point) noexcept
{
    return new (std::nothrow) Point(point);
}

Text::Text(const char* text, const Vec3& point) noexcept : Object(Type::Text), point(point), objText(_copy(text))
{
    style.fill = style.stroke;
    style.stroke.a = 0;
}

Text::~Text()
{
    delete[] objText;
    delete[] objFont;
}

Text* Text::gen(const char* text, const Vec3& point) noexcept
{
    if (!text) return nullptr;
    auto object = new (std::nothrow) Text(text, point);
    if (!object || object->objText) return object;
    delete object;
    return nullptr;
}

const char* Text::text() const noexcept
{
    return objText;
}

Result Text::text(const char* value) noexcept
{
    if (!value) return Result::InvalidArguments;
    auto copy = _copy(value);
    if (!copy) return Result::OutOfMemory;
    auto previous = objText;
    objText = copy;
    if (!objOwner) {
        delete[] previous;
        return Result::Success;
    }
    auto result = objOwner->update(this);
    if (result == Result::Success) {
        delete[] previous;
        return result;
    }
    delete[] objText;
    objText = previous;
    return result;
}

const char* Text::font() const noexcept
{
    return objFont;
}

Result Text::font(const char* value) noexcept
{
    if (owned()) return Result::InsufficientCondition;
    auto copy = _copy(value);
    if (value && !copy) return Result::OutOfMemory;
    delete[] objFont;
    objFont = copy;
    return Result::Success;
}

Result Object::label(Text* text) noexcept
{
    return add(text);
}

Vector::Vector(const Vec3& value, const Vec3& origin) noexcept : Object(Type::Vector), value(value), origin(origin)
{
}

Vector* Vector::gen(const Vec3& value, const Vec3& origin) noexcept
{
    return new (std::nothrow) Vector(value, origin);
}

Group::Group() noexcept : Object(Type::Group)
{
    style.stroke.a = 0;
    style.fill.a = 0;
    style.width = 0.0f;
}

Group* Group::gen() noexcept
{
    return new (std::nothrow) Group;
}

Space::Space(const Range& x, const Range& y, const Range& z) noexcept : Object(Type::Space), x(x), y(y), z(z)
{
    style.stroke = {55, 65, 81, 180};
    style.width = 1.0f;
    layer = -10;
}

Space::~Space()
{
}

Space* Space::gen(const Range& x, const Range& y, const Range& z) noexcept
{
    if (x.step <= 0.0f || y.step <= 0.0f || z.step <= 0.0f) return nullptr;
    if (x.min > x.max || y.min > y.max || z.min > z.max) return nullptr;
    return new (std::nothrow) Space(x, y, z);
}

Result Space::add(Object* object) noexcept
{
    if (objSampling) return Result::InsufficientCondition;
    return Object::add(object);
}

uint32_t Space::count() const noexcept
{
    return childCount();
}

Object* Space::objectAt(uint32_t index) const noexcept
{
    return childAt(index);
}

static Result _samples(const Range& range, float& first, uint32_t& count) noexcept
{
    if (!std::isfinite(range.min) || !std::isfinite(range.max)
        || !std::isfinite(range.step) || range.min > range.max || range.step <= 0.0f) {
        return Result::InvalidArguments;
    }
    auto step = static_cast<double>(range.step);
    auto start = std::ceil(static_cast<double>(range.min) / step) * step;
    auto tolerance = step * 0.001;
    if (!std::isfinite(start) || start > static_cast<double>(range.max) + tolerance) {
        return Result::InsufficientCondition;
    }
    auto samples = std::floor((static_cast<double>(range.max) + tolerance - start) / step) + 1.0;
    if (!std::isfinite(samples) || samples < 1.0 || samples > 4096.0) {
        return Result::InsufficientCondition;
    }
    first = static_cast<float>(start);
    count = static_cast<uint32_t>(samples);
    return Result::Success;
}

struct CellSample
{
    CellSampler callback = nullptr;
    void* data = nullptr;
};

static bool _sampleCell(float x, float y, float, float time,
                        Color& color, void* data) noexcept
{
    auto context = static_cast<CellSample*>(data);
    return context->callback(x, y, time, color, context->data);
}

Result Space::cell(CellSampler callback, Group*& cells, void* data,
                   CellMode mode, float padding, const SampleTime& time) noexcept
{
    cells = nullptr;
    if (!callback) return Result::InvalidArguments;
    auto context = CellSample{callback, data};
    return sample(_sampleCell, cells, &context, mode, padding, time, false);
}

Result Space::voxel(VoxelSampler callback, Group*& voxels, void* data,
                    CellMode mode, float padding, const SampleTime& time) noexcept
{
    return sample(callback, voxels, data, mode, padding, time, true);
}

static Result _timeFrames(const SampleTime& time, uint64_t volume,
                          uint32_t& frames) noexcept
{
    static constexpr uint64_t MaxColors = 262144u;
    if (!std::isfinite(time.duration) || time.duration < 0.0f || !time.fps) {
        return Result::InvalidArguments;
    }
    if (time.duration == 0.0f) {
        frames = 1u;
    } else {
        auto intervals = std::ceil(static_cast<double>(time.duration) * time.fps);
        if (!std::isfinite(intervals) || intervals < 1.0 || intervals > 4095.0) {
            return Result::InsufficientCondition;
        }
        frames = static_cast<uint32_t>(intervals) + 1u;
    }
    if (volume > MaxColors / frames) return Result::InsufficientCondition;
    return Result::Success;
}

Result Space::sample(VoxelSampler callback, Group*& output, void* data,
                     CellMode mode, float padding, const SampleTime& time,
                     bool spatial) noexcept
{
    output = nullptr;
    if (objSampling) return Result::InsufficientCondition;
    if (!callback || (mode != CellMode::Full && mode != CellMode::Padd)
        || !std::isfinite(padding) || padding < 0.0f || padding >= 0.5f) {
        return Result::InvalidArguments;
    }
    float starts[3];
    uint32_t counts[3];
    auto result = _samples(x, starts[0], counts[0]);
    if (result != Result::Success) return result;
    result = _samples(y, starts[1], counts[1]);
    if (result != Result::Success) return result;
    if (spatial) {
        result = _samples(z, starts[2], counts[2]);
        if (result != Result::Success) return result;
    } else {
        starts[2] = 0.0f;
        counts[2] = 1u;
    }
    auto slice = static_cast<uint64_t>(counts[0]) * counts[1];
    auto volume = slice * counts[2];
    if (slice > 16384u || volume > 65536u) return Result::InsufficientCondition;
    uint32_t frames;
    result = _timeFrames(time, volume, frames);
    if (result != Result::Success) return result;

    auto group = Group::gen();
    if (!group) return Result::OutOfMemory;
    for (auto iz = 0u; iz < counts[2]; iz++) {
        auto cell = Cell::gen({}, counts[0], counts[1], {}, mode, padding);
        if (!cell) {
            delete group;
            return Result::OutOfMemory;
        }
        result = cell->frames(frames, time.duration);
        if (result != Result::Success) {
            delete cell;
            delete group;
            return result;
        }
        auto zStep = spatial ? z.step : 1.0f;
        auto zValue = starts[2] + static_cast<float>(iz) * zStep;
        cell->model = Mat4::translate({
            starts[0] - x.step * 0.5f,
            starts[1] - y.step * 0.5f,
            zValue - zStep * 0.5f}) * Mat4::scale({x.step, y.step, zStep});
        result = group->add(cell);
        if (result != Result::Success) {
            delete cell;
            delete group;
            return result;
        }
    }

    objSampling = true;
    for (auto frame = 0u; frame < frames; frame++) {
        auto sampleTime = frames > 1u
                        ? time.duration * static_cast<float>(frame) / static_cast<float>(frames - 1u)
                        : 0.0f;
        for (auto iz = 0u; iz < counts[2]; iz++) {
            auto cell = static_cast<Cell*>(group->childAt(iz));
            auto zStep = spatial ? z.step : 1.0f;
            auto zValue = starts[2] + static_cast<float>(iz) * zStep;
            for (auto iy = 0u; iy < counts[1]; iy++) {
                auto yValue = starts[1] + static_cast<float>(iy) * y.step;
                for (auto ix = 0u; ix < counts[0]; ix++) {
                    auto xValue = starts[0] + static_cast<float>(ix) * x.step;
                    Color color;
                    if (!callback(xValue, yValue, zValue, sampleTime, color, data)) {
                        objSampling = false;
                        delete group;
                        return Result::InvalidArguments;
                    }
                    auto index = static_cast<size_t>(frame) * slice
                               + static_cast<size_t>(iy) * counts[0] + ix;
                    cell->objColors[index] = color;
                }
            }
        }
    }
    objSampling = false;
    result = add(group);
    if (result != Result::Success) {
        delete group;
        return result;
    }
    output = group;
    return Result::Success;
}

static Mat4 _world(const Space* space)
{
    auto matrix = space->model;
    for (auto parent = space->parent(); parent; parent = parent->parent())
        matrix = parent->model * matrix;
    return matrix;
}

Vec3 Space::c2w(const Vec3& coordinate) const noexcept
{
    return _world(this) * coordinate;
}

bool Space::w2c(const Vec3& world, Vec3& coordinate) const noexcept
{
    auto matrix = _world(this);
    auto a = static_cast<double>(matrix.e[0]);
    auto b = static_cast<double>(matrix.e[1]);
    auto c = static_cast<double>(matrix.e[2]);
    auto d = static_cast<double>(matrix.e[4]);
    auto e = static_cast<double>(matrix.e[5]);
    auto f = static_cast<double>(matrix.e[6]);
    auto g = static_cast<double>(matrix.e[8]);
    auto h = static_cast<double>(matrix.e[9]);
    auto i = static_cast<double>(matrix.e[10]);
    auto det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
    auto scale = std::fmax(std::fmax(std::fabs(a), std::fabs(b)), std::fabs(c));
    scale = std::fmax(scale, std::fmax(std::fmax(std::fabs(d), std::fabs(e)), std::fabs(f)));
    scale = std::fmax(scale, std::fmax(std::fmax(std::fabs(g), std::fabs(h)), std::fabs(i)));
    if (!std::isfinite(det) || scale == 0.0 || std::fabs(det) <= std::numeric_limits<double>::epsilon() * scale * scale * scale) {
        return false;
    }
    auto x = static_cast<double>(world.x) - matrix.e[3];
    auto y = static_cast<double>(world.y) - matrix.e[7];
    auto z = static_cast<double>(world.z) - matrix.e[11];
    auto inv = 1.0 / det;
    auto result = Vec3{
        static_cast<float>(((e * i - f * h) * x + (c * h - b * i) * y + (b * f - c * e) * z) * inv),
        static_cast<float>(((f * g - d * i) * x + (a * i - c * g) * y + (c * d - a * f) * z) * inv),
        static_cast<float>(((d * h - e * g) * x + (b * g - a * h) * y + (a * e - b * d) * z) * inv)};
    if (!std::isfinite(result.x) || !std::isfinite(result.y) || !std::isfinite(result.z)) return false;
    coordinate = result;
    return true;
}

Circle::Circle(const Vec3& center, float radius) noexcept : Object(Type::Circle), center(center), radius(radius)
{
}

Circle* Circle::gen(const Vec3& center, float radius) noexcept
{
    if (radius <= 0.0f) return nullptr;
    return new (std::nothrow) Circle(center, radius);
}

Polygon::Polygon(const Vec3* points, uint32_t count) noexcept : Object(Type::Polygon), objCount(count)
{
    objPoints = new (std::nothrow) Vec3[count];
    if (objPoints) std::memcpy(objPoints, points, sizeof(Vec3) * count);
}

Polygon::~Polygon()
{
    delete[] objPoints;
}

Polygon* Polygon::gen(const Vec3* points, uint32_t count) noexcept
{
    if (!points || count < 3) return nullptr;
    auto object = new (std::nothrow) Polygon(points, count);
    if (!object || object->objPoints) return object;
    delete object;
    return nullptr;
}

const Vec3* Polygon::points() const noexcept
{
    return objPoints;
}

uint32_t Polygon::count() const noexcept
{
    return objCount;
}

Plot::Plot(const Vec3* points, uint32_t count) noexcept : Object(Type::Plot), objCount(count)
{
    objPoints = new (std::nothrow) Vec3[count];
    if (objPoints) std::memcpy(objPoints, points, sizeof(Vec3) * count);
}

Plot::~Plot()
{
    delete[] objPoints;
}

Plot* Plot::gen(const Vec3* points, uint32_t count) noexcept
{
    if (!points || count < 2) return nullptr;
    auto object = new (std::nothrow) Plot(points, count);
    if (!object || object->objPoints) return object;
    delete object;
    return nullptr;
}

const Vec3* Plot::points() const noexcept
{
    return objPoints;
}

uint32_t Plot::count() const noexcept
{
    return objCount;
}

DirectedRoute::DirectedRoute(const Vec3* points, uint32_t count) noexcept : Object(Type::Route), objCount(count)
{
    objPoints = new (std::nothrow) Vec3[count];
    if (objPoints) std::memcpy(objPoints, points, sizeof(Vec3) * count);
}

DirectedRoute::~DirectedRoute()
{
    delete[] objPoints;
}

DirectedRoute* DirectedRoute::gen(const Vec3* points, uint32_t count) noexcept
{
    if (!points || count < 2) return nullptr;
    auto object = new (std::nothrow) DirectedRoute(points, count);
    if (!object || object->objPoints) return object;
    delete object;
    return nullptr;
}

const Vec3* DirectedRoute::points() const noexcept
{
    return objPoints;
}

uint32_t DirectedRoute::count() const noexcept
{
    return objCount;
}

static constexpr uint32_t PATH_SAMPLE_LIMIT = 1024u;

PathCommand PathCommand::move(const Vec3& to) noexcept
{
    return {PathVerb::Move, to, {}, {}};
}

PathCommand PathCommand::line(const Vec3& to) noexcept
{
    return {PathVerb::Line, to, {}, {}};
}

PathCommand PathCommand::quadratic(const Vec3& control, const Vec3& to) noexcept
{
    return {PathVerb::Quadratic, to, control, {}};
}

PathCommand PathCommand::cubic(const Vec3& control1, const Vec3& control2,
                               const Vec3& to) noexcept
{
    return {PathVerb::Cubic, to, control1, control2};
}

PathCommand PathCommand::close() noexcept
{
    return {PathVerb::Close, {}, {}, {}};
}

static Vec3 _quadratic(const Vec3& from, const Vec3& control, const Vec3& to, float t)
{
    auto inverse = 1.0f - t;
    return from * (inverse * inverse) + control * (2.0f * inverse * t) + to * (t * t);
}

static Vec3 _cubic(const Vec3& from, const Vec3& control1, const Vec3& control2,
                   const Vec3& to, float t)
{
    auto inverse = 1.0f - t;
    auto inverse2 = inverse * inverse;
    auto t2 = t * t;
    return from * (inverse2 * inverse) + control1 * (3.0f * inverse2 * t)
         + control2 * (3.0f * inverse * t2) + to * (t2 * t);
}

Path::Path(Vec3* points, uint32_t count, bool closed) noexcept :
    Object(Type::Path), objPoints(points), objCount(count), objClosed(closed)
{
}

Path::~Path()
{
    delete[] objPoints;
}

Path* Path::gen(const PathCommand* commands, uint32_t count, uint32_t samples) noexcept
{
    if (!commands || count < 2u || !samples || samples > PATH_SAMPLE_LIMIT
        || commands[0].verb != PathVerb::Move) {
        return nullptr;
    }
    auto points = uint64_t{1};
    auto closed = false;
    for (auto i = 1u; i < count; i++) {
        switch (commands[i].verb) {
            case PathVerb::Line: points++; break;
            case PathVerb::Quadratic:
            case PathVerb::Cubic: points += samples; break;
            case PathVerb::Close: {
                if (i + 1u != count) return nullptr;
                closed = true;
                break;
            }
            case PathVerb::Move: return nullptr;
            default: return nullptr;
        }
        if (points > UINT32_MAX) return nullptr;
    }
    if (points < (closed ? 3u : 2u)) return nullptr;
    auto output = new (std::nothrow) Vec3[static_cast<uint32_t>(points)];
    if (!output) return nullptr;
    auto cursor = 0u;
    output[cursor++] = commands[0].to;
    for (auto i = 1u; i < count; i++) {
        auto& command = commands[i];
        auto from = output[cursor - 1u];
        switch (command.verb) {
            case PathVerb::Line: output[cursor++] = command.to; break;
            case PathVerb::Quadratic: {
                for (auto sample = 1u; sample <= samples; sample++) {
                    auto t = static_cast<float>(sample) / static_cast<float>(samples);
                    output[cursor++] = _quadratic(from, command.control1, command.to, t);
                }
                break;
            }
            case PathVerb::Cubic: {
                for (auto sample = 1u; sample <= samples; sample++) {
                    auto t = static_cast<float>(sample) / static_cast<float>(samples);
                    output[cursor++] = _cubic(from, command.control1, command.control2, command.to, t);
                }
                break;
            }
            case PathVerb::Close:
            case PathVerb::Move: break;
        }
    }
    auto object = new (std::nothrow) Path(output, cursor, closed);
    if (object) return object;
    delete[] output;
    return nullptr;
}

const Vec3* Path::points() const noexcept
{
    return objPoints;
}

uint32_t Path::count() const noexcept
{
    return objCount;
}

bool Path::closed() const noexcept
{
    return objClosed;
}

Curve::Curve(Vec3* points, uint32_t count) noexcept :
    Object(Type::Curve), objPoints(points), objCount(count)
{
}

Curve::~Curve()
{
    delete[] objPoints;
}

Curve* Curve::gen(const Vec3& from, const Vec3& control1, const Vec3& control2,
                  const Vec3& to, uint32_t samples) noexcept
{
    if (!samples || samples > PATH_SAMPLE_LIMIT) return nullptr;
    auto points = new (std::nothrow) Vec3[samples + 1u];
    if (!points) return nullptr;
    points[0] = from;
    for (auto sample = 1u; sample <= samples; sample++) {
        auto t = static_cast<float>(sample) / static_cast<float>(samples);
        points[sample] = _cubic(from, control1, control2, to, t);
    }
    auto object = new (std::nothrow) Curve(points, samples + 1u);
    if (object) return object;
    delete[] points;
    return nullptr;
}

const Vec3* Curve::points() const noexcept
{
    return objPoints;
}

uint32_t Curve::count() const noexcept
{
    return objCount;
}

SurfaceMesh::SurfaceMesh(const Vec3* points, uint32_t columns, uint32_t rows) noexcept :
    Object(Type::SurfaceMesh), objColumns(columns), objRows(rows)
{
    if (rows <= std::numeric_limits<size_t>::max() / columns) {
        auto count = static_cast<size_t>(columns) * rows;
        objPoints = new (std::nothrow) Vec3[count];
        if (objPoints) std::memcpy(objPoints, points, count * sizeof(Vec3));
    }
    style.fill = {91, 141, 239, 255};
    style.stroke = {35, 55, 84, 255};
    style.width = 1.0f;
}

SurfaceMesh::~SurfaceMesh()
{
    delete[] objPoints;
}

SurfaceMesh* SurfaceMesh::gen(const Vec3* points, uint32_t columns,
                              uint32_t rows) noexcept
{
    if (!points || columns < 2u || rows < 2u || rows > 65536u / columns) return nullptr;
    auto object = new (std::nothrow) SurfaceMesh(points, columns, rows);
    if (!object || object->objPoints) return object;
    delete object;
    return nullptr;
}

const Vec3* SurfaceMesh::points() const noexcept
{
    return objPoints;
}

uint32_t SurfaceMesh::columns() const noexcept
{
    return objColumns;
}

uint32_t SurfaceMesh::rows() const noexcept
{
    return objRows;
}

Ruler::Ruler(const Vec3& from, const Vec3& to, float step) noexcept : Object(Type::Ruler), from(from), to(to), step(step)
{
}

Ruler* Ruler::gen(const Vec3& from, const Vec3& to, float step) noexcept
{
    if (step <= 0.0f || (to - from).length() < 1e-7f) return nullptr;
    return new (std::nothrow) Ruler(from, to, step);
}

Svg::Svg(const char* path, const Vec3& center, float width) noexcept : Object(Type::Svg), center(center), width(width), objPath(_copy(path))
{
}

Svg::~Svg()
{
    delete[] objPath;
}

Svg* Svg::gen(const char* path, const Vec3& center, float width) noexcept
{
    if (!path || width <= 0.0f) return nullptr;
    auto object = new (std::nothrow) Svg(path, center, width);
    if (!object || object->objPath) return object;
    delete object;
    return nullptr;
}

const char* Svg::path() const noexcept
{
    return objPath;
}

Image::Image(const Asset* asset, const Vec3& center, float width) noexcept :
    Object(Type::Image), center(center), width(width), objWidth(asset->width()), objHeight(asset->height())
{
    if (objHeight <= std::numeric_limits<size_t>::max() / objWidth) {
        auto count = static_cast<size_t>(objWidth) * objHeight;
        objPixels = new (std::nothrow) uint32_t[count];
        if (objPixels) std::memcpy(objPixels, asset->data(), count * sizeof(uint32_t));
    }
}

Image::~Image()
{
    delete[] objPixels;
}

Image* Image::gen(const Asset* asset, const Vec3& center, float width) noexcept
{
    if (!asset || !asset->data() || !asset->width() || !asset->height() || !std::isfinite(width) || width <= 0.0f) {
        return nullptr;
    }
    auto object = new (std::nothrow) Image(asset, center, width);
    if (!object || object->objPixels) return object;
    delete object;
    return nullptr;
}

uint32_t Image::pixelWidth() const noexcept
{
    return objWidth;
}

uint32_t Image::pixelHeight() const noexcept
{
    return objHeight;
}

const uint32_t* Image::pixels() const noexcept
{
    return objPixels;
}

Cell::Cell(const Vec3& origin, uint32_t columns, uint32_t rows, Color color,
           CellMode mode, float padding) noexcept :
    Object(Type::Cell), origin(origin), mode(mode), padding(padding), objColumns(columns), objRows(rows)
{
    if (rows <= std::numeric_limits<size_t>::max() / columns) {
        auto count = static_cast<size_t>(columns) * rows;
        objColors = new (std::nothrow) Color[count];
        if (objColors) {
            for (auto i = 0u; i < count; i++)
                objColors[i] = color;
        }
    }
}

Cell::~Cell()
{
    delete[] objColors;
}

Cell* Cell::gen(const Vec3& origin, uint32_t columns, uint32_t rows, Color color,
                CellMode mode, float padding) noexcept
{
    if (!columns || !rows || rows > 16384u / columns || (mode != CellMode::Full && mode != CellMode::Padd) || !std::isfinite(padding) || padding < 0.0f || padding >= 0.5f) {
        return nullptr;
    }
    auto object = new (std::nothrow) Cell(origin, columns, rows, color, mode, padding);
    if (!object || object->objColors) return object;
    delete object;
    return nullptr;
}

Result Cell::frames(uint32_t count, float duration) noexcept
{
    if (!count || !std::isfinite(duration) || duration < 0.0f
        || (count == 1u) != (duration == 0.0f)) {
        return Result::InvalidArguments;
    }
    if (count == 1u) return Result::Success;
    auto size = static_cast<size_t>(objColumns) * objRows;
    if (size > std::numeric_limits<size_t>::max() / count) return Result::OutOfMemory;
    auto colors = new (std::nothrow) Color[size * count];
    if (!colors) return Result::OutOfMemory;
    delete[] objColors;
    objColors = colors;
    objFrames = count;
    objFrameDuration = duration;
    return Result::Success;
}

const Color* sampleColors(const Cell* cell, uint32_t frame) noexcept
{
    if (!cell || frame >= cell->objFrames) return nullptr;
    auto size = static_cast<size_t>(cell->objColumns) * cell->objRows;
    return cell->objColors + size * frame;
}

uint32_t sampleFrames(const Cell* cell) noexcept
{
    return cell ? cell->objFrames : 0u;
}

float sampleDuration(const Object* object) noexcept
{
    if (!object || object->type() != Type::Cell) return 0.0f;
    return static_cast<const Cell*>(object)->objFrameDuration;
}

uint32_t Cell::columns() const noexcept
{
    return objColumns;
}

uint32_t Cell::rows() const noexcept
{
    return objRows;
}

const Color* Cell::colors() const noexcept
{
    return objColors;
}

Result Cell::fill(const CellRegion& region, Color color) noexcept
{
    if (owned()) return Result::InsufficientCondition;
    if (!region.width || !region.height || region.x >= objColumns || region.y >= objRows || region.width > objColumns - region.x || region.height > objRows - region.y) {
        return Result::InvalidArguments;
    }
    for (auto y = region.y; y < region.y + region.height; y++) {
        for (auto x = region.x; x < region.x + region.width; x++)
            objColors[static_cast<size_t>(y) * objColumns + x] = color;
    }
    return Result::Success;
}

Result Cell::texture(const Asset* asset, const CellRegion& source,
                     const CellRegion& destination) noexcept
{
    if (owned()) return Result::InsufficientCondition;
    if (!asset || !asset->data() || !asset->width() || !asset->height()) return Result::InvalidArguments;
    auto src = source;
    auto dst = destination;
    if (!src.width) src.width = asset->width() - src.x;
    if (!src.height) src.height = asset->height() - src.y;
    if (!dst.width) dst.width = objColumns - dst.x;
    if (!dst.height) dst.height = objRows - dst.y;
    if (src.x >= asset->width() || src.y >= asset->height() || src.width > asset->width() - src.x || src.height > asset->height() - src.y || dst.x >= objColumns || dst.y >= objRows || dst.width > objColumns - dst.x || dst.height > objRows - dst.y || !src.width || !src.height || !dst.width || !dst.height) {
        return Result::InvalidArguments;
    }
    for (auto y = 0u; y < dst.height; y++) {
        auto sourceY = src.y + static_cast<uint32_t>((static_cast<uint64_t>(y) * src.height) / dst.height);
        auto targetY = dst.y + dst.height - y - 1u;
        for (auto x = 0u; x < dst.width; x++) {
            auto sourceX = src.x + static_cast<uint32_t>((static_cast<uint64_t>(x) * src.width) / dst.width);
            auto pixel = asset->data()[static_cast<size_t>(sourceY) * asset->width() + sourceX];
            objColors[static_cast<size_t>(targetY) * objColumns + dst.x + x] = {
                static_cast<uint8_t>(pixel), static_cast<uint8_t>(pixel >> 8u),
                static_cast<uint8_t>(pixel >> 16u), static_cast<uint8_t>(pixel >> 24u)};
        }
    }
    return Result::Success;
}

Rectangle::Rectangle(const Vec3& center, const Vec2& size, float corner) noexcept :
    Object(Type::Rectangle), center(center), size(size), corner(corner)
{
}

Rectangle* Rectangle::gen(const Vec3& center, const Vec2& size, float corner) noexcept
{
    if (!std::isfinite(size.x) || !std::isfinite(size.y) || size.x <= 0.0f || size.y <= 0.0f
        || !std::isfinite(corner) || corner < 0.0f || corner > std::fmin(size.x, size.y) * 0.5f) {
        return nullptr;
    }
    return new (std::nothrow) Rectangle(center, size, corner);
}

Connector::Connector(Object* from, Object* to) noexcept :
    Object(Type::Connector), source(from), destination(to)
{
    layer = -1;
}

Connector* Connector::gen(Object* from, Object* to) noexcept
{
    if (!from || !to || from == to) return nullptr;
    return new (std::nothrow) Connector(from, to);
}

Object* Connector::from() const noexcept
{
    return source;
}

Object* Connector::to() const noexcept
{
    return destination;
}

Vec3 Bounds::center() const noexcept
{
    return (min + max) * 0.5f;
}

Vec3 Bounds::size() const noexcept
{
    return max - min;
}

Vec2 BBox::center() const noexcept
{
    return {x + width * 0.5f, y + height * 0.5f};
}

Vec2 BBox::size() const noexcept
{
    return {width, height};
}

bool BBox::intersects(const BBox& other, float padding) const noexcept
{
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) || !std::isfinite(height)
        || !std::isfinite(other.x) || !std::isfinite(other.y) || !std::isfinite(other.width)
        || !std::isfinite(other.height) || !std::isfinite(padding) || width <= 0.0f
        || height <= 0.0f || other.width <= 0.0f || other.height <= 0.0f || padding < 0.0f) {
        return false;
    }
    return x < other.x + other.width + padding && other.x < x + width + padding
        && y < other.y + other.height + padding && other.y < y + height + padding;
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

bool localBounds(const Object* object, Bounds& bounds) noexcept
{
    auto defined = false;
    switch (object->type()) {
        case Type::Group:
        case Type::Connector: return false;
        case Type::Point: _include(bounds, defined, static_cast<const Point*>(object)->point); break;
        case Type::Line: {
            auto line = static_cast<const Line*>(object);
            _include(bounds, defined, line->from);
            _include(bounds, defined, line->to);
            break;
        }
        case Type::Arrow: {
            auto arrow = static_cast<const Arrow*>(object);
            _include(bounds, defined, arrow->from);
            _include(bounds, defined, arrow->to);
            break;
        }
        case Type::Vector: {
            auto vector = static_cast<const Vector*>(object);
            _include(bounds, defined, vector->origin);
            _include(bounds, defined, vector->origin + vector->value);
            break;
        }
        case Type::Circle: {
            auto circle = static_cast<const Circle*>(object);
            auto radius = Vec3{circle->radius, circle->radius, 0.0f};
            _include(bounds, defined, circle->center - radius);
            _include(bounds, defined, circle->center + radius);
            break;
        }
        case Type::Rectangle: {
            auto rectangle = static_cast<const Rectangle*>(object);
            auto half = Vec3{rectangle->size.x * 0.5f, rectangle->size.y * 0.5f, 0.0f};
            _include(bounds, defined, rectangle->center - half);
            _include(bounds, defined, rectangle->center + half);
            break;
        }
        case Type::Polygon: {
            auto polygon = static_cast<const Polygon*>(object);
            for (auto i = 0u; i < polygon->count(); i++)
                _include(bounds, defined, polygon->points()[i]);
            break;
        }
        case Type::Plot: {
            auto plot = static_cast<const Plot*>(object);
            for (auto i = 0u; i < plot->count(); i++)
                _include(bounds, defined, plot->points()[i]);
            break;
        }
        case Type::Route: {
            auto route = static_cast<const DirectedRoute*>(object);
            for (auto i = 0u; i < route->count(); i++)
                _include(bounds, defined, route->points()[i]);
            break;
        }
        case Type::Path: {
            auto path = static_cast<const Path*>(object);
            for (auto i = 0u; i < path->count(); i++)
                _include(bounds, defined, path->points()[i]);
            break;
        }
        case Type::Curve: {
            auto curve = static_cast<const Curve*>(object);
            for (auto i = 0u; i < curve->count(); i++)
                _include(bounds, defined, curve->points()[i]);
            break;
        }
        case Type::SurfaceMesh: {
            auto surface = static_cast<const SurfaceMesh*>(object);
            auto count = surface->columns() * surface->rows();
            for (auto i = 0u; i < count; i++)
                _include(bounds, defined, surface->points()[i]);
            break;
        }
        case Type::Text: _include(bounds, defined, static_cast<const Text*>(object)->point); break;
        case Type::Ruler: {
            auto ruler = static_cast<const Ruler*>(object);
            _include(bounds, defined, ruler->from);
            _include(bounds, defined, ruler->to);
            break;
        }
        case Type::Space: {
            auto space = static_cast<const Space*>(object);
            _include(bounds, defined, {space->x.min, space->y.min, space->z.min});
            _include(bounds, defined, {space->x.max, space->y.max, space->z.max});
            break;
        }
        case Type::Svg: {
            auto svg = static_cast<const Svg*>(object);
            auto half = Vec3{svg->width * 0.5f, svg->width * 0.5f, 0.0f};
            _include(bounds, defined, svg->center - half);
            _include(bounds, defined, svg->center + half);
            break;
        }
        case Type::Image: {
            auto image = static_cast<const Image*>(object);
            auto height = image->width * static_cast<float>(image->pixelHeight()) / image->pixelWidth();
            auto half = Vec3{image->width * 0.5f, height * 0.5f, 0.0f};
            _include(bounds, defined, image->center - half);
            _include(bounds, defined, image->center + half);
            break;
        }
        case Type::Cell: {
            auto cell = static_cast<const Cell*>(object);
            _include(bounds, defined, cell->origin);
            _include(bounds, defined,
                     cell->origin + Vec3{static_cast<float>(cell->columns()), static_cast<float>(cell->rows()), cell->depth});
            break;
        }
    }
    return defined;
}

static void _transform(const Bounds& source, const Mat4& matrix, Bounds& output, bool& defined)
{
    for (auto x = 0u; x < 2u; x++) {
        for (auto y = 0u; y < 2u; y++) {
            for (auto z = 0u; z < 2u; z++) {
                _include(output, defined, matrix * Vec3{
                    x ? source.max.x : source.min.x,
                    y ? source.max.y : source.min.y,
                    z ? source.max.z : source.min.z});
            }
        }
    }
}

static bool _bounds(const Object* object, const Mat4& parent, Bounds& output, bool& defined)
{
    if (!valid(object)) return false;
    auto model = parent * object->model;
    Bounds local;
    if (localBounds(object, local)) _transform(local, model, output, defined);
    for (auto i = 0u; i < object->childCount(); i++) {
        if (!_bounds(object->childAt(i), model, output, defined)) return false;
    }
    return true;
}

bool Object::bounds(Bounds& output) const noexcept
{
    auto defined = false;
    return _bounds(this, Mat4::identity(), output, defined) && defined;
}

Result Object::layout(const Mat4& value) noexcept
{
    auto previous = model;
    model = value;
    if (!objOwner) return Result::Success;
    auto result = objOwner->update(this);
    if (result == Result::Success) return result;
    model = previous;
    return result;
}

Result Object::moveTo(const Vec3& point) noexcept
{
    if (!std::isfinite(point.x) || !std::isfinite(point.y) || !std::isfinite(point.z)) {
        return Result::InvalidArguments;
    }
    Bounds box;
    if (!bounds(box)) return Result::InsufficientCondition;
    return layout(Mat4::translate(point - box.center()) * model);
}

static float _support(const Bounds& bounds, const Vec3& direction)
{
    auto half = bounds.size() * 0.5f;
    return std::fabs(direction.x) * half.x + std::fabs(direction.y) * half.y + std::fabs(direction.z) * half.z;
}

Result Object::nextTo(const Object* target, const Vec3& direction, float gap) noexcept
{
    if (!target || target == this || target->objParent != objParent || target->objOwner != objOwner
        || !std::isfinite(gap) || gap < 0.0f) {
        return Result::InvalidArguments;
    }
    auto length = direction.length();
    if (!std::isfinite(length) || length <= 1.0e-7f) return Result::InvalidArguments;
    Bounds own;
    Bounds other;
    if (!bounds(own) || !target->bounds(other)) return Result::InsufficientCondition;
    auto axis = direction / length;
    auto point = other.center() + axis * (_support(other, axis) + gap + _support(own, axis));
    return layout(Mat4::translate(point - own.center()) * model);
}

Result Object::alignTo(const Object* target, const Vec3& direction) noexcept
{
    if (!target || target == this || target->objParent != objParent || target->objOwner != objOwner) {
        return Result::InvalidArguments;
    }
    if (!std::isfinite(direction.x) || !std::isfinite(direction.y) || !std::isfinite(direction.z)
        || (direction.x == 0.0f && direction.y == 0.0f && direction.z == 0.0f)) {
        return Result::InvalidArguments;
    }
    Bounds own;
    Bounds other;
    if (!bounds(own) || !target->bounds(other)) return Result::InsufficientCondition;
    Vec3 shift;
    if (direction.x > 0.0f) shift.x = other.max.x - own.max.x;
    else if (direction.x < 0.0f) shift.x = other.min.x - own.min.x;
    if (direction.y > 0.0f) shift.y = other.max.y - own.max.y;
    else if (direction.y < 0.0f) shift.y = other.min.y - own.min.y;
    if (direction.z > 0.0f) shift.z = other.max.z - own.max.z;
    else if (direction.z < 0.0f) shift.z = other.min.z - own.min.z;
    return layout(Mat4::translate(shift) * model);
}

Result Group::arrange(const Vec3& direction, float gap) noexcept
{
    if (!std::isfinite(gap) || gap < 0.0f) return Result::InvalidArguments;
    auto length = direction.length();
    if (!std::isfinite(length) || length <= 1.0e-7f) return Result::InvalidArguments;
    if (objOwner && objOwner->update(this) != Result::Success) return Result::InsufficientCondition;
    auto items = new (std::nothrow) Object*[childCnt];
    auto boxes = new (std::nothrow) Bounds[childCnt];
    auto positions = new (std::nothrow) float[childCnt];
    if ((!items || !boxes || !positions) && childCnt) {
        delete[] items;
        delete[] boxes;
        delete[] positions;
        return Result::OutOfMemory;
    }
    auto count = 0u;
    for (auto i = 0u; i < childCnt; i++) {
        Bounds box;
        if (!children[i]->bounds(box)) continue;
        items[count] = children[i];
        boxes[count++] = box;
    }
    if (!count) {
        delete[] items;
        delete[] boxes;
        delete[] positions;
        return Result::InsufficientCondition;
    }
    auto axis = direction / length;
    auto cursor = 0.0f;
    for (auto i = 0u; i < count; i++) {
        auto radius = _support(boxes[i], axis);
        positions[i] = cursor + radius;
        cursor += radius * 2.0f + gap;
    }
    auto total = cursor - gap;
    auto result = Result::Success;
    for (auto i = 0u; i < count; i++) {
        result = items[i]->moveTo(axis * (positions[i] - total * 0.5f));
        if (result != Result::Success) break;
    }
    delete[] items;
    delete[] boxes;
    delete[] positions;
    return result;
}

Result Group::arrangeGrid(uint32_t columns, float columnGap, float rowGap) noexcept
{
    if (!columns || !std::isfinite(columnGap) || !std::isfinite(rowGap)
        || columnGap < 0.0f || rowGap < 0.0f) {
        return Result::InvalidArguments;
    }
    if (objOwner && objOwner->update(this) != Result::Success) return Result::InsufficientCondition;
    auto items = new (std::nothrow) Object*[childCnt];
    auto boxes = new (std::nothrow) Bounds[childCnt];
    if ((!items || !boxes) && childCnt) {
        delete[] items;
        delete[] boxes;
        return Result::OutOfMemory;
    }
    auto count = 0u;
    for (auto i = 0u; i < childCnt; i++) {
        Bounds box;
        if (!children[i]->bounds(box)) continue;
        items[count] = children[i];
        boxes[count++] = box;
    }
    if (!count) {
        delete[] items;
        delete[] boxes;
        return Result::InsufficientCondition;
    }
    if (columns > count) columns = count;
    auto rows = (count + columns - 1u) / columns;
    auto widths = new (std::nothrow) float[columns]();
    auto heights = new (std::nothrow) float[rows]();
    if (!widths || !heights) {
        delete[] items;
        delete[] boxes;
        delete[] widths;
        delete[] heights;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < count; i++) {
        auto size = boxes[i].size();
        auto column = i % columns;
        auto row = i / columns;
        widths[column] = std::fmax(widths[column], size.x);
        heights[row] = std::fmax(heights[row], size.y);
    }
    auto width = columnGap * (columns - 1u);
    auto height = rowGap * (rows - 1u);
    for (auto i = 0u; i < columns; i++) width += widths[i];
    for (auto i = 0u; i < rows; i++) height += heights[i];
    auto result = Result::Success;
    auto y = height * 0.5f;
    for (auto row = 0u; row < rows && result == Result::Success; row++) {
        auto x = -width * 0.5f;
        for (auto column = 0u; column < columns; column++) {
            auto index = row * columns + column;
            if (index < count) {
                auto point = Vec3{x + widths[column] * 0.5f, y - heights[row] * 0.5f, 0.0f};
                result = items[index]->moveTo(point);
                if (result != Result::Success) break;
            }
            x += widths[column] + columnGap;
        }
        y -= heights[row] + rowGap;
    }
    delete[] items;
    delete[] boxes;
    delete[] widths;
    delete[] heights;
    return result;
}

}  // namespace tmath
