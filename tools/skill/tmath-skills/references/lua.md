# Lua API

Use this reference when producing a `.lua` scene or Lua source loaded by an application. The host injects `tmath` as a global; never call `require`, `import`, `package`, or dynamic loading. The script must return one root Scene.

Create the root with `tmath.scene {width, height, fps, loop, theme, camera}` and return that Scene. Omitted `theme` is standalone Pro White; a VS Code scene explicitly uses host-resolved `"adaptive_vscode"` unless the user selects another style. Fixed preset tokens are `"pro_white"`, `"pro_black"`, and the original dark `"3_blue_1_eyes"`. An authored 2D `camera` uses `mode="fixed"`, `view="2d"`, `target`, and world-unit `height`; 3D also accepts `eye`, `up`, `projection="orthographic"|"perspective"`, `fov`, `near`, and `far`. `mode="interactive"` is host-driven and belongs to `tmath-game`. Scene dimensions are raster pixels while object positions are world coordinates; follow the mapping contract in `scene-contract.md`. Vectors are positional Lua arrays `{x,y}`/`{x,y,z}`: read them as `v[1]`, `v[2]`, `v[3]`, never `v.x`. Ranges are `{min,max,step}`. Colors accept `#rgb`, `#rgba`, `#rrggbb`, and `#rrggbbaa`.

A Mat4 is exactly 16 finite numbers in row-major order and multiplies the column point `[x,y,z,1]`. Translation therefore occupies entries 4, 8, and 12: `{1,0,0,tx, 0,1,0,ty, 0,0,1,tz, 0,0,0,1}`. Use this representation for Group/Space `matrix`, Composite Play `transform`, and `scene:transform`; each is an absolute local-to-parent transform, not a delta.

## Factories

Scene and every Object handle expose the same child factories. The receiver becomes the direct parent.

| Factory | Essential fields |
|---|---|
| `group` | optional `matrix`; paintless semantic container |
| `space` | `x`, `y`, `z`, `matrix`, axes, grid/number styling |
| `point` | `point` and pixel `radius` |
| `line` | `from`, `to` |
| `arrow` | `from`, `to`, optional pixel `tail`, `tip` |
| `vector` | `value`, optional `origin`, `tail`, `tip` |
| `circle` | optional `center`, world-unit `radius` |
| `rectangle` | optional `center`, `size={width,height}`, `corner` |
| `polygon` | at least three `points` |
| `plot` | `points`, or `fn` with inclusive `x_range` |
| `route` | at least two ordered `points`, optional pixel `tail`, `tip`; style dash applies only to the shaft |
| `path` | one contour of move/line/quadratic/cubic/close `commands` |
| `curve` | `from`, `control1`, `control2`, `to`, optional `samples` |
| `surface` | row-major `points`, `size={columns,rows}`, mode and shading |
| `text` | `text`, point, font, pixel size, align, role, orientation |
| `picture` | `asset` (registered name, or svg/png/jpg/webp path relative to the script) or inline `pixels` + `size`, center, world-unit width, filter; SVG stays vector when scaled |
| `cell` | dense color grid; `size={columns,rows}`, optional origin, color, patches, `mode="full"|"padd"`, fractional padding |
| `connector` | `from` and `to` handles, padding, tail, tip |

`object:label(config)` is an Object-only semantic alias for creating one ordinary child `Text` with the complete Text configuration. It does not auto-place the label, bind paint/layer, or create a renderer-specific primitive. Primitive geometry does not move the child origin: an identity-model Rectangle at `center={cx,cy}` needs `point={cx,cy}`, `align={0.5,0.5}`, and an explicit foreground `layer` for a centered visible label. The returned Text participates in layout, animation, inspection, and ownership exactly like `object:text(config)`.

Path `commands` are keyed records: `move`/`line` use `to`; `quadratic` adds `control`; `cubic` adds `control1` and `control2`; `close` closes the contour.

Factory configs share `id`, `color`, `stroke`, `fill`, `gradient`, `width`, `radius`, `dash`, `dash_offset`, `opacity`, `progress`, and `layer` where the Object supports them. Stroke thickness is the screen-pixel field `width`; `stroke_width` and `line_width` are not Object options. Author `Route` and `Connector` with explicit `stroke`, especially under `create`, rather than relying on generic `color`. Cell uses its own `color`/patch surface and rejects stroke/fill styling.

