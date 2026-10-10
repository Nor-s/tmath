#ifndef _TMATH_H_
#define _TMATH_H_

#include <cstdint>

namespace tmath
{

struct Scene;
struct Space;
struct Object;
struct Text;

enum struct Result : uint8_t
{
    Success = 0,
    InvalidArguments = 1,
    InsufficientCondition = 2,
    NonSupport = 3,
    OutOfMemory = 4,
    IoError = 5,
    ScriptError = 6,
    Unknown = 7
};

enum struct RenderEngine : uint8_t
{
    Cpu = 0,
    Gl
};

enum struct Type : uint8_t
{
    Space,
    Point,
    Line,
    Arrow,
    Vector,
    Circle,
    Polygon,
    Plot,
    Text,
    Picture,
    Cell,
    Group,
    Rectangle,
    Connector,
    Path,
    Curve,
    SurfaceMesh,
    Route
};

enum struct LayoutSceneKind : uint8_t
{
    Root = 0,
    Viewport,
    Transition
};

enum struct LayoutVisualKind : uint8_t
{
    Stable = 0,
    Morph,
    FadeOut,
    FadeIn
};

enum struct PathVerb : uint8_t
{
    Move = 0,
    Line,
    Quadratic,
    Cubic,
    Close
};

enum struct ImageFilter : uint8_t
{
    Bilinear = 0,
    Nearest
};

enum struct CellMode : uint8_t
{
    Full = 0,
    Padd
};

enum struct SurfaceMode : uint8_t
{
    Solid = 0,
    Mesh,
    SolidMesh
};

enum struct TextOrientation : uint8_t
{
    Billboard = 0,
    Plane
};

enum struct TextRole : uint8_t
{
    H1 = 0,
    H2,
    H3,
    Text,
    Code
};

enum struct ThemePreset : uint8_t
{
    ThreeBlueOneEyes = 0,
    ProWhite,
    ProBlack,
    AdaptiveVscode,
    Pro = ProWhite
};

enum struct ThemeColorRole : uint8_t
{
    Background = 0,
    Foreground,
    Muted,
    Accent,
    Secondary,
    Success,
    Warning,
    Danger,
    Info,
    Surface,
    Border,
    Result,
    Focus
};

enum struct NumberMode : uint8_t
{
    Fixed = 0,
    Relative
};

enum struct Easing : uint8_t
{
    Linear = 0,
    Smooth,
    EaseIn,
    EaseOut,
    EaseInOut
};

enum struct AnimCurvePreset : uint8_t
{
    Linear = 0,
    Smooth,
    EaseIn,
    EaseOut,
    EaseInOut,
    Gentle,
    Snappy,
    Back,
    Bounce,
    Elastic,
    Custom
};

enum struct Projection : uint8_t
{
    Orthographic = 0,
    Perspective
};

enum struct CameraMode : uint8_t
{
    Fixed = 0,
    Interactive
};

enum struct CameraView : uint8_t
{
    TwoD = 0,
    ThreeD
};

enum struct CameraAction : uint8_t
{
    Pan = 0,
    Orbit,
    Zoom,
    Reset,
    View2D,
    View3D
};

struct Vec2
{
    float x = 0.0f;
    float y = 0.0f;

    Vec2 operator+(const Vec2& v) const noexcept;
    Vec2 operator-(const Vec2& v) const noexcept;
    Vec2 operator*(float s) const noexcept;
    Vec2 operator/(float s) const noexcept;
    float dot(const Vec2& v) const noexcept;
    float length() const noexcept;
    Vec2 normalized() const noexcept;
};

struct AnimCurve
{
    AnimCurvePreset kind = AnimCurvePreset::Smooth;
    Vec2 control1 = {0.25f, 0.1f};
    Vec2 control2 = {0.25f, 1.0f};
    float strength = 1.0f;
    bool reverse = false;

    static AnimCurve preset(AnimCurvePreset preset, float strength = 1.0f) noexcept;
    static AnimCurve cubicBezier(const Vec2& control1, const Vec2& control2,
                                 float strength = 1.0f) noexcept;
    AnimCurve reversed() const noexcept;
    bool valid() const noexcept;
};

struct Vec3
{
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    Vec3 operator+(const Vec3& v) const noexcept;
    Vec3 operator-(const Vec3& v) const noexcept;
    Vec3 operator*(float s) const noexcept;
    Vec3 operator/(float s) const noexcept;
    float dot(const Vec3& v) const noexcept;
    Vec3 cross(const Vec3& v) const noexcept;
    float length() const noexcept;
    Vec3 normalized() const noexcept;
};

struct Mat3
{
    float e[9];

    static Mat3 identity() noexcept;
    static Mat3 translate(const Vec2& v) noexcept;
    static Mat3 scale(const Vec2& v) noexcept;
    static Mat3 rotate(float radians) noexcept;
    Mat3 operator*(const Mat3& m) const noexcept;
    Vec2 operator*(const Vec2& v) const noexcept;
    bool inverse(Mat3& out) const noexcept;
};

struct Mat4
{
    float e[16];

