# JavaScript and TypeScript API

Use the typed builder for browser or WASM-hosted scenes. Import `tmath` and `createTMath` from the module entry supplied by the user's installation or application; do not assume a repository build directory. The example import path below is a placeholder to replace with that entry.

## Build and render a scene

```js
import {createTMath, tmath} from "./client.js";

const definition = tmath.scene({
    width: 960,
    height: 540,
    fps: 30,
    loop: false,
    theme: "pro_white", // standalone default; VS Code uses "adaptive_vscode"
    camera: {mode: "fixed", view: "2d", target: [0, 0], height: 7},
});

const lesson = definition.group({id: "lesson"});
definition.text({
    text: "How does this vector encode direction?",
    point: [-4.8, 3],
    align: [0, 0.5],
    role: "h2",
    id: "question",
});
const plane = lesson.space({
    x: [-5, 5, 1],
    y: [-3, 3, 1],
    numbers: true,
    id: "plane",
});
const vector = plane.vector({origin: [0, 0], value: [3, 2], tip: 14, id: "vector-a"});
vector.label({
    text: "a = (3, 2)",
    point: [3.25, 2.2],
    align: [0, 0.5],
    role: "code",
    id: "vector-a-label",
});

definition
    .wait(0.35)
    .fadeIn(lesson, {shift: [0, 0.15], scale: 0.97, duration: 0.55, curve: "gentle"})
    .indicate(vector, {scale: 1.06, duration: 0.45, curve: "ease_in_out"})
    .wait(0.65);

const runtime = await createTMath(definition, "vector-lesson.js");
const canvas = document.querySelector("canvas");
if (canvas) runtime.draw(canvas, runtime.duration);
```

`SceneBuilder` records a typed definition and compiles through the same bounded scene path as Lua. `TMathScene` is the loaded runtime used for rendering, drawing, assets, fonts, bounds, resize, reload, Lottie, and destruction.

The experimental native Diagram and Chart semantic builders currently expose C++ and optional Lua authoring surfaces, not JavaScript/TypeScript `SceneBuilder` methods. In JS/TS, keep using ordinary Object handles for diagram and chart compositions. Do not emit `tmath.diagram(...)` or `tmath.chart(...)` into a typed JavaScript scene merely because a module-enabled WASM can load those names from Lua.

## Builder factories

SceneBuilder and every Object handle expose `group`, `space`, `point`, `line`, `arrow`, `vector`, `circle`, `rectangle`, `polygon`, `plot`, `route`, `path`, `curve`, `surface`, `text`, `ruler`, `svg`, `image`, `cell`, and `connector`. `route` creates one ordered polyline with a shaft and solid endpoint markers in one Object. A Cell uses `size: [columns, rows]`, `mode: "full"|"padd"`, and normalized per-cell `padding` in `[0,0.5)`, not pixels. SpaceHandle additionally overloads `cell(callback, options)` and provides `voxel(callback, options)`; sampled fields require explicit finite positive-step `x`/`y` ranges on the Space, plus `z` for Voxel.

ObjectHandle offers `moveTo`, `nextTo`, and `alignTo`. GroupHandle adds `arrange` and `arrangeGrid`. The same direct-parent coordinate and pre-timeline layout rules as Lua apply.

A `Mat4` is a flat 16-number row-major tuple and multiplies the column point `[x,y,z,1]`. Translation is `[1,0,0,tx, 0,1,0,ty, 0,0,1,tz, 0,0,0,1]`. Group/Space `matrix`, Composite Play `transform`, and `definition.transform` all take this absolute local-to-parent transform, not a delta.

`object.label(options)` is an Object-only semantic alias that creates and returns an ordinary child Text with the complete `TextOptions` surface. Placement and styling remain explicit: it does not infer an anchor, offset, paint, or layer. Primitive geometry does not move the child origin: an identity-model Rectangle at `center: [cx, cy]` needs `point: [cx, cy]`, `align: [0.5, 0.5]`, and an explicit foreground `layer` for a centered visible label. Because it is a normal child, it inherits the labeled object's transform and can be animated, inspected, or bound to a StyleGroup like any other Text handle.

Prefer the exported TypeScript declarations—`SceneConfig`, object option types, `SceneBuilder`, Handle types, animation options, `TMathScene`, and related enums—over untyped object literals copied from prose.

## Timeline names

JavaScript uses camelCase:

```js
definition.play(specification, duration, curve, lag);
const identity = definition.styleGroup({members: [{target, channel: "stroke"}]});
definition.styleBind(identity, newlyAttachedTarget, "fill");
definition.style(identity, color, duration, curve);
definition.create(targets, duration, curve, lag, direction);
definition.uncreate(targets, duration, curve, lag, direction);
definition.write(targets, duration, curve, lag, direction);
definition.fillReveal(targets, duration, curve, lag);
definition.drawBorderThenFill(targets, duration, curve, lag, direction);
definition.fadeIn(target, options);
definition.fadeOut(target, options);
definition.growFromCenter(target, duration, curve);
definition.growFromEdge(target, "bottom", duration, curve);
definition.shrinkToCenter(target, duration, curve);
definition.indicate(target, options);
definition.morph(source, target, duration, curve, lag);
definition.replacementTransform(source, target, duration, curve, lag);
definition.fadeTransform(source, newlyAttachedTarget, duration, curve);
definition.shift(target, by, duration, curve);
definition.transform(target, matrix, duration, curve);
definition.fade(target, opacity, duration, curve);
definition.transition(outgoing, incoming, duration, curve);
definition.stroke(target, color, duration, curve);
definition.fill(target, color, duration, curve);
definition.look(cameraTarget, duration, curve);
definition.wait(duration);
definition.remove(target);
```

