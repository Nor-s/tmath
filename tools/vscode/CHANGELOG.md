# Changelog

## 0.7.78

- Make Equip Bullet offers advance a deterministic non-cyclic PRNG, avoid immediate
  repeats while alternatives remain, and show the exact weapon silhouette and name on
  each card. Replace the Earth and layered space scenery with one dark flat 60px Grid,
  two continuously wrapped downward-moving sheets, and restrained highlighted cells, then
  use the complete portrait Canvas for a full-width header, battlefield, and lower HUD.
  Enemy cross-flash deaths now apply
  player-safe radial damage, pop nearby hostile bullets, and trigger delayed chain blasts.
- Separate projectile clash strength from HP damage so ordinary player fire can again
  cumulatively cancel stronger hostile bullets; preserve exact residual damage, scale,
  radius, and safe pooled-slot reuse for whichever projectile survives.
- Give player projectiles an independent 1.6× cancellation-strength factor so Lv.1
  Short Laser and Pulse Bullet remove regular hostile shots in one collision while
  actor damage and weapon roles remain unchanged.
- Double the original base damage of the starting penetrating Short Laser, Homing
  Missile, Ricochet Ball, and Pulse Bullet while leaving Long Laser unchanged.
- Make ordinary player hits subtract exact HP and open a 1.45-second invulnerability
  window without teleporting the craft, cancelling inertia or charge, or clearing
  unrelated hostile projectiles.
- Scale hostile-shot visuals and collision radii to 62% so multi-point damage no longer
  produces oversized bullets, while preserving their HP damage, clash strength, and
  recoil-only enemy propulsion momentum.
- Let retained Group fill state recolor its painted descendants while preserving a
  nearer descendant override.
- Carry charge heat into every player weapon so every charged projectile remains visibly
  red after release, including the complete Short Laser core and glow rather than only
  its center fill.
- Replace cyclic Weapon Shift with a named deterministic-random five-weapon cache, adding
  a slow-firing continuous Long Laser and level-widened 1/3/5-shot Pulse Bullet volleys.
- Turn tap and charged Long Laser fire into a canvas-overscanning extend/hold/retract
  channel above ordinary HUD content that locks steering, boost, dash, and repeat fire
  while the player moves only through firing recoil. Replace its curved whip with a
  snap-fast rigid straight beam whose exact collision segment rotates toward the pointer,
  and give it a sharper ignition transient with a distinct sustained 8-bit tail.
- Give every weapon an independent Lv.0–5 upgrade path, display acquisition or exact level
  transitions on random weapon cards, and replace HP/KILL/BREACH/THREAT/POWER/ROUND pips
  with numeric retained digit wheels. Higher Short Laser levels add timed bursts while
  Pulse Bullet expands through symmetric 1/3/5/7/9-shot fans.
- Start the numeric hull at HP 100 and subtract exact hostile projectile damage. Give
  every weapon independent tap/charge/release/hold stamina costs so ball and pulse fire
  remain economical while Short and Long Laser channels drain the reactor quickly.
- Remove the nearby-ally attack burst so enemy fire cadence depends only on its own
  cooldown and recoil lock. Replace sine-graph and sigil-shaped emitters with readable
  direct and heavy aimed shots while preserving their color-owned movement traits.
- Add a Runtime-owned, Audio-independent 64-event sound bridge and wire the Preview to
  optional Audio playback and transport after a user gesture. Ship deterministic
  self-generated 8-bit BGM plus distinct weapon, explosion, hit, level-up, and card-select
  PCM WAV assets with a dependency-free generator.

## 0.7.77

- Focus the Canvas explicitly on pointer press so Viewer keyboard controls no longer
  continue typing into the source editor; passive previews still avoid stealing focus.
- Add Shift as an independent logical Input key and ship the matching native, Lua,
  retained-runtime, WASM, and TypeScript mappings.
