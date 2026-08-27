# Scene contract

Apply this contract to every authored tmath scene. Profiles may narrow an explicit default; they never weaken source truth, derivation, identity, layout, or rendered review.

## Evidence and canonical state

Fix the audience, one question or claim, authoritative inputs, named variant, language and host, output dimensions or integration constraints, and the final state that must answer the question without playback. Prefer a stable composition when inspection matters more than time.

Before creating objects, record independent source values or deterministic trace events; derived quantities and dependencies; invariants and boundary cases; persistent identities; visible input, mechanism, and result; coordinate spaces, units, conventions, and camera role; text ownership and containment; layer bands and likely overlaps; and representative states/review times. Preserve supplied data, specification values, source behavior, and named special cases. Mark illustrative or unknown facts; illustrative values must be non-degenerate and stay in the claimed regime.

The source data or deterministic trace is authoritative. Derive every displayed coordinate, endpoint, index, shape, measurement, counter, label, result, and target state from it, formatting only at the display boundary. Two views of one state use the same record and update in the same semantic beat. A Group can share transforms, but does not prove that descendant geometry or values share meaning.

Before final choreography, perturb one independent input to an asymmetric valid value or replay a second trace. Every claimed dependent must update without editing another literal; unrelated presentation constants must remain unchanged. Canvas, camera, padding, stroke, layers, timing, sample density, and review filenames may remain authored constants only when they encode no subject fact.

## Objects, coordinates, and identity

Choose objects whose geometry supplies evidence. Prefer `Cell`, `Voxel`, `Surface`, `Vector`, `Image`, and direct geometry before explanatory Text or boxes; use the Scene background, negative space, alignment, scale, and restrained contrast instead of decorative cards, heavy shadows, or gratuitous rounding. A backing shape requires real containment, clipping, masking, selection, local contrast, or a distinct surface.

Scene `width` and `height` are output pixels, not world-coordinate bounds. Geometry uses direct-parent world coordinates in a right-handed, Y-up frame; two components imply `z=0`. A 2D orthographic camera shows vertical span `camera.height` and horizontal span `camera.height * width / height`, centered on `camera.target`; the defaults are target `{0,0,0}` and height `8`. To map a top-left pixel plan `(px,py)` into world space, use `x = target.x + (px - width/2) * camera.height/height` and `y = target.y + (height/2 - py) * camera.height/height`. Text size, stroke width, Point radius, and arrow/route caps remain screen pixels. Choose one coordinate convention explicitly and never pass raw screen coordinates as world positions.

Ancestor transforms carry descendants. A Group is a paintless semantic owner. Build a moving token as one Group positioned at its slot, author its mark and label in local coordinates around `{0,0}`, and animate that owner once; never shift a token's body and label independently. Use Space only when axes, units, grid, basis, or conversion teaches something. Use a child Scene and aspect-matched Viewport only for an independent camera, clock, or coordinate system; finish the child before mounting because successful attachment transfers and seals it.

Give unique stable IDs to objects queried, connected, source-mapped, matched across states, or discussed in review. Every visible Text needs one so production-font audits can identify failures. Store and reuse its handle; never call a factory again under the same ID. A moving value, vertex, tensor, node, or resource keeps identity when its position or representation changes. A slot, panel, or coordinate frame never silently becomes its content.

## Theme, text, and color

Choose Theme in the root Scene config before visible objects, including every child Scene: explicit user direction wins; otherwise a required VS Code host uses `theme="adaptive_vscode"`; otherwise honor the selected format; otherwise use restrained standalone `theme="pro_white"`. Lua has no author-side font-registration call: the host must register a font name before loading a Scene that selects it. JS/WASM uses `runtime.font(name, bytes, format)` before rendering. A host that bundles Source Serif 4 and IBM Plex Sans KR should assign Source Serif 4 to semantic roles and IBM Plex Sans KR to a complete inherited-font Text object containing Korean. Never select an unregistered font merely because it is named here. Explicit per-Text fonts remain authoritative; verify coverage for other scripts.

Assign Text the nearest `h1`, `h2`, `h3`, `text`, or `code` role; roles choose ordinary size, weight, and color without forcing capitalization. A Text `point` is its anchor and the default alignment is centered: set `align` explicitly, especially `align={0,0.5}` for a left-anchored title or label near a margin. Fixed logical-pixel sizes require an explicit constraint or measured delivery failure. Visually verify every meaning-bearing operator in the production raster—an audit can measure a Text object even when its font omits `∇`, `±`, `Θ`, or another glyph. Register a suitable font or use one consistent unambiguous spelling such as `grad f` or `Theta(n)`.