    static Mat4 identity() noexcept;
    static Mat4 translate(const Vec3& v) noexcept;
    static Mat4 scale(const Vec3& v) noexcept;
    static Mat4 rotateX(float radians) noexcept;
    static Mat4 rotateY(float radians) noexcept;
    static Mat4 rotateZ(float radians) noexcept;
    static Mat4 from(const Mat3& m) noexcept;
    Mat4 operator*(const Mat4& m) const noexcept;
    Vec3 operator*(const Vec3& v) const noexcept;
};

struct Color
{
    uint8_t r = 255;
    uint8_t g = 255;
    uint8_t b = 255;
    uint8_t a = 255;

    static Color hex(const char* value) noexcept;
    static Color hex(const char* value, Color fallback) noexcept;
};

using CellSampler = bool (*)(float x, float y, float time,
                             Color& color, void* data) noexcept;
using VoxelSampler = bool (*)(float x, float y, float z, float time,
                              Color& color, void* data) noexcept;

struct SampleTime
{
    float duration = 0.0f;
    uint32_t fps = 30;
};

struct Range
{
    float min = -5.0f;
    float max = 5.0f;
    float step = 1.0f;
};

struct CellRegion
{
    uint32_t x = 0;
    uint32_t y = 0;
    uint32_t width = 0;
    uint32_t height = 0;
};

struct PathCommand
{
    PathVerb verb = PathVerb::Move;
    Vec3 to;
    Vec3 control1;
    Vec3 control2;

    static PathCommand move(const Vec3& to) noexcept;
    static PathCommand line(const Vec3& to) noexcept;
    static PathCommand quadratic(const Vec3& control, const Vec3& to) noexcept;
    static PathCommand cubic(const Vec3& control1, const Vec3& control2,
                             const Vec3& to) noexcept;
    static PathCommand close() noexcept;
};

struct Asset
{
    ~Asset();
    Asset(const Asset&) = delete;
    Asset& operator=(const Asset&) = delete;

    uint32_t width() const noexcept;
    uint32_t height() const noexcept;
    // RGBA pixels; encoded assets are rasterized at intrinsic size on first call.
    const uint32_t* data() const noexcept;
    // Original encoded bytes (null for assets created from raw pixels).
    const uint8_t* encoded() const noexcept;
    uint32_t encodedSize() const noexcept;
    const char* mime() const noexcept;

private:
    mutable uint32_t* pixels = nullptr;
    uint8_t* bytes = nullptr;
    char* type = nullptr;
    uint32_t byteSize = 0;
    uint32_t pixelWidth = 0;
    uint32_t pixelHeight = 0;

    Asset(uint32_t* pixels, uint8_t* bytes, uint32_t size, char* mime,
          uint32_t width, uint32_t height) noexcept;
    friend struct AssetLoader;
};

struct AssetLoader
{
    static Result load(const char* path, Asset*& output) noexcept;
    static Result load(const void* data, uint32_t size, const char* mime, Asset*& output) noexcept;
    static Result load(const uint32_t* pixels, uint32_t width, uint32_t height, Asset*& output) noexcept;
};

struct Ray3
{
    Vec3 origin;
    Vec3 direction;
};

struct CameraInput
{
    CameraAction action = CameraAction::Pan;
    Vec2 delta;
};

struct Camera
{
    Vec3 eye = {0.0f, 0.0f, 10.0f};
    Vec3 target;
    Vec3 up = {0.0f, 1.0f, 0.0f};
    Projection projection = Projection::Orthographic;
    float fov = 0.7853981634f;
    float orthoHeight = 8.0f;
    float near = 0.05f;
    float far = 1000.0f;

    bool project(const Vec3& world, float aspect, Vec3& ndc) const noexcept;
    bool segment(Vec3& from, Vec3& to) const noexcept;
    Ray3 ray(const Vec2& ndc, float aspect) const noexcept;
};

enum struct GradientType : uint8_t
{
    None = 0,
    Linear,
    Radial,
    Conic
};

struct GradientStop
{
    float offset = 0.0f;
    Color color;
};

// Paint gradient applied to a Shape's stroke and fill.
// stopCount == 0 keeps the legacy two-stop ramp: the paint color (stroke or fill) to
// Style::gradientEnd, with the end alpha copied from the paint color. Explicit stops use
// their own colors; each stop alpha is multiplied by the paint color alpha (which already
// carries object opacity), so a transparent fill still paints nothing.
// Geometry is optional and authored in the object's local coordinates; it is projected with
// the same model/camera transform as the Shape's points. Omitted geometry is derived from the
// projected Shape: linear follows an open path's first->last point or a closed shape's bbox
// diagonal; radial uses the bbox (or circle) center with half the bbox diagonal (or the circle
// radius); conic uses the bbox center with angle 0.
// The conic angle is in degrees, measured clockwise from local +x as seen on screen; stops
// advance clockwise.
struct Gradient
{
    static constexpr uint32_t StopLimit = 8;

    GradientType type = GradientType::None;
    GradientStop stops[StopLimit] = {};
    Vec3 from;
    Vec3 to;
    Vec3 center;
    Vec3 focal;
    float radius = 0.0f;
    float focalRadius = 0.0f;
    float angle = 0.0f;
    uint8_t stopCount = 0;
    bool line = false;         // from/to are explicit (Linear)
    bool centered = false;     // center is explicit (Radial, Conic)
    bool sized = false;        // radius is explicit (Radial)
    bool focused = false;      // focal center is explicit (Radial)

