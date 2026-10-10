#include <cmath>
#include <cstdio>
#include <cstring>
#include <initializer_list>
#include <limits>

#include "tmath.h"

static constexpr auto _pi = 3.14159265358979323846f;
static auto _failures = 0;

static bool _close(float a, float b, float epsilon = 1.0e-4f)
{
    return std::fabs(a - b) <= epsilon;
}

static bool _close(const tmath::Vec2& a, const tmath::Vec2& b)
{
    return _close(a.x, b.x) && _close(a.y, b.y);
}

static bool _close(const tmath::Vec3& a, const tmath::Vec3& b)
{
    return _close(a.x, b.x) && _close(a.y, b.y) && _close(a.z, b.z);
}

static void _check(bool condition, const char* expression, int line)
{
    if (condition) return;
    std::fprintf(stderr, "%s:%d: CHECK(%s) failed\n", __FILE__, line, expression);
    _failures++;
}

#define CHECK(condition) _check((condition), #condition, __LINE__)

static void _vectors()
{
    auto a = tmath::Vec2{3.0f, 4.0f};
    CHECK(_close(a.length(), 5.0f));
    CHECK(_close(a.normalized(), {0.6f, 0.8f}));
    CHECK(_close(a + tmath::Vec2{1.0f, -2.0f}, {4.0f, 2.0f}));
    CHECK(_close(a.dot({-4.0f, 3.0f}), 0.0f));
    CHECK(_close(tmath::Vec2{}.normalized(), {}));
    CHECK(_close(tmath::Vec2{1.0e-7f, 0.0f}.normalized(), {1.0f, 0.0f}));
    auto large2 = tmath::Vec2{std::numeric_limits<float>::max(), std::numeric_limits<float>::max()}.normalized();
    CHECK(std::isfinite(large2.x) && std::isfinite(large2.y));
    CHECK(_close(large2.length(), 1.0f));

    auto x = tmath::Vec3{1.0f, 0.0f, 0.0f};
    auto y = tmath::Vec3{0.0f, 1.0f, 0.0f};
    CHECK(_close(x.cross(y), {0.0f, 0.0f, 1.0f}));
    CHECK(_close(x.cross(y).dot(x), 0.0f));
    auto large3 = tmath::Vec3{std::numeric_limits<float>::max(), std::numeric_limits<float>::max(),
                              std::numeric_limits<float>::max()}
                      .normalized();
    CHECK(std::isfinite(large3.x) && std::isfinite(large3.y) && std::isfinite(large3.z));
    CHECK(_close(large3.length(), 1.0f));
}

