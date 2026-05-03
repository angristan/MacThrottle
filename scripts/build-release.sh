#!/bin/bash
set -euo pipefail

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Building MacThrottle v$VERSION"

# Clean and build
xcodebuild -project MacThrottle.xcodeproj \
    -scheme MacThrottle \
    -configuration Release \
    -derivedDataPath build \
    clean build

# Create release directory
mkdir -p release

APP_PATH="build/Build/Products/Release/MacThrottle.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Create ZIP
echo "Creating ZIP archive..."
ditto -c -k --keepParent "$APP_PATH" "release/MacThrottle-${VERSION}.zip"

# Create DMG using create-dmg
echo "Creating DMG..."
create-dmg \
    --volname "MacThrottle" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "MacThrottle.app" 150 190 \
    --hide-extension "MacThrottle.app" \
    --app-drop-link 450 185 \
    "release/MacThrottle-${VERSION}.dmg" \
    "$APP_PATH"

echo "Release artifacts created:"
ls -la release/

echo "Done!"
