#include <cmath>
#include <cstdio>
#include <cstring>

#include "tmath_diagram.h"

using namespace tmath;
using namespace tmath::diagram;

static int failures = 0;

#define CHECK(condition)                                                                       \
    do {                                                                                       \
        if (!(condition)) {                                                                    \
            std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                                        \
        }                                                                                      \
    } while (false)

static bool near(float lhs, float rhs, float epsilon = 1.0e-4f)
{
    return std::fabs(lhs - rhs) <= epsilon;
}

static NodeSpec nodeSpec(const char* id, const char* label, const char* detail = nullptr)
{
    NodeSpec spec;
    spec.id = id;
    spec.label = label;
    spec.detail = detail;
    return spec;
}

static EdgeSpec edgeSpec(const char* id, Node from, Node to)
{
    EdgeSpec spec;
    spec.id = id;
    spec.from = from;
    spec.to = to;
    return spec;
}

static ZoneSpec zoneSpec(const char* id, const char* label, const Node* members,
                         uint32_t count)
{
    ZoneSpec spec;
    spec.id = id;
    spec.label = label;
    spec.members = members;
    spec.memberCount = count;
    return spec;
}

static void aggregateCompatibility()
{
    tmath::diagram::Config config{
        "legacy", Direction::TopToBottom, {}, {2.0f, 1.0f}, 1.0f, 0.5f,
        0.4f, 0.08f, 0.32f, 0.28f, 0.12f, {},
    };
    CHECK(config.layout == Layout::Ranked && near(config.timeUnit, 1.0f));

    NodeSpec node{"node", "Node", nullptr, -1, {}, {}, false};
    CHECK(node.kind == NodeKind::Default && node.row == -1 && node.column == -1);

    Node from{0u};
    Node to{1u};
    EdgeSpec edge{
        "edge", nullptr, from, to, Port::Auto, Port::Auto, Route::Auto,
        nullptr, 0u, 0.0f, false,
    };
    CHECK(edge.kind == EdgeKind::Directed);

    Node members[] = {from};
    ZoneSpec zone{"zone", nullptr, members, 1u};
    CHECK(!zone.fullWidth);
}

static void ownershipAndBands()
{
    tmath::diagram::Config config;
    config.id = "pipeline";
    auto diagram = Diagram::gen(config);
    CHECK(diagram);
    if (!diagram) return;

    Node input;
    Node output;
    Edge transfer;
    Zone service;
    CHECK(diagram->add(nodeSpec("input", "Input", "request"), input) == Result::Success);
    NodeSpec outputSpec;
    outputSpec.id = "output";
    outputSpec.label = "Output";
    outputSpec.detail = "response";
    CHECK(diagram->add(outputSpec, output) == Result::Success);

    EdgeSpec edge;
    edge.id = "transfer";
    edge.label = "dispatch";
    edge.from = input;
    edge.to = output;
    edge.route = Route::Straight;
    edge.flow = true;
    edge.flowOffset = 2.0f;
    CHECK(diagram->add(edge, transfer) == Result::Success);
    Node members[] = {input, output};
    CHECK(diagram->add(zoneSpec("service", "Service", members, 2u), service)
          == Result::Success);

    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ProWhite), built) == Result::Success);
    CHECK(built && built->root() && built->zones() && built->routes() && built->nodes()
          && built->annotations());
    if (!built) {
        delete diagram;
        return;
    }
    CHECK(std::strcmp(built->root()->tag(), "pipeline:root") == 0);
    CHECK(std::strcmp(built->object(input)->tag(), "pipeline:node:input") == 0);
    CHECK(built->body(input) && built->label(input) && built->detail(input));
    CHECK(built->body(input)->center.x < built->body(output)->center.x);
    CHECK(built->object(transfer) && built->object(transfer)->type() == Type::Arrow);
    CHECK(built->object(transfer)->childCount() == 0u);
    CHECK(built->object(transfer)->style.dashCount == 2u);
    CHECK(near(built->object(transfer)->style.dashOffset, 2.0f));
    CHECK(built->label(transfer));
    CHECK(built->object(service) && built->body(service) && built->label(service));
    CHECK(built->body(service)->size.x > built->body(output)->center.x
                                            - built->body(input)->center.x);

    auto root = built->release();
    CHECK(root && !built->root());
    CHECK(built->object(input) && built->object(transfer) && built->object(service));
    delete built;
    CHECK(std::strcmp(root->tag(), "pipeline:root") == 0);
    delete root;
    delete diagram;
}

