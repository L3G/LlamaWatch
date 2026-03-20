#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/LlamaWatch.app/Contents"

echo "Building LlamaWatch..."

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"
cp "$SCRIPT_DIR/Info.plist" "$APP_DIR/"

# Generate app icon if needed
if [ ! -f "$SCRIPT_DIR/AppIcon.icns" ]; then
    echo "Generating app icon..."
    (cd "$SCRIPT_DIR" && swift generate_icon.swift)
fi
cp "$SCRIPT_DIR/AppIcon.icns" "$APP_DIR/Resources/"

swiftc -swift-version 5 \
    -o "$APP_DIR/MacOS/LlamaWatch" \
    "$SCRIPT_DIR/main.swift" \
    -framework AppKit

echo "Built: $BUILD_DIR/LlamaWatch.app"
echo ""
echo "To run:  open $BUILD_DIR/LlamaWatch.app"
echo ""
echo "To install as login item:"
echo "  cp $BUILD_DIR/LlamaWatch.app /Applications/"
echo "  Then add LlamaWatch to System Settings > General > Login Items"
