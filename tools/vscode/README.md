# tmath Preview

Preview tmath Lua scenes beside their source in Visual Studio Code. The extension runs the repository-pinned tmath WebAssembly renderer entirely inside a sandboxed Webview; no preview server is required.

## Use

1. Open a tmath `.lua` scene.
2. Click the tmath preview icon in the editor title bar.
3. Edit the Lua file. The canvas refreshes from the unsaved document after a short debounce.

Run **tmath: Open Viewer** from the Command Palette to open the same Viewer without choosing a Lua file. A newly opened Viewer starts in its empty `NO SCENE` state, loads named series from the active workspace, and can open an episode directly or follow a Lua scene later.

While the side view remains open, selecting another Lua tab switches the preview immediately. Hot reload builds each edited scene in an isolated runtime and only swaps it into view after a successful load, so an incomplete edit cannot corrupt the last valid canvas or its seek state.

The extension also provides tmath-aware IntelliSense for the scene followed by the side view and for any Lua document containing `tmath.scene`. Type `tmath.`, `scene:`, or a factory configuration field to get API completions and snippets; hover an API name for documentation, and use parenthesized calls for signature help. Local variables created by `tmath.scene` and object factories are tracked so Scene, Object, Group, and Space methods can be suggested separately.

The built-in providers work without another extension. For deeper project-wide type inference with [Lua Language Server](https://luals.github.io/), run **tmath: Enable LuaLS Type Definitions** once per workspace. This copies the bundled generated metadata to VS Code's extension storage and adds that stable directory to the workspace `Lua.workspace.library` setting. The metadata is generated from the same API schema used by the built-in providers. A workspace `.luarc.json` takes precedence over VS Code settings, so add the displayed metadata directory to that file instead when one is present.

The Preview chrome follows the active VS Code color theme through semantic Webview tokens while the Canvas preserves the Scene's own theme. Canvas backing resolution adapts to Preview zoom and display pixel ratio without changing logical size. The root HTML never scrolls and reuses one player and Inspector across two responsive layouts. Compact stacks the edge-to-edge Canvas and Playback above the Title and unified Inspector. Wide begins at 600px and returns to Compact below the safe 567px two-column minimum, keeps Canvas plus opaque Playback in the left player, and places the same Inspector on the right. **Option → Compact Layout → ENABLE** forces Compact regardless of width. A non-empty series catalog docks below Wide Playback, while the Series button temporarily opens that same panel in the viewport-bound popup and returns it to the dock when closed. Compact and Canvas Full Screen use the popup directly. Drag the vertical divider to resize the complete Wide player, or drag the horizontal sash above Playback in either layout to set Canvas height. Automatic Compact sizing uses all available space above Playback without a description-length reservation. Manual height keeps Playback reachable and may collapse a Wide docked playlist to zero, so the Series popup remains available; Reset restores automatic sizing.

The Inspector uses one scroll-owning disclosure list: `NOTES` comes first, followed by manifest `links` in execution order, with a small gap below the Viewer title. The first source opens when links exist and `NOTES` otherwise. Notes and any number of source entries can then remain expanded together. Every summary occupies the complete Inspector width without separators or open-state edge rules and shows only its chevron and title. Its indented child code header contains the source path and range, optional green/red Diff marks, and right-aligned **SEE**. Each excerpt owns bounded horizontal and vertical scrolling, so long code cannot disturb another item. Ordinary **SEE** opens the focused current range in the adjacent editor group; Diff **SEE** opens VS Code's native Diff Editor. GitHub-style controls reveal 5 lines at a time by default above or below Source and Diff ranges; **Show Lines** changes that shared step to 5, 10, or 20. Series selections, Previous, and Next update only the Viewer. Settings uses opaque, clamped cascading menus with one vertical column: each state alternative is a complete full-width action, Option properties are separated, and the current action is disabled. Reveal Source and Full Screen/Windowed are removed. `CANVAS TO FIT WINDOW`, `CANVAS TO RAW SIZE`, and `RESET LAYOUT` are the direct bottom actions. Right-clicking the Canvas opens the same viewport-bound settings menu beside the pointer.

To focus playback on one interval, scrub to its beginning and choose **RANGE → SET IN**, then scrub to its end and choose **SET OUT**. The seekbar highlights the active interval. Restart returns to its start; Loop wraps from its end to its start; non-loop playback stops at the end. **CLEAR** restores the full scene. The range belongs to the current viewer, survives a valid hot reload of the same Lua scene, and clears when another scene is loaded.

Save the current viewer from the Command Palette with **tmath: Save Current Viewer as PNG**, **GIF**, or **MP4**. PNG saves the displayed frame; GIF and MP4 sample only the active playback range and ask for 24, 30, or 60 FPS. Encoding happens locally in the Webview with progress shown in the player status; MP4 uses the WebCodecs implementation included with VS Code. Export is capped at 3840×2160, 3600 frames, and 268 million sampled pixels.

Use `CANVAS TO FIT WINDOW` or `CANVAS TO RAW SIZE` to change only the Webview display scale; the active choice is disabled. `RESET LAYOUT` clears manual Canvas height and Wide width, recalculates automatic sizing, and restores the active display mode's default zoom and position. While FIT is active, the mouse wheel applies a damped zoom around the pointer and middle-button drag pans the enlarged canvas. Wheel zoom never shrinks the canvas below its automatic FIT scale, and choosing FIT resets the interactive zoom and pan. Outside FIT, a preview larger than the panel retains its ordinary horizontal and vertical scroll area and the wheel does not change its display scale. Vertical overflow always receives an ordinary Y-wheel gesture first. Only when a Preview surface has horizontal overflow and no vertical scroll range does that Y gesture scroll horizontally; this applies to the series group rail and a non-FIT Canvas. Related source excerpts keep independent native two-axis scrolling and do not convert Y-wheel input into horizontal movement. Native horizontal-wheel gestures remain unchanged. Display transforms never change PNG/GIF/MP4 export dimensions.

For scenes authored with `camera = {mode = "interactive", ...}`, drag to pan in 2D or orbit in 3D and use Shift-drag to pan. Arrow keys pan, `+`/`-` zoom the Scene camera, `2`/`3` switch views, and `R` resets it. The menu shows the current camera policy and disables controls for fixed-camera scenes.

The bundled runtime also includes the independent tmath Input sidecar. It does not
create controls or depend on UI. One `tmath.input.controller(scene)` can map passive
pointer motion and keydown/keyup events directly to ordinary Scene Objects. Pointer
mapping uses logical Canvas pixels and an explicit parent-space basis; each newest
sample starts a smooth Scene-time transition, including shortest-path `atan2` heading.
Keyboard bindings accept Arrow, Space, Enter, Escape, Shift, Tab, A–Z, 0–9, Plus, and Minus:

```lua
local input = tmath.input.controller(scene)

input:pointer_follow {
    target = direction_marker,
    region = { 80, 90, 800, 420 },
    target_origin = { 0, 0, 0 },
    map_origin = { -4, 2.1, 0 },
    map_x = { 8, 0, 0 },
    map_y = { 0, -4.2, 0 },
    period = 0.18,
    rotate = true,
    reset_on_leave = true,
}

input:key_move {
    target = movable_object,
    key = "ArrowRight",
    shift = { 0.5, 0, 0 },
    period = 0.12,
}
```

Input and UI are separate optional libraries and Lua namespaces. Preview composes
both: UI receives pointer control events first, captured controls keep ownership, and
only unhandled events continue to Input; pointer-cancel reaches both for cleanup. Input owns key movement and interactive-camera
state in this combined runtime. An Input-only host can move Objects without a Panel;
a UI-only host can render controls without linking Input. A declared KeyMove binding
holds movement from the first keydown until keyup, with a short acceleration ramp and
no dependency on platform repeat delay or rate. It consumes its logical key before the
Preview's camera-key fallback, so use WASD when the
Arrow keys should continue to pan the camera. Ctrl, Alt, and Meta combinations remain
available to VS Code and the operating system. A pointer press on the Canvas transfers
keyboard focus to the Viewer; passive hover and automatic Preview opening do not steal
focus from the source editor.

The bundled JavaScript runtime also exposes frame-oriented input independently of the
Lua Controller: `beginInputFrame(time)`, `keyState(key)`, `pointerState(id)`,
`actionMap()`, and `releaseInput(time)`. A host begins a frame, forwards queued normalized
events through `runtime.input`, samples named actions, advances its own fixed-step
simulation, and then draws. Pressed/released edges, pointer delta, and wheel delta clear
at the next frame boundary while held state persists. The Preview calls `releaseInput`
when focus is lost or its input router is disposed, preventing a missed keyup from
leaving retained state active. These methods require an Input-enabled bundle and do not
introduce a UI dependency.

The bundled runtime also includes the experimental tmath UI sidecar. A Lua scene may create one `tmath.ui.panel(scene)` and add declarative Button, Toggle Button, Slider, and SampleArea controls whose regions use logical Canvas pixels. `panel:toggle_button` retains one bounded boolean and alternates one target between explicit `off` and `on` transforms. Passive pointer motion updates Button hover state before camera fallback, while pointer capture keeps slider drags and SampleArea clicks coherent outside their initial point. A Button-family control can select distinct Theme-authored `visual`, `hover_visual`, and `pressed_visual` Objects without mutating their styles. Give every control independent, non-nested face Objects; state faces cannot be shared within a Panel. Object transforms, sampled swatch fill, and camera deltas compose after the authored timeline is sampled, so interaction never rewrites the Lua-authored definition. For example:

```lua
local panel = tmath.ui.panel(scene)

panel:button {
    visual = reset_face,
    hover_visual = reset_hover_face,
    pressed_visual = reset_pressed_face,
    region = { 20, 450, 80, 40 },
    camera = "reset",
}

panel:toggle_button {
    visual = branch_toggle_face,
    region = { 120, 450, 80, 40 },
    target = subject,
    off = {},
    on = { opacity = 1, shift = { 0.5, 0, 0 } },
    value = false,
    duration = 0.45,
}

panel:slider {
    visual = slider_face,
    region = { 230, 440, 300, 56 },
    target = subject,
    from = { scale = { 0.6, 0.6, 1 } },
    to = { scale = { 1.5, 1.5, 1 } },
}

panel:sample_area {
    region = { x = 90, y = 90, width = 360, height = 360 },
    targets = { gradient_disk },
    marker = sample_marker,
    marker_origin = { -2.4, 2.4, 0 },
    marker_x = { 4.8, 0, 0 },
    marker_y = { 0, -4.8, 0 },
    swatch = enlarged_pixel,
}
```

A Slider may replace its top-level `target`/`from`/`to` with
`bindings = {{target=thumb, ...}, {target=subject, ...}}`. Every item receives the same
clamped normalized value with independent transform endpoints, so a visible thumb and
several affine evidence Objects remain synchronized. The forms are mutually exclusive
and every item counts against the Panel-wide 256-binding limit.

`targets` must contain one to 64 distinct candidate Objects owned by the Panel's root Scene, with no ancestor/descendant pair. A completed primary click samples the current Scene at the release point, current playback time, and current backing-store density after existing Panel Object/fill/camera state has been composed. The runtime input result exposes `sample.position = {x, y}`, normalized `sample.value = {x = u, y = v}`, `sample.rgba = [r, g, b, a]`, and `sample.object = {handle, id, type}`. `sample.object` identifies the configured topmost candidate, not an individual descendant paint. Its RGBA is the candidate-family composite straight raster color under the Scene's antialiasing policy, isolated from the background and all non-family Objects. Only a successful sample commits the new output state. The optional marker stays hidden until that first success, must be a childless Object or Group, and receives the parent-space runtime shift `marker_origin + marker_x * u + marker_y * v`; the optional `swatch` must be a non-gradient Rectangle and receives that RGBA as a runtime fill override. Marker and swatch families must remain independent from every candidate and every other control-bound Object family. Neither output Object is required, so runtime host code may consume the sample result without an authored marker or swatch. A miss produces no new runtime sample and preserves the previous successful outputs.

The single Canvas router forwards every successful immutable snapshot through its `onSample` callback. The built-in viewer posts that snapshot to the extension host, where `PreviewPanel.currentSample()` exposes the latest validated result for subsequent VS Code features. A renderer failure is returned separately as `input.error`, reported through the router's `inputError` hook, and still preserves pointer release; it is not treated as a transparent miss.

Ordinary Lua callbacks are not retained after scene loading. Use `tmath.input` for
declarative continuous pointer/key motion and `tmath.ui` for visible controls and
sampling. The bundled experimental Runtime makes one explicit exception:
`tmath.runtime(scene, config)` retains a protected VM, and Preview advances its bounded
fixed-step callback while playing. That callback may atomically update only Object
transform, opacity, progress, and solid fill overlays; Scene/Object/UI/Input authoring
remains locked. A Toggle Button still retains only its bounded boolean and target
transforms inside Panel. SampleArea remains click-only and does not provide a 3D ray,
world/local hit point, or depth intersection. Always choose an understandable
deterministic initial state because hover GIFs and video exports cannot reproduce
future live input.

The bundled runtime also exposes the optional semantic Motion controller as
`tmath.motion(scene)`. Define complete named Object overlays while constructing the
scene, then call `motion:transition(...)` from retained decisions and
`motion:advance(dt)` exactly once per fixed step. Motion owns an independent clock;
Preview's Runtime does not advance it implicitly. The controller captures the visible
overlay when interrupted, supports atomic `transition_many` batches, and exposes a
bounded native acknowledgement journal. Keep its Lua handle captured by the retained
callback. Ordinary timeline-only series should continue to bake their motion into
`scene:play` clips so seeking, hover GIFs, and GIF/MP4 export remain portable.

Relative `asset = "..."` and `texture = "..."` values are loaded from the Lua file's directory. The bundled Pretendard, Source Serif 4 Semibold, and IBM Plex Sans KR SemiBold fonts are registered automatically. Webview text uses Source Serif 4 for Latin glyphs and IBM Plex Sans KR for Korean glyphs, including controls, titles, descriptions, and code context. The `adaptive_vscode` Canvas Theme selects Source Serif 4 for every semantic Text role. A Text containing Korean is automatically assigned IBM Plex Sans KR when it is attached to the Scene; an explicitly authored font remains unchanged. A fixed or custom Scene Theme remains Scene-owned. For a non-adaptive Scene that wants the same policy, select Source Serif 4 on all roles:

```lua
theme = {
    preset = "adaptive_vscode",
    text = {
        h1 = { font = "Source Serif 4" },
        h2 = { font = "Source Serif 4" },
        h3 = { font = "Source Serif 4" },
        text = { font = "Source Serif 4" },
        code = { font = "Source Serif 4" },
    },
}
```

Source Serif 4 does not contain Korean glyphs. The runtime therefore selects IBM Plex Sans KR for the complete Text object when it contains Korean, including mixed Korean/Latin text. Preserve natural authored capitalization—an `h2` or `h3` role never implies ALL CAPS or title case.

## Code-linked visualizations

The extension can attach a tmath animation to a function definition in any workspace source file. Create `.vscode/tmath/visualizations.json` and give each series its own flat `animations` directory. Opening a mapped Lua scene directly—or following it as the active Lua tab—also restores its manifest title, description, Related source accordion, and series catalog when exactly one entry names that animation:

```text
.vscode/tmath/
├── visualizations.json
├── software-fill/
│   └── animations/
│       ├── tvggSwFill.function.lua
│       ├── tvggSwFill.function.gif  # generated automatically
│       └── tvggRaster.rasterize.lua
└── compositing/
    └── animations/
        └── tvggComposite.lua
```

```json
{
  "version": 2,
  "visualizations": [
    {
      "source": "src/renderer/tvg/tvggSwFill.cpp",
      "symbol": "tvg::SwFill::function",
      "animation": ".vscode/tmath/software-fill/animations/tvggSwFill.function.lua",
      "series": "software-fill",
      "title": "SwFill function",
      "description": "# Software fill\n\nShows how the raster operation transforms one span.",
      "links": [
        {
          "label": "SwFill declaration",
          "source": "src/renderer/tvg/tvggSwFill.h",
          "symbol": "tvg::SwFill::function"
        },
        {
          "label": "Raster call site",
          "source": "src/renderer/tvg/tvggRaster.cpp",
          "range": {
            "startLine": 184,
            "endLine": 202
          }
        }
      ]
    },
    {
      "source": "src/renderer/tvg/tvggRaster.cpp",
      "symbol": "tvg::rasterize",
      "animation": ".vscode/tmath/software-fill/animations/tvggRaster.rasterize.lua",
      "series": "software-fill",
      "title": "Raster stage",
      "links": [
        {
          "label": "Fill stage",
          "source": "src/renderer/tvg/tvggSwFill.cpp",
          "symbol": "tvg::SwFill::function"
        }
      ]
    },
    {
      "source": "src/renderer/tvg/tvggComposite.cpp",
      "symbol": "tvg::composite",
      "animation": ".vscode/tmath/compositing/animations/tvggComposite.lua",
      "series": "compositing",
      "title": "Composite output"
    }
  ]
}
```

All paths are relative to the workspace root. Manifest version 2 requires every entry to have a `series`, and its animation must be a direct Lua child of `.vscode/tmath/<series>/animations/`; the directory name and `series` value must match exactly. Entries with the same `series` form one ordered Lua series in manifest order. The Series trigger is always visible between Previous and Next and shows the active episode position; without manifest entries it opens a `NO SERIES` state. Otherwise it opens a two-level catalog: every named series appears in a compact top rail that scrolls horizontally without a visible scrollbar, and the selected series' numbered `#01`, `#02`, … episodes appear in the independently scrollable list below. Wide docks this catalog below Playback by default, but the trigger temporarily moves the same catalog into the popup and closing it restores the dock. Choosing a group or episode updates the Viewer and Inspector without moving the source editor; use the opened code header's **SEE** action for explicit navigation. Previous and Next step only within the current group, disable at its boundaries, and never wrap. **Option → Auto-play Next → ENABLE** overrides Loop and advances cyclically inside the active series, including final item → item 0; `DISABLE` is the default. A **Preview animation** CodeLens appears above the matching definition. Related entries that specify a `range`, `symbol`, or `line` receive the same CodeLens, animated hover, Preview action, and accordion context. A hover at a call or other use site also resolves through VS Code's definition provider to the mapped visualization. The player opens only when you click CodeLens, a hover Preview action, the Lua editor Preview button, or run **tmath: Open Viewer**. Opening files, moving the cursor, and hovering never open the player. Hover images use existing sidecars generated after an explicitly opened Preview renders. Optional `description` is escaped Markdown displayed in the first `NOTES` accordion item.

Each related `links[]` entry may define a focused code region:

```json
{
  "label": "Clip spans",
  "source": "src/renderer/tvg/tvggRaster.cpp",
  "range": {
    "startLine": 184,
    "endLine": 202
  }
}
```

`startLine` and `endLine` are required one-based inclusive lines. Optional one-based inclusive `startColumn` and exclusive `endColumn` must be supplied together. Resolution prefers an explicit `range`, then an explicit one-based `line`/`column`, then the complete range reported for `symbol` by the document-symbol provider. Use `range` for a focused causal excerpt and `symbol` when the complete function is the useful context.

A revision-dependent link can add a verified Diff Range. `range` always addresses the post-change `source`, while `base` and `head` are full 40-character Git commit SHAs:

```json
{
  "label": "Dispatch ownership",
  "source": "src/renderer/tvg/tvggRaster.cpp",
  "range": {
    "startLine": 184,
    "endLine": 202
  },
  "diff": {
    "base": "1111111111111111111111111111111111111111",
    "head": "2222222222222222222222222222222222222222"
  }
}
```

For a rename, keep `source` as the current path and add the previous workspace-relative path as `diff.oldPath`. The extension reads the exact blobs through VS Code's built-in Git extension and shows the comparison only while the repository HEAD and current target file match the declared head snapshot. Removed rows come only from the base blob. A deletion-only comparison anchors its manifest range to the nearest surviving current line. Missing revisions, checkout drift, local edits, invalid paths, and ranges without a real change produce `DIFF UNAVAILABLE` rather than guessed or substituted code.

The Inspector keeps `NOTES` first and Related source entries after it in one independently expandable list. Clicking a source title shows or hides its escaped, Shiki-highlighted child code area without closing another item. The summary stays title-only; the child header carries the path, focused range, and **SEE**. A Diff header also carries green inserted and red removed marks, while its body renders unified rows with previous/current line numbers and VS Code semantic diff colors. Ordinary **SEE** opens the exact current source region; Diff **SEE** opens VS Code's native Diff Editor with the base blob on the left, verified current file on the right, and focus on the current range. A file verified as absent from the base commit renders its requested current range as inserted rows against an empty previous document. `SHOW 5 LINES ABOVE` and `SHOW 5 LINES BELOW` are the bounded context actions for both Source and Diff bodies. **Show Lines** can switch both directions to 5, 10, or 20 lines without sending the complete file into the Webview. Series navigation never moves the source editor implicitly. Column-bounded ranges preserve their exact syntax span, and editing open Related sources refreshes every expanded excerpt without recompiling the Scene. Invalid source evidence and stale Git comparisons are shown as unavailable instead of substituting unrelated content. Source and Git URIs remain in the extension host; the Webview returns only a validated source index. This reuses the existing `PreviewPanel` and native editor—there is no new VS Code View, fixed side panel, embedded code editor, or separate Diff Viewer.

Hovering a mapped symbol starts generation of a compact animated GIF when one is missing (inside an 800×800 maximum box, up to 24 frames, and a three-second loop). Definitions, declarations in other workspace files, and ordinary use sites share the visualization when their unqualified function name maps unambiguously. The GIF is a workspace sidecar beside the animation (`scene.lua` → `scene.gif`), so an existing local file is used without a global cache. The first hover reports generation in progress; move away and hover again after the Preview renders. Editing the mapped Lua scene refreshes both the live Preview and its hover animation. Setting or clearing a playback range regenerates that sidecar from the selected interval, making a focused beat usable for long-scene hovers. In the settings menu, **Document → Lua** opens the current animation and **Document → Source** returns to the mapped definition. Only optional `links` appear in the Related source accordion; their Inspector excerpts use the explicit range, line/column override, or full symbol range whether editor navigation is enabled or not.

The extension uses the editor's document symbols when available and falls back to source-text matching. Add a one-based `line` to the visualization entry when a symbol is overloaded or the language server cannot identify the intended definition. The manifest has bundled JSON validation and completion support.

The behavior can be adjusted with **tmath Preview** settings:

- `tmathPreview.codeVisualizations.hoverThumbnails` — generate and show animated hover GIFs; defaults to `true`.

The Command Palette exposes **tmath: Open Viewer** as the single Viewer entry point. The Lua editor-title icon remains the direct action for opening the active scene. Additional commands are:

- **tmath: Refresh Preview** — force a reload of the current document.
- **tmath: Save Current Viewer as PNG/GIF/MP4** — export the scene currently loaded in the viewer.
- **tmath: Open Bundled Runtime Folder** — reveal the packaged WASM, fonts, and licenses.
- **tmath: Enable LuaLS Type Definitions** — enable generated tmath types in Lua Language Server.

## Development

```sh
cd vscode
npm install
npm run compile
```

Press `F5` from the `vscode` folder to launch an Extension Development Host. Build an installable package with:

```sh
npm run package
```

The panel and live-document synchronization follow the same broad integration pattern as [ThorVG LiveView](https://github.com/thorvg/thorvg.vscode), adapted for tmath's Lua-to-canvas WASM runtime.
