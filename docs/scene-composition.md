# Scene composition and lifecycle

tmath scenes are retained object trees sampled at an explicit time. A coordinate grid is optional: a Scene can own a `Circle`, `Rectangle`, `Text`, or semantic `Group` directly, so an array, memory buffer, tree, or sorting trace does not need a `Space`.

This document is the contract for composition, ownership, authoring, animation, and sampling. [architecture.md](architecture.md) describes the renderer pipeline, while the [Lua API reference](../skills/tmath-skills/references/lua.md) lists concrete authoring calls.

## Composition

`Scene` owns root Objects and optional child Scenes mounted as Viewports. Every Object can own child Objects. `Group` and `Space` give that general tree two specialized meanings:

- `Group` is a paintless semantic container. Use it for a tree node with its label and links, one array cell with its value, or any collection that should move and fade together.
- `Space` is a visible coordinate-system Object with ranges, axes, optional grid numbers, and coordinate conversion.
- `Space::cell`/`voxel` and their Lua/JavaScript forms may sample those ranges over a bounded authoring-time time lattice and attach a Group of batched planar/spatial Cells. The callback is not retained.
- Other Objects paint their own geometry and may still own children. This makes a shape plus its annotation a single semantic subtree without requiring a wrapper Group.

Lua and JavaScript expose the same factories on Scene and every Object handle: `group`, `space`, `point`, `line`, `arrow`, `vector`, `circle`, `rectangle`, `polygon`, `plot`, `route`, `path`, `curve`, `surface`, `text`, `ruler`, `svg`, `image`, `cell`, and `connector`. The receiver becomes the direct parent. Scene creates roots; an Object factory creates a child. C++ constructs a concrete type with its `gen()` function, then transfers it through `Scene::add()` or `Object::add()`.

```text
Scene
├── Group "buffer"
│   ├── Rectangle "cell-0"
│   │   └── Text "value-0"
│   └── Rectangle "cell-1"
│       └── Text "value-1"
├── Group "tree"
│   ├── Circle "node-8"
│   ├── Circle "node-3"
│   └── Connector "edge-8-3"
└── Space "plot"
    └── Plot "complexity"
```

Every Object has one affine row-major local-to-parent model. Rendering composes all ancestor models in tree order:

```text
worldPoint = root.model × ... × parent.model × object.model × localPoint
```

In C++, `Object::parent()` returns the direct parent Object, or null for a Scene root. `Object::space()` walks the same parent chain and returns the nearest `Space`, or null when the object is not inside one. Coordinate conversion never requires every intermediate parent to be a Space. Lua and JavaScript handles keep this relationship protected rather than exposing mutable parent access.

`childCount()` and `childAt(index)` enumerate direct children in insertion order, which Group layout preserves. Rendering uses stable Scene attachment order after layer/depth comparison; Scene identity lookup remains independent from tree traversal.

All ancestor born/dead visibility gates apply to a subtree. A `Group` additionally multiplies its sampled opacity and creation progress into every descendant. A Space and ordinary painted Objects apply opacity and progress only to their own paint; their model and born/dead state still affect descendants. Group stroke, fill, and layer do not restyle children.

## Draw order and layer

Every painted Object has an integer `layer`. Lower layers are painted first and higher layers are painted later, so a higher layer appears in front when pixels overlap. Within one layer, projected camera depth is compared next: farther commands paint before nearer commands. Stable Scene attachment order is only the final tie-breaker. Do not use construction order as a semantic foreground contract.

Most Objects default to layer `0`. Space grid paint defaults to `-10`; its axes use the next layer and its generated numbers the layer after that. Connector defaults to `-1`, which keeps ordinary edges behind default-layer nodes. A Group's layer is not inherited by its children. Set the layer on each painted child, or apply the same layer while constructing the children.

For a 2D mathematical overlay where overlaps are possible, choose explicit bands. One useful convention is background/scaffolding `-20..-10`, ordinary objects `0`, Points used as dots `10`, Vectors `20`, directional Arrows `30`, and annotation Text `40`. This is an authoring convention, not a type-specific engine default. A Point used as an endpoint cap, a foreground mask, or a selection handle may intentionally need a higher layer. Text should be placed away from arrows when possible; raise a label above its own panel or mask, but do not rely on layering to repair an unreadable collision.

