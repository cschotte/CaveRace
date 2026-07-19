# CaveRace 1.5 — Odin rewrite for Windows and macOS

CaveRace 1.5 is the current desktop edition of the 1997 maze-action game. It
is written in [Odin] and uses Odin's bundled [raylib] bindings for windowing,
graphics, keyboard input, streamed music, and sound effects. The rewrite keeps
the ten original level files and the recognizable pixel-art rules while giving
the game a modern, cross-platform application loop.

| Forest | Winter | Lava |
| --- | --- | --- |
| ![Forest level](../images/demo1.png) | ![Winter level](../images/demo2.png) | ![Lava level](../images/demo3.png) |

The implemented game includes the complete seven-panel story intro, alternating
title and controls screens, all ten levels, player and enemy movement, bombs,
chain reactions, pickups, scoring, retries, level progression, game over, and a
final victory screen.

## Requirements

- A current [Odin compiler]
- Windows or macOS

No separate raylib installation or third-party package download is required.
The source imports `vendor:raylib` from the Odin distribution.

## Build and run

From the repository root on macOS or a Unix-like shell:

```sh
cd "1.5 Odin (Windows & MacOS)/source"
mkdir -p ../build
odin build . -debug -out:../build/caverace
../build/caverace
```

For an optimized build, omit `-debug`. On Windows, give the output an `.exe`
suffix:

```powershell
Set-Location "1.5 Odin (Windows & MacOS)/source"
New-Item -ItemType Directory -Force ../build | Out-Null
odin build . -debug -out:../build/caverace.exe
../build/caverace.exe
```

Run the automated suite from the `source` directory:

```sh
odin test .
```

For the same style and correctness checks used during development:

```sh
odin check . -vet -vet-cast -vet-style -vet-tabs -warnings-as-errors
```

The repository's `.vscode/tasks.json` defines `odin: build debug` as the
default build task. `.vscode/launch.json` builds and launches
`build/caverace` through LLDB with `source/` as the working directory.

## Controls and launch options

The current edition is keyboard-controlled.

| Input | Action |
| --- | --- |
| Window close button | Quit |
| Any key | Start from the title or controls screen; leave game over or final victory |
| Arrow keys | Move during gameplay |
| Space | Skip one story panel; place a bomb during gameplay |
| Enter | Retry after death; continue after levels 1–9; retry a failed level load |
| Escape | Skip the complete intro; return from gameplay to the main menu |
| F1 | Destroy all enemies and complete the level when cheats are enabled |
| F2 | Restore four lives and eight energy when cheats are enabled |
| F3 | Grant four-bomb capacity when cheats are enabled |
| F4 | Increase bomb power, up to 10, when cheats are enabled |
| F5 | Double the score when cheats are enabled |

The original command-line switches remain supported:

```sh
../build/caverace -powerblast
../build/caverace -slow
../build/caverace -powerblast -slow
```

- `-powerblast` enables F1–F5. Without it, those keys do not change game state.
- `-slow` limits presentation to 30 FPS. Simulation still runs at a fixed 60 Hz.
- Unknown arguments are reported and ignored.

## Game flow

The application starts with the story intro. Space advances one panel and
Escape skips directly to the main menu. The title and controls screens then
alternate every five seconds until any key starts a new game.

Gameplay uses these explicit lifecycle states:

| State | Behavior |
| --- | --- |
| Load level | Read and validate the requested `.bin` file outside the simulation update |
| Playing | Queue frame input and advance deterministic 60 Hz gameplay ticks |
| Dead | Wait for Enter, apply the retry penalty, reset level upgrades, and reload the same level |
| Won | Wait for Enter, preserve run progress, and load the next level |
| Game won | Show the final victory screen after level 10; any key returns to the menu |
| Game over | Show the game-over screen after the last life; any key returns to the menu |
| Load failed | Preserve valid state and allow Enter to retry or Escape to return to the menu |

Completing level 10 never wraps back to level 1. If the final enemy and player
are destroyed in the same update, level completion takes precedence.

## Gameplay rules