- Upgrade the retained Lua game template to a portrait procedural Earth-defense demo
  with a blue ocean, green terrain, cloud-depth bands, sun/moon round palettes, exact
  1.25× nighttime enemy behavior, input-gated animated three-card level
  progression, exponential XP requirements, card hover focus,
  pointer-aimed 1–5× stamina-backed charge fire with synchronized blue-to-red ring/craft
  heat feedback and a persistent red overheat state,
  3× movement-and-shake recoil tuning,
  recoil lock,
  boost, invulnerable dash, strength-resolving projectile clashes,
  recoil-only Boids/dance/sentinel guidance driven by actual opposite-vector projectile
  momentum, color-owned enemy archetypes, shake-to-cross-flash enemy deaths, scalable
  enemy HP/damage, breach scoring, single-beam laser, orbit-to-homing missile swarms,
  shrinking reflective balls, and graph/sigil bullet patterns. Rebalance the weapons so
  Ricochet Ball has the strongest single-projectile damage, lasers trade damage for
  penetration, and Homing Missile has the weakest shot but the largest guided flock.
- Add a thin pointer-aligned aim guide that reaches the nearest battlefield boundary
  while remaining beneath actors, the opaque HUD strip, and level-up overlays.
- Separate mouse-facing orientation from WASD translation and add inertia-steered target
  velocity plus low-drag coasting, preserving visible momentum through direction changes.
- Prevent saturated projectile pools from reassigning active in-flight bullets, expand
  the game pools, and raise the optional retained-runtime overlay budget to 512.

## 0.7.75

- Clamp Preview frame deltas at the host clock boundary so a same-frame timestamp
  skew after Scene reload cannot interrupt retained Lua playback.

## 0.7.74

- Add an opt-in retained Lua VM with a bounded fixed-step scheduler and atomic Object
  transform, opacity, progress, and fill overlays.
- Integrate retained Lua actions with the independent Input sidecar while preserving
  press/release edges across accumulator-only Preview frames.
- Ship a deterministic Lua 2D game template and feature-detected WASM/TypeScript APIs
  for runtime time, tick, interpolation, dropped time, and host advancement.

## 0.7.73

- Add independent per-frame key and pointer state with pressed/held/released edges,
  press times, pointer deltas, and focus-loss release.
- Add named digital/2D Action Maps to native C++ and the typed WASM client without a UI
  dependency, plus a fixed-step 2D collector-game template.
- Release all retained Input state when the Preview loses focus, reloads, or disposes
  its Canvas router.

## 0.7.72

- Add synchronized multi-target Slider bindings plus production templates for sampled
  object inspection, UI/Input routing, transform controls, and native key lifecycles.
- Permit attached Text content to refresh atomically while a Scene remains unsealed,
  preserving the previous string when an authored timeline rejects the update.
- Release retained Scene keys on keyup even while Preview is busy, and synthesize
  keyup when the Webview loses focus, replaces the Scene, or disposes its router.

## 0.7.71

- Make Input KeyMove retain keydown state until keyup, ignore platform repeat delay and
  rate, and expose native Tap/Down/Up signals with press begin/end Scene times.

## 0.7.70

- Split keyboard, pointer-follow, and camera state into an optional Input sidecar that has no UI dependency and composes independently with authored Scene motion.
- Route passive pointer movement plus logical keydown/keyup through the shared Preview bridge, with UI-first pointer ownership when both optional modules are present.
- Add smooth pointer-to-position/angle and keyboard Object-motion templates, synchronized LuaLS declarations, runtime coverage, and a refreshed combined WASM bundle.
- Add declarative `panel:toggle_button` state with explicit off/on transforms, retained initial value, and reversible Scene-time motion.
- Expand the bundled Diagram runtime with ranked, manual, grid, and timeline layouts plus semantic node and edge kinds and full-width zones.
- Synchronize LuaLS metadata and the shipped WASM, and exercise the base Diagram plus six production family templates in the packaged-runtime suite.

## 0.7.69

- Render solid and dashed directed objects through one marker-aware path pipeline.
- Trim shaft endpoints by the visible head and tail lengths so markers meet the path without overlapping it.
- Preserve flat directed-shaft caps in the ThorVG renderer and Lottie output.

## 0.7.68

- Initialize Diagram and Chart Lua builder state on every load so repeated Preview refreshes cannot inherit a stale `built` flag.
- Add a shipped-WASM regression that repeatedly reloads the native Diagram template.

## 0.7.67

- Add edge-anchored growth so bars can rise from a fixed quantitative baseline.
- Refresh the native Chart template with inset categorical slots, slimmer bars, direct budget labeling, and left-to-right bar reveals.
- Refresh the bundled authoring WASM runtime, typed bindings, LuaLS metadata, and diagram guidance.

