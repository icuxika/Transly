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

ZIP_NAME="${APP_NAME}-${VERSION}.zip"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

rm -f "$DIST_DIR/$ZIP_NAME" "$DIST_DIR/$DMG_NAME" "$DIST_DIR/${APP_NAME}-temp.dmg"

echo "📁 创建 ZIP 包..."
cd build/Release
zip -r "../../$DIST_DIR/$ZIP_NAME" "$APP_NAME.app"
cd ../..
echo "✅ ZIP 包已创建: $DIST_DIR/$ZIP_NAME"
ZIP_SIZE=$(ls -lh "$DIST_DIR/$ZIP_NAME" | awk '{print $5}')

echo ""
echo "📁 创建 DMG 包（支持拖动安装）..."

DMG_TEMP="$DIST_DIR/${APP_NAME}-temp.dmg"
DMG_VOLUME_NAME="$APP_NAME"

TMP_DIR="$DIST_DIR/dmg_temp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cp -R "build/Release/$APP_NAME.app" "$TMP_DIR/"
ln -sf /Applications "$TMP_DIR/Applications"

hdiutil create -volname "$DMG_VOLUME_NAME" \
    -srcfolder "$TMP_DIR" \
    -format UDRW \
    -ov \
    "$DMG_TEMP"

rm -rf "$TMP_DIR"

DMG_DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" 2>/dev/null | egrep '^/dev/' | sed 1q | awk '{print $1}')

sleep 2

echo "🎨 配置 DMG 窗口布局..."

osascript <<EOF
tell application "Finder"
    tell disk "$DMG_VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 100
        
        set position of item "$APP_NAME.app" of container window to {125, 180}
        set position of item "Applications" of container window to {375, 180}
        
        update without registering applications
        delay 2
    end tell
end tell
EOF

sleep 1

hdiutil detach "$DMG_DEVICE" 2>/dev/null || true
sleep 2

hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DIST_DIR/$DMG_NAME"
rm "$DMG_TEMP"

echo "✅ DMG 包已创建: $DIST_DIR/$DMG_NAME"
DMG_SIZE=$(ls -lh "$DIST_DIR/$DMG_NAME" | awk '{print $5}')

echo ""
echo "🎉 打包完成!"
echo ""
echo "📦 输出文件:"
echo "   ZIP: $DIST_DIR/$ZIP_NAME ($ZIP_SIZE)"
echo "   DMG: $DIST_DIR/$DMG_NAME ($DMG_SIZE)"
