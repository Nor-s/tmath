# Developing the tmath VS Code extension

Read this guide when modifying the extension rather than only using it.

## Source map

- `tools/vscode/src/extension.ts`: activation, commands, providers, and diagnostics wiring.
- `tools/vscode/src/languageProvider.ts`: tmath Lua completion, hover documentation, and signature help.
- `tools/vscode/src/visualizationProvider.ts`: manifest loading, CodeLens, hover action, Preview launch, and source-link context.
- `tools/vscode/src/visualizationManifest.ts`: workspace-safe manifest parsing and validation.
- `tools/vscode/src/symbolLocator.ts`: document-symbol resolution and definition-text fallback.
- `tools/vscode/src/thumbnailCache.ts`: deterministic keys used to authenticate thumbnail messages.
- `tools/vscode/src/thumbnailPath.ts`: mapped Lua-to-GIF sidecar naming.
- `tools/vscode/src/previewTarget.ts`: validates explicit command URI candidates and falls back to the active editor URI.
- `tools/vscode/src/previewPanel.ts`: Webview lifecycle, Lua document following, scene payloads, diagnostics, source navigation, and command-driven media export.
- `tools/vscode/src/gitSnapshots.ts`: read-only VS Code Git API bridge, exact checkout/snapshot verification, and native Diff Editor navigation.
- `tools/vscode/src/unifiedDiff.ts`: pure unified-patch parsing and post-change range projection.
- `tools/vscode/media/main.js` and `main.css`: Preview UI behavior and presentation.
- `tools/vscode/media/time.mjs`: testable time clamping shared by Preview playback behavior.
- `tools/vscode/media/playback-range.mjs`: range validation, hot-reload clamping, boundary editing, and deterministic playback stepping.
- `tools/vscode/media/series-step.mjs`: pure current-group Previous/Next series target resolution.
- `tools/vscode/media/source-inspector.mjs`: data-only source-context normalization, selection, and code-line rows for the bottom Inspector.
- `tools/vscode/media/markdown.mjs`: dependency-free, escaped Markdown rendering for visualization descriptions.
- `tools/vscode/media/viewer-layout.mjs`: testable normal-mode stage-height allocation and viewport-bound floating-menu placement.
- `tools/vscode/media/viewport.mjs`: FIT, zoom, and camera transforms applied to the fixed-size scene canvas.
- `tools/vscode/media/canvas-input.mjs`: the sole Canvas pointer, wheel, keyboard, pointer-capture, Panel-first, and camera/FIT fallback router.
- `tools/vscode/webview/thumbnail-plan.mjs`: bounded hover image dimensions, timing, and frame sampling.
- `tools/vscode/webview/export-plan.mjs`: deterministic media-export frame timing.
- `tools/vscode/schemas/visualizations.schema.json`: editor validation and completion for workspace manifests.
- `tools/vscode/test/visualization-manifest.mjs`: manifest contract tests.
- `tools/vscode/README.md`: distributable user documentation.

The bundled Preview runtime is built explicitly with `-Dengines=cpu`. Its Canvas2D, hover
thumbnail, export, layout, and interactive sampling paths all consume the same RGBA
surface. Keep `createTMath(..., {renderEngine: "cpu"})` implicit or explicit in this
host. A future GL Preview must first add an Emscripten WebGL context handle, a GL
target lifecycle, direct presentation, and deterministic pixel readback; it must
recreate the DOM Canvas when switching context type and must not fall back to CPU.

When the shipped runtime supports native semantic authoring, configure the WASM build with `-Ddiagram=enabled` in addition to the existing CPU/Lua options. This module adds a Lua construction namespace only: it lowers into the same Object graph before the authoring VM closes and require no Preview message, renderer, Canvas, or manifest branch. Keep a module-disabled engine build working. Synchronize the complete WASM artifact set, build manifests, generated Lua authoring metadata, and module-enabled tests whenever its binding contract changes.

## Code-linked preview flow