Layer is evaluated before 3D depth. Giving a distant 3D Arrow a higher layer deliberately turns it into an overlay and can make occlusion physically false. Keep one layer when true 3D occlusion matters, and reserve layer bands for 2D annotations or intentionally screen-facing overlays. Viewports have isolated display lists: their object layers do not cross Viewport boundaries, and sibling Viewports composite in their attachment order.

## Ownership and identity

The object tree has unique ownership. It is a tree, not a shared graph.

| Operation | Ownership result |
|---|---|
| Construct a C++ Object | Caller owns a detached, mutable object |
| Successful `Object::add()` | Parent owns the child subtree |
| Successful `Scene::add()` | Scene owns the root subtree |
| Failed add | Caller keeps ownership; the destination is unchanged |
| Lua/JavaScript factory | Receiver immediately owns the returned handle's object |
| Successful `Scene::viewport()` | Parent Scene owns and seals the child Scene |
| Successful `Scene::transition()` | Parent Scene owns and seals every stage Scene |

One Object cannot be shared by two parents, added twice, reparented, added to itself, or added below one of its descendants. Validation covers the complete incoming subtree before ownership changes, so a duplicate ID, invalid definition, cycle, depth overflow, or resource overflow cannot partially attach it.

Attachment registers every member in the owning Scene, assigns stable numeric identity, validates stable string IDs, snapshots its base visual state, and records `born` at the current timeline cursor. Destruction follows the owning tree exactly once. Scene lookup uses the flat registry for identity and timeline work; the parent tree remains the ownership source of truth.

## Theme resolution

Each Scene owns one [Theme](themes.md) and one independent cyclic object-color cursor. Assign the Theme before adding Objects, mounting Viewports, or scheduling animation. Attachment resolves only omitted style fields, then snapshots the resolved result as the Object's deterministic base state.

Explicit object colors win and do not consume a palette entry. Eligible uncolored shapes consume colors in depth-first attachment order and wrap at the configured palette count; their omitted stroke width resolves from `object_width`. When Theme gradients are enabled, the resolved object color becomes the start stop and `end_gradient_stop` becomes the end stop; an explicit per-shape gradient setting wins. Text resolves omitted font, size, and color from its H1/H2/H3/Text/Code role without consuming that cycle. Space resolves default axes, grid, and labels from the Theme. Paintless Groups and asset/cell objects do not consume colors or receive gradient paint.

The authored-versus-themed distinction is retained for animation composition: an automatically themed morph or equal-ID Scene-transition target inherits its source color and gradient, while an explicitly styled target remains explicit. Child Scenes in Viewports do not inherit the parent Theme implicitly; this preserves their isolation and makes multiple visual systems safe in one output.

## Authoring, update, and sealing

Configure a detached C++ subtree before attaching it whenever possible. Attachment freezes the captured geometry, style, and local model for deterministic past-time sampling. C++ fields remain public for compact authoring, so an attached definition changed at timeline time zero must be acknowledged explicitly with `Scene::update(object)`. `update` revalidates and refreshes that object's base snapshot; it is an authoring operation, not a frame callback.

`Scene::update` and bounds-based layout are available only while the cursor is zero and before the first `play`, `look`, `wait`, or `remove`. The first scheduling command seals definitions already attached to the Scene. A later direct field change is a contract violation detected by fingerprint validation; it is never silently incorporated into a render.

`Text::text(value)` is the private-payload counterpart to `Scene::update`: for an
attached Text it refreshes the owning Scene automatically during that same unsealed
authoring window. A rejected refresh restores the previous string, so a host never
observes a half-committed label update.

New, fully authored Objects may still be attached after scheduling. Such a subtree is born at the current cursor and is immediately frozen; a dead parent cannot accept a late child. Because the layout/update phase has already closed, configure that late subtree before C++ attachment or supply complete constructor coordinates/matrices to a Lua or JavaScript factory.

