# VS Code scene delivery

Read the [tmath-skills scene contract](../../tmath-skills/references/scene-contract.md) and the relevant profile before this host-only delta. Scene generation—including animation, diagram, code, graphics, AI, cheatsheet, and short-form motion—belongs to `tmath-skills`; this reference adds fixed-Canvas delivery, FIT, source anchors, and series behavior.

## Fixed Canvas and theme

Lua creates one fixed logical Scene; resizing never reruns it. FIT is uniform (`min(available width / scene width, available height / scene height)`): it neither stretches nor crops. Choose aspect ratio from evidence geometry, editor-group shape, and hover legibility. Compact puts Canvas/Playback above the one Inspector; Wide reflows that same Inspector beside the player.

An explicit user style always wins. Otherwise, before creating any Object, apply built-in `adaptive_vscode` to every root and child Scene. The Preview supplies `Source Serif 4` and `IBM Plex Sans KR`; inherited Source Serif Text containing Korean switches as one complete Text object, while an explicit font remains authoritative. Use the scene contract's Theme text/color roles and preserve authored capitalization.

Use thin solid structure, negative space, and evidence geometry. Prioritize the actual Cell, Voxel, Surface, Vector, Picture, or other subject geometry. Do not recreate IDE chrome, thick-stroked boxes, card grids, badges, shadows, or a second viewer UI. The host already provides title, description, transport, source navigation, and series controls; keep them outside Canvas. Fixed/custom themes remain Scene-owned.

## Source and durable delivery

Inspect the product path and select one representative execution or causal scenario. Preserve its order in manifest `links`, Inspector entries, visible anchors, sections, and explanation. Each explicit range covers the smallest coherent input/condition, decisive operation, and immediate result/handoff; use separate ordered links for distant stages. Never use paths, tmath Lua, helpers, generated media, or authoring calls as subject evidence or `links`.

Put disposable frames, audit reports, and scratch exports in `temp/` beside the mapped animation; retain the scene, manifest, hover GIF, and requested output at durable paths. Verify initial, settled, clearance, range/loop-boundary, narrow/common/Wide/FIT/full-screen, and hover states. Check production-font bounds, containment, and that transport/Related Source remain outside Canvas.