The map is 19×11 cells, rendered as 32×32 tiles in a fixed 640×400 window.
Actors move one tile over 16 fixed simulation steps. Frame input is buffered so
a bomb press is not lost between action boundaries. Losing window focus clears
queued input and pauses elapsed simulation time, preventing catch-up movement
when focus returns.

Each new game starts with:

| Player value | Start | Maximum |
| --- | ---: | ---: |
| Lives | 4 | 4 |
| Energy | 8 | 8 |
| Simultaneous bombs | 1 | 4 |
| Bomb power | 1 | 10 |

Enemies choose a cardinal direction from the session-owned seeded random
generator at each action boundary. Contact removes two energy once per action.
Up to 16 enemies and four bombs are stored inline in fixed arrays; gameplay does
not allocate entities dynamically.

Bombs capture the player's position and current power when placed. A bomb uses
one of four fixed slots, blocks movement through its cell, and counts down for
12 action boundaries. Blasts have a center plus four directional arms, can
destroy enemies, the player, treasure, and destructible objects, and trigger
other bombs deterministically without recursive entity mutation.

### Pickups and scoring

The four beneficial object types are bomb power, bomb capacity, full energy,
and an extra life. A pickup at its cap remains on the map. Items are checked
before treasure, so an uncollectable capped item continues to cover treasure in
the same cell.

| Event | Score change |
| --- | ---: |
| Place a bomb | −5 when at least 5 points are available |
| Collect an item | +50 |
| Destroy an enemy | +75 |
| Collect treasure | +100 |
| Complete a level | +100 |
| Confirm a retry | −50 when at least 50 points are available |

The legacy action-floor rule changes a zero score to 5 after an action. Score
and remaining lives persist across levels. Energy, bomb capacity, and bomb
power reset to their starting values on retry and when entering the next level.

## Architecture and ownership

The project intentionally remains one `caverace` package. Files separate
responsibilities without introducing framework layers or cyclic package
dependencies.

1. `Application` owns the allocated resource root, raylib handles, window and
   audio lifetime, active music stream, and frame loop.
2. `Game` owns platform-independent screen routing, front-end state, gameplay,
   and visual feedback.
3. `Gameplay` owns the complete run: loaded mutable level data, player progress,
   fixed enemy/bomb/explosion storage, occupancy, input accumulator, and RNG.
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
| `application.odin` | Window/audio startup, owned resource lifetime, frame loop, music routing, sound playback, and level-load requests |
| `options.odin` | `-powerblast` and `-slow` parsing and reporting |
| `config.odin` | Window, fixed-tick, map, theme, and content-schema constants |
| `input.odin` | raylib keyboard state to semantic `Game_Input` mapping |
| `assets.odin` | Asset manifests, loading, validation, rollback, and cleanup |
| `resources.odin` | Packaged, app-bundle, development, and working-directory resource discovery |
| `render.odin` | Top-level screen rendering, lifecycle messages, fades, and feedback flashes |
| `level_render.odin` | Layered map, bomb, actor, and explosion rendering |
| `gameplay_hud.odin` | Read-only HUD snapshot, status icons, and score rendering |

### Front end and game routing

| File | Responsibility |
| --- | --- |
| `game.odin` | Top-level screen state, new-game/menu transitions, update routing, and application requests |
| `front_end.odin` | Story timing, title/controls loop, image transitions, skip behavior, and start policy |
| `feedback.odin` | Non-blocking transition fades and damage/item/treasure flashes |

### Gameplay state and systems

