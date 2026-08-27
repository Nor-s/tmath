#include <cmath>
#include <cstdio>
#include <cstring>
#include <new>

#include "tmath_diagram.h"

namespace tmath::diagram
{

namespace
{

constexpr uint32_t LabelLimit = 1023u;
constexpr float Epsilon = 1.0e-5f;

struct NodeRecord
{
    char* id = nullptr;
    char* label = nullptr;
    char* detail = nullptr;
    NodeKind kind = NodeKind::Default;
    int32_t rank = -1;
    int32_t row = -1;
    int32_t column = -1;
    float start = 0.0f;
    float span = 0.0f;
    Vec2 position;
    Vec2 size;
    bool manualPosition = false;
};

struct EdgeRecord
{
    char* id = nullptr;
    char* label = nullptr;
    Node from;
    Node to;
    Port fromPort = Port::Auto;
    Port toPort = Port::Auto;
    Route route = Route::Auto;
    EdgeKind kind = EdgeKind::Directed;
    Vec2* waypoints = nullptr;
    uint32_t waypointCount = 0;
    float flowOffset = 0.0f;
    bool flow = false;
};

struct ZoneRecord
{
    char* id = nullptr;
    char* label = nullptr;
    Node* members = nullptr;
    uint32_t memberCount = 0;
    bool fullWidth = false;
};

struct NodeLayout
{
    Vec2 center;
    Vec2 size;
    uint32_t rank = 0;
};

struct EdgeLayout
{
    Port fromPort = Port::Auto;
    Port toPort = Port::Auto;
    Vec2 from;
    Vec2 to;
};

struct NodeView
{
    Object* object = nullptr;
    Rectangle* body = nullptr;
    Text* label = nullptr;
    Text* detail = nullptr;
};

struct EdgeView
{
    Object* object = nullptr;
    Text* label = nullptr;
};

struct ZoneView
{
    Object* object = nullptr;
    Rectangle* body = nullptr;
    Text* label = nullptr;
};

static bool _finite(float value) noexcept
{
    return std::isfinite(value);
}

static bool _finite(const Vec2& value) noexcept
{
    return _finite(value.x) && _finite(value.y);
}

static uint32_t _length(const char* value, uint32_t limit) noexcept
{
    if (!value) return 0u;
    auto length = 0u;
    while (length <= limit && value[length]) length++;
    return length;
}

static bool _validId(const char* value) noexcept
{
    auto length = _length(value, Diagram::IdLimit);
    if (!length || length > Diagram::IdLimit) return false;
    for (auto i = 0u; i < length; i++) {
        auto c = value[i];
        if (c == ':' || static_cast<unsigned char>(c) <= 0x20u) return false;
    }
    return true;
}

static bool _validText(const char* value, bool required = false) noexcept
{
    if (!value) return !required;
    auto length = _length(value, LabelLimit);
    return length <= LabelLimit && (!required || length > 0u);
}

static char* _copy(const char* value) noexcept
{
    if (!value) return nullptr;
    auto length = std::strlen(value);
    auto output = new (std::nothrow) char[length + 1u];
    if (!output) return nullptr;
    std::memcpy(output, value, length + 1u);
    return output;
}

static bool _equal(const char* lhs, const char* rhs) noexcept
{
    return lhs && rhs && std::strcmp(lhs, rhs) == 0;
}

static bool _valid(const Config& config) noexcept
{
    auto layout = static_cast<uint8_t>(config.layout);
    auto direction = static_cast<uint8_t>(config.direction);
    return _validId(config.id) && layout <= static_cast<uint8_t>(Layout::Timeline)
           && direction <= static_cast<uint8_t>(Direction::TopToBottom)
           && _finite(config.origin) && _finite(config.nodeSize)
           && config.nodeSize.x > 0.0f && config.nodeSize.y > 0.0f
           && _finite(config.rankGap) && config.rankGap > 0.0f
           && _finite(config.nodeGap) && config.nodeGap >= 0.0f
           && _finite(config.timeUnit) && config.timeUnit > 0.0f
           && _finite(config.zonePadding) && config.zonePadding > 0.0f
           && _finite(config.routeWidth) && config.routeWidth > 0.0f
           && _finite(config.arrowLength) && config.arrowLength > 0.0f
           && _finite(config.arrowWidth) && config.arrowWidth > config.routeWidth
           && _finite(config.corner) && config.corner >= 0.0f;
}

static bool _valid(Port port) noexcept
{
    return static_cast<uint8_t>(port) <= static_cast<uint8_t>(Port::Bottom);
}

static bool _valid(Route route) noexcept
{
    return static_cast<uint8_t>(route) <= static_cast<uint8_t>(Route::Orthogonal);
}

static bool _valid(NodeKind kind) noexcept
{
    return static_cast<uint8_t>(kind) <= static_cast<uint8_t>(NodeKind::Evidence);
}

static bool _valid(EdgeKind kind) noexcept
{
    return static_cast<uint8_t>(kind) <= static_cast<uint8_t>(EdgeKind::Optional);
}

static uint32_t _portIndex(Port port) noexcept
{
    switch (port) {
        case Port::Left: return 0u;
        case Port::Right: return 1u;
        case Port::Top: return 2u;
        case Port::Bottom: return 3u;
        case Port::Auto: break;
    }
    return 0u;
}

static Vec2 _sub(const Vec2& lhs, const Vec2& rhs) noexcept
{
    return {lhs.x - rhs.x, lhs.y - rhs.y};
}

static Vec2 _add(const Vec2& lhs, const Vec2& rhs) noexcept
{
    return {lhs.x + rhs.x, lhs.y + rhs.y};
}

static Vec2 _mul(const Vec2& value, float scalar) noexcept
{
    return {value.x * scalar, value.y * scalar};
}

static float _length(const Vec2& value) noexcept
{
    return std::hypot(value.x, value.y);
}

static bool _near(float lhs, float rhs) noexcept
{
    return std::fabs(lhs - rhs) <= Epsilon;
}

static bool _same(const Vec2& lhs, const Vec2& rhs) noexcept
{
    return _near(lhs.x, rhs.x) && _near(lhs.y, rhs.y);
}

static Port _resolveFrom(const Config& config, const NodeLayout& from,
                         const NodeLayout& to, Port requested) noexcept
{
    if (requested != Port::Auto) return requested;
    if (config.direction == Direction::LeftToRight) {
        return to.center.x >= from.center.x ? Port::Right : Port::Left;
    }
    return to.center.y <= from.center.y ? Port::Bottom : Port::Top;
}

static Port _resolveTo(const Config& config, const NodeLayout& from,
                       const NodeLayout& to, Port requested) noexcept
{
    if (requested != Port::Auto) return requested;
    if (config.direction == Direction::LeftToRight) {
        return to.center.x >= from.center.x ? Port::Left : Port::Right;
    }
    return to.center.y <= from.center.y ? Port::Top : Port::Bottom;
}

static Vec2 _port(const NodeLayout& node, Port port, uint32_t ordinal,
                  uint32_t count) noexcept
{
    auto fraction = (static_cast<float>(ordinal) + 1.0f)
                    / (static_cast<float>(count) + 1.0f) - 0.5f;
    switch (port) {
        case Port::Left:
            return {node.center.x - node.size.x * 0.5f,
                    node.center.y + fraction * node.size.y * 0.7f};
        case Port::Right:
            return {node.center.x + node.size.x * 0.5f,
                    node.center.y + fraction * node.size.y * 0.7f};
        case Port::Top:
            return {node.center.x + fraction * node.size.x * 0.7f,
                    node.center.y + node.size.y * 0.5f};
        case Port::Bottom:
            return {node.center.x + fraction * node.size.x * 0.7f,
                    node.center.y - node.size.y * 0.5f};
        case Port::Auto: break;
    }
    return node.center;
}

static Result _tag(Object* object, const char* prefix, const char* kind,
                   const char* id = nullptr, const char* suffix = nullptr) noexcept
{
    if (!object || !prefix || !kind) return Result::InvalidArguments;
    char value[256];
    auto count = id ? std::snprintf(value, sizeof(value), "%s:%s:%s%s%s", prefix, kind, id,
                                    suffix ? ":" : "", suffix ? suffix : "")
                    : std::snprintf(value, sizeof(value), "%s:%s%s%s", prefix, kind,
                                    suffix ? ":" : "", suffix ? suffix : "");
    if (count <= 0 || static_cast<size_t>(count) >= sizeof(value)) {
        return Result::InvalidArguments;
    }
    object->tag(value);
    return object->tag() && std::strcmp(object->tag(), value) == 0
               ? Result::Success
               : Result::OutOfMemory;
}

static Result _attach(Object* parent, Object* child) noexcept
{
    return parent && child ? parent->add(child) : Result::OutOfMemory;
}

static Color _alpha(Color color, uint8_t alpha) noexcept
{
    color.a = static_cast<uint8_t>((static_cast<uint16_t>(color.a) * alpha) / 255u);
    return color;
}

static Color _nodeStroke(const Theme& theme, NodeKind kind) noexcept
{
    switch (kind) {
        case NodeKind::State: return theme.colors.accent;
        case NodeKind::Decision: return theme.colors.warning;
        case NodeKind::Terminal: return theme.colors.result;
        case NodeKind::Entity: return theme.colors.info;
        case NodeKind::Task: return theme.colors.accent;
        case NodeKind::Evidence: return theme.colors.danger;
        case NodeKind::Cell:
        case NodeKind::Default: return theme.colors.border;
    }
    return theme.colors.border;
}

static Color _nodeFill(const Theme& theme, NodeKind kind) noexcept
{
    switch (kind) {
        case NodeKind::Decision: return _alpha(theme.colors.warning, 44u);
        case NodeKind::Terminal: return _alpha(theme.colors.result, 48u);
        case NodeKind::Task: return _alpha(theme.colors.accent, 56u);
        case NodeKind::Evidence: return _alpha(theme.colors.danger, 44u);
        case NodeKind::State:
        case NodeKind::Entity:
        case NodeKind::Cell:
        case NodeKind::Default: return theme.colors.surface;
    }
    return theme.colors.surface;
}

static Color _edgeColor(const Theme& theme, const EdgeRecord& edge) noexcept
{
    switch (edge.kind) {
        case EdgeKind::Relation: return theme.colors.border;
        case EdgeKind::Return: return theme.colors.muted;
        case EdgeKind::Error: return theme.colors.danger;
        case EdgeKind::Optional: return theme.colors.secondary;
        case EdgeKind::Directed: return edge.flow ? theme.colors.accent : theme.colors.muted;
    }
    return theme.colors.muted;
}

static bool _dashed(const EdgeRecord& edge) noexcept
{
    return edge.flow || edge.kind == EdgeKind::Return || edge.kind == EdgeKind::Error
           || edge.kind == EdgeKind::Optional;
}

static uint32_t _simplify(Vec2* points, uint32_t count) noexcept
{
    if (!points || count < 2u) return 0u;
    auto output = 1u;
    for (auto i = 1u; i < count; i++) {
        if (_same(points[output - 1u], points[i])) continue;
        points[output++] = points[i];
        while (output >= 3u) {
            auto a = points[output - 3u];
            auto b = points[output - 2u];
            auto c = points[output - 1u];
            auto ab = _sub(b, a);
            auto bc = _sub(c, b);
            auto collinear = (_near(ab.x, 0.0f) && _near(bc.x, 0.0f)
                              && ab.y * bc.y > 0.0f)
                             || (_near(ab.y, 0.0f) && _near(bc.y, 0.0f)
                                 && ab.x * bc.x > 0.0f);
            if (!collinear) break;
            points[output - 2u] = points[output - 1u];
            output--;
        }
    }
    return output;
}

static bool _axisAligned(const Vec2* points, uint32_t count) noexcept
{
    if (!points || count < 2u) return false;
    for (auto i = 1u; i < count; i++) {
        auto delta = _sub(points[i], points[i - 1u]);
        if (_length(delta) <= Epsilon) return false;
        if (!_near(delta.x, 0.0f) && !_near(delta.y, 0.0f)) return false;
        if (i < 2u) continue;
        auto previous = _sub(points[i - 1u], points[i - 2u]);
        auto dot = previous.x * delta.x + previous.y * delta.y;
        if (dot < -Epsilon && (_near(previous.x, 0.0f) == _near(delta.x, 0.0f))) {
            return false;
        }
    }
    return true;
}

static uint32_t _centerline(const Config& config, const EdgeRecord& edge,
                            const EdgeLayout& layout, Route route,
                            Vec2* output) noexcept
{
    auto count = 0u;
    output[count++] = layout.from;
    for (auto i = 0u; i < edge.waypointCount; i++) output[count++] = edge.waypoints[i];
    if (!edge.waypointCount && route == Route::Orthogonal
        && !_near(layout.from.x, layout.to.x) && !_near(layout.from.y, layout.to.y)) {
        if (config.direction == Direction::LeftToRight) {
            auto middle = (layout.from.x + layout.to.x) * 0.5f;
            output[count++] = {middle, layout.from.y};
            output[count++] = {middle, layout.to.y};
        } else {
            auto middle = (layout.from.y + layout.to.y) * 0.5f;
            output[count++] = {layout.from.x, middle};
            output[count++] = {layout.to.x, middle};
        }
    }
    output[count++] = layout.to;
    return _simplify(output, count);
}

static Path* _orthogonalPath(const Config& config, const Vec2* route,
                             uint32_t count) noexcept
{
    if (!_axisAligned(route, count)) return nullptr;
    auto last = _sub(route[count - 1u], route[count - 2u]);
    auto lastLength = _length(last);
    if (lastLength <= config.arrowLength + Epsilon) return nullptr;
    auto direction = _mul(last, 1.0f / lastLength);
    auto normal = Vec2{-direction.y, direction.x};
    auto base = _sub(route[count - 1u], _mul(direction, config.arrowLength));

    Vec2 shaft[Diagram::WaypointLimit + 4u];
    auto shaftCount = count;
    for (auto i = 0u; i + 1u < count; i++) shaft[i] = route[i];
    shaft[shaftCount - 1u] = base;
    if (!_axisAligned(shaft, shaftCount)) return nullptr;

    Vec2 left[Diagram::WaypointLimit + 4u];
    Vec2 right[Diagram::WaypointLimit + 4u];
    auto half = config.routeWidth * 0.5f;
    for (auto i = 0u; i < shaftCount; i++) {
        Vec2 offset;
        if (i == 0u) {
            auto delta = _sub(shaft[1u], shaft[0u]);
            auto length = _length(delta);
            offset = _mul(Vec2{-delta.y / length, delta.x / length}, half);
        } else if (i + 1u == shaftCount) {
            auto delta = _sub(shaft[i], shaft[i - 1u]);
            auto length = _length(delta);
            offset = _mul(Vec2{-delta.y / length, delta.x / length}, half);
        } else {
            auto previous = _sub(shaft[i], shaft[i - 1u]);
            auto next = _sub(shaft[i + 1u], shaft[i]);
            auto previousLength = _length(previous);
            auto nextLength = _length(next);
            auto previousNormal = Vec2{-previous.y / previousLength,
                                       previous.x / previousLength};
            auto nextNormal = Vec2{-next.y / nextLength, next.x / nextLength};
            if (_near(previousNormal.x, nextNormal.x)
                && _near(previousNormal.y, nextNormal.y)) {
                offset = _mul(previousNormal, half);
            } else {
                offset = _mul(_add(previousNormal, nextNormal), half);
            }
        }
        left[i] = _add(shaft[i], offset);
        right[i] = _sub(shaft[i], offset);
    }

    PathCommand commands[(Diagram::WaypointLimit + 4u) * 2u + 5u];
    auto commandCount = 0u;
    commands[commandCount++] = PathCommand::move({left[0].x, left[0].y, 0.0f});
    for (auto i = 1u; i < shaftCount; i++) {
        commands[commandCount++] = PathCommand::line({left[i].x, left[i].y, 0.0f});
    }
    auto headHalf = config.arrowWidth * 0.5f;
    auto headLeft = _add(base, _mul(normal, headHalf));
    auto headRight = _sub(base, _mul(normal, headHalf));
    commands[commandCount++] = PathCommand::line({headLeft.x, headLeft.y, 0.0f});
    commands[commandCount++] = PathCommand::line(
        {route[count - 1u].x, route[count - 1u].y, 0.0f});
    commands[commandCount++] = PathCommand::line({headRight.x, headRight.y, 0.0f});
    for (auto i = shaftCount; i > 0u; i--) {
        auto point = right[i - 1u];
        commands[commandCount++] = PathCommand::line({point.x, point.y, 0.0f});
    }
    commands[commandCount++] = PathCommand::close();
    return Path::gen(commands, commandCount, 1u);
}

static Vec2 _labelPoint(const Config& config, const Vec2* points,
                        uint32_t count) noexcept
{
    auto total = 0.0f;
    for (auto i = 1u; i < count; i++) total += _length(_sub(points[i], points[i - 1u]));
    auto target = total * 0.5f;
    auto cursor = 0.0f;
    for (auto i = 1u; i < count; i++) {
        auto segment = _sub(points[i], points[i - 1u]);
        auto length = _length(segment);
        if (cursor + length >= target && length > Epsilon) {
            auto progress = (target - cursor) / length;
            auto point = _add(points[i - 1u], _mul(segment, progress));
            auto normal = Vec2{-segment.y / length, segment.x / length};
            if (normal.y < -Epsilon
                || (_near(normal.y, 0.0f) && normal.x < 0.0f)) {
                normal = _mul(normal, -1.0f);
            }
            auto gap = std::fmax(config.routeWidth * 2.0f,
                                 config.corner + 0.12f);
            return _add(point, _mul(normal, gap));
        }
        cursor += length;
    }
    return points[count - 1u];
}

}  // namespace

struct Diagram::Impl
{
    Config config;
    char* prefix = nullptr;
    NodeRecord* nodes = nullptr;
    EdgeRecord* edges = nullptr;
    ZoneRecord* zones = nullptr;
    uint32_t nodeCount = 0u;
    uint32_t edgeCount = 0u;
    uint32_t zoneCount = 0u;

