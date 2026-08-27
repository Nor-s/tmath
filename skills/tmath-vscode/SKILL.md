---
name: tmath-vscode
description: "Develop, configure, test, package, and use tmath's VS Code extension: Lua Preview, IntelliSense, manifests, CodeLens, hover, source links, playback, and source-linked series. Use tmath-skills for scene content and tmath-game for input-driven scenes; use tmath-animation-dev for engine work outside `vscode/`."
---

# tmath VS Code

This is the editor host skill. Preserve the sandboxed Webview/WASM Preview and keep scene semantics in [tmath-skills](../tmath-skills/SKILL.md) or, for retained input/runtime behavior, [tmath-game](../tmath-game/SKILL.md). VS Code adds a fixed Canvas, FIT delivery, manifest source anchors, and series navigation; it does not create a second visual language or viewer mode.

## Route

- Read [usage.md](references/usage.md) to install or use Preview, write a manifest, use CodeLens/hover/source links, or diagnose Lua IntelliSense.
- Read [development.md](references/development.md) before changing extension providers, Lua completion/hover/signature help, manifests, Preview, Webview messages, source navigation, packaging, or tests.
- For every authored scene, read the [scene contract](../tmath-skills/references/scene-contract.md), a matching `tmath-skills` profile, [concept explainer](../tmath-skills/references/concept-explainer.md) for educational motion, then [animation-authoring.md](references/animation-authoring.md) for this host's delivery delta. For multiple Scenes or episodes, also read [series production](../tmath-skills/references/series-production.md). Use the `algorithm-and-code`, `graphics`, `ai-systems`, `cheatsheet`, `math-shortform`, and diagram references under `../tmath-skills/references/` as their evidence requires.
- Choose an ordinary animation for one temporal mechanism (`loop=false` by default); [editor-cheatsheet-authoring.md](references/editor-cheatsheet-authoring.md) when several verified regions must remain inspectable (`loop=true` by default); [short-form-authoring.md](references/short-form-authoring.md) only for an explicit short-form code-story request (`loop=false` by default). A tall Canvas or a request to be engaging is not short-form.
- Read [diff-authoring.md](references/diff-authoring.md) for revision evidence, [segment-playback.md](references/segment-playback.md) for range-aware playback/export, and [interactive-authoring.md](references/interactive-authoring.md) only for requested Canvas controls, direct manipulation, or interactive cameras.
- Route engine, renderer, binding, or cross-language API work outside `vscode/` to `tmath-animation-dev`.

## Host contract

- Manifest v2 at `.vscode/tmath/visualizations.json` maps source to a required `series` whose scene is a direct `.vscode/tmath/<series>/animations/<scene>.lua` child. Preserve path validation and execution-ordered `links`.
- Reuse the one `PreviewPanel`: fixed logical Canvas, uniform FIT, CPU WASM surface, Inspector, playback, hover, export, and source navigation. Keep filesystem/Git URIs, editor ranges, saves, and navigation host-owned; Webview messages are data-only and host-validated.
- Keep source evidence in the unified Inspector and native editor. Series selection changes only the Viewer; source reveal remains explicit **SEE** or **Document → Source**.
- Preserve ordinary Lua Preview, diagnostics, hot reload, assets, camera controls, timeline behavior, IntelliSense, manifest validation, and media export when changing mapped behavior.

## Verify

Run the smallest relevant check while iterating. Before delivery run `npm run check` and `npm test` from `vscode/`; inspect `npx vsce ls` or a VSIX for packaging changes.
