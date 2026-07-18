# CaveRace 1.5 rewrite for modern Windows and MacOS

This directory contains the new, cross-platform CaveRace rewrite in [Odin],
using Odin's bundled [raylib] bindings for graphics, input, and audio. It brings
the 1997 maze-based action game to modern hardware while retaining its original
pixel art, level data, and command-line conventions.

The story remains the same: miners on Eldora collect gold and diamonds, blast
paths through the caves, and defend the mines from alien visitors. CaveRace was
inspired by *Dyna Blaster* (*Bomberman*). More history and original screenshots
are available on the [CaveRace] website.

## Current status

CaveRace 1.5 is a work in progress. Gameplay is not complete.
The game screen loads the original map data, validates it, extracts player and
enemy spawns into fixed runtime state, and renders the resulting level. It has
a gameplay state machine and a 60 Hz fixed-step action scheduler independent
from rendering. Player movement uses the original collision rules, 16-step
tile timing, and directional animation. Bombs, enemy movement, collisions,
scoring, high-score storage, and the original cheat effects still need to be
implemented.

## Requirements

- A current [Odin compiler]
- Windows or macOS with graphics and audio support

No separate raylib installation is required: the source imports
`vendor:raylib` from the Odin distribution.

## Build and run

Run the following commands from this version's `source` directory. The working
directory is important because the application loads assets from the relative
`media` path.

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
default build task writes the executable to `build/caverace` and launches it
with this version's `source/` directory as its working directory.

## Controls

| Key | Current action |
| --- | --- |
| Up / Down | Move through the main menu |
| 1 / 2 / 3 | Select Start Game / High Scores / Quit |
| Enter | Confirm the selected menu item |
| Mouse | Select and confirm a main-menu item |
| Escape | Return to the main menu from game or high scores |
| Arrow keys | Move the player during gameplay |
| Space / either mouse button | Return from the high-score screen |

The application recognizes the original `-powerblast` and `-slow` arguments:

```sh
../build/caverace -powerblast
../build/caverace -slow
```

`-slow` limits rendering to 30 FPS while gameplay simulation remains at 60 Hz.
`-powerblast` and F1-F5 input are recognized, but the cheat effects are not
implemented yet.

## Source guide

| File | Responsibility |
| --- | --- |
| `caverace.odin` | Entry point and launch messages |
| `application.odin` | Window, audio, render loop, and application lifetime |
| `game.odin` | Application screen state and update/draw dispatch |
| `gameplay.odin` | Playing-session state, transitions, and simulation update |
| `gameplay_runtime.odin` | Gameplay rules, fixed runtime entities, input scheduling, and spawn extraction |
| `gameplay_test.odin` | Map, runtime-state, input-priority, and fixed-timing regression tests |
| `level_render.odin` | Layered rendering of map tiles and runtime entities |
| `player_movement.odin` | Player walkability, tile movement, coordinate conversion, and animation |
| `player_movement_test.odin` | Player collision, movement, conversion, and animation regression tests |
| `menu.odin` | Menu state, navigation, and rendering |
| `high_score.odin` | High-score screen update and rendering |
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

## Assets

Runtime assets are converted to PNG and WAV files under `media/`. They include
four full-screen images, six sprite sheets, five tile themes, eight sound
effects, and ten original `.bin` levels. Keep the executable's working
directory set to `source/` unless `MEDIA_PATH` in `config.odin` is changed.

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
