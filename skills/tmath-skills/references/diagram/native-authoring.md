# Native Lua Diagram and Chart authoring

Use these optional Lua sidecars only when their bounded semantic IR matches the evidence. They do not parse Mermaid, draw.io, SVG, HTML, or templates; JavaScript/TypeScript uses ordinary Object handles instead. A missing namespace is a hard failure for a scene that requires it—do not silently substitute a different layout.

`tmath.diagram(scene, config)` supports ranked, manual, grid, and timeline layouts with nodes, edges, zones, explicit ports, waypoints, and straight/orthogonal routes. `tmath.chart(scene, config)` supports line and bar series with axes, grid, ticks, and legend. Both are one-shot lowerings:

```text
semantic inventory -> bounded IR -> layout/routing or scale mapping -> ordinary Object tree
```

Create the inventory, call `build()` exactly once, retain returned handles, then animate or annotate that generated Object tree with the ordinary timeline API. Attachment seals the generated subtree. Configure the Scene Theme before `build()` and measure the result before adding specialized glyphs.

For diagrams, use `layout = "ranked"|"manual"|"grid"|"timeline"`; manual nodes require positions, grid cells are unique zero-based rows/columns, and timeline tasks have row, finite start, and positive span. Use node kinds only as restrained Theme treatment, not as a promise of a complete UML, ER, Gantt, or matrix grammar. Edges name their relation kind, `from`/`to`, optional ports and waypoints, and use `route = "auto"|"straight"|"orthogonal"`; duplicate IDs, cross-builder handles, self-edges, invalid grid cells, waypoints on a straight route, and repeated builds fail closed.

Every directed edge lowers to one marker-bearing object: straight to `Arrow`, dashed orthogonal to `Route`, and undashed orthogonal to one closed filled `Path`. A relation has no invented head. A route's markers and shaft remain one identity through Create/Uncreate; `flow` applies the dash to that same eligible object. Zones derive bounds from members; `full_width` only spans the inventory and does not create a swimlane grammar.

For charts, provide the complete quantitative domain and canonical series data; do not infer a domain from an attractive curve. Add categorical semantics and nonstandard axes with ordinary scene objects. Generated handles are evidence objects, not permission to skip source, route, text, raster, or seam review.