## 0.7.66

- Add marker-aware `route` authoring and native dashed Arrow/Route rendering with solid endpoint markers.
- Animate shaft dash phase and marker `tail`/`tip` sizes through one timeline state; Diagram flow edges no longer create duplicate overlays.
- Refresh the bundled WASM runtime, LuaLS metadata, and diagram templates for the single-object flow contract.

## 0.7.65

- Add Object-only `label` helpers across C++, Lua, and JavaScript/TypeScript; labels remain ordinary child Text with explicit placement and styling.
- Refresh the shipped WASM runtime, LuaLS metadata, and runtime coverage for Object labels.

## 0.7.64

- Bundle the optional native Diagram and Chart Lua authoring modules, which lower semantic flow and line/bar descriptions into ordinary Preview objects.
- Publish synchronized LuaLS metadata and verify both authoring modules through the shipped WASM runtime.

## 0.7.63

- Require manifest version 2 and organize every mapped Lua scene under its required series at `.vscode/tmath/<series>/animations/<scene>.lua`.

## 0.7.62

- Continue a downward wheel gesture through the Inspector after a Related source excerpt consumes its remaining vertical scroll range.

## 0.7.61

- Render verified ranges from files added after the base commit as inserted Diff rows, and open native Diff navigation against an empty previous document.

## 0.7.60

- Let verified Diff excerpts reveal bounded current-file context above and below with the shared 5, 10, or 20-line **Show Lines** setting.

## 0.7.59

- Make settings submenu summaries non-selectable and let their labels and current-value text activate the complete row.

## 0.7.58

- Continue ordinary vertical wheel scrolling in the Inspector when a Related source excerpt has no remaining vertical scroll range.

## 0.7.57

- Move source locations, Diff indicators, and **SEE** into an indented child code header while keeping accordion summaries title-only.
- Flatten settings into opaque single-column actions, remove Reveal Source and Full Screen/Windowed controls, and prevent the Wide divider from painting over menus.

## 0.7.56

- Let the Wide Playback Series button open the same viewport-bound catalog popup as Compact, then return the single panel to its dock when closed.

## 0.7.55

- Add verified Git Diff Range links with head-relative manifest ranges, exact snapshot validation, unified Shiki rendering, rename support, and native VS Code Diff Editor navigation.

## 0.7.54

- Give every expanded Related source excerpt bounded independent vertical scrolling in addition to horizontal scrolling, preserving both offsets across Inspector refreshes.

## 0.7.53

- Remove Related source item separators and give every expanded code excerpt an independent horizontal scroll area with refresh-safe position restoration.

## 0.7.52

- Make Notes and all Related source disclosures share one horizontal overflow rail while keeping their visible controls pinned to the Inspector viewport.

## 0.7.51

- Keep Related source headers and separators bound to the visible Inspector width while long code scrolls independently, and place **SEE** beside the disclosure control.

## 0.7.50

- Reveal 5 Related source lines by default and add a persistent **Show Lines** setting for 5, 10, or 20-line expansion steps.

## 0.7.47

- Enter Wide at 600px, remove description-length and manual playlist height reservations, and keep Playback reachable while the Canvas uses the available space.
- Reset SHOW context when a source disclosure closes, lightly mark the original focus only while expanded, and hide the Inspector's horizontal scrollbar track.
- Reuse the editor group immediately right of the Viewer for SEE destinations and center each exact source range without selection decoration.

## 0.7.46

- Add an optional `duration` to declarative target Buttons so interactive Object state changes can transition smoothly from their currently composed state.
- Refresh the UI-enabled CPU WASM runtime and Lua API metadata for the new Button contract.

## 0.7.45

- Separate Related source disclosure from navigation: click a source label to expand or collapse its Shiki excerpt, and use the adjacent **SEE** action to open that exact range in the native editor.

## 0.7.44

- Keep `tmath: Open Viewer` as the only Preview-opening command in the Command Palette while retaining the Lua editor-title Preview action.

## 0.7.43

- Add GitHub-style controls that reveal Related source context 20 lines at a time above or below its focused reference range.
- Keep the visible source line anchored while expanding upward and validate every expansion request in the extension host.

