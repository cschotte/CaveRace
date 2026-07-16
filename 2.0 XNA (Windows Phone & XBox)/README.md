# CaveRace 2.0 for XNA

CaveRace 2.0 is a 2012 C# edition built with Microsoft XNA Game Studio 4.0. The
shared game project has targets for Windows, Windows Phone, and Xbox 360, along
with a Windows level editor and a shared XNA content pipeline project.

## Historical toolchain

This is an archived XNA solution. Its original development environment was
Visual Studio 2010 with XNA Game Studio 4.0, the .NET Framework 4.0, and the
Windows Phone development tools. Xbox 360 deployment additionally required the
XNA Creators Club tooling and a configured console.

These SDKs and project types are retired, so current Visual Studio and `dotnet`
do not build the solution directly. A preserved compatible Windows environment
is recommended.

## Building

1. Open `source/CaveRace 2.sln` in Visual Studio 2010 with XNA Game Studio 4.0.
2. Choose the desired startup project:
   - `CaveRace2Windows` for Windows
   - `CaveRace2Phone` for Windows Phone
   - `CaveRace2Xbox360` for Xbox 360
   - `MapEdit` for the Windows level editor
3. Build and deploy through Visual Studio for the selected platform.

The three game targets compile the same gameplay sources and consume the shared
`CaveRace2Content` content project.

## Controls

| Platform/input | Action |
| --- | --- |
| Keyboard arrows | Move |
| Space | Place a bomb |
| Escape | Save and return to the menu |
| Gamepad D-pad | Move |
| Gamepad A | Place a bomb or start the game |
| Gamepad B / Back | Save and return to the menu |
| Phone on-screen controls | Move and place a bomb |

## Source guide

| Path | Responsibility |
| --- | --- |
| `source/CaveRacePhone/CaveRacePhone/` | Shared game code and platform project files |
| `source/CaveRacePhone/CaveRacePhoneContent/` | Textures, sounds, fonts, and levels |
| `source/MapEdit/MapEdit/` | XNA-based Windows level editor |
| `source/MapEdit/MapEditContent/` | Level-editor content pipeline project |
| `source/Media/` | Original promotional and working artwork |

## License

Copyright © 2012–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

More history is available in the [repository README](../README.md) and on the
[CaveRace website](https://caverace.com/).
