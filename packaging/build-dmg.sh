#!/bin/bash
# Create DMG installer for C&C Generals Zero Hour
# This script packages the .app bundle into a distributable DMG

set -e  # Exit on error

# Configuration
APP_NAME="Generals"
DMG_NAME="Generals-Zero-Hour-1.0.0"
BUILD_DIR="./build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_TEMP="${BUILD_DIR}/dmg_temp"
DMG_FILE="${BUILD_DIR}/${DMG_NAME}.dmg"
VOLUME_NAME="C&C Generals Zero Hour"

echo "=== Creating DMG Installer ==="
echo ""

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: App bundle not found at ${APP_BUNDLE}"
    echo "Run ./packaging/build-app-bundle.sh first"
    exit 1
fi

# Clean previous DMG
if [ -f "${DMG_FILE}" ]; then
    echo "Removing previous DMG..."
    rm -f "${DMG_FILE}"
fi

# Create temporary DMG directory
echo "Creating temporary DMG directory..."
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy app bundle
echo "Copying app bundle..."
cp -r "${APP_BUNDLE}" "${DMG_TEMP}/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "${DMG_TEMP}/Applications"

# Copy README
if [ -f "README.md" ]; then
    echo "Copying README..."
    cp README.md "${DMG_TEMP}/README.txt"
fi

# Copy license
if [ -f "LICENSE" ]; then
    echo "Copying LICENSE..."
    cp LICENSE "${DMG_TEMP}/LICENSE.txt"
fi

# Create custom background (if available)
if [ -f "packaging/dmg-background.png" ]; then
    mkdir -p "${DMG_TEMP}/.background"
    cp packaging/dmg-background.png "${DMG_TEMP}/.background/"
fi

# Create temporary DMG
echo "Creating temporary DMG..."
TEMP_DMG="${BUILD_DIR}/temp.dmg"
hdiutil create -srcfolder "${DMG_TEMP}" -volname "${VOLUME_NAME}" \
    -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 500m "${TEMP_DMG}"

# Mount temporary DMG
echo "Mounting temporary DMG..."
MOUNT_DIR="/Volumes/${VOLUME_NAME}"
hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}"

# Wait for mount
sleep 2

# Set up DMG window appearance
echo "Configuring DMG appearance..."
if [ -f "packaging/dmg-setup.applescript" ]; then
    osascript packaging/dmg-setup.applescript
else
    # Basic AppleScript for DMG setup
    echo 'tell application "Finder"
        tell disk "'${VOLUME_NAME}'"
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set the bounds of container window to {400, 100, 900, 500}
            set theViewOptions to the icon view options of container window
            set arrangement of theViewOptions to not arranged
            set icon size of theViewOptions to 128
            set position of item "'${APP_NAME}'.app" of container window to {125, 150}
            set position of item "Applications" of container window to {375, 150}
            update without registering applications
            delay 2
        end tell
    end tell' | osascript
fi

# Unmount
echo "Unmounting temporary DMG..."
hdiutil detach "${MOUNT_DIR}" || {
    echo "Warning: Could not detach automatically, trying force..."
    hdiutil detach "${MOUNT_DIR}" -force
}

sleep 2

# Convert to compressed DMG
echo "Creating final compressed DMG..."
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FILE}"

# Clean up
echo "Cleaning up..."
rm -f "${TEMP_DMG}"
rm -rf "${DMG_TEMP}"

# Verify DMG
echo ""
echo "Verifying DMG..."
hdiutil verify "${DMG_FILE}"

# Get DMG size
DMG_SIZE=$(du -h "${DMG_FILE}" | cut -f1)

echo ""
echo "=== DMG Created Successfully ==="
echo "Location: ${DMG_FILE}"
echo "Size: ${DMG_SIZE}"
echo ""
echo "To test:"
echo "  open ${DMG_FILE}"
echo ""
echo "To distribute:"
echo "  Upload ${DMG_FILE} to your distribution platform"
echo ""
