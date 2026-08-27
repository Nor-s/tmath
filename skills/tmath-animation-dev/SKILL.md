---
name: tmath-animation-dev
description: Develop, debug, test, and maintain the tmath engine, bindings, repository examples, and animation behavior from a tmath source checkout. Use for contributor work that needs repository paths, Meson builds, renderer diagnostics, or cross-language API synchronization; use tmath-skills for portable scene authoring.
---

# tmath Animation Development

Use this skill only inside a tmath source checkout. Repository paths, local build directories, internal tests, and implementation details belong here; never copy those assumptions into the distributable `tmath-skills` authoring skill.

## Workflow

1. Identify the affected public surface: C++, Lua, JavaScript/TypeScript, C/WASM, renderer/export, or documentation.
2. Before changing scene behavior, read the sibling [tmath-skills skill](../tmath-skills/SKILL.md) and the relevant language reference. It defines the user-facing authoring contract that must remain coherent.
3. Read [references/repository-workflow.md](references/repository-workflow.md) for source locations, build variants, targeted tests, render checks, and repository example work.
4. For any public API or lifecycle change, read [references/api-synchronization.md](references/api-synchronization.md) and update every affected binding, declaration, document, skill reference, and test in the same change.
5. Prefer a focused numeric, lifecycle, binding, or render invariant over a test that matches formatting or prose.

## Contributor invariants

- Treat `inc/tmath.h` as the C++ public contract, `src/bindings/lua/tmathLua.cpp` as the Lua mapping, and `wasm/bindings.js` plus `wasm/bindings.d.ts` as the typed JavaScript builder contract.
- Preserve ownership and sealing semantics across languages: successful attachment transfers ownership; timeline scheduling captures explicit state; Viewport and Scene-transition attachment seals and transfers child Scenes.
- Keep rendering deterministic at arbitrary sample times. Authoring callbacks may materialize retained data, but renderers must not execute user callbacks.
- Keep the public `tmath-skills` skill portable. It may mention installed modules or a CLI command available on `PATH`, but it must not require this repository's `build*`, `examples/`, `src/`, `test/`, or absolute filesystem paths.
- When an API is unsupported in one frontend, document that difference explicitly rather than inventing an equivalent call.
- Run the smallest relevant checks while iterating, then the full configured test suite and every affected native/WASM build before delivery.
