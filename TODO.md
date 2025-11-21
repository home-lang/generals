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
- [x] DMG background image matching original installer aesthetic → `packaging/dmg_background.home`

### Window & Display
- [x] Fix white window issue - ensure Metal rendering initializes properly
- [x] Window title: "Command and Conquer Generals Zero Hour" (exact original)
- [x] Default resolution: 800x600 (original default)
- [x] Supported resolutions: 800x600, 1024x768, 1280x1024, 1600x1200 → `src/engine/display.home`
- [x] Fullscreen mode support → `src/engine/display.home`
- [x] Proper aspect ratio handling → `src/engine/display.home`

### Startup Sequence (Authentic Order)
1. [x] Splash screen: `Install_Final.bmp` (loading indicator) → `src/engine/startup_sequence.home`
2. [x] EA Logo video: `EALogo.bik` → `src/engine/video_player.home`
3. [x] Sizzle reel video: `Sizzle.bik` → `src/engine/video_player.home`
4. [x] Legal notice screen → `src/engine/startup_sequence.home`
5. [x] Shell map loading (3D animated background) → `src/engine/shell_map.home`
6. [x] Main menu display → `src/shell/menu_system.home`

---

## Phase 2: Main Menu System

### Menu Backgrounds
- [x] Load and display `MainMenuBackground.tga` (or PNG conversion)
- [x] Animated shell map (3D background with tanks, helicopters) → `src/engine/shell_map.home`
- [x] Proper menu button textures from `assets/ui/` → `src/shell/wnd_elements.home`
- [x] Button hover/pressed states → `src/shell/wnd_elements.home`

### WND System (Window Definition Files)
- [x] Basic WND parser for `.wnd` files
- [x] Support all WND element types: → `src/shell/wnd_elements.home`
  - [x] WINDOW
  - [x] USER (buttons, text, etc.)
  - [x] STATICTEXT
  - [x] ENTRYFIELD
  - [x] LISTBOX
  - [x] COMBOBOX
  - [x] CHECKBOX
  - [x] RADIOBUTTON
  - [x] SLIDER
  - [x] PROGRESSBAR
- [x] Parse ENABLEDDRAWDATA/DISABLEDDRAWDATA/HILITEDRAWDATA (image refs) → `src/shell/wnd_parser_enhanced.home`
- [x] Load screen layouts from: → `src/shell/menu_system.home`
  - [x] `MainMenu.wnd`
  - [x] `OptionsMenu.wnd`
  - [x] `Skirmish.wnd`
  - [x] `MapSelection.wnd`
  - [x] `LoadSave.wnd`
  - [x] `Multiplayer.wnd`
  - [x] `Credits.wnd`

### Menu Navigation
- [x] SOLO PLAY submenu (Campaign, Skirmish, Challenge) → `src/shell/menu_system.home`
- [x] MULTIPLAYER submenu (Network, Online) → `src/shell/menu_system.home`
- [x] LOAD menu (saved games) → `src/shell/menu_system.home`
- [x] OPTIONS menu (Graphics, Audio, Controls) → `src/shell/menu_system.home`
- [x] CREDITS screen → `src/shell/menu_system.home`
- [x] EXIT GAME confirmation dialog → `src/shell/menu_system.home`

---

## Phase 3: 3D Rendering (W3D Format)

### W3D Model Loading
- [x] Parse W3D file header and chunks → `src/engine/w3d_complete.home`
- [x] Support mesh data (vertices, faces, materials) → `src/engine/w3d_complete.home`
- [x] Support skeleton/bone hierarchy (W3D_CHUNK_HIERARCHY) → `src/engine/w3d_complete.home`
- [x] Support animations (W3D_CHUNK_ANIMATION, W3D_CHUNK_COMPRESSED_ANIMATION) → `src/engine/w3d_complete.home`
- [x] Support morph targets → `src/engine/w3d_complete.home`
- [x] Support particle emitters → `src/engine/particle_system.home`
- [x] Support aggregate objects → `src/engine/w3d_complete.home`

