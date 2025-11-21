#!/bin/bash
# =============================================================================
# Command & Conquer: Generals - Home Edition
# Release DMG Build Script
# =============================================================================
#
# This script creates a complete macOS DMG installer containing:
# - The compiled game executable
# - All game assets (~1.1GB - textures, models, audio, maps, configs)
# - Proper macOS app bundle structure
# - Code signing (optional)
#
# Usage:
#   ./scripts/build-release-dmg.sh [--sign]
#
# Requirements:
#   - Zig compiler (0.14+)
#   - macOS 11.0+ (Big Sur or later)
#   - ~3GB free disk space for build process
#
# =============================================================================

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DMG_DIR="$BUILD_DIR/dmg-staging"
APP_NAME="Generals"
APP_BUNDLE="$DMG_DIR/$APP_NAME.app"
DMG_NAME="Command_Conquer_Generals_Home_Edition"
DMG_VOLUME_NAME="C&C Generals - Home Edition"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Command & Conquer: Generals - Home Edition                    ║${NC}"
echo -e "${BLUE}║     Release DMG Build System                                      ║${NC}"
echo -e "${BLUE}║     Version $VERSION                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
SIGN_APP=false
if [ "$1" == "--sign" ]; then
    SIGN_APP=true
    echo -e "${YELLOW}Code signing enabled${NC}"
fi

# =============================================================================
# Step 1: Clean previous builds
# =============================================================================
echo -e "${BLUE}[1/8] Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR/dmg-staging"
rm -rf "$BUILD_DIR/$DMG_NAME.dmg"
rm -rf "$BUILD_DIR/$DMG_NAME-temp.dmg"
mkdir -p "$DMG_DIR"

# =============================================================================
# Step 2: Build the game executable (Release mode)
# =============================================================================
echo -e "${BLUE}[2/8] Building game executable (Release mode)...${NC}"
cd "$PROJECT_DIR"
zig build -Doptimize=ReleaseFast

if [ ! -f "$PROJECT_DIR/zig-out/bin/generals" ]; then
    echo -e "${RED}ERROR: Build failed - executable not found${NC}"
    exit 1
fi

EXECUTABLE_SIZE=$(du -h "$PROJECT_DIR/zig-out/bin/generals" | cut -f1)
echo -e "${GREEN}   Executable built: $EXECUTABLE_SIZE${NC}"

# =============================================================================
# Step 3: Create app bundle structure
# =============================================================================
echo -e "${BLUE}[3/8] Creating macOS app bundle structure...${NC}"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"

# Copy executable
cp "$PROJECT_DIR/zig-out/bin/generals" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# =============================================================================
# Step 4: Create Info.plist
# =============================================================================
echo -e "${BLUE}[4/8] Creating Info.plist...${NC}"

cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Generals</string>
    <key>CFBundleIdentifier</key>
    <string>com.generals.home-edition</string>
    <key>CFBundleName</key>
    <string>Generals</string>
    <key>CFBundleDisplayName</key>
    <string>Command &amp; Conquer: Generals - Home Edition</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>GNRL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>100</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>Generals.icns</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.strategy-games</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Based on Thyme Engine - Reimplemented in Zig + Home</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Generals Map</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>map</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Generals Replay</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>rep</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPLGNRL" > "$APP_BUNDLE/Contents/PkgInfo"

# =============================================================================
# Step 5: Copy game assets (1.1GB+)
# =============================================================================
echo -e "${BLUE}[5/8] Copying game assets (this may take a while)...${NC}"

ASSETS_DIR="$PROJECT_DIR/assets"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