1. `VisualizationProvider` loads manifest version 2 from `.vscode/tmath/visualizations.json` for the source document's workspace. The parser accepts an entry only when its required `series` exactly owns a direct `.vscode/tmath/<series>/animations/<scene>.lua` child.
2. It matches declarations directly by workspace-relative path. At a use site, it asks VS Code for the symbol definition and matches the returned source path against the primary `source` or a related link.
3. Each related link resolves its explicit one-based `range` first, its explicit `line`/`column` second, and the full `DocumentSymbol.range` last. The full symbol range supplies contextual source rather than only the symbol-name selection.
4. A debounced selection listener can open that reference without taking editor focus; CodeLens or the trusted hover link invokes the same command explicitly.
5. The command verifies the animation file and opens it through the existing `PreviewPanel` with source context and a deterministic thumbnail key.
6. After a successful render, the Webview downsamples a bounded GIF and posts its key plus data URL to the extension host.
7. The extension host validates the key, host-owned target, GIF signature, and size before writing a `scene.gif` sidecar beside `scene.lua`. Hover Markdown reads only that derived workspace URI.
8. The Webview receives related-source labels, escaped excerpt text with display-only metadata, ordered series-group and episode labels, active indices, and safe description text; source URIs remain host-only. It toggles Inspector disclosures independently or switches the series group locally. Keep every disclosure summary at the Inspector's full width with only its chevron and title. Put path, focused range, optional Diff inserted/removed marks, and **SEE** in an indented child code header; **SEE** may post only its validated Related index. Give each expanded excerpt its own bounded horizontal and vertical scroll and preserve both offsets by stable source identity across Inspector-only refreshes; the Inspector retains its own disclosure-list vertical scrolling. The host targets the editor group immediately right of the Viewer and reuses it for subsequent destinations as ordinary tabs. Bounded SHOW requests keep the original focus metadata and preserve the visible anchor within the excerpt; closing a disclosure sends a validated reset and restores its base excerpt. Series selection, Previous, and Next never reveal source implicitly. The extension host validates every value before resolving stored context and centering it in the native editor with a collapsed cursor. Do not add a native range decoration. Explicit **SEE** and **Document → Source** remain unconditional.
9. Ordinary Lua Preview and active-Lua-tab following ask the same provider to reverse-resolve the normalized workspace-relative Lua path against `animation`. A unique match receives the same Preview context and series catalog; an absent or ambiguous match remains a plain Lua scene.

Do not send filesystem paths into Webview HTML, accept arbitrary command payload paths, or let manifest paths escape the workspace.

Keep this source context in the existing `PreviewPanel` unified Inspector. Do not add a new VS Code View, fixed side panel, embedded editor, or separate diff surface. Compact places it below the player and Wide reflows the same DOM to the right; neither layout creates another Inspector. A Diff link changes only its opened accordion body to unified diff rows; **SEE** delegates full comparison to VS Code's native Diff Editor. The title remains visible above one scroll owner. Put `NOTES` first, then execution-ordered Related source entries; open the first source when one exists and `NOTES` otherwise, then allow any number of items to remain expanded independently. Canvas Full Screen hides the complete Inspector.

## Preview layout and interaction invariants

