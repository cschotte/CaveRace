# CaveRace 1.5 version history

## 1.5.4

- Redesigned the level-complete screen as a cleaner two-column summary with a
  framed celebration portrait, medal badge, aligned run statistics, emphasized
  score earned, and a separated total-score/continue footer.
- Added three celebration portraits; the game now randomly selects one whenever
  a cave is completed.
- Successful time and treasure results now receive clearer color feedback, and
  negative score adjustments display with the correct sign.

## 1.5.3

- Pressing Escape (or controller B) during active gameplay now opens the pause
  menu with its "abandon run?" confirmation, instead of leaving for the main
  menu instantly; Pause's own Main Menu option worked this way already.
- Closing pause now plays the same menu sound as opening it.
- Dying now plays a distinct sound instead of only the controller rumble.
- The Game Over and Victory screens now show a dynamic, binding-aware prompt
  ("R FOR A NEW GAME, ENTER FOR MENU" / "ENTER TO CONTINUE") instead of
  relying only on the baked artwork, matching the Dead and Load Failed
  screens.

## 1.5.2

- Added mouse hover and click support to the main menu, first-run choice,
  Settings, control bindings, How to Play, pause menu, and pause confirmation
  dialogs.
- Clicking any mouse button now skips the current intro story panel.
- Settings now show clickable decrease/increase controls; the mouse wheel can
  also adjust the hovered setting.
- Added mouse-wheel menu navigation and right-click Back behavior while
  preserving all existing keyboard and controller controls.
- Mouse hit testing uses the fixed 640x400 presentation space, so controls stay
  aligned in scaled windows, borderless mode, and letterboxed aspect ratios.

## 1.5.1

- The game window now opens centered on the current monitor instead of at
  the platform's default position.
- Changing the window scale in Settings re-centers the window at its new
  size instead of leaving it anchored to its previous top-left corner.
- Windows: the executable now declares Per-Monitor-V2 DPI awareness
  (`packaging/windows/caverace.manifest`) and enables raylib's
  `WINDOW_HIGHDPI` flag, so the game renders at native resolution on scaled
  displays instead of being bitmap-stretched by Windows, matching the
  existing `NSHighResolutionCapable` behavior on macOS.
- Windows: the embedded icon resource is now named `GLFW_ICON` so it is
  adopted as the running window's title bar/taskbar/Alt-Tab icon, not just
  the `.exe` file icon shown in Explorer.
- Windows: the version resource now also sets `InternalName` and
  `OriginalFilename`, shown in Explorer's file Properties → Details tab.
- Windows Store package: `build_windows_store.ps1` now also passes
  `packaging/windows/caverace.rc` to Odin's `-resource:` flag, so the
  DPI-awareness manifest, `GLFW_ICON`, and version info above apply to the
  `.msix` build too, not just the direct-distribution `.exe` (previously the
  Store build compiled with no resource file at all).
- Windows Store package: `MaxVersionTested` bumped from 10.0.22621.0 (22H2)
  to 10.0.26100.0 (24H2).

## 1.5.0

- Initial release of the 1.5 edition: a from-scratch rewrite of CaveRace in
  [Odin](https://odin-lang.org/) using Odin's bundled
  [raylib](https://www.raylib.com/) bindings, for Windows and macOS.
- Carries over the ten original level files and pixel-art rules from the
  DOS-era releases with a modern, cross-platform application loop.
