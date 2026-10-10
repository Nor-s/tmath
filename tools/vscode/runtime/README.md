# tmath WASM bundle

This directory is a portable, optimized tmath 0.1.0 browser runtime. Keep all files together when copying it into an application.

- Import `createTMath` and `tmath` from `client.js`.
- Author scenes with the JavaScript builder, or pass Lua source to `createTMath`.
- Use `object.label(options)` or Lua `object:label(config)` for an ordinary child Text that follows the Object; placement and styling stay explicit.
- Use `route(options)` or Lua `route(config)` for one marker-aware polyline; dashed shafts keep solid head/tail markers and one Create/Uncreate state.
- This build enables the Lua-only `tmath.diagram` authoring sidecar; it lowers into ordinary Scene Objects before rendering.
- Lua `grow_from_edge` and JavaScript `growFromEdge` keep a selected bounds edge fixed while revealing the perpendicular dimension.
- Serve browser applications over HTTP so the module can fetch `tmath-wasm.wasm`.
- Register `Pretendard.ttf` as `Pretendard` before rendering body text.
- Register `SourceSerif4-Semibold.ttf` as `Source Serif 4` for every semantic Text role in the VS Code host.
- Register `IBMPlexSansKR-SemiBold.ttf` as `IBM Plex Sans KR`; inherited Source Serif Text containing Korean switches to this family.
- Use `runtime.layoutReport(time, padding)` for root-pixel collision, clipping, stretch, and parent/child containment review across nested Viewports.
- This bundle enables independent UI and Input sidecars. Lua may use
  `tmath.ui.panel(scene)` for visible controls and `tmath.input.controller(scene)` for
  pointer-follow, key movement, and camera state; neither module depends on the other.
- `runtime.input(event)` routes owned pointer controls to UI first, then forwards
  unhandled pointer events and logical keydown/keyup to Input. Passive motion drives
  both Button hover and PointerFollow bindings.
- Input-enabled hosts may call `runtime.beginInputFrame(time)`, query
  `runtime.keyState(key)` / `runtime.pointerState(id)`, build named digital or 2D
  actions with `runtime.actionMap()`, and call `runtime.releaseInput(time)` on focus loss.
  The frame state and action layer has no UI dependency.
- Feature-detect `runtime.input` in builds with both optional modules disabled.
  `runtime.camera(...)` returns false when neither interactive sidecar is present.
- This build enables the experimental retained Lua Runtime. Only a source that calls
  `tmath.runtime(scene, config)` keeps its VM; feature-detect
  `runtime.advanceRuntime(elapsed)` and use `runtime.retainedLua` for the active Scene.
  The fixed-step result reports time, tick, steps, interpolation, and dropped elapsed
  time. Input actions remain optional and UI is not a Runtime dependency.
- This build enables Lua `tmath.motion(scene)` for named semantic states, capture-current
  retargeting, atomic multi-object transitions, and a bounded acknowledgement journal.
  Advance its independent interaction clock explicitly from a retained Runtime callback.
- In Node, pass the contents of `tmath-wasm.wasm` as the `wasmBinary` module option.
- Preserve the included Pretendard, Source Serif 4, and IBM Plex Sans KR OFL notices when redistributing the bundle.

`BUILD-MANIFEST.json` records the exact toolchain, enabled features, file sizes, and SHA-256 checksums.
