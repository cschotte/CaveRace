# CaveRace 1.5 for Odin

This directory contains the new, cross-platform CaveRace rewrite in [Odin],
using Odin's bundled [raylib] bindings for graphics, input, and audio. It brings
the 1997 maze-based action game to modern hardware while retaining its original
pixel art, level data, and command-line conventions.

The story remains the same: miners on Eldora collect gold and diamonds, blast
paths through the caves, and defend the mines from alien visitors. CaveRace was
inspired by *Dyna Blaster* (*Bomberman*). More history and original screenshots
are available on the [CaveRace project page].

## Current status

CaveRace 1.5 is a work in progress. Gameplay is not complete.
The game screen currently displays its background;
level loading and rendering, player movement, bombs, enemies, treasure,
collisions, scoring, high-score storage, and the original cheat effects still
need to be implemented.

## Requirements

- A current [Odin compiler]
- Windows or macOS with graphics and audio support

No separate raylib installation is required: the source imports
`vendor:raylib` from the Odin distribution.

## Build and run

Run the following commands from this `Odin` directory. The working directory is
important because the application loads assets from the relative `media` path.

```sh
mkdir -p ../build
odin build . -debug -out:../build/caverace
../build/caverace
```

For an optimized build, omit `-debug`. On Windows, use an `.exe` output name if
needed:

```powershell
odin build . -out:../build/caverace.exe
../build/caverace.exe
```

The repository also includes VS Code build and LLDB launch configurations. The
default build task writes the executable to `build/caverace` and launches it
with `Odin/` as its working directory.

## Controls

| Key | Current action |
| --- | --- |
| Up / Down | Move through the main menu |
| 1 / 2 / 3 | Select Start Game / High Scores / Quit |
| Enter | Confirm the selected menu item |
| Escape | Return to the main menu from game or high scores |

The application recognizes the original `-powerblast` and `-slow` arguments:

```sh
../build/caverace -powerblast
../build/caverace -slow
```

These options are parsed and reported at startup, but their gameplay behavior
is not implemented yet.

## Source guide

| File | Responsibility |
| --- | --- |
| `caverace.odin` | Entry point and launch messages |
| `application.odin` | Window, audio, main loop, and application lifetime |
| `game.odin` | Game state and screen update/draw dispatch |
| `menu.odin` | Menu state, navigation, and rendering |
| `input.odin` | Keyboard input mapping |
| `assets.odin` | Texture and sound loading, validation, and cleanup |
| `level.odin` | Original map data layout and runtime level state |
| `options.odin` | Legacy command-line option parsing |
| `config.odin` | Window, frame-rate, map, and media constants |

The map is 19×11 cells. A stored level consists of five byte grids for the
background, items, treasure, enemies, and player state. Bombs are runtime state
and are therefore kept outside the original on-disk structure.

## Assets

Runtime assets are converted to PNG and WAV files under `media/`. They include
four full-screen images, six sprite sheets, five tile themes, eight sound
effects, and ten original `.bin` levels. Keep the executable's working
directory set to `Odin/` unless `MEDIA_PATH` in `config.odin` is changed.

The original Amiga IFF artwork and additional converted files are preserved in
the repository's [`Artwork/`](../Artwork/) directory.

## License

Copyright © 1997–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

[CaveRace project page]: https://caverace.com/
[Odin]: https://odin-lang.org/
[Odin compiler]: https://odin-lang.org/docs/install/
[raylib]: https://www.raylib.com/