`create`, `write`, and `fadeIn` hide their targets before the scheduled reveal; a handle without an entrance animation is visible at `t=0`. Leave one coherent opening group unanimated, schedule later facts only in their evidence beat, and render `t=0` again after the full definition is built. Do not entrance-animate every object or leave labels visible without their owners.

Composite Play:

```js
definition.play(
    [
        {target: left, shift: [-1, 0], opacity: 0.75, fill: "#4cc9f0"},
        {target: dashedRoute, dash_offset: -14, tail: 8, tip: 16},
        {target: right, transform: targetMatrix, stroke: "#f72585"},
    ],
    0.8,
    tmath.animCurve.preset("snappy", 0.85),
    0.1,
);
```

`dash_offset` requires a target with a non-empty dash pattern. `tail` and `tip` require an Arrow, Vector, Connector, or Route; on dashed Arrow/Route geometry they remain solid while only the shaft consumes the dash phase. For a seamless flow cycle, animate the offset linearly by one full dash period: the sum of the route's dash and gap lengths. Keep every Composite Play target distinct.

Build curves with `tmath.animCurve.preset(name, strength)`, `cubicBezier(x1,y1,x2,y2,strength)`, or `reverse(curve)`.

Use `styleGroup` for a semantic color shared across marks, Text, and copy/morph proxies. Omit `color` to infer an automatically cycled identity from the first member's selected paint channel; `both` inference requires equal stroke and fill. Pass `color: "result"` for returned or derived output and `color: "focus"` only for a fixed transient-salience group. Bind each live, clip-free member before its first animation. One `style` call emits simultaneous clips, while consuming Morph and Fade Transform operations transfer membership to the live target.

Use `fadeTransform` when unrelated object families represent one replacing identity. Create the target immediately before the call. It is hidden automatically before the cross-fade; afterward the source handle is consumed and the target remains live. `transition` is the non-consuming group cross-fade.

## Fonts and assets

Fonts can be registered after a scene loads but before text rendering. Asset-backed Image/Cell objects need their named bytes during scene construction, so create a minimal runtime first, register bytes, then hot-load the real definition:

```js
const bootstrap = tmath.scene({width: 1, height: 1});
const runtime = await createTMath(bootstrap, "bootstrap.js");

runtime.font("Lesson Sans", fontBytes, "ttf");
runtime.asset("diagram", imageBytes, "png");
runtime.loadScene(definition, "lesson.js");
```

Use stable application-owned names. WASM has no native filesystem; fetch or bundle bytes through the host. `evaluateScene(source, name)` uses dynamic JavaScript evaluation and is appropriate only for trusted editor code. Normal applications should build through `tmath.scene()`.

## Runtime lifecycle

```js
const runtime = await createTMath(definition, "scene.js", {renderEngine: "cpu"});
runtime.renderEngine;             // "cpu" or "gl"
runtime.render(time);             // transient zero-copy pixel view
runtime.render(time, true);       // stable copied Uint8ClampedArray
runtime.draw(canvas, time);
runtime.bounds("subject", time);
runtime.intersects("title", "plot", time, 4);
runtime.layoutReport(time, 4);    // root + nested Viewports in root pixels
runtime.resize(width, height);
runtime.lottie(30);               // stable Uint8Array
runtime.loadScene(nextDefinition, "next.js");
runtime.loadLua(luaSource, "next.lua");
runtime.destroy();
```

The zero-copy render view is invalidated by the next render, resize, or WASM memory growth. Copy pixels that must outlive the call. Failed hot reload preserves the last valid scene. Call `destroy()` when the runtime is no longer used.

`renderEngine` is fixed when the runtime is created. A requested engine that is not
compiled fails creation and never falls back. The distributed tmath WASM bundle is
CPU-only because `render()`, Canvas2D `draw()`, layout inspection, sampling, and
media export require synchronized RGBA. A custom GL WASM host needs its own WebGL
target and presentation/readback bridge; choosing `"gl"` on the CPU bundle fails
explicitly.

Bounds and intersection queries use stable root-Scene IDs/tags and sampled render-space family boxes. `layoutReport` returns every Scene path and Object, own and descendant-inclusive bounds, clipping/stretch status, cross-Scene collision candidates, and ancestor/descendant containment. Resolve report objects by `scenePath + id`; call `layoutReport(Math.min(frame / fps, runtime.duration), 4)` for every frame from zero through `Math.ceil(runtime.duration * fps)`, render representative copied pixel frames, and inspect the exact final time. Use reports for validation, never as live constraints.

## Game and retained-runtime boundary

Use `tmath-game` for UI/Input, action maps, camera control, retained Lua runtime, audio, host-driven mutation, or a simulation loop. This reference covers only construction and the minimal runtime lifecycle needed to render or mount a finished scene.

## Fields, Viewports, and transitions

Cell and Voxel callbacks are synchronous authoring-time functions:

```js
const field = plane.cell(
    (x, y, time) => x*x + y*y <= (1 + 0.4*time) ** 2 ? "#0891b2" : "#00000000",
    {duration: 1, fps: 24, mode: "padd", padding: 0.06},
);
```

Mount completed child builders with `definition.viewport(child, bounds)`. Use `definition.sceneTransition([first, second], options)` for sequential stage replacement. Both calls transfer and seal the child builders; do not author into them afterward.
