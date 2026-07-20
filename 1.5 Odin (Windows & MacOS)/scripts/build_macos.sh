#!/bin/sh

set -eu

MODE="${1:-release}"
SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIRECTORY=$(dirname -- "$SCRIPT_DIRECTORY")
SOURCE_DIRECTORY="$PROJECT_DIRECTORY/source"
DIST_DIRECTORY="$PROJECT_DIRECTORY/dist/macos"
APP_DIRECTORY="$DIST_DIRECTORY/CaveRace.app"
CONTENTS_DIRECTORY="$APP_DIRECTORY/Contents"

case "$MODE" in
	debug)
		BUILD_FLAGS="-debug"
		;;
	release)
		BUILD_FLAGS="-o:speed"
		;;
	*)
		echo "Usage: $0 [debug|release]" >&2
		exit 2
		;;
esac

rm -rf "$APP_DIRECTORY"
mkdir -p "$CONTENTS_DIRECTORY/MacOS" "$CONTENTS_DIRECTORY/Resources"

cd "$SOURCE_DIRECTORY"
odin build . $BUILD_FLAGS -out:../dist/macos/CaveRace.app/Contents/MacOS/CaveRace
cp "$PROJECT_DIRECTORY/packaging/macos/Info.plist" "$CONTENTS_DIRECTORY/Info.plist"
cp -R "$SOURCE_DIRECTORY/media" "$CONTENTS_DIRECTORY/Resources/media"
cp -R "$SOURCE_DIRECTORY/levels" "$CONTENTS_DIRECTORY/Resources/levels"

test -x "$CONTENTS_DIRECTORY/MacOS/CaveRace"
test -f "$CONTENTS_DIRECTORY/Resources/media/screens/game_border.png"
test -f "$CONTENTS_DIRECTORY/Resources/levels/10.bin"

echo "Built $MODE macOS package: $APP_DIRECTORY"
