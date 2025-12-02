# C&C Generals Zero Hour - Complete Implementation TODO

## Master Task List for 100% Original Game Compatibility

This document contains **ALL** tasks required to achieve a pixel-perfect, audio-perfect, and gameplay-perfect recreation of C&C Generals Zero Hour in the Home programming language.

**Format**: Each task has a unique ID for tracking. Tasks are marked:
- `[ ]` = Not started
- `[~]` = In progress
- `[x]` = Complete

---

## TABLE OF CONTENTS

1. [PHASE 0: HOME LANGUAGE IMPROVEMENTS](#phase-0-home-language-improvements)
2. [PHASE 1: COMPILER & TYPE SYSTEM FIXES](#phase-1-compiler--type-system-fixes)
3. [PHASE 2: UPSTREAM GAME CODE PATCHES](#phase-2-upstream-game-code-patches)
4. [PHASE 3: CORE ENGINE SYSTEMS](#phase-3-core-engine-systems)
5. [PHASE 4: RENDERING SYSTEMS](#phase-4-rendering-systems)
6. [PHASE 5: AUDIO SYSTEMS](#phase-5-audio-systems)
7. [PHASE 6: GAME LOGIC SYSTEMS](#phase-6-game-logic-systems)
8. [PHASE 7: AI SYSTEMS](#phase-7-ai-systems)
9. [PHASE 8: NETWORKING & MULTIPLAYER](#phase-8-networking--multiplayer)
10. [PHASE 9: UI & SHELL SYSTEMS](#phase-9-ui--shell-systems)
11. [PHASE 10: CAMPAIGN & MISSIONS](#phase-10-campaign--missions)
12. [PHASE 11: GAME CONTENT & DATA](#phase-11-game-content--data)
13. [PHASE 12: ASSETS & RESOURCES](#phase-12-assets--resources)
14. [PHASE 13: PLATFORM INTEGRATION](#phase-13-platform-integration)
15. [PHASE 14: TESTING & QA](#phase-14-testing--qa)
16. [PHASE 15: TOOLS & EDITORS](#phase-15-tools--editors)
17. [PHASE 16: DOCUMENTATION](#phase-16-documentation)

---

## PHASE 0: HOME LANGUAGE IMPROVEMENTS

These features need to be added to the Home programming language (~/Code/home) to support game engine development.

### 0.1 Graphics API Bindings
- [ ] `H0-001` Create Metal API bindings (`packages/graphics/metal.home`)
- [ ] `H0-002` Create Vulkan API bindings (`packages/graphics/vulkan.home`)
- [ ] `H0-003` Create OpenGL API bindings (`packages/graphics/opengl.home`)
- [ ] `H0-004` Implement shader compilation support (SPIR-V, Metal Shading Language)
- [ ] `H0-005` Add render target/framebuffer abstractions

### 0.2 Window & Input System
- [ ] `H0-010` Create window management module (`packages/window/window.home`)
- [ ] `H0-011` Add GLFW FFI bindings for cross-platform windowing
- [ ] `H0-012` Add SDL2 FFI bindings as alternative
- [ ] `H0-013` Implement keyboard input event system
- [ ] `H0-014` Implement mouse input with cursor management
- [ ] `H0-015` Implement gamepad/controller input support
- [ ] `H0-016` Add input remapping and hotkey system

### 0.3 Game Math Library
- [ ] `H0-020` Create `packages/math/vector2.home` - 2D vector with SIMD
- [ ] `H0-021` Create `packages/math/vector3.home` - 3D vector with SIMD
- [ ] `H0-022` Create `packages/math/vector4.home` - 4D vector with SIMD
- [ ] `H0-023` Create `packages/math/matrix4.home` - 4x4 matrix with SIMD
- [ ] `H0-024` Create `packages/math/quaternion.home` - Quaternion rotations
- [ ] `H0-025` Create `packages/math/frustum.home` - View frustum culling
- [ ] `H0-026` Create `packages/math/aabb.home` - Axis-aligned bounding boxes
- [ ] `H0-027` Create `packages/math/ray.home` - Ray casting utilities
- [ ] `H0-028` Create `packages/math/plane.home` - Plane mathematics
- [ ] `H0-029` Create `packages/math/transform.home` - Transform hierarchy

### 0.4 Memory Management
- [ ] `H0-030` Implement arena allocator (`packages/memory/arena.home`)
- [ ] `H0-031` Implement pool allocator (`packages/memory/pool.home`)
- [ ] `H0-032` Implement stack allocator (`packages/memory/stack.home`)
- [ ] `H0-033` Implement free-list allocator (`packages/memory/freelist.home`)
- [ ] `H0-034` Add memory profiling and leak detection
- [ ] `H0-035` Implement string interning/pooling

### 0.5 File System Improvements
- [ ] `H0-040` Complete directory listing API
- [ ] `H0-041` Add file watching/notification support
- [ ] `H0-042` Add memory-mapped file support
- [ ] `H0-043` Implement async file I/O
- [ ] `H0-044` Add file permissions/attributes API

### 0.6 Operator Overloading
- [ ] `H0-050` Add operator overloading syntax for math types (`+`, `-`, `*`, `/`)
- [ ] `H0-051` Support comparison operator overloading (`==`, `!=`, `<`, `>`)
- [ ] `H0-052` Support index operator overloading (`[]`)
- [ ] `H0-053` Support compound assignment operators (`+=`, `-=`, etc.)

### 0.7 Additional Language Features
- [ ] `H0-060` Add bitfield struct support for memory layouts
- [ ] `H0-061` Add packed struct attributes
- [ ] `H0-062` Improve variadic function FFI support
- [ ] `H0-063` Add union types for C interop
- [ ] `H0-064` Add alignment specification for structs

---

## PHASE 1: COMPILER & TYPE SYSTEM FIXES

### 1.1 Memory Management Bugs
- [x] `C1-001` Fix double-free bug in for-loop iterator handling
- [x] `C1-002` Fix stack offset integer overflow protection
- [ ] `C1-003` Fix memory leak in type checker (shown in error output)

### 1.2 Parser Fixes
- [x] `C1-010` Fix `if !optional` syntax in struct context
- [x] `C1-011` Fix module resolution during type checking
- [x] `C1-012` Support pattern matching on MemberExpr
- [x] `C1-013` Implement ArrayRepeat expression `[value; count]`

### 1.3 Type System Fixes
- [x] `C1-020` Fix `module::Type` resolution in type annotations
- [x] `C1-021` Implement `Vec<T>` generic collection type
- [x] `C1-022` Support complex generic instantiations
- [x] `C1-023` Add string method type inference
- [x] `C1-024` Fix optional type conditionals
- [x] `C1-025` Implement optional chaining operators (`?.`, `??`)
- [x] `C1-026` Support `mut T` mutable parameter syntax
- [x] `C1-027` Add Zig stdlib type imports

### 1.4 Codegen Improvements
- [x] `C1-030` Support tuple destructuring assignments
- [x] `C1-031` Implement RangeExpr as standalone value
- [x] `C1-032` Fix struct field resolution
- [x] `C1-033` Implement enum variant data access
- [x] `C1-034` Fix Vec<T> constructor syntax

### 1.5 Advanced Features
- [x] `C1-040` Match on enum variants with data
- [x] `C1-041` Match on nested structures
- [ ] `C1-042` Match guards (`match val { x if x > 10 => ... }`)
- [x] `C1-043` Infer generic type parameters
- [x] `C1-044` Infer lambda/closure types
- [ ] `C1-045` Define and implement traits
- [ ] `C1-046` Trait bounds on generics

---

## PHASE 2: UPSTREAM GAME CODE PATCHES

Patches from the original GeneralsGameCode repository that must be implemented.

### 2.1 Recent Bugfixes (Latest 20 Commits)
- [ ] `U2-001` Fix Campaign/Challenge/Score movie cancellation artifacts when tabbing out (#1927)
- [ ] `U2-002` Fix wrong INIZH.big loading from Data/INI directory preventing INI CRC mismatch (#1879)
- [ ] `U2-003` Fix disabled Power Plant destruction lowering energy production twice (#1857)
- [ ] `U2-004` Fix hero radar objects causing cache update issues (#1893)
- [ ] `U2-005` Fix weapon effects not showing for hidden non-stealthed objects (#1918)
- [ ] `U2-006` Fix projectile being jammed multiple times (#1907)

### 2.2 Refactors to Match Original
- [ ] `U2-010` Implement generic startsWith/endsWith functions for strings (#1898)
- [ ] `U2-011` Implement observed player behaviour handling (#1861)
- [ ] `U2-012` Update Radar::addObject to match simplified original (#1893)
- [ ] `U2-013` Update Radar::deleteListResources to match original (#1893)
- [ ] `U2-014` Update W3DRadar::renderObjectList to match original (#1893)

### 2.3 New Features
- [ ] `U2-020` Add Money Per Minute configuration to GameData.ini (#1914)

### 2.4 Code Unification (Match Original Structure)
- [ ] `U2-030` Unify View and W3DView into Core module (#1904)
- [ ] `U2-031` Move ParabolicEase to Core (#1904)
- [ ] `U2-032` Move CameraShakeSystem to Core (#1904)
- [ ] `U2-033` Move W3DShaderManager to Core (#1920)
- [ ] `U2-034` Merge Smudge/W3DSmudge code into Core (#1920)
- [ ] `U2-035` Move ObjectStatusTypes to Core (#1894)
- [ ] `U2-036` Unify Radar code into single module (#1894)

---

## PHASE 3: CORE ENGINE SYSTEMS

### 3.1 Entity Component System
- [ ] `E3-001` Implement Entity ID with generation counter
- [ ] `E3-002` Implement Component storage (sparse sets)
- [ ] `E3-003` Implement System dispatcher
- [ ] `E3-004` Add component iteration queries
- [ ] `E3-005` Implement entity hierarchy (parent/child)
- [ ] `E3-006` Add component lifecycle hooks (onCreate, onDestroy)

### 3.2 Game Loop
- [ ] `E3-010` Implement fixed timestep game loop (30 Hz like original)
- [ ] `E3-011` Implement frame accumulator for variable framerate
- [ ] `E3-012` Add update order management (Production → Spawning → Objects → AI → State)
- [ ] `E3-013` Implement pause/resume functionality
- [ ] `E3-014` Add slow-motion/time multiplier support

### 3.3 Memory Management
- [ ] `E3-020` Implement 3-tier memory pooling (fast/medium/slow)
- [ ] `E3-021` Implement memory leak detection
- [ ] `E3-022` Implement string pooling/interning
- [ ] `E3-023` Implement object pooling for game entities
- [ ] `E3-024` Add memory profiler integration

### 3.4 File System & Archives
- [ ] `E3-030` Complete BIG archive format reader (BIGF/BIG4 magic)
- [ ] `E3-031` Implement archive priority layering
- [ ] `E3-032` Implement directory normalization
- [ ] `E3-033` Add RefPack decompression support
- [ ] `E3-034` Implement virtual file system abstraction
- [ ] `E3-035` Add async asset loading

### 3.5 Thing/Object System
- [ ] `E3-040` Implement Thing base class
- [ ] `E3-041` Implement ThingTemplate (object prototypes)
- [ ] `E3-042` Implement ThingFactory (object creation)
- [ ] `E3-043` Implement Module base class
- [ ] `E3-044` Implement ModuleFactory (module instantiation)
- [ ] `E3-045` Add object lifecycle management

### 3.6 Timing & Performance
- [ ] `E3-050` Implement high-resolution timer
- [ ] `E3-051` Implement frame limiter
- [ ] `E3-052` Add frame metrics collection
- [ ] `E3-053` Implement profiler with flame graph support
- [ ] `E3-054` Add performance counters

### 3.7 State Machine
- [ ] `E3-060` Implement generic state machine
- [ ] `E3-061` Add transition conditions
- [ ] `E3-062` Add state enter/exit hooks
- [ ] `E3-063` Support hierarchical state machines

---

## PHASE 4: RENDERING SYSTEMS

### 4.1 Core Renderer
- [ ] `R4-001` Implement renderer abstraction layer
- [ ] `R4-002` Implement Metal renderer backend (macOS)
- [ ] `R4-003` Implement Vulkan renderer backend
- [ ] `R4-004` Implement render command buffer system
- [ ] `R4-005` Implement render queue with sorting
- [ ] `R4-006` Add multi-threaded rendering support

### 4.2 W3D Model System
- [ ] `R4-010` Implement W3D chunk parser (all 16 chunk types)
- [ ] `R4-011` Parse mesh chunks (vertices, normals, triangles, UVs)
- [ ] `R4-012` Parse hierarchy chunks (pivots, bone structure)
- [ ] `R4-013` Parse animation chunks (skeletal, channels)
- [ ] `R4-014` Parse compressed animation
- [ ] `R4-015` Parse HModel and LODModel
- [ ] `R4-016` Parse particle emitters embedded in models
- [ ] `R4-017` Implement material system (single/multi-pass)
- [ ] `R4-018` Implement texture stage mapping
- [ ] `R4-019` Support pre-lit lighting (vertex, lightmap)
- [ ] `R4-020` Implement morphing animations

### 4.3 Skeletal Animation
- [ ] `R4-030` Implement bone hierarchy system
- [ ] `R4-031` Implement animation player
- [ ] `R4-032` Implement animation blending
- [ ] `R4-033` Implement animation events (sound triggers, etc.)
- [ ] `R4-034` Support multiple animations per model

### 4.4 Terrain System
- [ ] `R4-040` Implement heightmap loading
- [ ] `R4-041` Implement terrain chunk rendering
- [ ] `R4-042` Implement terrain texture blending (4 layers)
- [ ] `R4-043` Implement terrain roads
- [ ] `R4-044` Implement cliff rendering
- [ ] `R4-045` Implement water rendering (reflection, refraction)
- [ ] `R4-046` Implement terrain tracks (unit footprints)

### 4.5 Shader System
- [ ] `R4-050` Implement W3DShaderManager equivalent
- [ ] `R4-051` Implement all 16 shader types (terrain, road, shroud, cloud, etc.)
- [ ] `R4-052` Implement multi-pass rendering
- [ ] `R4-053` Implement shader hot-reloading for development
- [ ] `R4-054` Add GPU feature detection

### 4.6 View/Camera System
- [ ] `R4-060` Implement W3DView camera system
- [ ] `R4-061` Implement RTS camera controls (pan, zoom, rotate)
- [ ] `R4-062` Implement camera constraints (bounds checking)
- [ ] `R4-063` Implement ParabolicEase for smooth camera transitions
- [ ] `R4-064` Implement camera shake system (CameraShakeSystem)
- [ ] `R4-065` Implement waypoint path camera movement
- [ ] `R4-066` Implement screen-to-world transformations
- [ ] `R4-067` Implement pick ray generation for object selection
- [ ] `R4-068` Implement frustum culling

### 4.7 Post-Processing
- [ ] `R4-070` Implement render-to-texture support
- [ ] `R4-071` Implement ScreenMotionBlurFilter
- [ ] `R4-072` Implement ScreenBWFilter (black & white)
- [ ] `R4-073` Implement ScreenCrossFadeFilter
- [ ] `R4-074` Implement bloom effect
- [ ] `R4-075` Implement color grading

### 4.8 Particle System
- [ ] `R4-080` Implement particle emitter system
- [ ] `R4-081` Implement particle renderer (GPU instancing)
- [ ] `R4-082` Support all particle types (smoke, fire, debris, etc.)
- [ ] `R4-083` Implement particle collision
- [ ] `R4-084` Implement particle trails

### 4.9 Effects & Decals
- [ ] `R4-090` Implement Smudge/decal system
- [ ] `R4-091` Implement scorch marks
- [ ] `R4-092` Implement explosion effects
- [ ] `R4-093` Implement weapon trails
- [ ] `R4-094` Implement muzzle flashes
- [ ] `R4-095` Implement laser/beam rendering

### 4.10 Shadow System
- [ ] `R4-100` Implement shadow mapping
- [ ] `R4-101` Implement projected shadows
- [ ] `R4-102` Implement volumetric shadows
- [ ] `R4-103` Implement shadow quality levels

### 4.11 LOD System
- [ ] `R4-110` Implement level-of-detail switching
- [ ] `R4-111` Implement distance-based LOD
- [ ] `R4-112` Implement screen-size based LOD
- [ ] `R4-113` Implement LOD transitions (no popping)

### 4.12 Radar/Minimap
- [ ] `R4-120` Implement W3DRadar terrain texture generation
- [ ] `R4-121` Implement radar overlay rendering
- [ ] `R4-122` Implement shroud texture on radar
- [ ] `R4-123` Implement unit icon rendering on radar
- [ ] `R4-124` Implement event beacon rendering
- [ ] `R4-125` Implement hero icon display
- [ ] `R4-126` Implement view box tracking

---

## PHASE 5: AUDIO SYSTEMS

### 5.1 Audio Engine
- [ ] `A5-001` Implement 32-channel audio mixer
- [ ] `A5-002` Implement audio format loading (WAV, MP3, OGG)
- [ ] `A5-003` Implement 3D positional audio
- [ ] `A5-004` Implement audio attenuation (distance falloff)
- [ ] `A5-005` Implement audio ducking
- [ ] `A5-006` Implement audio streaming for large files

### 5.2 Music System
- [ ] `A5-010` Implement dynamic music system
- [ ] `A5-011` Implement mood-based music selection (normal, intense, victory, defeat)
- [ ] `A5-012` Implement music crossfading
- [ ] `A5-013` Match original music trigger conditions

### 5.3 Sound Effects
- [ ] `A5-020` Implement sound effect playback
- [ ] `A5-021` Implement weapon sounds
- [ ] `A5-022` Implement explosion sounds
- [ ] `A5-023` Implement ambient sounds
- [ ] `A5-024` Implement UI sounds

### 5.4 Voice System
- [ ] `A5-030` Implement EVA voice announcement system
- [ ] `A5-031` Implement priority-based voice queue
- [ ] `A5-032` Implement unit voice responses (selection, movement, attack)
- [ ] `A5-033` Implement faction-specific unit voices
- [ ] `A5-034` Implement General taunts

### 5.5 Audio Events
- [ ] `A5-040` Implement event-driven audio triggers
- [ ] `A5-041` Parse audio event definitions from INI
- [ ] `A5-042` Implement audio cues for game events

---

## PHASE 6: GAME LOGIC SYSTEMS

### 6.1 Unit System
- [ ] `G6-001` Implement unit spawning
- [ ] `G6-002` Implement unit state machine (Idle, Moving, Attacking, etc.)
- [ ] `G6-003` Implement unit categories (Infantry, Vehicle, Aircraft, Structure, Hero)
- [ ] `G6-004` Implement health/armor system
- [ ] `G6-005` Implement movement speed and turn rate
- [ ] `G6-006` Implement vision/detection ranges
- [ ] `G6-007` Implement garrison and transport slots
- [ ] `G6-008` Implement weapon slots (primary/secondary)

### 6.2 Building System
- [ ] `G6-010` Implement building placement
- [ ] `G6-011` Implement building construction animation
- [ ] `G6-012` Implement building states (Idle, Constructing, Damaged, Producing, Selling)
- [ ] `G6-013` Implement power production/consumption
- [ ] `G6-014` Implement production queues
- [ ] `G6-015` Implement rally points

### 6.3 Combat System
- [ ] `G6-020` Implement all 13+ damage types
- [ ] `G6-021` Implement all 11 armor types
- [ ] `G6-022` Implement damage type vs armor modifier matrix
- [ ] `G6-023` Implement weapon firing mechanics
- [ ] `G6-024` Implement projectile physics
- [ ] `G6-025` Implement homing projectiles
- [ ] `G6-026` Implement area-of-effect damage
- [ ] `G6-027` Implement critical hits

### 6.4 Economy System
- [ ] `G6-030` Implement resource (money) tracking
- [ ] `G6-031` Implement supply center gathering
- [ ] `G6-032` Implement harvester AI
- [ ] `G6-033` Implement bounty system (unit kills)
- [ ] `G6-034` Implement power bar system
- [ ] `G6-035` Implement blackout mechanics

### 6.5 Veterancy System
- [ ] `G6-040` Implement experience accumulation
- [ ] `G6-041` Implement level progression (1-3 stars)
- [ ] `G6-042` Implement stat bonuses per level
- [ ] `G6-043` Implement heal at high veterancy

### 6.6 Upgrade System
- [ ] `G6-050` Implement upgrade templates
- [ ] `G6-051` Implement upgrade prerequisites
- [ ] `G6-052` Implement upgrade effects on units
- [ ] `G6-053` Implement all upgrade module types (20+)

### 6.7 Special Powers
- [ ] `G6-060` Implement all 69 special powers
- [ ] `G6-061` Implement cooldown management
- [ ] `G6-062` Implement cost requirements
- [ ] `G6-063` Implement targeting mechanics
- [ ] `G6-064` Implement all special power module types (9+)

### 6.8 Tech Tree
- [ ] `G6-070` Implement science/tech tree
- [ ] `G6-071` Implement prerequisites checking
- [ ] `G6-072` Implement General's powers selection

### 6.9 Module System (192 Module Types!)
- [ ] `G6-080` Implement all Update modules (84 types)
- [ ] `G6-081` Implement all Behavior modules (29 types)
- [ ] `G6-082` Implement all Contain modules (15 types)
- [ ] `G6-083` Implement all Die modules (12 types)
- [ ] `G6-084` Implement all Collide modules (15+ types including crates)
- [ ] `G6-085` Implement all Body modules (7 types)
- [ ] `G6-086` Implement all Create modules (7 types)
- [ ] `G6-087` Implement all Damage modules (5 types)
- [ ] `G6-088` Implement all Destroy modules

### 6.10 Crate System
- [ ] `G6-090` Implement crate spawning
- [ ] `G6-091` Implement all crate types (veterancy, salvage, sabotage, etc.)
- [ ] `G6-092` Implement crate pickup mechanics

### 6.11 Fog of War
- [ ] `G6-100` Implement vision radius per unit
- [ ] `G6-101` Implement shroud management
- [ ] `G6-102` Implement enemy detection
- [ ] `G6-103` Implement stealth unit mechanics
- [ ] `G6-104` Implement stealth detection

### 6.12 Player/Team System
- [ ] `G6-110` Implement player state management
- [ ] `G6-111` Implement team/alliance system
- [ ] `G6-112` Implement player templates (faction selection)
- [ ] `G6-113` Implement shared vision for allies

---

## PHASE 7: AI SYSTEMS

### 7.1 Pathfinding
- [ ] `AI7-001` Implement A* pathfinding algorithm
- [ ] `AI7-002` Implement navigation mesh
- [ ] `AI7-003` Implement HPA* (Hierarchical Pathfinding)
- [ ] `AI7-004` Implement all locomotor types (Ground, Air, Hover, Tank, etc.)
- [ ] `AI7-005` Implement dynamic obstacle avoidance
- [ ] `AI7-006` Implement partial path finding
- [ ] `AI7-007` Support 65,536 path nodes, 256 waypoints

### 7.2 Flow Field System
- [ ] `AI7-010` Implement flow field generation
- [ ] `AI7-011` Implement group movement optimization
- [ ] `AI7-012` Implement crowd avoidance

### 7.3 Formation System
- [ ] `AI7-020` Implement unit group formations (V-shape, line, column)
- [ ] `AI7-021` Implement formation movement
- [ ] `AI7-022` Implement formation rotation
- [ ] `AI7-023` Implement tight/loose formation modes
- [ ] `AI7-024` Implement formation breaking on combat

### 7.4 Behavior Tree
- [ ] `AI7-030` Implement behavior tree system
- [ ] `AI7-031` Implement selector nodes
- [ ] `AI7-032` Implement sequence nodes
- [ ] `AI7-033` Implement condition nodes
- [ ] `AI7-034` Implement action nodes

### 7.5 AI Brain
- [ ] `AI7-040` Implement per-player AI controller
- [ ] `AI7-041` Implement decision making system
- [ ] `AI7-042` Implement resource management AI
- [ ] `AI7-043` Implement threat assessment
- [ ] `AI7-044` Implement target prioritization

### 7.6 AI States
- [ ] `AI7-050` Implement strategic states (attack, defend, expand)
- [ ] `AI7-051` Implement unit-specific states (hunt, patrol, guard)
- [ ] `AI7-052` Implement state transition logic

### 7.7 AI Strategies
- [ ] `AI7-060` Implement rush strategies
- [ ] `AI7-061` Implement tech rush strategies
- [ ] `AI7-062` Implement army composition strategies
- [ ] `AI7-063` Implement economic strategies
- [ ] `AI7-064` Implement adaptability to player actions

### 7.8 Skirmish AI
- [ ] `AI7-070` Implement AISkirmishPlayer
- [ ] `AI7-071` Implement difficulty levels (Easy, Medium, Hard, Brutal)
- [ ] `AI7-072` Implement AI personalities
- [ ] `AI7-073` Implement aggression levels

### 7.9 Unit Behaviors
- [ ] `AI7-080` Implement auto-heal behavior
- [ ] `AI7-081` Implement assisted targeting
- [ ] `AI7-082` Implement auto-deposit (harvester return)
- [ ] `AI7-083` Implement overcharge behavior
- [ ] `AI7-084` Implement spawn behavior
- [ ] `AI7-085` Implement mob member slaved update

---

## PHASE 8: NETWORKING & MULTIPLAYER

### 8.1 Lockstep Networking
- [ ] `N8-001` Implement deterministic simulation
- [ ] `N8-002` Implement command-based synchronization
- [ ] `N8-003` Implement frame buffering for lag hiding
- [ ] `N8-004` Implement deterministic RNG seeding
- [ ] `N8-005` Support 1-8 players per game

### 8.2 Network Foundation
- [ ] `N8-010` Implement UDP transport layer
- [ ] `N8-011` Implement packet fragmentation and reassembly
- [ ] `N8-012` Implement connection management
- [ ] `N8-013` Implement drop detection and reconnection

### 8.3 Lobby System
- [ ] `N8-020` Implement game hosting
- [ ] `N8-021` Implement game joining
- [ ] `N8-022` Implement player ready states
- [ ] `N8-023` Implement map selection
- [ ] `N8-024` Implement difficulty settings
- [ ] `N8-025` Implement team assignment
- [ ] `N8-026` Implement game start coordination

### 8.4 Replay System
- [ ] `N8-030` Implement command recording
- [ ] `N8-031` Implement timestamp tracking
- [ ] `N8-032` Implement playback with UI controls
- [ ] `N8-033` Implement replay scrubbing

### 8.5 GameSpy Integration
- [ ] `N8-040` Implement online lobbies
- [ ] `N8-041` Implement chat system
- [ ] `N8-042` Implement matchmaking
- [ ] `N8-043` Implement peer-to-peer connections

### 8.6 File Transfer
- [ ] `N8-050` Implement map transfer to clients
- [ ] `N8-051` Implement mod/patch distribution
- [ ] `N8-052` Implement progress tracking

### 8.7 CRC Validation
- [ ] `N8-060` Implement game state CRC
- [ ] `N8-061` Implement desync detection
- [ ] `N8-062` Implement INI CRC validation

---

## PHASE 9: UI & SHELL SYSTEMS

### 9.1 UI Framework
- [ ] `UI9-001` Implement hierarchical window system
- [ ] `UI9-002` Implement GameWindow base class
- [ ] `UI9-003` Implement Panel container
- [ ] `UI9-004` Implement Button widget
- [ ] `UI9-005` Implement Label widget
- [ ] `UI9-006` Implement Slider widget
- [ ] `UI9-007` Implement TextBox widget
- [ ] `UI9-008` Implement Checkbox widget
- [ ] `UI9-009` Implement ListBox widget
- [ ] `UI9-010` Implement ComboBox widget
- [ ] `UI9-011` Implement ProgressBar widget
- [ ] `UI9-012` Implement TabControl widget

### 9.2 WND Format Parser
- [ ] `UI9-020` Implement WND file parser
- [ ] `UI9-021` Parse static text elements
- [ ] `UI9-022` Parse buttons
- [ ] `UI9-023` Parse listboxes
- [ ] `UI9-024` Parse sliders
- [ ] `UI9-025` Parse input fields
- [ ] `UI9-026` Support absolute positioning with relative sizing
- [ ] `UI9-027` Support multiple UI themes

### 9.3 Control Bar
- [ ] `UI9-030` Implement 180-pixel height bar at bottom
- [ ] `UI9-031` Implement 3x5 command button grid
- [ ] `UI9-032` Implement money display
- [ ] `UI9-033` Implement power display
- [ ] `UI9-034` Implement supply display
- [ ] `UI9-035` Implement context-sensitive commands
- [ ] `UI9-036` Implement hotkey display

### 9.4 In-Game HUD
- [ ] `UI9-040` Implement selection info display
- [ ] `UI9-041` Implement build progress indicators
- [ ] `UI9-042` Implement objectives marker
- [ ] `UI9-043` Implement damage indicators
- [ ] `UI9-044` Implement veterancy stars display

### 9.5 Minimap
- [ ] `UI9-050` Implement tactical overview
- [ ] `UI9-051` Implement unit positions display
- [ ] `UI9-052` Implement shroud/fog visualization
- [ ] `UI9-053` Implement viewport rectangle indicator
- [ ] `UI9-054` Implement minimap clicking for camera

### 9.6 Main Menu
- [ ] `UI9-060` Implement campaign selection (USA, China, GLA)
- [ ] `UI9-061` Implement Generals Challenge mode selection
- [ ] `UI9-062` Implement skirmish setup
- [ ] `UI9-063` Implement multiplayer lobby
- [ ] `UI9-064` Implement options/settings

### 9.7 Skirmish Screen
- [ ] `UI9-070` Implement map selection with preview
- [ ] `UI9-071` Implement player setup (human/AI)
- [ ] `UI9-072` Implement faction selection
- [ ] `UI9-073` Implement difficulty selection
- [ ] `UI9-074` Implement team assignment

### 9.8 Options Screen
- [ ] `UI9-080` Implement graphics settings
- [ ] `UI9-081` Implement audio settings
- [ ] `UI9-082` Implement gameplay options
- [ ] `UI9-083` Implement control remapping

### 9.9 Additional Screens
- [ ] `UI9-090` Implement loading screen with progress bar
- [ ] `UI9-091` Implement credits screen
- [ ] `UI9-092` Implement score screen (victory/defeat)
- [ ] `UI9-093` Implement diplomacy screen
- [ ] `UI9-094` Implement in-game chat

### 9.10 GUI Callbacks
- [ ] `UI9-100` Implement all GUICallbacks (91 files in original)
- [ ] `UI9-101` Implement menu event handlers
- [ ] `UI9-102` Implement shell system

---

## PHASE 10: CAMPAIGN & MISSIONS

### 10.1 Campaign System
- [ ] `M10-001` Implement campaign manager
- [ ] `M10-002` Implement campaign progression tracking
- [ ] `M10-003` Implement mission unlocking
- [ ] `M10-004` Implement difficulty selection

### 10.2 Mission System
- [ ] `M10-010` Implement mission loading
- [ ] `M10-011` Implement primary objectives
- [ ] `M10-012` Implement secondary objectives
- [ ] `M10-013` Implement hidden objectives
- [ ] `M10-014` Implement time limits
- [ ] `M10-015` Implement victory conditions
- [ ] `M10-016` Implement defeat conditions

### 10.3 Script Engine
- [ ] `M10-020` Implement script parser
- [ ] `M10-021` Implement all script conditions (100+)
- [ ] `M10-022` Implement all script actions (100+)
- [ ] `M10-023` Implement counters/flags system (256 total)
- [ ] `M10-024` Implement event triggers

### 10.4 Generals Challenge
- [ ] `M10-030` Implement challenge mode progression
- [ ] `M10-031` Implement all general opponents
- [ ] `M10-032` Implement general-specific AI behaviors
- [ ] `M10-033` Implement challenge rewards

### 10.5 Briefings
- [ ] `M10-040` Implement briefing screens
- [ ] `M10-041` Implement mission intro videos
- [ ] `M10-042` Implement mission outro videos

### 10.6 Cinematics
- [ ] `M10-050` Implement in-game cinematic system
- [ ] `M10-051` Implement camera scripting
- [ ] `M10-052` Implement unit scripting
- [ ] `M10-053` Implement dialogue system

---

## PHASE 11: GAME CONTENT & DATA

### 11.1 INI Parsing
- [ ] `D11-001` Implement complete INI parser
- [ ] `D11-002` Parse Object definitions (units, buildings)
- [ ] `D11-003` Parse Weapon definitions
- [ ] `D11-004` Parse Upgrade definitions
- [ ] `D11-005` Parse Science definitions
- [ ] `D11-006` Parse CommandButton definitions
- [ ] `D11-007` Parse FXList definitions
- [ ] `D11-008` Parse GameData.ini
- [ ] `D11-009` Parse PlayerTemplate definitions
- [ ] `D11-010` Parse ControlBarScheme definitions

### 11.2 USA Faction Units
- [ ] `D11-020` Implement Ranger
- [ ] `D11-021` Implement Missile Defender
- [ ] `D11-022` Implement Pathfinder
- [ ] `D11-023` Implement Colonel Burton
- [ ] `D11-024` Implement Pilot
- [ ] `D11-025` Implement Humvee
- [ ] `D11-026` Implement Crusader Tank
- [ ] `D11-027` Implement Paladin Tank
- [ ] `D11-028` Implement Tomahawk Launcher
- [ ] `D11-029` Implement Comanche
- [ ] `D11-030` Implement Chinook
- [ ] `D11-031` Implement Raptor
- [ ] `D11-032` Implement Stealth Fighter
- [ ] `D11-033` Implement Aurora Bomber
- [ ] `D11-034` Implement B-52 Stratofortress

### 11.3 China Faction Units
- [ ] `D11-040` Implement Red Guard
- [ ] `D11-041` Implement Tank Hunter
- [ ] `D11-042` Implement Hacker
- [ ] `D11-043` Implement Black Lotus
- [ ] `D11-044` Implement Battlemaster Tank
- [ ] `D11-045` Implement Dragon Tank
- [ ] `D11-046` Implement Overlord Tank
- [ ] `D11-047` Implement Inferno Cannon
- [ ] `D11-048` Implement Nuke Cannon
- [ ] `D11-049` Implement MiG
- [ ] `D11-050` Implement Helix

### 11.4 GLA Faction Units
- [ ] `D11-060` Implement Rebel
- [ ] `D11-061` Implement RPG Trooper
- [ ] `D11-062` Implement Terrorist
- [ ] `D11-063` Implement Hijacker
- [ ] `D11-064` Implement Jarmen Kell
- [ ] `D11-065` Implement Technical
- [ ] `D11-066` Implement Scorpion Tank
- [ ] `D11-067` Implement Marauder Tank
- [ ] `D11-068` Implement Quad Cannon
- [ ] `D11-069` Implement Rocket Buggy
- [ ] `D11-070` Implement Scud Launcher
- [ ] `D11-071` Implement Bomb Truck

### 11.5 USA Faction Buildings
- [ ] `D11-080` Implement Command Center (USA)
- [ ] `D11-081` Implement Power Plant (USA)
- [ ] `D11-082` Implement Barracks (USA)
- [ ] `D11-083` Implement War Factory (USA)
- [ ] `D11-084` Implement Airfield (USA)
- [ ] `D11-085` Implement Supply Center (USA)
- [ ] `D11-086` Implement Strategy Center
- [ ] `D11-087` Implement Particle Cannon
- [ ] `D11-088` Implement Patriot Missile System
- [ ] `D11-089` Implement Firebase

### 11.6 China Faction Buildings
- [ ] `D11-090` Implement Command Center (China)
- [ ] `D11-091` Implement Nuclear Reactor
- [ ] `D11-092` Implement Barracks (China)
- [ ] `D11-093` Implement War Factory (China)
- [ ] `D11-094` Implement Airfield (China)
- [ ] `D11-095` Implement Supply Center (China)
- [ ] `D11-096` Implement Propaganda Center
- [ ] `D11-097` Implement Nuclear Missile
- [ ] `D11-098` Implement Gattling Cannon
- [ ] `D11-099` Implement Bunker

### 11.7 GLA Faction Buildings
- [ ] `D11-100` Implement Command Center (GLA)
- [ ] `D11-101` Implement Supply Stash
- [ ] `D11-102` Implement Barracks (GLA)
- [ ] `D11-103` Implement Arms Dealer
- [ ] `D11-104` Implement Black Market
- [ ] `D11-105` Implement Palace
- [ ] `D11-106` Implement Scud Storm
- [ ] `D11-107` Implement Stinger Site
- [ ] `D11-108` Implement Tunnel Network
- [ ] `D11-109` Implement Demo Trap

### 11.8 Zero Hour Generals
- [ ] `D11-110` Implement USA Air Force General units/abilities
- [ ] `D11-111` Implement USA Laser General units/abilities
- [ ] `D11-112` Implement USA Super Weapon General units/abilities
- [ ] `D11-113` Implement China Tank General units/abilities
- [ ] `D11-114` Implement China Infantry General units/abilities
- [ ] `D11-115` Implement China Nuke General units/abilities
- [ ] `D11-116` Implement GLA Toxin General units/abilities
- [ ] `D11-117` Implement GLA Stealth General units/abilities
- [ ] `D11-118` Implement GLA Demo General units/abilities

### 11.9 Weapons
- [ ] `D11-120` Implement all weapon templates
- [ ] `D11-121` Implement weapon damage values
- [ ] `D11-122` Implement weapon ranges
- [ ] `D11-123` Implement weapon fire rates
- [ ] `D11-124` Implement weapon special effects

### 11.10 Maps
- [ ] `D11-130` Implement map format loading
- [ ] `D11-131` Load all original campaign maps
- [ ] `D11-132` Load all multiplayer/skirmish maps
- [ ] `D11-133` Load all Generals Challenge maps

---

## PHASE 12: ASSETS & RESOURCES

### 12.1 Unit Models (W3D)
- [ ] `A12-001` Load all USA unit models
- [ ] `A12-002` Load all China unit models
- [ ] `A12-003` Load all GLA unit models
- [ ] `A12-004` Load all LOD variants
- [ ] `A12-005` Load all damage state variants

### 12.2 Building Models (W3D)
- [ ] `A12-010` Load all USA building models
- [ ] `A12-011` Load all China building models
- [ ] `A12-012` Load all GLA building models
- [ ] `A12-013` Load construction animation states
- [ ] `A12-014` Load damage animation states

### 12.3 Terrain Textures
- [ ] `A12-020` Load grass textures
- [ ] `A12-021` Load sand textures
- [ ] `A12-022` Load dirt textures
- [ ] `A12-023` Load rock textures
- [ ] `A12-024` Load water textures
- [ ] `A12-025` Load normal maps
- [ ] `A12-026` Load specular maps

### 12.4 UI Assets
- [ ] `A12-030` Load button textures
- [ ] `A12-031` Load border textures
- [ ] `A12-032` Load icon textures
- [ ] `A12-033` Load faction-specific UI elements
- [ ] `A12-034` Load minimap icons
- [ ] `A12-035` Load cursor images

### 12.5 Effect Assets
- [ ] `A12-040` Load particle textures
- [ ] `A12-041` Load explosion textures
- [ ] `A12-042` Load smoke textures
- [ ] `A12-043` Load fire textures
- [ ] `A12-044` Load weapon trail textures
- [ ] `A12-045` Load muzzle flash textures

### 12.6 Audio Assets
- [ ] `A12-050` Load weapon sounds
- [ ] `A12-051` Load explosion sounds
- [ ] `A12-052` Load ambient sounds
- [ ] `A12-053` Load UI sounds
- [ ] `A12-054` Load music tracks
- [ ] `A12-055` Load EVA voice files
- [ ] `A12-056` Load unit voice files

### 12.7 Video Assets
- [ ] `A12-060` Load menu videos
- [ ] `A12-061` Load campaign briefing videos
- [ ] `A12-062` Load victory/defeat videos

---

## PHASE 13: PLATFORM INTEGRATION

### 13.1 macOS Platform Layer
- [ ] `P13-001` Implement window management
- [ ] `P13-002` Implement Metal renderer bindings
- [ ] `P13-003` Implement keyboard input
- [ ] `P13-004` Implement mouse input
- [ ] `P13-005` Implement gamepad support
- [ ] `P13-006` Implement file I/O
- [ ] `P13-007` Implement timing/performance counters

### 13.2 App Bundle
- [ ] `P13-010` Configure Info.plist
- [ ] `P13-011` Create app icon (Generals.icns)
- [ ] `P13-012` Bundle frameworks
- [ ] `P13-013` Bundle assets

### 13.3 Code Signing & Distribution
- [ ] `P13-020` Configure code signing
- [ ] `P13-021` Configure notarization
- [ ] `P13-022` Create DMG installer
- [ ] `P13-023` Configure auto-update system

### 13.4 Cross-Platform (Future)
- [ ] `P13-030` Windows platform layer
- [ ] `P13-031` Linux platform layer
- [ ] `P13-032` Steam integration

---

## PHASE 14: TESTING & QA

### 14.1 Unit Tests
- [ ] `T14-001` Test math library (vectors, matrices, quaternions)
- [ ] `T14-002` Test ECS system
- [ ] `T14-003` Test pathfinding algorithms
- [ ] `T14-004` Test combat calculations
- [ ] `T14-005` Test resource management
- [ ] `T14-006` Test INI parser
- [ ] `T14-007` Test W3D loader
- [ ] `T14-008` Test BIG archive reader

### 14.2 Integration Tests
- [ ] `T14-010` Test unit movement and combat
- [ ] `T14-011` Test building construction
- [ ] `T14-012` Test resource collection
- [ ] `T14-013` Test tech tree progression
- [ ] `T14-014` Test AI behavior
- [ ] `T14-015` Test multiplayer synchronization
- [ ] `T14-016` Test save/load functionality

### 14.3 Performance Tests
- [ ] `T14-020` Benchmark rendering (target 60 FPS)
- [ ] `T14-021` Benchmark pathfinding (100+ units)
- [ ] `T14-022` Benchmark AI decision making
- [ ] `T14-023` Benchmark network sync
- [ ] `T14-024` Memory usage profiling

### 14.4 Compatibility Tests
- [ ] `T14-030` Test on macOS 12 (Monterey)
- [ ] `T14-031` Test on macOS 13 (Ventura)
- [ ] `T14-032` Test on macOS 14 (Sonoma)
- [ ] `T14-033` Test on macOS 15 (Sequoia)
- [ ] `T14-034` Test on Intel Macs
- [ ] `T14-035` Test on Apple Silicon (M1, M2, M3, M4)

### 14.5 Original Game Parity Tests
- [ ] `T14-040` Compare unit stats with original
- [ ] `T14-041` Compare weapon damage with original
- [ ] `T14-042` Compare AI behavior with original
- [ ] `T14-043` Compare economy rates with original
- [ ] `T14-044` Compare visual effects with original
- [ ] `T14-045` Compare audio with original

---

## PHASE 15: TOOLS & EDITORS

### 15.1 World Builder (Map Editor)
- [ ] `W15-001` Implement terrain sculpting tools
- [ ] `W15-002` Implement texture painting
- [ ] `W15-003` Implement object placement
- [ ] `W15-004` Implement team/player setup
- [ ] `W15-005` Implement script condition editor
- [ ] `W15-006` Implement script action editor
- [ ] `W15-007` Implement road tool
- [ ] `W15-008` Implement water tool
- [ ] `W15-009` Implement fence tool
- [ ] `W15-010` Implement bridge tool
- [ ] `W15-011` Implement map export

### 15.2 Particle Editor
- [ ] `W15-020` Implement particle preview
- [ ] `W15-021` Implement emitter editing
- [ ] `W15-022` Implement velocity editing
- [ ] `W15-023` Implement shader editing
- [ ] `W15-024` Implement particle export

### 15.3 Model Viewer
- [ ] `W15-030` Implement W3D model preview
- [ ] `W15-031` Implement animation playback
- [ ] `W15-032` Implement LOD switching
- [ ] `W15-033` Implement damage state preview

### 15.4 INI Editor
- [ ] `W15-040` Implement INI file editing
- [ ] `W15-041` Implement syntax highlighting
- [ ] `W15-042` Implement validation
- [ ] `W15-043` Implement auto-complete

### 15.5 Asset Pipeline
- [ ] `W15-050` Implement texture conversion
- [ ] `W15-051` Implement model import
- [ ] `W15-052` Implement audio conversion
- [ ] `W15-053` Implement BIG archive creation

---

## PHASE 16: DOCUMENTATION

### 16.1 User Documentation
- [ ] `DOC-001` Installation guide
- [ ] `DOC-002` Controls and gameplay guide
- [ ] `DOC-003` Troubleshooting guide
- [ ] `DOC-004` FAQ
- [ ] `DOC-005` System requirements

### 16.2 Developer Documentation
- [ ] `DOC-010` Architecture overview
- [ ] `DOC-011` Build instructions
- [ ] `DOC-012` Code style guide
- [ ] `DOC-013` API documentation
- [ ] `DOC-014` Module system documentation

### 16.3 Modding Documentation
- [ ] `DOC-020` Modding guide
- [ ] `DOC-021` INI file reference
- [ ] `DOC-022` Script command reference
- [ ] `DOC-023` Map creation guide

### 16.4 Legal Documentation
- [ ] `DOC-030` License file (GPL-3.0)
- [ ] `DOC-031` Attribution for assets
- [ ] `DOC-032` Third-party licenses

---

## SUCCESS CRITERIA

The port is considered "100% matching the original game" when:

1. [ ] All compiler errors resolved
2. [ ] All .home files compile successfully
3. [ ] Game launches and shows main menu identical to original
4. [ ] Can start a skirmish match with all 3 factions
5. [ ] All 90+ units behave correctly
6. [ ] All 40+ buildings function properly
7. [ ] All 69 special powers work correctly
8. [ ] All 192 module types implemented
9. [ ] Economy system (resource collection) matches original rates
10. [ ] Tech tree and upgrades functional
11. [ ] AI provides challenging gameplay matching original difficulty levels
12. [ ] Graphics match original quality (W3D models, terrain, effects)
13. [ ] Audio and music play correctly with original files
14. [ ] Runs at 60 FPS on modern Macs
15. [ ] All 3 campaigns completable
16. [ ] Generals Challenge mode completable
17. [ ] Multiplayer functional with original game network protocol
18. [ ] Replays playable and sync correctly
19. [ ] All maps loadable (campaign + skirmish + multiplayer)
20. [ ] No critical bugs in normal gameplay

---

## TASK STATISTICS

| Phase | Total Tasks | Priority |
|-------|-------------|----------|
| Phase 0: Home Language | 64 | CRITICAL |
| Phase 1: Compiler Fixes | 17 | HIGH |
| Phase 2: Upstream Patches | 19 | HIGH |
| Phase 3: Core Engine | 54 | CRITICAL |
| Phase 4: Rendering | 126 | CRITICAL |
| Phase 5: Audio | 42 | HIGH |
| Phase 6: Game Logic | 113 | CRITICAL |
| Phase 7: AI | 85 | HIGH |
| Phase 8: Networking | 62 | MEDIUM |
| Phase 9: UI/Shell | 102 | HIGH |
| Phase 10: Campaign | 53 | MEDIUM |
| Phase 11: Game Content | 135 | CRITICAL |
| Phase 12: Assets | 62 | HIGH |
| Phase 13: Platform | 33 | HIGH |
| Phase 14: Testing | 45 | HIGH |
| Phase 15: Tools | 53 | LOW |
| Phase 16: Documentation | 32 | LOW |
| **TOTAL** | **~1,100** | |

---

## RECOMMENDED IMPLEMENTATION ORDER

### Sprint 1: Foundation (Weeks 1-4)
1. Complete Phase 0 (Home Language Improvements) - Math, Graphics bindings
2. Complete remaining Phase 1 (Compiler Fixes)
3. Start Phase 3 (Core Engine) - ECS, Game Loop, Memory

### Sprint 2: Core Engine (Weeks 5-8)
4. Complete Phase 3 (Core Engine)
5. Start Phase 4 (Rendering) - W3D loader, Basic renderer
6. Start Phase 11 (Game Content) - INI parsing

### Sprint 3: Game Systems (Weeks 9-12)
7. Continue Phase 4 (Rendering) - Terrain, Shaders
8. Start Phase 6 (Game Logic) - Units, Buildings, Combat
9. Start Phase 5 (Audio) - Basic audio

### Sprint 4: Gameplay (Weeks 13-16)
10. Complete Phase 6 (Game Logic)
11. Start Phase 7 (AI) - Pathfinding, Basic AI
12. Start Phase 9 (UI) - Control bar, Menus

### Sprint 5: Features (Weeks 17-20)
13. Complete Phase 7 (AI)
14. Complete Phase 9 (UI)
15. Start Phase 10 (Campaign)

### Sprint 6: Content (Weeks 21-24)
16. Complete Phase 11 (Game Content) - All units, buildings
17. Complete Phase 12 (Assets)
18. Start Phase 8 (Networking)

### Sprint 7: Polish (Weeks 25-28)
19. Complete Phase 8 (Networking)
20. Complete Phase 10 (Campaign)
21. Phase 2 (Upstream Patches)

### Sprint 8: Release (Weeks 29-32)
22. Phase 13 (Platform Integration)
23. Phase 14 (Testing)
24. Phase 16 (Documentation)

---

*Last Updated: 2025-12-02*
*Total Unique Tasks: ~1,100*
*Status: Comprehensive task list created for 100% game compatibility*
