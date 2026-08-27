---
name: tmath-skills
description: "Author portable, source-grounded tmath scenes in Lua or JavaScript/TypeScript: animation, diagrams, algorithm/code traces, 2D/3D graphics, AI systems, cheatsheets, and math shorts. Use tmath-game for input, retained runtime, audio, or games; tmath-vscode for the VS Code host; tmath-animation-dev for engine, build, bindings, or C++ work."
---

# tmath authoring

Create deterministic visual evidence with the public Lua or JavaScript/TypeScript API available in the user's host. Do not depend on source-checkout paths, build products, or C++ authoring APIs.

## Read only what changes the scene

1. Always read [scene-contract.md](references/scene-contract.md).
2. Choose exactly one API: [lua.md](references/lua.md) for a `.lua` Scene, or [javascript.md](references/javascript.md) for JS/TS and browser/WASM hosts.
3. Read only a matching evidence profile: [diagram.md](references/profiles/diagram.md), [algorithm-and-code.md](references/profiles/algorithm-and-code.md), [graphics.md](references/profiles/graphics.md), [ai-systems.md](references/profiles/ai-systems.md), [cheatsheet.md](references/profiles/cheatsheet.md), or [math-shortform.md](references/profiles/math-shortform.md).
4. For educational motion, read [concept-explainer.md](references/concept-explainer.md). Additionally read [equation-derivation.md](references/equation-derivation.md) when symbolic steps or geometry prove an equation, and [series-production.md](references/series-production.md) when the result needs several Scenes or episodes.
5. For the bundled browser distribution only, read [wasm-bundle.md](references/wasm-bundle.md).

## Route boundaries

- `tmath-game`: UI/Input, action maps, retained runtime, audio, simulation loops, or game state. This skill may make only the minimal host hook needed to mount a finished authored scene.
- `tmath-vscode`: Preview, extension manifests, editor navigation, CodeLens/hover, packaging, or the required `adaptive_vscode` host theme.
- `tmath-animation-dev`: engine/build/renderer/binding/C++ work, repository examples, or public-surface synchronization.

## Author and review

Before code, decide whether a still or motion is the better proof and whether one Scene or a series is needed; for animation, write a 3–7 beat ledger. Treat the routed contract and profiles as acceptance gates.

Use the Theme priority in the contract before creating visible objects and in every child Scene. Prefer geometry (`Cell`, `Voxel`, `Surface`, `Vector`, `Image`, or other shapes) to explanatory Text and boxes; use thin solid structure and negative space rather than decorative cards, heavy shadows, or rounded panels.

Resolve `TMATH_FONT` to the delivery font; for CLI-only review, `assets/wasm/Pretendard.ttf` is a broad-coverage fallback. Repeat this matrix at the initial state, decisive beats, maximum density, and exact final time:

```sh
TMATH_FONT=/absolute/path/to/production-font.ttf
tmath inspect scene.lua
TMATH_TIME=0
tmath render scene.lua --time "$TMATH_TIME" --font "$TMATH_FONT" -o temp/review.png
tmath layout scene.lua --time "$TMATH_TIME" --padding 4 --font "$TMATH_FONT"
python3 /path/to/tmath-skills/scripts/audit_text_layout.py scene.lua \
  --cli tmath --font "$TMATH_FONT" --canvas-inset 4
```

Adapt command paths and extensions to the actual host. Review normal-speed playback plus the exact final frame; for a loop, compare decoded seam pixels at `t=0` and the exact boundary. Deliver source, requested export, represented claim/variant, checks performed, and unverified limitations.
