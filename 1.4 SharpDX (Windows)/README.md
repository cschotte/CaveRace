# CaveRace 1.4 for Windows

CaveRace 1.4 is a C# port created for Windows 8 in 2012. It is packaged as a
Windows Store app and uses SharpDX with Direct3D 11, Direct2D, and XAudio2.
This edition expands the game to more than 25 Forest, Desert, Winter, and Lava
levels.

## Historical toolchain

This is an archived Windows 8 project, not a current .NET desktop application.
Its original build environment was Visual Studio 2012 with the Windows 8 SDK.
The solution uses the retired Windows Store application project format and
cannot normally be built by current cross-platform .NET tooling.

The required SharpDX assemblies are preserved in `source/SharpDX/`; no package
restore is needed for those references. Running or deploying the app still
requires a compatible Windows Store development environment and an appropriate
developer certificate.

## Building

1. Open `source/CaveRace.sln` in a Visual Studio installation with Windows 8
   Store app support.
2. Select an `x86`, `x64`, or `ARM` configuration.
3. Build and deploy the `CaveRace Classic` project using Visual Studio.

The checked-in package manifest contains the original publisher identity and
certificate metadata. A locally trusted replacement certificate may be needed
to deploy a newly built package.

## Controls

| Input | Action |
| --- | --- |
| Arrow keys | Move |
| Space | Place a bomb |
| On-screen direction buttons | Move on a touch device |
| On-screen B button | Place a bomb on a touch device |

## Source guide

| Path | Responsibility |
| --- | --- |
| `source/CaveRace Classic/` | Windows Store application, gameplay, views, and assets |
| `source/CaveRace Classic/Code/` | Player, enemy, bomb, map, and renderer logic |
| `source/CaveRace Classic/Views/` | XAML main and game pages |
| `source/CommonDX/` | Shared DirectX device, target, texture, and rendering helpers |
| `source/SharpDX/` | Historical SharpDX assemblies and API documentation |

The app includes its level data, textures, sounds, logos, and store artwork as
project content under `source/CaveRace Classic/Assets/`.

## License

Copyright © 2012–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

More history is available in the [repository README](../README.md) and on the
[CaveRace website](https://caverace.com/).