- Keep one fixed, zero-margin, zero-padding viewport grid; never duplicate DOM or state for responsive modes. Compact stacks the edge-to-edge Canvas and Playback above the Inspector. Wide begins at a `600px` Webview width and returns to Compact below its safe `567px` two-column minimum, independent of Scene dimensions. Persistent **Option → Compact Layout** choices default to `DISABLE`. Wide keeps Canvas and opaque Playback in the left player and the same Title and Inspector on the right. Its vertical sash preserves at least `280px` for each column when possible; the Inspector defaults to `32%`, clamped to `280–380px`. Narrow transport rules respond to the player column, not the whole Webview.
- Keep the Canvas edge-to-edge. Playback has an eight-pixel horizontal inset; the Inspector header and disclosure summaries have a fourteen-pixel inset. Code rows remain edge-aligned inside the active body, outer margins remain zero, the title row stays compact, and extra spacing belongs between Markdown blocks.
- In Compact, calculate the automatic FIT stage cap from viewport size, Scene ratio, measured transport, and the horizontal sash—never description length or rendered line count. In Wide, keep Scene ratio out of the player grid row and measure the left stage itself after automatic or manual resizing. Observe stage resize directly. The horizontal sash sits immediately above Playback in both modes; its first pointer or keyboard adjustment enters manual height. Clamp only enough to keep Playback and the sash reachable, preserve requested pixels across responsive changes, and allow a Wide docked series list to collapse fully. Do not add a persistent manual-state label or idle color. The status area may show Canvas size and FPS. Canvas Reset clears both manual dimensions and restores the current layout plus the active FIT/1:1 mode's default zoom and position without changing Stat visibility.
- Follow VS Code toolbar behavior: transparent icon buttons at rest, `icon.foreground`, subtle `toolbar.hoverBackground` and `toolbar.hoverOutline`, `toolbar.activeBackground` while pressed, and `focusBorder` for keyboard focus. A persistent toggle uses `aria-pressed`, semantic accent, and a non-color-only state mark rather than a filled primary button. Use accessible inline SVG, not emoji, brand color, ornamental shadow, or an overloaded transport.
- Keep `NOTES` and Related source in one independently expandable, scroll-owning disclosure list. Summaries occupy the full Inspector width and show only chevron and title, without separators or open-state edge rules. Each expanded excerpt owns bounded native horizontal and vertical scrolling and preserves both offsets by stable source identity across Inspector-only refreshes; preserve the Inspector's position too. Ordinary vertical wheel input stays with an excerpt while it can scroll, then returns to Inspector navigation; never convert it to horizontal movement. Keep the Inspector title and root `html`, `body`, and `.viewer` overflow-hidden so scrollbar changes cannot reflow Markdown during resize.
- Keep Previous, Series, and Next together immediately before settings. The Series summary is always reachable. Wide docks the one existing non-empty series panel below Playback; opening it as a popup temporarily moves that same panel, and closing returns it to the dock. Compact and Canvas Full Screen use the same viewport-bound popup. Group selection and episodes retain independent scrolling and one selection state. Manual Previous/Next stay within the group without wrapping; Auto-play Next defaults disabled, takes precedence over Loop when enabled, wraps the last episode to the first, and never crosses groups or reveals source. Every selection path uses validated group and item indices.
- Pre-position settings and series popups before native `details` opens, hide them until placement is ready, clamp each cascading panel independently to the viewport, and keep triggers clickable. Menus are opaque and above the Wide sash. Settings stays a narrow single-column context menu: Stat first; Stat, Speed, Camera, Range, Option, and Document as cascades; explicit complete alternatives with the current choice disabled; direct Canvas FIT, raw-size, and reset actions last. Do not restore Reveal Source or Full Screen/Windowed settings. Apply the same placement lifecycle to pointer, keyboard, assistive, and programmatic opens.
- Keep the bundled, unmodified `SourceSerif4-Semibold.ttf` and `IBMPlexSansKR-SemiBold.ttf` registered as `Source Serif 4` and `IBM Plex Sans KR`. Fixed and custom Scene themes remain Scene-owned. Only `adaptive_vscode` consumes the live editor palette and rebuilds after a workbench-theme change; preserve explicit per-Text fonts and authored capitalization.

## Change checklist

For manifest changes:

- Update `visualizationManifest.ts` and keep partial invalid entries from becoming runnable command payloads.
- Keep the required series name and its `.vscode/tmath/<series>/animations/<scene>.lua` path synchronized; do not restore the legacy flat animation directory or an implicit standalone group.
- Reject absolute paths, traversal through `..`, backslash paths, nested animation subdirectories, and any mismatch between the required `series` and its direct animation directory.
- Update `visualizations.schema.json` to match runtime validation.
- Extend `visualization-manifest.mjs` with valid and invalid examples.
- Update both `tools/vscode/README.md` and `references/usage.md` when the user-facing contract changes.
- For `links[].diff`, require exact full commit SHAs and a head-relative explicit range. Resolve snapshots through the read-only built-in Git extension API, compare blobs directly rather than using three-dot branch diff semantics, and keep a mismatch unavailable.
- Support a verified added file only when the base commit resolves, the current path is absent from its tree with Git's `UnknownPath`, no distinct `oldPath` was supplied, and the checked-out current file equals the head blob. Render its requested current range as inserted rows and use an empty previous document for native Diff navigation; do not create or hash a synthetic blob in the repository.

For Preview messages:

- Use VS Code semantic Webview variables (`--vscode-*`) for player chrome, menus, Related source accordion summaries, Inspector title/code, and Markdown instead of targeting exact theme IDs. Use toolbar tokens for icon and summary hover/active states, `icon.foreground` for icons, `focusBorder` for keyboard focus, editor-widget tokens for menus, and editor tokens for code. Keep disclosure summaries free of separators and open-state edge rules. Present each state or mode as explicit alternatives, disable the current choice, and persist user preferences in Webview plus extension global state. Keep fixed and custom Canvas themes untouched. For `adaptive_vscode` only, resolve the semantic editor, status, focus-border, and chart colors into the host palette: chart categories drive the peer-object cycle, chart yellow drives `result`, and focus border drives `focus`. Rebuild the Scene after a workbench-theme change.
- Add the payload or message type in `previewPanel.ts` and its matching handler in `media/main.js`. Keep forced Compact layout disabled by default, mirror immediate values in Webview state, and persist each user choice through extension global state. Series messages carry only validated group and item indices and never move the native editor; source navigation is explicit through **SEE** or **Document → Source**.
- Validate message shapes and indices in the extension host.
- Send only escaped source and diff lines plus display metadata to the Webview. Keep source URIs and resolved editor ranges in host-owned state and accept only a validated link index or bounded context-expansion action from Related source controls. Let Source and Diff bodies request 5 more current-file lines above or below a stable reference ID by default, and persist one validated 5, 10, or 20-line **Show Lines** choice for both directions. Validate the Scene, index, ID, direction, and preference message in the extension host before returning a refreshed excerpt. Keep the focused range in summary metadata and preserve the prior visible line when prepending context. Preserve exact column bounds and center the range with a collapsed native-editor selection; do not apply a range decoration. Represent an out-of-date explicit range as unavailable instead of displaying the file prefix, and update excerpts after Related source edits with a debounced Inspector-only message rather than recompiling the unchanged Scene.
- Preserve the existing Content Security Policy. Trust command links only for `tmathPreview.openVisualization` and the validated `tmathPreview.openVisualizationSource` navigation command.
- Keep thumbnail generation bounded and opportunistic; failures must never interrupt live Preview or media export.
- Keep media save entry points as VS Code commands. The extension host requests an export from the current Webview and retains control of the native Save dialog.
- Preserve ordinary Lua hot reload, diagnostics, assets, camera controls, timeline behavior, and export behavior while changing code-linked Preview.

For playback-range changes, follow [segment-playback.md](segment-playback.md). Keep one validated range model shared by playback, restart, scrubbing, hover thumbnails, and export. Test edge cases independently of the DOM before wiring the player UI.

For experimental interactive-Canvas changes, follow [interactive-authoring.md](interactive-authoring.md). Keep the native UI module optional, feature-detect the WASM `input` export, and preserve a working UI-disabled runtime. Add Canvas listeners only through `canvas-input.mjs`; test logical-coordinate conversion, handled fallback, capture/release, cancellation, and animation-frame redraw coalescing outside the full Preview DOM.

For provider behavior:

- Keep providers restricted to file documents and cheap for files absent from the manifest.
- At use sites, trust definition-provider paths over name matching. Use the leaf symbol name only as an unambiguous fallback when definition data is unavailable.
- Invalidate manifest caches and CodeLens when the manifest is created, changed, or deleted.
- Preserve multi-root workspace ownership when resolving paths.
- Debounce cursor-triggered opens, preserve editor focus, suppress automatic missing-file notifications, and cancel stale asynchronous opens.
- Prefer an explicit manifest range for a focused causal excerpt. Otherwise preserve an explicit one-based line/column override, then use the full document-symbol range for Inspector context and retain the smaller selection range only for precise editor reveal when appropriate.

## Commands

Run from `tools/vscode/`:

```bash
npm run check
npm test
```

`npm test` compiles the extension and Webview, validates the manifest parser and generated Lua API metadata, tests Preview utilities, thumbnail planning, export codecs, and bundled runtime seeking.

For package inspection:

```bash
npx vsce ls
npm run package
```

Confirm package contents include `out/visualizationProvider.js`, `out/visualizationManifest.js`, `out/symbolLocator.js`, `out/thumbnailCache.js`, `out/thumbnailPath.js`, `schemas/visualizations.schema.json`, `media/`, and `runtime/`.
