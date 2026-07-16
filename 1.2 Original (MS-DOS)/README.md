# CaveRace 1.2 for MS-DOS

This directory preserves the original CaveRace release and source code. The
game was created in 1997 and version 1.2 was dated May 1998. It targets an
80386-compatible IBM PC running MS-DOS and uses 320×200, 256-color VGA graphics
(Mode 13h).

CaveRace is a maze-based action game inspired by *Dyna Blaster* (*Bomberman*).
The player collects gold and diamonds, clears passages with bombs, and defeats
enemies in the mines of Eldora.

## Running the game

The easiest way to run this historical version is with DOSBox or a comparable
MS-DOS environment:

1. Extract `/releases/caverace-1.2-dos.zip`.
2. Mount the extracted directory in DOSBox.
3. Run `CAVERACE.EXE`.

The game expects its `graphics` and `levels` directories beside the executable.
`MAPEDIT.EXE` is the original level editor. A mouse driver must be available in
the DOS environment.

## Controls and options

The menus use the mouse. Gameplay uses the keyboard; bombs are placed with the
space bar. Start the game with `-powerblast` to enable these cheats:

| Key | Action |
| --- | --- |
| F1 | Advance to the next level |
| F2 | Restore maximum health |
| F3 | Give the maximum number of bombs |
| F4 | Increase bomb power |
| F5 | Double the score |

The `-slow` option skips display-refresh synchronization and was intended for
slower PCs.

## Building the source

The source is a historical Borland C 3.1 codebase with DOS-specific VGA,
keyboard, mouse, memory, and x86 assembly routines. No modern project file is
included. Build `source/CaveRace.c` and `source/MapEdit.c` as separate DOS
programs in the original compiler, with `source/` as the working directory so
the relative `include`, `graphics`, and `levels` paths resolve correctly.

Modern compilers will require a port because the code relies on Borland and DOS
APIs that are no longer available.

## Directory guide

| Path | Contents |
| --- | --- |
| `release/` | Ready-to-run executables and game data |
| `source/` | Original C/C++ source, headers, converted graphics, and levels |
| `artwork/` | Original Amiga IFF artwork and PNG conversions |

## License

Copyright © 1997–2026 NavaTron B.V. The source code is licensed under the
[Apache License 2.0](../LICENSE).

More history is available in the [repository README](../README.md) and on the
[CaveRace website](https://caverace.com/).
