# C&C Generals: Zero Hour - 100% Authenticity TODO

**Goal**: Match the original Command & Conquer: Generals Zero Hour experience with 99.9% accuracy.

**Reference**: Original Thyme engine source at `~/Code/thyme`

---

## Phase 1: Critical Foundation (Current Priority)

### App Icon & Branding
- [x] Extract/create authentic C&C Generals icon (based on original game icon)
- [x] Create proper macOS .icns file with all required sizes (16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024)
- [x] Update Info.plist with correct icon reference
- [x] Set proper application name: "Command and Conquer Generals Zero Hour"
- [ ] DMG background image matching original installer aesthetic

### Window & Display
- [x] Fix white window issue - ensure Metal rendering initializes properly
- [x] Window title: "Command and Conquer Generals Zero Hour" (exact original)
- [x] Default resolution: 800x600 (original default)
- [ ] Supported resolutions: 800x600, 1024x768, 1280x1024, 1600x1200
- [ ] Fullscreen mode support
- [ ] Proper aspect ratio handling

### Startup Sequence (Authentic Order)
1. [ ] Splash screen: `Install_Final.bmp` (loading indicator)
2. [ ] EA Logo video: `EALogo.bik`
3. [ ] Sizzle reel video: `Sizzle.bik`
4. [ ] Legal notice screen
5. [ ] Shell map loading (3D animated background)
6. [ ] Main menu display

---

## Phase 2: Main Menu System

### Menu Backgrounds
- [x] Load and display `MainMenuBackground.tga` (or PNG conversion)
- [ ] Animated shell map (3D background with tanks, helicopters)
- [ ] Proper menu button textures from `assets/ui/`
- [ ] Button hover/pressed states

### WND System (Window Definition Files)
- [x] Basic WND parser for `.wnd` files
- [ ] Support all WND element types:
  - [x] WINDOW
  - [x] USER (buttons, text, etc.)
  - [ ] STATICTEXT
  - [ ] ENTRYFIELD
  - [ ] LISTBOX
  - [ ] COMBOBOX
  - [ ] CHECKBOX
  - [ ] RADIOBUTTON
  - [ ] SLIDER
  - [ ] PROGRESSBAR
- [ ] Parse ENABLEDDRAWDATA/DISABLEDDRAWDATA/HILITEDRAWDATA (image refs)
- [ ] Load screen layouts from:
  - [ ] `MainMenu.wnd`
  - [ ] `OptionsMenu.wnd`
  - [ ] `Skirmish.wnd`
  - [ ] `MapSelection.wnd`
  - [ ] `LoadSave.wnd`
  - [ ] `Multiplayer.wnd`
  - [ ] `Credits.wnd`

### Menu Navigation
- [ ] SOLO PLAY submenu (Campaign, Skirmish, Challenge)
- [ ] MULTIPLAYER submenu (Network, Online)
- [ ] LOAD menu (saved games)
- [ ] OPTIONS menu (Graphics, Audio, Controls)
- [ ] CREDITS screen
- [ ] EXIT GAME confirmation dialog

---

## Phase 3: 3D Rendering (W3D Format)

### W3D Model Loading
- [ ] Parse W3D file header and chunks
- [ ] Support mesh data (vertices, faces, materials)
- [ ] Support skeleton/bone hierarchy (W3D_CHUNK_HIERARCHY)
- [ ] Support animations (W3D_CHUNK_ANIMATION, W3D_CHUNK_COMPRESSED_ANIMATION)
- [ ] Support morph targets
- [ ] Support particle emitters
- [ ] Support aggregate objects

### W3D Chunk Types to Implement
- [ ] MESH (0x00000000)
- [ ] HIERARCHY (0x00000100)
- [ ] ANIMATION (0x00000200)
- [ ] COMPRESSED_ANIMATION (0x00000280)
- [ ] MORPH_ANIMATION (0x000002C0)
- [ ] HMODEL (0x00000300)
- [ ] LODMODEL (0x00000400)
- [ ] COLLECTION (0x00000420)
- [ ] POINTS (0x00000440)
- [ ] LIGHT (0x00000460)
- [ ] EMITTER (0x00000500)
- [ ] AGGREGATE (0x00000600)
- [ ] BOX (0x00000700)
- [ ] SPHERE (0x00000720)
- [ ] RING (0x00000740)
- [ ] NULL_OBJECT (0x00000750)
- [ ] SOUNDROBJ (0x00000780)

### Rendering Pipeline
- [ ] Metal shader for W3D meshes
- [ ] Texture mapping with DDS/TGA support
- [ ] Normal mapping
- [ ] Specular highlights
- [ ] Skeletal animation playback
- [ ] Particle system rendering
- [ ] Shadow rendering (blob shadows for units)

---

## Phase 4: Texture System

### Texture Formats
- [x] TGA uncompressed loading
- [x] TGA RLE compressed loading
- [x] DDS loading (DXT1, DXT3, DXT5)
- [x] BMP loading (splash screens)
- [ ] PNG loading (converted assets)