`cell` and `voxel` sampling are authoring operations under the same rule. They synchronously materialize a complete Group from the Space's current ranges and attach that Group at the current cursor. The default zero duration stores one frame at `time=0`. A positive `duration` and `fps` store a bounded sequence including both endpoints and advance the Scene cursor by that duration; rendering interpolates retained colors and never invokes the callback. If a detached subtree contains several temporal fields, attaching it consumes their maximum duration so those fields share a start. The exact sampling order, limits, and C++/Lua/JavaScript signatures are documented in [cell-voxel.md](cell-voxel.md).

Lua and JavaScript expose protected handles rather than mutable object fields. Their layout calls perform the corresponding authoring refresh while the timeline is still at its start. Mounting a Scene in a Viewport is a stronger seal: every subsequent authoring call through that child Scene or any handle created by it is rejected. Native C++ retains explicit access to a mounted child through `sceneAt()` for host-controlled camera input.

## Bounds and authoring layout

`Object::bounds(Bounds&)` returns the axis-aligned family geometry bound expressed in the Object's direct-parent coordinate system. It includes the Object's own model and every descendant model, but not ancestors above the receiver. Its extents come from world-unit geometry rather than pixels. It deliberately excludes:

- stroke width;
- arrow and vector tail/tip caps;
- Point marker radius;
- screen-facing Text glyph extents.

Text contributes its world anchor, not a font-dependent glyph box. These rules keep layout independent from resolution, font rasterization, antialiasing, camera projection, and render backend.

For final layout validation, `SwRenderer::bounds(scene, object, time, output)` lowers the selected Object and its descendants through the normal display-list and ThorVG paint path. The returned `BBox` is an axis-aligned top-left pixel rectangle after animation sampling, ancestor transforms, camera projection, glyph shaping, and painted stroke expansion. Fully transparent commands do not contribute. `SwRenderer::intersects(...)` compares two such boxes; a positive `padding` specifies the minimum clear pixel gap. Merely touching edges is not an intersection at zero padding.

The C/WASM surface exposes the same operation for root-Scene Object IDs through `tmath_bounds`, `tmath_intersects`, `scene.bounds`, and `scene.intersects`. For complete composition review, `SwRenderer::layout`, `scene.layoutReport`, and `tmath_layout_report*` flatten nested Viewports into root output pixels. Each object entry separates its own painted commands (`paintBounds`) from its descendant-inclusive family (`familyBounds`). Independent objects produce overlap/minimum-gap candidates; ancestor-descendant pairs produce containment results by comparing the ancestor's own paint with the descendant family, so a child cannot enlarge its container and hide overflow.

The CLI can audit a complete file without producing an image:

```sh
build/tmath layout examples/lua/vector_operations.lua --time 2.0 --padding 4 \
  --font examples/assets/Pretendard.ttf
```

The JSON keeps the legacy local records under `.scene` and places the flattened composition under `.report`, including Scene paths, root-pixel own/family bounds, ancestor clips, stretch flags, independent-object collisions, and parent/descendant containment. Use authoring `Bounds` to place objects before sealing; use the sampled whole-Scene report at every encoded frame for final geometry validation, then inspect the worst raster frames for actual occlusion and glyph quality.

`moveTo`, `nextTo`, and `alignTo` update an Object model from these bounds. Points and directions are in the direct parent's coordinates, and `nextTo`/`alignTo` require both Objects to have the same direct parent. `Group::arrange` lays children out in Group coordinates along one direction, and `Group::arrangeGrid` uses columns and row/column gaps. Lua uses `move_to`, `next_to`, `align_to`, `arrange`, and `arrange_grid`; JavaScript uses the camel-case forms.

An attached C++ Object layout call refreshes its authoring snapshot through the owning Scene automatically. `Scene::update(object)` is still required after direct public-field edits that bypass these layout methods.

Layout is a timeline-start authoring calculation, not a retained constraint. It runs once, updates authored models, and does not run again when an ancestor or target later animates. To animate a layout change, compute the desired target matrices before sealing and schedule those matrices explicitly.

## Connectors are deterministic derived geometry