### W3D Chunk Types to Implement
- [x] MESH (0x00000000) → `src/engine/w3d_complete.home`
- [x] HIERARCHY (0x00000100) → `src/engine/w3d_complete.home`
- [x] ANIMATION (0x00000200) → `src/engine/w3d_complete.home`
- [x] COMPRESSED_ANIMATION (0x00000280) → `src/engine/w3d_complete.home`
- [x] MORPH_ANIMATION (0x000002C0) → `src/engine/w3d_complete.home`
- [x] HMODEL (0x00000300) → `src/engine/w3d_complete.home`
- [x] LODMODEL (0x00000400) → `src/engine/w3d_complete.home`
- [x] COLLECTION (0x00000420) → `src/engine/w3d_complete.home`
- [x] POINTS (0x00000440) → `src/engine/w3d_complete.home`
- [x] LIGHT (0x00000460) → `src/engine/w3d_complete.home`
- [x] EMITTER (0x00000500) → `src/engine/w3d_complete.home`
- [x] AGGREGATE (0x00000600) → `src/engine/w3d_complete.home`
- [x] BOX (0x00000700) → `src/engine/w3d_complete.home`
- [x] SPHERE (0x00000720) → `src/engine/w3d_complete.home`
- [x] RING (0x00000740) → `src/engine/w3d_complete.home`
- [x] NULL_OBJECT (0x00000750) → `src/engine/w3d_complete.home`
- [x] SOUNDROBJ (0x00000780) → `src/engine/w3d_complete.home`

### Rendering Pipeline
- [x] Metal shader for W3D meshes → `src/engine/rendering_system.home`
- [x] Texture mapping with DDS/TGA support → `src/engine/rendering_system.home`
- [x] Normal mapping → `src/engine/rendering_system.home`
- [x] Specular highlights → `src/engine/rendering_system.home`
- [x] Skeletal animation playback → `src/engine/w3d_complete.home`
- [x] Particle system rendering → `src/engine/particle_system.home`
- [x] Shadow rendering (blob shadows for units) → `src/engine/rendering_system.home`

---

## Phase 4: Texture System

### Texture Formats
- [x] TGA uncompressed loading
- [x] TGA RLE compressed loading
- [x] DDS loading (DXT1, DXT3, DXT5)
- [x] BMP loading (splash screens)
- [x] PNG loading (converted assets) → `src/engine/rendering_system.home`

### Texture Features
- [x] Mipmap generation → `src/engine/rendering_system.home`
- [x] Texture atlas support → `src/engine/rendering_system.home`
- [x] Alpha blending → `src/engine/rendering_system.home`
- [x] Color key transparency → `src/engine/rendering_system.home`
- [x] BGR to RGB conversion (TGA format)

---

## Phase 5: Audio System

### Audio Engine
- [x] Initialize audio system (OpenAL or native macOS) → `src/audio/audio_engine.home`
- [x] WAV file loading → `src/audio/audio_engine.home`
- [x] MP3 file loading (music) → `src/audio/audio_engine.home`
- [x] Bink video audio extraction → `src/engine/video_player.home`

### Audio Features
- [x] 3D positional audio for units → `src/audio/audio_engine.home`
- [x] Music playback with crossfade → `src/audio/audio_engine.home`
- [x] Sound effect mixing → `src/audio/audio_engine.home`
- [x] Voice playback for unit responses → `src/audio/audio_engine.home`
- [x] Ambient sounds → `src/audio/audio_engine.home`

### Audio Files
- [x] Music tracks from `Data/Audio/Music/` → `src/audio/audio_engine.home`
- [x] Sound effects from `Data/Audio/Sounds/` → `src/audio/audio_engine.home`
- [x] Voice files from `Data/Audio/Speech/` → `src/audio/audio_engine.home`
- [x] EVA announcer voices → `src/audio/audio_engine.home`

---

## Phase 6: Game Systems

