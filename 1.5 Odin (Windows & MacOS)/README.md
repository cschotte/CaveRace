# CaveRace 1.5 — Odin rewrite for Windows and macOS

CaveRace 1.5 is the current desktop edition of the 1997 maze-action game. It
is written in [Odin] and uses Odin's bundled [raylib] bindings for windowing,
graphics, keyboard input, streamed music, and sound effects. The rewrite keeps
the ten original level files and the recognizable pixel-art rules while giving
the game a modern, cross-platform application loop.

## Installation

Prebuilt binaries, when published, are available from the
[GitHub Releases page](https://github.com/cschotte/CaveRace/releases). Download
the archive for your platform, extract it, and run `CaveRace.app` (macOS) or
`CaveRace.exe` (Windows) — both come bundled with their required `media/` and
`levels/` directories.

To build from source instead, see [Requirements](#requirements) and
[Build and run](#build-and-run) below.

## Requirements

- A current [Odin compiler]
- Windows or macOS

No separate raylib installation or third-party package download is required.
The source imports `vendor:raylib` from the Odin distribution.

## Build and run

Reproducible package commands build the executable and copy every runtime
resource into the platform layout checked by the game:

```sh
cd "1.5 Odin (Windows & MacOS)"
./scripts/build_macos.sh release   # or debug
```

```powershell
Set-Location "1.5 Odin (Windows & MacOS)"
.\scripts\build_windows.ps1 release   # or debug
```

Outputs are `dist/macos/CaveRace.app` and `dist/windows/CaveRace.exe` with its
adjacent `media/` and `levels/` directories. Each script starts from a clean
platform output directory and fails if the executable, screen marker, or final
level is absent.

For a credentialed release, `scripts/build_macos.sh` reads
`CAVERACE_SIGN_IDENTITY` and `CAVERACE_NOTARY_PROFILE` to sign with hardened
runtime, submit, wait, staple, and validate. The Windows script optionally reads
`CAVERACE_WINDOWS_CERT_SHA1` for Authenticode signing. 

For the correctness checks used during development:

```sh
odin check . -vet -vet-cast -vet-style -vet-tabs -warnings-as-errors
```

## Controls and launch options

All player-facing flows work without a mouse. Keyboard and controller bindings
can be remapped from Settings; arrow keys and the left stick remain movement
fallbacks, while Escape/controller B stay reserved for Back. Xbox-style labels
below use raylib's standard layout. Controller rumble can be disabled
independently, and Screen Shake at 0% is exactly still.

| Input | Action |
| --- | --- |
| Arrow keys or WASD | Move; navigate menus (left stick/D-pad on controller) |
| Space / controller A | Place a bomb during gameplay; skip the current story panel |
| Enter or Space / controller A | Confirm menu and outcome actions |
| R / controller X | Quick-retry after death or start a new run from game over |
| P / controller Start | Open/close pause during active campaign or tutorial play |
| Escape / controller B | Go back; Escape retains direct active-gameplay-to-menu behavior |
| Main-menu Quit or window close | Quit safely |
| F10 | Toggle the diagnostics overlay in debug builds; absent from release builds |
| F1 | Destroy all enemies and complete the level when cheats are enabled |
| F2 | Restore four lives and eight energy when cheats are enabled |
| F3 | Grant four-bomb capacity when cheats are enabled |
| F4 | Increase bomb power, up to 10, when cheats are enabled |
| F5 | Double the score when cheats are enabled |
| 1 | Save a timestamped PNG screenshot of the current frame when cheats are enabled |

The original command-line switches remain supported:

```sh
../build/caverace -powerblast
../build/caverace -slow
```

- `-powerblast` enables F1–F5 and the 1 screenshot key. Without it, those keys do not change game state.
- `-slow` limits presentation to 30 FPS. Simulation still runs at a fixed 60 Hz.
- Unknown arguments are reported and ignored.

## Game flow

The application starts with the NavaTron branding image and its 3.84-second
audio cue, then enters the story automatically. Each panel advances automatically
when its music finishes. Space/A skips the current panel, while Escape/B skips
the complete story and opens the stable, selectable main menu. Start Game offers a
recommended tutorial on first launch. Tutorial is
always replayable from the menu, while How to Play, Settings, Replay Story,
and Quit remain directly accessible. How to Play shows the supplied
full-screen Controls artwork with a device-aware Back hint.

Each original story illustration also receives a restrained animated accent:
space and treasure twinkles, alien eye glow, fuse sparks, torch movement,
explosion smoke/embers, and homecoming sunlight motes. These overlays are fixed,
deterministic, and reduced in count, speed, and brightness by Reduced Flashes.

Gameplay uses these explicit lifecycle states:

| State | Behavior |
| --- | --- |
| Load level | Read and validate the requested `.bin` file outside the simulation update |
| Playing | Queue frame input and advance deterministic 60 Hz gameplay ticks |
| Dead | Wait for Confirm or Quick Retry, preserve score, reset level upgrades, and reload the same level |
| Won | Show time, objective, damage, medal, and an exact score ledger; Confirm loads the next level |
| Game won | Show the final victory screen after level 10; Confirm, or its music finishing, returns to the menu |
| Game over | Show the game-over screen after the last life; Quick Retry starts a run, and Confirm, or its music finishing, returns to menu |
| Load failed | Preserve valid state and allow Enter to retry or Escape to return to the menu |

P or controller Start opens a simulation-freezing pause menu with Resume,
Restart Level, Settings, Controls, and Main Menu. Restart and Main Menu require
confirmation. Focus loss opens the same pause menu by default, and queued
movement/bomb input is cleared on both pause edges. Escape retains the direct
gameplay-to-menu behavior requested for this edition.

Completing level 10 never wraps back to level 1. If the final enemy and player
are destroyed in the same update, level completion takes precedence.

## Gameplay rules

The map is 19×11 cells, rendered as 32×32 tiles on a fixed 640×400 canvas.
Windowed 1×/2×/3× modes use integer scaling where the display permits it;
borderless mode preserves aspect ratio with letterboxing when necessary.
Actors move one tile over 12 fixed simulation steps: 0.20 seconds at 60 Hz.
Frame input is buffered so a bomb press is not lost between action boundaries.
Bomb placement is independent from movement, so placing one no longer consumes
an idle movement interval. Losing window focus opens pause and suppresses
elapsed simulation time, preventing catch-up movement when focus returns.

Each new game starts with:

| Player value | Start | Maximum |
| --- | ---: | ---: |
| Lives | 4 | 4 |
| Energy | 8 | 8 |
| Simultaneous bombs | 1 | 4 |
| Bomb power | 1 | 10 |

Enemies choose a cardinal direction from the session-owned seeded gameplay
generator at each action boundary. Caves 1–4 retain fully random movement;
caves 5–10 add a modest 5–30% chance to choose a walkable step that reduces
Manhattan distance, preferring not to reverse when another reducing step is
available. Assisted halves that chance. Cosmetic variations use a
separate seeded generator, so adding a sound or visual draw cannot alter an
enemy trace. Contact
removes two energy and grants 45 fixed ticks (0.75 seconds) of contact grace on
Standard. Assisted contact removes one energy with 60 ticks of grace; Assisted
blasts remove four energy once and preview danger for the full fuse, while
Standard blasts remain lethal and preview the final 36 ticks. Damage is
communicated by a player blink, energy-HUD pulse, red flash, and pitched hit cue.
Up to 16 enemies and four bombs are stored inline in fixed arrays; gameplay does
not allocate entities dynamically.

Bombs capture the player's position and current power when placed. A bomb uses
one of four fixed slots, blocks movement through its cell, and counts down for
180 fixed ticks (3.0 seconds). Its ticking cadence accelerates and the exact
damage footprint is previewed during the final 36 ticks (0.60 seconds). Blasts
have a center plus four directional arms, can
destroy enemies, the player, treasure, and destructible objects, and trigger
other bombs deterministically without recursive entity mutation.

### Pickups and scoring

The four beneficial object types are bomb power, bomb capacity, full energy,
and an extra life. A pickup at its cap is collected as visible salvage for 25
points, clearing the cell so it cannot permanently cover treasure. Items are
checked before treasure.

| Event | Score change |
| --- | ---: |
| Collect an item | +50 |
| Salvage a capped item | +25 |
| Destroy an enemy | +75 |
| Collect treasure | +100 |
| Complete a level | +100 |
| Collect all cave treasure | +250 |
| Complete without damage | +200 |
| Complete at or under par | +150 |

Bomb placement, empty actions, retries, and restarts do not mutate score. Score
and remaining lives persist across levels. Energy is restored between caves.
On Standard, bomb capacity and power reset to their starting values at the
start of every cave — whether reached by clearing the previous one, a death
retry, or a pause-menu restart — matching the original 1.2/1.3 games. Assisted
preserves both across every one of those transitions instead.

Every cave completion displays all point sources, active bonuses, elapsed/par
time, treasure, hits, damage, deaths, final score, and medal. Bronze requires a
clear, Silver adds either all treasure or par, and Gold requires both in the
same clear. Par times are metadata, never access gates. Campaign completion and
failure do not create or save high scores, times, or medals.

Committed events also produce bounded presentation feedback: at most 64 tiny
particles and eight score popups, a maximum two-pixel optional shake, short
controller pulses, and category-limited sound voices. Reduced Flashes removes
full-screen color flashes and halves particle burst density while preserving
text, shape, sound, and optional rumble cues. These effects consume only the
cosmetic RNG stream and never influence fixed-step gameplay.

## Architecture and ownership

The project intentionally remains one `caverace` package. Files separate
responsibilities without introducing framework layers or cyclic package
dependencies.

1. `Application` owns resource/settings paths, atomic persistence calls, raylib
   handles, fixed presentation canvas, window/audio lifetime, and frame loop.
2. `Game` owns platform-independent screen routing, menu/tutorial/settings,
   gameplay, pause state, last input device, and visual feedback.
3. `Gameplay` owns the complete run: loaded mutable level data, player progress,
   fixed enemy/bomb/explosion storage, occupancy, input accumulator, selected
   difficulty profile, and separate gameplay/cosmetic RNG streams.
4. `Game_Input` is an allocation-free semantic snapshot built at the raylib
   boundary.
5. Updates return transient result structs; only `Application` turns them into
   filesystem work and audio calls.

Simulation collision uses integer sub-tile coordinates rather than rendered
screen pixels. Rendering converts those coordinates to pixels only when drawing.
Resource paths and temporary C strings are allocated explicitly and released by
their owners. Asset loading is transactional: a failed load releases partial
raylib resources and leaves the asset bundle empty.

## Source guide

### Application, platform, and presentation

| File | Responsibility |
| --- | --- |
| `caverace.odin` | Entry point, launch-option parsing call, and console messages |
| `application.odin` | Window/audio startup, scaled canvas, settings path, frame loop, crossfaded/ducked music, voice-limited SFX, rumble, and application requests |
| `options.odin` | `-powerblast` and `-slow` parsing and reporting |
| `config.odin` | Window, fixed-tick, map, theme, and content-schema constants |
| `input.odin` | raylib keyboard/Xbox-style controller state to semantic `Game_Input` mapping |
| `bindings.odin` | Remappable keyboard actions, conflict checks, labels, and last-device policy |
| `settings.odin` | Settings defaults and validation |
| `persistence.odin` | Version-4 settings-only JSON, older-version acceptance, validation, and flushed atomic sibling replacement |
| `assets.odin` | Asset manifests, loading, validation, rollback, and cleanup |
| `resources.odin` | Packaged, app-bundle, development, and working-directory resource discovery |
| `render.odin` | Top-level screen rendering, lifecycle messages, fades, and feedback flashes |
| `debug_overlay.odin` | Debug-build F10 diagnostics and collision-cell outlines |
| `level_render.odin` | Layered map, bomb, actor, and explosion rendering |
| `gameplay_hud.odin` | Read-only HUD snapshot, status icons, and score rendering |

### Front end and game routing

| File | Responsibility |
| --- | --- |
| `game.odin` | Top-level branding/story/campaign/tutorial/menu transitions, update routing, and application requests |
| `front_end.odin` | Story timing, stable title presentation, image transitions, and skip behavior |
| `story_effects.odin` | Deterministic per-panel story twinkles, glows, flame, smoke, embers, and Reduced Flashes policy |
| `menu.odin` | Main/help/settings/binding/level-select navigation and settings mutation |
| `tutorial.odin` | Dedicated tutorial map, gated learning steps, skip, completion, and replay |
| `pause.odin` | Pause selection, confirmations, focus-safe freeze, and queued-input clearing |
| `feedback.odin` | Non-blocking transition fades, accessible flashes, and bounded shake timing |
| `effects.odin` | Fixed particle/score-popup pools driven by cosmetic RNG only |

### Gameplay state and systems

| File | Responsibility |
| --- | --- |
| `gameplay_state.odin` | Gameplay value types, fixed storage, owned session state, and initialization |
| `tuning.odin` | Named gameplay tuneables and difficulty-profile values |
| `level_catalog.odin` | Fixed level names, themes, treasure totals, pars, and pursuit ramp |
| `gameplay.odin` | Per-frame gameplay lifecycle routing |
| `gameplay_loading.odin` | Validated level loading and conversion of spawn grids into active state |
| `gameplay_lifecycle.odin` | Retry, next-level, completion, final victory, game-over, and level-state cleanup rules |
| `gameplay_ticks.odin` | Input latching, action priority, fixed-step accumulation, tick order, and transient events |
| `player_movement.odin` | Walkability, grid/sub-tile/screen conversion, player movement, and animation |
| `enemy.odin` | Fixed enemy-slot access, seeded movement, sub-tile contact, and damage |
| `bomb.odin` | Capacity, placement, occupancy, fuse timing, and slot cleanup |
| `explosion.odin` | Blast footprints, map/entity effects, chain reactions, animation, and sound selection |
| `pickup.odin` | Item caps, item/treasure collection order, and pickup results |
| `scoring.odin` | Central visible, attributable score-event rules |
| `progression.odin` | Run/level telemetry, result accounting, and medals |
| `cheats.odin` | Gated F1–F5 gameplay mutations |
| `level.odin` | Original binary map layout, filenames, file I/O, and tile-index validation |

## Level data

`source/levels/` contains `01.bin` through `10.bin`. Every file is exactly
1,045 bytes and stores five 19×11 byte grids in this order:

| Layer | Bytes | Purpose |
| --- | ---: | --- |
| Background | 209 | Terrain sprite index |
| Item | 209 | Object or power-up sprite index |
| Treasure | 209 | Treasure sprite index |
| Enemy | 209 | Enemy spawn and sprite kind |
| Player | 209 | Single player spawn marker |

Before activation, the loader checks the exact file size, every sprite index,
one and only one player spawn, and the 16-enemy capacity. A validated file is
copied into mutable gameplay state; player, enemies, bombs, explosions, and bomb
occupancy are maintained separately from the stored spawn grids.

Each level has fixed metadata for its display name, tile theme, treasure total,
par time, tutorial-hint flag, and future AI-bias field.
Reloading or retrying a cave therefore preserves its visual identity. Themes
remain visual and do not change map rules.

## Media inventory

All runtime media is under `source/media/`.

| Directory | Files | Format and use |
| --- | ---: | --- |
| `intro/` | 16 | Branding PNG/OGG plus seven 640×400 PNG story panels with matching OGG narration |
| `screens/` | 5 | 640×400 PNG menu, controls, gameplay border, game-over, and victory screens |
| `music/` | 4 | Ogg Vorbis menu, level-complete, game-over, and victory cues streamed by raylib |
| `sounds/` | 9 | Ogg Vorbis gameplay and menu effects |
| `sprites/` | 6 | 32-pixel-wide vertical actor, object, treasure, bomb, and HUD sheets |
| `tiles/` | 5 | 32×1600 sheets containing 50 terrain tiles per theme |

### Music and sounds

The branding and story cues are finite, `menu.ogg` loops throughout the main
menu and Controls/Settings pages, and active tutorial/cave play is silent.
Level completion, final victory, and game over use their matching finite cues.
Cue changes use a 0.45-second two-stream
crossfade, and pause ducks both streams to 50% without advancing simulation.

The active OGG effects are four randomized bomb sounds, pitched contact,
`item.ogg`, `squish.ogg`, `ticking.ogg`, and `menu.ogg`. Repeated
events are capped per category and already-playing variants are not stacked,
preventing ticking, pickup, menu, or explosion bursts from clipping badly.

### Sprite sheets

| File | Dimensions | Stored rows | Current use |
| --- | ---: | ---: | --- |
| `bomb.png` | 32×544 | 17 | Ticking bomb and three five-frame explosion sets |
| `enemy.png` | 32×480 | 15 | Enemy kinds |
| `objects.png` | 32×416 | 13 | Map objects and power-ups |
| `player.png` | 32×544 | 17 | Idle plus four frames for each direction |
| `tools.png` | 32×160 | 5 | First four rows provide life, energy, power, and bomb HUD icons |
| `treasure.png` | 32×224 | 7 | Treasure kinds |

Startup validates all full-screen dimensions, raylib handles, sheet widths, and
minimum sprite-row counts before entering the frame loop.

## Resource lookup and deployment

The application searches for a usable resource root in this order:

1. the executable directory;
2. `../Resources` relative to the executable, for a macOS app bundle;
3. `../source` relative to a development build in `build/`;
4. the current working directory.

A standalone distribution must keep both resource directories together:

```text
CaveRace/
├── caverace              # caverace.exe on Windows
├── media/
│   ├── intro/
│   ├── music/
│   ├── screens/
│   ├── sounds/
│   ├── sprites/
│   └── tiles/
└── levels/
    ├── 01.bin
    └── ... 10.bin
```

For a macOS bundle, place `media/` and `levels/` in
`CaveRace.app/Contents/Resources/`.

Missing or invalid visual assets stop startup cleanly after partial resources
are released. If the audio device cannot initialize, the game continues
silently. Missing, truncated, or invalid levels enter the recoverable load-failed
state without replacing previously valid gameplay data.

## Historical assets and license

The original Amiga IFF artwork, PNG conversions, DOS graphics, and source level
files remain preserved under
[`1.2 Original (MS-DOS)/`](<../1.2 Original (MS-DOS)/>). See the
[repository README](../README.md) for the complete version history and archived
releases.

Copyright © 1997–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

[CaveRace]: https://caverace.com/
[Odin]: https://odin-lang.org/
[Odin compiler]: https://odin-lang.org/docs/install/
[raylib]: https://www.raylib.com/
