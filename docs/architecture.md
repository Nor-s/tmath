# Architecture

tmath is a semantic math-animation engine. Scene objects never inherit ThorVG paints. Each Scene is sampled at a time, projected by its own camera, and lowered to a backend-neutral display list. Viewport groups are then clipped and composed before translation to ThorVG.

```text
C++ / resource-limited Lua / typed JavaScript
       + optional Diagram / Chart lowering
                    |
                    v
 Scene/Viewport tree + independent timelines/Object trees
                    |
                    v
  parent Mat4 composition -> Camera -> clipping
                    |
                    v
       depth/layer-sorted 2D display list
                    |
          +---------+---------+
          |                   |
   ThorVG SwCanvas      ThorVG GlCanvas
```

## Scene and Object composition

The public hierarchy is `Scene -> Object -> Object`. A Scene can own any root Object, and every Object can own children. `Group` is the paintless semantic container; `Space` is the coordinate-system Object with ranges, axes, and optional numbers. The remaining types are geometry (`Point`, `Line`, `Arrow`, `Vector`, `Circle`, `Rectangle`, `Polygon`, `Plot`, `Path`, `Curve`, `SurfaceMesh`, `Connector`), annotations (`Text`, `Ruler`), and assets/cells (`Svg`, `Image`, `Cell`). Lua and JavaScript expose the complete factory set on Scene and every Object handle, so neither a Group nor a Space is mandatory.

Every Object owns one row-major affine local-to-parent `Mat4`; every spatial value is a `Vec3`. Lua and JavaScript accept two components as a concise form and lift them to `z=0`, but they do not create a different object type. Rendering composes every ancestor rather than only Spaces:

```text
world = root.model × ... × parent.model × object.model × localPoint
```

Native `Object::parent()` reports the direct Object parent; `Object::space()` reports the nearest Space, which may be null. All ancestor models and born/dead gates affect descendants. Group opacity and creation progress multiply through its subtree; opacity/progress on a Space or painted Object affect only that Object's own paint. A Group emits no paint of its own.

Space X/Y/Z ranges define coordinate samples and its matrix controls cell size, basis orientation, shear, and origin. Transforming one Space therefore changes its axes and every descendant without repeating the matrix on each object. `c2w()` and checked `w2c()` include all Object ancestors. The planar camera view emits the XY plane and axes; the spatial view emits XY, XZ, and YZ from the same Space.

`Space::cell` and `Space::voxel` are bounded authoring-time compilers from coordinate/time/color callbacks to retained field data. The planar form builds one batched Cell at Z=0; the spatial form builds one Cell per Z slice. A zero duration stores one static frame. A positive duration samples a bounded time lattice, advances the Scene cursor, and display-list lowering interpolates adjacent retained RGBA frames at arbitrary render times. Lua executes callbacks through the same native construction transaction; the JavaScript builder evaluates callbacks synchronously and serializes each color snapshot into that Lua/native path. The callback is never retained. See [cell-voxel.md](cell-voxel.md).

Optional Space numbers lower to screen-facing text commands after the current animated matrix is sampled. `Fixed` labels show the local coordinate. `Relative` labels multiply it by the corresponding composed basis-column length, so a 0.1 scale displays `1,2,3` as `0.1,0.2,0.3`. Labels have a 256-command budget per Space and require a registered font.

Space paint is independent from containment. Setting a Space's `opacity=0` or `progress=0` hides its coordinate lines without hiding descendants, so an invisible Space can act as an FK/IK transform node. See [scene-composition.md](scene-composition.md) for ownership, bounds, layout, Connector, and sealing contracts.

The world is right-handed. Pixel space is +X right and +Y down; only the final viewport conversion flips Y. The camera derives:

```text
forward = normalize(target - eye)
right   = normalize(cross(forward, up))
up'     = cross(right, forward)
```

Perspective projection is a pinhole camera with a vertical field of view. Orthographic projection uses a vertical world height. Geometry is clipped against near and far camera depth before projection. ThorVG therefore remains a compact 2D raster/vector backend; it does not become the 3D engine.

Object models are affine-only, so paths cannot cross a model-space homogeneous singularity. Standalone `Mat3`/`Mat4` math still performs projective point division and uses double intermediates where float accumulation would overflow before cancellation.

## Camera modes and input

