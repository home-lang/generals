# C&C Generals Zero Hour - Home Language Port

## Project Overview

Refactoring the Command & Conquer: Generals – Zero Hour C++ codebase (4,385 source files) to the Home programming language. This is a complete reimplementation of a AAA RTS game engine with modern language features.

**Original:** ~/Code/generals-old (C++20 codebase)
**Target:** ~/Code/generals (Home language)

---

## Phase 1: Foundation & Core Systems (Weeks 1-4)

### 1.1 Project Setup
- [ ] Create directory structure mirroring original
- [ ] Set up Home build system (build.home)
- [ ] Configure linker script for game executable
- [ ] Set up testing infrastructure
- [ ] Create README and contribution guidelines

### 1.2 Core Memory Management
- [ ] Port `GameMemory.cpp` → `core/memory.home`
  - Custom allocators
  - Memory pools
  - Leak detection
- [ ] Port memory debugging tools
- [ ] Add Home-specific memory safety features
- [ ] **Home API Addition**: `basics/memory` module with game-optimized allocators

### 1.3 String Systems
- [ ] Port `AsciiString.cpp` → `core/string.home`
- [ ] Port `UnicodeString.cpp` → `core/unicode.home`
- [ ] Implement string pooling for performance
- [ ] **Home API Addition**: String interning/pooling utilities

### 1.4 File I/O & Filesystem
- [ ] Port `FileSystem.cpp` → `core/filesystem.home`
- [ ] Port `File.cpp`, `LocalFile.cpp` → file abstractions
- [ ] Port `ArchiveFile.cpp` → archive reading (.big files)
- [ ] Port `StreamingArchiveFile.cpp` → streaming I/O
- [ ] **Home API Addition**: `basics/archive` for game asset packaging

---

## Phase 2: Platform Layer & Rendering (Weeks 5-8)

### 2.1 Platform Abstraction
- [ ] Port Windows-specific code to cross-platform Home
- [ ] Abstract window creation/management
- [ ] Input handling (keyboard, mouse)
- [ ] **Home API Addition**: `basics/window` module

### 2.2 Graphics Foundation
- [ ] Port W3D (Westwood 3D) format loaders
- [ ] Implement DirectX/Vulkan backend abstraction
- [ ] Vertex/Index buffer management
- [ ] Shader system foundation
- [ ] **Home API Addition**: `basics/graphics` with modern GPU abstractions

### 2.3 Rendering Pipeline
- [ ] Scene graph system
- [ ] Camera management
- [ ] Mesh rendering
- [ ] Terrain rendering
- [ ] Particle systems
- [ ] **Home API Addition**: Scene graph utilities in `basics/rendering`

---

## Phase 3: Game Engine Core (Weeks 9-14)

### 3.1 Math Library
- [ ] Port vector/matrix math
- [ ] Quaternion rotations
- [ ] Collision detection primitives
- [ ] Frustum culling
- [ ] **Home API Addition**: `basics/math3d` for game math

### 3.2 Timing & Frame Management
- [ ] Port `FramePacer.cpp` → `engine/timing.home`
- [ ] Fixed timestep game loop
- [ ] Delta time handling
- [ ] **Home API Addition**: Frame pacing utilities

### 3.3 Entity Component System
- [ ] Design Home-native ECS architecture
- [ ] Port game object system
- [ ] Component registration
- [ ] Update/render loops
- [ ] **Home API Addition**: ECS framework in `basics/ecs`

### 3.4 Physics & Collision
- [ ] Implement collision detection
- [ ] Rigid body dynamics (basic)
- [ ] Pathfinding integration hooks
- [ ] **Home API Addition**: Physics utilities

---

## Phase 4: Game Logic Systems (Weeks 15-20)

### 4.1 Unit Management
- [ ] Port unit definitions and stats
- [ ] Unit creation/destruction
- [ ] Unit behaviors and AI
- [ ] Formation system
- [ ] **Home API Addition**: Behavior tree system

### 4.2 Building System
- [ ] Building placement
- [ ] Construction mechanics
- [ ] Production queues
- [ ] Tech tree dependencies

### 4.3 Combat System
- [ ] Weapon systems
- [ ] Damage calculation
- [ ] Line of sight
- [ ] Veterancy/experience

### 4.4 Economy & Resources
- [ ] Resource gathering
- [ ] Supply system
- [ ] Economy balancing

---

## Phase 5: AI Systems (Weeks 21-26)

### 5.1 Pathfinding
- [ ] A* pathfinding implementation
- [ ] Flow fields for unit movement
- [ ] Dynamic obstacle avoidance
- [ ] **Home API Addition**: Pathfinding library

### 5.2 AI Decision Making
- [ ] Skirmish AI
- [ ] Build order AI
- [ ] Combat tactics AI
- [ ] **Home API Addition**: FSM and behavior trees

### 5.3 Strategic AI
- [ ] Base building logic
- [ ] Attack coordination
- [ ] Defensive positioning

---

## Phase 6: Networking & Multiplayer (Weeks 27-32)

### 6.1 Network Foundation
- [ ] Lockstep networking model
- [ ] Command replication
- [ ] Network synchronization
- [ ] **Home API Addition**: `basics/netcode` for deterministic networking

### 6.2 Lobby & Matchmaking
- [ ] Lobby system
- [ ] Game hosting/joining
- [ ] Player ready states

### 6.3 Replay System
- [ ] Command recording
- [ ] Replay playback
- [ ] Replay viewer UI

