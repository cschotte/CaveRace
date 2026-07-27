#!/bin/sh

set -eu

MODE="${1:-release}"
SCRIPT_DIRECTORY=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIRECTORY=$(dirname -- "$SCRIPT_DIRECTORY")
SOURCE_DIRECTORY="$PROJECT_DIRECTORY/source"
DIST_DIRECTORY="$PROJECT_DIRECTORY/dist/macos-appstore"
APP_DIRECTORY="$DIST_DIRECTORY/CaveRace.app"
CONTENTS_DIRECTORY="$APP_DIRECTORY/Contents"
PKG_PATH="$DIST_DIRECTORY/CaveRace.pkg"

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

# Unlike build_macos.sh (direct/notarized distribution, where signing is
# optional for local testing), a Mac App Store package is worthless without
# real Store credentials, so these are required rather than silently skipped.
SIGN_IDENTITY="${CAVERACE_APPSTORE_SIGN_IDENTITY:-}"
INSTALLER_IDENTITY="${CAVERACE_APPSTORE_INSTALLER_IDENTITY:-}"
PROVISIONING_PROFILE="${CAVERACE_APPSTORE_PROVISIONING_PROFILE:-}"
if [ -z "$SIGN_IDENTITY" ] || [ -z "$INSTALLER_IDENTITY" ] || [ -z "$PROVISIONING_PROFILE" ]; then
	echo "Set these environment variables before building for the Mac App Store:" >&2
	echo "  CAVERACE_APPSTORE_SIGN_IDENTITY        - 'Apple Distribution' certificate" >&2
	echo "  CAVERACE_APPSTORE_INSTALLER_IDENTITY   - 'Mac Installer Distribution' certificate" >&2
	echo "  CAVERACE_APPSTORE_PROVISIONING_PROFILE - path to the Mac App Store .provisionprofile" >&2
	exit 2
fi

rm -rf "$APP_DIRECTORY"
mkdir -p "$CONTENTS_DIRECTORY/MacOS" "$CONTENTS_DIRECTORY/Resources"

cd "$SOURCE_DIRECTORY"
EXECUTABLE_PATH="$CONTENTS_DIRECTORY/MacOS/CaveRace"

# The Mac App Store rejects an arm64-only bundle unless the deployment target
# is 12.0+ (ours is 10.15, packaging/macos/Info.plist), so build both slices
# and glue them into one universal executable with lipo.
for target in darwin_arm64 darwin_amd64; do
	odin build . $BUILD_FLAGS -vet -vet-cast -vet-style -vet-tabs -warnings-as-errors \
		-target:$target -out:"$EXECUTABLE_PATH-$target"
done
lipo -create "$EXECUTABLE_PATH-darwin_arm64" "$EXECUTABLE_PATH-darwin_amd64" -output "$EXECUTABLE_PATH"
rm -f "$EXECUTABLE_PATH-darwin_arm64" "$EXECUTABLE_PATH-darwin_amd64"

cp "$PROJECT_DIRECTORY/packaging/macos/Info.plist" "$CONTENTS_DIRECTORY/Info.plist"
cp "$PROJECT_DIRECTORY/packaging/macos/CaveRace.icns" "$CONTENTS_DIRECTORY/Resources/CaveRace.icns"
cp -R "$SOURCE_DIRECTORY/media" "$CONTENTS_DIRECTORY/Resources/media"
cp -R "$SOURCE_DIRECTORY/levels" "$CONTENTS_DIRECTORY/Resources/levels"
cp "$PROVISIONING_PROFILE" "$CONTENTS_DIRECTORY/embedded.provisionprofile"

# The provisioning profile was downloaded through a browser, so macOS tags it
# (and, via cp, the copy inside the bundle) with com.apple.quarantine. App
# Store Connect rejects any package containing that attribute (ITMS-91109),
# so strip it recursively before signing.
xattr -cr "$APP_DIRECTORY"

test -x "$CONTENTS_DIRECTORY/MacOS/CaveRace"
lipo -archs "$CONTENTS_DIRECTORY/MacOS/CaveRace" | grep -q "x86_64" && \
	lipo -archs "$CONTENTS_DIRECTORY/MacOS/CaveRace" | grep -q "arm64"
test -f "$CONTENTS_DIRECTORY/Resources/CaveRace.icns"
test -f "$CONTENTS_DIRECTORY/Resources/media/screens/border.png"
test -f "$CONTENTS_DIRECTORY/Resources/media/intro/00_branding.png"
test -f "$CONTENTS_DIRECTORY/Resources/media/intro/00_branding.ogg"
test -f "$CONTENTS_DIRECTORY/Resources/levels/10.bin"

codesign --force --deep --options runtime --timestamp \
	--entitlements "$PROJECT_DIRECTORY/packaging/macos/CaveRace.entitlements" \
	--sign "$SIGN_IDENTITY" "$APP_DIRECTORY"
codesign --verify --deep --strict --verbose=2 "$APP_DIRECTORY"

rm -f "$PKG_PATH"
productbuild --component "$APP_DIRECTORY" /Applications \
	--sign "$INSTALLER_IDENTITY" "$PKG_PATH"

echo "Built $MODE Mac App Store package: $PKG_PATH"
echo "Upload with: xcrun altool --upload-app --type macos --file \"$PKG_PATH\" ..."
echo "(or open the .pkg in Transporter)."