`CameraMode::Fixed` makes the scripted camera authoritative for ordinary host input.
External `Scene::camera(CameraInput)` calls return `InsufficientCondition` even when an
optional sidecar is registered. `CameraMode::Interactive` allows the host to forward a
camera command to the first registered runtime layer that accepts it.

A fixed scene may schedule `Scene::look()` keyframes. Target and viewing distance interpolate linearly while a scaled-double orthonormal basis follows the shortest quaternion arc; scheduling conservatively verifies eye range, sufficient orbit precision at that coordinate scale, and a positive near/far gap after float rounding. An unchanged pose is copied exactly for lens-only animation. The first clip captures the then-current valid native Camera/View authoring state, so adding it after `wait()` does not rewrite earlier samples. Camera lens values and planar/spatial view share the same timeline while the object tree remains unchanged. Leaving 2D activates the spatial projection as movement starts; returning to 2D keeps the spatial projection until the front-facing camera arrives, avoiding an invalid oblique 2D camera.

The optional `tmath-input` Controller owns the primary implementation of the
backend-independent camera command vocabulary:

| Action | Normalized input | Meaning |
|---|---|---|
| `Pan` | `delta.x`, `delta.y` as viewport fractions | Move eye and target in the camera plane |
| `Orbit` | viewport fractions | Rotate the spatial eye around the target; unavailable in planar view |
| `Zoom` | `delta.y` | Exponential zoom, `scale = exp(delta.y)` |
| `Reset` | none | Clear runtime deltas and reveal the authored camera at the sampled time |
| `View2D` | none | Front-facing orthographic planar view |
| `View3D` | none | Perspective spatial view |

Web pointer movement is divided by the displayed canvas width/height before camera
dispatch. A native GLFW/SDL host performs the same conversion, creates one Input
Controller, and calls `cameraMove`, `cameraOrbit`, or `cameraZoom`; it may use
`Scene::camera()` as a narrow forwarding point. Wheel/trackpad input is converted to a
small signed zoom delta. This keeps behavior independent of DPI, window size, and
backend. The UI sidecar retains compatible camera helpers for existing UI-only hosts,
but a combined host routes ordinary camera gestures to Input.

A 3D cursor still requires a chosen hit plane or object intersection; a screen coordinate alone identifies a ray, not a unique world point.

## Optional UI, Input, and runtime composition

The experimental `tmath-ui` module is an optional C++ sidecar selected with
`-Dui=true`. Its `Panel` owns hit testing and pointer capture only for its visible
controls; Scene and renderer code do not dispatch button or slider events. A host may
construct and render the complete Panel without delivering any input. A visible `UIObject`
uses an ordinary Group/Object visual tree, so lowering, clipping, depth ordering, and
painting follow the existing Object path without a UI-specific renderer type; a
nonvisual SampleArea only retains its explicit input region and interaction state in
the optional module. Button idle, hover, and pressed faces are distinct authored
Objects; the Panel selects one after timeline sampling by composing opacity. State
faces are Panel-exclusive and cannot contain one another, preventing one inactive
opacity mask from hiding another control or its active descendant. A control's visual
identity is immutable after Panel registration.

`SampleArea` is the bounded exception to ordinary region-only control hit testing. It
owns no renderer-specific logic and names one to 64 explicit candidate Objects owned
by its root Scene. Candidates must be distinct, non-nested families. After a captured
primary press is released inside its region, Panel invokes
a host-supplied sampling function before committing the new marker or swatch state.
The software renderer evaluates the current timeline together with the already active
Panel Object/fill/camera state at the host's render density. It examines candidate
families in painted order and returns the configured candidate whose family has the
topmost nonzero-alpha hit; it does not return an individual descendant paint. The
color is the candidate-family composite straight RGBA rasterized under the Scene's
antialiasing policy. The Scene background and all non-family Objects are excluded.
This is an explicit click query, not implicit renderer hit testing during normal
frames. Only a successful query commits the new selection for the following composed
frame. `InsufficientCondition` is the transparent-miss result; other sampler failures
remain distinguishable in `InputResult::status` and the WASM input error flag.

