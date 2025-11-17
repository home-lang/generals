#!/usr/bin/env bash
# C&C Generals Zero Hour - Cross-Platform Distribution Builder
#
# This script builds distributable packages for:
# - macOS (Universal Binary: Apple Silicon + Intel)
# - Windows (x64)
# - Linux (x64)
#
# Output: Ready-to-distribute game packages in dist/

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION="1.0.0"
GAME_NAME="Generals"
DIST_DIR="dist"
BUILD_DIR="build"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  C&C Generals - Distribution Builder${NC}"
echo -e "${BLUE}  Version: ${VERSION}${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Checking for required tools...${NC}"
check_tool zig
echo -e "${GREEN}✓ All required tools found${NC}\n"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf ${DIST_DIR}
rm -rf ${BUILD_DIR}
mkdir -p ${DIST_DIR}
mkdir -p ${BUILD_DIR}
echo -e "${GREEN}✓ Clean complete${NC}\n"

# ============================================================================
# macOS Build (Universal Binary: ARM64 + x86_64)
# ============================================================================

build_macos() {
    echo -e "${BLUE}Building for macOS (Universal Binary)...${NC}"

    # Build ARM64
    echo "  Building ARM64..."
    zig build -Dtarget=aarch64-macos \
        -Doptimize=ReleaseFast \
        --prefix ${BUILD_DIR}/macos-arm64

    # Build x86_64
    echo "  Building x86_64..."
    zig build -Dtarget=x86_64-macos \
        -Doptimize=ReleaseFast \
        --prefix ${BUILD_DIR}/macos-x86_64

    # Create universal binary
    echo "  Creating universal binary..."
    mkdir -p ${BUILD_DIR}/macos-universal/bin
    lipo -create \
        ${BUILD_DIR}/macos-arm64/bin/${GAME_NAME} \
        ${BUILD_DIR}/macos-x86_64/bin/${GAME_NAME} \
        -output ${BUILD_DIR}/macos-universal/bin/${GAME_NAME}

    # Create .app bundle
    echo "  Creating application bundle..."
    APP_BUNDLE="${DIST_DIR}/${GAME_NAME}.app"
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"

    # Copy executable
    cp ${BUILD_DIR}/macos-universal/bin/${GAME_NAME} "${APP_BUNDLE}/Contents/MacOS/"

    # Create Info.plist
    cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${GAME_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.ea.generals</string>
    <key>CFBundleName</key>
    <string>C&C Generals Zero Hour</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

    # Copy assets (if they exist)
    if [ -d "assets" ]; then
        echo "  Copying assets..."
        cp -r assets "${APP_BUNDLE}/Contents/Resources/"
    fi

    # Create DMG
    echo "  Creating DMG installer..."
    DMG_NAME="${GAME_NAME}-${VERSION}-macOS-Universal.dmg"
    hdiutil create -volname "${GAME_NAME}" \
        -srcfolder "${DIST_DIR}/${GAME_NAME}.app" \
        -ov -format UDZO \
        "${DIST_DIR}/${DMG_NAME}"

    echo -e "${GREEN}✓ macOS build complete: ${DIST_DIR}/${DMG_NAME}${NC}\n"
}

# ============================================================================
# Windows Build (x64)
# ============================================================================

build_windows() {
    echo -e "${BLUE}Building for Windows (x64)...${NC}"

    zig build -Dtarget=x86_64-windows \
        -Doptimize=ReleaseFast \
        --prefix ${BUILD_DIR}/windows-x64

    # Create distribution folder
    WIN_DIST="${DIST_DIR}/${GAME_NAME}-${VERSION}-Windows-x64"
    mkdir -p "${WIN_DIST}"

    # Copy executable
    cp ${BUILD_DIR}/windows-x64/bin/${GAME_NAME}.exe "${WIN_DIST}/"

    # Copy assets
    if [ -d "assets" ]; then
        echo "  Copying assets..."
        cp -r assets "${WIN_DIST}/"
    fi

    # Create README
    cat > "${WIN_DIST}/README.txt" << EOF
C&C Generals Zero Hour - Home Port
Version ${VERSION}

SYSTEM REQUIREMENTS:
- Windows 10/11 (64-bit)
- DirectX 12 compatible GPU
- 8GB RAM
- 5GB free disk space

INSTALLATION:
1. Extract all files to a folder
2. Run Generals.exe

CONTROLS:
- WASD: Move camera
- Mouse: Select units
- Spacebar: Select all combat units
- ESC: Cancel/Menu

For support, visit: https://github.com/stacksjs/generals

(c) 2025 Home Port Team
Original game (c) Electronic Arts
EOF

    # Create ZIP
    echo "  Creating ZIP archive..."
    cd ${DIST_DIR}
    ZIP_NAME="${GAME_NAME}-${VERSION}-Windows-x64.zip"
    zip -r "${ZIP_NAME}" "${GAME_NAME}-${VERSION}-Windows-x64"
    cd ..

    echo -e "${GREEN}✓ Windows build complete: ${DIST_DIR}/${ZIP_NAME}${NC}\n"
}

# ============================================================================
# Linux Build (x64)
# ============================================================================

build_linux() {
    echo -e "${BLUE}Building for Linux (x64)...${NC}"

    zig build -Dtarget=x86_64-linux \
        -Doptimize=ReleaseFast \
        --prefix ${BUILD_DIR}/linux-x64

    # Create distribution folder
    LINUX_DIST="${DIST_DIR}/${GAME_NAME}-${VERSION}-Linux-x64"
    mkdir -p "${LINUX_DIST}"

    # Copy executable
    cp ${BUILD_DIR}/linux-x64/bin/${GAME_NAME} "${LINUX_DIST}/"
    chmod +x "${LINUX_DIST}/${GAME_NAME}"

    # Copy assets
    if [ -d "assets" ]; then
        echo "  Copying assets..."
        cp -r assets "${LINUX_DIST}/"
    fi

    # Create launcher script
    cat > "${LINUX_DIST}/run.sh" << 'EOF'
#!/bin/bash
# C&C Generals launcher
cd "$(dirname "$0")"
./Generals "$@"
EOF
    chmod +x "${LINUX_DIST}/run.sh"

    # Create desktop file
    cat > "${LINUX_DIST}/${GAME_NAME}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=C&C Generals Zero Hour
Comment=Real-time strategy game
Exec=/path/to/${GAME_NAME}
Icon=${GAME_NAME}
Terminal=false
Categories=Game;StrategyGame;
EOF

    # Create README
    cat > "${LINUX_DIST}/README.md" << EOF
# C&C Generals Zero Hour - Home Port
Version ${VERSION}

## System Requirements
- Linux (x64) - Ubuntu 20.04+ or equivalent
- Vulkan compatible GPU
- 8GB RAM
- 5GB free disk space

## Installation
1. Extract all files
2. Run: \`./run.sh\` or \`./Generals\`

## Optional: Install Desktop Entry
\`\`\`bash
cp ${GAME_NAME}.desktop ~/.local/share/applications/
\`\`\`

## Controls
- WASD: Move camera
- Mouse: Select units
- Spacebar: Select all combat units
- ESC: Cancel/Menu

For support, visit: https://github.com/stacksjs/generals

© 2025 Home Port Team | Original game © Electronic Arts
EOF

    # Create tarball
    echo "  Creating tarball..."
    cd ${DIST_DIR}
    tar czf "${GAME_NAME}-${VERSION}-Linux-x64.tar.gz" "${GAME_NAME}-${VERSION}-Linux-x64"
    cd ..

    echo -e "${GREEN}✓ Linux build complete: ${DIST_DIR}/${GAME_NAME}-${VERSION}-Linux-x64.tar.gz${NC}\n"
}

# ============================================================================
# Build All Platforms
# ============================================================================

build_all() {
    build_macos
    build_windows
    build_linux

    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}  All builds complete!${NC}"
    echo -e "${GREEN}=====================================${NC}\n"

    echo -e "${BLUE}Distribution files:${NC}"
    ls -lh ${DIST_DIR}/*.{dmg,zip,tar.gz} 2>/dev/null || echo "  (No distribution files found)"

    echo -e "\n${YELLOW}Total size:${NC}"
    du -sh ${DIST_DIR}
}

# ============================================================================
# Main
# ============================================================================

# Parse arguments
if [ "$1" == "macos" ]; then
    build_macos
elif [ "$1" == "windows" ]; then
    build_windows
elif [ "$1" == "linux" ]; then
    build_linux
elif [ "$1" == "all" ] || [ -z "$1" ]; then
    build_all
else
    echo -e "${RED}Error: Unknown platform '$1'${NC}"
    echo "Usage: $0 [macos|windows|linux|all]"
    exit 1
fi

echo -e "\n${GREEN}✓ Build script complete!${NC}"
