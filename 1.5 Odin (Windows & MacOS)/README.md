# CaveRace 1.5.1

CaveRace 1.5 is the current desktop edition of the 1997
maze-action game. This edition is a from-scratch rewrite in [Odin] using
Odin's bundled [raylib] bindings for windowing, graphics, keyboard/controller
input, streamed music, and sound effects. It keeps the ten original level
files and the recognizable pixel-art rules from the DOS-era releases while
giving the game a modern, cross-platform (Windows and macOS) application loop.

## Requirements

- A current [Odin compiler]
- Windows or macOS

No separate raylib installation or third-party package download is required;
the source imports `vendor:raylib` from the Odin distribution.

## Build and run

From this directory, the reproducible package scripts build the executable and
copy every runtime resource into the platform layout the game expects:

```sh
./scripts/build_macos.sh release   # or debug
```

```powershell
.\scripts\build_windows.ps1 release   # or debug
```

Outputs are `dist/macos/CaveRace.app` and `dist/windows/CaveRace.exe` with
their adjacent `media/` and `levels/` directories. Each script starts from a
clean platform output directory and fails if the executable, screen marker,
or final level is absent.

### Debugging in VS Code

Open the repository root in VS Code, make sure `odin` is available on `PATH`,
and install the recommended CodeLLDB extension. Press F5 and select
**Debug CaveRace**. The pre-launch task creates the build directory, builds a
checked debug executable, and starts it with `source/` as its working directory
so the development assets and levels can be found.

The shared configuration emits `build/caverace` on macOS and
`build/caverace.exe` on Windows, both inside this version's directory.

Both packages carry the app icons from `icons/`: `build_macos.sh` copies
`packaging/macos/CaveRace.icns` into the bundle alongside
`packaging/macos/Info.plist` (`CFBundleIconFile`); `build_windows.ps1` and
`build_windows_store.ps1` both pass `packaging/windows/caverace.rc` (which
embeds `packaging/windows/caverace.ico`, `packaging/windows/caverace.manifest`,
and version info) to Odin's `-resource:` flag, which compiles and links it
into the executable, so the direct-distribution `.exe` and the Store `.msix`
carry identical icon/DPI/version resources. Regenerate the `.icns`/`.ico` from
`icons/*.png` if the source artwork changes.

The icon resource is named `GLFW_ICON` rather than a numbered `IDI_` constant
so raylib's GLFW backend adopts it as the live window/taskbar/Alt-Tab icon,
not just the `.exe` file icon shown in Explorer. `caverace.manifest` declares
Per-Monitor-V2 DPI awareness, matching `NSHighResolutionCapable` on macOS, so
Windows hands the process real pixels on scaled displays instead of
bitmap-stretching a low-DPI-rendered window; `rl.SetConfigFlags({.WINDOW_HIGHDPI})`
before `InitWindow` in `application.odin` is the raylib-side half of that.

For a credentialed release, `scripts/build_macos.sh` reads
`CAVERACE_SIGN_IDENTITY` and `CAVERACE_NOTARY_PROFILE` to sign with hardened
runtime, submit, wait, staple, and validate. `scripts/build_windows.ps1`
optionally reads `CAVERACE_WINDOWS_CERT_SHA1` for Authenticode signing.

Correctness checks used during development:

```sh
cd source
odin check . -vet -vet-cast -vet-style -vet-tabs -warnings-as-errors
```

Distributable builds are available in the repository's
[releases](../releases/) folder. See [CHANGELOG.md](CHANGELOG.md) for the
1.5.x version history.

## Controls and launch options

All player-facing flows work without a mouse. Keyboard and controller
bindings can be remapped from Settings; arrow keys and the left stick remain
movement fallbacks, while Escape/controller B stay reserved for Back.
Xbox-style labels below use raylib's standard layout. Controller rumble can
be disabled independently, and Screen Shake at 0% is exactly still.

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

The original `-powerblast` and `-slow` switches remain supported, and 1.5 adds
`-log`:

```sh
./dist/macos/CaveRace.app/Contents/MacOS/CaveRace -powerblast
./dist/macos/CaveRace.app/Contents/MacOS/CaveRace -slow
./dist/macos/CaveRace.app/Contents/MacOS/CaveRace -log
```

```powershell
.\dist\windows\CaveRace.exe -powerblast
.\dist\windows\CaveRace.exe -slow
.\dist\windows\CaveRace.exe -log
```

- `-powerblast` enables F1–F5 and the 1 screenshot key. Without it, those keys do not change game state.
- `-slow` limits presentation to 30 FPS. Simulation still runs at a fixed 60 Hz.
- `-log` prints detailed `[LOG]` lines tracing startup (resource root, window/audio/asset init) and key runtime events (level loads, settings saves, quits), in addition to raylib's own verbose trace log. Useful for diagnosing a crash or silent exit on another machine — ask for a `-log` run and share the last lines printed before it stops.
- Unknown arguments are reported and ignored.

## Level data

`source/levels/` contains `01.bin` through `10.bin`, carried over unchanged
from the original 1.2/1.3 releases. Every file is exactly 1,045 bytes and
stores five 19×11 byte grids in this order:

| Layer | Bytes | Purpose |
| --- | ---: | --- |
| Background | 209 | Terrain sprite index |
| Item | 209 | Object or power-up sprite index |
| Treasure | 209 | Treasure sprite index |
| Enemy | 209 | Enemy spawn and sprite kind |
| Player | 209 | Single player spawn marker |

Before activation, the loader checks the exact file size, every sprite
index, one and only one player spawn, and the 16-enemy capacity. A validated
file is copied into mutable gameplay state; player, enemies, bombs,
explosions, and bomb occupancy are maintained separately from the stored
spawn grids.

Each level has fixed metadata for its display name, tile theme, treasure
total, par time, tutorial-hint flag, and enemy-pursuit bias. Reloading or
retrying a cave therefore preserves its visual identity. Themes remain
visual and do not change map rules.

---

Copyright © 1997–2026 NavaTron B.V. All rights reserved.

[Odin]: https://odin-lang.org/
[Odin compiler]: https://odin-lang.org/docs/install/
[raylib]: https://www.raylib.com/