    bool enabled() const noexcept { return type != GradientType::None; }
    bool valid() const noexcept;
    bool operator==(const Gradient& other) const noexcept;
    bool operator!=(const Gradient& other) const noexcept { return !(*this == other); }
};

struct Style
{
    static constexpr uint32_t DashLimit = 4;

    Color stroke = {235, 238, 245, 255};
    Color fill = {0, 0, 0, 0};
    Color gradientEnd = {247, 37, 133, 255};
    float width = 2.0f;
    float radius = 5.0f;
    float dash[DashLimit] = {};
    float dashOffset = 0.0f;
    uint8_t dashCount = 0;
    Gradient gradient;
};

struct TextTheme
{
    const char* font = "Pretendard";
    float size = 17.0f;
    Color color = {219, 231, 243, 255};
};

struct AxisTheme
{
    Color x = {239, 83, 80, 255};
    Color y = {102, 187, 106, 255};
    Color z = {66, 165, 245, 255};
    Color grid = {55, 65, 81, 180};
    Color label = {174, 183, 195, 255};
};

struct SemanticTheme
{
    Color foreground = {32, 33, 36, 255};
    Color muted = {106, 112, 121, 255};
    Color accent = {0, 95, 184, 255};
    Color secondary = {103, 80, 164, 255};
    Color success = {46, 125, 50, 255};
    Color warning = {138, 93, 0, 255};
    Color danger = {179, 38, 30, 255};
    Color info = {0, 99, 155, 255};
    Color surface = {245, 246, 248, 255};
    Color border = {216, 218, 221, 255};
    Color result = {138, 101, 0, 255};
    Color focus = {49, 95, 140, 255};
};

struct Theme
{
    static constexpr uint32_t ColorLimit = 10;

    Color background = {255, 255, 255, 255};
    TextTheme h1 = {"Pretendard", 36.0f, {32, 33, 36, 255}};
    TextTheme h2 = {"Pretendard", 27.0f, {32, 33, 36, 255}};
    TextTheme h3 = {"Pretendard", 21.0f, {60, 64, 67, 255}};
    TextTheme text = {"Pretendard", 16.0f, {85, 91, 100, 255}};
    TextTheme code = {"Pretendard", 14.0f, {155, 54, 0, 255}};
    Color objects[ColorLimit] = {
        {180, 95, 6, 255},
        {182, 58, 60, 255},
        {46, 127, 122, 255},
        {63, 125, 53, 255},
        {129, 86, 129, 255},
        {185, 86, 104, 255},
        {118, 80, 61, 255},
        {98, 102, 106, 255},
    };
    uint32_t objectCount = 8;
    float objectWidth = 1.25f;
    bool gradient = false;
    Color endGradientStop = {102, 102, 102, 255};
    AxisTheme axis = {
        {216, 218, 221, 255},
        {216, 218, 221, 255},
        {216, 218, 221, 255},
        {216, 218, 221, 255},
        {85, 91, 100, 255},
    };
    SemanticTheme colors;

    static Theme preset(ThemePreset preset) noexcept;
    Color color(ThemeColorRole role) const noexcept;
};

struct Bounds
{
    Vec3 min;
    Vec3 max;

    Vec3 center() const noexcept;
    Vec3 size() const noexcept;
};

struct BBox
{
    float x = 0.0f;
    float y = 0.0f;
    float width = 0.0f;
    float height = 0.0f;

    Vec2 center() const noexcept;
    Vec2 size() const noexcept;
    bool intersects(const BBox& other, float padding = 0.0f) const noexcept;
};

struct LayoutScene
{
    const Scene* scene = nullptr;
    const char* path = nullptr;
    BBox bounds;
    BBox clipBounds;
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    uint32_t parent = 0xffffffffu;
    uint32_t depth = 0;
    LayoutSceneKind kind = LayoutSceneKind::Root;
    bool clipped = false;
    bool stretched = false;
};

struct LayoutObject
{
    const Object* object = nullptr;
    BBox familyBounds;
    BBox paintBounds;
    BBox visibleFamilyBounds;
    BBox visibleBounds;
    BBox clipBounds;
    uint32_t scene = 0;
    uint32_t parent = 0xffffffffu;
    int32_t layer = 0;
    bool familyVisible = false;
    bool visible = false;
    bool familyClipped = false;
    bool clipped = false;
};

struct LayoutVisual
{
    uint32_t object = 0xffffffffu;
    uint32_t counterpart = 0xffffffffu;
    uint32_t occluder = 0xffffffffu;
    BBox paintBounds;
    BBox visibleBounds;
    BBox clipBounds;
    int32_t layer = 0;
    float opacity = 1.0f;
    LayoutVisualKind kind = LayoutVisualKind::Stable;
    bool visible = false;
    bool clipped = false;
    bool occluded = false;
};

struct LayoutPath
{
    // Owned by LayoutReport and valid until the report is destroyed or reused.
    // Points and paintBounds use root output pixels after camera and Viewport mapping.
    const Vec2* points = nullptr;
    // Encloses fill plus the renderer's round-join and butt/round-cap stroke footprint.
    BBox paintBounds;
    uint32_t visual = 0xffffffffu;
    uint32_t count = 0;
    // Maximum-axis width; conservative when a Viewport stretches one axis.
    float strokeWidth = 0.0f;
    bool closed = false;
    bool filled = false;
    bool stroked = false;
};

struct LayoutCollision
{
    uint32_t first = 0;
    uint32_t second = 0;
    BBox overlap;
    Vec2 clearance;
    Vec2 separation;
    bool overlapping = false;
};

struct LayoutContainment
{
    uint32_t container = 0;
    uint32_t content = 0;
    uint32_t depth = 0;
    float inset = 0.0f;
    float overflowLeft = 0.0f;
    float overflowTop = 0.0f;
    float overflowRight = 0.0f;
    float overflowBottom = 0.0f;
    bool contained = false;
};

struct LayoutReport
{
    LayoutReport() noexcept;
    ~LayoutReport();
    LayoutReport(const LayoutReport&) = delete;
    LayoutReport& operator=(const LayoutReport&) = delete;

