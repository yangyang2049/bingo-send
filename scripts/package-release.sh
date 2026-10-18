#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$PROJECT_DIR/build/Bingo Send.app"

usage() {
    printf 'Usage: ./scripts/package-release.sh [--app "/path/to/Bingo Send.app"]\n'
    printf 'Packages an existing signed app into dist/ without rebuilding, signing, or launching it.\n'
}

case "${1:-}" in
    "") ;;
    --app)
        if [[ $# -lt 2 || -z "$2" ]]; then usage >&2; exit 2; fi
        APP_DIR="$2"
        shift 2
        ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
if [[ $# -ne 0 ]]; then usage >&2; exit 2; fi
if [[ "$(uname -s)" != Darwin ]]; then
    printf 'Packaging requires macOS.\n' >&2
    exit 1
fi
if [[ ! -d "$APP_DIR" || "$APP_DIR" != *.app ]]; then
    printf 'App not found. Run ./build.sh first, or provide --app.\n' >&2
    exit 1
fi
APP_DIR="$(cd -- "$APP_DIR" && pwd)"
APP_NAME="$(basename -- "$APP_DIR")"
PLIST="$APP_DIR/Contents/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST")"
if [[ ! "$VERSION" =~ ^[0-9][A-Za-z0-9._-]*$ || "$EXECUTABLE" == */* || -z "$EXECUTABLE" ]]; then
    printf 'Invalid bundle version or executable name.\n' >&2
    exit 1
fi
codesign --verify --strict "$APP_DIR"
ARCHS="$(lipo -archs "$APP_DIR/Contents/MacOS/$EXECUTABLE")"
case "$ARCHS" in
    'arm64 x86_64'|'x86_64 arm64') ARCH_LABEL=universal ;;
    arm64|x86_64) ARCH_LABEL="$ARCHS" ;;
    *) printf 'Unsupported app architectures.\n' >&2; exit 1 ;;
esac

DIST_DIR="$PROJECT_DIR/dist"
mkdir -p "$DIST_DIR"
PACKAGE_NAME="BingoSend-$VERSION-macOS-$ARCH_LABEL"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bingo-release.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$STAGING_DIR/$PACKAGE_NAME.zip"
mkdir -p "$STAGING_DIR/dmg"
ditto "$APP_DIR" "$STAGING_DIR/dmg/$APP_NAME"
ln -s /Applications "$STAGING_DIR/dmg/Applications"
hdiutil create -quiet -volname "Bingo Send $VERSION" -srcfolder "$STAGING_DIR/dmg" -format UDZO "$STAGING_DIR/$PACKAGE_NAME.dmg"
mv -f "$STAGING_DIR/$PACKAGE_NAME.zip" "$DIST_DIR/"
mv -f "$STAGING_DIR/$PACKAGE_NAME.dmg" "$DIST_DIR/"

(
    cd "$DIST_DIR"
    shasum -a 256 -- *.zip *.dmg > SHA256SUMS.txt
)
printf 'Packaged: %s\n' "$DIST_DIR/$PACKAGE_NAME.zip" "$DIST_DIR/$PACKAGE_NAME.dmg" "$DIST_DIR/SHA256SUMS.txt"
