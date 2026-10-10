# Semantic runtime motion

`tmath-motion` is the optional native layer for changing an already retained,
Scene-owned Object
from its current motion state to a named semantic state. It complements, rather than
rewrites, the core Scene timeline:

| Core `Scene::play()` | `motion::Controller` |
|---|---|
| Immutable authored clips | Retained semantic state overlays |
| Sampled at arbitrary Scene time | Advanced by a separate host interaction clock |
| Best for a known editorial timeline | Best for input and game outcomes |
| Authored command order is the record | Accepted transitions produce an event journal |

Enable the module explicitly:

```sh
meson setup build-motion \
  -Dmodules=motion -Dengines=cpu -Dbundled_thorvg=true
meson compile -C build-motion
```

Native installation adds `tmath_motion.h`, `libtmath-motion`, and
`tmath-motion.pc`. A core-only build installs none of them. When Lua is enabled,
selecting the module also installs its `tmath.motion(scene)` hook into assembled CLI
and WASM Lua hosts. It does not add a direct JavaScript or C ABI.

## State overlays

A state is relative to the Object state already sampled by the Scene and by earlier
runtime layers:

```cpp
#include "tmath_motion.h"

using namespace tmath;

auto scene = Scene::gen();
auto answer = Rectangle::gen({}, {2.0f, 0.8f});
scene->add(answer);

auto motion = motion::Controller::gen(scene);

motion::State idle;
motion::State correct;
correct.shift = {0.0f, 0.12f, 0.0f};
correct.rotation.z = 0.03f;  // radians
correct.scale = {1.08f, 1.08f, 1.0f};
correct.opacity = 1.0f;

motion->define(answer, "answer.idle", idle);
motion->define(answer, "answer.correct", correct);

motion->transition(answer, "answer.correct", 0.18f, Easing::Smooth);
motion->advance(1.0f / 60.0f);
```

The Lua surface mirrors that bounded controller:

```lua
if not tmath.motion then
    error("this scene requires a tmath build configured with -Dmodules=motion")
end

local scene = tmath.scene {width = 1280, height = 720}
local answer = scene:rectangle {id = "answer", size = {2, 0.8}}
local motion = tmath.motion(scene)

motion:define(answer, "answer.idle", {})
motion:define(answer, "answer.correct", {
    shift = {0, 0.12},
    rotation = 0.03,
    scale = {1.08, 1.08},
})
motion:transition(answer, "answer.correct", 0.18, "smooth")

return scene
```

`define` is construction-only. `transition`, `transition_many`, `advance`, `sample`,
and journal queries remain callable from a retained Lua callback. The returned Lua
handle borrows the Scene-owned Controller; keep it in a local captured by every
callback that needs it. Dropping the handle does not delete the native Controller.

The supported channels are Object-local transform origin, parent-space relative shift,
XYZ rotation in radians, scale, opacity, and progress. Unless `originEnabled` is set,
`define()` resolves the local Object-family bounds center. Each render maps that point
through the currently sampled model, so scale and rotation follow an authored transform
instead of orbiting around its final position. An explicit local origin supports
authored pivot behavior. Transform overlays are composed before the currently sampled
Object model; opacity and progress multiply their sampled values. This keeps authored
math, code, and diagram geometry in core while an interaction adds feedback such as
focus, selection, correctness, or reveal state. Empty families have no automatic
bounds and require an explicit origin.

State names are copied into bounded native storage. They contain at most 96 ASCII
characters, start and end with a lowercase letter or digit, and may use `.`, `_`, or
`-` in the middle. Definitions are immutable for the lifetime of the Controller, so
the authored scene recipe remains the source of truth for replay.

## Capture-current retargeting

An interrupted transition begins from the value visible in the motion layer at the
exact interaction clock time:

```text
idle ---- 40% toward focused
                    \
                     +---- current value ----> answer.correct
```

The Controller samples the old curve before installing the new target. A zero duration
snaps immediately. Rendering and `sample()` are pure: asking for a future Scene frame
cannot complete or otherwise mutate the retained transition, and sampling Scene frames
out of order does not change the motion clock.

This guarantee is value continuity (C0), not velocity continuity. The Controller
captures its own relative overlay; it does not freeze an authored clip or another
runtime modifier that continues to change underneath it. The final visible state is
their deterministic composition.

## Clock and host loop

Only `advance(elapsed)` changes the motion clock. The host should advance it once per
simulation or interaction tick, then render any number of Scene times:

```text
input/event -> semantic decision -> transition(...)
fixed tick  -> advance(dt)
render      -> Scene time sample + current motion overlay
```

