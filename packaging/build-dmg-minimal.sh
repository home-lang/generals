#!/bin/bash
set -e

APP_NAME="Generals"
DMG_NAME="Generals-Zero-Hour-1.0.0"
BUILD_DIR="./build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_TEMP="${BUILD_DIR}/dmg_temp"
DMG_FILE="${BUILD_DIR}/${DMG_NAME}.dmg"
VOLUME_NAME="C&C Generals Zero Hour"

echo "=== Creating Minimal DMG Installer ==="

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: App bundle not found"
    exit 1
fi

# Clean previous DMG
rm -f "${DMG_FILE}" "${BUILD_DIR}/temp.dmg"

# Create temporary DMG directory
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy app bundle (without large assets)
cp -r "${APP_BUNDLE}" "${DMG_TEMP}/"

# Create Applications symlink
ln -s /Applications "${DMG_TEMP}/Applications"

# Create DMG (smaller size for minimal build)
hdiutil create -srcfolder "${DMG_TEMP}" -volname "${VOLUME_NAME}" \
    -fs HFS+ -format UDZO -imagekey zlib-level=9 -o "${DMG_FILE}"

# Clean up
rm -rf "${DMG_TEMP}"

# Get DMG size
DMG_SIZE=$(du -h "${DMG_FILE}" | cut -f1)

echo ""
echo "=== DMG Created Successfully ==="
echo "Location: ${DMG_FILE}"
echo "Size: ${DMG_SIZE}"
echo ""
