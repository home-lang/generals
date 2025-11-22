#!/bin/bash
# Link or copy assets from generals-game-patch-old to the generals project
# This script sets up the proper asset directory structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$HOME/Code/generals-game-patch-old"
ASSETS_DIR="$PROJECT_DIR/assets"

echo "=== C&C Generals Zero Hour Asset Linker ==="
echo "Project: $PROJECT_DIR"
echo "Source:  $SOURCE_DIR"
echo "Assets:  $ASSETS_DIR"
echo ""

# Check if source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Create assets directory structure if needed
mkdir -p "$ASSETS_DIR/audio"
mkdir -p "$ASSETS_DIR/cursors"
mkdir -p "$ASSETS_DIR/data"
mkdir -p "$ASSETS_DIR/ini"
mkdir -p "$ASSETS_DIR/maps"
mkdir -p "$ASSETS_DIR/models"
mkdir -p "$ASSETS_DIR/splashes"
mkdir -p "$ASSETS_DIR/textures"
mkdir -p "$ASSETS_DIR/video"
mkdir -p "$ASSETS_DIR/ui"

# Source paths in generals-game-patch-old
EDITED="$SOURCE_DIR/Patch104pZH/GameFilesEdited"
ORIGINAL_ZH="$SOURCE_DIR/Patch104pZH/GameFilesOriginalZH"

echo "Linking assets..."

# Link/copy Audio files
if [ -d "$EDITED/Data/Audio" ]; then
    echo "  - Audio files..."
    cp -rn "$EDITED/Data/Audio/"* "$ASSETS_DIR/audio/" 2>/dev/null || true
fi

# Link/copy INI files
if [ -d "$EDITED/Data/INI" ]; then
    echo "  - INI configuration files..."
    cp -rn "$EDITED/Data/INI/"* "$ASSETS_DIR/ini/" 2>/dev/null || true
fi

# Link/copy localization data
echo "  - Localization files..."
for lang in English German French Spanish Italian Korean Chinese Polish Brazilian Russian Ukrainian Arabic Swedish; do
    if [ -d "$EDITED/Data/$lang" ]; then
        mkdir -p "$ASSETS_DIR/data/$lang"
        cp -rn "$EDITED/Data/$lang/"* "$ASSETS_DIR/data/$lang/" 2>/dev/null || true
    fi
    if [ -d "$ORIGINAL_ZH/Data/$lang" ]; then
        mkdir -p "$ASSETS_DIR/data/$lang"
        cp -rn "$ORIGINAL_ZH/Data/$lang/"* "$ASSETS_DIR/data/$lang/" 2>/dev/null || true
    fi
done

# Link/copy W3D models
if [ -d "$EDITED/Art/W3D" ]; then
    echo "  - W3D model files..."
    cp -rn "$EDITED/Art/W3D/"* "$ASSETS_DIR/models/" 2>/dev/null || true
fi

# Link/copy textures
if [ -d "$EDITED/Art/Textures" ]; then
    echo "  - Texture files..."
    cp -rn "$EDITED/Art/Textures/"* "$ASSETS_DIR/textures/" 2>/dev/null || true
fi

# Link/copy WND UI files
if [ -d "$EDITED/Window" ]; then
    echo "  - WND UI files..."
    cp -rn "$EDITED/Window/"* "$ASSETS_DIR/ui/" 2>/dev/null || true
fi
if [ -d "$ORIGINAL_ZH/Window" ]; then
    cp -rn "$ORIGINAL_ZH/Window/"* "$ASSETS_DIR/ui/" 2>/dev/null || true
fi

# Link/copy Maps
if [ -d "$SOURCE_DIR/Maps" ]; then
    echo "  - Map files..."
    cp -rn "$SOURCE_DIR/Maps/"* "$ASSETS_DIR/maps/" 2>/dev/null || true
fi
if [ -d "$EDITED/Maps" ]; then
    cp -rn "$EDITED/Maps/"* "$ASSETS_DIR/maps/" 2>/dev/null || true
fi

