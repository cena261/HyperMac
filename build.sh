#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║          HyperMac — Build Script         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Step 0: Terminate existing instances ──
echo "🛑 Stopping any running instances..."
pkill -9 HyperMac 2>/dev/null || true
pkill -9 DisplayControl 2>/dev/null || true
sleep 0.5

# ── Step 1: Build ──
echo "🔨 Building HyperMac (Release)..."
swift build -c release 2>&1

BINARY=".build/release/HyperMac"
if [ ! -f "$BINARY" ]; then
    echo "❌ Build failed – binary not found."
    exit 1
fi
echo "✅ Build succeeded."

# ── Step 2: Create .app bundle ──
APP_NAME="HyperMac"
BUILD_DIR="build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

echo "📦 Creating app bundle..."
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

cp "$BINARY" "${MACOS}/"

# Copy Resources (AppIcon.icns, cover.jpg, SMC tools, etc.)
if [ -d "Resources" ]; then
    echo "🎨 Copying app resources (icons, cover image, SMC tools)..."
    cp -R Resources/* "${RESOURCES}/"
    chmod +x "${RESOURCES}/smc" "${RESOURCES}/displaycontrol-power" "${RESOURCES}/install-helper.sh" 2>/dev/null || true
fi

# Info.plist — LSUIElement hides dock icon (menu-bar only)
cat > "${CONTENTS}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HyperMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.opensource.hypermac</string>
    <key>CFBundleName</key>
    <string>HyperMac</string>
    <key>CFBundleDisplayName</key>
    <string>HyperMac</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.4.3</string>
    <key>CFBundleShortVersionString</key>
    <string>1.4.3</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# ── Step 3: Ad-hoc code sign ──
echo "🔏 Code signing (ad-hoc)..."
codesign --force --deep --sign - --identifier "com.opensource.hypermac" "${APP_DIR}" 2>/dev/null || true

# ── Step 4: Install to /Applications/ ──
echo "🚀 Installing to /Applications/HyperMac.app..."
rm -rf /Applications/HyperMac.app
cp -R "${APP_DIR}" /Applications/HyperMac.app
rm -rf /Applications/DisplayControl.app 2>/dev/null || true

# ── Step 5: Launch ──
echo "▶️ Launching /Applications/HyperMac.app..."
open /Applications/HyperMac.app

sleep 1
PID=$(pgrep -x HyperMac || true)
if [ -n "$PID" ]; then
    echo "✅ HyperMac is running with PID: $PID"
else
    echo "⚠️ HyperMac not detected yet, please check Console."
fi

echo ""
echo "══════════════════════════════════════════"
echo "  ✅  HyperMac updated & running!"
echo "══════════════════════════════════════════"
echo ""
