# CaveRace 1.5.4

CaveRace 1.5.4 is the finished desktop edition of the 1997 maze-action game.
This from-scratch rewrite uses [Odin] and its bundled [raylib] bindings to run
the original ten caves on modern Windows and macOS systems.

Enter the mines of Eldora, collect treasure, open passages with bombs, and
defeat every alien to clear each cave. Bombs can also destroy treasure,
power-ups, and the player, so careful placement and a safe escape route are
essential.

CaveRace is fully offline and contains no accounts, advertising, in-app
purchases, analytics, or online services.

## Release status

Version 1.5.4 is under code and documentation freeze. Changes are limited to
issues identified during Apple App Store or Microsoft Store submission and
certification. Other development belongs in a future version.

See [CHANGELOG.md](CHANGELOG.md) for the complete 1.5 release history.

## Features

- Ten preserved caves from the original CaveRace releases
- Original story and recognizable pixel-art gameplay
- Campaign and interactive tutorial
- Standard and Assisted difficulty profiles
- Keyboard, mouse, and controller support with remappable controls
- Windowed and borderless display modes with 1×, 2×, and 3× scaling
- Adjustable music, sound effects, screen shake, controller rumble, reduced
  flashes, high-contrast bomb previews, and focus-loss pausing
- Automatic one-minute gameplay demonstrations when the main menu is idle
- Local settings storage; no network connection is required

## System requirements

| Platform | Minimum version | Architecture |
| --- | --- | --- |
| Windows | Windows 10 version 1809 | 64-bit x86 |
| macOS | macOS 10.15 Catalina | Intel or Apple silicon |

A keyboard is sufficient. A mouse or compatible game controller is optional.

## Installation

Download CaveRace for Windows or macOS from the
[official CaveRace website](https://caverace.com/).

- On macOS, place `CaveRace.app` in Applications and launch it normally.
- On Windows, keep `CaveRace.exe`, `media/`, and `levels/` together in the same
  distribution folder. Microsoft Store installations manage these files
  automatically.

## Controls

Menus support keyboard, controller, and mouse navigation. Moving the pointer
over a row selects it; left-click activates it; right-click goes back; and the
mouse wheel navigates or adjusts the selected setting.

Keyboard and controller gameplay bindings can be changed in Settings. Arrow
keys and the left stick remain movement fallbacks, while Escape and controller
B remain reserved for Back.

| Input | Action |
| --- | --- |
| Arrow keys or WASD | Move; navigate menus |
| Controller D-pad or left stick | Move; navigate menus |
| Space or controller A | Place a bomb; confirm; skip the current story panel |
| Enter | Confirm menu and outcome actions |
| R or controller X | Retry after death or begin a new run after game over |
| P or controller Start | Open or close the pause menu |
| Escape or controller B | Go back; during gameplay, open pause with an abandon-run confirmation |
| Mouse | Select and activate menu actions |
| Mouse wheel | Navigate menus or adjust a hovered setting |
| Right mouse button | Go back |
| Main-menu Quit or window close | Quit safely |

## Demo mode

After one minute without input on the main menu, CaveRace starts a one-minute
automated demonstration. The demonstrations alternate between caves 1 and 2.
Any keyboard key, controller action, or mouse click immediately returns to the
main menu, where the idle cycle begins again.

Demo mode uses the selected difficulty and exactly the same starting stats,
pickups, bomb behavior, damage, and enemy rules as normal gameplay. Only the
player input is automated. The idle timer pauses outside the main menu and
while the game window is unfocused.

## Settings

Settings are saved automatically in the operating system's per-user
application-data location. If the settings file is missing or invalid, the
game starts with safe defaults.

The Settings menu provides:

- Music and sound-effect volume
- Windowed or borderless display
- Window scale
- Reduced flashes and screen-shake strength
- Controller rumble
- High-contrast bomb danger previews
- Pause on focus loss
- Standard or Assisted difficulty
- Keyboard and controller rebinding

## Launch options

The desktop executable accepts three optional command-line switches:

| Option | Purpose |
| --- | --- |
| `-powerblast` | Enable the original function-key cheats and screenshot key |
| `-slow` | Limit presentation to 30 FPS while gameplay remains fixed at 60 Hz |
| `-log` | Print detailed startup and runtime diagnostics for support cases |

Unknown arguments are reported and ignored.

When `-powerblast` is active:

| Key | Result |
| --- | --- |
| F1 | Destroy all enemies and complete the current cave |
| F2 | Restore four lives and eight energy |
| F3 | Grant four-bomb capacity |
| F4 | Increase bomb power, up to 10 |
| F5 | Double the score |
| 1 | Save a timestamped PNG screenshot |

## Building from source

A current [Odin compiler] is required. No separate raylib installation or
third-party package download is needed because the source imports
`vendor:raylib` from the Odin distribution.

Run the appropriate command from this `1.5 Odin (Windows & MacOS)` directory.

### Direct distribution

macOS:

```sh
./scripts/build_macos.sh release
```

Windows PowerShell:

```powershell
.\scripts\build_windows.ps1 release
```

The resulting packages are written to `dist/macos/CaveRace.app` and
`dist/windows/`. Passing `debug` instead of `release` creates a checked debug
build.

The macOS script optionally uses `CAVERACE_SIGN_IDENTITY` and
`CAVERACE_NOTARY_PROFILE` for Developer ID signing and notarization. The
Windows script optionally uses `CAVERACE_WINDOWS_CERT_SHA1` for Authenticode
signing.

### Store submission packages

Mac App Store:

```sh
./scripts/build_macos_appstore.sh release
```

This creates a universal Intel/Apple-silicon `CaveRace.pkg` in
`dist/macos-appstore/`. The script requires the Apple distribution identity,
installer identity, and provisioning profile described in the script.

Microsoft Store:

```powershell
.\scripts\build_windows_store.ps1 release
```

This creates `dist/windows-store/CaveRace.msix`. It requires the Windows SDK
and the final Partner Center identity in `packaging/windows-store/AppxManifest.xml`.
The Microsoft Store applies its own signature during certification.

All packaging scripts compile with strict Odin vetting and warnings treated as
errors, copy the required media and level resources, and verify the package's
essential files before completing.

## Preserved game content

The files `source/levels/01.bin` through `10.bin` are the original CaveRace
level data. The 1.5 loader validates each file before play, while keeping live
player, enemy, bomb, and explosion state separate from the preserved data.

The five visual themes are presentation-only and do not alter the rules of a
cave.

## Privacy and support

The privacy policy used for Store distribution is available at
[navatron.com/privacy](https://navatron.com/privacy/). For game information and
support, visit the [official CaveRace website](https://caverace.com/).

For startup or packaging problems, run the direct-distribution executable with
`-log` and include the final diagnostic lines with the report.

## License

Copyright © 1997–2026 NavaTron B.V.

The source code is licensed under the [Apache License 2.0](../LICENSE). Game
content, artwork, music, and sound effects remain copyright NavaTron B.V.

[Odin]: https://odin-lang.org/
[Odin compiler]: https://odin-lang.org/docs/install/
[raylib]: https://www.raylib.com/