static void rankedLayouts()
{
    tmath::diagram::Config config;
    config.direction = Direction::TopToBottom;
    auto diagram = Diagram::gen(config);
    CHECK(diagram);
    if (!diagram) return;

    Node start;
    Node first;
    Node second;
    Node final;
    CHECK(diagram->add(nodeSpec("start", "Start"), start) == Result::Success);
    CHECK(diagram->add(nodeSpec("first", "First"), first) == Result::Success);
    CHECK(diagram->add(nodeSpec("second", "Second"), second) == Result::Success);
    NodeSpec finalSpec;
    finalSpec.id = "final";
    finalSpec.label = "Final";
    finalSpec.rank = 4;
    CHECK(diagram->add(finalSpec, final) == Result::Success);

    Edge firstRoute;
    Edge secondRoute;
    Edge finalRoute;
    auto firstEdge = edgeSpec("a", start, first);
    firstEdge.route = Route::Straight;
    auto secondEdge = edgeSpec("b", start, second);
    secondEdge.route = Route::Straight;
    auto finalEdge = edgeSpec("c", first, final);
    finalEdge.route = Route::Straight;
    CHECK(diagram->add(firstEdge, firstRoute) == Result::Success);
    CHECK(diagram->add(secondEdge, secondRoute) == Result::Success);
    CHECK(diagram->add(finalEdge, finalRoute) == Result::Success);

    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success);
    CHECK(built);
    if (built) {
        CHECK(built->body(start)->center.y > built->body(first)->center.y);
        CHECK(built->body(first)->center.y > built->body(final)->center.y);
        CHECK(built->body(first)->center.x > built->body(second)->center.x);
        auto firstArrow = static_cast<Arrow*>(built->object(firstRoute));
        auto secondArrow = static_cast<Arrow*>(built->object(secondRoute));
        CHECK(firstArrow && secondArrow && firstArrow->from.x < secondArrow->from.x);
    }
    delete built;
    delete diagram;
}

static void manualRoute()
{
    tmath::diagram::Config config;
    config.id = "manual";
    auto diagram = Diagram::gen(config);
    CHECK(diagram);
    if (!diagram) return;

    Node source;
    Node target;
    NodeSpec sourceSpec;
    sourceSpec.id = "source";
    sourceSpec.label = "Source";
    sourceSpec.manualPosition = true;
    sourceSpec.position = {0.0f, 0.0f};
    NodeSpec targetSpec;
    targetSpec.id = "target";
    targetSpec.label = "Target";
    targetSpec.manualPosition = true;
    targetSpec.position = {6.0f, 2.0f};
    CHECK(diagram->add(sourceSpec, source) == Result::Success);
    CHECK(diagram->add(targetSpec, target) == Result::Success);

    Vec2 waypoints[] = {{3.0f, 0.0f}, {3.0f, 2.0f}};
    EdgeSpec edgeSpec;
    edgeSpec.id = "route";
    edgeSpec.from = source;
    edgeSpec.to = target;
    edgeSpec.fromPort = Port::Right;
    edgeSpec.toPort = Port::Left;
    edgeSpec.route = Route::Orthogonal;
    edgeSpec.waypoints = waypoints;
    edgeSpec.waypointCount = 2u;
    edgeSpec.flow = true;
    Edge route;
    CHECK(diagram->add(edgeSpec, route) == Result::Success);

    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ProBlack), built) == Result::Success);
    CHECK(built);
    if (built) {
        CHECK(near(built->body(source)->center.x, 0.0f));
        CHECK(near(built->body(source)->center.y, 0.0f));
        CHECK(near(built->body(target)->center.x, 6.0f));
        CHECK(near(built->body(target)->center.y, 2.0f));
        CHECK(built->object(route) && built->object(route)->type() == Type::Route);
        auto path = static_cast<tmath::DirectedRoute*>(built->object(route));
        CHECK(path->count() >= 3u && path->childCount() == 0u);
        CHECK(path->style.dashCount == 2u);
    }
    delete built;
    delete diagram;
}

static void edgeLabelsClearRoutes()
{
    tmath::diagram::Config config;
    config.id = "labels";
    auto diagram = Diagram::gen(config);
    CHECK(diagram);
    if (!diagram) return;

    Node source;
    Node target;
    CHECK(diagram->add(nodeSpec("source", "Source"), source) == Result::Success);
    CHECK(diagram->add(nodeSpec("target", "Target"), target) == Result::Success);
    auto spec = edgeSpec("route", source, target);
    spec.label = "payload";
    spec.route = Route::Straight;
    Edge route;
    CHECK(diagram->add(spec, route) == Result::Success);

    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success);
    CHECK(built && built->label(route));
    if (built && built->label(route)) {
        auto arrow = static_cast<Arrow*>(built->object(route));
        auto midpointY = (arrow->from.y + arrow->to.y) * 0.5f;
        CHECK(built->label(route)->point.y > midpointY);
    }
    delete built;
    delete diagram;
}

