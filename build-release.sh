#!/bin/bash

set -e

APP_NAME="Transly"
SOURCE_PATH="build/Release/${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_NAME}.app"

echo "🧹 Cleaning..."
tuist clean

echo "🔨 Building Release version..."
tuist xcodebuild build

if [ ! -d "${SOURCE_PATH}" ]; then
    echo "❌ Error: Could not find built app at ${SOURCE_PATH}"
    exit 1
fi

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
fi