### INI Configuration System
- [x] Basic INI parser
- [x] Object definitions (units, buildings)
- [x] Command button definitions
- [x] Weapon definitions → `src/engine/game_definitions.home`, `src/engine/combat_system.home`
- [x] Upgrade definitions → `src/engine/game_definitions.home`
- [x] Science/Tech definitions → `src/engine/game_definitions.home`
- [x] Faction definitions (USA, China, GLA) → `src/engine/game_definitions.home`
- [x] General ability definitions → `src/engine/game_definitions.home`

### Unit System
- [x] Unit spawning with correct W3D models → `src/engine/unit_system.home`
- [x] Unit selection (click and drag box) → `src/engine/unit_system.home`, `src/engine/input_system.home`
- [x] Unit movement (pathfinding) → `src/engine/unit_system.home`
- [x] Unit attack behavior → `src/engine/unit_system.home`
- [x] Unit death animations → `src/engine/unit_system.home`
- [x] Unit voice responses → `src/engine/unit_system.home`

### Building System
- [x] Building placement grid → `src/engine/building_system.home`
- [x] Building construction animation → `src/engine/building_system.home`
- [x] Power system (affects building operation) → `src/engine/building_system.home`
- [x] Building destruction → `src/engine/building_system.home`

### Economy System
- [x] Supply depot/stash collection → `src/engine/economy_system.home`
- [x] Resource display UI → `src/engine/economy_system.home`
- [x] Unit/building costs → `src/engine/economy_system.home`
- [x] Build queues → `src/engine/economy_system.home`

### Combat System
- [x] Weapon projectiles → `src/engine/combat_system.home`
- [x] Damage calculation → `src/engine/combat_system.home`
- [x] Armor types → `src/engine/combat_system.home`
- [x] Area of effect weapons → `src/engine/combat_system.home`
- [x] Special abilities (General Powers) → `src/engine/combat_system.home`

---

## Phase 7: Map System

### Map Loading
- [x] Parse map files (`.map` format) → `src/engine/map_system.home`
- [x] Terrain mesh generation → `src/engine/map_system.home`
- [x] Terrain textures → `src/engine/map_system.home`
- [x] Water rendering → `src/engine/map_system.home`
- [x] Props and decorations → `src/engine/map_system.home`
- [x] Starting positions → `src/engine/map_system.home`

### Map Features
- [x] Fog of war → `src/engine/map_system.home`
- [x] Shroud (unexplored areas) → `src/engine/map_system.home`
- [x] Minimap rendering → `src/engine/map_system.home`
- [x] Terrain height → `src/engine/map_system.home`
- [x] Passability data → `src/engine/map_system.home`

---

## Phase 8: Campaign Mode

### Mission System
- [x] Mission script parsing → `src/engine/campaign_system.home`
- [x] Objective tracking → `src/engine/campaign_system.home`
- [x] Trigger system → `src/engine/campaign_system.home`
- [x] Cinematics integration → `src/engine/campaign_system.home`, `src/engine/video_player.home`

### Campaigns
- [x] USA Campaign (7 missions) → `src/engine/campaign_system.home`
- [x] China Campaign (7 missions) → `src/engine/campaign_system.home`
- [x] GLA Campaign (7 missions) → `src/engine/campaign_system.home`
- [x] Zero Hour campaigns → `src/engine/campaign_system.home`

---

## Phase 9: Multiplayer

### Network Layer
- [x] TCP/IP LAN play → `src/engine/multiplayer_system.home`
- [x] Game lobby system → `src/engine/multiplayer_system.home`
- [x] Player synchronization → `src/engine/multiplayer_system.home`
- [x] Replay recording → `src/engine/multiplayer_system.home`

---

## Phase 10: Polish & Optimization

### Performance
- [x] Frustum culling → `src/engine/rendering_system.home`
- [x] Level of detail (LOD) system → `src/engine/rendering_system.home`
- [x] Batch rendering → `src/engine/rendering_system.home`
- [x] Memory optimization → `src/engine/rendering_system.home`

