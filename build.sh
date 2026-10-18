#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
cd "$PROJECT_DIR"

usage() {
    printf 'Usage: ./build.sh [--universal]\n'
    printf 'Builds for the current architecture by default; --universal includes Apple Silicon and Intel.\n'
    printf 'Optional: BINGO_SIGN_IDENTITY="Developer ID Application: ..." enables hardened runtime signing.\n'
}

UNIVERSAL=false
case "${1:-}" in
    "") ;;
    --universal) UNIVERSAL=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac
if [[ $# -ne 0 ]]; then usage >&2; exit 2; fi
if [[ "$(uname -s)" != Darwin ]]; then
    printf 'This build requires macOS and Xcode Command Line Tools.\n' >&2
    exit 1
fi

build_arch() {
    swift build --configuration release --triple "$1-apple-macosx13.0" --scratch-path "$PROJECT_DIR/.build/release-$1"
}

binary_for_arch() {
    swift build --configuration release --triple "$1-apple-macosx13.0" --scratch-path "$PROJECT_DIR/.build/release-$1" --show-bin-path
}

if "$UNIVERSAL"; then
    build_arch arm64
    build_arch x86_64
else
    NATIVE_ARCH="$(uname -m)"
    case "$NATIVE_ARCH" in arm64|x86_64) ;; *) printf 'Unsupported architecture.\n' >&2; exit 1 ;; esac
    build_arch "$NATIVE_ARCH"
fi

APP_DIR="$PROJECT_DIR/build/Bingo Send.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
if "$UNIVERSAL"; then
    ARM_BIN_DIR="$(binary_for_arch arm64)"
    INTEL_BIN_DIR="$(binary_for_arch x86_64)"
    lipo -create "$ARM_BIN_DIR/BingoSend" "$INTEL_BIN_DIR/BingoSend" -output "$APP_DIR/Contents/MacOS/BingoSend"
else
    BIN_DIR="$(binary_for_arch "$NATIVE_ARCH")"
    cp "$BIN_DIR/BingoSend" "$APP_DIR/Contents/MacOS/BingoSend"
fi
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/LICENSE" "$APP_DIR/Contents/Resources/LICENSE.txt"
if [[ -f "$PROJECT_DIR/docs/PRIVACY.md" ]]; then
    cp "$PROJECT_DIR/docs/PRIVACY.md" "$APP_DIR/Contents/Resources/Privacy.md"
fi
if [[ -f "$PROJECT_DIR/docs/PRIVACY.zh-CN.md" ]]; then
    cp "$PROJECT_DIR/docs/PRIVACY.zh-CN.md" "$APP_DIR/Contents/Resources/Privacy.zh-CN.md"
fi
swift "$PROJECT_DIR/scripts/make-icon.swift" "$PROJECT_DIR/build/AppIcon.iconset"
iconutil --convert icns "$PROJECT_DIR/build/AppIcon.iconset" --output "$APP_DIR/Contents/Resources/AppIcon.icns"
APP_IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_DIR/Contents/Info.plist")"
if [[ -n "${BINGO_SIGN_IDENTITY:-}" ]]; then
    codesign --force --sign "$BINGO_SIGN_IDENTITY" --identifier "$APP_IDENTIFIER" --options runtime --timestamp "$APP_DIR"
else
    codesign --force --sign - --identifier "$APP_IDENTIFIER" "$APP_DIR"
fi
codesign --verify --strict "$APP_DIR"
printf 'Built: %s\n' "$APP_DIR"
lipo -archs "$APP_DIR/Contents/MacOS/BingoSend"
