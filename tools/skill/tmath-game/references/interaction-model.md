# Interaction contract

Read this contract for declarative UI, Object input bindings, mixed UI/Input routing, logical-pixel regions, or interactive cameras. Apply the authoring, layout, typography, motion, and render-review rules from `tmath-skills` first.

## Optional sidecars and guards

The core Scene, timeline, renderer, and saver do not depend on interaction. The optional static sidecars are independent:

| Sidecar | Build option | Lua namespace | Ownership |
| --- | --- | --- | --- |
| UI | `-Dui=true` | `tmath.ui` | controls, hit regions, pointer capture, retained control state, rendered sampling |
| Input | `-Dinput=true` | `tmath.input` | normalized events, Object motion bindings, native frame state/actions, camera deltas |
| Lua Runtime | `-Dlua_runtime=true` | `tmath.runtime` | one explicitly retained VM, fixed-step scheduling, bounded Object overlays |
| Audio | `-Daudio=true` | `tmath.audio` | authored audio transport and immediate host playback |
| Motion | `-Dmodules=motion` | `tmath.motion` | named semantic overlays, capture-current retargeting, bounded acknowledgements |

UI and Input never include, link, call, or read each other. Core, UI, and Input do not depend on Lua Runtime. Runtime works without UI, Input, or Audio; only its optional Input adapter links Input when both are enabled. `ctx:sound` stays a data event without Audio.

Guard every namespace a Lua scene requires with its exact option:

```lua
if not tmath.ui then
    error("this scene requires a tmath build configured with -Dui=true")
end

if not tmath.input then
    error("this scene requires a tmath build configured with -Dinput=true")
end

if not tmath.runtime then
    error("this scene requires a tmath build configured with -Dlua_runtime=true")
end

if not tmath.audio then
    error("this scene requires a tmath build configured with -Daudio=true")
end

if not tmath.motion then
    error("this scene requires a tmath build configured with -Dmodules=motion")
end
```

## Minimal UI and Object-input anchors

Create all target and face Objects first. Faces are independent objects reserved for one control; `region` stays in logical Scene pixels while target transforms use direct-parent world units.

```lua
local panel = tmath.ui.panel(scene)
panel:button {
    visual = button_face,
    region = {x = 24, y = 24, width = 96, height = 40},
    target = player,
    transform = {shift = {1, 0, 0}},
    duration = 0.25,
}

local input = tmath.input.controller(scene)
input:key_move {
    target = player,
    key = "ArrowRight",
    shift = {1, 0, 0},
    period = 0.12,
}
```

Panel methods are `button`, `toggle_button`, `slider`, and `sample_area`; Input methods are `pointer_follow` and `key_move`. The ownership rules below define valid combinations. Use only fields named in this contract: do not infer browser-style callbacks or mutable widget properties.

## Host routing and coordinates

The host owns event delivery. In a combined host:

1. Offer each pointer event to UI.
2. Forward it to Input only when UI reports it unhandled.
3. Keep an accepted UI press/drag captured by UI through completion.
4. Broadcast pointer cancellation so both modules can clear transient state.
5. Route keyboard Object motion and camera control to Input.

This is host policy, not a module dependency. UI-only may render without events; Input-only needs no Panel.

All Panel, SampleArea, and PointerFollow regions use top-left-origin logical Scene pixels. This applies only to input regions: authored Object geometry and Runtime `ctx:update` transforms remain direct-parent world units under the `tmath-skills` camera contract. Convert display coordinates with:

```text
x = (clientX - canvasLeft) * sceneWidth  / displayedCanvasWidth
y = (clientY - canvasTop)  * sceneHeight / displayedCanvasHeight
```

Never pass world, CSS, device, or backing-store coordinates. Recompute regions after any layout, canvas, camera, or projection change.

For the fixed 2D camera, invert the main scene mapping when aligning a face centered at world `(wx,wy)` to a logical-pixel region: `px = width/2 + (wx-target.x) * height/camera.height` and `py = height/2 - (wy-target.y) * height/camera.height`. Derive the region from the face's full projected family bounds plus intentional hit padding; never eyeball unrelated pixel literals.

PointerFollow maps its region into the target's direct-parent space:

```text
u = clamp((x - region.x) / region.width, 0, 1)
v = clamp((y - region.y) / region.height, 0, 1)
mapped = map_origin + map_x * u + map_y * v
```

No Y inversion is implicit. `target_origin` is the parent-space home pivot that arrives at `mapped` and is the optional rotation pivot.

## Composition and ownership

Display state composes in this order:

```text
sample authored Scene timeline at time t
-> compose registered runtime Object/fill modifiers in registration order
-> compose registered camera state over the authored camera
-> render
```

Interaction never mutates authored Object fields or timeline definitions. Retargeted transitions begin from the currently composed state. Camera reset clears Input deltas and returns to the authored camera at the current Scene time.

Motion is another independently selected runtime modifier. Its clock advances only
when Lua or the host calls `motion:advance(dt)`; Runtime does not advance it
automatically. Define semantic states before retained authoring is sealed, keep the
Motion handle captured by the fixed-step callback, and advance it exactly once per
simulation step when the two clocks should share a cadence. Do not also drive the
same Object through `ctx:update`, UI transform bindings, or Input Object-motion
bindings unless the intended modifier order and composed transform are explicit.

A Scene owns at most one UI Panel and one Input Controller. The Panel owns at most 256 controls and 256 target bindings. The Input Controller owns at most 256 total PointerFollow, KeyMove, and key-trigger bindings.

Keep ownership unambiguous:

- Control faces are existing, independent, non-nested Objects reserved for one control. Never use a control face as its data target.
- Panel-owned face families and Input target families must not be ancestors or descendants of one another.
- Use a semantic Group as the target when several painted objects share one state.
- Multiple Button-family bindings may target one Object; the most recently activated persistent transform wins.
- A Slider uses either top-level `target`/`from`/`to` or `bindings`, never both. Every binding receives one normalized value and owns its own target endpoints; each counts toward the Panel binding limit. Avoid ancestor/descendant bindings that apply a transform twice.
- SampleArea accepts one to 64 explicit candidate Object families and updates only on a completed sample. It is not a continuous pad or 3D ray query.

## Input bindings and camera

PointerFollow requires `target`, `region`, `map_origin`, `map_x`, and `map_y`. Its `period` is finite and nonnegative. One target may have only one PointerFollow. Do not combine PointerFollow with KeyMove on that target. PointerFollow observes passive motion, does not capture, and optionally retargets the authored home transform on leave or cancellation.

KeyMove permits multiple distinct keys on one target but rejects a duplicate target/key pair. Supported logical keys are ArrowLeft/Right/Up/Down, Space, Enter, Escape, Shift, Tab, A-Z, 0-9, Plus, and Minus. The first keydown begins retained state; platform repeat does not retrigger or change speed. A positive `period` ramps and then advances at `shift / period` until keyup; zero applies one immediate shift on the Down edge. Ctrl, Alt, and Meta combinations remain host shortcuts; Shift may accompany a declared binding.

Interactive camera state belongs to Input and must reveal a spatial fact. Provide a discoverable reset path. Host camera gestures compose over the authored camera; authored camera timeline calls are not input callbacks. Because Panel regions stay in logical pixels while faces project through the camera, verify face/region alignment in every reachable camera state.