`Connector` references two Objects in the same Scene. At every requested sample time, the engine first samples the endpoints and their complete ancestor chains, computes each endpoint family's scene-world geometry bounds, and then resolves the connector endpoints from those sampled bounds. Optional padding moves the endpoints away from the bound; tail and tip remain pixel-sized caps.

The connector is resolved after Object animation sampling and before camera projection and display-list lowering. It therefore follows animated nodes at an arbitrary render time without mutating either endpoint, remembering a previous frame, or running user code. Endpoint ownership remains unchanged, and a hidden or dead ancestor makes its endpoint family unavailable for that sample.

A Connector has no independent geometry transform: its local model must remain identity, and `shift`/`transform` clips targeting the Connector are rejected. Move its endpoints instead. A spatial transform on a Connector ancestor is accepted only when that ancestor also owns at least one endpoint, so a graph root or node-owned outgoing edge follows the transformed nodes. An edge-only Group model would be ignored by derived geometry and is therefore rejected at attachment, authoring update, or animation scheduling. Connector opacity, creation progress, stroke, and fill remain animatable, and Group opacity/progress still gate an edge-only Connector subtree.

This derived-geometry phase is the supported replacement for a common “line follows two nodes” updater. It is deliberately narrow: tmath does not expose arbitrary Lua, JavaScript, or C++ per-frame callback updaters. Sampled `cell` and `voxel` fields do not relax this rule because they precompute bounded coordinate/time samples while authoring and retain only Cell data.

## Animation lifecycle

Scene playback is one-shot unless its root configuration sets `loop=true`. `loop=false` is the default. This flag tells a host player whether to stop on the final frame or wrap to zero; `Scene::duration()` and renderer sampling remain deterministic and do not modulo the requested time. A Viewport tree shares one global time, so only the root policy controls playback and child loop settings do not create independent clocks.

Lua and JavaScript provide a compact animation vocabulary above the same retained timeline:

- `create` and `uncreate` reveal or erase geometry in authored path order. Their optional direction is `forward`, `reverse`, `clockwise`, or `counterclockwise`; the clockwise names select the expected screen direction for a closed path and alias reverse/forward for an open path.
- `fill_reveal`/`fillReveal` interpolates only the authored fill alpha while preserving the completed stroke. Schedule it after `create` to keep a closed Path unfilled until the outline is complete. `draw_border_then_fill`/`drawBorderThenFill` is the one-clip form: the first two thirds draw the boundary and the final third reveals the fill. Both accept arrays and lag; the combined form also accepts draw direction.
- `write` traces the stroke and simultaneously closes only the traversed prefix for fill. Its synthetic closing edge is fill-only, so no chord flashes across the contour. A fill-only path receives a temporary same-color stroke while writing. It accepts the same array, lag, curve, and direction arguments as `create`.
- `fade_in`/`fadeIn` and `fade_out`/`fadeOut` combine opacity with an optional hidden-state parent-space `shift` and positive center-relative `scale`: FadeIn starts at that offset and FadeOut ends there. A Group carries the complete fade to its text and shape descendants.
- `grow_from_center`/`growFromCenter` and `shrink_to_center`/`shrinkToCenter` scale a family around its geometry-bounds center while introducing or removing it. `grow_from_edge`/`growFromEdge` instead keeps the selected geometry-bounds edge fixed and grows only the perpendicular dimension, which is appropriate for bars rising from a quantitative baseline.
- `indicate` temporarily applies a color and a scale greater than one, then restores the exact incoming visual state at the end of the clip.
- `morph` and `replacement_transform`/`replacementTransform` use replacement semantics. A call accepts one source/target pair or equally sized arrays of pairs, with optional lag for a staggered batch. Geometry pairs must be distinct, childless, same-parent `Polygon`, `Plot`, `Path`, or `Curve` objects with equal sampled point counts; Path topology must also agree. Sampled Cell/Voxel Groups are not Morph geometry—put the change in their callback's `time` argument. Handles must be distinct across a batch. Attach all targets at the current cursor immediately before scheduling the morph; they must have no earlier clips. At the end each source is dead and its target handle remains active for subsequent animation.
- `fade_transform`/`fadeTransform`/`Scene::fadeTransform` replaces one live Object with a newly attached target of any family through a simultaneous cross-fade. The target must be distinct, belong to the same Scene, be outside the source's ancestor/descendant chain, be born at the current cursor, and have no earlier clips. Scheduling hides the target before the boundary, fades both objects in one timeline slot, marks the source dead at the end, and leaves the target live. Use object `transition` for a non-consuming group cross-fade.
- `style_group`/`styleGroup`/`Scene::styleGroup` binds one semantic color to explicit live Object `stroke`, `fill`, or `both` channels before those members' first clips. Omit the group color to infer it from the first member's selected channel; `both` inference succeeds only when stroke and fill match. This lets an automatically cycled operand establish the identity for its label and proxies. Supply `result` or `focus` explicitly for those fixed semantic roles. One `style` call emits simultaneous color clips for every live member. A channel belongs to at most one StyleGroup; Morph and Fade Transform transfer consumed membership to the live target, and remove detaches it.

