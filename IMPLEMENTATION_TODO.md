# C&C Generals: Zero Hour - Complete Implementation Roadmap

**Goal**: Create a fully playable, 100% authentic C&C Generals Zero Hour for macOS
**Reference**: Thyme engine (`~/Code/thyme`) - C++ reimplementation
**Language**: Zig + Home (compiled to native macOS binary with Metal rendering)

---

## Prerequisites

### Required Assets (from original game or EA release)
- [ ] Locate original game data files (.BIG archives)
- [ ] Implement BIG archive reader to extract assets
- [ ] Verify all required asset types are accessible:
  - [ ] INI configuration files
  - [ ] W3D models (.w3d)
  - [ ] Textures (TGA, DDS)
  - [ ] Audio (WAV, MP3)
  - [ ] Videos (BIK)
  - [ ] Maps (.map)
  - [ ] Strings (CSF)

---

## Phase 1: Core Infrastructure [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: CRITICAL - Must complete first

### 1.1 BIG Archive System
- [ ] Parse BIG file header and file table
- [ ] Implement file extraction from archives
- [ ] Create virtual filesystem for asset access
- [ ] Support nested BIG archives
- **Reference**: `thyme/src/game/common/compression/`

### 1.2 Platform Layer (macOS)
- [ ] Window creation with Metal backend ✅ (exists)
- [ ] Input handling (keyboard, mouse)
- [ ] Event loop integration
- [ ] High DPI / Retina support
- [ ] Fullscreen toggle
- **Files**: `src/platform/macos_window.m`, `src/platform/macos_renderer.m`

### 1.3 Memory Management
- [ ] Pool allocators for game objects
- [ ] Asset streaming/caching system
- [ ] Memory budget management

---

## Phase 2: Rendering System [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: CRITICAL

### 2.1 Metal Renderer
- [ ] Initialize Metal device and command queue
- [ ] Create render pipeline states
- [ ] Implement vertex/index buffer management
- [ ] Texture loading and sampling
- [ ] Shader compilation (MSL)
- **Reference**: `thyme/src/w3d/renderer/`

### 2.2 W3D Model Rendering
- [ ] Parse W3D mesh chunks
- [ ] Load vertex positions, normals, UVs
- [ ] Load bone hierarchy
- [ ] Implement skeletal animation
- [ ] Material/texture binding
- [ ] LOD selection
- **Reference**: `thyme/src/w3d/lib/`

### 2.3 Terrain Rendering
- [ ] Height map loading
- [ ] Terrain texture blending
- [ ] Water plane rendering
- [ ] Cliff/shoreline handling
- **Reference**: `thyme/src/game/client/terrain/`

### 2.4 Particle System
- [ ] Particle emitter types
- [ ] Billboard rendering
- [ ] Smoke, fire, explosion effects
- **Reference**: `thyme/src/w3d/renderer/`

### 2.5 2D UI Rendering
- [ ] Sprite batching
- [ ] Font rendering (bitmap fonts)
- [ ] WND UI element rendering
- **Files**: `src/platform/macos_sprite_renderer.m`

---

## Phase 3: Asset Loading [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: HIGH

### 3.1 INI Parser
- [ ] Tokenizer for INI format ✅ (basic exists)
- [ ] Object definition parsing
- [ ] Weapon definitions
- [ ] Upgrade definitions
- [ ] Science/tech tree
- [ ] Command button definitions
- **Reference**: `thyme/src/game/common/ini/`

### 3.2 Texture Loading
- [ ] TGA loader (uncompressed + RLE) ✅ (exists)
- [ ] DDS loader (DXT1/3/5) ✅ (exists)
- [ ] Texture atlas support
- [ ] Mipmap generation

### 3.3 W3D Model Loading
- [ ] Chunk parser framework
- [ ] MESH chunk (geometry)
- [ ] HIERARCHY chunk (bones)
- [ ] ANIMATION chunk
- [ ] COMPRESSED_ANIMATION
- [ ] EMITTER chunk (particles)
- **Reference**: `thyme/src/w3d/lib/`

### 3.4 Audio Loading
- [ ] WAV file loading
- [ ] MP3 decoding (for music)
- [ ] Audio streaming for large files

### 3.5 Map Loading
- [ ] Map file format parsing
- [ ] Terrain heightmap
- [ ] Object placement
- [ ] Waypoints
- [ ] Player start positions
- **Reference**: `thyme/src/game/logic/map/`

### 3.6 String/Localization Loading
- [ ] CSF file parser
- [ ] UTF-16 to UTF-8 conversion
- [ ] String lookup by label

