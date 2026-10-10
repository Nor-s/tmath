# Full-timeline layout audit

`tmath audit` turns renderer layout inspection into a deterministic publish gate. It
loads the Lua Scene, registers the exact delivery font, samples every frame that the
native saver would encode, and includes the exact final time. For a positive-duration
Scene, the final time is appended as a separate sample. A layout violation exits with
status `1` while still writing a complete report.

Before sampling, it inventories the full root, Viewport, and transition Scene tree.
This keeps stable paths for inactive stages and reports authored Text that the chosen
delivery FPS never displays.

When the optional Diagram module is linked, that inventory also discovers the
versioned semantic IR retained by each generated diagram root. The IR is inspected
after Lua construction has ended; the audit does not depend on a live Lua builder.
It is a tmath-native compile receipt, not a Manim format or compatibility layer.

```sh
build/tmath audit scene.lua \
  --font src/examples/assets/Pretendard.ttf \
  --max-samples 1200 \
  --text-gap 4 --canvas-inset 4 --panel-inset 12 --diagram-route-gap 2 \
  --require-containment-ledger \
  --contain node-label node-body 12 \
  --allow-uncontained title \
  --allow-occluded-scene root
```

The default output is `tmath.layout-audit/v1` JSON. Use `--format text` for a short
human-readable report. `--width`, `--height`, and `--fps` select an explicit output
profile before measurement. `--max-samples` sets an optional positive hard limit on
the native saver timeline, including its exact-final sample. If that calculated count
is larger, the command exits with status `4` before Scene inventory or layout
sampling. Omitting the option leaves the standalone command uncapped.

## Contract

Every authored Text needs a stable object ID. The audit checks:

- Text paint bounds against the current root or Viewport clip with
  `--canvas-inset`;
- Text/Text clearance with `--text-gap`;
- each declared Text-to-Rectangle relationship with `--contain`;
- missing or never-painted Text IDs, duplicate object IDs within a Scene, and
  unmatched ledger declarations;
- Text fully covered by a later opaque mounted Scene background, unless its
  authored Scene path is explicitly allowed;
- nonuniform Viewport or Scene-transition mounts unless
  `--allow-viewport-stretch` is explicit.

For each retained Diagram IR, the audit additionally checks its local, static
constraints and reports failures as ordinary error issues with repair codes. Node
label and detail Text are automatically related to that node's body Rectangle, and a
zone label is automatically related to that zone's body Rectangle. An explicit
`--contain` or `--allow-uncontained` entry for the same Text ID replaces the generated
relationship. Generated entries alone carry a `provenance` object in the policy
receipt; the JSON shape of user-authored entries is unchanged.

The optional Diagram module then joins that semantic receipt to the CPU renderer's
sampled path geometry at every encoded frame and at the exact final time. In root
output pixels it checks each visible route against non-endpoint node bodies, node
labels/details, other edge labels, zone labels, other routes, and its active canvas or
Viewport clip. `--diagram-route-gap` sets route-to-object and route-to-route
clearance; `--canvas-inset` is also the required route-to-clip clearance. Stroke and
marker paths contribute their rendered footprint. These physical failures use the
`diagram_sampled_*` issue codes and `sampled-rendered-geometry` provenance. They do
not change the static receipt's `constraints.valid` value and never reroute or move
authored geometry.

The `tmath.diagram.layout/v2` receipt records the result of a deterministic static
layout pass. In ranked diagrams, automatically placed blocks reflow along their rank
around nodes with authored positions; those positioned nodes are hard pins and are
not displaced. The block uses one common translation; if the bounded reflow cannot
find a translation whose stored float geometry preserves automatic-node separation,
the build fails closed instead of returning an already-overlapping IR. Exhaustion is
not a proof that no mathematical translation exists. Configured spacing allows only
the stored centers' local float-ULP tolerance; canonical overlap is never tolerated. A
no-waypoint `auto` or `orthogonal` edge uses deterministic routing around expanded
node bounds in Diagram world space. A candidate must leave and enter
through the resolved port directions and leave enough terminal length for a solid
arrowhead; a clear aligned `auto` edge may still lower as a straight edge. Authored
`straight` routes and authored waypoint sequences are not rewritten, so a conflicting
route remains visible in the receipt and fails the corresponding static constraint.
This includes `diagram_edge_endpoint_direction` when a fixed path only touches a port
but approaches it from the wrong side.
Manual positions and timeline starts, spans, and rows likewise remain authoritative
rather than being moved to make a diagnostic disappear.