Every animation helper and fixed-camera `look` accepts an `AnimCurve`. The original string values remain source-compatible, and five expressive presets extend them:

```lua
scene:shift(card, {4, 0}, 0.8, "snappy")
scene:shift(card, {4, 0}, 0.8, {preset="back", strength=1.35})
scene:shift(card, {4, 0}, 0.8, {
    bezier={0.18, 0.90, 0.28, 1.00}, strength=0.8
})
scene:shift(card, {-4, 0}, 0.8, {preset="back", strength=1.35, reverse=true})
```

Preset names are `linear`, `smooth`, `ease_in`, `ease_out`, `ease_in_out`, `gentle`, `snappy`, `back`, `bounce`, and `elastic`. `strength` is in `[0,2]`: zero blends the result back to linear time, one preserves the preset or cubic curve, and two doubles its timing deviation. A custom cubic Bézier uses CSS-style `(x1,y1,x2,y2)` controls; x controls must be in `[0,1]`, y controls in `[-2,2]`. The runtime solves curve x for each normalized time instead of treating the Bézier parameter as time. Set Lua `reverse=true`, call JavaScript `tmath.animCurve.reverse(curve)`, or use C++ `curve.reversed()` to sample `1 - curve(1 - t)`. Applying reverse twice restores the original timing.

Back and elastic curves may leave `[0,1]`. Model transforms retain that overshoot, which provides anticipation and spring motion. Colors, opacity, draw progress, morph progress, and camera interpolation are clamped to their valid domains. All curves return the exact authored start and end states at clip boundaries, so sequential clips and arbitrary-time sampling stay deterministic. In C++, use `AnimCurve::preset(AnimCurvePreset::Back, 1.35f)` or `AnimCurve::cubicBezier({0.18f, 0.90f}, {0.28f, 1.0f})`; legacy `Easing` overloads remain available.

For a closed filled Path, choose either an explicit two-beat sequence or the combined animation:

```lua
scene:create(path, 0.8, "linear")
scene:fill_reveal(path, 0.35, "ease_out")

-- Equivalent visual order in one clip.
scene:draw_border_then_fill(other_path, 1.15, "ease_in_out", 0, "clockwise")
```

The C++ factories are `Animation::fillReveal()` and `Animation::drawBorderThenFill()`. The existing `fill` animation remains a color interpolation; it does not control fill visibility.
`Animation::write()` is the traced-fill counterpart.

The replacement contract makes a chain explicit rather than mutating a stale source handle:

```lua
scene:wait(0.3)
local square = scene:polygon {points = square_points, id = "square"}
scene:morph(circle_polygon, square, 1.0, "ease_in_out")

scene:wait(0.2)
local star = scene:polygon {points = star_points, id = "star"}
scene:replacement_transform(square, star, 0.8, "ease_in_out")
scene:indicate(star, {color = "#ffd166", scale = 1.15, duration = 0.7})
```

For Manim-style “transform from copy” staging, keep the authored source alive and attach a same-parent duplicate at the current cursor. Use only that duplicate as the replacement-transform source. The duplicate is consumed by the morph while the original remains available and visible:

