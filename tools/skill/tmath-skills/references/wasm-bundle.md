# Bundled WASM runtime

Use skill-relative `assets/wasm/` only when the user lacks a tmath installation. Copy the entire directory together: `client.js`, `bindings.js`, `tmath-wasm.js`, `tmath-wasm.wasm`, declarations, fonts, manifest, and license notices have intentional relative relationships. The bundle is CPU-only; request `renderEngine: "cpu"`. A requested unavailable engine fails rather than falling back.

It provides the JavaScript/TypeScript builder and embedded Lua for portable construction and rendering, not a server, native CLI, or WebGL bridge. UI/Input, action maps, retained Lua runtime, audio, and game loops route to `tmath-game`; this reference covers only rendering or mounting a finished scene.

## Browser host

Serve copied files over HTTP so the adjacent WASM binary can load. Import from the copied directory and destroy the runtime at teardown:

```js
import {createTMath, tmath} from "./tmath-wasm/client.js";

const definition = tmath.scene({width: 640, height: 360, loop: false});
definition.circle({center: [0, 0], radius: 1.2, fill: "#2563eb", id: "subject"});
const runtime = await createTMath(definition, "scene.js");
runtime.draw(document.querySelector("canvas"), runtime.duration);
window.addEventListener("pagehide", () => runtime.destroy(), {once: true});
```

If deployment moves the WASM file, provide `locateFile`. For Lua, pass trusted source text to `createTMath(luaSource, "scene.lua")`; JavaScript owns loading and Canvas output. Do not expose `evaluateScene` or arbitrary Lua as an unrestricted public execution endpoint.

## Fonts, Node, and distribution

Register every selected Theme font before rendering. The standalone default uses `Source Serif 4` for semantic roles and `IBM Plex Sans KR` for inherited Korean Text; register Pretendard only when explicitly selected. In Node, read the `.wasm` bytes and pass `wasmBinary`; copied `render(..., true)` pixels survive subsequent calls. Use `layoutReport(time, 4)` for sampled rendered-layout review, not live layout.

Keep each font with its OFL notice, retain all runtime license files, and verify copied releases against `BUILD-MANIFEST.json`.