static void _matrices()
{
    auto model = tmath::Mat3::translate({3.0f, -1.0f}) * tmath::Mat3::rotate(_pi * 0.5f) * tmath::Mat3::scale({2.0f, 3.0f});
    CHECK(_close(model * tmath::Vec2{1.0f, 0.0f}, {3.0f, 1.0f}));

    auto inverse = tmath::Mat3{};
    CHECK(model.inverse(inverse));
    CHECK(_close(inverse * (model * tmath::Vec2{2.0f, -1.0f}), {2.0f, -1.0f}));
    auto singular = tmath::Mat3::scale({0.0f, 1.0f});
    CHECK(!singular.inverse(inverse));
    auto small = tmath::Mat3::scale({1.0e-4f, 1.0e-4f});
    CHECK(small.inverse(inverse));
    CHECK(_close(inverse * (small * tmath::Vec2{2.0f, -1.0f}), {2.0f, -1.0f}));
    auto projective2 = tmath::Mat3::identity();
    projective2.e[8] = 1.0e-7f;
    auto projected2 = projective2 * tmath::Vec2{1.0f, 2.0f};
    CHECK(projected2.x > 9.9e6f && projected2.y > 1.99e7f);
    projective2.e[8] = 0.0f;
    projected2 = projective2 * tmath::Vec2{1.0f, 2.0f};
    CHECK(!std::isfinite(projected2.x) && !std::isfinite(projected2.y));
    auto maximum = std::numeric_limits<float>::max();
    auto minimum = std::numeric_limits<float>::denorm_min();
    auto scaled2 = tmath::Mat3{};
    scaled2.e[0] = scaled2.e[4] = scaled2.e[8] = maximum;
    CHECK(_close(scaled2 * tmath::Vec2{2.0f, 3.0f}, {2.0f, 3.0f}));
    scaled2.e[0] = scaled2.e[4] = scaled2.e[8] = minimum;
    CHECK(_close(scaled2 * tmath::Vec2{0.5f, 1.5f}, {0.5f, 1.5f}));
    scaled2 = {};
    scaled2.e[0] = minimum;
    scaled2.e[8] = maximum;
    projected2 = scaled2 * tmath::Vec2{1.0f, 0.0f};
    CHECK(!std::isfinite(projected2.x) && !std::isfinite(projected2.y));
    auto cancellation2A = tmath::Mat3::identity();
    cancellation2A.e[0] = maximum;
    cancellation2A.e[1] = maximum;
    auto cancellation2B = tmath::Mat3::identity();
    cancellation2B.e[0] = 2.0f;
    cancellation2B.e[3] = -2.0f;
    auto cancelled2 = cancellation2A * cancellation2B;
    CHECK(cancelled2.e[0] == 0.0f && cancelled2.e[1] == maximum);

    auto model3 = tmath::Mat4::translate({1.0f, 2.0f, 3.0f}) * tmath::Mat4::rotateZ(_pi * 0.5f) * tmath::Mat4::scale({2.0f, 3.0f, 4.0f});
    CHECK(_close(model3 * tmath::Vec3{1.0f, 0.0f, 1.0f}, {1.0f, 4.0f, 7.0f}));
    CHECK(_close(tmath::Mat4::from(model) * tmath::Vec3{1.0f, 0.0f, 5.0f}, {3.0f, 1.0f, 5.0f}));
    auto projective3 = tmath::Mat4::identity();
    projective3.e[15] = 1.0e-7f;
    auto projected3 = projective3 * tmath::Vec3{1.0f, 2.0f, 3.0f};
    CHECK(projected3.x > 9.9e6f && projected3.z > 2.99e7f);
    projective3.e[15] = 0.0f;
    projected3 = projective3 * tmath::Vec3{1.0f, 2.0f, 3.0f};
    CHECK(!std::isfinite(projected3.x) && !std::isfinite(projected3.z));
    auto scaled3 = tmath::Mat4{};
    scaled3.e[0] = scaled3.e[5] = scaled3.e[10] = scaled3.e[15] = maximum;
    CHECK(_close(scaled3 * tmath::Vec3{2.0f, 3.0f, 4.0f}, {2.0f, 3.0f, 4.0f}));
    scaled3.e[0] = scaled3.e[5] = scaled3.e[10] = scaled3.e[15] = minimum;
    CHECK(_close(scaled3 * tmath::Vec3{0.5f, 1.5f, 2.5f}, {0.5f, 1.5f, 2.5f}));
    scaled3 = {};
    scaled3.e[0] = minimum;
    scaled3.e[15] = maximum;
    projected3 = scaled3 * tmath::Vec3{1.0f, 0.0f, 0.0f};
    CHECK(!std::isfinite(projected3.x) && !std::isfinite(projected3.y) && !std::isfinite(projected3.z));
    auto cancellation3A = tmath::Mat4::identity();
    cancellation3A.e[0] = maximum;
    cancellation3A.e[1] = maximum;
    auto cancellation3B = tmath::Mat4::identity();
    cancellation3B.e[0] = 2.0f;
    cancellation3B.e[4] = -2.0f;
    auto cancelled3 = cancellation3A * cancellation3B;
    CHECK(cancelled3.e[0] == 0.0f && cancelled3.e[1] == maximum);
}