The experimental `tmath-input` module is a separate C++ sidecar selected with
`-Dinput=true`. It owns logical key/pointer events, declarative PointerFollow and
KeyMove bindings, retained key state, native Tap/Down/Up triggers, and interactive
camera state. KeyMove uses the first keydown as a Down edge, ignores platform repeat,
and samples continuous motion until the matching keyup records its end time. It neither includes nor links UI. An
Input-only host can therefore move ordinary Scene Objects and the camera without a
Panel, control face, or UI symbol. Conversely, UI neither includes nor links Input.

Game input is layered below the Scene Controller:

```text
platform adapter -> input::State -> input::ActionMap -> simulation / Controller
```

`input::State` has no Scene or UI pointer. A host begins one frame, forwards raw
logical events, samples held/edge key and pointer state, and releases every retained
control on focus loss. Pointer movement and wheel values accumulate during a frame;
`pressed` and `released` edges remain observable even when a complete tap occurs
between two updates. `input::ActionMap` owns copied bounded action names and combines
key or pointer-button bindings into clamped 2D values plus aggregate lifecycle edges.
The application, not Scene time, chooses the fixed simulation timestep. The existing
Controller consumes the same state contract only to provide optional Object motion
and camera behavior, so a game host may omit it entirely.

The core exposes a module-neutral, bounded stack of up to `Scene::RuntimeLimit`
`RuntimeModifier` layers. At each requested time, the Scene first samples its immutable
authored Object and camera timelines. Registered layers then compose Object model,
opacity, progress, fill, and Camera/View in registration order before ancestor
composition and display-list lowering. A module-private `RuntimeModifier::key` prevents
two owners of the same sidecar type while `data` identifies the exact registration for
replacement and removal.

Each callback receives the requested Scene time, so a layer can apply time-independent
state or an intentional deterministic function of both time and retained input. With
no registered layers, sampling is the original core-only path. The renderer knows only
the resulting sampled state, never `Panel`, `Controller`, or a concrete control class.
The narrow compatibility input callback lets `Scene::camera()` offer a command to
registered owners without implementing pan, orbit, zoom, reset, or view state in core.

By default this separation also keeps interaction lifetime out of declarative
authoring. The bounded Lua state is destroyed after Scene construction and cannot retain
click, drag, pointer, or key closures. Optional Lua hooks expose one
`tmath.ui.panel(scene)` and one `tmath.input.controller(scene)` only when their
respective libraries are linked. The UI hook serializes Button, Toggle Button, Slider,
SampleArea, camera, and Object-transform descriptions into native controls. A
Slider description selects either one target mapping or a bounded list of synchronized
target mappings; each list item shares the control's normalized value and consumes one
Panel binding. This exposes the native multi-bind contract without introducing a Lua
callback or an Input dependency. A
SampleArea may map its normalized click coordinates to an
optional marker transform and its sampled color to an optional non-gradient Rectangle
swatch. A marker is either a childless Object or a Group, remains hidden until the
first successful sample, and receives `marker_origin + marker_x * u + marker_y * v`
as a transform in its parent's coordinate space. Marker and swatch families are
exclusive outputs and must remain family-independent from every candidate and every
other control-bound Object. It does not retain arbitrary callbacks
or make the renderer execute Lua per frame. The Input hook serializes explicit
logical-pixel-to-parent-space PointerFollow maps and logical-key-to-shift KeyMove
bindings. Arbitrary native trigger callbacks remain outside construction-only Lua. A
Lua-disabled build supplies an independent `NonSupport` stub for each enabled
authoring sidecar.

`tmath-lua-runtime` is an opt-in exception selected with `-Dlua_runtime=true` and
identified by `TMATH_LUA_RUNTIME` only in hosts that assemble its hook. Core, UI, and
Input do not depend on it. Even when compiled, a normal script closes exactly as
before; only an explicit `tmath.runtime(scene, config)` transfers its VM to one
Scene-owned `lua_runtime::Runtime`. Once loading succeeds, the VM's authoring flag is
disabled and the returned Scene handle is non-owning. Scene/Object-tree factories,
timeline calls, UI/Input builders, and authoring sidecars therefore reject later use.
The retained callback receives only a protected fixed-step context. Its `update()` and
`clear()` methods stage bounded render-time Object overlays by stable Scene identity;
the whole staging set commits after a successful protected call or is discarded on
error. `sound()` appends only a validated playback description to a bounded output queue;
it never opens a device or calls the Audio module. The VM is destroyed with the Scene.

