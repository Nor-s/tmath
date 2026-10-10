# Runtime and review contract

Read this contract for native frame input, `State`/`ActionMap`, retained Lua, sound events, build validation, and delivery review.

## Native frame input

`input::State` is independent of Scene, Controller, UI, renderer, and the platform window layer. The host owns normalization and event order.

- Call `begin(time)` exactly once before pumping all events for one host input frame, never once per event or simulation step.
- `begin` copies current digital state to `previous` and clears only frame-local `pressed`/`released` edges, pointer delta, and wheel. Events accumulate until the next `begin`. A press and release in one frame exposes both edges while final `down` is false.
- Held keys, pointer buttons, positions, and begin/end times persist. One State tracks all supported keys and at most 16 observed pointer IDs; each active pointer needs a stable ID.
- Call `release(time)` on focus loss, router cancellation, Scene replacement, and teardown. It atomically ends every held key and pointer button while leaving Released edges observable for that frame.

`ActionMap` owns at most 256 key or pointer-button bindings. Action names are at most 63 bytes. Values of held bindings with the same name sum and clamp per component to `[-1, 1]`; lifecycle edges describe the aggregate action. Releasing one alias does not release an action still held by another. Re-registering the same action/source replaces only its value; remove an action before changing its source set.

Sample input once per host frame before fixed-step catch-up. Expose `pressed`/`released`, pointer delta, and wheel only to the first simulation step; held state remains visible to every step. A single edge must never repeat merely because one host frame runs multiple simulation steps.

## Retained Lua

Ordinary Lua remains construction-only and closes its VM after load. Retention requires an enabled build, the exact `tmath.runtime` guard in [interaction-model.md](interaction-model.md), and one explicit `tmath.runtime(scene, config)` declaration.

If the callback uses actions or snapshots, also require `tmath.input` with the exact `-Dinput=true` guard from the interaction contract. `bind_key`, `bind_pointer`, `ctx:action`, `ctx:key`, and `ctx:pointer` exist only when Input is built; an autonomous Runtime does not need Input.

Create the runtime after every Scene object and sidecar binding it will use. This minimal action-driven loop is the exact retained shape:

```lua
local x = 0
local runtime = tmath.runtime(scene, {
    fixed_step = 1 / 60,
    max_steps = 8,
    update = function(ctx, dt)
        local move = ctx:action("Move")
        x = x + move.value.x * dt
        ctx:update(player, {shift = {x, 0, 0}})
        if move.pressed then
            ctx:sound("audio/short-laser.wav", {
                bus = "effect", gain = 0.5, rate = 1, loop = false,
            })
        end
    end,
})
runtime:bind_key("Move", "A", {-1, 0})
runtime:bind_key("Move", "D", {1, 0})
```

`ctx:action(name)` returns `previous`, `value`, and `delta` Vec2 records plus `down`, `pressed`, and `released`; each Vec2 supports both `.x`/`.y` and numeric indices. `bind_key(action, key, value)` defaults value to `{1,0}`. `bind_pointer(action, button, value, pointer_id)` defaults value to `{1,0}` and pointer ID to zero.

The host supplies finite, nonnegative monotonic elapsed time to native `Runtime::advance` or feature-detected WASM `advanceRuntime`. Runtime time is separate from authored Scene time. `fixed_step` must be finite, greater than zero, and at most one second; `max_steps` is an integer from 1 through 64. One advance executes at most `max_steps` callbacks, clamps the accumulator to `fixed_step * max_steps`, and records discarded elapsed time.

Do not advance the host Input frame until at least one fixed step consumed its current snapshot. Within one catch-up advance, transient edges, pointer delta, and wheel reach only the first callback; held state reaches every callback.

After load, Scene/Object factories, tree edits, timelines, UI/Input builders, and Diagram authoring are locked. The protected callback may use only its context:

- `ctx:update(object, state)` accepts finite pivot/origin, shift, XYZ rotation, scale, opacity, progress, and solid fill.
- `ctx:clear(object)` removes one overlay; `ctx:clear()` removes all.
- One Runtime controls at most 512 stable Scene Object identities.
- A retained Group fill propagates to painted descendants unless a nearer retained fill overrides it.

Every callback stages its complete overlay transaction. Success commits it atomically. Any callback error discards all overlays staged by that step, preserves the last committed display state, permanently pauses the Runtime in the failed state, and makes later advances fail. Lua-local mutations made before the error are not rolled back.

Runtime opacity multiplies authored opacity. An Object that must become visible later cannot be authored at zero opacity; pre-author it at opacity one outside the visible frame, accounting for complete painted bounds, then commit destination and runtime opacity together. Pre-author any reusable bounded pool; when full, reject new activation rather than repurposing an active identity.

`ctx:sound(asset, options)` appends validated asset, bus, gain, rate, and loop data; it is not playback. Asset paths are host-resolved relative to the delivered Scene source: copy a selected reference WAV into that layout or rewrite the path rather than assuming the skill-tree location survives delivery. One host advance carries at most 64 events. A full queue returns false. Invalid data fails the callback, and events staged by a failed callback roll back with its overlays. Runtime exposes the queue without Audio; an independently detected Audio host may consume it, while any other host may ignore it without changing simulation.

## Interactive verification

Verify observable behavior through the real host router, native `Panel::input`/`Controller::input`, or typed WASM bridge:

- Render the deterministic initial frame at delivery size with production fonts. Check affordances, default state, units, target containment, reset, and exact face-to-region alignment.
- Exercise every control at its endpoints and intermediate state. For captured controls, test press, drag outside, release outside, completion, and cancellation. Persistent changes and reversals must begin from the currently composed state without snapping.
- For PointerFollow, test region corners and interior points, repeated retargeting, shortest-angle motion across the ±π boundary, leave, and cancellation. For KeyMove, test down/up, held motion without repeat, ignored platform repeat, opposite bindings, modifiers, focus loss, and teardown.
- In a combined host, prove that a captured UI gesture does not leak into Input, later unhandled motion does reach Input, cancellation cleans both, and keyboard/camera ownership stays with Input.
- For `State`, accumulate multiple ordered events in one frame, include a same-frame press/release, confirm transients clear only at the next `begin`, and verify `release` recovery. Run a multi-step catch-up frame and prove one edge is consumed once.
- For Runtime, exercise zero-step, one-step, maximum catch-up, and dropped-time advances. Force a failure after several staged updates and sounds; verify atomic rollback, the prior committed render, permanent failure, and unchanged behavior without Audio.
- Test only the build combinations relevant to delivery, while confirming each enabled header/library/Lua namespace/WASM member appears only with its sidecar. At minimum, prove every requested sidecar also works without unrelated sidecars.
- Recheck playback, pause, seek, loop boundaries, camera reset, resize/display scaling, reload, and disposal wherever the host supports them.

PNG, GIF, and MP4 do not capture future interaction. An export contains the authored timeline plus only the retained state that its export path explicitly samples. State that limitation and report the exact sidecars, host/runtime, interactions, release/reset paths, and unimplemented behavior outside the bounded overlay surface.
