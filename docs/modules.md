# Core, native modules, and host plugins

tmath keeps the deterministic scene sampler small and composes optional capability at
build or host packaging time. This follows ThorVG's Meson pattern: one array selects
named modules, every selected module owns its sources and dependency declaration, and
the core never reaches back into a module.

## Boundaries

| Layer | Owns | Must not own |
|---|---|---|
| `tmath` core | Object/Scene ownership, immutable clips, arbitrary-time sampling, Theme and Camera state, Viewport composition, backend-neutral DisplayList, renderer selection, sampled layout data | Diagram grammar, input devices, retained Lua callbacks, audio devices, editor protocol |
| Native module | One bounded C++ capability and its optional Lua hook | A second renderer, a private Scene graph, host networking, arbitrary render-time callbacks |
| Host plugin | VS Code UI, source navigation, editor state | Native Object ownership, renderer fallback, unvalidated code execution |

The native modules are separate static libraries and pkg-config units:

| Meson name | Library | Dependency rule |
|---|---|---|
| `ui` | `tmath-ui` | core only; Lua hook is optional |
| `input` | `tmath-input` | core only; Lua hook is optional |
| `runtime` | `tmath-lua-runtime` | Lua is required; Input is linked only when selected |
| `audio` | `tmath-audio` | core + private miniaudio implementation |
| `motion` | `tmath-motion` | core only; optional Lua hook when Lua is enabled |
| `diagram` | `tmath-diagram` | core only; lowers once to ordinary Objects |

`tools/vscode/` is a host plugin. It consumes public core or module contracts but is not
linked into `libtmath`. A host can therefore ship a renderer without game modules, or
an authoring CLI with Diagram but no Audio.

## Meson selection

Use `modules`, an array with the same named-selection shape as ThorVG's `engines`,
`loaders`, and `savers` options:

```sh
# Core, Lua binding, CLI, and the CPU renderer only; no native sidecars.
# (Native builds default to -Dengines=cpu,gl; GL is dropped with a warning on
# Emscripten or when no OpenGL is available.)
meson setup build-core -Dmodules='' -Dengines=cpu

# A publishing build with semantic authoring modules only.
meson setup build-author \
  -Dmodules=diagram -Dengines=cpu -Dbundled_thorvg=true

# An interactive retained host.
meson setup build-interactive \
  -Dmodules=ui,input,runtime,audio,motion -Dengines=cpu

# The complete native module matrix.
meson setup build-full -Dmodules=all  # engines default to cpu,gl
```

Animation exporters use the separate ThorVG-style `savers` selector. PNG snapshot
writing stays in core; `gif` and `video` select the corresponding timeline
encoders. Their public entry points remain ABI-stable and return `NonSupport` when an
implementation was compiled out.

```sh
meson setup build-web -Dmodules=diagram -Dsavers=gif -Dengines=cpu
meson setup build-minimal -Dmodules='' -Dsavers='' -Dengines=cpu
```

Native executables use `tools=cli,audit`. `audit` is a CLI subcommand and therefore
also selects the CLI shell; an empty selector builds libraries without installing the
native executable. Lua-disabled and Emscripten configurations omit the native CLI
regardless of the default tool set.

```sh
meson setup build-library -Dmodules='' -Dsavers='' -Dtools=''
meson setup build-publisher -Dmodules=diagram -Dtools=cli,audit
```

The earlier `ui`, `input`, `lua_runtime`, `audio`, and `diagram` options remain
accepted as compatibility aliases. New configurations should use `modules`; an
enabled alias is combined with the array. Omitting a name from `modules` excludes its
library, public header installation, Lua hook, CLI/WASM capability, module tests, and
private dependency unless its compatibility alias is enabled.

`motion` has no compatibility boolean. Selecting it always exposes its bounded C++
API; a Lua-enabled assembled host also receives `tmath.motion(scene)`. The Emscripten
host can therefore load Motion-enabled Lua without adding a direct JavaScript/C export.
Selection still does not imply a durable host-side event schema or automatic coupling
to the retained Runtime clock.

Selection is fail-closed:

- `runtime` without Lua is a configuration error;
- Emscripten still requires the CPU engine for the RGBA bridge;
- unavailable renderer backends never fall back to another backend;
- a Lua scene sees `tmath.diagram`, `tmath.motion`, `tmath.ui`,
  `tmath.input`, `tmath.runtime`, or `tmath.audio` only when the host assembled that
  hook.

## Adding a native module

1. Give it a bounded public header under `src/inc/` and implementation directory under
   `src/core/`.
2. Add one choice to `modules` and one conditional `subdir()` (with its define,
   dependency, and pkg-config entry) in `src/core/meson.build`.
3. Declare a standalone library/dependency in that directory's `meson.build`; depend
   on `tmath_dep`, never add the module source to `tmath_sources`.
4. Add its Lua hook through the existing bounded hook span only when Lua is enabled.
5. Link it explicitly into native CLI or WASM hosts and feature-detect its host API.
6. Verify core-only, module-only, and complete builds. An unavailable module must
   produce `NonSupport` or an absent host namespace, not a silent substitute.

Add an importer, AI tool, or editor as a host plugin
instead when it can operate on versioned data and public runtime APIs. Native dynamic
loading and a stable plugin ABI are intentionally not claimed by this compile-time
module contract.
