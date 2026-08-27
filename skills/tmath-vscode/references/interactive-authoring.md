# Interactive Canvas authoring

Read this after [tmath-game](../../tmath-game/SKILL.md) and the [tmath-skills scene contract](../../tmath-skills/references/scene-contract.md), only for explicit controls, direct manipulation, pointer inspection, or user-controlled cameras in the VS Code Canvas. `tmath-game` owns UI, Input, retained Runtime, and Audio semantics; this reference adds host behavior. Interactivity does not choose style, format, or aspect ratio. The initial FIT frame must remain complete for hover, export, and readers who never interact.

## Runtime boundary

The UI module described below exists only with `-Dui=true`; `-Dui=false` excludes `inc/tmath_ui.h`, `src/ui/`, bindings, tests, and WASM UI control/sample exports. Input, retained Runtime, and Audio are separate feature-detected modules and do not become unavailable merely because UI is disabled. Preserve a working UI-disabled host.

`UIObject`, `Button`, `Slider`, `SampleArea`, and `Panel` belong to the UI sidecar. Create at most one Panel per Scene. The Panel owns controls, attaches to one root Scene, reverse-hit-tests, captures drags, and publishes handled/redraw/capture/release/sample results. The authoring Lua VM closes after construction; persistent Lua callbacks do not exist.

Button-family and Slider faces are ordinary Scene Objects supplied as `visual`. Optional `hover_visual` and `pressed_visual` replace the idle face through composed opacity. Every face must be independent, non-nested, reserved for one control, and Theme-authored before Panel registration; its visual identity is then frozen. Panel never mutates authored fill or stroke.

Treat the implementation ceilings—one Panel, `256` controls, `256` bindings, and `64` SampleArea targets—as safety limits, not design targets.

## Coordinates and declarations

Control `region` uses positive-size logical Scene pixels:

```text
x = (clientX - canvasLeft) * sceneWidth  / displayedCanvasWidth
y = (clientY - canvasTop)  * sceneHeight / displayedCanvasHeight
```

Do not use device pixels, surrounding CSS pixels, world coordinates, or implicit bounds-derived regions.

Supported declarative behavior:

- `panel:button`: exactly one camera action (`move`/`pan`, `orbit`, `zoom`, `reset`, `view2d`, or `view3d`, optionally with a two-component `delta`) or one Object `target` plus persistent `transform`. Target Buttons may use non-negative Scene-second `duration`; camera Buttons may not. Most recently clicked Button state wins for a shared target.
- `panel:toggle_button`: one target, required `off` and `on` transforms, optional initial boolean `value`, and optional non-negative `duration`. Only a completed primary click flips it.
- `panel:slider`: one target, normalized `value`, `axis`, and `from`/`to` transforms. Drag remains captured and clamps the value.
- `panel:sample_area`: one region and one to `64` distinct candidate Objects owned by the root Scene. No candidate may be an ancestor or descendant of another.

A transform may contain `shift`, `scale`, rotation in radians, `opacity`, and draw `progress`; clamp opacity, progress, and slider values to `[0, 1]`. Native C++ Button and Slider may use allocation-free function-pointer callbacks with caller data that outlives the Scene; a Toggle callback observes its post-click value through `Button::toggled()`. The native host installs the bounded `SwRenderer::sample` bridge.

## Sampling contract

SampleArea captures primary down and samples only when primary up completes inside its region, using the release position. Sample in this order:

```text
authored timeline at t -> existing Panel Object/fill/camera state
-> explicit candidate families under Scene AA -> topmost nonzero-alpha family
-> commit immutable result -> redraw
```

Return and retain logical `x`/`y`, normalized `u`/`v`, configured candidate identity, and its internally composited straight RGBA at current backing density. Exclude Scene background and every non-family Object. Commit marker and swatch only after success. A miss preserves the previous successful result; a renderer failure is `input.error`, not a miss.

An optional marker must be childless or a Group. `marker_origin + marker_x*u + marker_y*v` is a parent-space shift; logical `u` grows right and `v` down. An optional swatch is a non-gradient Rectangle whose runtime fill becomes sampled RGBA. Marker and swatch families are reserved outputs, independent from all candidates and control-bound families. Sampling is click-only—not hover, continuous drag, a 3D ray, depth query, local-coordinate query, or retained Lua handler.

Panel Object, fill, and camera state compose after the authored timeline without mutating it. Camera move/orbit/zoom remains a delta over the camera at current time; Reset clears Panel deltas and returns to that authored camera.

## Input and host behavior

All Canvas input passes through `canvas-input.mjs`: convert to logical coordinates; offer passive and captured events to Panel; honor handled/capture/release/sample/redraw and coalesce redraw; then run FIT, context-menu, or camera fallback only when unhandled. Forward successful snapshots through `onSample`; surface `inputError` without losing release. Clear hover/capture on leave, cancellation, reload, disable, lost capture, and disposal. Never attach a control-specific Canvas listener or steal form input, editor shortcuts, right click, or FIT middle drag.

Right click opens the existing settings popup beside the pointer, clamped to an eight-pixel viewport edge and flipped as needed. Shift+drag camera pan remains; FIT uses middle-drag pan and damped pointer-anchored wheel zoom, which cannot shrink below automatic FIT, affect Scene camera/export size, or run outside FIT.

Canvas Full Screen uses the Webview viewport, not the browser API. Hide Inspector and Wide sash; Compact retains Playback, while Wide hides Playback and docked series at rest. Keep right-click settings, suspend then restore manual stage sizing, recalculate FIT on both transitions, and exit with Escape.

## Verification

Verify deterministic defaults; exact regions at every layout; topmost overlap; hover/pressed/cancel state; Toggle and Slider endpoints; capture outside regions; sampled identity/RGBA/marker/swatch under active time and density; miss/error behavior; timeline and camera composition; host-gesture fallback; and complete absence of UI exports in a disabled build.