    float time() const noexcept;
    float padding() const noexcept;
    uint32_t sceneCount() const noexcept;
    const LayoutScene* sceneAt(uint32_t index) const noexcept;
    uint32_t objectCount() const noexcept;
    const LayoutObject* objectAt(uint32_t index) const noexcept;
    uint32_t visualCount() const noexcept;
    const LayoutVisual* visualAt(uint32_t index) const noexcept;
    uint32_t pathCount() const noexcept;
    const LayoutPath* pathAt(uint32_t index) const noexcept;
    uint32_t collisionCount() const noexcept;
    const LayoutCollision* collisionAt(uint32_t index) const noexcept;
    uint32_t containmentCount() const noexcept;
    const LayoutContainment* containmentAt(uint32_t index) const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;
    friend struct SwRenderer;
};

struct Object
{
    virtual ~Object();
    Object(const Object&) = delete;
    Object& operator=(const Object&) = delete;

    Style style;
    Mat4 model = Mat4::identity();
    int32_t layer = 0;
    float opacity = 1.0f;
    float progress = 1.0f;

    Type type() const noexcept;
    uint32_t id() const noexcept;
    Object* parent() const noexcept;
    Space* space() const noexcept;
    Result add(Object* object) noexcept;
    Result label(Text* text) noexcept;
    uint32_t childCount() const noexcept;
    Object* childAt(uint32_t index) const noexcept;
    bool bounds(Bounds& output) const noexcept;
    Result moveTo(const Vec3& point) noexcept;
    Result nextTo(const Object* target, const Vec3& direction, float gap = 0.25f) noexcept;
    Result alignTo(const Object* target, const Vec3& direction) noexcept;
    Object& tag(const char* value) noexcept;
    const char* tag() const noexcept;
    Object& stroke(Color color) noexcept;
    Object& stroke(Color color, float width) noexcept;
    Object& strokeWidth(float width) noexcept;
    Object& gradient(bool enabled = true) noexcept;
    Object& gradient(Color end) noexcept;
    // Validates and applies a full gradient description; GradientType::None disables it.
    Result gradient(const Gradient& value) noexcept;
    Result dash(const float* pattern, uint32_t count, float offset = 0.0f) noexcept;
    Object& fill(Color color) noexcept;
    Object& shift(const Vec3& by) noexcept;
    Object& scale(const Vec3& by) noexcept;
    Object& rotateX(float radians) noexcept;
    Object& rotateY(float radians) noexcept;
    Object& rotateZ(float radians) noexcept;
    Object& transform(const Mat4& by) noexcept;

private:
    explicit Object(Type type) noexcept;
    bool owned() const noexcept;
    bool grow() noexcept;
    Result layout(const Mat4& model) noexcept;

    Type objType;
    uint32_t objId = 0;
    char* objTag = nullptr;
    Scene* objOwner = nullptr;
    Object* objParent = nullptr;
    Object** children = nullptr;
    uint32_t childCnt = 0;
    uint32_t childCap = 0;
    bool objColorAuthored = false;
    bool objWidthAuthored = false;
    bool objGradientAuthored = false;
    bool objGradientEndAuthored = false;
    bool objThemeGradient = false;
    bool objThemeColor = false;
    friend struct Group;
    friend struct Space;
    friend struct Point;
    friend struct Line;
    friend struct Arrow;
    friend struct Vector;
    friend struct Circle;
    friend struct Polygon;
    friend struct Plot;
    friend struct DirectedRoute;
    friend struct Text;
    friend struct Picture;
    friend struct Cell;
    friend struct Rectangle;
    friend struct Connector;
    friend struct Path;
    friend struct Curve;
    friend struct SurfaceMesh;
    friend struct Scene;
};

struct Group : Object
{
    static Group* gen() noexcept;
    Result arrange(const Vec3& direction = {1.0f, 0.0f, 0.0f}, float gap = 0.25f) noexcept;
    Result arrangeGrid(uint32_t columns, float columnGap = 0.25f, float rowGap = 0.25f) noexcept;

protected:
    Group() noexcept;
};

struct Space final : Object
{
    Range x;
    Range y;
    Range z;
    Color axisX = {239, 83, 80, 255};
    Color axisY = {102, 187, 106, 255};
    Color axisZ = {66, 165, 245, 255};
    Color numberColor = {174, 183, 195, 255};
    NumberMode numberMode = NumberMode::Fixed;
    float numberSize = 15.0f;
    bool numbers = false;