The v2 router is a deterministic bounded candidate search, not a complete orthogonal
visibility-graph solver. It tries local elbows, obstacle corridors, and one- or
two-ended escapes outside the settled node bounds. If none is valid, it preserves the
fallback placement so the static audit can report the unresolved conflict; it does not
move authored nodes or silently reinterpret a fixed route.

An edge label is intentionally free-floating rather than contained by a Rectangle.
When `--require-containment-ledger` is used, declare each edge label with
`--allow-uncontained`; the sampled Diagram pass still checks its clearance from
every other route. Its own route is exempt because the compiler deliberately anchors
the label to that route.

The sampled report deliberately separates authored Objects from physical visuals
and their renderer-sampled path vertices. Each path references its owning visual and
records root-pixel points, fill/stroke/closed flags, scaled stroke width, and a
conservative paint envelope.
Canvas and Text/Text gap checks run against the actual ThorVG-measured visuals, not
against unblended stage bounds. A compatible transition morph contributes one visual
and marks both Text identities as painted. Incompatible or unmatched commands remain
separate outgoing/incoming fade visuals, so simultaneous transition labels can still
fail the gap rule. Exact transition endpoints contain only the selected stable stage.
Containment policy remains attached to authored IDs and is evaluated against every
physical visual that applies to that identity.

`visible` means that paint survives authored alpha and ancestor clipping. A visual is
also marked `occluded`, with an `occluder` Scene index, when a later, fully opaque
mounted Scene background contains its entire clipped bounds. Occluded visuals remain
traceable to their authored Object and are excluded from Text/Text, canvas, and
containment checks because the learner cannot see them; instead, they produce a
`text_occluded` error. Use `--allow-occluded-scene PATH` only when that complete cover
is an intentional composition boundary. Transparent Viewports still share the
parent's collision space. Partial cover is handled conservatively as visible; the
report does not claim arbitrary shape-level occlusion.

`--contain TEXT PANEL [INSET]` compares the Text's own paint bounds with the owning
Rectangle's own paint bounds in root pixels. It does not use authored anchors, Group
bounds, or the Rectangle's descendant-inclusive family bounds, so the Rectangle may
be an ancestor of the Text without making the check tautological. The optional inset
overrides `--panel-inset` for that relationship.

With `--require-containment-ledger`, every distinct Text ID must choose exactly one
global policy: the Text side of one `--contain`, or one `--allow-uncontained` entry.
`--allow-uncontained` is rejected as invalid syntax unless
`--require-containment-ledger` is also present, because it has no effect outside that
mode.
Use `--allow-text-overlap FIRST_PATH FIRST_ID SECOND_PATH SECOND_ID` only for a
reviewed semantic exception. Both Scene path and Text ID are exact, and pair order is
irrelevant; this prevents an exception for one Viewport or transition stage from
silencing an unrelated collision between reused IDs. The pair may use the same ID
when its two exact Scene paths differ. Ordinary same-Scene opacity cross-fades do not
carry replacement provenance in this first contract, so either use a non-overlapping
handoff or declare the exact pair. Option operands beginning with `--` are reserved
for CLI flags.

Overlap and occlusion allowances are strict ledger entries. Their Scene paths must
match the inventory, both overlap endpoints must resolve to Text, and an allowance
must suppress sampled evidence. Duplicate, unmatched, and unused entries are contract
errors, so a stale exception cannot silently survive a composition change. Occlusion
allowances use exact stable paths such as `root` or `root/viewport:0`.

A global containment declaration is applied independently wherever its Text ID
occurs. The Rectangle must exist exactly once in that same Scene; an owner in a
different Viewport does not satisfy the declaration. Repeated Text IDs therefore
share one containment policy across the tree, while overlap allowances remain scoped
to their exact Scene-path occurrences. Give repeated Text distinct IDs when their
containment ownership differs by Scene. A containment policy reports `matched: true`
only when every Scene containing its Text ID resolves exactly one Text and one
Rectangle of the declared IDs; `textMatched` and `panelMatched` expose the endpoint
states separately. Diagnostics identify each occurrence by Scene path, ID, and
per-Scene handle.

