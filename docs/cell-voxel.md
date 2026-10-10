# Cell and Voxel coordinate fields

`cell` and `voxel` sample a `Space` coordinate/time lattice during authoring and materialize the result as colored planar cells or spatial voxels. They are useful for implicit equations, scalar fields, occupancy maps, and other demonstrations where a color can be computed independently for every coordinate and time sample.

The APIs belong to `Space` because the Space defines the ranges, sampling steps, coordinate transform, and axes that give callback values meaning. `cell` samples X/Y and returns a paintless `Group` with one batched `Cell` on Z=0. `voxel` samples X/Y/Z and returns one batched `Cell` per Z slice. Neither API creates one Object per coordinate, so the returned Group remains practical to animate and transform.

Lua and JavaScript overload `Space.cell`: an options table/object creates one manually authored `Cell`, while a callback samples an X/Y field. `Space.voxel` always takes an X/Y/Z callback.

## Lifecycle and determinism

The callback is an authoring-time sampler, not code executed by ThorVG during rendering and not a per-frame updater.

1. The API validates the relevant Space ranges, Cell mode, `duration`, and `fps`.
2. With the default `duration=0`, it calls the callback once per coordinate at `time=0`.
3. With a positive duration, it retains `ceil(duration * fps) + 1` uniformly spaced frames, including exact `time=0` and `time=duration` endpoints. Sampling order is frame/Z/Y/X for Voxel and frame/Y/X for Cell.
4. It snapshots the returned colors into one planar Cell or Z-sliced Cell objects.
5. It attaches one completed Group to the Space, advances the Scene cursor by `duration`, and discards the callback.
6. Rendering and export linearly interpolate retained RGBA frames; they never call user code.

This keeps an arbitrary-time render deterministic and makes the result identical whether frames are requested forward, backward, or out of order. Calling either API on an attached Space creates the Group at the Scene's current timeline cursor. A positive `duration` occupies that interval, just like an animation helper; after its end the last field frame is held. Calling it on a detached C++ Space makes it part of that detached subtree, and attaching the subtree later advances the Scene by the longest temporal field it contains. On failure, no partial field Group is attached and the output Group is null.

The root Scene's normal `loop` policy controls playback. A temporal Cell or Voxel field does not own a separate clock and does not wrap its own time.

Treat the callback as a pure coordinate-to-color function. Lua and JavaScript reject Scene/Object authoring from inside the callback so their preflighted Object and memory budgets cannot change during construction. C++ rejects recursive sampling and `add` calls on the same Space; caller-owned `data` must not mutate the Scene graph through another route.

JavaScript follows the same contract. Its callback runs synchronously while the `SceneBuilder` definition is authored. The builder serializes the resulting color array into its generated Lua source, which then enters the same bounded Lua/C++ construction path. The JavaScript function is not retained by the WASM runtime.

## Sampling and field geometry

Each axis is aligned to the Space lattice around zero:

```text
first = ceil(range.min / range.step) * range.step
value(i) = first + i * range.step
```

The maximum value is inclusive with a small floating-point tolerance. `cell` calls Y then X and places cells on a single Z=0 layer. `voxel` calls Z, Y, then X. Callback coordinates are Cell/Voxel centers. A 2D cell has local size `(x.step, y.step)`; a 3D voxel has local size `(x.step, y.step, z.step)`. The Space model and all ancestor models place the field in the Scene. A color whose alpha is zero remains in the sampled buffer but emits no visible paint.

`mode="full"` fills the complete Cell/Voxel footprint. `mode="padd"` leaves a proportional gap controlled by `padding`; padding must be in `[0, 0.5)`. The default is `mode="padd", padding=0.05`.

Resource limits are enforced before construction:

- at most 4,096 samples on one axis;
- at most 16,384 X/Y cells in one Z slice;
- at most 65,536 coordinate samples (`cell` uses one slice);
- at most 4,096 retained time frames;
- at most 262,144 retained coordinate/color samples across all frames;
- Lua additionally applies the Scene's shared Object and native-memory budgets.

Use `cell` with a 2D camera for planar equations. Use `voxel` with a 3D camera to see samples as boxes.

## C++