    ~Space() override;
    static Space* gen(const Range& x = {}, const Range& y = {}, const Range& z = {}) noexcept;
    Result add(Object* object) noexcept;
    uint32_t count() const noexcept;
    Object* objectAt(uint32_t index) const noexcept;
    Vec3 c2w(const Vec3& coordinate) const noexcept;
    bool w2c(const Vec3& world, Vec3& coordinate) const noexcept;
    Result cell(CellSampler callback, Group*& cells, void* data = nullptr,
                CellMode mode = CellMode::Padd, float padding = 0.05f,
                const SampleTime& time = {}) noexcept;
    Result voxel(VoxelSampler callback, Group*& voxels, void* data = nullptr,
                 CellMode mode = CellMode::Padd, float padding = 0.05f,
                 const SampleTime& time = {}) noexcept;

private:
    bool objSampling = false;
    Space(const Range& x, const Range& y, const Range& z) noexcept;
    Result sample(VoxelSampler callback, Group*& output, void* data, CellMode mode,
                  float padding, const SampleTime& time, bool spatial) noexcept;
    friend struct Scene;
};

struct Point final : Object
{
    Vec3 point;

    static Point* gen(const Vec3& point) noexcept;

private:
    explicit Point(const Vec3& point) noexcept;
};

struct Line final : Object
{
    Vec3 from;
    Vec3 to;

    static Line* gen(const Vec3& from, const Vec3& to) noexcept;

private:
    Line(const Vec3& from, const Vec3& to) noexcept;
};

struct Arrow final : Object
{
    Vec3 from;
    Vec3 to;
    float tail = 0.0f;
    float tip = 16.0f;

    static Arrow* gen(const Vec3& from, const Vec3& to) noexcept;

private:
    Arrow(const Vec3& from, const Vec3& to) noexcept;
};

struct Vector final : Object
{
    Vec3 value;
    Vec3 origin;
    float tail = 0.0f;
    float tip = 16.0f;

    static Vector* gen(const Vec3& value, const Vec3& origin = {}) noexcept;

private:
    Vector(const Vec3& value, const Vec3& origin) noexcept;
};

struct Circle final : Object
{
    Vec3 center;
    float radius = 1.0f;

    static Circle* gen(const Vec3& center, float radius) noexcept;

private:
    Circle(const Vec3& center, float radius) noexcept;
};

struct Polygon final : Object
{
    ~Polygon() override;
    static Polygon* gen(const Vec3* points, uint32_t count) noexcept;
    const Vec3* points() const noexcept;
    uint32_t count() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objCount = 0;
    Polygon(const Vec3* points, uint32_t count) noexcept;
};

struct Plot final : Object
{
    ~Plot() override;
    static Plot* gen(const Vec3* points, uint32_t count) noexcept;
    const Vec3* points() const noexcept;
    uint32_t count() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objCount = 0;
    Plot(const Vec3* points, uint32_t count) noexcept;
};

struct DirectedRoute final : Object
{
    float tail = 0.0f;
    float tip = 16.0f;

    ~DirectedRoute() override;
    static DirectedRoute* gen(const Vec3* points, uint32_t count) noexcept;
    const Vec3* points() const noexcept;
    uint32_t count() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objCount = 0;
    DirectedRoute(const Vec3* points, uint32_t count) noexcept;
};

struct Path final : Object
{
    ~Path() override;
    static Path* gen(const PathCommand* commands, uint32_t count,
                     uint32_t samples = 24) noexcept;
    const Vec3* points() const noexcept;
    uint32_t count() const noexcept;
    bool closed() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objCount = 0;
    bool objClosed = false;
    Path(Vec3* points, uint32_t count, bool closed) noexcept;
};

struct Curve final : Object
{
    ~Curve() override;
    static Curve* gen(const Vec3& from, const Vec3& control1, const Vec3& control2,
                      const Vec3& to, uint32_t samples = 32) noexcept;
    const Vec3* points() const noexcept;
    uint32_t count() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objCount = 0;
    Curve(Vec3* points, uint32_t count) noexcept;
};

struct SurfaceMesh final : Object
{
    SurfaceMode mode = SurfaceMode::Solid;
    bool shading = true;

    ~SurfaceMesh() override;
    static SurfaceMesh* gen(const Vec3* points, uint32_t columns,
                            uint32_t rows) noexcept;
    const Vec3* points() const noexcept;
    uint32_t columns() const noexcept;
    uint32_t rows() const noexcept;

private:
    Vec3* objPoints = nullptr;
    uint32_t objColumns = 0;
    uint32_t objRows = 0;
    SurfaceMesh(const Vec3* points, uint32_t columns, uint32_t rows) noexcept;
};

struct Text final : Object
{
    Vec3 point;
    float size = 28.0f;
    Vec2 align = {0.5f, 0.5f};
    TextOrientation orientation = TextOrientation::Billboard;
    TextRole role = TextRole::Text;

    ~Text() override;
    static Text* gen(const char* text, const Vec3& point = {}) noexcept;
    const char* text() const noexcept;
    Result text(const char* value) noexcept;
    const char* font() const noexcept;
    Result font(const char* value) noexcept;

private:
    char* objText = nullptr;
    char* objFont = nullptr;
    Text(const char* text, const Vec3& point) noexcept;
    friend struct Scene;
};

struct Picture final : Object
{
    Vec3 center;
    float width = 1.0f;
    ImageFilter filter = ImageFilter::Bilinear;

