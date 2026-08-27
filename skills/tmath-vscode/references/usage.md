# Using the tmath VS Code extension

Use this for installation, ordinary Lua Preview, workspace mappings, editor actions, and troubleshooting. Implementation changes belong in [development.md](development.md).

## Run and open Preview

From `vscode/`, run `npm install` and `npm run compile`, open that directory in VS Code, press `F5`, and open the target workspace in the Extension Development Host. For a package, run `npm run package` and install the VSIX.

**tmath: Open Viewer** reveals the existing Viewer or opens one in `NO SCENE`, with every workspace series available. An editor-title action opens the active Lua Scene. Preview follows active Lua tabs, hot reloads edits, and reports Lua diagnostics. If the normalized workspace-relative Lua path uniquely matches a manifest `animation`, it receives the mapped title, description, Related Source, navigation, thumbnail, and series context; zero or ambiguous matches remain ordinary Preview.

Compact stacks Canvas and Playback above the unified Inspector. Wide activates at `600px` and falls back below `567px`; **Option → Compact Layout** can force the stack. The same Inspector, player, and state reflow—no second view is created. Vertical and horizontal sashes resize Wide player width and stage height; Reset clears manual size, FIT zoom, and pan.

The Inspector lists `NOTES` first, then Related Source in manifest order. The first source opens initially when present; otherwise Notes opens. Items expand independently. Each source body owns its scroll, context expansion, focused-range mark, and **SEE** action. **SEE** centers the exact range with a collapsed cursor in the editor group immediately right of Viewer; Diff uses VS Code's native Diff Editor. Series selection never moves source.

Previous/Next stay within the current group and do not wrap. **Auto-play Next** defaults disabled; when enabled it overrides Loop and wraps the final episode to the first without crossing groups. Series, settings, Canvas FIT/raw/reset, and document actions remain outside Canvas. **LUA** opens Scene implementation; **SOURCE** opens mapped product source.

The Preview registers `Source Serif 4` and `IBM Plex Sans KR`. Only a Scene using `adaptive_vscode` consumes live host colors; fixed/custom themes remain Scene-owned. Optional UI, Diagram, and Chart namespaces require synchronized module-enabled WASM and still produce the same ordinary Preview. Scene methods are documented in [tmath-skills](../../tmath-skills/SKILL.md); Canvas input is in [interactive-authoring.md](interactive-authoring.md).

## Lua IntelliSense

IntelliSense activates for the Scene followed by Preview and for any Lua document containing `tmath.scene`. Type `tmath.`, `scene:`, an Object/Group/Space handle followed by `:`, or a factory configuration field to get API-aware completions and snippets. Hover an API name for the generated documentation; use parenthesized calls for signature help. The provider tracks local variables returned by `tmath.scene` and Object factories so it can keep Scene, Object, Group, and Space methods distinct.

If suggestions are missing, confirm the file is Lua and contains `tmath.scene`, save it, inspect extension diagnostics, and reload the Extension Development Host after `npm run compile`. When changing the API metadata, keep completion, hover, signatures, generated Lua authoring metadata, and runtime validation synchronized; [development.md](development.md) owns that workflow.

## Playback and export

Use **RANGE → SET IN**, **SET OUT**, and **CLEAR** for a host playback interval. Restart, Loop, GIF, MP4, and hover GIF share it; PNG captures the current frame. A valid range survives same-document hot reload and clears on Scene change. Export through **tmath: Save Current Viewer as PNG/GIF/MP4**; GIF/MP4 prompt for `24`, `30`, or `60` FPS. The Webview contains no save controls. See [segment-playback.md](segment-playback.md).

## Manifest contract

Create `.vscode/tmath/visualizations.json` at the workspace root:

```json
{
  "version": 2,
  "visualizations": [{
    "source": "<product source>",
    "symbol": "<definition>",
    "animation": ".vscode/tmath/<series>/animations/<scene>.lua",
    "series": "<series>",
    "title": "<label>",
    "links": []
  }]
}
```

All paths are workspace-relative and use `/`, including on Windows. Every version-2 entry requires `series`; `animation` must be a direct Lua child of `.vscode/tmath/<series>/animations/`, with exact directory/value agreement. Legacy flat paths, nested animation directories, absolute paths, traversal, and backslash paths are invalid.

Fields:

- `source`, `symbol`: mapped product definition. Prefer a qualified symbol; optional one-based `line` disambiguates weak symbols or overloads.
- `animation`, `series`: Scene path and required ordered group.
- `title`, `description`: optional Viewer/CodeLens label and escaped Markdown Notes.
- `links`: execution-ordered product-source destinations. Each has `label`, `source`, and optional `symbol`, `range`, `line`, or `column`.
- `range`: one-based inclusive `startLine`/`endLine`; optional one-based `startColumn` and exclusive `endColumn` must appear together.
- `diff`: verified comparison requiring `range`, full `base` and `head` commit SHAs, and optional workspace-relative `oldPath` for a rename. The range addresses head/current source; see [diff-authoring.md](diff-authoring.md).

Resolution order is explicit `range`, explicit `line`/`column`, then full document-symbol range. Prefer the smallest coherent block containing local input/condition, decisive operation, and immediate result or handoff. Split distant stages into separate links.

Order `links` by representative runtime control/data flow or causal handoff, not file, declaration, or alphabetic order. For concurrent behavior, describe overlap rather than inventing a total order. Stable visible section identifiers may prefix corresponding labels, but never invent one only in the manifest. Never add the mapped animation Lua, helper Scene Lua, generated GIF, or authoring code to `links` or subject evidence.

## Editor actions and troubleshooting

Mapped definitions and Related locations receive CodeLens. Cursor dwell defaults to `400ms` and opens Preview without stealing focus; definition-provider paths beat name matching. Hover starts bounded local GIF generation when needed. A hover GIF preserves Scene aspect ratio inside an `800×800` maximum box and has at most `24` frames. Sidecars live beside Scene Lua and regenerate after active Scene saves or range changes.

Settings are `tmathPreview.codeVisualizations.autoOpen` (enabled by default), `tmathPreview.codeVisualizations.autoOpenDelay` (`100–2000ms`, default `400`), and `tmathPreview.codeVisualizations.hoverThumbnails` (enabled by default).

If CodeLens is absent, save and validate the manifest, check exact path case and symbol/line, enable Editor Code Lens, then reload after compilation. If hover has no image, allow one Preview render, re-hover, check sidecar writability and `hoverThumbnails`. If Preview fails, confirm the direct `.lua` path and inspect Lua diagnostics.