The runtime accumulator clamps one host advance to `fixedStep * maxSteps`, records
discarded elapsed time, and runs no more than 64 callbacks per advance. Each callback
has an instruction limit. Object overlays are finite, capped at 512, and contain only
a captured or explicit pivot, shift, XYZ rotation, scale, opacity, progress, and solid
fill. They compose through the existing `RuntimeModifier` seam and never rewrite base
Object fields or clips. Lua-local state is retained; on callback failure its Object
overlay transaction rolls back and the runtime remains failed rather than attempting
an unsafe resume.

One host advance starts with an empty sound queue and may retain at most 64 events from
successful fixed steps. Each event contains a bounded asset name, music/effect/UI bus,
gain, rate, and loop flag. A failing callback rolls back the events it staged. The queue
belongs to Lua Runtime and remains available through `soundCount()`/`soundAt()` whether
or not Audio is compiled; an Audio-capable host may consume it, while every other host
may deterministically ignore it.

Fill overlay lookup follows Object ancestry: the nearest retained fill wins, so one
Group state recolors its painted family unless a descendant supplies a more specific
fill. Transform and opacity composition keep their existing Group semantics.

The runtime works without Input for autonomous simulation. When both optional modules
are built, the runtime library alone links `tmath-input`, receives a non-owning
`input::State`, and owns its private `ActionMap`. Key and pointer-button bindings are
immutable after load. One host input snapshot may feed several catch-up steps, but
Pressed/Released, pointer delta, and wheel data are masked after the first step. The
host advances the Input frame only after at least one fixed update consumes it. UI is
not included or linked by this adapter.

Emscripten exports the generic camera/input bridge when either sidecar is enabled. UI
adds capture/release and SampleArea metadata; Input adds keyup, logical key identity,
pointer-follow, Object motion, and the preferred camera owner. A combined host offers
pointer events to UI first and forwards only unhandled events to Input, except that it
broadcasts pointer-cancel for cleanup. UI hover updates do not claim an otherwise
unhandled move, so passive PointerFollow can continue outside captured gestures.
Keyboard Object bindings and ordinary camera gestures go to Input. These rules live in
the host adapter, not in either sidecar.

With the retained runtime enabled, Emscripten additionally exports an active-Scene
query, fixed-step advance, simulation time/tick, step count, interpolation fraction,
discarded-time counter, and bounded sound-event queries. The typed client
feature-detects the complete scheduler export set and independently detects the sound
queries for backward compatibility. `advanceRuntime()` is absent when the module is
compiled out, returns `null` for a construction-only Scene, and returns immutable
`sounds` data for an active Runtime. Runtime-declared key and pointer-button claims are
reflected by the host adapter so bound game controls are consumed without teaching
Input about Lua Runtime. An Audio-enabled host may forward the events to its player;
Lua Runtime itself has no Audio link dependency.

Passive pointer motion uses the same host-to-logical-Canvas conversion as captured
dragging. UI reverse-hit-tests one topmost control and updates Button hover state;
Input independently maps configured PointerFollow regions to parent-space positions
and shortest-path `atan2` headings. A logical 2D Canvas position does not by itself
define a 3D ray, world-space point, object-local coordinate, or depth intersection.

## Optional authoring sidecars

`tmath-diagram` and `tmath-chart` are separately selectable authoring libraries. They
depend on the public tmath object model but the core library never depends on either
one. Diagram stores bounded node, edge, zone, port, ranked/manual/grid/timeline layout,
semantic kind, full-width band, and waypoint descriptions; Chart stores bounded
quantitative ranges and line/bar series. Their `build()` steps
perform deterministic layout or scale mapping and return a detached owning Group
tree. Transferring that root to a Scene erases the authoring distinction: all later
timeline sampling, display-list lowering, renderer selection, and saving use the
existing ordinary Object paths.

The optional Lua bindings follow the same boundary. `tmath.diagram(scene, config)`
and `tmath.chart(scene, config)` collect semantic descriptions while the bounded VM
is alive, lower them once, recursively charge the complete generated subtree against
the core Lua Scene budgets, and expose protected non-owning handles for animation.
The module hook chain is assembled only by native CLI and WASM hosts that link those
libraries. A core-only loader has no Diagram or Chart symbols. External Mermaid,
DOT, and draw.io parsers remain importer/tool concerns rather than runtime module
dependencies.

