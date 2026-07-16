# CaveRace

Classic maze-based video game from 1997.

> **Modern rewrite:** CaveRace is being rewritten from its original C code in
> [Odin] so the game can run again on modern hardware and operating systems.
> The original C source remains in this repository for historical reference.

![demo1](Artwork/demo1.png)

## System requirements

Intel 80386 IBM compatible PC running MS-DOS and VGA 320×200 pixels (Mode 13h) in 256-color mode video system.

## Graphics

The original artwork is created by Marijn Schotte on an Amiga using [Deluxe Paint] in the file format IFF (Interchange File Format). The game CaveRace is using a binary RGB byte file format. Game tiles (16 x 16 pixels) and screens (320 x 200 pixels) are converted to this binary RGB byte file format.

| File | Tiles         | Bytes   | Description |
| ---- | ------------- | ------- | ----------- |
| BGS  | 5 x 50(16x16) | 64000   | BackGrounds
| BOM  | 17 x (16x16)  | 4352    | Boms
| CAR  | 320 x 200     | 64000   | Carder (Picture)
| ENM  | 16 x (16x16)  | 4096    | Enemys
| FNT  | 36 x (3x5)    | 540     | Font
| HIS  | 320 x 200     | 64000   | Hi-Scores (Picture)
| ITM  | 13 x (16x16)  | 3328    | Items
| MAN  | 18 x (16x16)  | 4608    | Man
| MN1  | 320 x 200     | 64000   | Menu 1 (Picture)
| MN2  | 320 x 200     | 64000   | Menu 2 (Picture)
| PAL  | 256 x (RGB)   | 768     | Palette
| STS  | 4 x (16x16)   | 1024    | Status
| TRS  | 6 x (16x16)   | 1536    | Treacure

## How to compile

The source code is mainly plain C, but it also has some assembly code for memory and graphics routines. The compiler and linker used is [Borland C] 3.1 (not Turbo C). In Borland C set the working directory to the project folder and you can compile CaveRace and the MapEditor.

## Game cheats

Start the game using the switch **-powerblast**, now you can use the function keys for additional power.

| Key | Result |
| --- | ------ |
| F1  | next level
| F2  | max. health
| F3  | max. bombs
| F4  | more bomb power
| F5  | double points
| 1   | screen capture, output is saved to the file screen.raw
| %   | shows the rendering time

When running the game on old slow systems, you can use the **-slow** switch to speed up the game.

## Versions

| Version | Year      | OS      | Lang      | GFX         |
| ------- | --------- | ------- | --------- | ----------- |
| 1.2     | 1997      | MS-DOS  | Borland C | VGA         |
| 1.3     | 2002      | Windows | C         | DirectX 8.1 |
| 1.4     | 2012      | Windows | C#        | SharpDX     |
| 2.0     | 2012      | Windows Phone 7 & XBox | C# | XNA |
| 1.5     | 2026      | Windows & MacOS | Odin | RayLib 6 |

## Origninal project team for version 1.0

- Clemens Schotte (code and concept)
- Harro Lock (code)
- Marijn Schotte (artwork)
- Paul Bosselaar (documenation)
- Paul van Croonenburg (documenation)

> from version 1.3 and later, coded by Clemens Schotte and artwork by Marijn Schotte

## License

Copyright (c) 2026 by NavaTron B.V. All rights reserved.

*Code License: [Apache-2.0](LICENSE)*

Applies to all other files

[Borland C]: <https://en.wikipedia.org/wiki/Borland_C%2B%2B>
[Deluxe Paint]: <https://en.wikipedia.org/wiki/Deluxe_Paint>
[Odin]: <https://odin-lang.org/>