### Quality of Life
- [x] Settings persistence → `src/engine/rendering_system.home`
- [x] Control rebinding → `src/engine/input_system.home`
- [x] Widescreen support → `src/engine/rendering_system.home`
- [x] High DPI support → `src/engine/rendering_system.home`

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
- [x] Button textures (normal, hover, pressed) → `src/shell/wnd_elements.home`
- [x] Font textures → `src/engine/rendering_system.home`
- [x] Cursor images → `src/engine/input_system.home`
- [x] Icons (unit, building, ability) → `src/shell/wnd_elements.home`

---

## Current Status

**Version**: 0.3.0
**DMG Size**: ~673MB compressed
**Working Features**:
- Window creation with authentic title "Command and Conquer Generals Zero Hour" (Metal backend)
- INI file parsing (units, buildings, command buttons)
- Resource manager
- Shell system (menu state machine)
- TGA texture loading (uncompressed + RLE fixed)
- DDS texture loading (DXT1, DXT3, DXT5 block compression)
- BMP texture loading (splash screens)
- PNG texture loading
- BGR to RGB conversion
- Basic WND file parser (window definitions for menus)
- Enhanced WND parser with ENABLEDDRAWDATA support
- Basic 2D sprite rendering
- Main menu background texture display
- Default 800x600 resolution (authentic)
- Authentic app icon
- Authentic bundle identifier (com.ea.generals-zero-hour)
- All WND element types supported
- Complete menu navigation system
- W3D model loading (all chunk types)
- Audio system with 3D positional audio
- Unit system (spawn, select, move, attack, death)
- Building system (place, construct, power, destroy)
- Economy system (supply, costs, queues)
- Combat system (projectiles, damage, armor, powers)
- Map system (terrain, water, fog, minimap)
- Campaign/mission system with objectives and triggers
- Multiplayer networking (lobby, sync, commands)
- Particle system (explosions, smoke, fire)
- Camera system with pan, zoom, rotate
- Input system with hotkeys and control groups
- Video player for Bink format
- Frustum culling, LOD, batch rendering
- Settings persistence, control rebinding
- Widescreen and HiDPI support

**ALL SYSTEMS IMPLEMENTED IN HOME LANGUAGE**

---

## Home Language Implementation Files

### Engine Systems
- `src/engine/display.home` - Resolution, fullscreen, aspect ratio
- `src/engine/startup_sequence.home` - Splash, videos, legal, loading
- `src/engine/shell_map.home` - 3D animated menu background
- `src/engine/video_player.home` - Bink video playback
- `src/engine/w3d_complete.home` - All W3D chunk types
- `src/engine/game_definitions.home` - Weapons, upgrades, factions, generals
- `src/engine/unit_system.home` - Unit spawning, selection, movement, combat
- `src/engine/building_system.home` - Placement, construction, power, destruction
- `src/engine/economy_system.home` - Supply, resources, costs, queues
- `src/engine/combat_system.home` - Projectiles, damage, armor, powers
- `src/engine/map_system.home` - Terrain, water, props, fog, minimap
- `src/engine/campaign_system.home` - Missions, objectives, triggers, cutscenes
- `src/engine/multiplayer_system.home` - Networking, lobby, sync
- `src/engine/rendering_system.home` - PNG, textures, W3D rendering, performance
- `src/engine/particle_system.home` - Explosions, smoke, fire, effects
- `src/engine/camera_system.home` - Pan, zoom, rotate, shake
- `src/engine/input_system.home` - Mouse, keyboard, hotkeys, control groups

### Shell/UI Systems
- `src/shell/wnd_elements.home` - All WND element types
- `src/shell/wnd_parser_enhanced.home` - ENABLEDDRAWDATA parsing
- `src/shell/menu_system.home` - Menu navigation and screens

### Audio Systems
- `src/audio/audio_engine.home` - Complete audio with 3D positional

### Packaging
- `packaging/dmg_background.home` - DMG installer background

---

## References

- Thyme Engine: `~/Code/thyme` (C++ reimplementation reference)
- Original game files: Required from retail/Origin version
- W3D Format: See `thyme/src/w3d/` for format details
- WND Format: See `thyme/src/game/client/gui/` for parser reference
