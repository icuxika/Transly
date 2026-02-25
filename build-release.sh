#!/bin/bash

set -e

APP_NAME="Transly"
SOURCE_PATH="build/Release/${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_NAME}.app"
SIGNING_IDENTITY="Apple Development: benjun Rao (7X7AZ5MMKZ)"

echo "🧹 Cleaning build directory..."
rm -rf build

echo "📦 Generating Xcode project..."
tuist generate --no-open

echo "🔨 Building Release version..."
xcodebuild -workspace Transly.xcworkspace \
  -scheme Transly \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  2>&1 | tail -10

echo "📋 Finding built app..."
BUILT_APP=$(find build/DerivedData/Build/Products -name "Transly.app" -type d 2>/dev/null | head -1)

if [ -z "$BUILT_APP" ]; then
    echo "❌ Error: Could not find built app"
    exit 1
fi

echo "📁 Built app found at: $BUILT_APP"

echo "📦 Copying to build/Release..."
mkdir -p build/Release
cp -R "$BUILT_APP" "${SOURCE_PATH}"

echo "✍️ Re-signing application..."
codesign --force --deep --sign "${SIGNING_IDENTITY}" "${SOURCE_PATH}"

echo "✅ Verifying signature..."
codesign -dv --verbose=4 "${SOURCE_PATH}" 2>&1 | grep -E "(Identifier|Authority|TeamIdentifier)"

echo ""
echo "🎉 Build completed successfully!"
echo "📍 App location: ${SOURCE_PATH}"
echo ""

if [ "$1" == "--install" ]; then
    echo "📦 Installing to ${INSTALL_PATH}..."
    
    if [ -d "${INSTALL_PATH}" ]; then
        echo "Removing existing installation..."
        rm -rf "${INSTALL_PATH}"
    fi
    
    cp -R "${SOURCE_PATH}" "${INSTALL_PATH}"
    
    echo "✅ Installed to ${INSTALL_PATH}"
    echo ""
    echo "🚀 Launching ${APP_NAME}..."
    open "${INSTALL_PATH}"
else
    echo "💡 Tip: Run './build-release.sh --install' to install to /Applications"
    echo "   Installing to /Applications may improve permission handling."
fi
