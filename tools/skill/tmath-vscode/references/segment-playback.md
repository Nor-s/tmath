# Playback ranges in the VS Code viewer

Read this for ranges, chapters, markers, range-aware hover, or range-aware export. Core tmath accepts absolute Scene time; it has no public named-marker or playback-segment API. Keep ranges in the host while they remain player policy. Do not mutate duration or apply hidden modulo in the renderer.

## Canonical model

```ts
interface PlaybackRange { start: number; end: number }
```

Require finite seconds with `0 <= start < end <= sceneDuration`; `null` means the full Scene. One validated model drives every consumer:

- play never advances beyond `end` and draws exactly that boundary;
- Loop wraps to `start`, retaining small overshoot when practical;
- Auto-play Next takes precedence over Loop, opens the next item in the current series, and wraps its final item to the first;
- without either policy, playback stops at `end`;
- Restart seeks to `start`;
- the absolute-time seekbar highlights the interval;
- a new Scene clears the range; same-Scene hot reload clamps it only while the interval remains valid.

Keep validation, clamping, and next-time logic in pure modules before wiring the DOM.

## Host integration and outputs

**Set In**, **Set Out**, and **Clear Range** remain in the existing settings menu. Do not add a permanent control row. PNG captures the current absolute frame. GIF, MP4, hover GIF, Restart, Loop, and seek highlighting share the active interval. Time-based outputs sample frame zero at `start` and never sample beyond `end`. Setting or clearing a mapped Scene range regenerates its local hover GIF sidecar. Normal and Canvas Full Screen retain the same range.

Declarative named segments are not current manifest syntax. If they are later added, update the parser, schema, tests, README, and usage reference together; reject blank or duplicate IDs, blank labels, non-finite or reversed bounds, and intervals outside Scene duration. Keep source navigation independent so an invalid segment cannot block source reveal.

Promote markers into core only when multiple hosts require author-authored discovery; that requires coordinated C++, C API, bindings, WASM, TypeScript declarations, serialization, and documentation.

## Verification

Test full Scene and strict middle ranges; zero/duration boundaries; exact and overshooting frames; loop, stop, Restart, pause/resume, and scrubbing; shorter/longer hot reload; fractional output plans; hover limits; Auto-play precedence; and parity between normal and Canvas Full Screen.