---

## Phase 7: UI & HUD (Weeks 33-38)

### 7.1 UI Framework
- [ ] Widget system (buttons, panels, etc.)
- [ ] Layout management
- [ ] Event handling
- [ ] **Home API Addition**: Immediate-mode GUI library

### 7.2 In-Game HUD
- [ ] Minimap
- [ ] Unit selection UI
- [ ] Command bar
- [ ] Resource display

### 7.3 Menus
- [ ] Main menu
- [ ] Options menu
- [ ] Multiplayer lobby UI
- [ ] Map selection

---

## Phase 8: Audio System (Weeks 39-42)

### 8.1 Audio Engine
- [ ] Sound effect playback
- [ ] Music streaming
- [ ] 3D positional audio
- [ ] **Home API Addition**: `basics/audio` module

### 8.2 Voice & Dialog
- [ ] Unit voices
- [ ] Mission briefings
- [ ] Ambient sounds

---

## Phase 9: Content Pipeline & Tools (Weeks 43-48)

### 9.1 Asset Pipeline
- [ ] Model importer (.w3d → Home format)
- [ ] Texture conversion
- [ ] Audio conversion
- [ ] Map editor tools

### 9.2 Modding Support
- [ ] INI parsing and loading
- [ ] Script system for mods
- [ ] Asset loading from mods
- [ ] **Home API Addition**: INI/config parser

---

## Phase 10: Campaign & Missions (Weeks 49-54)

### 10.1 Mission System
- [ ] Mission scripting
- [ ] Objectives tracking
- [ ] Win/loss conditions

### 10.2 Campaign Flow
- [ ] Campaign progression
- [ ] Mission selection
- [ ] Cutscene integration

---

## Phase 11: Optimization & Polish (Weeks 55-60)

### 11.1 Performance
- [ ] Profiling and optimization
- [ ] LOD (Level of Detail) system
- [ ] Occlusion culling
- [ ] Multi-threading for game systems

### 11.2 Polish
- [ ] Visual effects polish
- [ ] Sound mixing
- [ ] UI/UX improvements
- [ ] Bug fixing

---

## Phase 12: Testing & Release (Weeks 61-65)

### 12.1 Testing
- [ ] Unit tests for core systems
- [ ] Integration tests
- [ ] Multiplayer stress testing
- [ ] Balance testing

### 12.2 Documentation
- [ ] API documentation
- [ ] Modding guide
- [ ] Architecture documentation

### 12.3 Release Preparation
- [ ] Packaging system
- [ ] Installer
- [ ] License compliance
- [ ] Release notes

---

## Home Language Features to Leverage

### Safety & Performance
- [ ] Use Home's ownership system for memory safety
- [ ] Leverage compile-time evaluation for data validation
- [ ] Use generics for type-safe collections
- [ ] Async/await for loading systems

### Modern Features
- [ ] Pattern matching for game state machines
- [ ] Traits for component interfaces
- [ ] Macros for code generation (unit/building definitions)
- [ ] Reflection for serialization

### Home Stdlib Extensions Needed

**High Priority APIs to Add:**
1. **`basics/memory`** - Game-optimized allocators, pools
2. **`basics/graphics`** - GPU abstraction (DirectX/Vulkan/Metal)
3. **`basics/audio`** - Sound engine integration
4. **`basics/ecs`** - Entity Component System framework
5. **`basics/netcode`** - Deterministic networking for RTS
6. **`basics/math3d`** - Game-specific math (vectors, matrices, quaternions)
7. **`basics/archive`** - Asset packaging (.big file format)
8. **`basics/window`** - Cross-platform windowing
9. **`basics/pathfinding`** - A* and flow field pathfinding
10. **`basics/ui`** - Immediate-mode or retained-mode GUI

---

## Directory Structure

```
generals/
├── build.home              # Home build configuration
├── core/                   # Core engine systems
│   ├── memory.home
│   ├── string.home
│   ├── filesystem.home
│   └── archive.home
├── engine/                 # Game engine
│   ├── timing.home
│   ├── ecs.home
│   ├── scene.home
│   └── camera.home
├── graphics/               # Rendering
│   ├── renderer.home
│   ├── mesh.home
│   ├── shader.home
│   └── terrain.home
├── game/                   # Game logic
│   ├── unit.home
│   ├── building.home
│   ├── combat.home
│   └── economy.home
├── ai/                     # AI systems
│   ├── pathfinding.home
│   ├── skirmish_ai.home
│   └── behavior_tree.home
├── network/                # Multiplayer
│   ├── netcode.home
│   ├── lobby.home
│   └── replay.home
├── ui/                     # User interface
│   ├── widgets.home
│   ├── hud.home
│   └── menus.home
├── audio/                  # Audio system
│   ├── sound.home
│   └── music.home
├── tools/                  # Asset pipeline tools
│   ├── model_converter.home
│   └── map_editor.home
└── main.home               # Entry point
```

---

## Success Metrics

- [ ] Game boots and shows main menu
- [ ] Single-player skirmish functional
- [ ] Multiplayer 1v1 works
- [ ] All factions playable
- [ ] Performance: 60 FPS on mid-range hardware
- [ ] Mod support functional
- [ ] Cross-platform (Windows, macOS, Linux)

---

## Estimated Timeline

**Total: 65 weeks (~15 months)**

This is an aggressive timeline for a full AAA game engine port. Adjust based on team size and part-time vs full-time work.

---

*Last Updated: 2025-11-16*