| File | Responsibility |
| --- | --- |
| `gameplay_state.odin` | Fixed capacities, rule constants, gameplay value types, owned session state, and initialization |
| `gameplay.odin` | Per-frame gameplay lifecycle routing |
| `gameplay_loading.odin` | Validated level loading and conversion of spawn grids into active state |
| `gameplay_lifecycle.odin` | Retry, next-level, completion, final victory, game-over, and level-state cleanup rules |
| `gameplay_ticks.odin` | Input latching, action priority, fixed-step accumulation, tick order, and transient events |
| `player_movement.odin` | Walkability, grid/sub-tile/screen conversion, player movement, and animation |
| `enemy.odin` | Fixed enemy-slot access, seeded movement, sub-tile contact, and damage |
| `bomb.odin` | Capacity, placement, occupancy, fuse timing, and slot cleanup |
| `explosion.odin` | Blast footprints, map/entity effects, chain reactions, animation, and sound selection |
| `pickup.odin` | Item caps, item/treasure collection order, and pickup results |
| `scoring.odin` | Central legacy score-event rules |
| `cheats.odin` | Gated F1–F5 gameplay mutations |
| `level.odin` | Original binary map layout, filenames, file I/O, and tile-index validation |

### Tests

| File | Coverage |
| --- | --- |
| `front_end_test.odin` | Intro timing and skip flow, crossfades, menu loop, start behavior, and music cues |
| `gameplay_test.odin` | Initialization, every level, validation, spawn extraction, fixed ticks, input priority, and limits |
| `gameplay_lifecycle_test.odin` | Win/death precedence, retries, routing, all ten levels, and final victory |
| `player_movement_test.odin` | Walkability, coordinate equivalence, movement timing, collisions, and animation |
| `enemy_test.odin` | Seed determinism, rate independence, movement, contact, damage, and all-level walkability |
| `bomb_test.odin` | Placement, score cost, capacity, occupancy, timing, blocking, and cleanup |
| `explosion_test.odin` | Edge clipping, animation, destruction, chains, overlap, scoring, and player damage |
| `pickup_test.odin` | Every pickup, caps, timing, scoring, audio requests, and HUD snapshots |
| `cheats_test.odin` | Cheat gating and limits, feedback priority, and non-blocking transitions |
| `release_test.odin` | Resource resolution/failure, focus policy, repeated routing, and a complete-run smoke test |

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

Each successful load chooses one of five tile themes—Desert, Forest, Lava, Oil,
or Winter—from the session RNG. The theme is visual and does not change the map
rules.

## Media inventory

All runtime media is under `source/media/`.

| Directory | Files | Format and use |
| --- | ---: | --- |
| `intro/` | 7 | 640×400 PNG story panels |
| `screens/` | 5 | 640×400 PNG menu, controls, gameplay border, game-over, and victory screens |
| `music/` | 14 | 48 kHz stereo Ogg Vorbis tracks streamed by raylib |
| `sounds/` | 8 | WAV effects; seven are loaded by the current game |
| `sprites/` | 6 | 32-pixel-wide vertical actor, object, treasure, bomb, and HUD sheets |
| `tiles/` | 5 | 32×1600 sheets containing 50 terrain tiles per theme |

### Story panels and timing

Each intro panel has a matching numbered music track and remains on screen for
the duration encoded in `front_end.odin`.

| Panel | Image and track stem | Seconds |
| ---: | --- | ---: |
| 1 | `01_intro_eldora` | 40.474 |
| 2 | `02_intro_mining` | 31.455 |
| 3 | `03_intro_aliens` | 39.962 |
| 4 | `04_intro_defense` | 36.174 |
| 5 | `05_intro_hero` | 32.366 |
| 6 | `06_intro_bombs` | 30.866 |
| 7 | `07_intro_protect` | 9.187 |

Front-end image changes crossfade through black over 0.5 seconds. Screen and
gameplay-state changes also start a non-blocking 0.4-second black overlay.
Damage, item, and treasure events produce short red, green, and blue flashes.

### Music and sounds

The menu loops `08_main_menu.ogg`. Levels rotate through
`09_gameplay_a.ogg`, `10_gameplay_b.ogg`, and `11_gameplay_c.ogg` by level
index. Level completion, final victory, and game over use tracks 12, 13, and 14
respectively. Intro and outcome tracks are finite; menu and cave tracks loop.

The active WAV effects are four randomized bomb sounds, `item.wav`,
`squish.wav`, and `ticking.wav`. `menu.wav` is retained as a legacy media file
but is not loaded; menu audio comes from the streamed OGG track.

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
