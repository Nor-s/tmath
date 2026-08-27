#ifndef _TMATH_DIAGRAM_H_
#define _TMATH_DIAGRAM_H_

#include "tmath.h"

namespace tmath::diagram
{

enum struct Direction : uint8_t
{
    LeftToRight = 0,
    TopToBottom
};

enum struct Layout : uint8_t
{
    Ranked = 0,
    Manual,
    Grid,
    Timeline
};

enum struct NodeKind : uint8_t
{
    Default = 0,
    State,
    Decision,
    Terminal,
    Entity,
    Cell,
    Task,
    Evidence
};

enum struct EdgeKind : uint8_t
{
    Directed = 0,
    Relation,
    Return,
    Error,
    Optional
};

enum struct Route : uint8_t
{
    Auto = 0,
    Straight,
    Orthogonal
};

enum struct Port : uint8_t
{
    Auto = 0,
    Left,
    Right,
    Top,
    Bottom
};

struct Node
{
    static constexpr uint32_t Invalid = 0xffffffffu;
    uint32_t index = Invalid;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct Edge
{
    static constexpr uint32_t Invalid = 0xffffffffu;
    uint32_t index = Invalid;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct Zone
{
    static constexpr uint32_t Invalid = 0xffffffffu;
    uint32_t index = Invalid;

    explicit operator bool() const noexcept { return index != Invalid; }
};

struct Layers
{
    int32_t zones = -30;
    int32_t routes = -20;
    int32_t nodes = 0;
    int32_t annotations = 10;
};

struct Config
{
    const char* id = "diagram";
    Direction direction = Direction::LeftToRight;
    Vec2 origin;
    Vec2 nodeSize = {3.2f, 1.2f};
    float rankGap = 2.2f;
    float nodeGap = 0.7f;
    float zonePadding = 0.55f;
    float routeWidth = 0.08f;
    float arrowLength = 0.32f;
    float arrowWidth = 0.28f;
    float corner = 0.12f;
    Layers layers;
    Layout layout = Layout::Ranked;
    float timeUnit = 1.0f;
};

struct NodeSpec
{
    const char* id = nullptr;
    const char* label = nullptr;
    const char* detail = nullptr;
    int32_t rank = -1;
    Vec2 position;
    Vec2 size;
    bool manualPosition = false;
    NodeKind kind = NodeKind::Default;
    int32_t row = -1;
    int32_t column = -1;
    float start = 0.0f;
    float span = 0.0f;
};

struct EdgeSpec
{
    const char* id = nullptr;
    const char* label = nullptr;
    Node from;
    Node to;
    Port fromPort = Port::Auto;
    Port toPort = Port::Auto;
    Route route = Route::Auto;
    const Vec2* waypoints = nullptr;
    uint32_t waypointCount = 0;
    float flowOffset = 0.0f;
    bool flow = false;
    EdgeKind kind = EdgeKind::Directed;
};

struct ZoneSpec
{
    const char* id = nullptr;
    const char* label = nullptr;
    const Node* members = nullptr;
    uint32_t memberCount = 0;
    bool fullWidth = false;
};

struct Built
{
    ~Built();
    Built(const Built&) = delete;
    Built& operator=(const Built&) = delete;

    // The Built instance owns this detached tree until release() transfers it.
    Group* root() const noexcept;
    Group* release() noexcept;
    Group* zones() const noexcept;
    Group* routes() const noexcept;
    Group* nodes() const noexcept;
    Group* annotations() const noexcept;

    Object* object(Node node) const noexcept;
    Rectangle* body(Node node) const noexcept;
    Text* label(Node node) const noexcept;
    Text* detail(Node node) const noexcept;

    Object* object(Edge edge) const noexcept;
    Text* label(Edge edge) const noexcept;

    Object* object(Zone zone) const noexcept;
    Rectangle* body(Zone zone) const noexcept;
    Text* label(Zone zone) const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Built(Impl* impl) noexcept;
    friend struct Diagram;
};

struct Diagram
{
    static constexpr uint32_t NodeLimit = 256u;
    static constexpr uint32_t EdgeLimit = 512u;
    static constexpr uint32_t ZoneLimit = 64u;
    static constexpr uint32_t WaypointLimit = 16u;
    static constexpr uint32_t IdLimit = 63u;

    ~Diagram();
    Diagram(const Diagram&) = delete;
    Diagram& operator=(const Diagram&) = delete;

    static Diagram* gen(const Config& config = {}) noexcept;
    Result add(const NodeSpec& spec, Node& output) noexcept;
    Result add(const EdgeSpec& spec, Edge& output) noexcept;
    Result add(const ZoneSpec& spec, Zone& output) noexcept;

    uint32_t nodeCount() const noexcept;
    uint32_t edgeCount() const noexcept;
    uint32_t zoneCount() const noexcept;
    // output must be null and remains null when construction fails atomically.
    Result build(const Theme& theme, Built*& output) const noexcept;

private:
    struct Impl;
    Impl* pImpl = nullptr;

    explicit Diagram(Impl* impl) noexcept;
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

}  // namespace tmath::diagram

#endif
