# Audio v1

The experimental Audio module provides two independent playback paths over one
mixer:

- game playback starts immediate, concurrent music, effect, or UI voices;
- a Scene-owned `Soundscape` stores authored cues and gain animation that a
  host synchronizes to the animation playhead.

Audio is a sidecar. The core Scene, renderer, and saver do not acquire an audio
dependency, and rendering a Scene never starts or advances a sound.

## Build

Enable the module explicitly:

```sh
meson setup build-audio \
  -Daudio=true -Dbundled_thorvg=true -Dengines=cpu
meson compile -C build-audio
meson test -C build-audio --print-errorlogs
```

The native build installs `tmath_audio.h`, `libtmath-audio.a`, and
`tmath-audio.pc`. An audio-disabled build contains none of the optional Audio
symbols. Emscripten builds use the same `-Daudio=true` option and expose Audio
through the optional `scene.audio` JavaScript object.

## Playback model

`audio::Player` owns encoded resources, the native or Web Audio backend, three
buses, and a bounded pool of simultaneous voices. `audio::Soundscape` derives
from the paintless `Group` and is owned by its Scene. It stores names and timing
only; every named asset must be loaded into the Player before playback.

The buses are:

- `Bus::Music` for background music;
- `Bus::Effect` for game and animation effects;
- `Bus::Ui` for controls and other interface feedback.

Master, bus, cue, and immediate-playback gain values use linear amplitude in
the inclusive range `[0, 4]`. `0` is silent and `1` is the asset's original
level. Master and bus gain multiply the voice or cue gain. Cue gain clips are
sampled from Scene time; a host can animate master or bus gain by applying its
own per-frame value to the immediate setters.

The default Player has 32 simultaneous voices. A host may select 1 through 256
with `PlayerConfig::voiceLimit`. When all slots are active, another immediate
`play()` returns `Result::InsufficientCondition`; v1 does not steal a playing
voice. A `Voice` contains a generation, so a handle cannot stop a newer sound
that reused its slot.

## C++

The Player copies encoded asset bytes supplied by the host. File paths are not
part of the v1 public API, which keeps the same asset path available to native
and filesystem-free WASM builds.

```cpp
#include "tmath.h"
#include "tmath_audio.h"

using namespace tmath;

auto scene = Scene::gen();
auto soundscape = audio::Soundscape::gen(scene);

audio::CueConfig music;
music.asset = "music.mp3";
music.bus = audio::Bus::Music;
music.begin = 0.0f;
music.end = 18.0f;
music.gain = 0.7f;
music.loop = true;

audio::Cue musicCue;
soundscape->cue(music, musicCue);
soundscape->gain(musicCue, 0.25f, 14.0f, 2.0f, Easing::Smooth);

audio::CueConfig hit;
hit.asset = "hit.wav";
hit.bus = audio::Bus::Effect;
hit.begin = 2.4f;

audio::Cue hitCue;
soundscape->cue(hit, hitCue);

auto player = audio::Player::gen();
player->load("music.mp3", musicBytes, musicSize);
player->load("hit.wav", hitBytes, hitSize);
player->bind(soundscape);
player->start();
```

`CueConfig::begin` and `end` are absolute Scene seconds. `end=0` means that no
explicit cutoff is applied. A non-looping cue still stops at the end of its
asset; a looping cue continues until its explicit end or until the host stops
the transport. Cues must be authored before `Player::bind()`. If another cue is
added later, bind the Soundscape again before the next sync.

Gain clips for one cue cannot overlap. A clip starts from the cue gain sampled
at `begin` and reaches the supplied value at `begin + duration`. Both the
built-in `Easing` values and `AnimCurve` are supported.

The animation host supplies the authoritative playback state:

```cpp
audio::Transport transport;
transport.time = animationTime;
transport.rate = playbackRate;
transport.playing = playing;
transport.seek = scrubbedOrJumped;
player->sync(transport);
```

Immediate game and UI playback does not belong to the Scene timeline. It can
therefore overlap authored cues and is not replayed when the animation seeks:

```cpp
audio::Playback click;
click.asset = "click.wav";
click.bus = audio::Bus::Ui;
click.gain = 0.8f;

audio::Voice first;
audio::Voice second;
player->play(click, &first);
player->play(click, &second);

player->gain(0.75f);
player->gain(audio::Bus::Music, 0.6f);
player->stop(first);
```

A bound Soundscape must remain alive. If the Player survives the owning Scene,
call `player->bind(nullptr)` before deleting that Scene. WASM Scene replacement
performs this detach and rebind automatically.

For tests and offline host validation, set `PlayerConfig::device=false`. The
Player then constructs its mixer and validates decoding, voices, and transport
without opening a system audio device.

## Retained Lua sound events

The optional retained Lua Runtime does not depend on Audio. Inside its fixed-step
callback, `ctx:sound()` appends one bounded description to the current host advance:

```lua
if fire.released then
    ctx:sound("laser.wav", {
        bus = "effect",
        gain = 0.7,
        rate = 0.94,
    })
end
```

The Runtime accepts at most 64 events per host advance. Invalid asset names, buses,
gains, or rates reject the callback; a full queue returns `false` so a simulation can
drop excess sound without failing. Events from a failing callback are rolled back.
Native hosts read `Runtime::soundCount()` and `soundAt()`. The WASM client returns the
same immutable data on `advanceRuntime(elapsed).sounds`:

```js
const step = scene.advanceRuntime(elapsed);
for (const sound of step?.sounds ?? []) {
    scene.audio?.play(sound.asset, sound);
}
```

This bridge keeps all four combinations valid: Runtime only, Audio only, both, or
neither. Asset bytes are still loaded by the host. Authored background music remains a
Scene cue guarded by `tmath.audio`; immediate combat effects are runtime sound events.
The VS Code Preview loads declared audio assets, starts Web Audio only after a user
gesture, synchronizes authored cue transport, and forwards retained events to immediate
voices when its bundled runtime includes Audio. If the bounded immediate-voice pool is
saturated, Preview drops that optional sound rather than interrupting fixed-step
simulation or rendering.

## Lua authoring

Lua authoring declares synchronized cues but does not open a device or load
bytes. The native or WASM host owns those runtime operations.

```lua
local scene = tmath.scene {
    width = 960, height = 540,
}

local music = tmath.audio.cue(scene, {
    asset = "music.mp3",
    bus = "music",
    begin = 0,
    ["end"] = 18,
    gain = 0.7,
    loop = true,
})
music:gain(0.25, 14, 2, "smooth")

local hit = tmath.audio.cue(scene, {
    asset = "hit.wav",
    bus = "effect",
    begin = 2.4,
})
hit:gain(0.5, 2.4, 0.1, "ease_out")

scene:wait(18)
return scene
```

Valid bus strings are `"music"`, `"effect"`, and `"ui"`. The cue handle owns
no asset bytes and is valid only while its Scene is being authored. As with the
C++ API, cue times are explicit absolute seconds and do not move the Scene
timeline cursor. Use `scene:wait()` to establish the intended animation
duration.

## JavaScript and WASM

The JavaScript SceneBuilder mirrors Lua authoring:

```js
const scene = tmath.scene({width: 960, height: 540});
const music = scene.sound({
    asset: "music.mp3",
    bus: "music",
    begin: 0,
    end: 18,
    gain: 0.7,
    loop: true,
});
music.gain(0.25, 14, 2, "smooth");
scene.wait(18);
```

When the WASM bundle was built with Audio, the loaded Scene has an optional
`scene.audio` runtime object. Its absence is the feature-detection result; there
is no separate `supported()` query.

WASM has no filesystem, so fetch each asset as bytes and register it by the
same name used by the authored cue:

```js
const music = new Uint8Array(
    await (await fetch("music.mp3")).arrayBuffer(),
);
scene.audio.load("music.mp3", music);
```

Browsers block audible playback until a user gesture. Call `start()` directly
from a click, pointer, or keyboard activation handler before starting the
animation transport:

```js
startButton.addEventListener("click", () => {
    scene.audio.start();
    scene.audio.transport({
        time: timeline.current,
        rate: timeline.rate,
        playing: true,
        seek: true,
    });
});
```

Immediate game and UI sounds use the same registered names and return opaque
voice handles:

```js
const first = scene.audio.play("click.wav", {bus: "ui", gain: 0.8});
const second = scene.audio.play("click.wav", {bus: "ui", gain: 0.8});
scene.audio.stop(first);
```

The runtime surface is:

```ts
interface TMathAudio {
    load(name: string, data: Uint8Array | ArrayBuffer): void;
    start(): void;
    play(name: string, options?: {
        bus?: "music" | "effect" | "ui";
        gain?: number;
        rate?: number;
        loop?: boolean;
    }): number;
    stop(voice: number): void;
    active(voice: number): boolean;
    masterGain(gain: number): void;
    busGain(bus: "music" | "effect" | "ui", gain: number): void;
    transport(state: {
        time: number;
        rate?: number;
        playing?: boolean;
        seek?: boolean;
    }): void;
}
```

The numeric JavaScript voice is opaque. Do not decode it or reuse it after
`stop()` returns. Multiple calls to `play()` create independent voices up to
the configured limit.

## Seek and playback rate

Scene time is authoritative. Call `transport()` or `Player::sync()` whenever
the host plays, pauses, seeks, changes rate, or wraps a loop. Set `seek=true`
for a scrub or discontinuous jump. A paused seek positions authored audio but
does not make it audible. Resuming inside a cue starts from the corresponding
asset offset rather than replaying its beginning. Immediate game voices are
not repositioned by transport changes.

The supported playback-rate interval is `[0.125, 8]`. Rate must remain positive;
pause with `playing=false`, not `rate=0`. v1 changes decoder pitch with rate, so
slow playback lowers pitch and fast playback raises it. Reverse playback and
pitch-preserving time stretch are not supported.

## Backend, license, and web limitation

Audio v1 pins miniaudio 0.11.25 and builds its C implementation as one
private static dependency. The selected license is MIT No Attribution
(`MIT-0`), and installed Audio builds include its license text. tmath does not
expose miniaudio types in `tmath_audio.h`.

The Emscripten v1 backend selects miniaudio's Web Audio implementation. It uses
the browser `ScriptProcessorNode` path rather than `AudioWorklet`. This keeps
the first WASM integration free of worker, shared-memory, and COOP/COEP server
requirements, but ScriptProcessor is deprecated and runs on the main thread.
Heavy rendering or JavaScript work can therefore cause audible underruns. A
window/main-thread runtime is required for audible output; worker-only scene
renderers can leave the lazy audio API dormant. A future AudioWorklet backend
should retain the same authored cue and transport contract while changing only
the host/backend integration.