---

## Phase 4: Game Logic [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: HIGH

### 4.1 Entity System
- [ ] Game object base class
- [ ] Object factory (from INI templates)
- [ ] Object lifecycle management
- [ ] Object ID assignment
- **Reference**: `thyme/src/game/logic/object/`

### 4.2 Unit Behaviors
- [ ] State machine for unit AI
- [ ] Idle behavior
- [ ] Move behavior
- [ ] Attack behavior
- [ ] Guard behavior
- [ ] Die behavior
- **Reference**: `thyme/src/game/logic/object/behavior/`

### 4.3 Locomotor System
- [ ] Ground movement
- [ ] Air movement (helicopters, jets)
- [ ] Naval movement
- [ ] Cliff climbing
- **Reference**: `thyme/src/game/logic/object/locomotor.cpp`

### 4.4 Weapon System
- [ ] Weapon templates
- [ ] Projectile spawning
- [ ] Damage calculation
- [ ] Armor types
- [ ] Area of effect
- **Reference**: `thyme/src/game/logic/object/weapon/`

### 4.5 Building System
- [ ] Construction dozer
- [ ] Building placement validation
- [ ] Construction progress
- [ ] Power system
- [ ] Building upgrades

### 4.6 Economy System
- [ ] Supply collection
- [ ] Resource tracking
- [ ] Build costs
- [ ] Production queues

---

## Phase 5: AI System [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: MEDIUM

### 5.1 Pathfinding
- [ ] Navigation mesh generation
- [ ] A* pathfinding
- [ ] Hierarchical pathfinding
- [ ] Formation movement
- [ ] Obstacle avoidance
- **Reference**: `thyme/src/game/logic/ai/`

### 5.2 Unit AI
- [ ] Target selection
- [ ] Threat assessment
- [ ] Micro behaviors
- [ ] Group coordination

### 5.3 Skirmish AI
- [ ] Base building logic
- [ ] Army composition
- [ ] Attack timing
- [ ] Defense setup
- [ ] Resource management
- **Reference**: `thyme/src/game/logic/ai/`

### 5.4 Generals Challenge AI
- [ ] Per-general AI personalities
- [ ] Difficulty scaling
- [ ] Taunt system

---

## Phase 6: User Interface [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: HIGH

### 6.1 WND System
- [ ] WND file parser ✅ (basic exists)
- [ ] Element types (WINDOW, BUTTON, etc.)
- [ ] Draw data parsing
- [ ] Event handling
- **Reference**: `thyme/src/game/client/gui/`

### 6.2 Main Menu
- [ ] Background (shell map or image)
- [ ] Menu navigation
- [ ] Button interactions
- [ ] Sub-menus

### 6.3 In-Game HUD
- [ ] Minimap
- [ ] Resource display
- [ ] Command bar
- [ ] Selection info
- [ ] Control groups

### 6.4 Selection System
- [ ] Click selection
- [ ] Box selection
- [ ] Control groups (0-9)
- [ ] Double-click (select all of type)

---

## Phase 7: Audio System [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: MEDIUM

### 7.1 Audio Engine
- [ ] CoreAudio/AVFoundation integration
- [ ] 3D positional audio
- [ ] Sound mixing
- [ ] Volume control

### 7.2 Sound Effects
- [ ] Unit responses
- [ ] Weapon sounds
- [ ] Building sounds
- [ ] UI sounds

### 7.3 Music System
- [ ] Track loading
- [ ] Crossfade transitions
- [ ] Context-aware music

### 7.4 EVA System
- [ ] Event triggers
- [ ] Voice queue
- [ ] Priority system
- [ ] Faction-specific voices

---

## Phase 8: Camera System [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: HIGH

### 8.1 RTS Camera
- [ ] Pan (WASD/edge scroll)
- [ ] Zoom (scroll wheel)
- [ ] Rotate (middle mouse)
- [ ] Smooth movement

### 8.2 Camera Constraints
- [ ] Map boundaries
- [ ] Height limits
- [ ] Angle limits

### 8.3 Camera Effects
- [ ] Screen shake
- [ ] Cinematic camera paths

---

## Phase 9: Input System [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: HIGH

### 9.1 Input Handling
- [ ] Keyboard input
- [ ] Mouse input (buttons, position, wheel)
- [ ] Hotkey system
- [ ] Key rebinding

### 9.2 Commands
- [ ] Unit commands (move, attack, stop, etc.)
- [ ] Building commands (build, sell, rally)
- [ ] Special abilities