### Texture Features
- [ ] Mipmap generation
- [ ] Texture atlas support
- [ ] Alpha blending
- [ ] Color key transparency
- [x] BGR to RGB conversion (TGA format)

---

## Phase 5: Audio System

### Audio Engine
- [ ] Initialize audio system (OpenAL or native macOS)
- [ ] WAV file loading
- [ ] MP3 file loading (music)
- [ ] Bink video audio extraction

### Audio Features
- [ ] 3D positional audio for units
- [ ] Music playback with crossfade
- [ ] Sound effect mixing
- [ ] Voice playback for unit responses
- [ ] Ambient sounds

### Audio Files
- [ ] Music tracks from `Data/Audio/Music/`
- [ ] Sound effects from `Data/Audio/Sounds/`
- [ ] Voice files from `Data/Audio/Speech/`
- [ ] EVA announcer voices

---

## Phase 6: Game Systems

### INI Configuration System
- [x] Basic INI parser
- [x] Object definitions (units, buildings)
- [x] Command button definitions
- [ ] Weapon definitions
- [ ] Upgrade definitions
- [ ] Science/Tech definitions
- [ ] Faction definitions (USA, China, GLA)
- [ ] General ability definitions

### Unit System
- [ ] Unit spawning with correct W3D models
- [ ] Unit selection (click and drag box)
- [ ] Unit movement (pathfinding)
- [ ] Unit attack behavior
- [ ] Unit death animations
- [ ] Unit voice responses

### Building System
- [ ] Building placement grid
- [ ] Building construction animation
- [ ] Power system (affects building operation)
- [ ] Building destruction

### Economy System
- [ ] Supply depot/stash collection
- [ ] Resource display UI
- [ ] Unit/building costs
- [ ] Build queues

### Combat System
- [ ] Weapon projectiles
- [ ] Damage calculation
- [ ] Armor types
- [ ] Area of effect weapons
- [ ] Special abilities (General Powers)

---

## Phase 7: Map System

### Map Loading
- [ ] Parse map files (`.map` format)
- [ ] Terrain mesh generation
- [ ] Terrain textures
- [ ] Water rendering
- [ ] Props and decorations
- [ ] Starting positions

### Map Features
- [ ] Fog of war
- [ ] Shroud (unexplored areas)
- [ ] Minimap rendering
- [ ] Terrain height
- [ ] Passability data

---

## Phase 8: Campaign Mode

### Mission System
- [ ] Mission script parsing
- [ ] Objective tracking
- [ ] Trigger system
- [ ] Cinematics integration

### Campaigns
- [ ] USA Campaign (7 missions)
- [ ] China Campaign (7 missions)
- [ ] GLA Campaign (7 missions)
- [ ] Zero Hour campaigns

---

## Phase 9: Multiplayer

### Network Layer
- [ ] TCP/IP LAN play
- [ ] Game lobby system
- [ ] Player synchronization
- [ ] Replay recording

---

## Phase 10: Polish & Optimization

### Performance
- [ ] Frustum culling
- [ ] Level of detail (LOD) system
- [ ] Batch rendering
- [ ] Memory optimization

### Quality of Life
- [ ] Settings persistence
- [ ] Control rebinding
- [ ] Widescreen support
- [ ] High DPI support

---

## Asset Checklist

### Required Original Assets (~968MB uncompressed)
- [x] `Data/INI/*.ini` - Game configuration
- [x] `Data/Audio/` - Sound and music files
- [x] `Data/Maps/` - Game maps
- [x] `Data/Art/` - Textures and models
- [x] `Data/Movies/` - Video files (BIK format)
- [x] `Data/English/` - Localization
- [x] `Window/` - UI definitions (.wnd files)

### UI Assets
- [x] Main menu background
- [ ] Button textures (normal, hover, pressed)
- [ ] Font textures
- [ ] Cursor images
- [ ] Icons (unit, building, ability)

---

## Current Status

**Version**: 0.2.2
**DMG Size**: ~673MB compressed
**Working Features**:
- Window creation with authentic title "Command and Conquer Generals Zero Hour" (Metal backend)
- INI file parsing (units, buildings, command buttons)
- Resource manager
- Shell system (menu state machine)
- TGA texture loading (uncompressed + RLE fixed)
- DDS texture loading (DXT1, DXT3, DXT5 block compression)
- BMP texture loading (splash screens)
- BGR to RGB conversion
- Basic WND file parser (window definitions for menus)
- Basic 2D sprite rendering
- Main menu background texture display
- Default 800x600 resolution (authentic)
- Authentic app icon
- Authentic bundle identifier (com.ea.generals-zero-hour)

**Known Issues**:
- No 3D rendering yet
- No audio yet
- Menu buttons are procedural (not using original textures yet)
- PNG loading not yet implemented
- WND parser doesn't yet parse ENABLEDDRAWDATA for button images

---

## References

- Thyme Engine: `~/Code/thyme` (C++ reimplementation reference)
- Original game files: Required from retail/Origin version
- W3D Format: See `thyme/src/w3d/` for format details
- WND Format: See `thyme/src/game/client/gui/` for parser reference