## Scene and timeline

`Scene::add()` transfers any root Object, and `Object::add()` transfers a child subtree. The Scene keeps a flat non-owning identity/timeline index while Scene roots and Object nodes own the actual tree. Attachment records the current cursor as `born` and snapshots geometry, style, and local model. At cursor zero, native callers may edit an attached public definition and call `Scene::update(object)` to revalidate and refresh its base snapshot. `Text::text(value)` performs that refresh internally and rolls its private string payload back if the Scene rejects it. The first `play()`, `look()`, `wait()`, or `remove()` seals definitions already attached; a fully authored subtree may still be attached later and is born at that later cursor.

Later visual changes use immutable compact clips. Composite `AnimationTarget` and Lua/JavaScript `play` descriptors combine shift or transform, opacity, stroke, fill, and dashed-stroke offset into one `VisualState` clip per distinct target. Dash-offset motion is accepted only for an Object that already owns a non-empty dash pattern; the renderer interpolates the sampled offset through the same backend-neutral style path. A Scene-owned StyleGroup maps one semantic color to explicit live Object stroke/fill channels and expands each recolor into the same atomic target clips; its initial color may be explicit or inferred from the first selected channel, and channel ownership cannot overlap. Morph and Fade Transform transfer consumed membership to the live target, while remove detaches it. Effect clips additionally preserve path direction, pixel-relative scale, transient there-and-back state, or a replacement morph target. `fadeTransform()` atomically schedules paired FadeOut/FadeIn clips for unrelated object families and records the source's exclusive dead boundary at the shared end. Validation and reservation cover the complete group before an atomic commit. `look()` schedules a fixed-camera clip; `wait()` advances the cursor; `remove()` records an exclusive dead boundary.

At render time the engine samples base states, clips, and retained temporal Cell/Voxel frames at the requested `t`, composes ancestor state, resolves sampled family bounds and Connectors, projects/clips geometry, lowers and sorts the display list, composes isolated Viewports, then renders and synchronizes the backend. Sampling neither advances the cursor nor mutates a previous frame. Core has no arbitrary per-frame callback updater; the sampled `cell` and `voxel` authoring helpers have already materialized every retained time sample before this pipeline starts. The optional retained Lua sidecar runs only when its host explicitly advances the separate fixed-step clock, then contributes bounded overlays through the same sampling seam. Repeated and out-of-order renders are deterministic for the same authored time and committed runtime state. The full authoring and sampling lifecycle is specified in [scene-composition.md](scene-composition.md).

Matrices interpolate element-wise, which is intentional for visualizing linear maps. Text defaults to a screen-facing pixel-sized billboard; `TextOrientation::Plane` instead treats its size as world units and projects the receiver's local XY plane into one affine ThorVG text transform. This is exact under orthographic projection and an approximation under strong perspective. Points remain screen-facing pixel-sized markers. Layer is the primary draw order; projected depth is the secondary far-to-near order. This is correct for educational wireframes and non-intersecting translucent geometry. Exact intersecting surfaces need a depth buffer.

## Viewport composition

`Scene::viewport(child, {x, y, width, height})` transfers one complete child Scene into a normalized top-left rectangle of its parent. Rectangles must be finite, positive, and contained in `[0, 1]`. Self ownership, reuse, cycles, more than 64 children per node, and trees deeper than 16 Scenes are rejected. Lua/JavaScript use the same contract and seal a child after mounting. JavaScript requires all four bounds fields, while Lua and the C++ value type default to a full rectangle. Lua also limits the complete tree to 64 mounted children; every live Lua Scene shares the same scene, object, clip, point, and native-memory budgets, so unmounted drafts cannot multiply the limits.

Every Scene samples the same global time but keeps its own object namespace, timeline, camera, Theme, object-color cursor, background, display list, and layer/depth sort. Theme defaults are resolved when an Object joins that Scene, before its immutable base state is captured. Parent duration is the maximum of its local cursor and every descendant duration. Parent paints are below its Viewports; sibling Viewports are composited in insertion order. The root `loop` flag is a host playback policy, not a renderer time transform: the core samples the supplied time unchanged, and child loop flags do not rewind isolated Viewports independently.