---

## Phase 10: Game Modes [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: MEDIUM

### 10.1 Skirmish
- [ ] Map selection
- [ ] Player/AI setup
- [ ] Game start
- [ ] Victory conditions

### 10.2 Campaign
- [ ] Mission loading
- [ ] Objectives
- [ ] Triggers/scripts
- [ ] Cutscenes

### 10.3 Generals Challenge
- [ ] General selection
- [ ] Ladder progression
- [ ] AI generals

### 10.4 Multiplayer (Future)
- [ ] LAN discovery
- [ ] Lobby system
- [ ] Game synchronization

---

## Phase 11: Polish & Optimization [NOT STARTED]
**Status**: 🔴 Not Started
**Priority**: LOW (after core gameplay)

### 11.1 Performance
- [ ] Frustum culling
- [ ] Occlusion culling
- [ ] LOD system
- [ ] Batch rendering
- [ ] Asset streaming

### 11.2 Save/Load
- [ ] Game state serialization
- [ ] Quick save/load
- [ ] Auto save

### 11.3 Replay System
- [ ] Command recording
- [ ] Playback
- [ ] Timeline controls

### 11.4 Settings
- [ ] Graphics options
- [ ] Audio options
- [ ] Control options
- [ ] Persistence

---

## Current Progress Summary

| Phase | Description | Status | Progress |
|-------|-------------|--------|----------|
| 1 | Core Infrastructure | 🟡 Partial | 20% |
| 2 | Rendering System | 🔴 Not Started | 5% |
| 3 | Asset Loading | 🟡 Partial | 15% |
| 4 | Game Logic | 🔴 Not Started | 0% |
| 5 | AI System | 🔴 Not Started | 0% |
| 6 | User Interface | 🟡 Partial | 10% |
| 7 | Audio System | 🔴 Not Started | 0% |
| 8 | Camera System | 🔴 Not Started | 0% |
| 9 | Input System | 🔴 Not Started | 5% |
| 10 | Game Modes | 🔴 Not Started | 0% |
| 11 | Polish | 🔴 Not Started | 0% |

**Overall Progress**: ~5%

---

## Next Steps (Priority Order)

1. **[IMMEDIATE]** Implement BIG archive reader to access game assets
2. **[IMMEDIATE]** Set up Metal rendering pipeline with basic 3D
3. **[HIGH]** Implement W3D model loading and rendering
4. **[HIGH]** Create terrain rendering system
5. **[HIGH]** Build entity system and object factory
6. **[HIGH]** Implement basic unit movement and selection
7. **[MEDIUM]** Add combat system
8. **[MEDIUM]** Create in-game UI (HUD, minimap)
9. **[MEDIUM]** Implement AI pathfinding
10. **[LOW]** Add audio, polish, optimization

---

## File Structure

```
src/
├── main.zig                 # Entry point
├── platform/
│   ├── macos_window.m       # Window management
│   ├── macos_renderer.m     # Metal rendering
│   └── macos_audio.m        # Audio (to create)
├── engine/
│   ├── big_archive.zig      # BIG file reading (to create)
│   ├── w3d_loader.zig       # W3D model loading (to create)
│   ├── terrain.zig          # Terrain system (to create)
│   ├── entity.zig           # Entity system (to create)
│   ├── weapon.zig           # Weapon system (to create)
│   └── ...
├── game/
│   ├── unit.zig             # Unit logic (to create)
│   ├── building.zig         # Building logic (to create)
│   ├── player.zig           # Player state (to create)
│   └── ...
├── ai/
│   ├── pathfinding.zig      # Pathfinding (to create)
│   ├── skirmish_ai.zig      # AI logic (to create)
│   └── ...
├── ui/
│   ├── wnd_parser.zig       # WND files (exists)
│   ├── hud.zig              # In-game HUD (to create)
│   └── ...
└── assets/
    ├── ini_parser.zig       # INI parsing (exists)
    └── ...
```

---

## References

- **Thyme Engine**: `~/Code/thyme` - Primary reference for all systems
- **W3D Format**: `thyme/src/w3d/` - Model and animation format
- **INI Format**: `thyme/src/game/common/ini/` - Configuration parsing
- **Game Logic**: `thyme/src/game/logic/` - Unit behaviors, weapons, AI
- **Rendering**: `thyme/src/w3d/renderer/` - Graphics pipeline

---

*Last Updated*: 2025-11-21
*Version*: 0.1.0 (Planning Phase)