static tmath::Camera _camera()
{
    auto camera = tmath::Camera{};
    camera.eye = {0.0f, 0.0f, 0.0f};
    camera.target = {0.0f, 0.0f, -1.0f};
    camera.up = {0.0f, 1.0f, 0.0f};
    camera.projection = tmath::Projection::Perspective;
    camera.fov = _pi * 0.5f;
    camera.near = 1.0f;
    camera.far = 11.0f;
    return camera;
}

static void _orthographic()
{
    auto camera = tmath::Camera{};
    camera.eye = {2.0f, -3.0f, 10.0f};
    camera.target = {2.0f, -3.0f, 0.0f};
    camera.orthoHeight = 6.0f;
    auto ndc = tmath::Vec3{};
    CHECK(camera.project({3.0f, -2.0f, 0.0f}, 1280.0f / 720.0f, ndc));
    CHECK(_close(ndc, {0.1875f, 1.0f / 3.0f, 0.0099505f}));

    auto expected = tmath::Vec2{-0.35f, 0.42f};
    auto ray = camera.ray(expected, 1280.0f / 720.0f);
    auto world = ray.origin + ray.direction * 10.0f;
    CHECK(camera.project(world, 1280.0f / 720.0f, ndc));
    CHECK(_close(tmath::Vec2{ndc.x, ndc.y}, expected));
}

static void _projection()
{
    auto camera = _camera();
    auto ndc = tmath::Vec3{};
    CHECK(camera.project({2.0f, 1.0f, -2.0f}, 2.0f, ndc));
    CHECK(_close(ndc, {0.5f, 0.5f, 0.1f}));
    CHECK(camera.project({8.0f, 0.0f, -2.0f}, 2.0f, ndc));
    CHECK(ndc.x > 1.0f);
    CHECK(!camera.project({0.0f, 0.0f, 1.0f}, 2.0f, ndc));
    CHECK(!camera.project({0.0f, 0.0f, -12.0f}, 2.0f, ndc));

    auto scaledCamera = _camera();
    scaledCamera.target = {0.0f, 0.0f, -1.0e-7f};
    scaledCamera.up = {0.0f, 1.0e-7f, 0.0f};
    scaledCamera.near = 1.0e-8f;
    CHECK(scaledCamera.project({0.0f, 0.0f, -1.0e-6f}, 1.0f, ndc));
    CHECK(_close(ndc.x, 0.0f) && _close(ndc.y, 0.0f));

    camera.projection = tmath::Projection::Orthographic;
    camera.orthoHeight = 4.0f;
    CHECK(camera.project({2.0f, 1.0f, -5.0f}, 2.0f, ndc));
    CHECK(_close(ndc, {0.5f, 0.5f, 0.4f}));
    camera.orthoHeight = 1.0e-7f;
    CHECK(camera.project({1.0e-8f, 0.0f, -5.0f}, 1.0f, ndc));
    CHECK(_close(ndc.x, 0.2f));
    camera.orthoHeight = 1.0e-40f;
    CHECK(camera.project({1.0e-41f, 0.0f, -5.0f}, 1.0f, ndc));
    CHECK(_close(ndc.x, 0.2f, 1.0e-3f));

    camera.projection = tmath::Projection::Perspective;
    camera.fov = std::numeric_limits<float>::denorm_min();
    CHECK(camera.project({std::numeric_limits<float>::denorm_min(), 0.0f, -2.0f}, 1.0f, ndc));
    CHECK(_close(ndc.x, 1.0f));

    auto nan = std::numeric_limits<float>::quiet_NaN();
    CHECK(!camera.project({nan, 0.0f, -5.0f}, 2.0f, ndc));
    CHECK(!camera.project({0.0f, 0.0f, -5.0f}, nan, ndc));

    camera.eye = {-std::numeric_limits<float>::max(), 0.0f, 0.0f};
    camera.target = {std::numeric_limits<float>::max(), 0.0f, 0.0f};
    CHECK(!camera.project({0.0f, 0.0f, 0.0f}, 1.0f, ndc));
}

