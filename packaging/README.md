# macOS Packaging

This directory contains everything needed to build and package C&C Generals Zero Hour as a macOS application.

## Files

- **Info.plist** - macOS app bundle metadata
- **build-app-bundle.sh** - Creates the .app bundle structure
- **build-dmg.sh** - Packages the .app into a DMG installer
- **AppIcon.icns** - Application icon (1024x1024 recommended)
- **dmg-background.png** - Custom DMG background (optional)

## Building

### Prerequisites

- macOS 11.0 or later
- Xcode Command Line Tools
- Home compiler (when available)

### Step 1: Build the App Bundle

```bash
cd /Users/chrisbreuer/Code/generals
chmod +x packaging/build-app-bundle.sh
./packaging/build-app-bundle.sh
```

This creates: `build/Generals.app`

**App Bundle Structure:**
```
Generals.app/
├── Contents/
│   ├── Info.plist           # App metadata
│   ├── PkgInfo              # App type signature
│   ├── MacOS/
│   │   └── Generals         # Executable
│   ├── Resources/
│   │   ├── AppIcon.icns     # App icon
│   │   └── assets/          # Game assets
│   │       ├── shaders/
│   │       ├── textures/
│   │       ├── sounds/
│   │       └── data/
│   └── Frameworks/          # Bundled libraries
│       ├── libopenal.dylib
│       └── ...
```

### Step 2: Create DMG Installer

```bash
chmod +x packaging/build-dmg.sh
./packaging/build-dmg.sh
```

This creates: `build/Generals-Zero-Hour-1.0.0.dmg`

**DMG Contents:**
- Generals.app
- Applications symlink (for drag-and-drop install)
- README.txt
- LICENSE.txt

## Testing

### Test App Bundle

```bash
# Run from command line
./build/Generals.app/Contents/MacOS/Generals

# Or open with Finder
open ./build/Generals.app
```

### Test DMG

```bash
# Mount DMG
open ./build/Generals-Zero-Hour-1.0.0.dmg

# Drag Generals.app to Applications
# Then run from Launchpad or Applications folder
```

## Distribution

### Code Signing (Required for Distribution)

To distribute outside the Mac App Store, you need to code sign:

```bash
# Set your Developer ID
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

# Build with signing
./packaging/build-app-bundle.sh

# Verify signature
codesign --verify --deep --strict --verbose=2 build/Generals.app
```

### Notarization (Required for macOS 10.15+)

For macOS Catalina and later, apps must be notarized:

```bash
# Create DMG
./packaging/build-dmg.sh

# Submit for notarization
xcrun notarytool submit build/Generals-Zero-Hour-1.0.0.dmg \
    --apple-id "your@email.com" \
    --team-id "TEAM_ID" \
    --password "app-specific-password" \
    --wait

# Staple notarization ticket
xcrun stapler staple build/Generals-Zero-Hour-1.0.0.dmg

# Verify
spctl --assess --type install --verbose build/Generals-Zero-Hour-1.0.0.dmg
```

## Customization

### App Icon

Create a 1024x1024 PNG, then convert to ICNS:

```bash
mkdir AppIcon.iconset
sips -z 16 16     icon.png --out AppIcon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out AppIcon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out AppIcon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out AppIcon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns AppIcon.iconset -o packaging/AppIcon.icns
```

### DMG Background

Create a 540x380 PNG background image:

```bash
# Save as packaging/dmg-background.png
# The build script will automatically include it
```

### Version Number

Edit `packaging/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>  <!-- Change this -->

<key>CFBundleVersion</key>
<string>1</string>  <!-- Increment for each build -->
```

## Troubleshooting

### "Generals.app" is damaged and can't be opened

This means Gatekeeper blocked the app. Solutions:

1. **Code sign the app** (recommended)
2. **Disable Gatekeeper temporarily:**
   ```bash
   sudo spctl --master-disable
   # Run app
   sudo spctl --master-enable
   ```
3. **Allow this specific app:**
   ```bash
   xattr -cr build/Generals.app
   ```

### App won't launch

Check console logs:

```bash
# View crash logs
open ~/Library/Logs/DiagnosticReports/

# Or use Console.app
open -a Console
```

### Missing dylibs

Bundle all required dynamic libraries:

```bash
# Find dependencies
otool -L build/Generals.app/Contents/MacOS/Generals

# Copy to Frameworks/
cp /path/to/library.dylib build/Generals.app/Contents/Frameworks/

# Fix library paths
install_name_tool -change /old/path/library.dylib \
    @executable_path/../Frameworks/library.dylib \
    build/Generals.app/Contents/MacOS/Generals
```

## App Store Submission

To submit to the Mac App Store:

1. **Use Mac App Store provisioning profile**
2. **Enable App Sandbox** in entitlements
3. **Remove private APIs** (if any)
4. **Follow App Store guidelines**

Create `Generals.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

Sign with entitlements:

```bash
codesign --force --deep --sign "3rd Party Mac Developer Application: Your Name" \
    --entitlements Generals.entitlements \
    build/Generals.app
```

## Continuous Integration

### GitHub Actions

Create `.github/workflows/build-macos.yml`:

```yaml
name: Build macOS App

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v2

    - name: Build App Bundle
      run: |
        chmod +x packaging/build-app-bundle.sh
        ./packaging/build-app-bundle.sh

    - name: Create DMG
      run: |
        chmod +x packaging/build-dmg.sh
        ./packaging/build-dmg.sh

    - name: Upload Artifacts
      uses: actions/upload-artifact@v2
      with:
        name: Generals-macOS
        path: build/Generals-Zero-Hour-*.dmg
```

## Performance

### DMG Compression

The build script uses maximum zlib compression:

```bash
hdiutil convert temp.dmg -format UDZO -imagekey zlib-level=9 -o final.dmg
```

**Compression Levels:**
- 1 = Fastest, largest file
- 9 = Slowest, smallest file (default)

### App Size Optimization

**Reduce binary size:**
```bash
# Strip debug symbols (when building with Home compiler)
strip build/Generals.app/Contents/MacOS/Generals
```

**Compress textures:**
```bash
# Use compressed texture formats
# DXT1/DXT5 for desktop
# PVRTC for iOS (if porting)
```

**Expected Sizes:**
- App Bundle: ~200-500 MB (with assets)
- DMG (compressed): ~100-200 MB

## License

All packaging scripts are GPL licensed, matching the Thyme Engine source.

## Support

For issues with packaging:
1. Check console logs (`Console.app`)
2. Verify code signature: `codesign -dv --verbose=4 Generals.app`
3. Check file permissions: `ls -lR Generals.app`
4. Review macOS security settings

## References

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [DMG Creation](https://developer.apple.com/forums/thread/653458)