Color conveys identity, result, state, or salience. Accepted semantic Theme colors are `background`, `foreground`, `muted`, `accent`, `secondary`, `success`, `warning`, `danger`, `info`, `surface`, `border`, `result`, and `focus`; names such as `object1` or `object2` do not exist. Peer inputs may use an inferred object-cycle color by creating a StyleGroup without `color`, or use explicit literals. `result` is persistent derived identity and `focus` transient emphasis. Bind all relevant fill/stroke channels of one identity through one StyleGroup, including its mark, label, formula term, and copy proxy, and change them atomically. Split neutral explanation from its colorable identity chunk. Pair color with label, position, enclosure, route, pattern, or shape whenever color alone is insufficient.

## Layout and draw order

Build the complete settled layout before timeline calls. Measure production-font content and reserve regions for titles, evidence, labels, captions, legends, and controls. Size containers from rendered contents plus declared insets. Enlarge, recompose, or split overview/detail before shrinking instructional Text below delivery readability.

Before building the full timeline, render the settled skeleton and one representative state at delivery size. Reject an empty, mostly off-camera, mirrored, or wrong-scale frame immediately; do not let a successful inspect/layout command stand in for this camera smoke test.

Use explicit layer bands for background, structural regions, routes/guides, subjects, labels, annotations, and transient focus. Creation order is not a foreground contract and a Group layer does not cascade. Put intersecting 3D geometry in one band so the camera establishes depth. Sample the full motion envelope.

Authoring bounds are not live constraints: `Object::bounds()` omits some projected, stroked, descendant, and screen-facing glyph extents. Use sampled renderer layout reports and raster output for final containment, gaps, clipping, and overlap. Feed corrections into authored source; do not invent render-time layout updaters.

## Motion, continuity, and replacement

Give each beat one evidence claim and dominant verb, with at most one coupled supporting change. Animate the semantic object or state: construct geometry, move a value, transform its owner, replace a route, advance a trace, change a sample, or update a derived result. Generic travelling dots, sweeps, pulses, and camera movement are not evidence.

Keep useful prior structure as quieter context. Reveal geometry before notation when notation formalizes it, and hold completed constructions, readable equations, decisive comparisons, and conclusions. Use linear motion for meaningful uniform rate, restrained ease-out for construction, and ease-in-out for reversible change. Select a mode with a testable endpoint: stable still, one-shot construction, causal trace, state transition, comparison, or a true loop. Reduce or split dense material before accelerating it; review at normal delivery speed.

Default to `loop=false`. Loop only when recurrence is requested or mechanistic and every object, camera, label, accumulated state, and salience channel returns to a continuous boundary. Compare decoded pixels at `t=0` and the exact loop boundary, not container hashes; any unexplained mismatch fails the seam. A format profile may explicitly override the default.

Morph only compatible sampled geometry when interpolation communicates continuity. Morph and replacement transforms consume the source handle; continue with the target and update the identity ledger. Preserve an original only by reconstructing an explicit opaque proxy from the same source data—there is no generic Object `copy()`, `clone()`, or deep-copy API. Text glyphs are not contour-morph geometry. Use Fade Transform for unrelated families representing one replacement identity; a same-color geometry proxy may travel to a compact seed before becoming Text, but must retain canonical value and color.

Timeline calls are deterministic at explicit sample times. Do not invent `add_updater`, `always_redraw`, or arbitrary render-time callbacks. The documented `time` argument drives temporal Cell or Voxel fields; sampled fields are retained data, not Morph targets.

## Verify and deliver

Recompute or replay the source model, check relevant invariants and boundaries, and confirm the final state against authoritative data. Inspect first, then choose valid review times from `0` through the reported duration. Render and run layout at the initial state, decisive beats, maximum density, and exact final time; for Lua use `tmath layout scene.lua --time "$TMATH_TIME" --padding 4 --font "$TMATH_FONT"`. Audit every visible Text object with the production font at every encoded frame, including exact final time, using `audit_text_layout.py scene.lua --cli tmath --font "$TMATH_FONT" --canvas-inset 4`; for JS/TS use the runtime review loop in its API reference. For composed Scenes, use the whole-Scene report for root-pixel collision, clipping, stretch, and parent/descendant containment across Viewports; do not globally exclude ancestor pairs. Null bounds, unsupported glyphs, one-glyph overflow, and transient clipping are failures even when commands succeed.

Inspect original-size rasters for the initial state, each decisive transition, maximum density/concurrency, worst text clearance, final hold, and both sides of a loop seam. For every reviewed frame, identify its focal evidence, tightest unintended clearance, and meaning-bearing glyphs; fix and rerender rather than merely recording a successful command. Review the full animation once at normal speed in the intended host. API success, rendering, or a layout report alone is not visual proof.

Store disposable review material—including probe source—under `temp/` in the scene source directory; keep only the durable scene source and requested outputs outside it and never create a repository-root `artifacts/`. Deliver only after source truth, production-font layout, draw order, motion comprehension, final readability, and requested export behavior pass. State unavailable checks or host capabilities plainly.