`gradient` accepts `true`/`false`, an end-stop color (legacy two-stop linear ramp from the paint color), or a table: `{type = "linear"|"radial"|"conic", stops = {"accent", "warning"} | {{0, "accent"}, {0.5, "#fff"}, {1, "warning"}}, ...}` with kind-specific geometry `from`/`to` (linear, both or neither), `center`/`radius`/`focal`/`focal_radius` (radial), or `center`/`angle` (conic, degrees clockwise from +x). Stops: 2 to 8, bare colors spaced evenly, offsets non-decreasing in 0..1; stop alpha is multiplied by the stroke/fill alpha, so filled gradients need an opaque `fill`. Geometry is local and follows the object's transform; omitted geometry derives from the shape (radial: bbox center and half-diagonal or the circle; conic: bbox center, angle 0). Unknown or mismatched keys are errors. See `src/examples/lua/gradient_kinds.lua`.

## Layout

Call `move_to`, `next_to`, `align_to`, `arrange`, or `arrange_grid` before the first timeline operation. Next To and Align To require siblings; Arrange and Arrange Grid require a Group.

## Timeline API

```lua
scene:play(descriptor_or_array, duration, curve, lag)
scene:create(target_or_array, duration, curve, lag, direction)
scene:uncreate(target_or_array, duration, curve, lag, direction)
scene:write(target_or_array, duration, curve, lag, direction)
scene:fill_reveal(target_or_array, duration, curve, lag)
scene:draw_border_then_fill(target_or_array, duration, curve, lag, direction)
scene:fade_in(target, {shift = vector, scale = number, duration = seconds, curve = curve})
scene:fade_out(target, {shift = vector, scale = number, duration = seconds, curve = curve})
scene:grow_from_center(target, duration, curve)
scene:grow_from_edge(target, "bottom", duration, curve)
scene:shrink_to_center(target, duration, curve)
scene:indicate(target, {color = color, scale = number, duration = seconds, curve = curve})
scene:morph(source_or_array, target_or_array, duration, curve, lag)
scene:replacement_transform(source_or_array, target_or_array, duration, curve, lag)
scene:fade_transform(source, newly_attached_target, duration, curve)
scene:shift(target, parent_vector, duration, curve)
scene:transform(target, absolute_local_to_parent_mat4, duration, curve)
scene:fade(target, opacity, duration, curve)
scene:transition(outgoing, incoming, duration, curve)
scene:stroke(target, color, duration, curve)
scene:fill(target, color, duration, curve)
scene:look(camera_target, duration, curve)
scene:wait(duration)
scene:remove(target)
local seconds = scene:duration()
```

Composite `play` changes several properties in one clip per distinct Scene-owned target. A descriptor may use `shift` or `transform`, never both, and may also set `opacity`, `stroke`, `fill`, `dash_offset`, `tail`, and `tip`. A `dash_offset` target needs a non-empty pattern; `tail` and `tip` require Arrow, Vector, Connector, or Route and stay solid when its shaft is dashed. A seamless linear flow cycle advances by exactly one complete dash-and-gap period.

For an array animation, `duration` applies to every target and `lag` delays each later target, so the scheduled span is `duration + lag * (count - 1)`. Use `scene:duration()` or `inspect` for the actual final time; do not estimate delivery length by summing comments.

Animation durations must be positive; only `wait` and sampled-field construction may use zero. Never encode setup as a tiny `transform` or `fade`: set the factory `matrix`, geometry, or pre-timeline layout directly, and use an entrance operation at the intended beat for later objects. `create`, `write`, and `fade_in` hide their targets automatically before the scheduled reveal, while an object without an entrance animation is visible at `t=0`. Leave one coherent opening group unanimated; do not entrance-animate every object or leave orphaned labels. Schedule later facts only in their evidence beat, then render `t=0` again after the complete timeline is authored.

Curve values may be a preset string, `{preset=..., strength=..., reverse=true}`, or `{bezier={x1,y1,x2,y2}, strength=...}`. Create direction accepts `forward`, `reverse`, `clockwise`, or `counterclockwise`.