if [ -d "$ASSETS_DIR" ]; then
    echo "   Copying assets from $ASSETS_DIR..."

    # Copy all asset directories
    for dir in ini textures models audio maps data ui scripts; do
        if [ -d "$ASSETS_DIR/$dir" ]; then
            echo "   - Copying $dir/..."
            cp -R "$ASSETS_DIR/$dir" "$RESOURCES_DIR/"
        fi
    done

    # Copy JSON metadata files
    for json in "$ASSETS_DIR"/*.json; do
        if [ -f "$json" ]; then
            cp "$json" "$RESOURCES_DIR/"
        fi
    done

    # Calculate total size
    ASSETS_SIZE=$(du -sh "$RESOURCES_DIR" | cut -f1)
    echo -e "${GREEN}   Total assets copied: $ASSETS_SIZE${NC}"
else
    echo -e "${YELLOW}   WARNING: Assets directory not found at $ASSETS_DIR${NC}"
fi

# =============================================================================
# Step 6: Create app icon (placeholder if not exists)
# =============================================================================
echo -e "${BLUE}[6/8] Setting up app icon...${NC}"

ICON_SOURCE="$PROJECT_DIR/packaging/Generals.icns"
if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$RESOURCES_DIR/Generals.icns"
    echo -e "${GREEN}   Icon copied${NC}"
else
    # Create a placeholder icon set
    echo -e "${YELLOW}   No icon found, creating placeholder...${NC}"

    # Create iconset directory
    ICONSET_DIR="$BUILD_DIR/Generals.iconset"
    mkdir -p "$ICONSET_DIR"

    # Create a simple placeholder icon using sips (built into macOS)
    # We'll create a solid colored square as placeholder
    for size in 16 32 64 128 256 512; do
        # Create solid color PNG using built-in tools
        printf "P6\n$size $size\n255\n" > "$ICONSET_DIR/temp_$size.ppm"
        # Dark military green color (RGB: 50, 70, 50)
        for ((i=0; i<$size*$size; i++)); do
            printf '\x32\x46\x32' >> "$ICONSET_DIR/temp_$size.ppm"
        done
        sips -s format png "$ICONSET_DIR/temp_$size.ppm" --out "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null || true
        rm -f "$ICONSET_DIR/temp_$size.ppm"

        # Also create @2x versions
        if [ $size -le 256 ]; then
            double=$((size * 2))
            cp "$ICONSET_DIR/icon_${size}x${size}.png" "$ICONSET_DIR/icon_${size}x${size}@2x.png" 2>/dev/null || true
        fi
    done

    # Convert iconset to icns
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/Generals.icns" 2>/dev/null || {
        echo -e "${YELLOW}   Could not create icon, continuing without...${NC}"
    }
    rm -rf "$ICONSET_DIR"
fi

# =============================================================================
# Step 7: Code sign (optional)
# =============================================================================
if [ "$SIGN_APP" = true ]; then
    echo -e "${BLUE}[7/8] Code signing...${NC}"

    if [ -n "$CODESIGN_IDENTITY" ]; then
        codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
        echo -e "${GREEN}   Signed with: $CODESIGN_IDENTITY${NC}"
    else
        echo -e "${YELLOW}   No CODESIGN_IDENTITY set, using ad-hoc signing${NC}"
        codesign --force --deep --sign - "$APP_BUNDLE"
    fi
else
    echo -e "${BLUE}[7/8] Skipping code signing (use --sign to enable)${NC}"
fi

# =============================================================================
# Step 8: Create DMG
# =============================================================================
echo -e "${BLUE}[8/8] Creating DMG installer...${NC}"

# Calculate required size (assets + 200MB buffer)
APP_SIZE_KB=$(du -sk "$APP_BUNDLE" | cut -f1)
DMG_SIZE_MB=$(( (APP_SIZE_KB / 1024) + 200 ))

echo "   App bundle size: $((APP_SIZE_KB / 1024)) MB"
echo "   DMG size (with buffer): $DMG_SIZE_MB MB"

# Create symlink to Applications
ln -sf /Applications "$DMG_DIR/Applications"

# Create README
cat > "$DMG_DIR/README.txt" << 'README'
Command & Conquer: Generals - Home Edition
==========================================

A faithful reimplementation of Command & Conquer: Generals Zero Hour
using modern technologies:

- Zig programming language
- Home programming language
- Metal GPU rendering (macOS)
- Craft UI engine

Based on the open-source Thyme engine.

Installation:
1. Drag "Generals" to your Applications folder
2. Double-click to launch
3. Enjoy!

Controls:
- WASD / Arrow Keys: Pan camera
- Left Click: Select units
- Right Click: Move selected units
- Cmd+Q: Quit

For updates and source code, visit:
https://github.com/generals-home/generals

License:
Based on open-source Thyme engine.
Original game assets copyright EA/Westwood.
README

# Create temporary DMG
echo "   Creating temporary DMG..."
hdiutil create \
    -srcfolder "$DMG_DIR" \
    -volname "$DMG_VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE_MB}m \
    "$BUILD_DIR/$DMG_NAME-temp.dmg"

# Mount DMG for customization
echo "   Mounting for customization..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$BUILD_DIR/$DMG_NAME-temp.dmg" | /usr/bin/grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/')

if [ -n "$MOUNT_DIR" ]; then
    # Apply Finder customization via AppleScript
    echo "   Applying Finder customizations..."
    osascript << APPLESCRIPT
    tell application "Finder"
        tell disk "$DMG_VOLUME_NAME"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set bounds of container window to {100, 100, 700, 500}
            set theViewOptions to the icon view options of container window
            set arrangement of theViewOptions to not arranged
            set icon size of theViewOptions to 80
            -- Position icons
            set position of item "Generals.app" of container window to {150, 200}
            set position of item "Applications" of container window to {450, 200}
            set position of item "README.txt" of container window to {300, 350}
            close
            open
            update without registering applications
            delay 2
        end tell
    end tell
APPLESCRIPT

    # Unmount
    sync
    hdiutil detach "$MOUNT_DIR"
fi

# Convert to compressed DMG
echo "   Compressing final DMG..."
hdiutil convert \
    "$BUILD_DIR/$DMG_NAME-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$BUILD_DIR/$DMG_NAME.dmg"

# Clean up
rm -f "$BUILD_DIR/$DMG_NAME-temp.dmg"
rm -rf "$DMG_DIR"

# Verify
echo "   Verifying DMG..."
hdiutil verify "$BUILD_DIR/$DMG_NAME.dmg"

# =============================================================================
# Done!
# =============================================================================
FINAL_SIZE=$(du -h "$BUILD_DIR/$DMG_NAME.dmg" | cut -f1)

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    BUILD COMPLETE!                                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "   DMG Location: ${BLUE}$BUILD_DIR/$DMG_NAME.dmg${NC}"
echo -e "   DMG Size:     ${BLUE}$FINAL_SIZE${NC}"
echo ""
echo -e "   To install:"
echo -e "   1. Open the DMG"
echo -e "   2. Drag 'Generals' to Applications"
echo -e "   3. Launch from Applications"
echo ""
