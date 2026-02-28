#!/bin/bash

set -e

APP_NAME="Transly"
ARCHIVE_PATH="build/Transly.xcarchive/Products/Applications/${APP_NAME}.app"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${ARCHIVE_PATH}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")

echo "📦 打包 $APP_NAME v$VERSION"
echo ""

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo "❌ 错误: 请先运行 ./build-release.sh 构建应用"
    exit 1
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
rm -f "$DIST_DIR/$DMG_NAME"

echo "📁 创建 DMG 包..."

create-dmg \
    --volname "$APP_NAME" \
    --hdiutil-quiet \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 160 \
    --icon "${APP_NAME}.app" 180 170 \
    --app-drop-link 480 170 \
    --hide-extension "${APP_NAME}.app" \
    "$DIST_DIR/$DMG_NAME" \
    "${ARCHIVE_PATH}"

DMG_SIZE=$(ls -lh "$DIST_DIR/$DMG_NAME" | awk '{print $5}')

echo ""
echo "🎉 打包完成!"
echo ""
echo "📦 输出文件:"
echo "   DMG: $DIST_DIR/$DMG_NAME ($DMG_SIZE)"