    ~Picture() override;
    static Picture* gen(const Asset* asset, const Vec3& center = {}, float width = 1.0f) noexcept;
    uint32_t pixelWidth() const noexcept;
    uint32_t pixelHeight() const noexcept;
    const uint32_t* pixels() const noexcept;
    const uint8_t* encoded() const noexcept;
    uint32_t encodedSize() const noexcept;
    const char* mime() const noexcept;

private:
    uint32_t* objPixels = nullptr;
    uint8_t* objEncoded = nullptr;
    char* objMime = nullptr;
    uint32_t objEncodedSize = 0;
    uint32_t objWidth = 0;
    uint32_t objHeight = 0;
    Picture(const Vec3& center, float width) noexcept;
};

struct Cell final : Object
{
    Vec3 origin;
    float depth = 1.0f;
    CellMode mode = CellMode::Full;
    float padding = 0.05f;

    ~Cell() override;
    static Cell* gen(const Vec3& origin, uint32_t columns, uint32_t rows,
                     Color color = {}, CellMode mode = CellMode::Full,
                     float padding = 0.05f) noexcept;
    uint32_t columns() const noexcept;
    uint32_t rows() const noexcept;
    const Color* colors() const noexcept;
    Result fill(const CellRegion& region, Color color) noexcept;
    Result texture(const Asset* asset, const CellRegion& source = {},
                   const CellRegion& destination = {}) noexcept;

private:
    Color* objColors = nullptr;
    uint32_t objColumns = 0;
    uint32_t objRows = 0;
    uint32_t objFrames = 1;
    float objFrameDuration = 0.0f;
    Cell(const Vec3& origin, uint32_t columns, uint32_t rows, Color color,
         CellMode mode, float padding) noexcept;
    Result frames(uint32_t count, float duration) noexcept;
    friend const Color* sampleColors(const Cell* cell, uint32_t frame) noexcept;
    friend uint32_t sampleFrames(const Cell* cell) noexcept;
    friend float sampleDuration(const Object* object) noexcept;
    friend struct Space;
};

struct Rectangle final : Object
{
    Vec3 center;
    Vec2 size = {1.0f, 1.0f};
    float corner = 0.0f;

    static Rectangle* gen(const Vec3& center = {}, const Vec2& size = {1.0f, 1.0f},
                          float corner = 0.0f) noexcept;

private:
    Rectangle(const Vec3& center, const Vec2& size, float corner) noexcept;
};

struct Connector final : Object
{
    float padding = 0.0f;
    float tail = 0.0f;
    float tip = 0.0f;

    static Connector* gen(Object* from, Object* to) noexcept;
    Object* from() const noexcept;
    Object* to() const noexcept;

private:
    Object* source = nullptr;
    Object* destination = nullptr;
    Connector(Object* from, Object* to) noexcept;
};

enum struct AnimationKind : uint8_t
{
    Transform,
    Create,
    Fade,
    Stroke,
    Fill,
    Uncreate,
    FadeIn,
    FadeOut,
    Grow,
    GrowFromEdge,
    Shrink,
    Indicate,
    Morph,
    FillReveal,
    DrawBorderThenFill,
    Write
};

enum struct DrawDirection : uint8_t
{
    Forward,
    Reverse,
    Clockwise,
    CounterClockwise
};

enum struct GrowthEdge : uint8_t
{
    Left,
    Right,
    Bottom,
    Top
};

struct Animation
{
    Object* target = nullptr;
    AnimationKind kind = AnimationKind::Create;
    Mat4 model = Mat4::identity();
    Color color;
    float value = 1.0f;
    Object* related = nullptr;
    Vec3 offset;
    DrawDirection direction = DrawDirection::Forward;
    GrowthEdge growthEdge = GrowthEdge::Bottom;
    float scale = 1.0f;