```lua
local vector_copy = space:polygon {points = vector_points, fill = vector_color}
local formula_chip = space:polygon {points = chip_points, fill = vector_color}
scene:replacement_transform(vector_copy, formula_chip, 0.8, "ease_in_out")
```

Text is not contour-morphed. Bridge geometry to text with a solid, same-point-count copy instead:

```lua
-- Keep the original vector. Only this opaque duplicate is consumed.
local vector_copy = space:polygon {
    points = vector_points, fill = vector_color, stroke = vector_color
}
local bullet = space:polygon {
    points = bullet_points, fill = vector_color, stroke = vector_color
}
scene:replacement_transform(vector_copy, bullet, 0.7, "ease_in_out")
scene:fade_transform(bullet, label, 0.22, "gentle")
```

For a typing treatment, morph the copy into an opaque narrow polygon, then animate each text chunk's opacity and the cursor's shift in the same `play` call. See `examples/lua/text_reveal_transitions.lua` for both the bullet and cursor recipes.

The single-property animation helpers remain useful. Composite target-state animation adds one atomic way to change several visual properties together. C++ uses `AnimationTarget`; Lua and JavaScript use a `play` descriptor:

```lua
scene:play({
    {target = left, shift = {-1, 0}, fill = "#4cc9f0", opacity = 0.8},
    {target = right, transform = target_matrix, stroke = "#f72585"},
}, 0.8, "ease_in_out", 0.15)
```

Each descriptor has exactly one target and may contain:

- either relative parent-space `shift` or an absolute affine local-to-parent `transform`, never both and never for a Connector; a transformed ancestor containing Connectors must also contain at least one endpoint of each such Connector;
- optional `opacity`;
- optional `stroke` and `fill` colors.

All targets in one call must be distinct and owned by that Scene. Scheduling validates every target, matrix, value, duration, animation curve, lag, duplicate, resource limit, and target lifetime before committing anything. Failure leaves the cursor, target states, fingerprints, and clip storage unchanged.

### Scene-to-Scene transitions

A Scene transition composes two or more independently authored Scenes into one ordered sequence. Each stage is sampled at its own final frame, held for `hold`, and then transformed into the next stage over `duration`. The destination rectangle is normalized like a Viewport and defaults to the full parent.

```lua
local root = tmath.scene {width=960, height=540}
local diagram = tmath.scene {width=960, height=540}
local formula = tmath.scene {width=640, height=360}

diagram:circle {center={-2,0}, radius=0.8, id="subject"}
formula:rectangle {center={2,0}, size={2,1}, id="subject"}

root:scene_transition({diagram, formula}, {
    duration=1.0, hold=0.5, curve="smooth",
    viewport={x=0.1, y=0.1, width=0.8, height=0.8}
})
```

JavaScript uses `root.sceneTransition([diagram, formula], options)`. Native C++ supplies an array to `Scene::transition(stages, count, viewport, duration, hold, curve)` and can inspect the transferred stages with `transitionCount()` and `transitionAt(index)`. A successful call atomically transfers and seals all stages. A stage cannot be reused, edited, mounted elsewhere, or returned as the owning root afterward. One parent owns at most one transition sequence, and the same stage cannot occur twice.

The timeline span for `N` stages is:

```text
span = hold × N + duration × (N - 1)
```

Matching uses each Object's non-empty string `id`, independently for every adjacent stage pair. Compatible rendered contours with the same ID morph in screen space after each stage's camera and resolution have been applied. Closed and open paths remain separate; path outlines are arc-length resampled and closed contours are cyclically aligned to reduce twisting. Identical text and font content can move, resize, and restyle. Equal-ID text with different content or fonts uses a sequential dissolve so two layouts never collide. Images, incompatible command structures, unmatched objects, nested Viewports, and nested Scene sequences cross-fade instead. Stage backgrounds interpolate.

This is deliberately distinct from object-level `morph`: Scene transitions preserve the independent object namespaces and do not require matching C++ types or equal authored point counts. IDs describe semantic continuity across scenes; a Circle, Rectangle, and Polygon with `id="subject"` can therefore become one continuous rendered contour. Omitting an ID explicitly opts that object into cross-fade behavior.