The native callback returns `true` after writing `color`. Returning `false` aborts the complete operation. `data` is passed through unchanged for caller-owned state.

```cpp
static bool circle(float x, float y, float, tmath::Color& color, void*) noexcept
{
    color = x * x + y * y <= 2.25f
          ? tmath::Color::hex("#0891b2")
          : tmath::Color::hex("#00000000");
    return true;
}

tmath::Group* cells = nullptr;
auto result = space->cell(circle, cells);
```

The spatial form adds Z to the callback:

```cpp
static bool sample(float x, float y, float z, float time, tmath::Color& color,
                   void*) noexcept
{
    auto radius = 1.0f + time * 0.5f;
    color = x * x + y * y + z * z < radius * radius
          ? tmath::Color::hex("#2563eb")
          : tmath::Color::hex("#00000000");
    return true;
}

auto space = tmath::Space::gen({-2, 2, 0.25f},
                               {-2, 2, 0.25f},
                               {-2, 2, 0.25f});
tmath::Group* voxels = nullptr;
auto result = space->voxel(sample, voxels, nullptr,
                           tmath::CellMode::Padd, 0.08f,
                           {1.0f, 24u});
if (result == tmath::Result::Success) scene->add(space);
```

After success, the Space owns the returned Group. Do not delete it separately. If a later `Scene::add(space)` fails, the caller still owns the complete Space subtree.

The public callback and timing types are `CellSampler`, `VoxelSampler`, and `SampleTime`.

## Lua

The callback must return `#rgb`, `#rgba`, `#rrggbb`, or `#rrggbbaa`. A callback error or invalid color aborts construction without leaving a partial subtree.

```lua
local field = scene:space {
    x = {-2, 2, 0.25}, y = {-2, 2, 0.25}, z = {-2, 2, 0.25}
}

local duration = 1.5
local circle = field:cell(function(x, y, time)
    local a = 1.5 + 0.5 * time / duration
    return x*x/(a*a) + y*y/2.25 <= 1 and "#0891b2" or "#00000000"
end, {duration=duration, fps=24})

local voxels = field:voxel(function(x, y, z, time)
    local radius = 1.0 + 0.5 * time
    if math.sqrt(x*x + y*y + z*z) > radius then return "#00000000" end
    return y < 0 and "#2563eb" or "#7c3aed"
end, {mode="padd", padding=0.08, duration=1, fps=24})
```

## JavaScript and TypeScript

The typed facade returns a `GroupHandle` for sampled fields:

```js
const field = scene.space({
    x: [-2, 2, 0.25], y: [-2, 2, 0.25], z: [-2, 2, 0.25],
});

const duration = 1.5;
const circle = field.cell((x, y, time) => {
    const a = 1.5 + 0.5 * time / duration;
    return x*x/(a*a) + y*y/2.25 <= 1 ? "#0891b2" : "#00000000";
}, {duration, fps: 24});

const voxels = field.voxel((x, y, z, time) => {
    const radius = 1 + 0.5 * time;
    if (Math.hypot(x, y, z) > radius) return "#00000000";
    return y < 0 ? "#2563eb" : "#7c3aed";
}, {mode: "padd", padding: 0.08, duration: 1, fps: 24});
```

The public types are `CellSampler`, `CellSampleOptions`, `VoxelSampler`, and `VoxelSampleOptions`. Callbacks must be synchronous and return a color string; asynchronous callbacks and mutable render-time state are intentionally unsupported.

## Time-varying fields and Morph

Use the callback's final `time` argument for field animation. Shape occupancy may change by returning transparent colors outside the time-dependent equation, while visible colors can change at the same samples. The renderer interpolates every corresponding retained Cell or Voxel between adjacent samples.

Sampled Groups are retained containers with children, so the ordinary geometry Morph API intentionally returns `NonSupport` for them. Morph remains restricted to compatible childless Polygon, Plot, Path, and Curve geometry. This avoids a second competing time model and removes the need to allocate duplicate source and target fields.

See the [circle-to-ellipse Cell example](../src/examples/lua/cell_field.lua) and [sphere-to-ellipsoid Voxel example](../src/examples/lua/voxel_field.lua). Their editable Lua/JavaScript versions are in the WASM Playground under **tmath**.
