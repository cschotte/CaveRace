# CaveRace 1.5 rewrite for modern Windows and MacOS

This directory contains the new, cross-platform CaveRace rewrite in [Odin],
using Odin's bundled [raylib] bindings for graphics, input, and audio. It brings
the 1997 maze-based action game to modern hardware while retaining its original
pixel art, level data, and command-line conventions.

The story remains the same: miners on Eldora collect gold and diamonds, blast
paths through the caves, and defend the mines from alien visitors. CaveRace was
inspired by *Dyna Blaster* (*Bomberman*). More history and original screenshots
are available on the [CaveRace] website.

## Requirements

- A current [Odin compiler]
- Windows or macOS

No separate raylib installation is required: the source imports
`vendor:raylib` from the Odin distribution.

## Build and run

Run the following commands from this version's `source` directory:

```sh
mkdir -p ../build
odin build . -debug -out:../build/caverace
../build/caverace
```

Run the automated map and runtime-state tests from the same directory:

```sh
odin test .
```

For an optimized build, omit `-debug`. On Windows, use an `.exe` output name if
needed:

```powershell
odin build . -out:../build/caverace.exe
../build/caverace.exe
```

The repository also includes VS Code build and LLDB launch configurations. The
default build task writes the executable to `build/caverace`. Development
builds find the adjacent `source/media` and `source/levels` directories even
when launched from another working directory.

For a standalone directory, place both resource directories beside the
executable:

```text
CaveRace/
├── caverace            # caverace.exe on Windows
├── media/              # images and sounds
└── levels/             # level data      
```

On macOS application bundles, the same directories may instead be placed in
`CaveRace.app/Contents/Resources/`.

## Controls

| Key | Current action |
| --- | --- |
| Up / Down | Move through the main menu |
| 1 / 2 / 3 | Select Start Game / High Scores / Quit |
| Enter | Confirm menu selection, retry, the next level, or a high-score name |
| Mouse | Select and confirm a main-menu item |
| Escape | Return to the main menu from game or high scores |
| Arrow keys | Move the player during gameplay |
| Space | Place a bomb during gameplay |
| Space / either mouse button | Return from the high-score screen |
| F1 | Clear all enemies and complete the level (`-powerblast` only) |
| F2 | Restore four lives and eight energy (`-powerblast` only) |
| F3 | Grant four-bomb capacity (`-powerblast` only) |
| F4 | Increase bomb power up to the safe limit of 10 (`-powerblast` only) |
| F5 | Double the score (`-powerblast` only) |

The application recognizes the original `-powerblast` and `-slow` arguments:

```sh
../build/caverace -powerblast
../build/caverace -slow
```

`-slow` limits rendering to 30 FPS while gameplay simulation remains at 60 Hz.
`-powerblast` enables F1-F5 during gameplay. Without the option, those keys do
not mutate gameplay state.

## Source guide

| File | Responsibility |
| --- | --- |
| `caverace.odin` | Entry point and launch messages |
| `application.odin` | Window, audio, render loop, and application lifetime |
| `game.odin` | Application screen state and update/draw dispatch |
| `gameplay.odin` | Playing-session state, transitions, and simulation update |
| `gameplay_lifecycle.odin` | Win, retry, game-over, level-wrap, and runtime cleanup rules |
| `gameplay_lifecycle_test.odin` | Outcome precedence, retry, routing, and ten-level-cycle tests |
| `gameplay_runtime.odin` | Gameplay rules, fixed runtime entities, input scheduling, and spawn extraction |
| `gameplay_test.odin` | Map, runtime-state, input-priority, and fixed-timing regression tests |
| `cheats.odin` | Gated legacy F1-F5 gameplay mutations and safe power/score limits |
| `feedback.odin` | Non-blocking transition fades and gameplay color flashes |
| `feedback_cheat_test.odin` | Cheat gating, feedback timing, and menu-animation tests |
| `resources.odin` | Packaged, bundle, development, and working-directory resource resolution |
| `release_hardening_test.odin` | Resource failures, platform-loop policy, transition cycling, and full-run smoke tests |
| `enemy_simulation.odin` | Seeded enemy movement, rendering positions, and contact damage |
| `enemy_simulation_test.odin` | Enemy determinism, collision, timing, and damage regression tests |
| `bomb_simulation.odin` | Bomb placement, capacity, fuse timing, occupancy, and cleanup |
| `bomb_simulation_test.odin` | Bomb placement, capacity, blocking, timing, and cleanup regression tests |
| `explosion_simulation.odin` | Blast cells, animation, map/entity effects, and deterministic chain reactions |
| `explosion_simulation_test.odin` | Edge clipping, destruction, chains, overlap, scoring, and player-hit regression tests |
| `pickup_simulation.odin` | Item and treasure collection, caps, and retention rules |
| `pickup_simulation_test.odin` | Pickup timing, caps, scoring, audio, and HUD-state regression tests |
| `scoring.odin` | Central legacy score-event rules |
| `gameplay_hud.odin` | Runtime status icons and numeric score rendering |
| `level_render.odin` | Layered rendering of map tiles and runtime entities |
| `player_movement.odin` | Player walkability, tile movement, coordinate conversion, and animation |
| `player_movement_test.odin` | Player collision, movement, conversion, and animation regression tests |
| `menu.odin` | Menu state, navigation, and rendering |
| `high_score.odin` | High-score table, qualification, name entry, and rendering |
| `high_score_persistence.odin` | Versioned high-score loading, validation, and safe saving |
| `high_score_test.odin` | Defaults, entry, sorting, corruption, persistence, and routing tests |
| `input.odin` | Frame-level keyboard, text, and mouse input mapping |
| `mouse.odin` | Shared custom mouse state and rendering |
| `assets.odin` | Texture and sound loading, validation, and cleanup |
| `level.odin` | Original map data layout, loading, and index validation |
| `options.odin` | Legacy command-line option parsing |
| `config.odin` | Window, frame-rate, map, and media constants |

The map is 19×11 cells. A stored level consists of five byte grids for the
background, items, treasure, enemy spawns, and the player spawn. Mutable
player, enemy, bomb, and bomb-occupancy state is kept outside the original
on-disk structure.

High scores are stored independently of the source directory:

- macOS: `~/Library/Application Support/CaveRace/highscores.dat`
- Windows: `%LOCALAPPDATA%\CaveRace\highscores.dat`

Missing or invalid files fall back to the legacy defaults. A changed table is
written through a temporary file and then atomically renamed into place.

## Assets

Runtime assets are converted to PNG and WAV files under `media/`. They include
four full-screen images, six sprite sheets, five tile themes, eight sound
effects, and ten original `.bin` levels. The application searches beside the
executable first, then macOS bundle resources, the repository development
layout, and finally the current working directory. Screen dimensions and the
minimum sprite-sheet rows are validated before the application loop starts.

Missing visual assets cause a clean startup failure. If audio initialization
fails, the game continues silently. Missing, truncated, or invalid level files
show the recoverable **Load Failed** screen instead of replacing valid runtime
state.

The original Amiga IFF artwork and additional converted files are preserved in
the repository's
[`1.2 Original (MS-DOS)/artwork/`](<../1.2 Original (MS-DOS)/artwork/>)
directory.

## License

Copyright © 1997–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

[CaveRace]: https://caverace.com/
[Odin]: https://odin-lang.org/
[Odin compiler]: https://odin-lang.org/docs/install/
[raylib]: https://www.raylib.com/