    ~Impl()
    {
        for (auto i = 0u; i < nodeCount; i++) {
            delete[] nodes[i].id;
            delete[] nodes[i].label;
            delete[] nodes[i].detail;
        }
        for (auto i = 0u; i < edgeCount; i++) {
            delete[] edges[i].id;
            delete[] edges[i].label;
            delete[] edges[i].waypoints;
        }
        for (auto i = 0u; i < zoneCount; i++) {
            delete[] zones[i].id;
            delete[] zones[i].label;
            delete[] zones[i].members;
        }
        delete[] nodes;
        delete[] edges;
        delete[] zones;
        delete[] prefix;
    }
};

struct Built::Impl
{
    Group* root = nullptr;
    Group* zones = nullptr;
    Group* routes = nullptr;
    Group* nodes = nullptr;
    Group* annotations = nullptr;
    NodeView* nodeViews = nullptr;
    EdgeView* edgeViews = nullptr;
    ZoneView* zoneViews = nullptr;
    uint32_t nodeCount = 0u;
    uint32_t edgeCount = 0u;
    uint32_t zoneCount = 0u;

    ~Impl()
    {
        if (root) {
            if (zones && !zones->parent()) delete zones;
            if (routes && !routes->parent()) delete routes;
            if (nodes && !nodes->parent()) delete nodes;
            if (annotations && !annotations->parent()) delete annotations;
        }
        delete root;
        delete[] nodeViews;
        delete[] edgeViews;
        delete[] zoneViews;
    }
};

Diagram::Diagram(Impl* impl) noexcept : pImpl(impl)
{
}

Diagram::~Diagram()
{
    delete pImpl;
}

Diagram* Diagram::gen(const Config& config) noexcept
{
    if (!_valid(config)) return nullptr;
    auto impl = new (std::nothrow) Impl;
    if (!impl) return nullptr;
    impl->prefix = _copy(config.id);
    impl->nodes = new (std::nothrow) NodeRecord[NodeLimit]{};
    impl->edges = new (std::nothrow) EdgeRecord[EdgeLimit]{};
    impl->zones = new (std::nothrow) ZoneRecord[ZoneLimit]{};
    if (!impl->prefix || !impl->nodes || !impl->edges || !impl->zones) {
        delete impl;
        return nullptr;
    }
    impl->config = config;
    impl->config.id = impl->prefix;
    auto diagram = new (std::nothrow) Diagram(impl);
    if (!diagram) delete impl;
    return diagram;
}

Result Diagram::add(const NodeSpec& spec, Node& output) noexcept
{
    if (!pImpl || pImpl->nodeCount >= NodeLimit || !_validId(spec.id)
        || !_validText(spec.label) || !_validText(spec.detail) || !_valid(spec.kind)
        || spec.rank < -1 || spec.row < -1 || spec.column < -1
        || spec.rank >= static_cast<int32_t>(NodeLimit) || !_finite(spec.position)
        || spec.row >= static_cast<int32_t>(NodeLimit)
        || spec.column >= static_cast<int32_t>(NodeLimit) || !_finite(spec.start)
        || !_finite(spec.span) || !_finite(spec.size)
        || ((spec.size.x != 0.0f || spec.size.y != 0.0f)
            && (spec.size.x <= 0.0f || spec.size.y <= 0.0f))) {
        return pImpl && pImpl->nodeCount >= NodeLimit ? Result::InsufficientCondition
                                                      : Result::InvalidArguments;
    }
    switch (pImpl->config.layout) {
        case Layout::Ranked: {
            if (spec.row != -1 || spec.column != -1 || spec.start != 0.0f
                || spec.span != 0.0f) return Result::InvalidArguments;
            break;
        }
        case Layout::Manual: {
            if (!spec.manualPosition || spec.rank != -1 || spec.row != -1
                || spec.column != -1 || spec.start != 0.0f || spec.span != 0.0f) {
                return Result::InvalidArguments;
            }
            break;
        }
        case Layout::Grid: {
            if (spec.manualPosition || spec.rank != -1 || spec.row < 0 || spec.column < 0
                || spec.start != 0.0f || spec.span != 0.0f) {
                return Result::InvalidArguments;
            }
            break;
        }
        case Layout::Timeline: {
            if (spec.manualPosition || spec.rank != -1 || spec.row < 0
                || spec.column != -1 || spec.span <= 0.0f) {
                return Result::InvalidArguments;
            }
            break;
        }
    }
    for (auto i = 0u; i < pImpl->nodeCount; i++) {
        if (_equal(pImpl->nodes[i].id, spec.id)) return Result::InvalidArguments;
        if (pImpl->config.layout == Layout::Grid && pImpl->nodes[i].row == spec.row
            && pImpl->nodes[i].column == spec.column) return Result::InvalidArguments;
    }
    auto id = _copy(spec.id);
    auto label = _copy(spec.label ? spec.label : spec.id);
    auto detail = spec.detail && spec.detail[0] ? _copy(spec.detail) : nullptr;
    if (!id || !label || (spec.detail && spec.detail[0] && !detail)) {
        delete[] id;
        delete[] label;
        delete[] detail;
        return Result::OutOfMemory;
    }
    auto& record = pImpl->nodes[pImpl->nodeCount];
    record.id = id;
    record.label = label;
    record.detail = detail;
    record.kind = spec.kind;
    record.rank = spec.rank;
    record.row = spec.row;
    record.column = spec.column;
    record.start = spec.start;
    record.span = spec.span;
    record.position = spec.position;
    record.size = spec.size;
    record.manualPosition = spec.manualPosition;
    output.index = pImpl->nodeCount++;
    return Result::Success;
}

Result Diagram::add(const EdgeSpec& spec, Edge& output) noexcept
{
    if (!pImpl || pImpl->edgeCount >= EdgeLimit || !_validId(spec.id)
        || !_validText(spec.label) || !spec.from || !spec.to
        || spec.from.index >= pImpl->nodeCount || spec.to.index >= pImpl->nodeCount
        || spec.from.index == spec.to.index || !_valid(spec.fromPort) || !_valid(spec.toPort)
        || !_valid(spec.route) || !_valid(spec.kind)
        || (spec.waypointCount && !spec.waypoints)
        || (!spec.waypointCount && spec.waypoints) || spec.waypointCount > WaypointLimit
        || (spec.route == Route::Straight && spec.waypointCount)
        || !_finite(spec.flowOffset)) {
        return pImpl && pImpl->edgeCount >= EdgeLimit ? Result::InsufficientCondition
                                                      : Result::InvalidArguments;
    }
    for (auto i = 0u; i < pImpl->edgeCount; i++) {
        if (_equal(pImpl->edges[i].id, spec.id)) return Result::InvalidArguments;
    }
    for (auto i = 0u; i < spec.waypointCount; i++) {
        if (!_finite(spec.waypoints[i])
            || (i && _same(spec.waypoints[i - 1u], spec.waypoints[i]))) {
            return Result::InvalidArguments;
        }
    }
    auto id = _copy(spec.id);
    auto label = spec.label && spec.label[0] ? _copy(spec.label) : nullptr;
    auto waypoints = spec.waypointCount
                         ? new (std::nothrow) Vec2[spec.waypointCount]
                         : nullptr;
    if (!id || (spec.label && spec.label[0] && !label)
        || (spec.waypointCount && !waypoints)) {
        delete[] id;
        delete[] label;
        delete[] waypoints;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < spec.waypointCount; i++) waypoints[i] = spec.waypoints[i];
    auto& record = pImpl->edges[pImpl->edgeCount];
    record.id = id;
    record.label = label;
    record.from = spec.from;
    record.to = spec.to;
    record.fromPort = spec.fromPort;
    record.toPort = spec.toPort;
    record.route = spec.route;
    record.kind = spec.kind;
    record.waypoints = waypoints;
    record.waypointCount = spec.waypointCount;
    record.flowOffset = spec.flowOffset;
    record.flow = spec.flow;
    output.index = pImpl->edgeCount++;
    return Result::Success;
}

Result Diagram::add(const ZoneSpec& spec, Zone& output) noexcept
{
    if (!pImpl || pImpl->zoneCount >= ZoneLimit || !_validId(spec.id)
        || !_validText(spec.label) || !spec.members || !spec.memberCount
        || spec.memberCount > pImpl->nodeCount) {
        return pImpl && pImpl->zoneCount >= ZoneLimit ? Result::InsufficientCondition
                                                      : Result::InvalidArguments;
    }
    for (auto i = 0u; i < pImpl->zoneCount; i++) {
        if (_equal(pImpl->zones[i].id, spec.id)) return Result::InvalidArguments;
    }
    for (auto i = 0u; i < spec.memberCount; i++) {
        if (!spec.members[i] || spec.members[i].index >= pImpl->nodeCount) {
            return Result::InvalidArguments;
        }
        for (auto j = 0u; j < i; j++) {
            if (spec.members[i].index == spec.members[j].index) {
                return Result::InvalidArguments;
            }
        }
    }
    auto id = _copy(spec.id);
    auto label = _copy(spec.label ? spec.label : spec.id);
    auto members = new (std::nothrow) Node[spec.memberCount];
    if (!id || !label || !members) {
        delete[] id;
        delete[] label;
        delete[] members;
        return Result::OutOfMemory;
    }
    for (auto i = 0u; i < spec.memberCount; i++) members[i] = spec.members[i];
    auto& record = pImpl->zones[pImpl->zoneCount];
    record.id = id;
    record.label = label;
    record.members = members;
    record.memberCount = spec.memberCount;
    record.fullWidth = spec.fullWidth;
    output.index = pImpl->zoneCount++;
    return Result::Success;
}

uint32_t Diagram::nodeCount() const noexcept
{
    return pImpl ? pImpl->nodeCount : 0u;
}

uint32_t Diagram::edgeCount() const noexcept
{
    return pImpl ? pImpl->edgeCount : 0u;
}

uint32_t Diagram::zoneCount() const noexcept
{
    return pImpl ? pImpl->zoneCount : 0u;
}

Result Diagram::build(const Theme& theme, Built*& output) const noexcept
{
    if (!pImpl || output || !pImpl->nodeCount) return Result::InvalidArguments;

    NodeLayout layouts[NodeLimit]{};
    EdgeLayout edgeLayouts[EdgeLimit]{};
    uint32_t indegree[NodeLimit]{};
    bool processed[NodeLimit]{};
    float rankSpan[NodeLimit]{};
    float rankPosition[NodeLimit]{};
    float rowSpan[NodeLimit]{};
    float rowPosition[NodeLimit]{};
    uint32_t portCount[NodeLimit][4]{};
    uint32_t portCursor[NodeLimit][4]{};

    for (auto i = 0u; i < pImpl->nodeCount; i++) {
        layouts[i].size = (pImpl->nodes[i].size.x > 0.0f) ? pImpl->nodes[i].size
                                                         : pImpl->config.nodeSize;
        layouts[i].rank = pImpl->nodes[i].rank >= 0
                              ? static_cast<uint32_t>(pImpl->nodes[i].rank)
                              : 0u;
    }
    if (pImpl->config.layout == Layout::Ranked) {
        for (auto i = 0u; i < pImpl->edgeCount; i++) indegree[pImpl->edges[i].to.index]++;

        auto visited = 0u;
        while (visited < pImpl->nodeCount) {
            auto current = Node::Invalid;
            for (auto i = 0u; i < pImpl->nodeCount; i++) {
                if (!processed[i] && !indegree[i]) {
                    current = i;
                    break;
                }
            }
            if (current == Node::Invalid) return Result::InvalidArguments;
            processed[current] = true;
            visited++;
            for (auto i = 0u; i < pImpl->edgeCount; i++) {
                auto& edge = pImpl->edges[i];
                if (edge.from.index != current) continue;
                auto target = edge.to.index;
                auto candidate = layouts[current].rank + 1u;
                auto authored = pImpl->nodes[target].rank;
                if (authored >= 0) {
                    if (static_cast<uint32_t>(authored) < candidate) {
                        return Result::InvalidArguments;
                    }
                    layouts[target].rank = static_cast<uint32_t>(authored);
                } else if (layouts[target].rank < candidate) {
                    layouts[target].rank = candidate;
                }
                indegree[target]--;
            }
        }

        auto maximumRank = 0u;
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            maximumRank = layouts[i].rank > maximumRank ? layouts[i].rank : maximumRank;
            auto primary = pImpl->config.direction == Direction::LeftToRight
                               ? layouts[i].size.x
                               : layouts[i].size.y;
            if (primary > rankSpan[layouts[i].rank]) rankSpan[layouts[i].rank] = primary;
        }
        for (auto rank = 0u; rank <= maximumRank; rank++) {
            if (rankSpan[rank] <= 0.0f) {
                rankSpan[rank] = pImpl->config.direction == Direction::LeftToRight
                                     ? pImpl->config.nodeSize.x
                                     : pImpl->config.nodeSize.y;
            }
            if (!rank) {
                rankPosition[rank] = pImpl->config.direction == Direction::LeftToRight
                                         ? pImpl->config.origin.x
                                         : pImpl->config.origin.y;
            } else {
                auto distance = rankSpan[rank - 1u] * 0.5f + pImpl->config.rankGap
                                + rankSpan[rank] * 0.5f;
                rankPosition[rank] = pImpl->config.direction == Direction::LeftToRight
                                         ? rankPosition[rank - 1u] + distance
                                         : rankPosition[rank - 1u] - distance;
            }
        }

        for (auto rank = 0u; rank <= maximumRank; rank++) {
            auto total = 0.0f;
            for (auto i = 0u; i < pImpl->nodeCount; i++) {
                if (layouts[i].rank != rank || pImpl->nodes[i].manualPosition) continue;
                total += pImpl->config.direction == Direction::LeftToRight
                             ? layouts[i].size.y
                             : layouts[i].size.x;
            }
            auto automaticCount = 0u;
            for (auto i = 0u; i < pImpl->nodeCount; i++) {
                if (layouts[i].rank == rank && !pImpl->nodes[i].manualPosition) {
                    automaticCount++;
                }
            }
            if (automaticCount > 1u) {
                total += pImpl->config.nodeGap * (automaticCount - 1u);
            }
            auto cursor = (pImpl->config.direction == Direction::LeftToRight
                               ? pImpl->config.origin.y
                               : pImpl->config.origin.x)
                          + total * 0.5f;
            for (auto i = 0u; i < pImpl->nodeCount; i++) {
                if (layouts[i].rank != rank) continue;
                if (pImpl->nodes[i].manualPosition) {
                    layouts[i].center = pImpl->nodes[i].position;
                    continue;
                }
                auto secondary = pImpl->config.direction == Direction::LeftToRight
                                     ? layouts[i].size.y
                                     : layouts[i].size.x;
                auto position = cursor - secondary * 0.5f;
                if (pImpl->config.direction == Direction::LeftToRight) {
                    layouts[i].center = {rankPosition[rank], position};
                } else {
                    layouts[i].center = {position, rankPosition[rank]};
                }
                cursor -= secondary + pImpl->config.nodeGap;
            }
        }
    } else if (pImpl->config.layout == Layout::Manual) {
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            layouts[i].center = pImpl->nodes[i].position;
        }
    } else if (pImpl->config.layout == Layout::Grid) {
        auto maximumColumn = 0u;
        auto maximumRow = 0u;
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            auto column = static_cast<uint32_t>(pImpl->nodes[i].column);
            auto row = static_cast<uint32_t>(pImpl->nodes[i].row);
            maximumColumn = column > maximumColumn ? column : maximumColumn;
            maximumRow = row > maximumRow ? row : maximumRow;
            if (layouts[i].size.x > rankSpan[column]) rankSpan[column] = layouts[i].size.x;
            if (layouts[i].size.y > rowSpan[row]) rowSpan[row] = layouts[i].size.y;
        }
        for (auto column = 0u; column <= maximumColumn; column++) {
            if (rankSpan[column] <= 0.0f) rankSpan[column] = pImpl->config.nodeSize.x;
        }
        for (auto row = 0u; row <= maximumRow; row++) {
            if (rowSpan[row] <= 0.0f) rowSpan[row] = pImpl->config.nodeSize.y;
        }
        rankPosition[0] = pImpl->config.origin.x;
        rowPosition[0] = pImpl->config.origin.y;
        for (auto column = 1u; column <= maximumColumn; column++) {
            rankPosition[column] = rankPosition[column - 1u]
                                   + rankSpan[column - 1u] * 0.5f
                                   + pImpl->config.rankGap + rankSpan[column] * 0.5f;
        }
        for (auto row = 1u; row <= maximumRow; row++) {
            rowPosition[row] = rowPosition[row - 1u] - rowSpan[row - 1u] * 0.5f
                               - pImpl->config.nodeGap - rowSpan[row] * 0.5f;
        }
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            layouts[i].center = {
                rankPosition[static_cast<uint32_t>(pImpl->nodes[i].column)],
                rowPosition[static_cast<uint32_t>(pImpl->nodes[i].row)],
            };
        }
    } else {
        auto maximumRow = 0u;
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            auto row = static_cast<uint32_t>(pImpl->nodes[i].row);
            maximumRow = row > maximumRow ? row : maximumRow;
            layouts[i].size.x = pImpl->nodes[i].span * pImpl->config.timeUnit;
            if (layouts[i].size.y > rowSpan[row]) rowSpan[row] = layouts[i].size.y;
        }
        for (auto row = 0u; row <= maximumRow; row++) {
            if (rowSpan[row] <= 0.0f) rowSpan[row] = pImpl->config.nodeSize.y;
        }
        rowPosition[0] = pImpl->config.origin.y;
        for (auto row = 1u; row <= maximumRow; row++) {
            rowPosition[row] = rowPosition[row - 1u] - rowSpan[row - 1u] * 0.5f
                               - pImpl->config.nodeGap - rowSpan[row] * 0.5f;
        }
        for (auto i = 0u; i < pImpl->nodeCount; i++) {
            auto& record = pImpl->nodes[i];
            layouts[i].center = {
                pImpl->config.origin.x + (record.start + record.span * 0.5f)
                                                   * pImpl->config.timeUnit,
                rowPosition[static_cast<uint32_t>(record.row)],
            };
        }
    }

    for (auto i = 0u; i < pImpl->edgeCount; i++) {
        auto& edge = pImpl->edges[i];
        auto& layout = edgeLayouts[i];
        layout.fromPort = _resolveFrom(pImpl->config, layouts[edge.from.index],
                                       layouts[edge.to.index], edge.fromPort);
        layout.toPort = _resolveTo(pImpl->config, layouts[edge.from.index],
                                   layouts[edge.to.index], edge.toPort);
        portCount[edge.from.index][_portIndex(layout.fromPort)]++;
        portCount[edge.to.index][_portIndex(layout.toPort)]++;
    }
    for (auto i = 0u; i < pImpl->edgeCount; i++) {
        auto& edge = pImpl->edges[i];
        auto& layout = edgeLayouts[i];
        auto fromSide = _portIndex(layout.fromPort);
        auto toSide = _portIndex(layout.toPort);
        layout.from = _port(layouts[edge.from.index], layout.fromPort,
                            portCursor[edge.from.index][fromSide]++,
                            portCount[edge.from.index][fromSide]);
        layout.to = _port(layouts[edge.to.index], layout.toPort,
                          portCursor[edge.to.index][toSide]++,
                          portCount[edge.to.index][toSide]);
    }

    auto builtImpl = new (std::nothrow) Built::Impl;
    if (!builtImpl) return Result::OutOfMemory;
    builtImpl->nodeCount = pImpl->nodeCount;
    builtImpl->edgeCount = pImpl->edgeCount;
    builtImpl->zoneCount = pImpl->zoneCount;
    builtImpl->nodeViews = new (std::nothrow) NodeView[pImpl->nodeCount]{};
    if (pImpl->edgeCount) {
        builtImpl->edgeViews = new (std::nothrow) EdgeView[pImpl->edgeCount]{};
    }
    if (pImpl->zoneCount) {
        builtImpl->zoneViews = new (std::nothrow) ZoneView[pImpl->zoneCount]{};
    }
    if (!builtImpl->nodeViews || (pImpl->edgeCount && !builtImpl->edgeViews)
        || (pImpl->zoneCount && !builtImpl->zoneViews)) {
        delete builtImpl;
        return Result::OutOfMemory;
    }

    builtImpl->root = Group::gen();
    builtImpl->zones = Group::gen();
    builtImpl->routes = Group::gen();
    builtImpl->nodes = Group::gen();
    builtImpl->annotations = Group::gen();
    auto result = _tag(builtImpl->root, pImpl->prefix, "root");
    if (result == Result::Success) result = _tag(builtImpl->zones, pImpl->prefix, "zones");
    if (result == Result::Success) result = _tag(builtImpl->routes, pImpl->prefix, "routes");
    if (result == Result::Success) result = _tag(builtImpl->nodes, pImpl->prefix, "nodes");
    if (result == Result::Success) {
        result = _tag(builtImpl->annotations, pImpl->prefix, "annotations");
    }
    if (result != Result::Success) {
        delete builtImpl;
        return result;
    }
    if ((result = builtImpl->root->add(builtImpl->zones)) != Result::Success
        || (result = builtImpl->root->add(builtImpl->routes)) != Result::Success
        || (result = builtImpl->root->add(builtImpl->nodes)) != Result::Success
        || (result = builtImpl->root->add(builtImpl->annotations)) != Result::Success) {
        delete builtImpl;
        return result;
    }

    for (auto i = 0u; i < pImpl->zoneCount; i++) {
        auto& record = pImpl->zones[i];
        auto minimum = Vec2{layouts[record.members[0].index].center.x
                                - layouts[record.members[0].index].size.x * 0.5f,
                            layouts[record.members[0].index].center.y
                                - layouts[record.members[0].index].size.y * 0.5f};
        auto maximum = Vec2{layouts[record.members[0].index].center.x
                                + layouts[record.members[0].index].size.x * 0.5f,
                            layouts[record.members[0].index].center.y
                                + layouts[record.members[0].index].size.y * 0.5f};
        for (auto j = 1u; j < record.memberCount; j++) {
            auto& member = layouts[record.members[j].index];
            minimum.x = std::fmin(minimum.x, member.center.x - member.size.x * 0.5f);
            minimum.y = std::fmin(minimum.y, member.center.y - member.size.y * 0.5f);
            maximum.x = std::fmax(maximum.x, member.center.x + member.size.x * 0.5f);
            maximum.y = std::fmax(maximum.y, member.center.y + member.size.y * 0.5f);
        }
        if (record.fullWidth) {
            for (auto j = 0u; j < pImpl->nodeCount; j++) {
                minimum.x = std::fmin(minimum.x, layouts[j].center.x - layouts[j].size.x * 0.5f);
                maximum.x = std::fmax(maximum.x, layouts[j].center.x + layouts[j].size.x * 0.5f);
            }
        }
        minimum.x -= pImpl->config.zonePadding;
        minimum.y -= pImpl->config.zonePadding;
        maximum.x += pImpl->config.zonePadding;
        maximum.y += pImpl->config.zonePadding * 1.45f;
        auto zone = Group::gen();
        auto body = Rectangle::gen({(minimum.x + maximum.x) * 0.5f,
                                    (minimum.y + maximum.y) * 0.5f, 0.0f},
                                   {maximum.x - minimum.x, maximum.y - minimum.y},
                                   pImpl->config.corner * 1.5f);
        auto label = Text::gen(record.label,
                               {minimum.x + pImpl->config.zonePadding * 0.35f,
                                maximum.y - pImpl->config.zonePadding * 0.55f, 0.0f});
        if (!zone || !body || !label) {
            delete zone;
            delete body;
            delete label;
            delete builtImpl;
            return Result::OutOfMemory;
        }
        if ((result = _tag(zone, pImpl->prefix, "zone", record.id)) != Result::Success
            || (result = _tag(body, pImpl->prefix, "zone", record.id, "body"))
                   != Result::Success
            || (result = _tag(label, pImpl->prefix, "zone", record.id, "label"))
                   != Result::Success) {
            delete zone;
            delete body;
            delete label;
            delete builtImpl;
            return result;
        }
        body->fill(_alpha(theme.colors.surface, 150u));
        body->stroke(theme.colors.border, theme.objectWidth);
        body->layer = pImpl->config.layers.zones;
        label->fill(theme.colors.muted);
        label->role = record.fullWidth ? TextRole::Code : TextRole::H3;
        label->align = {0.0f, 0.5f};
        label->layer = pImpl->config.layers.annotations;
        if ((result = _attach(zone, body)) != Result::Success
            || (result = _attach(builtImpl->zones, zone)) != Result::Success
            || (result = _attach(builtImpl->annotations, label)) != Result::Success) {
            if (label && !label->parent()) delete label;
            if (body && !body->parent()) delete body;
            if (zone && !zone->parent()) delete zone;
            delete builtImpl;
            return result;
        }
        builtImpl->zoneViews[i] = {zone, body, label};
    }

    for (auto i = 0u; i < pImpl->edgeCount; i++) {
        auto& record = pImpl->edges[i];
        auto route = record.route;
        if (route == Route::Auto) {
            route = record.waypointCount || (!_near(edgeLayouts[i].from.x, edgeLayouts[i].to.x)
                                             && !_near(edgeLayouts[i].from.y,
                                                       edgeLayouts[i].to.y))
                        ? Route::Orthogonal
                        : Route::Straight;
        }
        Vec2 centerline[WaypointLimit + 4u];
        auto centerlineCount = _centerline(pImpl->config, record, edgeLayouts[i], route,
                                           centerline);
        if (centerlineCount < 2u
            || (route == Route::Orthogonal && !_axisAligned(centerline, centerlineCount))) {
            delete builtImpl;
            return Result::InvalidArguments;
        }
        auto color = _edgeColor(theme, record);
        auto dashed = _dashed(record);
        auto directed = record.kind != EdgeKind::Relation;
        Object* edgeObject = nullptr;
        if (route == Route::Straight) {
            if (directed) {
                edgeObject = Arrow::gen({edgeLayouts[i].from.x, edgeLayouts[i].from.y, 0.0f},
                                        {edgeLayouts[i].to.x, edgeLayouts[i].to.y, 0.0f});
            } else {
                edgeObject = Line::gen({edgeLayouts[i].from.x, edgeLayouts[i].from.y, 0.0f},
                                       {edgeLayouts[i].to.x, edgeLayouts[i].to.y, 0.0f});
            }
            if (edgeObject) {
                edgeObject->stroke(color, theme.objectWidth);
                edgeObject->layer = pImpl->config.layers.routes;
            }
        } else if (!directed || dashed) {
            Vec3 points[WaypointLimit + 4u];
            for (auto j = 0u; j < centerlineCount; j++) {
                points[j] = {centerline[j].x, centerline[j].y, 0.0f};
            }
            if (directed) {
                edgeObject = tmath::DirectedRoute::gen(points, centerlineCount);
            } else {
                edgeObject = Plot::gen(points, centerlineCount);
            }
            if (edgeObject) {
                edgeObject->stroke(color, theme.objectWidth);
                edgeObject->layer = pImpl->config.layers.routes;
            }
        } else {
            auto path = _orthogonalPath(pImpl->config, centerline, centerlineCount);
            if (path) {
                path->fill(color);
                path->stroke({0, 0, 0, 0}, 0.0f);
                path->layer = pImpl->config.layers.routes;
            }
            edgeObject = path;
        }
        if (!edgeObject) {
            delete builtImpl;
            return Result::InvalidArguments;
        }
        result = _tag(edgeObject, pImpl->prefix, "edge", record.id);
        if (result != Result::Success) {
            delete edgeObject;
            delete builtImpl;
            return result;
        }
        if ((result = _attach(builtImpl->routes, edgeObject)) != Result::Success) {
            delete edgeObject;
            delete builtImpl;
            return result;
        }
        builtImpl->edgeViews[i].object = edgeObject;

        if (dashed) {
            float pattern[] = {5.0f, 4.0f};
            result = edgeObject->dash(pattern, 2u, record.flowOffset);
            if (result != Result::Success) {
                delete builtImpl;
                return result;
            }
        }
        if (record.label) {
            auto point = _labelPoint(pImpl->config, centerline, centerlineCount);
            auto label = Text::gen(record.label, {point.x, point.y, 0.0f});
            if (!label) {
                delete builtImpl;
                return Result::OutOfMemory;
            }
            label->fill(color);
            label->role = TextRole::Code;
            label->layer = pImpl->config.layers.annotations;
            result = _tag(label, pImpl->prefix, "edge", record.id, "label");
            if (result != Result::Success) {
                delete label;
                delete builtImpl;
                return result;
            }
            if ((result = _attach(builtImpl->annotations, label)) != Result::Success) {
                delete label;
                delete builtImpl;
                return result;
            }
            builtImpl->edgeViews[i].label = label;
        }
    }

    for (auto i = 0u; i < pImpl->nodeCount; i++) {
        auto& record = pImpl->nodes[i];
        auto& layout = layouts[i];
        auto node = Group::gen();
        auto corner = record.kind == NodeKind::Terminal
                          ? std::fmin(layout.size.x, layout.size.y) * 0.5f
                          : pImpl->config.corner;
        auto body = Rectangle::gen({layout.center.x, layout.center.y, 0.0f}, layout.size,
                                   corner);
        auto labelPoint = record.detail
                              ? Vec3{layout.center.x, layout.center.y + layout.size.y * 0.27f,
                                     0.0f}
                              : Vec3{layout.center.x, layout.center.y, 0.0f};
        auto label = Text::gen(record.label, labelPoint);
        auto detail = record.detail
                          ? Text::gen(record.detail,
                                      {layout.center.x,
                                       layout.center.y - layout.size.y * 0.27f, 0.0f})
                          : nullptr;
        if (!node || !body || !label || (record.detail && !detail)) {
            delete node;
            delete body;
            delete label;
            delete detail;
            delete builtImpl;
            return Result::OutOfMemory;
        }
        if ((result = _tag(node, pImpl->prefix, "node", record.id)) != Result::Success
            || (result = _tag(body, pImpl->prefix, "node", record.id, "body"))
                   != Result::Success
            || (result = _tag(label, pImpl->prefix, "node", record.id, "label"))
                   != Result::Success
            || (detail
                && (result = _tag(detail, pImpl->prefix, "node", record.id, "detail"))
                       != Result::Success)) {
            delete node;
            delete body;
            delete label;
            delete detail;
            delete builtImpl;
            return result;
        }
        body->fill(_nodeFill(theme, record.kind));
        body->stroke(_nodeStroke(theme, record.kind), theme.objectWidth);
        body->layer = pImpl->config.layers.nodes;
        label->fill(theme.colors.foreground);
        label->role = record.kind == NodeKind::Cell || record.kind == NodeKind::Task
                              || record.kind == NodeKind::Terminal
                              || record.kind == NodeKind::Evidence
                          ? TextRole::Code
                          : TextRole::Text;
        label->layer = pImpl->config.layers.annotations;
        if (detail) {
            detail->fill(theme.colors.muted);
            detail->role = TextRole::Code;
            detail->layer = pImpl->config.layers.annotations;
        }
        if ((result = _attach(node, body)) != Result::Success
            || (result = _attach(node, label)) != Result::Success
            || (detail && (result = _attach(node, detail)) != Result::Success)
            || (result = _attach(builtImpl->nodes, node)) != Result::Success) {
            if (body && !body->parent()) delete body;
            if (label && !label->parent()) delete label;
            if (detail && !detail->parent()) delete detail;
            if (node && !node->parent()) delete node;
            delete builtImpl;
            return result;
        }
        builtImpl->nodeViews[i] = {node, body, label, detail};
    }

    auto built = new (std::nothrow) Built(builtImpl);
    if (!built) {
        delete builtImpl;
        return Result::OutOfMemory;
    }
    output = built;
    return Result::Success;
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

