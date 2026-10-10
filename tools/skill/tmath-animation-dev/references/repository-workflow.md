# Repository workflow

This reference is intentionally tied to a tmath source checkout.

## Source map

- Public C++ API: `src/inc/tmath.h`; C ABI: `src/inc/tmath_capi.h`.
- Scene ownership and timeline: `src/core/scene/tmathScene.cpp`, `src/core/scene/tmathObject.cpp`, and internal scene headers.
- Lua binding: `src/core/lua/tmathLua.cpp`.
- JavaScript builder and runtime: `src/bindings/js/bindings.js`, `src/bindings/js/client.js`, and their `.d.ts` files.
- C/WASM bridge: `src/bindings/wasm/tmathWasm.cpp`.
- ThorVG lowering/rendering: `src/core/renderer/`; savers: `src/core/savers/`.
- Executable scenes: `src/examples/lua/`.
- Contracts and tests: `docs/`, `src/test/`.
- Meson (ThorVG-style): root `meson.build` holds options, feature flags, ThorVG/Lua, and `subdir()` calls. Each folder owns its `meson.build`: folders under `src/core/` append to `tmath_sources`/`tmath_inc`; `src/core/meson.build` builds the library and optional modules; `src/meson.build` adds pkg-config; `src/cli/` and `src/bindings/wasm/` configure the CLI and WASM runtime (declared at the root to keep `build/tmath` and `build/tmath-wasm.js`); tests are tables in `src/test/meson.build`, `src/examples/meson.build`, and `tools/skill/meson.build`. A new source file means editing only its folder's `meson.build`; a new example or skill template means one table entry.

Search before editing. Follow a public method from its declaration through the binding/compiler, core implementation, renderer or saver if applicable, and existing tests.

## Build matrix

Use the configured directory that matches the change; do not silently reconfigure a user's existing build.

```sh
meson compile -C build-full
meson test -C build-full --print-errorlogs
meson compile -C build-wasm
```

The ordinary `build` directory is useful for a fast native loop. `build-full` is the repository's broad native configuration, and `build-wasm` checks Emscripten integration.

For a new checkout, inspect `meson_options.txt` and the README before selecting options. Keep bundled ThorVG, Lua, the `cpu`/`gl` engine list, test, and example choices explicit when they affect the result.

Treat build capability and runtime selection as separate contracts. Validate renderer
work against fresh `-Dengines=cpu`, `-Dengines=gl`, and
`-Dengines=cpu,gl` (the native default) directories; `gl-parity` (macOS) bounds CPU vs GL pixel differences per scene. `Renderer::gen(engine)` must preserve the requested
backend and reject a missing module or mismatched target without fallback. Runtime
`Renderer::defaultEngine()` stays CPU. Emscripten builds drop GL automatically; keep the
distributed WASM and VS Code runtime CPU-only until a complete WebGL target
and readback bridge exists.

For a future WG engine, extend the internal renderer registry with a real adapter and
an unavailable-build stub, then add its source selection in `src/core/renderer/meson.build`. Do not introduce WG
calls into backend-neutral Scene lowering or the CPU/GL adapters, and do not publish a
WG enum or target type before that path can render without fallback.

## Targeted verification

- Math or camera behavior: numeric C++ tests first.
- Ownership, layout, animation, or renderer behavior: scene tests plus a deterministic render invariant.
- Lua surface: load and render a representative `.lua` file.
- JavaScript builder/runtime: TypeScript declarations and `src/test/testJsBinding.mjs`.
- C/WASM bridge: C API tests and the WASM build.
- Media saver: parse the output and validate dimensions, timing, supported families, and failure behavior.

Repository examples are executable tests, not screenshots. Preserve stable IDs, deterministic data, semantic colors, and a readable final hold. When changing one example's native Lua and browser-embedded version, keep their intent and timing aligned.

## Render and layout checks

Use the CLI built by the selected directory:

```sh
build-full/tmath inspect path/to/scene.lua
build-full/tmath render path/to/scene.lua --time 1.25 -o review.png
build-full/tmath layout path/to/scene.lua --time 1.25 --padding 4
```

Register the repository's test font when text bounds matter. Inspect start, representative midpoint, transition boundaries, and final frames. Treat intended containment or connector contact differently from unrelated overlap.