Each child first lowers at its configured pixel size. ThorVG then scales that isolated group into the destination rectangle and clips the group to the rectangle before adding it to the parent. Text sizes, strokes, and arrow caps therefore scale with the child image, and a child aspect ratio different from its destination intentionally stretches. Parent resizing reflows normalized rectangles without changing their proportions. The 65,536-command frame budget is shared by the complete Viewport tree.

One ThorVG canvas renders the final tree, so the root Scene owns output width, height, FPS, antialiasing, and playback-loop policy. Child FPS, antialiasing, and loop fields do not override those output settings. The WASM host Panel addresses the root. Native C++ callers that need direct manipulation inside a mounted Viewport or transition stage create and retain a Panel for that child Scene and route normalized input through its camera helpers.

## Scene transition composition

`Scene::transition(stages, count, viewport, duration, hold, curve)` transfers an ordered array of isolated Scenes into one parent timeline. Lua exposes `scene:scene_transition(stages, options)` and JavaScript exposes `scene.sceneTransition(stages, options)`. Each stage contributes its completed frame; the parent holds it and then blends it into the next stage. The sequence begins at the parent's current cursor and advances it by `hold × count + duration × (count - 1)`.

At a boundary, both stages build unsorted display lists at their own configured resolutions and cameras. Non-empty Object IDs map source registry entries to target registry entries. Compatible command spans interpolate; path commands use 64-point arc-length sampling with closed-contour direction and start-point alignment. Changed equal-ID text dissolves out and then in to avoid layout collisions; other incompatible spans cross-fade. The blended list is then sorted once, rendered at the source stage size, mounted into the normalized transition Viewport, and clipped. Background colors interpolate, while nested Viewports and nested transition sequences remain isolated groups and cross-fade. The complete render tree shares the existing command and depth limits.

Ownership transfer is atomic. Validation and allocation complete before any stage is sealed; on failure the caller retains every Scene. On success the parent becomes their sole owner and destroys the complete sequence. Rendering is still arbitrary-time and stateless: the transition reads immutable stage final frames and does not advance or mutate either stage.

## Renderers and savers

`Renderer` owns exactly one immutable `RenderEngine::Cpu` or `RenderEngine::Gl`
backend. Its atomic global default applies only to future instances; explicit
`Renderer::gen(engine)` calls bypass that default. Missing modules and target
mismatches fail with no cross-engine fallback. The compatibility `SwRenderer` and
`GlRenderer` types are confined to their backend adapters.

The internal backend registry is the extension seam for another engine such as WG:
add one adapter and one unavailable-build stub, register the new engine in the facade,
and select its source in Meson. Backend-neutral Scene lowering, CPU inspection, and
existing GL code do not depend on that adapter. A WG enum value and target contract
should be exposed only when its adapter is implemented rather than reserving a public
value that cannot render.

The CPU adapter owns a ThorVG `SwCanvas`, renders to a caller-visible straight-alpha
`ABGR8888S` surface, and always synchronizes before buffer access. The GL adapter
consumes the same backend-neutral display list. It defers `GlCanvas` creation until
the first target render so selecting GL does not touch a context; the host owns and
makes current the OpenGL/WebGL context and framebuffer before that render. Each GL
renderer must also be destroyed or retargeted while its context remains valid and
current. Each Viewport is a transformed, clipped ThorVG Scene group rather than a
flattened command merge, so sibling layer and depth values cannot interfere. The PNG
writer is dependency-free.

ThorVG edge antialiasing is selected by the root Scene for the shared canvas and is consistent across SW/GL creation. It is independent from Image sampling, which selects bilinear or nearest filtering.

Native `Saver::video()` streams constant-cadence RGBA frames to external FFmpeg through a sibling temporary file and renames only after success. GIF and MP4 keep separate format modules over that shared frame pipeline. WASM exposes synchronized RGBA; the Playground encodes GIF/MP4 in browser libraries.

`Saver::lottie()` writes raw `.json` Lottie with the root Scene dimensions, selected FPS, an exclusive `op`, and one-frame vector layers sampled from the same DisplayList used by ThorVG. Path, Circle, Text, and Number commands become Lottie shape/text objects; Space, grids, cells, 3D projection, Viewports, clipping, and Scene transitions are already lowered through those commands and retain their composition order. The writer follows the properties consumed by ThorVG's Lottie parser (`ks`, `shapes`, `masksProperties`, fill/stroke, and text documents) and commits through a sibling temporary file. The same serializer can target an engine-owned memory buffer for the filesystem-free C/WASM API; JavaScript copies those bytes before returning them. File-backed Svg and pixel Image commands currently return `NonSupport` instead of silently rasterizing an otherwise vector export.