    static Animation create(Object* target, DrawDirection direction = DrawDirection::Forward) noexcept;
    static Animation uncreate(Object* target, DrawDirection direction = DrawDirection::Forward) noexcept;
    static Animation fillReveal(Object* target) noexcept;
    static Animation drawBorderThenFill(Object* target,
                                        DrawDirection direction = DrawDirection::Forward) noexcept;
    static Animation write(Object* target,
                           DrawDirection direction = DrawDirection::Forward) noexcept;
    static Animation fade(Object* target, float opacity) noexcept;
    static Animation fadeIn(Object* target, const Vec3& shift = {}, float scale = 1.0f) noexcept;
    static Animation fadeOut(Object* target, const Vec3& shift = {}, float scale = 1.0f) noexcept;
    static Animation growFromCenter(Object* target) noexcept;
    static Animation growFromEdge(Object* target, GrowthEdge edge) noexcept;
    static Animation shrinkToCenter(Object* target) noexcept;
    static Animation indicate(Object* target, Color color = {110, 168, 254, 255},
                               float scale = 1.2f) noexcept;
    static Animation morph(Object* source, Object* target) noexcept;
    static Animation replacementTransform(Object* source, Object* target) noexcept;
    static Animation shift(Object* target, const Vec3& by) noexcept;
    static Animation transform(Object* target, const Mat4& model) noexcept;
    static Animation stroke(Object* target, Color color) noexcept;
    static Animation fill(Object* target, Color color) noexcept;
};

struct AnimationTarget
{
    static AnimationTarget from(Object* target) noexcept;
    AnimationTarget& shift(const Vec3& by) noexcept;
    AnimationTarget& transform(const Mat4& model) noexcept;
    AnimationTarget& opacity(float value) noexcept;
    AnimationTarget& stroke(Color color) noexcept;
    AnimationTarget& fill(Color color) noexcept;
    AnimationTarget& dashOffset(float value) noexcept;
    AnimationTarget& tail(float value) noexcept;
    AnimationTarget& tip(float value) noexcept;

private:
    Object* target = nullptr;
    Mat4 targetModel = Mat4::identity();
    Color targetStroke;
    Color targetFill;
    float targetOpacity = 1.0f;
    float targetDashOffset = 0.0f;
    float targetTail = 0.0f;
    float targetTip = 0.0f;
    uint8_t properties = 0;
    friend struct Scene;
};

struct Config
{
    uint32_t width = 1280;
    uint32_t height = 720;
    uint32_t fps = 30;
    Color background = {255, 255, 255, 255};
    Camera camera;
    CameraMode cameraMode = CameraMode::Fixed;
    CameraView cameraView = CameraView::TwoD;
    bool antialiasing = true;
    bool loop = false;
};

struct Viewport
{
    float x = 0.0f;
    float y = 0.0f;
    float width = 1.0f;
    float height = 1.0f;
};

struct RuntimeModifier
{
    using ObjectCallback = Result (*)(const Object* object, float time, Mat4& model,
                                      float& opacity, float& progress, void* data) noexcept;
    using CameraCallback = Result (*)(float time, Camera& camera, CameraView& view,
                                      void* data) noexcept;
    using InputCallback = Result (*)(const CameraInput& input, void* data) noexcept;
    using FillCallback = Result (*)(const Object* object, float time, Color& fill,
                                    void* data) noexcept;

    ObjectCallback object = nullptr;
    CameraCallback camera = nullptr;
    InputCallback input = nullptr;
    void* data = nullptr;
    FillCallback fill = nullptr;
    const void* key = nullptr;
};

struct PixelSample
{
    const Object* object = nullptr;
    Vec2 position;
    Color color = {0, 0, 0, 0};
};

struct Scene
{
    static constexpr uint32_t RuntimeLimit = 8u;

    ~Scene();
    Scene(const Scene&) = delete;
    Scene& operator=(const Scene&) = delete;

    static Scene* gen(const Config& config = {}) noexcept;
    Result theme(const Theme& theme) noexcept;
    const Theme& theme() const noexcept;
    Result add(Object* object) noexcept;
    Result update(Object* object) noexcept;
    Result viewport(Scene* scene, const Viewport& viewport) noexcept;
    Result transition(Scene* const* scenes, uint32_t count, const Viewport& viewport = {},
                      float duration = 1.0f, float hold = 0.0f,
                      Easing easing = Easing::Smooth) noexcept;
    Result transition(Scene* const* scenes, uint32_t count, const Viewport& viewport,
                      float duration, float hold, const AnimCurve& curve) noexcept;
    Result remove(Object* object) noexcept;
    Result fadeTransform(Object* source, Object* target, float duration = 1.0f,
                         Easing easing = Easing::Smooth) noexcept;
    Result fadeTransform(Object* source, Object* target, float duration,
                         const AnimCurve& curve) noexcept;
    Result play(const Animation& animation, float duration = 1.0f, Easing easing = Easing::Smooth) noexcept;
    Result play(const Animation& animation, float duration, const AnimCurve& curve) noexcept;
    Result play(const Animation* animations, uint32_t count, float duration, Easing easing = Easing::Smooth, float lag = 0.0f) noexcept;
    Result play(const Animation* animations, uint32_t count, float duration,
                const AnimCurve& curve, float lag = 0.0f) noexcept;
    Result play(const AnimationTarget& target, float duration = 1.0f, Easing easing = Easing::Smooth) noexcept;
    Result play(const AnimationTarget& target, float duration, const AnimCurve& curve) noexcept;
    Result play(const AnimationTarget* targets, uint32_t count, float duration,
                Easing easing = Easing::Smooth, float lag = 0.0f) noexcept;
    Result play(const AnimationTarget* targets, uint32_t count, float duration,
                const AnimCurve& curve, float lag = 0.0f) noexcept;
    Result runtime(const RuntimeModifier* modifier) noexcept;
    Result runtimeAdd(const RuntimeModifier* modifier) noexcept;
    Result runtimeRemove(void* data) noexcept;
    Result camera(const CameraInput& input) noexcept;
    Result look(const Camera& camera, CameraView view, float duration = 1.0f,
                Easing easing = Easing::Smooth) noexcept;
    Result look(const Camera& camera, CameraView view, float duration,
                const AnimCurve& curve) noexcept;
    Result wait(float duration = 1.0f) noexcept;
    float duration() const noexcept;
    CameraView view(float time = 0.0f) const noexcept;
    uint32_t count() const noexcept;
    Object* object(uint32_t id) const noexcept;
    Object* objectAt(uint32_t index) const noexcept;
    Object* object(const char* tag) const noexcept;
    uint32_t viewportCount() const noexcept;
    Scene* sceneAt(uint32_t index) const noexcept;
    bool viewportAt(uint32_t index, Viewport& viewport) const noexcept;
    uint32_t transitionCount() const noexcept;
    Scene* transitionAt(uint32_t index) const noexcept;
    Config& config() noexcept;
    const Config& config() const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Scene(const Config& config) noexcept;
    static uint32_t depth(const Scene* scene) noexcept;
    Result attach(Object* object, Object* parent) noexcept;
    friend struct RendererBuilder;
    friend struct SwRenderer;
    friend struct GlRenderer;
    friend struct Object;
    friend struct Space;
};

struct Surface
{
    Surface() = default;
    Surface(const Surface&) = delete;
    Surface& operator=(const Surface&) = delete;
    ~Surface();
    Result resize(uint32_t width, uint32_t height) noexcept;
    uint32_t* data() noexcept;
    const uint32_t* data() const noexcept;
    uint32_t width() const noexcept;
    uint32_t height() const noexcept;
    uint32_t stride() const noexcept;

private:
    uint32_t* buffer = nullptr;
    uint32_t bufferWidth = 0;
    uint32_t bufferHeight = 0;
    uint32_t bufferStride = 0;
};

struct SwRenderer
{
    ~SwRenderer();
    SwRenderer(const SwRenderer&) = delete;
    SwRenderer& operator=(const SwRenderer&) = delete;

