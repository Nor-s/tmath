---
name: tmath-game
description: Author small experimental retained-Lua tmath game loops with independent UI, Input, Runtime, Audio, and semantic Motion sidecars. Use for current game prototypes, not general animation, VS Code hosts, or engine work.
---

# tmath Game

Create small, current retained-Lua game loops only. This surface is experimental: verify against the delivery host and state unsupported behavior rather than implying a stable game framework.

Route general authored animation to [tmath-skills](../tmath-skills/SKILL.md), VS Code hosts to [tmath-vscode](../tmath-vscode/SKILL.md), and engine, bindings, or build work to [tmath-animation-dev](../tmath-animation-dev/SKILL.md).

First apply the [tmath scene contract](../tmath-skills/references/scene-contract.md) and [Lua API](../tmath-skills/references/lua.md) to the authored base Scene. Then read [references/interaction-model.md](references/interaction-model.md) for UI/Input routing and coordinates and [references/review.md](references/review.md) for native input, retained Runtime, Audio, and delivery checks.

## Canonical contract

- UI, Input, Runtime, Audio, and Motion are independent sidecars; guard every used Lua namespace with its exact build-option message from the references. UI/Input never depend on one another; Runtime needs neither UI, Audio, nor Motion, and only its optional action bridge needs Input.
- In combined hosts, route pointers UI-first, forward only unhandled events to Input, preserve UI capture, and broadcast cancellation. Regions are top-left-origin logical Scene pixels; keyboard motion and cameras remain Input-owned.
- Sample input once per host frame. Consume transient edges, delta, and wheel only in the first fixed step; preserve held state for all steps. Runtime uses fixed-step catch-up with atomic overlays, `max_steps` 1–64, and at most 512 stable Object identities.
- Runtime opacity multiplies authored opacity: pre-author future-visible objects at opacity one off-frame. `ctx:sound` queues events; it is not playback. Audio hosts may consume the queue, and Runtime remains valid without Audio.
- Motion definitions are construction-only. Retained callbacks may retarget and sample them, but must call `motion:advance(dt)` explicitly; avoid overlapping ownership of the same Object across Motion and other transform sidecars.
- PNG, GIF, and MP4 cannot capture future interaction; exports contain only authored sampling plus retained state explicitly sampled by their export path.