## Result and exit status

The JSON report contains the resolved profile, encoded-frame and sample counts,
thresholds, subject and related Scene paths, aggregated issues, and a final `valid`
flag. Its `policy` receipt records the registered font path, thresholds, containment
relationships, uncontained IDs, exact overlap and occlusion allowances, Viewport
stretch decision, and each ledger entry's matched/used state. `scenePath` scopes the
subject and `relatedScenePath` scopes the second operand. The related path is null for
unary issues, and both are null for globally unmatched containment or uncontained
declarations. An unmatched overlap allowance instead retains both requested paths so
the stale endpoint is directly actionable. Handles are only unique within their Scene
path. Repeated failures of the same constraint are aggregated with their first, last,
and worst sample. Measured issues include the actual clearance, required clearance,
deficit, bounds, directional overflow, or suggested separation.
For sampled transition diagnostics, `visual` and `relatedVisual` identify the physical
paint kind plus any counterpart Scene path and authored Object.

With Diagram support, the top-level `diagramIR` array is a deterministic compile
receipt for every discovered diagram. Each entry includes its version, kind, layout
algorithm, complete authored configuration, semantic node/edge/zone records, computed
placements and generated Object bindings, plus the owning `scenePath`. References use
semantic string IDs; builder handle indices are never serialized as persistent
identity. This lets tools join an audit result back to `scenePath + diagram-id +
entity-kind + entity-id` without depending on allocation order.

Static Diagram issues carry `diagram-ir` provenance and null sample fields. Sampled
physical issues instead carry `sampled-rendered-geometry` provenance, semantic
subject/related IDs, measured root-pixel bounds, and first, last, and worst samples.
The physical codes are `diagram_sampled_route_node_collision`,
`diagram_sampled_route_label_collision`,
`diagram_sampled_route_route_collision`, and
`diagram_sampled_route_canvas_overflow`.

`summary.failingGeometrySamples` counts sampled geometry failures. Static inventory
errors have null sample fields, so a structurally invalid report can have zero failing
geometry samples.

- `0`: the audit passed;
- `1`: the layout contract failed; stdout is still a valid report;
- `2`: usage, Scene loading, or contract syntax failed;
- `3`: the CPU renderer or font could not be loaded;
- `4`: timeline calculation or its configured sample bound, Scene inventory,
  renderer layout, or audit allocation failed.

## Current boundary

This gate covers production-font Text, containment, canvas clipping, Viewport aspect,
Diagram IR's deterministic local constraints, and sampled Diagram route geometry.
The physical pass observes sampled 2D path vertices after object/ancestor transforms,
camera projection, and Viewport composition. Route clipping uses the complete visual
paint bounds, including stroke and arrowhead paths. Authored straight routes and
waypoints remain authoritative and are diagnosed rather than repaired.

The result is deterministic evidence at the requested delivery FPS, not continuous
collision detection or raster proof. A violation wholly between sampled times can be
missed. Text clearance uses shaped Text paint boxes rather than glyph contours.
Dashed routes are conservatively treated as continuous corridors. Endpoint node
bodies and their label/detail are excluded because a route must meet that owned node;
consequently, a route that later re-enters its own endpoint away from the intended
port is not distinguished. For two routes that share an endpoint, only a bounded
junction neighborhood derived from the sampled node body, stroke, and requested gap
is removed; crossings or shared corridors beyond it are still reported. Under a
nonuniform Viewport, stroke clearance uses the larger axis scale; the default audit
already rejects that stretch unless explicitly allowed. The current renderer's
round joins and butt/round caps fit the reported stroke envelope, while shape-level
partial occlusion, antialias coverage, custom paint effects, and three-dimensional
depth clearance still require inspection of original-size raster frames. A partially
clipped route keeps its full pre-clip path for conservative collision checks, so an
outside-clip contact can accompany the definitive canvas-overflow issue.