One descriptor becomes one compact `VisualState` clip, so its model, opacity, stroke, and fill interpolate over the same normalized progress. For descriptor index `i`:

```text
begin(i) = cursor + duration × lag × i
end(i)   = begin(i) + duration
span     = duration × (1 + lag × (count - 1))
```

Every scheduled timestamp must remain representable as a strictly increasing finite `float` at the current cursor. If the requested duration or lag would collapse a clip boundary, `play`, `look`, and positive `wait` reject the command atomically with `InvalidArguments`.

After an atomic commit, the target keeps the authored end state used by the next sequential play. The immutable base snapshot and clips still reconstruct an earlier time exactly; scheduling a later transform, fade, or style animation cannot rewrite a past frame. A target's first `Create`, `FadeIn`, or `GrowFromCenter` is its deliberate reveal boundary: definitions and earlier transform/style clips remain sampled, but path progress or opacity keeps the family hidden until that reveal begins. Once the object has been visibly consumed by an exit or emphasis effect, a later re-entry is local to its new clip and never retroactively hides the earlier visible interval.

Fixed-camera `look` clips interpolate the target and viewing distance linearly while rotating a scaled-double orthonormal camera basis along the shortest quaternion arc. This keeps `eye != target` and a nonparallel up direction throughout accepted 2D/3D transitions, including opposite views and 180-degree rolls. A static Camera may use any valid finite-float pose; `look` additionally checks that the target-plus-orbit envelope fits float coordinates, that the orbit radius remains large enough for the envelope's float spacing, and that independent near/far rounding cannot collapse their positive gap. An unchanged pose bypasses orbit reconstruction, so lens-only animation remains available even at extreme coordinate scales. Unsafe paths are rejected before allocating a clip or advancing the cursor. On the first camera clip, native C++ captures the current valid `Scene::config().camera` and `cameraView` as the historical initial state, including authoring edits made before that clip.

## Scene lifecycle

The normal fixed-scene lifecycle is:

```text
author detached definitions
        |
        v
attach and transfer ownership
        |
        v
update base snapshots at cursor 0, then seal definitions
        |
        v
schedule play / look / wait / remove
        |
        v
sample(t): base state + immutable clips + born/dead gates
        |
        v
resolve ancestor state, family bounds, and Connectors
        |
        v
camera project / clip / lower / layer-depth-order sort
        |
        v
compose isolated Viewports
        |
        v
sample and blend a Scene transition sequence
        |
        v
render and synchronize SW/GL output
        |
        v
destroy through the ownership tree
```

Sampling never advances the cursor or accumulates a frame result. Rendering `end`, then `start`, then `middle`, then `start` again must reproduce the same two start frames. A fixed Scene is therefore a function of its validated definitions, immutable timeline, registered assets, configuration, and requested time. An optional UI Panel adds one explicit input-event state after authored sampling; it does not change Object timeline semantics.

Every Scene in a Viewport tree samples the same global time but keeps its own object namespace, camera, timeline, background, display list, and layer/depth ordering. The parent duration is the maximum local or descendant duration. Each child is projected at its own configured size before its output is transformed and clipped into the parent rectangle.

## Relationship to Manim Community

tmath borrows familiar authoring ideas from Manim Community: a [Mobject](https://docs.manim.community/en/stable/reference/manim.mobject.mobject.Mobject.html) can have submobjects, [Group](https://docs.manim.community/en/stable/reference/manim.mobject.mobject.Group.html) and [VGroup](https://docs.manim.community/en/stable/reference/manim.mobject.types.vectorized_mobject.VGroup.html) provide composition, and Mobject supplies bounds-based `move_to`, `next_to`, `align_to`, and `arrange` operations.

The runtime contract is intentionally different. Manim Mobjects are mutable and can run `add_updater` functions, including functions that receive frame `dt`; [`always_redraw`](https://docs.manim.community/en/stable/reference/manim.animation.updaters.mobject_update_utils.html) regenerates a Mobject every frame. tmath freezes attached definitions, stores compact clips, and samples an arbitrary time without executing author callbacks or deep-copying the complete object tree. Use target-state clips for algorithm trace steps and Connector for sampled endpoint relationships.