The retained Lua Runtime does not advance Motion implicitly. Advance both clocks in
the same fixed-step callback when they should share a cadence:

```lua
local motion = tmath.motion(scene)
-- define states before the Runtime seals authoring

tmath.runtime(scene, {
    fixed_step = 1 / 60,
    update = function(ctx, dt)
        motion:advance(dt)
        -- semantic decisions may call motion:transition(...) here
    end,
})
```

Separating the clocks lets a host pause its editorial timeline while hover, answer,
or game feedback still settles. A publisher can replay the same semantic decisions at
a fixed cadence for deterministic shorts and editorial capture only when its host
steps both Scene transport and the motion clock. The built-in GIF and video
savers advance Scene time only; a publisher must drive a custom two-clock capture or
bake the decisions into immutable Scene clips first.

## Atomic transitions and recording

`transition(Target*, count, ...)` validates the complete batch and reserves all
required tracks and event entries before it changes any semantic state. A rejected
batch produces neither partial motion nor partial events. Every accepted target emits
one `motion::Event`; entries from the same call share a nonzero `transaction`, so a
recorder can recover the atomic boundary. Each event contains:

- motion-clock time;
- transaction number;
- Scene-local Object ID;
- copied semantic state name;
- duration and animation curve.

The journal is bounded and query-only through `eventAt()`. Its 4,096-entry limit counts
targets, not calls. When it is full, the complete next transition fails atomically.
The host must check every result, durably copy acknowledged entries, and call
`clearEvents()` only after that copy succeeds. A storage failure keeps the journal and
applies fail-closed backpressure instead of losing the transition record.
Clearing acknowledged entries does not reset definitions, tracks, the clock, or the
monotonic Controller-local transaction counter.

`Event::object`, `Event::transaction`, and `Event::time` are deliberately local to one
Controller and Scene instance. A numeric Object ID cannot in general be reverse-mapped
to a host semantic key, and transactions or clocks from multiple Controllers are not
globally ordered. The host therefore records its semantic command when it makes the
decision, while it still owns both the semantic key and its physical endpoint
expansion. Native Events acknowledge that the physical batch was accepted; they are
not a durable command log and never mutate the immutable compile receipt.
The durable record commits only after `transition()` succeeds and the host verifies the
expected physical Event batch. A host needing write-ahead durability instead records
`intent -> native acknowledgement -> commit/abort`; replay ignores uncommitted intents.

When one semantic target expands to multiple live revision Objects served by the same
Controller, the host includes all of them—even currently invisible revisions—in one
native Target batch. Endpoints across Controllers form a host transaction, but the
native module provides no cross-Controller rollback or atomicity.

A host that requires durable motion-command replay must define a sidecar referencing
the scene, receipt, state-catalog, profile, and motion-policy revisions. It stores its
own global sequence, integer fixed tick/timebase, Scene transport time, symbolic curve
fields, semantic targets, and expanded `{scenePath, objectId}` endpoints. Replay creates
the same Scene recipe and state catalog with fresh Controllers at clock zero, restores
runtime-modifier registration order, then applies same-tick batches in host sequence
order while advancing Scene and motion clocks separately. Raw struct bytes, enum
ordinals, float-accumulated Event time, and Scene-local transactions are not a portable
wire format.

That sidecar contract replays motion commands, not an entire learner session. Full
session replay additionally needs sequenced pause, seek, rate, and other transport
operations plus a terminal tick after the final command.

## Deliberate first-stage limits

- one Controller and one runtime-modifier slot per Scene;
- 512 tracked Objects, 2,048 definitions, and 4,096 undrained events;
- no fill, stroke, text, equation-token, path-topology, or Object replacement channel;
- no spring/velocity state and therefore no C1 interruption guarantee;
- no direct JavaScript/C ABI, durable command log, or automatic
  Runtime-clock coupling; Lua is present only in Lua-enabled assembled hosts.

State identity is local to `(Controller, Object, name)`, and every State is a complete
relative overlay rather than a patch. Targeting both an ancestor and its descendant
composes both transforms. `Scene::runtime(nullptr)` is the legacy destructive clear for
all runtime modifiers; module hosts must use `runtimeAdd()`/`runtimeRemove()` and must
not mix that legacy setter with a live Controller.

Those omitted semantic changes need typed higher-level adapters. Equation token
matching, code-trace identity, diagram relayout, and replacement/crossfade policy
belong to their modules or host compiler; they may lower a decision to this small
motion overlay without making core depend on those domains.