## 0.7.42

- Let Notes and multiple Related source entries remain expanded together while preserving their state and independent Shiki highlighting across Inspector refreshes.
- Route wheel input explicitly through a vertically overflowing Inspector, falling back to horizontal scrolling only when no vertical scroll range exists.

## 0.7.41

- Make Wide Canvas Full Screen canvas-only, support horizontal-sash height adjustment in both responsive layouts, and add a persistent Compact Layout preference.
- Replace implicit menu toggles with explicit mode and `ENABLE`/`DISABLE` choices whose current value is disabled.
- Combine Notes and Related source into one scroll-owning accordion and retain Shiki syntax colors without selection-like Webview or native-editor range fills.

## 0.7.40

- Make the responsive Wide breakpoint depend on the fixed 960px editor-authoring reference instead of the active Scene's logical width, retaining a 40px exit hysteresis.
- Prevent a manually narrowed Wide player from overlapping the Inspector by enforcing a usable player minimum and adapting Playback controls to the player column itself.

## 0.7.39

- Dock the existing series catalog below Playback in Wide layout so episodes remain visible as a dense playlist beside the Title and Inspector.
- Reuse the same group rail and episode list in Wide and popup layouts, keeping selection, scrolling, and episode playback synchronized without duplicating Webview state.

## 0.7.38

- Give **Auto-play Next** precedence over the current item's Loop setting and wrap the final item back to item 0 of the same series.

## 0.7.37

- Toggle the Play and Pause SVG attributes directly so the transport reliably shows Pause during playback and Play while stopped in the VS Code Webview.

## 0.7.36

- Add a persistent **Option → Auto-play Next** toggle that opens and starts the next item in the current series when non-loop playback reaches its end.
- Keep automatic advancement inside the active series, stop at its last item, and avoid moving the source editor during an automatic transition.

## 0.7.35

- Keep Canvas and Playback in separate, opaque rows within the Wide player so active rendering cannot overlap the controls and FIT always measures the real stage area.
- Derive the Compact/Wide breakpoint from the current Scene's logical width, with hysteresis, and add a draggable vertical divider between the player and Inspector.
- Load the active workspace's complete series catalog into an empty **tmath: Open Viewer** surface so an episode can be selected before a Scene is playing.

## 0.7.34

- Add **tmath: Open Viewer** to open the existing Preview surface without selecting a Lua scene first.

## 0.7.33

- Make Canvas Full Screen occupy the complete Webview in both Compact and Wide layouts while retaining Playback.

## 0.7.32

- Keep manual Canvas height behavior without showing a `MANUAL` label or a persistent highlighted resize line.

## 0.7.31

- Add automatic Compact and Wide viewer layouts with hysteresis to prevent resize oscillation.
- Place Canvas and Playback on the left and the existing Title plus `CODE`/`NOTES` Inspector on the right in Wide layout.
- Preserve Compact Inspector reservations and manual Canvas height while temporarily suspending manual height in Wide layout.

## 0.7.30

- Rename the source-navigation option to `Reveal Source on Select` so its editor-navigation behavior is clear without implementation-oriented click wording.

## 0.7.29

- Replace expanding settings sections with compact, viewport-clamped cascading menus styled from VS Code context-menu tokens.
- Move Canvas actions to the bottom and place the Stat visibility control first.
- Show optional Canvas size and FPS beside the manual-height marker on the resize sash.

## 0.7.28

- Replace the permanent Related Source strip with an execution-ordered, single-open accordion in the bottom `CODE` Inspector.
- Render the expanded source excerpt with Shiki while keeping native source navigation behind the existing opt-in setting.
- Group Previous, current series position, and Next in Playback, with a viewport-bound catalog and compact narrow-window behavior.
- Reclaim the removed source-row height for the Canvas while preserving normal-mode document reservations.

## 0.7.27

- Highlight Related Source excerpts with Shiki TextMate grammars in the bottom `CODE` Inspector.
- Follow VS Code light, dark, and high-contrast modes while preserving immediate plain-text fallback during lazy grammar loading.

## 0.7.26

- Drag the sash above Playback to set a manual Canvas height that bypasses the Inspector reservation while keeping player controls visible.
- Mark manual sizing in the Preview and let Canvas Reset restore automatic window-aware sizing, zoom, and position.

