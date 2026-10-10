# Native Lua Diagram authoring

Use this optional Lua sidecar only when its bounded semantic IR matches the evidence. They do not parse Mermaid, draw.io, SVG, HTML, or templates; JavaScript/TypeScript uses ordinary Object handles instead. A missing namespace is a hard failure for a scene that requires it—do not silently substitute a different layout.

`tmath.diagram(scene, config)` supports ranked, manual, grid, and timeline layouts with nodes, edges, zones, explicit ports, waypoints, and straight/orthogonal routes. It is a one-shot lowering:

```text
semantic inventory -> bounded IR -> layout/routing -> ordinary Object tree
```

Create the inventory, call `build()` exactly once, retain returned handles, then animate or annotate that generated Object tree with the ordinary timeline API. Attachment seals the generated subtree. Configure the Scene Theme before `build()` and measure the result before adding specialized glyphs.

The generated root retains a versioned Diagram IR after the one-shot builder and Lua
VM are gone. In a Diagram-enabled native publish build, run `tmath audit` with the
delivery font. Its JSON `diagramIR` receipt preserves semantic string IDs, authored
relations, computed placements, and Object bindings at the exact root, Viewport, or
transition `scenePath`. Treat `(scenePath, diagram id, entity kind, entity id)` as the
stable join key; numeric builder handles are temporary and must not be stored as
identity.

The audit automatically checks node label/detail Text against its node body and zone
label Text against its zone body. Use an explicit containment or uncontained policy
only when the scene intentionally overrides that generated ownership; an explicit
policy wins. Static IR diagnostics are deterministic authoring failures with repair
codes. They complement, rather than replace, the production-font and full-timeline
layout checks. At every delivery sample, the Diagram-enabled audit joins those stable
bindings to root-pixel rendered paths and checks route/node, route/label, route/route,
and route/canvas clearance. `--diagram-route-gap` controls route clearance and
`--canvas-inset` controls route-to-clip clearance. Edge labels are free-floating Text,
so explicitly declare them uncontained when using the strict containment ledger; the
physical pass still checks them against every other route.

For diagrams, use `layout = "ranked"|"manual"|"grid"|"timeline"`; manual nodes require positions, grid cells are unique zero-based rows/columns, and timeline tasks have row, finite start, and positive span. Use node kinds only as restrained Theme treatment, not as a promise of a complete UML, ER, Gantt, or matrix grammar. Edges name their relation kind, `from`/`to`, optional ports and waypoints, and use `route = "auto"|"straight"|"orthogonal"`; duplicate IDs, cross-builder handles, self-edges, invalid grid cells, waypoints on a straight route, and repeated builds fail closed.

The `tmath.diagram.layout/v2` lowering distinguishes authored constraints from
automatic choices. In a ranked diagram, a node with an authored position is a hard
pin; automatically placed nodes in that rank reflow around it instead of moving the
pin. A ranked block moves by one common translation, and lowering fails closed if its
bounded reflow cannot find stored float centers that preserve automatic-node
separation; exhaustion does not prove that no mathematical translation exists.
Spacing admits only the stored centers' local float-ULP tolerance; canonical overlap
never does. Manual
positions and timeline row/start/span values remain authoritative. A
no-waypoint `auto` or `orthogonal` edge uses deterministic bounded obstacle routing
against expanded node bounds in Diagram world space. A candidate must follow both
resolved port normals and reserve a drawable terminal arrow segment; a clear aligned
`auto` edge may still lower as a straight edge. An authored `straight` route or
waypoint sequence remains exact even when it crosses a node or approaches a port from
the wrong side: lowering does not silently change the claimed path, and `tmath audit`
reports the conflict for the author to resolve. The bounded search tries elbows,
obstacle corridors, and outer escapes; a residual conflict remains a diagnostic rather
than permission to move authored geometry.

Every directed edge lowers to one marker-bearing object: straight to `Arrow`, dashed orthogonal to `Route`, and undashed orthogonal to one closed filled `Path`. A relation has no invented head. A route's markers and shaft remain one identity through Create/Uncreate; `flow` applies the dash to that same eligible object. Zones derive bounds from members; `full_width` only spans the inventory and does not create a swimlane grammar.

The static v2 pass is intentionally local. Its obstacle routing and validation use
settled world-space node geometry; candidate scoring does not know which equal-cost
corridor stays inside the eventual canvas or Viewport. The full-timeline audit is the
separate physical gate: it samples transformed and projected renderer paths, including
stroke and marker geometry, without changing the authored route. It is conservative
for dashed routes and stretched Viewports, uses Text paint boxes rather than glyph
contours, permits a route's own label and intended endpoint-node contacts, clips only
a bounded shared-endpoint junction before comparing two routes, and samples at
delivery frames rather than proving continuous-time clearance. Crossings outside that
junction remain failures. Inspect worst-frame rasters as the final evidence.