Group* Built::release() noexcept
{
    if (!pImpl) return nullptr;
    auto root = pImpl->root;
    pImpl->root = nullptr;
    return root;
}

Group* Built::zones() const noexcept
{
    return pImpl ? pImpl->zones : nullptr;
}

Group* Built::routes() const noexcept
{
    return pImpl ? pImpl->routes : nullptr;
}

Group* Built::nodes() const noexcept
{
    return pImpl ? pImpl->nodes : nullptr;
}

Group* Built::annotations() const noexcept
{
    return pImpl ? pImpl->annotations : nullptr;
}

Object* Built::object(Node node) const noexcept
{
    return pImpl && node && node.index < pImpl->nodeCount
               ? pImpl->nodeViews[node.index].object
               : nullptr;
}

Rectangle* Built::body(Node node) const noexcept
{
    return pImpl && node && node.index < pImpl->nodeCount
               ? pImpl->nodeViews[node.index].body
               : nullptr;
}

Text* Built::label(Node node) const noexcept
{
    return pImpl && node && node.index < pImpl->nodeCount
               ? pImpl->nodeViews[node.index].label
               : nullptr;
}

Text* Built::detail(Node node) const noexcept
{
    return pImpl && node && node.index < pImpl->nodeCount
               ? pImpl->nodeViews[node.index].detail
               : nullptr;
}

Object* Built::object(Edge edge) const noexcept
{
    return pImpl && edge && edge.index < pImpl->edgeCount
               ? pImpl->edgeViews[edge.index].object
               : nullptr;
}

Text* Built::label(Edge edge) const noexcept
{
    return pImpl && edge && edge.index < pImpl->edgeCount
               ? pImpl->edgeViews[edge.index].label
               : nullptr;
}

Object* Built::object(Zone zone) const noexcept
{
    return pImpl && zone && zone.index < pImpl->zoneCount
               ? pImpl->zoneViews[zone.index].object
               : nullptr;
}

Rectangle* Built::body(Zone zone) const noexcept
{
    return pImpl && zone && zone.index < pImpl->zoneCount
               ? pImpl->zoneViews[zone.index].body
               : nullptr;
}

Text* Built::label(Zone zone) const noexcept
{
    return pImpl && zone && zone.index < pImpl->zoneCount
               ? pImpl->zoneViews[zone.index].label
               : nullptr;
}

}  // namespace tmath::diagram