## 0.7.25

- Add a Canvas Reset action beside Full Screen and FIT/1:1 that restores the current display mode's default zoom and position.

## 0.7.23

- Use Source Serif 4 across all adaptive VS Code semantic text roles and all Latin Webview text.
- Select IBM Plex Sans KR for inherited Canvas Text containing Korean while preserving explicit per-Text fonts.
- Ship the same language-aware font policy and licensed Korean font in the portable authoring skill runtime.

## 0.7.22

- Replace the oversized player settings sheet with compact Speed, Camera, Range, Canvas, Option, Document, and Stat submenus.
- Keep Related Source and series clicks inside the Preview Inspector by default, with an opt-in persisted setting for native source-editor navigation.
- Remove the visible live/unsaved status row and retain only Canvas size and FPS statistics.

## 0.7.21

- Pin the bundled Webview runtime to the CPU engine and reject unavailable GL requests without renderer fallback.
- Add optional Related Source code ranges, a live bottom `CODE`/`NOTES` Preview Inspector, and exact native editor range highlighting without introducing a separate View or side panel.
- Bundle Source Serif 4 Semibold under OFL 1.1, register it for Canvas scenes, and use it for Latin Webview titles with Korean fallback.
- Keep FIT wheel zoom at or above the automatic fitted scale.

## 0.7.20

- Add authored click-sampling areas that identify the selected Scene object, report its composited RGBA pixel, and update marker and swatch visuals through the optional interactive runtime.
- Expose the latest sample to the VS Code Preview while preserving camera fallback and UI-disabled WASM builds.

## 0.7.19

- Bundle and register IBM Plex Sans KR SemiBold for deterministic Korean and Latin `h1`/`h2` Scene headings in VS Code-authored animations.

## 0.7.18

- Open the existing player settings beside a Canvas right-click while keeping the menu inside the Webview viewport.

## 0.7.17

- Match VS Code toolbar interactions with transparent icon controls, explicit Loop and Play/Pause states, editor-widget menus, and an edge-to-edge Related source cell strip.
- Add Previous and Next controls beside player settings to step through the current series group without wrapping.
- Remove the title-to-description divider, add three pixels of breathing room between them, and increase their horizontal inset by three pixels.

## 0.7.15

- Follow the active VS Code color theme across Preview controls, menus, source tags, title, and Markdown while leaving the rendered Scene canvas theme-owned.

## 0.7.14

- Resolve a directly opened Lua scene back to its unique manifest animation entry so ordinary Preview and active-Lua-tab following retain related sources, series, title, and description.

## 0.7.13

- Pre-position the settings and series popups before reveal so they never flash at stale or default coordinates while the Webview layout settles.
- Keep the series catalog trigger visible without configured series and add a compact empty state.
- Replace Loop and settings glyph text with clearer icon controls, restore the playback/reference divider, and add three pixels to document-side insets.
- Base the one-sixth versus one-third document reservation on a stable 300-character description threshold so FIT can grow without line-wrap feedback.

## 0.7.12

- Split the series popup into a hidden-scrollbar horizontal group selector and an independently scrollable episode list.
- Make every named series in the workspace manifest reachable from the active code-linked Preview.

## 0.7.11

- Add ordered visualization series, a numbered hashtag series menu, and first-related-source navigation when switching episodes.
- Move Lua navigation from the related-source rail into the settings menu and replace the player hamburger with a settings icon.

## 0.7.10

- Recompute the normal FIT stage limit from actual stage-width changes so the canvas expands with the panel while preserving its document reservation.

## 0.7.9

- Keep the canvas edge-to-edge while aligning playback, related-source tags, title, and description to a shared eight-pixel inset.

## 0.7.8

- Replace root page scrolling with a zero-gutter viewport grid and a stable internal title-and-description scroller to prevent resize feedback.

## 0.7.7

- Pin related-source tags with the canvas and transport, and stop normal-mode width growth at the title-and-description reservation boundary.

## 0.7.6

- Reduce the title and description outer margin to zero and padding to one pixel at every Webview width.

## 0.7.5

- Keep the hamburger menu inside short Webviews by opening toward the larger vertical space and scrolling overflowing menu rows.

