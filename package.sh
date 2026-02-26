#!/bin/bash

set -e

APP_NAME="Transly"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" build/Release/Transly.app/Contents/Info.plist 2>/dev/null || echo "1.0.0")

echo "📦 打包 $APP_NAME v$VERSION"
echo ""

if [ ! -d "build/Release/$APP_NAME.app" ]; then
    echo "❌ 错误: 请先运行 ./build-release.sh 构建应用"
    exit 1
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
rm -f "$DIST_DIR/$DMG_NAME"

echo "📁 创建 DMG 包..."

TMP_DIR="$DIST_DIR/dmg_temp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

cp -R "build/Release/$APP_NAME.app" "$TMP_DIR/"
ln -sf /Applications "$TMP_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DIR" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DIST_DIR/$DMG_NAME" \
    2>/dev/null

rm -rf "$TMP_DIR"

DMG_SIZE=$(ls -lh "$DIST_DIR/$DMG_NAME" | awk '{print $5}')

echo ""
echo "🎉 打包完成!"
echo ""
echo "📦 输出文件:"
echo "   DMG: $DIST_DIR/$DMG_NAME ($DMG_SIZE)"
