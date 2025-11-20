#!/bin/bash
# Build macOS App Bundle for C&C Generals Zero Hour
# This script creates the .app structure and packages everything

set -e  # Exit on error

# Configuration
APP_NAME="Generals"
BUNDLE_ID="com.generals.zerolhour"
VERSION="1.0.0"
BUILD_DIR="./build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "=== Building C&C Generals Zero Hour macOS App ==="
echo ""

# Clean previous build
if [ -d "${APP_BUNDLE}" ]; then
    echo "Cleaning previous build..."
    rm -rf "${APP_BUNDLE}"
fi

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"

# Copy Info.plist
echo "Copying Info.plist..."
cp packaging/Info.plist "${APP_BUNDLE}/Contents/Info.plist"

# Copy PkgInfo
echo "Creating PkgInfo..."
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Build executable (placeholder - would use Home compiler)
echo "Building executable..."
# home build src/game/game.home --output "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# For now, create a placeholder script
cat > "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" << 'EOF'
#!/bin/bash
# Placeholder launcher for Generals
echo "C&C Generals Zero Hour - Home Engine"
echo "This would launch the actual game when the Home compiler is ready"
echo ""
echo "Engine Foundation: Complete"
echo "  - Math library"
echo "  - Renderer (OpenGL)"
echo "  - Entity system"
echo "  - Audio system"
echo "  - Asset loading"
echo ""
echo "Press Ctrl+C to exit"
read -r
EOF

chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy icon (if available)
if [ -f "packaging/AppIcon.icns" ]; then
    echo "Copying app icon..."
    cp packaging/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"
else
    echo "Warning: No app icon found (packaging/AppIcon.icns)"
fi

# Copy resources
echo "Copying resources..."
mkdir -p "${APP_BUNDLE}/Contents/Resources/assets"

# Copy shaders
if [ -d "assets/shaders" ]; then
    cp -r assets/shaders "${APP_BUNDLE}/Contents/Resources/assets/"
fi

# Copy default textures
if [ -d "assets/textures" ]; then
    cp -r assets/textures "${APP_BUNDLE}/Contents/Resources/assets/"
fi

# Copy sounds
if [ -d "assets/sounds" ]; then
    cp -r assets/sounds "${APP_BUNDLE}/Contents/Resources/assets/"
fi

# Copy game data
if [ -d "assets/data" ]; then
    cp -r assets/data "${APP_BUNDLE}/Contents/Resources/assets/"
fi

# Copy frameworks (OpenAL, etc.)
echo "Copying frameworks..."
# This would copy dylibs for OpenAL, SDL, etc.
# cp /usr/local/lib/libopenal.dylib "${APP_BUNDLE}/Contents/Frameworks/"

# Code signing (optional, for distribution)
if [ -n "$CODESIGN_IDENTITY" ]; then
    echo "Code signing app bundle..."
    codesign --force --deep --sign "$CODESIGN_IDENTITY" "${APP_BUNDLE}"
else
    echo "Skipping code signing (set CODESIGN_IDENTITY to sign)"
fi

# Verify bundle
echo ""
echo "Verifying app bundle..."
if [ -f "${APP_BUNDLE}/Contents/Info.plist" ]; then
    echo "✓ Info.plist present"
else
    echo "✗ Info.plist missing!"
    exit 1
fi

if [ -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]; then
    echo "✓ Executable present and executable"
else
    echo "✗ Executable missing or not executable!"
    exit 1
fi

echo ""
echo "=== App Bundle Created Successfully ==="
echo "Location: ${APP_BUNDLE}"
echo ""
echo "To run:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To test from command line:"
echo "  ${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
echo ""