static void gridAndTimelineLayouts()
{
    tmath::diagram::Config gridConfig;
    gridConfig.layout = Layout::Grid;
    gridConfig.origin = {-4.0f, 3.0f};
    gridConfig.nodeSize = {2.0f, 1.0f};
    gridConfig.rankGap = 0.5f;
    gridConfig.nodeGap = 0.75f;
    auto diagram = Diagram::gen(gridConfig);
    CHECK(diagram);
    if (!diagram) return;

    Node first;
    Node second;
    NodeSpec firstSpec;
    firstSpec.id = "first";
    firstSpec.row = 0;
    firstSpec.column = 0;
    NodeSpec secondSpec;
    secondSpec.id = "second";
    secondSpec.row = 1;
    secondSpec.column = 1;
    CHECK(diagram->add(firstSpec, first) == Result::Success);
    CHECK(diagram->add(secondSpec, second) == Result::Success);
    Node firstLaneMembers[] = {first};
    auto firstLaneSpec = zoneSpec("first-lane", "Lane 1", firstLaneMembers, 1u);
    firstLaneSpec.fullWidth = true;
    Zone firstLane;
    CHECK(diagram->add(firstLaneSpec, firstLane) == Result::Success);
    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success);
    CHECK(built && near(built->body(first)->center.x, -4.0f));
    CHECK(built && near(built->body(first)->center.y, 3.0f));
    CHECK(built && near(built->body(second)->center.x, -1.5f));
    CHECK(built && near(built->body(second)->center.y, 1.25f));
    CHECK(built && built->body(firstLane)->size.x > 4.5f);
    delete built;
    delete diagram;

    tmath::diagram::Config timelineConfig;
    timelineConfig.layout = Layout::Timeline;
    timelineConfig.origin = {-5.0f, 2.0f};
    timelineConfig.nodeSize = {1.0f, 0.8f};
    timelineConfig.nodeGap = 0.4f;
    timelineConfig.timeUnit = 1.5f;
    diagram = Diagram::gen(timelineConfig);
    CHECK(diagram);
    if (!diagram) return;
    Node task;
    NodeSpec taskSpec;
    taskSpec.id = "task";
    taskSpec.kind = NodeKind::Task;
    taskSpec.row = 1;
    taskSpec.start = 2.0f;
    taskSpec.span = 3.0f;
    CHECK(diagram->add(taskSpec, task) == Result::Success);
    built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success);
    CHECK(built && near(built->body(task)->size.x, 4.5f));
    CHECK(built && near(built->body(task)->center.x, 0.25f));
    CHECK(built && near(built->body(task)->center.y, 0.8f));
    delete built;
    delete diagram;
}

static void manualCyclesAndKinds()
{
    tmath::diagram::Config config;
    config.layout = Layout::Manual;
    auto diagram = Diagram::gen(config);
    CHECK(diagram);
    if (!diagram) return;

    Node first;
    Node second;
    Node third;
    NodeSpec spec;
    spec.id = "first";
    spec.manualPosition = true;
    spec.position = {-4.0f, 0.0f};
    spec.kind = NodeKind::State;
    CHECK(diagram->add(spec, first) == Result::Success);
    spec.id = "second";
    spec.position = {0.0f, 0.0f};
    spec.kind = NodeKind::Decision;
    CHECK(diagram->add(spec, second) == Result::Success);
    spec.id = "third";
    spec.position = {4.0f, 0.0f};
    spec.kind = NodeKind::Terminal;
    CHECK(diagram->add(spec, third) == Result::Success);

    Edge firstEdge;
    Edge secondEdge;
    Edge relation;
    auto edge = edgeSpec("first-second", first, second);
    edge.route = Route::Straight;
    CHECK(diagram->add(edge, firstEdge) == Result::Success);
    edge = edgeSpec("second-third", second, third);
    edge.route = Route::Straight;
    edge.kind = EdgeKind::Return;
    CHECK(diagram->add(edge, secondEdge) == Result::Success);
    edge = edgeSpec("third-first", third, first);
    edge.route = Route::Straight;
    edge.kind = EdgeKind::Relation;
    CHECK(diagram->add(edge, relation) == Result::Success);

    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built) == Result::Success);
    CHECK(built && built->object(firstEdge)->type() == Type::Arrow);
    CHECK(built && built->object(secondEdge)->style.dashCount == 2u);
    CHECK(built && built->object(relation)->type() == Type::Line);
    CHECK(built && near(built->body(third)->corner, 0.6f));
    delete built;
    delete diagram;
}