    static SwRenderer* gen() noexcept;
    Result font(const char* path) noexcept;
    Result font(const char* name, const void* data, uint32_t size, const char* mime = "ttf") noexcept;
    Result bounds(const Scene* scene, const Object* object, float time, BBox& output) noexcept;
    Result intersects(const Scene* scene, const Object* first, const Object* second, float time,
                      bool& output, float padding = 0.0f) noexcept;
    Result layout(const Scene* scene, float time, LayoutReport& output,
                  float padding = 0.0f) noexcept;
    Result sample(const Scene* scene, float time, const Vec2& position,
                  const Object* const* candidates, uint32_t count,
                  PixelSample& output, uint32_t pixelRatio = 1u) noexcept;
    Result render(const Scene* scene, float time, Surface& surface) noexcept;
    Result render(const Scene* scene, float time, Surface& surface,
                  uint32_t pixelRatio) noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;
    SwRenderer() noexcept;
};

struct GlTarget
{
    void* display = nullptr;
    void* surface = nullptr;
    void* context = nullptr;
    int32_t id = 0;
    uint32_t width = 0;
    uint32_t height = 0;
};

struct GlRenderer
{
    ~GlRenderer();
    GlRenderer(const GlRenderer&) = delete;
    GlRenderer& operator=(const GlRenderer&) = delete;

    static GlRenderer* gen() noexcept;
    Result font(const char* path) noexcept;
    Result font(const char* name, const void* data, uint32_t size, const char* mime = "ttf") noexcept;
    Result render(const Scene* scene, float time, const GlTarget& target) noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;
    GlRenderer() noexcept;
};

struct Renderer
{
    ~Renderer();
    Renderer(const Renderer&) = delete;
    Renderer& operator=(const Renderer&) = delete;

    static Renderer* gen() noexcept;
    static Renderer* gen(RenderEngine engine) noexcept;
    static Result defaultEngine(RenderEngine engine) noexcept;
    static RenderEngine defaultEngine() noexcept;
    static bool enabled(RenderEngine engine) noexcept;

    RenderEngine engine() const noexcept;
    Result font(const char* path) noexcept;
    Result font(const char* name, const void* data, uint32_t size,
                const char* mime = "ttf") noexcept;
    Result bounds(const Scene* scene, const Object* object, float time,
                  BBox& output) noexcept;
    Result intersects(const Scene* scene, const Object* first, const Object* second,
                      float time, bool& output, float padding = 0.0f) noexcept;
    Result layout(const Scene* scene, float time, LayoutReport& output,
                  float padding = 0.0f) noexcept;
    Result sample(const Scene* scene, float time, const Vec2& position,
                  const Object* const* candidates, uint32_t count,
                  PixelSample& output, uint32_t pixelRatio = 1u) noexcept;
    Result render(const Scene* scene, float time, Surface& surface) noexcept;
    Result render(const Scene* scene, float time, Surface& surface,
                  uint32_t pixelRatio) noexcept;
    Result render(const Scene* scene, float time, const GlTarget& target) noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;
    explicit Renderer(RenderEngine engine) noexcept;
    SwRenderer* cpuBackend() const noexcept;
    friend struct Saver;
};

struct Saver
{
    static Result png(const Surface& surface, const char* path) noexcept;
    static Result save(const Scene* scene, Renderer& renderer, const char* path,
                       uint32_t fps = 0) noexcept;
    static Result video(const Scene* scene, SwRenderer* renderer, const char* path, uint32_t fps = 0) noexcept;
};

struct Lua
{
    using AssetResolver = const Asset* (*)(const char* name, void* data);

    static Result load(const char* path, Scene** scene, char* error, uint32_t errorSize) noexcept;
    static Result load(const char* source, uint32_t size, const char* name, Scene** scene,
                       char* error, uint32_t errorSize, AssetResolver resolver = nullptr,
                       void* resolverData = nullptr, const Theme* adaptiveTheme = nullptr,
                       bool* adaptiveThemeUsed = nullptr) noexcept;
};

float ease(Easing easing, float progress) noexcept;
float ease(const AnimCurve& curve, float progress) noexcept;
const char* result(Result result) noexcept;
const char* type(Type type) noexcept;

}  // namespace tmath

#endif
