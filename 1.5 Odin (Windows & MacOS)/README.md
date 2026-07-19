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

Run the automated map and gameplay-state tests from the same directory:

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
| Window close button | Quit the game |
| Escape | Skip the complete story intro or return to the main menu from gameplay |
| Space | Skip the current story panel; place a bomb during gameplay |
| Any key | Start from the title/controls screens; leave game over or the final victory screen |
| Enter | Retry after death or continue after completing levels 1–9 |
| Arrow keys | Move the player during gameplay |
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

`-slow` limits rendering to 30 FPS while fixed gameplay ticks remain at 60 Hz.
`-powerblast` enables F1-F5 during gameplay. Without the option, those keys do
not mutate gameplay state.

## Source guide

| File | Responsibility |
| --- | --- |
| `caverace.odin` | Entry point and launch messages |
| `application.odin` | Owned paths/assets, window/audio lifetime, music routing, I/O requests, and the frame loop |
| `game.odin` | Platform-independent intro, main-menu, gameplay routing, and explicit application requests |
| `front_end.odin` | Timed story sequence, shared fade transitions, looping title/controls state, and keyboard start policy |
| `front_end_test.odin` | Intro sequence, crossfade, five-second menu loop, skip, and start regression tests |
| `render.odin` | Top-level front-end, gameplay, HUD, and feedback drawing |
| `gameplay_state.odin` | Fixed gameplay capacities, value types, session state, and initialization |
| `gameplay.odin` | Playing-session state-machine update and transitions |
| `gameplay_loading.odin` | Level resource loading and validated active-state construction |
| `gameplay_lifecycle.odin` | Level completion, final victory, retry, game-over, and active-level cleanup rules |
| `gameplay_lifecycle_test.odin` | Outcome precedence, retry, routing, and ten-level victory tests |
| `gameplay_ticks.odin` | Fixed-tick input queueing and gameplay update orchestration |
| `gameplay_test.odin` | Map, level-state, input-priority, and fixed-tick regression tests |
| `cheats.odin` | Gated legacy F1-F5 gameplay mutations and safe power/score limits |
| `feedback.odin` | Non-blocking transition fades and gameplay color flashes |
| `cheats_test.odin` | Cheat gating, feedback timing, and transition tests |
| `resources.odin` | Packaged, bundle, development, and working-directory resource resolution |
| `release_test.odin` | Resource failures, platform-loop policy, transition cycling, and full-run smoke tests |
| `enemy.odin` | Seeded enemy movement, rendering positions, and contact damage |
| `enemy_test.odin` | Enemy determinism, collision, timing, and damage regression tests |
| `bomb.odin` | Bomb placement, capacity, fuse timing, occupancy, and cleanup |
| `bomb_test.odin` | Bomb placement, capacity, blocking, timing, and cleanup regression tests |
| `explosion.odin` | Blast cells, animation, map/entity effects, and deterministic chain reactions |
| `explosion_test.odin` | Edge clipping, destruction, chains, overlap, scoring, and player-hit regression tests |
| `pickup.odin` | Item and treasure collection, caps, and retention rules |
| `pickup_test.odin` | Pickup timing, caps, scoring, audio, and HUD-state regression tests |
| `scoring.odin` | Central legacy score-event rules |
| `gameplay_hud.odin` | Gameplay status icons and numeric score rendering |
| `level_render.odin` | Layered rendering of map tiles and active entities |
| `player_movement.odin` | Player walkability, tile movement, coordinate conversion, and animation |
| `player_movement_test.odin` | Player collision, movement, conversion, and animation regression tests |
| `input.odin` | Frame-level keyboard input mapping |
| `assets.odin` | Texture, sound-effect, and streamed-music loading, validation, and cleanup |
| `level.odin` | Original map data layout, loading, and index validation |
| `options.odin` | Legacy command-line option parsing |
| `config.odin` | Window, frame-rate, map, theme, and fixed content-schema constants |

The map is 19×11 cells. A stored level consists of five byte grids for the
background, items, treasure, enemy spawns, and the player spawn. Mutable
player, enemy, bomb, and bomb-occupancy state is kept outside the original
on-disk structure.

## Assets

Game assets are stored as PNG, WAV, and OGG files under `media/`. The active
build loads seven intro images, five screen images, six sprite sheets, five tile
themes, seven sound effects, fourteen streamed music tracks, and ten original
`.bin` levels. Each numbered file in `media/intro/` has an identically named
track in `media/music/` and remains visible for that track's duration. Space
skips one story panel and Escape skips the complete intro.

`screens/menu.png` and `screens/controls.png` alternate every five seconds over
looping menu music. `screens/game_border.png` frames gameplay, while
`screens/game_over.png` and `screens/you_won.png` provide the two terminal
screens. Gameplay rotates the three cave tracks by level; level complete, final
victory, and game over use their matching cues. Completing level 10 enters the
final victory state and never wraps back to level 1. Every front-end image
change uses a half-second fade through black.

The application searches beside the executable first, then macOS bundle
resources, the repository development layout, and finally the current working
directory. Screen dimensions and the minimum sprite-sheet rows are validated
before the application loop starts.

Missing visual assets cause a clean startup failure. If audio initialization
fails, the game continues silently. Missing, truncated, or invalid level files
show the recoverable **Load Failed** screen instead of replacing valid level
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