static void invalidGraphs()
{
    tmath::diagram::Config invalidConfig;
    invalidConfig.id = "bad:id";
    CHECK(Diagram::gen(invalidConfig) == nullptr);

    tmath::diagram::Config manualConfig;
    manualConfig.layout = Layout::Manual;
    auto manualDiagram = Diagram::gen(manualConfig);
    CHECK(manualDiagram);
    if (manualDiagram) {
        NodeSpec missingPosition;
        missingPosition.id = "missing-position";
        Node node;
        CHECK(manualDiagram->add(missingPosition, node) == Result::InvalidArguments);
    }
    delete manualDiagram;

    tmath::diagram::Config gridConfig;
    gridConfig.layout = Layout::Grid;
    auto gridDiagram = Diagram::gen(gridConfig);
    CHECK(gridDiagram);
    if (gridDiagram) {
        NodeSpec cell;
        cell.id = "first-cell";
        cell.row = 0;
        cell.column = 0;
        Node firstCell;
        CHECK(gridDiagram->add(cell, firstCell) == Result::Success);
        cell.id = "duplicate-cell";
        Node duplicateCell;
        CHECK(gridDiagram->add(cell, duplicateCell) == Result::InvalidArguments);
    }
    delete gridDiagram;

    tmath::diagram::Config timelineConfig;
    timelineConfig.layout = Layout::Timeline;
    auto timelineDiagram = Diagram::gen(timelineConfig);
    CHECK(timelineDiagram);
    if (timelineDiagram) {
        NodeSpec zeroSpan;
        zeroSpan.id = "zero-span";
        zeroSpan.row = 0;
        Node task;
        CHECK(timelineDiagram->add(zeroSpan, task) == Result::InvalidArguments);
    }
    delete timelineDiagram;

    auto diagram = Diagram::gen();
    CHECK(diagram);
    if (!diagram) return;
    Node first;
    Node second;
    CHECK(diagram->add(nodeSpec("same", "First"), first) == Result::Success);
    Node unchanged;
    CHECK(diagram->add(nodeSpec("same", "Duplicate"), unchanged)
          == Result::InvalidArguments);
    CHECK(!unchanged && diagram->nodeCount() == 1u);
    CHECK(diagram->add(nodeSpec("second", "Second"), second) == Result::Success);
    Node duplicated[] = {first, first};
    Zone zone;
    CHECK(diagram->add(zoneSpec("duplicate-zone", nullptr, duplicated, 2u), zone)
          == Result::InvalidArguments);

    Edge forward;
    Edge backward;
    CHECK(diagram->add(edgeSpec("forward", first, second), forward) == Result::Success);
    CHECK(diagram->add(edgeSpec("backward", second, first), backward) == Result::Success);
    Built* built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built)
          == Result::InvalidArguments);
    CHECK(!built);
    delete diagram;

    diagram = Diagram::gen();
    CHECK(diagram);
    if (!diagram) return;
    Node source;
    Node target;
    CHECK(diagram->add(nodeSpec("source", "Source"), source) == Result::Success);
    CHECK(diagram->add(nodeSpec("target", "Target"), target) == Result::Success);
    Vec2 diagonal[] = {{2.0f, 1.0f}};
    EdgeSpec invalidRoute;
    invalidRoute.id = "diagonal";
    invalidRoute.from = source;
    invalidRoute.to = target;
    invalidRoute.route = Route::Orthogonal;
    invalidRoute.waypoints = diagonal;
    invalidRoute.waypointCount = 1u;
    Edge invalid;
    CHECK(diagram->add(invalidRoute, invalid) == Result::Success);
    built = nullptr;
    CHECK(diagram->build(Theme::preset(ThemePreset::ThreeBlueOneEyes), built)
          == Result::InvalidArguments);
    CHECK(!built);
    delete diagram;
}

int main()
{
    aggregateCompatibility();
    ownershipAndBands();
    rankedLayouts();
    manualRoute();
    edgeLabelsClearRoutes();
    gridAndTimelineLayouts();
    manualCyclesAndKinds();
    invalidGraphs();
    return failures ? 1 : 0;
}