static void _clipping()
{
    auto camera = _camera();
    auto from = tmath::Vec3{0.0f, 0.0f, -0.25f};
    auto to = tmath::Vec3{2.0f, 0.0f, -5.0f};
    CHECK(camera.segment(from, to));
    CHECK(_close(from.z, -1.0f));
    CHECK(_close(from.x, 0.3157895f));
    CHECK(_close(to, {2.0f, 0.0f, -5.0f}));

    from = {0.0f, 0.0f, -5.0f};
    to = {0.0f, 0.0f, -20.0f};
    CHECK(camera.segment(from, to));
    CHECK(_close(to.z, -11.0f));

    from = {0.0f, 0.0f, 0.5f};
    to = {0.0f, 0.0f, 2.0f};
    CHECK(!camera.segment(from, to));

    camera.eye = {-std::numeric_limits<float>::max(), 0.0f, 0.0f};
    camera.target = {std::numeric_limits<float>::max(), 0.0f, 0.0f};
    from = {0.0f, 0.0f, 0.0f};
    to = {1.0f, 0.0f, 0.0f};
    CHECK(!camera.segment(from, to));

    auto maximum = std::numeric_limits<float>::max();
    auto wide = tmath::Camera{};
    wide.eye = {-maximum, 0.0f, 0.0f};
    wide.target = {};
    wide.up = {0.0f, 1.0f, 0.0f};
    wide.projection = tmath::Projection::Orthographic;
    wide.orthoHeight = maximum;
    wide.near = 1.0f;
    wide.far = maximum;
    from = {0.0f, 0.0f, maximum};
    to = {0.0f, 0.0f, -maximum};
    auto projected = tmath::Vec3{};
    CHECK(wide.project(from, 1.0f, projected));
    CHECK(wide.project(to, 1.0f, projected));
    CHECK(wide.segment(from, to));
    CHECK(from.z == maximum && to.z == -maximum);
}

static void _rays()
{
    auto camera = _camera();
    auto expected = tmath::Vec2{0.25f, -0.5f};
    auto ray = camera.ray(expected, 2.0f);
    auto point = ray.origin + ray.direction * 5.0f;
    auto ndc = tmath::Vec3{};
    CHECK(camera.project(point, 2.0f, ndc));
    CHECK(_close(tmath::Vec2{ndc.x, ndc.y}, expected));

    camera.projection = tmath::Projection::Orthographic;
    camera.orthoHeight = 4.0f;
    ray = camera.ray(expected, 2.0f);
    point = ray.origin + ray.direction * 3.0f;
    CHECK(_close(ray.direction, {0.0f, 0.0f, -1.0f}));
    CHECK(camera.project(point, 2.0f, ndc));
    CHECK(_close(tmath::Vec2{ndc.x, ndc.y}, expected));

    auto subnormal = std::numeric_limits<float>::denorm_min();
    camera.projection = tmath::Projection::Perspective;
    camera.fov = subnormal;
    ray = camera.ray({2.0f, 0.0f}, 1.0f);
    point = ray.origin + ray.direction * 2.0f;
    CHECK(camera.project(point, 1.0f, ndc));
    CHECK(_close(ndc.x, 2.0f));
    CHECK(camera.ray({1.0f, 0.0f}, 1.0f).direction.length() == 0.0f);

    camera.projection = tmath::Projection::Orthographic;
    camera.orthoHeight = subnormal;
    ray = camera.ray({2.0f, 0.0f}, 1.0f);
    point = ray.origin + ray.direction * 3.0f;
    CHECK(camera.project(point, 1.0f, ndc));
    CHECK(_close(ndc.x, 2.0f));
}