## Assets, images, and cells

`AssetLoader` loads a file, encoded memory, or raw `ABGR8888S` pixels. Encoded PNG/JPG/WebP/SVG goes through a ThorVG `Picture` and a one-time CPU offscreen decoder so Image and Cell always consume the same straight-alpha RGBA representation. That decoder is an explicit CPU utility module rather than a hidden render fallback: GL-only builds return `NonSupport` for encoded assets, while raw pixels remain available. The pinned native/WASM CPU build enables those four loaders. File-backed Lua resolves relative asset paths from the Lua file directory; filesystem-free WASM registers bytes by name through `scene.asset()` before scene load.

`Image` copies an Asset and stores one parent-local center plus world-unit width. Height is derived from the pixel aspect ratio before ancestor matrices are composed; nonuniform ancestor scale is therefore an explicit distortion. ThorVG receives one affine image transform. Under an orthographic camera this is exact; a strongly perspective-warped image plane is an affine approximation because ThorVG has no projective texture primitive. Use Cell pixels/voxels when exact per-cell perspective structure matters.

`Cell` stores up to 16,384 colors as one scene object. Its integer local region is a dense batch rather than thousands of timeline objects. `fill()` paints a rectangular cell region and `texture()` nearest-samples a source image rectangle into a destination rectangle. `Full` uses complete unit cells; `Padd` insets them, defaulting to 5%. In planar view each visible cell lowers to one quad. In spatial view it lowers to a local +Z voxel with back-face rejection and ambient plus camera-headlight shading; there is intentionally no light graph, shadowing, or material system.

`SurfaceMesh` stores a row-major rectangular lattice of 3D samples. Each four-sample patch lowers to one depth-sorted shaded path. `Solid` paints a same-color seam-covering edge, `Mesh` emits the authored wireframe, and `SolidMesh` keeps both authored fill and stroke. This is a sampled educational surface rather than a general triangle mesh: it does not perform hidden-surface intersection or perspective-correct material sampling.

## Text, formulas, and trust

Fonts are registered explicitly, including byte-backed fonts in WASM. TeX stays outside the core. A build configured with `-Dlatex=enabled` adds the experimental native `tmath latex` precompiler, which launches `latex` and `dvisvgm` without a shell and writes SVG. Expressions remain trusted TeX input. Native SVG paths access the host filesystem and therefore require trusted input plus an application asset policy; filesystem-free WASM does not build the precompiler or support file-backed SVG. Plane-oriented Text currently returns `NonSupport` from the Lottie saver because the text layer exporter does not encode arbitrary projected affine transforms.

## Source layout

```text
inc/                    public C++ and C APIs
src/common/             vectors, matrices, camera, easing
src/loaders/            ThorVG-backed asset normalization
src/scene/              unified objects, ownership, timeline, camera input
src/renderer/           display-list lowering
src/renderer/tvg/       ThorVG SW/GL adapter
src/savers/             shared PNG/timeline code and format-specific GIF/Video/Lottie sinks
src/bindings/lua/       resource-limited Lua scene DSL
src/ui/                 optional controls, input routing, sampling bindings, camera helpers
src/input/              optional logical key/pointer state, actions, and camera adapter
src/lua_runtime/        optional retained VM, fixed-step scheduler, and Object overlays
src/diagram/            optional semantic flow layout, routing, and Object lowering
src/chart/              optional quantitative series mapping and Object lowering
bindings/wasm/          narrow C ABI over Lua + SW RGBA
tools/                  command-line renderer/inspector
test/                   numeric, scene, renderer, Lua, C/JS binding tests
examples/               Lua sources and browser Playground
skills/tmath-skills/    public animation, diagram, and visualization workflow
skills/tmath-game/      experimental interactive/runtime/audio game authoring
skills/tmath-vscode/    VS Code use, IntelliSense, manifests, and series delivery
skills/tmath-animation-dev/ repository contributor workflow and synchronization checks
```

The layers stay shallow: no renderer-specific scene graph, plugin framework, reflection system, or per-frame object deep copy.
