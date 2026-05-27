#!/usr/bin/env bash
# Regenerates the app icon: draws the 1024 master via CoreGraphics, then renders
# every size the AppIcon.appiconset needs. Run via `make icon`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/Resources/Assets.xcassets/AppIcon.appiconset"

: "${DEVELOPER_DIR:=/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

swift "$ROOT/scripts/make_icon.swift"

cd "$ICONSET"
gen() { sips -z "$1" "$1" icon_1024.png --out "$2" >/dev/null; }
gen 16  icon_16.png
gen 32  icon_16@2x.png
gen 32  icon_32.png
gen 64  icon_32@2x.png
gen 128 icon_128.png
gen 256 icon_128@2x.png
gen 256 icon_256.png
gen 512 icon_256@2x.png
gen 512 icon_512.png
cp icon_1024.png icon_512@2x.png

echo "icon: regenerated $(ls icon_*.png | wc -l | tr -d ' ') images in AppIcon.appiconset"
