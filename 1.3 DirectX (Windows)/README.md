# CaveRace 1.3 for Windows

CaveRace 1.3 is the 2002 Windows port of the original maze-based action game.
It is written in C++ and replaces the MS-DOS VGA code with DirectX 8.1 for
graphics, input, and audio while retaining the original ten levels and core
gameplay.

## Running the game

`caverace-1.3-win.zip`, available on the
[v1.3-directx release](https://github.com/cschotte/CaveRace/releases/tag/v1.3-directx),
contains the complete historical release. Extract the entire archive and run
`CaveRace.exe` on a compatible 32-bit Windows system.
Keep the `Levels` and `Media` directories beside the executable; the game loads
those files through relative paths.

This version requires DirectX 8.1 or later. Compatibility settings or a virtual
machine may be necessary on current Windows versions.

## Controls

| Input | Action |
| --- | --- |
| Arrow keys | Move the player or navigate the menu |
| Enter | Select a menu item |
| Space | Place a bomb; leave the high-score screen |
| Escape | Return to the menu |
| Mouse | Navigate and select menu items |

## Building the source

The source includes a Visual C++ 6 workspace (`source/Main.dsw`) and project
(`source/Main.dsp`). Open the workspace in Microsoft Visual C++ 6 and select
either the `Main - Win32 Debug` or `Main - Win32 Release` configuration.

The project targets 32-bit x86 Windows and links against the DirectX 8 SDK
libraries, including Direct3D 8, D3DX 8, DirectInput 8, and WinMM. Rebuilding
with a modern Visual Studio and Windows SDK will require project conversion and
likely compatibility changes.

The source refers to runtime assets under `Media/` and `Levels/`. Those assets
are present in the release ZIP but are not duplicated in the source directory.

## Source guide

| File | Responsibility |
| --- | --- |
| `WinMain.cpp` | Windows entry point, window creation, and application lifetime |
| `MainLoop.cpp` | Menus, gameplay, levels, sprites, bombs, and enemies |
| `mmGraphics.cpp` | Direct3D display, texture, sprite, and back-buffer handling |
| `mmControls.cpp` | DirectInput keyboard and mouse handling |
| `mmAudio.cpp` | Audio loading and playback |
| `Resource.rc` | Application icon and version information |

## License

Copyright © 2002–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

More history is available in the [repository README](../README.md) and on the
[CaveRace website](https://caverace.com/).