## 0.7.4

- Let a normal FIT canvas keep growing with a wider Webview, up to the height that leaves playback controls and related-source tags visible.

## 0.7.3

- Count the title inside the adaptive one-sixth or one-third normal Preview document reservation.

## 0.7.2

- Reserve one sixth of the normal Preview for descriptions up to three rendered lines, switching to one third from four lines onward.

## 0.7.1

- Allocate normal Preview height from rendered description length, compact the title row, stabilize FIT at narrow Webview sizes, raise hover GIF output to an 800×800 box, and resolve unambiguously mapped function references through declaration paths.

## 0.7.0

- Add host-only playback ranges with Set In/Out/Clear controls, an absolute-timeline range highlight, range-bound loop/restart behavior, and range-aware GIF, MP4, and hover GIF sampling.

## 0.6.0

- Keep the rendered canvas and compact Loop/Play/Restart transport pinned above the scrolling document, move secondary controls into a menu, use a thin horizontal related-source tag rail, and damp preview zoom sensitivity.
- Remove remaining horizontal player gutters and allow FIT to enlarge small canvases to the available scene-ratio viewport.
- Resolve visualization hovers at function use sites through the editor's definition provider.
- Generate hover GIFs on demand beside their mapped Lua scene instead of relying on global extension storage.
- Add a hamburger-menu Canvas Full Screen mode that center-fits the player, retains playback and related-source tags, and hides the title and description until exit.
- Bound normal-mode FIT height from the measured transport, source-tag, and title rows so the description retains roughly the lower third; keep the complete player and source tags inside Full Screen.

## 0.5.0

- Attach tmath Lua animations to C/C++/Lua function definitions through a workspace visualization manifest.
- Show animation actions as CodeLens and trusted hover links, backed by document-symbol lookup and a text fallback.
- Automatically follow mapped function definitions in a focus-preserving Preview after a configurable cursor delay.
- Generate bounded animated GIF thumbnails in extension storage and display them directly in function hovers.
- Give related source symbols the same CodeLens, cursor-following Preview, animated hover, and navigation actions as primary definitions.
- Redesign the Preview as a restrained Pro White, video-first document with a scene-ratio canvas, flexible seekbar, related-source tags, and a safe Markdown description.
- Move PNG, GIF, and MP4 saving out of the viewer chrome and into commands for the current viewer.
- Fall back to the active Lua editor when the editor-title Preview command does not provide a URI.
- Add JSON schema validation and tests for workspace-safe manifest paths.

## 0.4.0

- Add Side View-aware completion, snippets, hover documentation, and signature help for tmath Lua scenes.
- Track Scene, Object, Group, and Space values created by common tmath factory assignments.
- Generate bundled LuaLS annotations from the same API schema used by the editor providers.
- Add a command that enables the generated metadata in Lua Language Server.
- Verify the schema against the native `SCENE_METHODS` and `OBJECT_METHODS` registrations.

## 0.3.0

- Add GIF and MP4 export buttons with 24/30/60 FPS selection and progress feedback.
- Bundle gifenc and mediabunny so media export works without CDN access.
- Cancel active exports safely when a scene hot reloads or the preview closes.
- Route PNG, GIF, and MP4 output through the native VS Code Save Dialog.

## 0.2.2

- Match the WASM interactive example with an always-visible camera HUD.
- Add drag/orbit, Shift/right-button pan, wheel zoom, keyboard navigation, view state, and reset controls.
- Add runtime coverage for interactive and fixed camera behavior.

## 0.2.1

- Use the Webview panel icon for the Lua editor title action.

## 0.2.0

- Make hot reload atomic so failed edits cannot invalidate the last rendered scene.
- Guard seek values and report the exact failed render time when an engine error occurs.
- Follow active Lua tabs while the side preview is open.
- Show the editor title icon only for detected tmath Lua scenes.
- Add live FPS/render timing, a Lua file picker, and a bundled-runtime folder command.

## 0.1.0

- Preview tmath Lua scenes in a synchronized canvas Webview.
- Control playback, looping, speed, timeline position, and interactive cameras.
- Resolve local image assets and bundle the Pretendard font.
- Surface Lua failures as editor diagnostics and save the current frame as PNG.
