# CaveRace Original Soundtrack

An original, cohesive General MIDI score for CaveRace, designed around a Roland
SC-55-style 1990s DOS/Amiga sound.

## Included

- 17 individual MIDI masters
- 17 matching MusicXML notation sources
- one complete seven-cue intro sequence
- loop metadata in MIDI and repeat marks in MusicXML
- FluidSynth rendering scripts for macOS, Linux and Windows

## Recommended synthesizer

The preferred target is Roland Sound Canvas VA or an SC-55. The free,
cross-platform alternative is FluidSynth with a properly licensed,
SC-55-compatible General MIDI SoundFont.

No SoundFont is bundled because SoundFont licensing varies.

## Render

macOS/Linux:

    brew install fluid-synth
    ./scripts/render_fluidsynth.sh /path/to/soundfont.sf2

Windows PowerShell:

    .\scripts\render_fluidsynth.ps1 -SoundFont "C:\path\to\soundfont.sf2"

The output is 48 kHz, stereo, 16-bit WAV.

## Intro mapping

1. Space
2. Eldora
3. Treasure-filled mines
4. Alien arrival
5. The miners' defense
6. The hero
7. Bombs and danger
8. Main menu