static void _easing()
{
    for (auto easing : {tmath::Easing::Linear, tmath::Easing::Smooth, tmath::Easing::EaseIn,
                        tmath::Easing::EaseOut, tmath::Easing::EaseInOut}) {
        CHECK(_close(tmath::ease(easing, 0.0f), 0.0f));
        CHECK(_close(tmath::ease(easing, 1.0f), 1.0f));
    }
    CHECK(_close(tmath::ease(tmath::Easing::Smooth, 0.5f), 0.5f));
    CHECK(_close(tmath::ease(tmath::Easing::EaseIn, 0.5f), 0.25f));
    CHECK(_close(tmath::ease(tmath::Easing::EaseOut, 0.5f), 0.75f));
    CHECK(_close(tmath::ease(tmath::Easing::EaseInOut, 0.25f), 0.125f));
    CHECK(_close(tmath::ease(tmath::Easing::EaseInOut, 0.75f), 0.875f));
    CHECK(_close(tmath::ease(tmath::Easing::Linear, -1.0f), 0.0f));
    CHECK(_close(tmath::ease(tmath::Easing::Linear, 2.0f), 1.0f));

    for (auto preset : {tmath::AnimCurvePreset::Linear, tmath::AnimCurvePreset::Gentle,
                        tmath::AnimCurvePreset::Snappy, tmath::AnimCurvePreset::Back,
                        tmath::AnimCurvePreset::Bounce, tmath::AnimCurvePreset::Elastic}) {
        auto curve = tmath::AnimCurve::preset(preset);
        CHECK(curve.valid());
        CHECK(_close(tmath::ease(curve, 0.0f), 0.0f));
        CHECK(_close(tmath::ease(curve, 1.0f), 1.0f));
    }
    auto back = tmath::AnimCurve::preset(tmath::AnimCurvePreset::Back);
    CHECK(tmath::ease(back, 0.8f) > 1.0f);
    auto weak = tmath::AnimCurve::preset(tmath::AnimCurvePreset::Back, 0.0f);
    CHECK(_close(tmath::ease(weak, 0.37f), 0.37f));
    auto strong = tmath::AnimCurve::preset(tmath::AnimCurvePreset::Back, 1.6f);
    CHECK(tmath::ease(strong, 0.8f) > tmath::ease(back, 0.8f));
    auto reversed = back.reversed();
    CHECK(reversed.reverse);
    CHECK(_close(tmath::ease(reversed, 0.2f), 1.0f - tmath::ease(back, 0.8f)));
    CHECK(_close(tmath::ease(reversed.reversed(), 0.2f), tmath::ease(back, 0.2f)));

    auto custom = tmath::AnimCurve::cubicBezier({0.42f, 0.0f}, {0.58f, 1.0f}, 0.9f);
    CHECK(custom.valid());
    CHECK(_close(tmath::ease(custom, 0.5f), 0.5f));
    custom.control1.x = -0.1f;
    CHECK(!custom.valid());
    custom = tmath::AnimCurve::preset(tmath::AnimCurvePreset::Smooth, 2.1f);
    CHECK(!custom.valid());
}

static void _colors()
{
    auto color = tmath::Color::hex("#336699");
    CHECK(color.r == 0x33 && color.g == 0x66 && color.b == 0x99 && color.a == 0xff);
    color = tmath::Color::hex("8040ff80");
    CHECK(color.r == 0x80 && color.g == 0x40 && color.b == 0xff && color.a == 0x80);
    color = tmath::Color::hex("#abc");
    CHECK(color.r == 0xaa && color.g == 0xbb && color.b == 0xcc && color.a == 0xff);
    color = tmath::Color::hex("#abcd");
    CHECK(color.r == 0xaa && color.g == 0xbb && color.b == 0xcc && color.a == 0xdd);
    auto fallback = tmath::Color{1, 2, 3, 4};
    color = tmath::Color::hex("not-a-color", fallback);
    CHECK(color.r == 1 && color.g == 2 && color.b == 3 && color.a == 4);
    CHECK(std::strcmp(tmath::result(tmath::Result::IoError), "IoError") == 0);
    CHECK(std::strcmp(tmath::result(static_cast<tmath::Result>(255)), "Unknown") == 0);
}

int main()
{
    _vectors();
    _matrices();
    _orthographic();
    _projection();
    _clipping();
    _rays();
    _easing();
    _colors();

    if (_failures) std::fprintf(stderr, "%d math checks failed\n", _failures);
    return _failures ? 1 : 0;
}
