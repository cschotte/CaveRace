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
test -f "$CONTENTS_DIRECTORY/Resources/media/screens/Score.png"
test -f "$CONTENTS_DIRECTORY/Resources/levels/10.bin"

SIGN_IDENTITY="${CAVERACE_SIGN_IDENTITY:-}"
NOTARY_PROFILE="${CAVERACE_NOTARY_PROFILE:-}"
if [ -n "$SIGN_IDENTITY" ]; then
	codesign --force --deep --options runtime --timestamp \
		--sign "$SIGN_IDENTITY" "$APP_DIRECTORY"
	codesign --verify --deep --strict --verbose=2 "$APP_DIRECTORY"
fi

if [ -n "$NOTARY_PROFILE" ]; then
	if [ -z "$SIGN_IDENTITY" ]; then
		echo "CAVERACE_NOTARY_PROFILE requires CAVERACE_SIGN_IDENTITY." >&2
		exit 2
	fi
	NOTARY_ARCHIVE="$DIST_DIRECTORY/CaveRace-notarize.zip"
	rm -f "$NOTARY_ARCHIVE"
	ditto -c -k --keepParent "$APP_DIRECTORY" "$NOTARY_ARCHIVE"
	xcrun notarytool submit "$NOTARY_ARCHIVE" \
		--keychain-profile "$NOTARY_PROFILE" --wait
	xcrun stapler staple "$APP_DIRECTORY"
	xcrun stapler validate "$APP_DIRECTORY"
fi

echo "Built $MODE macOS package: $APP_DIRECTORY"
