#!/usr/bin/env bash
set -euo pipefail
SF2="${1:?Usage: render_fluidsynth.sh /path/to/soundfont.sf2}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/renders/wav"
for f in "$ROOT"/midi/*.mid; do
  name="$(basename "${f%.mid}")"
  fluidsynth -ni "$SF2" "$f" -F "$ROOT/renders/wav/$name.wav" -r 48000 -O s16
done