# Link/copy Cursors (ANI/CUR files)
echo "  - Cursor files..."
if [ -d "$EDITED/Data/Cursors" ]; then
    cp -rn "$EDITED/Data/Cursors/"* "$ASSETS_DIR/cursors/" 2>/dev/null || true
fi
if [ -d "$ORIGINAL_ZH/Data/Cursors" ]; then
    cp -rn "$ORIGINAL_ZH/Data/Cursors/"* "$ASSETS_DIR/cursors/" 2>/dev/null || true
fi
# Also check Art/Cursors
if [ -d "$EDITED/Art/Cursors" ]; then
    cp -rn "$EDITED/Art/Cursors/"* "$ASSETS_DIR/cursors/" 2>/dev/null || true
fi

# Link/copy Video files (BIK)
echo "  - Video files..."
if [ -d "$EDITED/Data/Videos" ]; then
    cp -rn "$EDITED/Data/Videos/"* "$ASSETS_DIR/video/" 2>/dev/null || true
fi
if [ -d "$ORIGINAL_ZH/Data/Videos" ]; then
    cp -rn "$ORIGINAL_ZH/Data/Videos/"* "$ASSETS_DIR/video/" 2>/dev/null || true
fi
if [ -d "$SOURCE_DIR/Movies" ]; then
    cp -rn "$SOURCE_DIR/Movies/"* "$ASSETS_DIR/video/" 2>/dev/null || true
fi

# Link/copy Splash screens (BMP)
echo "  - Splash screens..."
if [ -d "$EDITED/Data/Splash" ]; then
    cp -rn "$EDITED/Data/Splash/"* "$ASSETS_DIR/splashes/" 2>/dev/null || true
fi
if [ -d "$ORIGINAL_ZH/Data/Splash" ]; then
    cp -rn "$ORIGINAL_ZH/Data/Splash/"* "$ASSETS_DIR/splashes/" 2>/dev/null || true
fi
# Also check Art/Textures for loading screens
find "$EDITED" -name "*Loading*.bmp" -exec cp -n {} "$ASSETS_DIR/splashes/" \; 2>/dev/null || true

# Link/copy DDS textures
echo "  - DDS texture files..."
find "$EDITED" -name "*.dds" -o -name "*.DDS" | while read f; do
    cp -n "$f" "$ASSETS_DIR/textures/" 2>/dev/null || true
done
find "$ORIGINAL_ZH" -name "*.dds" -o -name "*.DDS" | while read f; do
    cp -n "$f" "$ASSETS_DIR/textures/" 2>/dev/null || true
done

echo ""
echo "=== Asset Summary ==="
echo "Audio files:   $(find "$ASSETS_DIR/audio" -type f 2>/dev/null | wc -l | tr -d ' ')"
echo "Cursor files:  $(find "$ASSETS_DIR/cursors" -type f \( -name "*.ani" -o -name "*.cur" -o -name "*.ANI" -o -name "*.CUR" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "INI files:     $(find "$ASSETS_DIR/ini" -type f -name "*.ini" 2>/dev/null | wc -l | tr -d ' ')"
echo "W3D models:    $(find "$ASSETS_DIR/models" -type f \( -name "*.W3D" -o -name "*.w3d" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "TGA textures:  $(find "$ASSETS_DIR/textures" -type f \( -name "*.tga" -o -name "*.TGA" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "DDS textures:  $(find "$ASSETS_DIR/textures" -type f \( -name "*.dds" -o -name "*.DDS" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "Video files:   $(find "$ASSETS_DIR/video" -type f \( -name "*.bik" -o -name "*.BIK" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "Splash files:  $(find "$ASSETS_DIR/splashes" -type f \( -name "*.bmp" -o -name "*.BMP" \) 2>/dev/null | wc -l | tr -d ' ')"
echo "WND UI files:  $(find "$ASSETS_DIR/ui" -type f -name "*.wnd" 2>/dev/null | wc -l | tr -d ' ')"
echo "CSF files:     $(find "$ASSETS_DIR/data" -type f -name "*.csf" 2>/dev/null | wc -l | tr -d ' ')"
echo "Map files:     $(find "$ASSETS_DIR/maps" -type f 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "Done! Assets are now available in: $ASSETS_DIR"