Use `fade_transform` when unrelated object families represent one replacing identity. Attach the target at the current cursor immediately before the call. The target is hidden automatically during earlier samples; after the cross-fade the source is consumed and the target remains live. Use `transition` when independent outgoing and incoming handles should merely cross-fade without replacement ownership semantics.

## Cell and Voxel sampling

For a static dense grid, use `scene:cell {origin={x,y}, size={columns,rows}, color=..., mode="padd", padding=0.06, patches=...}`. `origin` is the lower-left grid corner and cells are one world unit before parent transforms. A patch is `{region={column,row,width,height}, color=...}` with zero-based unsigned cell coordinates. `padding` has the same normalized `[0,0.5)` contract below.

Only Space exposes `cell(function(x, y, time), config)` and `voxel(function(x, y, z, time), config)`. The Space must declare sampled `x={min,max,step}` and `y={min,max,step}` ranges; Voxel also requires `z`. For an `n`-column unit grid use `x={0,n-1,1}`. The callback receives those range values. Config accepts non-negative `duration`, positive integer `fps`, `mode="full"|"padd"`, and normalized per-cell `padding` in `[0,0.5)`—padding is not pixels. Callbacks return a color, stay pure, use ordered deterministic data, and run during construction rather than rendering.

```lua
local grid = scene:space {x = {0, n - 1, 1}, y = {0, rows - 1, 1}}
local cells = grid:cell(function(x, y, time)
    return colors[y * n + x + 1]
end, {duration = 0, fps = 30, mode = "padd", padding = 0.06})
```

## Viewports and Scene transitions

Complete a child Scene before `parent:viewport(child, {x, y, width, height})`; attachment transfers and seals it. Use `root:scene_transition(scenes, {duration, hold, curve, viewport})` for sequential full-scene replacement.

## Game and retained-runtime boundary

Ordinary Lua scenes are construction-only and return one root Scene. UI, Input, action maps, retained callbacks, audio, host-driven mutation, and game loops belong to `tmath-game`; do not rebuild Lua source for each input event. A finished authored scene may be mounted by the game host through its documented hook.

## Optional Motion module

A Lua-enabled host built with `-Dmodules=motion` adds one Scene-owned semantic
controller through `tmath.motion(scene)`. Guard it before use. Define complete named
relative overlays during construction, then retarget and explicitly advance its
independent clock:

```lua
if not tmath.motion then
    error("this scene requires a tmath build configured with -Dmodules=motion")
end

local motion = tmath.motion(scene)
motion:define(card, "card.idle", {})
motion:define(card, "card.correct", {
    shift = {0, 0.12}, scale = {1.08, 1.08}, opacity = 1,
})
motion:transition(card, "card.correct", 0.18, "smooth")
motion:advance(1 / 60)
local visible = motion:sample(card)
```

Methods are `define`, `transition`, `transition_many`, `advance`, `sample`, `time`,
`active`, `definition_count`, `event_count`, `event`, and `clear_events`. `define` is
construction-only. A retained callback may use the others, but Runtime does not call
`motion:advance(dt)` implicitly. Keep the returned handle in a local captured by the
callback. An accepted batch produces one bounded acknowledgement event per physical
target; its shared `transaction` is decimal text and is not a durable command log.
Built-in timeline exporters do not advance this side clock, so use authored clips for
portable shorts or a host-driven two-clock capture for live semantic motion.

## Optional Diagram module

A host may add `tmath.diagram(scene, config)` for bounded ranked, manual, grid, or timeline topology. It builds once into an ordinary Object subtree and fail closed when unavailable; ordinary Object construction remains available. Follow [diagram native authoring](diagram/native-authoring.md) for the bounded Lua surface.

## Runtime limits

The Lua environment is bounded and deterministic. Use arrays with `ipairs`; do not rely on file, OS, package, debug, dynamic loading, hash-order iteration, or arbitrary updater APIs. Native file paths are host-dependent; a native `picture`/`cell` asset name is read as a file path relative to the script. When assets or fonts come from memory, the host must register them before loading an asset-dependent scene.
