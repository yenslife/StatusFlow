#!/bin/zsh

set -euo pipefail

APP_NAME="StatusFlow"
VERSION="${1:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"

if [[ -n "${CODESIGN_IDENTITY:-}" && -z "${NOTARY_PROFILE:-}" ]] || \
   [[ -z "${CODESIGN_IDENTITY:-}" && -n "${NOTARY_PROFILE:-}" ]]; then
    print -u2 "Error: CODESIGN_IDENTITY and NOTARY_PROFILE must be provided together."
    exit 1
fi

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/statusflow-release.XXXXXX")"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

cd "$PROJECT_DIR"
BUILD_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP_DIR" "$DMG_PATH"
mkdir -p "$APP_DIR/Contents/MacOS"
ditto "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
ditto "Packaging/Info.plist" "$APP_DIR/Contents/Info.plist"

plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_DIR/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$APP_DIR/Contents/Info.plist"

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_DIR"
else
    codesign --force --sign - "$APP_DIR"
    print "Warning: Developer ID not configured; this ad-hoc build is for local testing only."
fi

ditto "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_PATH"
fi

print "Created: $DMG_PATH"
