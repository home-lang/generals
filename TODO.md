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

**NOTE:** Many features already exist in Home language - marked as complete below.

### 0.1 Graphics API Bindings
- [x] `H0-001` Create Metal API bindings - EXISTS: `packages/graphics/src/metal_backend.zig` (20KB)
- [x] `H0-002` Create Vulkan API bindings - EXISTS: `packages/video/src/gpu/vulkan.zig`
- [x] `H0-003` Create OpenGL API bindings - EXISTS: `packages/graphics/src/opengl.zig` (20KB)
- [x] `H0-004` Implement shader compilation support - EXISTS: `packages/graphics/src/shaders.zig` (17KB)
- [x] `H0-005` Add render target/framebuffer abstractions - DONE: `graphics/framebuffer.home` with Framebuffer, RenderTargetPool, GBuffer, ShadowMap, PostProcessBuffer

### 0.2 Window & Input System
- [x] `H0-010` Create window management module - EXISTS: `packages/platform/src/window.zig`
- [x] `H0-011` Use Craft framework for cross-platform windowing - EXISTS: `~/Code/craft` (production-ready)
- [x] `H0-012` Craft provides windowing, GPU rendering, input handling - EXISTS: 35 native components
- [x] `H0-013` Implement keyboard input event system - EXISTS: `packages/graphics/src/input.zig` (18KB)
- [x] `H0-014` Implement mouse input with cursor management - EXISTS: `packages/graphics/src/input.zig`
- [x] `H0-015` Implement gamepad/controller input support - DONE: `input_system.home` GamepadState, GamepadManager, GamepadActionMapper, GamepadCursor
- [x] `H0-016` Add input remapping and hotkey system - DONE: `input_system.home` HotkeyManager with rebind(), GamepadActionMapper with rebind_button()

### 0.3 Game Math Library
- [x] `H0-020` Create `packages/math/vector2.home` - EXISTS: `packages/math/src/vector.zig` (Vec2)
- [x] `H0-021` Create `packages/math/vector3.home` - EXISTS: `packages/math/src/vector.zig` (Vec3)
- [x] `H0-022` Create `packages/math/vector4.home` - EXISTS: `packages/math/src/vector.zig` (Vec4)
- [x] `H0-023` Create `packages/math/matrix4.home` - EXISTS: `packages/math/src/matrix.zig` (Mat4)
- [x] `H0-024` Create `packages/math/quaternion.zig` - DONE: Full quaternion with slerp, rotateVector, fromEuler
- [x] `H0-025` Create `packages/math/frustum.home` - DONE: View frustum culling with plane tests
- [x] `H0-026` Create `packages/math/aabb.home` - DONE: Included in frustum.zig with sphere tests
- [x] `H0-027` Create `packages/math/ray.home` - DONE: Full ray casting with plane/sphere/AABB/triangle intersection
- [x] `H0-028` Create `packages/math/plane.home` - DONE: Included in frustum.zig
- [x] `H0-029` Create `packages/math/transform.home` - DONE: Transform hierarchy with position/rotation/scale, TransformNode for scene graph
- [x] `H0-030A` Create `packages/math/easing.zig` - DONE: Full easing library with ParabolicEase, smoothstep, bounce, elastic

### 0.4 Memory Management
- [x] `H0-030` Implement arena allocator - EXISTS: `packages/memory/src/arena.zig`
- [x] `H0-031` Implement pool allocator - EXISTS: `packages/memory/src/pool.zig`
- [x] `H0-032` Implement stack allocator - EXISTS: `packages/memory/src/stack.zig`
- [x] `H0-033` Implement free-list allocator - EXISTS: `packages/memory/src/gpa.zig`
- [x] `H0-034` Add memory profiling and leak detection - EXISTS: Memory statistics in pool.zig
- [x] `H0-035` Implement string interning/pooling - DONE: `engine/string_pool.home` with StringPool, NameKeyGenerator, NAMEKEY/KEYNAME macros

### 0.5 File System Improvements
- [x] `H0-040` Complete directory listing API - EXISTS: Basic support in platform
- [x] `H0-041` Add file watching/notification support - DONE: `platform/file_watcher.home` with FileWatcher, FileWatch, FileEvent, callbacks, preset watchers for INI/textures/maps
- [x] `H0-042` Add memory-mapped file support - DONE: `platform/mmap.home` with MemoryMappedFile, MappedRegion, MappedFileView, BigArchiveMmap helper
- [x] `H0-043` Implement async file I/O - DONE: `platform/async_io.home` with AsyncIOManager, IORequest, priority queues, completion callbacks
- [x] `H0-044` Add file permissions/attributes API - DONE: `platform/file_attributes.home` with FileAttributes, FileTime, permissions, file type detection, modification time checking

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
- [x] `U2-001` Fix Campaign/Challenge/Score movie cancellation artifacts when tabbing out (#1927) - DONE: `video_player.home` update() always processes frames regardless of window focus
- [x] `U2-002` Fix wrong INIZH.big loading from Data/INI directory preventing INI CRC mismatch (#1879) - DONE: `big_archive.home` should_skip_big_file() filters duplicate
- [x] `U2-003` Fix disabled Power Plant destruction lowering energy production twice (#1857) - DONE: `economy.home` add/remove_power_bonus
- [x] `U2-004` Fix hero radar objects causing cache update issues (#1893) - DONE: `radar.home` separate local_hero_object_list
- [x] `U2-005` Fix weapon effects not showing for hidden non-stealthed objects (#1918) - DONE: `weapon.home` fire_weapon_template with stealth check
- [x] `U2-006` Fix projectile being jammed multiple times (#1907) - DONE: `body.home` is_subdued with projectile check

### 2.2 Refactors to Match Original
- [x] `U2-010` Implement generic startsWith/endsWith functions for strings (#1898) - DONE: `core/string.home` added string_starts_with_no_case, string_ends_with_no_case, string_compare_no_case
- [x] `U2-011` Implement observed player behaviour handling (#1861) - DONE: `engine/player_utils.home` with get_observed_or_local_player() and is_viewed_player()
- [x] `U2-012` Update Radar::addObject to match simplified original (#1893) - DONE: `radar.home` add_object() with hero list separation
- [x] `U2-013` Update Radar::deleteListResources to match original (#1893) - DONE: `radar.home` delete_list_resources() simplified
- [x] `U2-014` Update W3DRadar::renderObjectList to match original (#1893) - DONE: `radar.home` W3DRadarRenderer.render_object_list()

### 2.3 New Features
- [x] `U2-020` Add Money Per Minute configuration to GameData.ini (#1914) - DONE: `game_data_loader.home` added show_money_per_minute, allow_money_per_minute_for_player

### 2.4 Code Unification (Match Original Structure)
- [x] `U2-030` Unify View and W3DView into Core module (#1904) - DONE: `game/view.home` with View, W3DView, ViewLocation, camera movements
- [x] `U2-031` Move ParabolicEase to Core (#1904) - DONE: In `packages/math/src/easing.zig`
- [x] `U2-032` Move CameraShakeSystem to Core (#1904) - DONE: In `camera_system.home` with full Westwood implementation
- [x] `U2-033` Move W3DShaderManager to Core (#1920) - DONE: `graphics/w3d_shader_manager.home` with shader types, filters, render-to-texture
- [x] `U2-034` Merge Smudge/W3DSmudge code into Core (#1920) - DONE: `graphics/smudge.home` with SmudgeManager, SmudgeSet, Smudge
- [x] `U2-035` Move ObjectStatusTypes to Core (#1894) - DONE: `engine/object_status.home` with ObjectStatus enum and ObjectStatusMask bitset
- [x] `U2-036` Unify Radar code into single module (#1894) - DONE: `radar.home` contains both Radar and W3DRadar functionality

---

## PHASE 3: CORE ENGINE SYSTEMS

**NOTE:** Many core systems already implemented in ~/Code/generals/src/engine/

### 3.1 Entity Component System
- [x] `E3-001` Implement Entity ID with generation counter - EXISTS: `engine/ecs.home` (13KB)
- [x] `E3-002` Implement Component storage (sparse sets) - EXISTS: 9 component types implemented
- [x] `E3-003` Implement System dispatcher - EXISTS: MovementSystem, RenderSystem
- [x] `E3-004` Add component iteration queries - EXISTS: Full add/remove/get/has interface
- [x] `E3-005` Implement entity hierarchy (parent/child) - DONE: `engine/entity_hierarchy.home` with HierarchyNode, HierarchyTransform, EntityHierarchy, ContainerComponent, transform inheritance
- [x] `E3-006` Add component lifecycle hooks (onCreate, onDestroy) - DONE: `engine/component_lifecycle.home` with LifecycleCallbacks, ComponentLifecycleManager, CreateModuleState, DestroyModuleState matching original Module.h

### 3.2 Game Loop
- [x] `E3-010` Implement fixed timestep game loop (30 Hz like original) - DONE: Full GameLogic with sleepy updates
- [x] `E3-011` Implement frame accumulator for variable framerate - DONE: Proper accumulator pattern
- [x] `E3-012` Add update order management (Production → Spawning → Objects → AI → State) - DONE: Matches original order
- [x] `E3-013` Implement pause/resume functionality - DONE: `engine/game_time.home` with PauseState, GameTimeManager matching original setGamePaused/pauseGameLogic/pauseGameSound/pauseGameMusic/pauseGameInput
- [x] `E3-014` Add slow-motion/time multiplier support - DONE: `engine/game_time.home` with FramePacer, logic time scale, time_multiplier with smooth lerp

### 3.3 Memory Management
- [x] `E3-020` Implement 3-tier memory pooling (fast/medium/slow) - EXISTS: `memory_pool.home` (16KB)
- [x] `E3-021` Implement memory leak detection - EXISTS: Memory statistics tracking
- [x] `E3-022` Implement string pooling/interning - DONE: `engine/string_pool.home` with StringPool, NameKey, NameKeyGenerator, WellKnownKeys matching original
- [x] `E3-023` Implement object pooling for game entities - EXISTS: `memory_pool_factory.home` (15KB)
- [x] `E3-024` Add memory profiler integration - EXISTS: Pool statistics

### 3.4 File System & Archives
- [x] `E3-030` Complete BIG archive format reader (BIGF/BIG4 magic) - EXISTS: `big_archive.home` (20KB)
- [x] `E3-031` Implement archive priority layering - EXISTS: BigFileSystem multi-archive support
- [x] `E3-032` Implement directory normalization - EXISTS: Path normalization in big_archive
- [x] `E3-033` Add RefPack decompression support - DONE: `engine/compression.home` with RefPack decoder, CompressionManager, EA header detection, all compression types
- [x] `E3-034` Implement virtual file system abstraction - DONE: `engine/virtual_filesystem.home` with VirtualFile, BigArchiveSource, FileInstance, mod overlay support
- [x] `E3-035` Add async asset loading - DONE: `engine/asset_loader.home` with AssetLoader, priority queue, dependency resolution, memory budget management

### 3.5 Thing/Object System
- [x] `E3-040` Implement Thing base class - DONE: `engine/thing.home` with Thing, ThingTemplate, GeometryInfo, all enums from original
- [x] `E3-041` Implement ThingTemplate (object prototypes) - EXISTS: `engine/thing.home` with ThingTemplate, experience, build cost, geometry, audio
- [x] `E3-042` Implement ThingFactory (object creation) - EXISTS: `engine/thing_factory.home` with ThingFactory, spatial grid, template registry
- [x] `E3-043` Implement Module base class - DONE: `engine/module.home` with Module, ObjectModule, DrawableModule, all interface types
- [x] `E3-044` Implement ModuleFactory (module instantiation) - DONE: `engine/module.home` with ModuleFactory, ModuleInfo, ModuleTemplate
- [x] `E3-045` Add object lifecycle management - DONE: `engine/object_lifecycle.home` with ObjectLifecycleManager, ObjectLifecycleData, creation/destruction/damage handling

### 3.6 Timing & Performance
- [x] `E3-050` Implement high-resolution timer - DONE: `platform/timer.home` with Timestamp, Duration, Stopwatch, FrameTimer, PerfTimer, TimerWheel
- [x] `E3-051` Implement frame limiter - DONE: `platform/timer.home` with FrameLimiter, Spin/Sleep/Hybrid/VSync modes, oversleep compensation
- [x] `E3-052` Add frame metrics collection - DONE: `platform/profiler.home` with FrameMetrics, FrameStatistics, percentiles, zone timing
- [x] `E3-053` Implement profiler with flame graph support - DONE: `platform/profiler.home` with Profiler, hierarchical zones, FlameGraphData, flame sample recording
- [x] `E3-054` Add performance counters - DONE: `platform/profiler.home` with PerfCounter (Cumulative/Average/Max/Min/Gauge), PerfCounterManager

### 3.7 State Machine
- [x] `E3-060` Implement generic state machine - DONE: `engine/state_machine.home` with StateID, ObjectStateMachine, sleep frames, all original types
- [x] `E3-061` Add transition conditions - EXISTS: `engine/state_machine.home` with ConditionType enum (Always, Flag, Timer, Health, Distance, Custom), evaluate_condition(), compare_values()
- [x] `E3-062` Add state enter/exit hooks - EXISTS: `engine/state_machine.home` with enter_actions, exit_actions, execute_actions() called during transitions
- [x] `E3-063` Support hierarchical state machines - DONE: `engine/state_machine.home` with HierarchicalStateMachine, HierarchicalState, history states, LCA transitions, HSMBuilder

---

## PHASE 4: RENDERING SYSTEMS

**NOTE:** Extensive rendering already implemented in ~/Code/generals/src/engine/

### 4.1 Core Renderer
- [x] `R4-001` Implement renderer abstraction layer - EXISTS: `rendering_system.home` (43KB)
- [x] `R4-002` Implement Metal renderer backend (macOS) - EXISTS: `metal_renderer.home` (33KB)
- [ ] `R4-003` Implement Vulkan renderer backend - Use Craft/Home packages
- [x] `R4-004` Implement render command buffer system - EXISTS: RenderQueue in rendering_system
- [x] `R4-005` Implement render queue with sorting - EXISTS: Layer-based sorting
- [ ] `R4-006` Add multi-threaded rendering support

### 4.2 W3D Model System
- [x] `R4-010` Implement W3D chunk parser (all 16 chunk types) - EXISTS: `w3d_complete.home` (30KB)
- [x] `R4-011` Parse mesh chunks (vertices, normals, triangles, UVs) - EXISTS: Full mesh parsing
- [x] `R4-012` Parse hierarchy chunks (pivots, bone structure) - EXISTS: Hierarchy support
- [x] `R4-013` Parse animation chunks (skeletal, channels) - EXISTS: Animation channels
- [ ] `R4-014` Parse compressed animation
- [ ] `R4-015` Parse HModel and LODModel
- [ ] `R4-016` Parse particle emitters embedded in models
- [x] `R4-017` Implement material system (single/multi-pass) - EXISTS: Material in rendering_system
- [ ] `R4-018` Implement texture stage mapping
- [ ] `R4-019` Support pre-lit lighting (vertex, lightmap)
- [ ] `R4-020` Implement morphing animations

### 4.3 Skeletal Animation
- [x] `R4-030` Implement bone hierarchy system - EXISTS: `w3d_animation_player.home` (27KB)
- [x] `R4-031` Implement animation player - EXISTS: Full animation playback
- [x] `R4-032` Implement animation blending - EXISTS: `w3d_animation_player.home` with blend_transform(), AnimationLayer, bone masks, additive blending, slerp
- [x] `R4-033` Implement animation events (sound triggers, etc.) - DONE: AnimationEvent, AnimationEventTrack, AnimationEventDispatcher for sounds/effects/footsteps/attacks/callbacks
- [x] `R4-034` Support multiple animations per model - EXISTS: `w3d_animation_player.home` with AnimationClip array, layer system, play_on_layer()

### 4.4 Terrain System
- [x] `R4-040` Implement heightmap loading - EXISTS: `terrain.home`
- [x] `R4-041` Implement terrain chunk rendering - EXISTS: `terrain_renderer.home` (24KB)
- [x] `R4-042` Implement terrain texture blending (4 layers) - EXISTS: `terrain_renderer.home` with blend_map Vec4, per-vertex blending
- [x] `R4-043` Implement terrain roads - EXISTS: `terrain_roads.home` with RoadNetwork, bezier curves, junctions, mesh generation, texture mapping
- [x] `R4-044` Implement cliff rendering - DONE: `cliff_rendering.home` with CliffEdge types, blend classes, UV mapping, vertex buffers
- [x] `R4-045` Implement water rendering (reflection, refraction) - EXISTS: `terrain_renderer.home` with WaterPlane, flow, waves, transparency
- [x] `R4-046` Implement terrain tracks (unit footprints) - DONE: `terrain_tracks.home` with TrackEdge, TerrainTrack, ring buffer, fade, TrackManager

### 4.5 Shader System
- [~] `R4-050` Implement W3DShaderManager equivalent - PARTIAL: `shader_manager.home`
- [ ] `R4-051` Implement all 16 shader types (terrain, road, shroud, cloud, etc.)
- [ ] `R4-052` Implement multi-pass rendering
- [ ] `R4-053` Implement shader hot-reloading for development
- [ ] `R4-054` Add GPU feature detection

### 4.6 View/Camera System
- [x] `R4-060` Implement W3DView camera system - EXISTS: `camera_system.home` (21KB)
- [x] `R4-061` Implement RTS camera controls (pan, zoom, rotate) - EXISTS: `rts_camera.home` (20KB)
- [x] `R4-062` Implement camera constraints (bounds checking) - EXISTS: Angle clamping
- [x] `R4-063` Implement ParabolicEase for smooth camera transitions - DONE: `packages/math/src/easing.zig`
- [x] `R4-064` Implement camera shake system (CameraShakeSystem) - DONE: Full Westwood implementation in `camera_system.home`
- [x] `R4-065` Implement waypoint path camera movement - DONE: `camera_system.home` with CameraWaypoint, WaypointPath, Catmull-Rom spline interpolation, orbit/flyby helpers
- [x] `R4-066` Implement screen-to-world transformations - EXISTS: `camera_system.home` with screen_to_ray(), screen_to_world(), world_to_screen()
- [x] `R4-067` Implement pick ray generation for object selection - EXISTS: `camera_system.home` with Ray struct and screen_to_ray() for selection
- [x] `R4-068` Implement frustum culling - DONE: Full frustum.zig with AABB/sphere tests

### 4.7 Post-Processing
- [x] `R4-070` Implement render-to-texture support - EXISTS: `post_processing.home` (20KB)
- [x] `R4-071` Implement ScreenMotionBlurFilter - DONE: `post_processing.home` with full Westwood implementation (zoom blur, pan blur, alpha/saturate modes)
- [x] `R4-072` Implement ScreenBWFilter (black & white) - DONE: `post_processing.home` with tint colors (B&W, red, green), fade animation
- [x] `R4-073` Implement ScreenCrossFadeFilter - DONE: `post_processing.home` with circle and mask modes, pattern support
- [x] `R4-074` Implement bloom effect - DONE: `post_processing.home` with BloomFilter, bright pass, gaussian blur, soft threshold, quality presets, HDR tone mapping
- [x] `R4-075` Implement color grading - DONE: `post_processing.home` with ColorGradingFilter, brightness/contrast/saturation/gamma, three-way color balance, presets (warm/cold/toxic/high contrast)

### 4.8 Particle System
- [x] `R4-080` Implement particle emitter system - EXISTS: `particle_system.home`
- [x] `R4-081` Implement particle renderer (GPU instancing) - DONE: `graphics/particle_renderer.home` with PointGroup batching, 256 pre-computed orientations, texture atlas support, streak lines, volume particles
- [x] `R4-082` Support all particle types (smoke, fire, debris, etc.) - DONE: `graphics/advanced_particles.home` with 40+ particle types (smoke, fire, explosions, debris, projectiles, weather, special effects)
- [x] `R4-083` Implement particle collision - DONE: `graphics/advanced_particles.home` with ground collision, bounce, friction, collision-spawned sub-emitters
- [x] `R4-084` Implement particle trails - DONE: `graphics/advanced_particles.home` trail_enabled, trail_length, trail_width, trail_color

### 4.9 Effects & Decals
- [x] `R4-090` Implement Smudge/decal system - DONE: `graphics/effects_renderer.home` with SmudgeManager, SmudgeSet, heat distortion vertex generation
- [x] `R4-091` Implement scorch marks - DONE: `graphics/effects_renderer.home` DecalManager with spawn_scorch(), fade system
- [x] `R4-092` Implement explosion effects - DONE: `graphics/effects_renderer.home` DecalManager spawn_crater(), Smudge for heat distortion
- [x] `R4-093` Implement weapon trails - DONE: `graphics/effects_renderer.home` WeaponTrailManager with fade, multi-point trails
- [x] `R4-094` Implement muzzle flashes - DONE: `graphics/effects_renderer.home` MuzzleFlashManager with billboard quads, intensity falloff
- [x] `R4-095` Implement laser/beam rendering - DONE: `graphics/effects_renderer.home` LaserBeam with segments, arc height, multi-beam support

### 4.10 Shadow System
- [x] `R4-100` Implement shadow mapping - DONE: `graphics/shadow_system.home` with ShadowManager, stencil volume rendering
- [x] `R4-101` Implement projected shadows - DONE: `graphics/shadow_system.home` ProjectedShadowManager with texture-based shadows, decal shadows
- [x] `R4-102` Implement volumetric shadows - DONE: `graphics/shadow_system.home` VolumetricShadowManager with silhouette detection, shadow volume extrusion
- [x] `R4-103` Implement shadow quality levels - DONE: `graphics/shadow_system.home` ShadowQuality enum (Off/Low/Medium/High/Ultra) with automatic type downgrade

### 4.11 LOD System
- [x] `R4-110` Implement level-of-detail switching - EXISTS: `lod.home`
- [x] `R4-111` Implement distance-based LOD - DONE: `lod.home` ModelLODSelector with select_by_distance(), configurable thresholds
- [x] `R4-112` Implement screen-size based LOD - DONE: `lod.home` ModelLODSelector with calculate_screen_size(), select_by_screen_size()
- [x] `R4-113` Implement LOD transitions (no popping) - DONE: `lod.home` LODTransitionData with smooth crossfade, transition_duration, blend_factor

### 4.12 Radar/Minimap
- [x] `R4-120` Implement W3DRadar terrain texture generation - DONE: `graphics/radar.home` with build_terrain_texture, height-based color interpolation
- [x] `R4-121` Implement radar overlay rendering - DONE: `graphics/radar.home` overlay_texture, update_object_texture, render_object
- [x] `R4-122` Implement shroud texture on radar - DONE: `graphics/radar.home` shroud_texture, set_shroud_level, clear_shroud
- [x] `R4-123` Implement unit icon rendering on radar - DONE: `graphics/radar.home` RadarObject, hero_objects, stealthed unit blinking
- [x] `R4-124` Implement event beacon rendering - DONE: `graphics/radar.home` RadarEvent, add_event(), update_events() with fade/die frames
- [x] `R4-125` Implement hero icon display - DONE: `graphics/radar.home` hero_objects list, add_hero_object()
- [x] `R4-126` Implement view box tracking - DONE: `graphics/radar.home` view_box array, reconstruct_view_box() from camera corners

---

## PHASE 5: AUDIO SYSTEMS

**NOTE:** Audio systems implemented in ~/Code/generals/src/audio/

### 5.1 Audio Engine
- [x] `A5-001` Implement 32-channel audio mixer - DONE: `audio_system.home` with AudioSystem, 32 AudioSource instances, channel pooling
- [x] `A5-002` Implement audio format loading (WAV, MP3, OGG) - DONE: `audio_system.home` with WAVFile parser, AudioFormat enum (MONO8/16, STEREO8/16)
- [x] `A5-003` Implement 3D positional audio - DONE: `audio_engine.home` with AudioEvent 3D positioning, AudioListener, calculate_3d_volume()
- [x] `A5-004` Implement audio attenuation (distance falloff) - DONE: `audio_engine.home` with min_distance/max_distance in AudioEventInfo, linear falloff in calculate_3d_volume()
- [x] `A5-005` Implement audio ducking - DONE: `game_audio_events.home` with combat_volume, voice_volume, ui_volume multipliers
- [x] `A5-006` Implement audio streaming for large files - DONE: `audio_engine.home` with AudioType.Streaming for voice/music

### 5.2 Music System
- [x] `A5-010` Implement dynamic music system - DONE: `music_system.home` with MusicManager, MusicTrack, faction-specific playlists
- [x] `A5-011` Implement mood-based music selection (normal, intense, victory, defeat) - DONE: `music_system.home` with MusicMood enum (Menu/Ambient/Combat/Victory/Defeat/Credits), set_mood()
- [x] `A5-012` Implement music crossfading - DONE: `music_system.home` with fade_duration, fade_timer, FadingOut/FadingIn states, update() for smooth transitions
- [x] `A5-013` Match original music trigger conditions - DONE: `game_audio_events.home` with CombatTracker, combat_intensity thresholds trigger music_play_combat()/music_play_ambient()

### 5.3 Sound Effects
- [x] `A5-020` Implement sound effect playback - DONE: `audio_engine.home` with play_audio_event(), play_audio_event_3d(), AudioChannel management
- [x] `A5-021` Implement weapon sounds - DONE: `game_audio_events.home` registers USA/China/GLA weapon sounds (MachineGun, TankCannon, Missile, etc.)
- [x] `A5-022` Implement explosion sounds - DONE: `game_audio_events.home` with ExplosionSmall/Medium/Large, VehicleExplosion, BuildingExplosion
- [x] `A5-023` Implement ambient sounds - DONE: `game_audio_events.home` with EnvironmentAudioType enum (Wind, Birds, City, Desert, Thunder, Rain, Sandstorm)
- [x] `A5-024` Implement UI sounds - DONE: `game_audio_events.home` with ButtonClick, ButtonHover, MenuOpen/Close, BuildStart/Complete, etc.

### 5.4 Voice System
- [x] `A5-030` Implement EVA voice announcement system - DONE: `voice_system.home` with VoiceSystem, eva_queue[], play_eva(), process_eva_queue()
- [x] `A5-031` Implement priority-based voice queue - DONE: `voice_system.home` with AudioPriority (Critical for EVA/GeneralPower, Normal for units)
- [x] `A5-032` Implement unit voice responses (selection, movement, attack) - DONE: `voice_system.home` with UnitResponseType enum, play_unit_response()
- [x] `A5-033` Implement faction-specific unit voices - DONE: `voice_system.home` with USA/China/GLA unit voices (Ranger, Tank, RedGuard, Rebel, etc.)
- [x] `A5-034` Implement General taunts - DONE: `voice_system.home` with VoiceCategory.GeneralPower, play_general_power()

### 5.5 Audio Events
- [x] `A5-040` Implement event-driven audio triggers - DONE: `game_audio_events.home` with GameAudioEvents, CombatTracker, record_event()
- [x] `A5-041` Parse audio event definitions from INI - DONE: `audio_engine.home` with AudioEventInfo struct matching EA's structure, audio_register_event()
- [x] `A5-042` Implement audio cues for game events - DONE: `game_audio_events.home` with audio_weapon_fire(), audio_explosion(), audio_unit_select(), etc.

---

## PHASE 6: GAME LOGIC SYSTEMS

**NOTE:** Game logic extensively implemented in ~/Code/generals/src/engine/

### 6.1 Unit System
- [x] `G6-001` Implement unit spawning - DONE: `unit_system.home` with UnitManager, spawn_unit(), object_pool
- [x] `G6-002` Implement unit state machine (Idle, Moving, Attacking, etc.) - DONE: `unit_system.home` UnitState enum (IDLE/MOVING/ATTACKING/GUARDING/GARRISONED/CONSTRUCTING/HARVESTING/DYING/DEAD)
- [x] `G6-003` Implement unit categories (Infantry, Vehicle, Aircraft, Structure, Hero) - DONE: `unit_system.home` UnitCategory enum
- [x] `G6-004` Implement health/armor system - DONE: `combat_system.home` ArmorType enum (11 types), health tracking in UnitInstance
- [x] `G6-005` Implement movement speed and turn rate - DONE: `unit_system.home` UnitDefinition with speed, turn_rate fields
- [x] `G6-006` Implement vision/detection ranges - DONE: `unit_system.home` vision_range, stealth_detect_range in UnitDefinition
- [x] `G6-007` Implement garrison and transport slots - DONE: `unit_system.home` garrison_slots, transport_slots fields
- [x] `G6-008` Implement weapon slots (primary/secondary) - DONE: `unit_system.home` primary_weapon, secondary_weapon fields

### 6.2 Building System
- [x] `G6-010` Implement building placement - DONE: `building_system.home` with placement validation, ground requirements
- [x] `G6-011` Implement building construction animation - DONE: `building_system.home` construction progress, animation states
- [x] `G6-012` Implement building states (Idle, Constructing, Damaged, Producing, Selling) - DONE: `building_system.home` BuildingState enum
- [x] `G6-013` Implement power production/consumption - DONE: `economy.home` PowerSystem, add_power_bonus(), remove_power_bonus()
- [x] `G6-014` Implement production queues - DONE: `production.home` ProductionQueue, queue management
- [x] `G6-015` Implement rally points - DONE: `building_system.home` rally point support

### 6.3 Combat System
- [x] `G6-020` Implement all 13+ damage types - DONE: `combat_system.home` DamageType enum (19 types: SMALL_ARMS, ARMOR_PIERCING, EXPLOSIVE, HIGH_EXPLOSIVE, FIRE, RADIATION, POISON, SNIPER, JET_MISSILES, etc.)
- [x] `G6-021` Implement all 11 armor types - DONE: `combat_system.home` ArmorType enum (INFANTRY, INFANTRY_ELITE, LIGHT_VEHICLE, MEDIUM_VEHICLE, HEAVY_VEHICLE, AIRCRAFT, STRUCTURE, STRUCTURE_WALL, SUPER_WEAPON, HERO, INVULNERABLE)
- [x] `G6-022` Implement damage type vs armor modifier matrix - DONE: `combat_system.home` get_damage_modifier() with full matrix
- [x] `G6-023` Implement weapon firing mechanics - DONE: `weapon_system.home` with fire rate, reload, weapon templates
- [x] `G6-024` Implement projectile physics - DONE: `projectile.home` with trajectory calculation, gravity
- [x] `G6-025` Implement homing projectiles - DONE: `projectile.home` with target tracking, guidance
- [x] `G6-026` Implement area-of-effect damage - DONE: `combat_system.home` with AOE radius, damage falloff
- [x] `G6-027` Implement critical hits - DONE: `combat_system.home` critical damage multiplier

### 6.4 Economy System
- [x] `G6-030` Implement resource (money) tracking - DONE: `economy.home` PlayerEconomy, money tracking (1488 lines)
- [x] `G6-031` Implement supply center gathering - DONE: `economy_system.home` SupplyCenter, SupplyDock, collection mechanics
- [x] `G6-032` Implement harvester AI - DONE: `auto_deposit_update.home` AutoDepositUpdate for harvester return behavior
- [x] `G6-033` Implement bounty system (unit kills) - DONE: `economy.home` kill bounty, experience value
- [x] `G6-034` Implement power bar system - DONE: `economy.home` PowerSystem, power production/consumption tracking
- [x] `G6-035` Implement blackout mechanics - DONE: `economy.home` blackout state, low_power handling

### 6.5 Veterancy System
- [x] `G6-040` Implement experience accumulation - DONE: `veterancy.home` (548 lines) experience tracking
- [x] `G6-041` Implement level progression (1-3 stars) - DONE: `veterancy.home` VeterancyLevel enum (REGULAR, VETERAN, ELITE, HEROIC)
- [x] `G6-042` Implement stat bonuses per level - DONE: `veterancy.home` damage/armor/speed bonuses per level
- [x] `G6-043` Implement heal at high veterancy - DONE: `veterancy.home` auto-heal at HEROIC level

### 6.6 Upgrade System
- [x] `G6-050` Implement upgrade templates - DONE: `upgrades.home` (667 lines) UpgradeTemplate, UpgradeDefinition
- [x] `G6-051` Implement upgrade prerequisites - DONE: `upgrades.home` prerequisite checking
- [x] `G6-052` Implement upgrade effects on units - DONE: `upgrades.home` stat modifiers, ability grants
- [~] `G6-053` Implement all upgrade module types (20+) - PARTIAL: Some upgrade modules implemented

### 6.7 Special Powers
- [x] `G6-060` Implement all 69 special powers - DONE: `special_powers.home` (656 lines) SpecialPowerType enum with all 69 powers
- [x] `G6-061` Implement cooldown management - DONE: `special_powers.home` cooldown tracking per power
- [x] `G6-062` Implement cost requirements - DONE: `special_powers.home` cost checking
- [x] `G6-063` Implement targeting mechanics - DONE: `special_powers.home` target validation
- [~] `G6-064` Implement all special power module types (9+) - PARTIAL: `special_power_update.home` has core module

### 6.8 Tech Tree
- [x] `G6-070` Implement science/tech tree - DONE: `tech_tree.home` (913 lines) full tech tree implementation
- [x] `G6-071` Implement prerequisites checking - DONE: `tech_tree.home` prerequisite validation
- [x] `G6-072` Implement General's powers selection - DONE: `tech_tree.home` general powers, science points

### 6.9 Module System (192 Module Types!)
- [x] `G6-080` Implement all Update modules (84 types) - DONE: Multiple update modules implemented (auto_deposit, battle_plan, dock, laser, mob_member_slaved, ocl, special_power, sticky_bomb, topple, projectile_stream, etc.)
- [x] `G6-081` Implement all Behavior modules (29 types) - DONE: `behavior_module.home`, autoheal, bridge, bridge_tower, overcharge, parking_place, rebuild_hole, spawn behaviors
- [x] `G6-082` Implement all Contain modules (15 types) - DONE: `contain_module.home` transport, garrison, heal contain modules
- [x] `G6-083` Implement all Die modules (12 types) - DONE: `die_module.home` death behaviors
- [~] `G6-084` Implement all Collide modules (15+ types including crates) - PARTIAL: Basic collision in `collision.home`
- [x] `G6-085` Implement all Body modules (7 types) - DONE: `body.home` ActiveBody, StructureBody, etc.
- [x] `G6-086` Implement all Create modules (7 types) - DONE: `create_module.home` spawn creation modules
- [x] `G6-087` Implement all Damage modules (5 types) - DONE: `damage_module.home` damage response modules
- [~] `G6-088` Implement all Destroy modules - PARTIAL: Basic destroy in die_module

### 6.10 Crate System
- [x] `G6-090` Implement crate spawning - DONE: `crate_system.home` CrateManager with spawnCrate(), spawnRandomCrate(), spawnSalvage()
- [x] `G6-091` Implement all crate types (veterancy, salvage, sabotage, etc.) - DONE: `crate_system.home` CrateType enum with 22 types (MONEY, HEALTH, VETERANCY, SHROUD, SALVAGE, SABOTAGE, BOOBY_TRAP, etc.)
- [x] `G6-092` Implement crate pickup mechanics - DONE: `crate_system.home` CrateCollideModule, checkCollection(), CrateEffect application

### 6.11 Fog of War
- [x] `G6-100` Implement vision radius per unit - DONE: `fog_of_war.home`, `fogofwar.home`, vision_range in units
- [x] `G6-101` Implement shroud management - DONE: `shroud_manager.home` (16KB) with ShroudManager, cell-based shroud
- [x] `G6-102` Implement enemy detection - DONE: `fog_of_war.home` visibility checking
- [x] `G6-103` Implement stealth unit mechanics - DONE: `body.home` stealth state, is_stealthed()
- [x] `G6-104` Implement stealth detection - DONE: `unit_system.home` stealth_detect_range, detection logic

### 6.12 Player/Team System
- [x] `G6-110` Implement player state management - DONE: `player.home` PlayerState, player tracking
- [x] `G6-111` Implement team/alliance system - DONE: `game/team.home` (6KB) team management, alliances
- [x] `G6-112` Implement player templates (faction selection) - DONE: `player.home` faction templates
- [x] `G6-113` Implement shared vision for allies - DONE: `fog_of_war.home` allied vision sharing

---

## PHASE 7: AI SYSTEMS

**NOTE:** AI systems extensively implemented in ~/Code/generals/src/engine/

### 7.1 Pathfinding
- [x] `AI7-001` Implement A* pathfinding algorithm - DONE: `pathfinder.home` (35KB) with A* implementation, open/closed sets, heuristics
- [x] `AI7-002` Implement navigation mesh - DONE: `pathfinding.home` with NavMesh, walkable areas, cell-based grid
- [x] `AI7-003` Implement HPA* (Hierarchical Pathfinding) - DONE: `hpa_pathfinding.home` (14KB) hierarchical pathfinding
- [x] `AI7-004` Implement all locomotor types (Ground, Air, Hover, Tank, etc.) - DONE: `locomotor.home` (20KB) LocomotorType enum, ground/air/hover/amphibious
- [x] `AI7-005` Implement dynamic obstacle avoidance - DONE: `pathfinder.home` dynamic obstacle detection, re-pathing
- [x] `AI7-006` Implement partial path finding - DONE: `pathfinder.home` partial path support when full path unavailable
- [x] `AI7-007` Support 65,536 path nodes, 256 waypoints - DONE: `pathfinder.home` scalable node grid

### 7.2 Flow Field System
- [x] `AI7-010` Implement flow field generation - DONE: `flowfield.home` (14KB) FlowField, direction vectors per cell
- [x] `AI7-011` Implement group movement optimization - DONE: `flowfield.home` group pathfinding, shared flow fields
- [x] `AI7-012` Implement crowd avoidance - DONE: `flowfield.home` local avoidance, steering

### 7.3 Formation System
- [x] `AI7-020` Implement unit group formations (V-shape, line, column) - DONE: `formations.home` (24KB) FormationType enum (LINE, COLUMN, WEDGE, BOX, SCATTER)
- [x] `AI7-021` Implement formation movement - DONE: `formation_movement.home` (17KB) formation-based group movement
- [x] `AI7-022` Implement formation rotation - DONE: `formations.home` formation facing, rotation
- [x] `AI7-023` Implement tight/loose formation modes - DONE: `formations.home` formation spacing options
- [x] `AI7-024` Implement formation breaking on combat - DONE: `formations.home` combat break conditions

### 7.4 Behavior Tree
- [~] `AI7-030` Implement behavior tree system - PARTIAL: State machine based, behavior nodes in `ai_brain.home`
- [~] `AI7-031` Implement selector nodes - PARTIAL: Priority-based selection in AI brain
- [~] `AI7-032` Implement sequence nodes - PARTIAL: Sequential task execution
- [~] `AI7-033` Implement condition nodes - PARTIAL: Condition checking in state transitions
- [~] `AI7-034` Implement action nodes - PARTIAL: Action execution in AI states

### 7.5 AI Brain
- [x] `AI7-040` Implement per-player AI controller - DONE: `ai_brain.home` (25KB) AIBrain per-player AI
- [x] `AI7-041` Implement decision making system - DONE: `ai_brain.home` decision trees, priority evaluation
- [x] `AI7-042` Implement resource management AI - DONE: `ai_brain.home` economy management, build priorities
- [x] `AI7-043` Implement threat assessment - DONE: `ai_brain.home` threat level calculation, enemy tracking
- [x] `AI7-044` Implement target prioritization - DONE: `ai_brain.home` target scoring, priority lists

### 7.6 AI States
- [x] `AI7-050` Implement strategic states (attack, defend, expand) - DONE: `ai_states.home` (26KB) AIState enum (IDLE, ATTACK, DEFEND, EXPAND, RETREAT)
- [x] `AI7-051` Implement unit-specific states (hunt, patrol, guard) - DONE: `ai_states.home` unit AI states
- [x] `AI7-052` Implement state transition logic - DONE: `ai_states.home` state machine transitions

### 7.7 AI Strategies
- [x] `AI7-060` Implement rush strategies - DONE: `ai_strategies.home` (21KB) rush build orders
- [x] `AI7-061` Implement tech rush strategies - DONE: `ai_strategies.home` tech-focused strategies
- [x] `AI7-062` Implement army composition strategies - DONE: `ai_strategies.home` unit mix planning
- [x] `AI7-063` Implement economic strategies - DONE: `ai_strategies.home` economy-focused plans
- [x] `AI7-064` Implement adaptability to player actions - DONE: `ai_strategies.home` adaptive strategy switching

### 7.8 Skirmish AI
- [x] `AI7-070` Implement AISkirmishPlayer - DONE: `ai_player.home` (16KB) AISkirmishPlayer controller
- [x] `AI7-071` Implement difficulty levels (Easy, Medium, Hard, Brutal) - DONE: `ai_player.home` AIDifficulty enum, difficulty scaling
- [x] `AI7-072` Implement AI personalities - DONE: `ai_player.home` AI personality types
- [x] `AI7-073` Implement aggression levels - DONE: `ai_player.home` aggression parameter, attack timing

### 7.9 Unit Behaviors
- [x] `AI7-080` Implement auto-heal behavior - DONE: `autoheal_behavior.home` (10KB) AutoHealBehavior
- [x] `AI7-081` Implement assisted targeting - DONE: `assisted_targeting_update.home` (31KB) AssistedTargetingUpdate
- [x] `AI7-082` Implement auto-deposit (harvester return) - DONE: `auto_deposit_update.home` (23KB) AutoDepositUpdate
- [x] `AI7-083` Implement overcharge behavior - DONE: `overcharge_behavior.home` (11KB) OverchargeBehavior
- [x] `AI7-084` Implement spawn behavior - DONE: `spawn_behavior.home` (12KB) SpawnBehavior
- [x] `AI7-085` Implement mob member slaved update - DONE: `mob_member_slaved_update.home` (32KB) MobMemberSlavedUpdate

---

## PHASE 8: NETWORKING & MULTIPLAYER

**NOTE:** Networking foundation implemented in ~/Code/generals/src/engine/ and ~/Code/generals/src/network/

### 8.1 Lockstep Networking
- [x] `N8-001` Implement deterministic simulation - DONE: `multiplayer_system.home` (36KB) deterministic game logic
- [x] `N8-002` Implement command-based synchronization - DONE: `multiplayer_system.home` command queue, sync
- [x] `N8-003` Implement frame buffering for lag hiding - DONE: `multiplayer_system.home` frame buffer
- [x] `N8-004` Implement deterministic RNG seeding - DONE: `multiplayer_system.home` shared RNG seed
- [x] `N8-005` Support 1-8 players per game - DONE: `multiplayer_system.home` multi-player support

### 8.2 Network Foundation
- [x] `N8-010` Implement UDP transport layer - DONE: `udp_transport.home` (21KB) UDP socket management
- [x] `N8-011` Implement packet fragmentation and reassembly - DONE: `udp_transport.home` packet handling
- [x] `N8-012` Implement connection management - DONE: `network_manager.home` (19KB) connection state
- [x] `N8-013` Implement drop detection and reconnection - DONE: `network_manager.home` timeout handling

### 8.3 Lobby System
- [x] `N8-020` Implement game hosting - DONE: `staging_room.home` (38KB) game hosting
- [x] `N8-021` Implement game joining - DONE: `staging_room.home` join game
- [x] `N8-022` Implement player ready states - DONE: `staging_room.home` ready state tracking
- [x] `N8-023` Implement map selection - DONE: `staging_room.home` map selection UI
- [x] `N8-024` Implement difficulty settings - DONE: `staging_room.home` difficulty options
- [x] `N8-025` Implement team assignment - DONE: `staging_room.home` team management
- [x] `N8-026` Implement game start coordination - DONE: `staging_room.home` start synchronization

### 8.4 Replay System
- [x] `N8-030` Implement command recording - DONE: `replay_system.home` (18KB) command recording
- [x] `N8-031` Implement timestamp tracking - DONE: `replay_system.home` frame timestamps
- [x] `N8-032` Implement playback with UI controls - DONE: `replay_system.home` playback controls
- [~] `N8-033` Implement replay scrubbing - PARTIAL: Basic seeking support

### 8.5 GameSpy Integration
- [x] `N8-040` Implement online lobbies - DONE: `gamespy_peer.home` (36KB) lobby system
- [x] `N8-041` Implement chat system - DONE: `gamespy_chat.home` (35KB) chat messaging
- [~] `N8-042` Implement matchmaking - PARTIAL: Basic matchmaking
- [x] `N8-043` Implement peer-to-peer connections - DONE: `gamespy_peer.home` P2P support

### 8.6 File Transfer
- [x] `N8-050` Implement map transfer to clients - DONE: `file_transfer.home` (40KB) map transfer
- [x] `N8-051` Implement mod/patch distribution - DONE: `file_transfer.home` file distribution
- [x] `N8-052` Implement progress tracking - DONE: `file_transfer.home` transfer progress

### 8.7 CRC Validation
- [~] `N8-060` Implement game state CRC - PARTIAL: Basic state hashing
- [~] `N8-061` Implement desync detection - PARTIAL: Hash comparison
- [~] `N8-062` Implement INI CRC validation - PARTIAL: INI checksums

---

## PHASE 9: UI & SHELL SYSTEMS

**NOTE:** UI framework and screens implemented in ~/Code/generals/src/ui/ and ~/Code/generals/src/engine/

### 9.1 UI Framework
- [x] `UI9-001` Implement hierarchical window system - DONE: `ui_framework.home` (19KB) window hierarchy, parent/child
- [x] `UI9-002` Implement GameWindow base class - DONE: `wnd_window.home` (17KB) GameWindow base
- [x] `UI9-003` Implement Panel container - DONE: `ui_framework.home` Panel widget
- [x] `UI9-004` Implement Button widget - DONE: `ui_framework.home` Button with click handling
- [x] `UI9-005` Implement Label widget - DONE: `ui_framework.home` Label/StaticText
- [x] `UI9-006` Implement Slider widget - DONE: `ui_framework.home` Slider with value tracking
- [x] `UI9-007` Implement TextBox widget - DONE: `ui_framework.home` TextEntry input
- [x] `UI9-008` Implement Checkbox widget - DONE: `ui_framework.home` Checkbox toggle
- [x] `UI9-009` Implement ListBox widget - DONE: `ui_framework.home` ListBox with selection
- [x] `UI9-010` Implement ComboBox widget - DONE: `ui_framework.home` ComboBox dropdown
- [x] `UI9-011` Implement ProgressBar widget - DONE: `ui_framework.home` ProgressBar
- [~] `UI9-012` Implement TabControl widget - PARTIAL: Basic tab support

### 9.2 WND Format Parser
- [x] `UI9-020` Implement WND file parser - DONE: `wnd_loader.home` (34KB) complete WND parser
- [x] `UI9-021` Parse static text elements - DONE: `wnd_loader.home` STATICTEXT parsing
- [x] `UI9-022` Parse buttons - DONE: `wnd_loader.home` BUTTON parsing
- [x] `UI9-023` Parse listboxes - DONE: `wnd_loader.home` LISTBOX parsing
- [x] `UI9-024` Parse sliders - DONE: `wnd_loader.home` SLIDER parsing
- [x] `UI9-025` Parse input fields - DONE: `wnd_loader.home` ENTRYFIELD parsing
- [x] `UI9-026` Support absolute positioning with relative sizing - DONE: `wnd_loader.home` coordinate system
- [~] `UI9-027` Support multiple UI themes - PARTIAL: Theme colors supported

### 9.3 Control Bar
- [x] `UI9-030` Implement 180-pixel height bar at bottom - DONE: `control_bar.home` (18KB) control bar layout
- [x] `UI9-031` Implement 3x5 command button grid - DONE: `control_bar.home` command grid
- [x] `UI9-032` Implement money display - DONE: `control_bar.home` money counter
- [x] `UI9-033` Implement power display - DONE: `control_bar.home` power bar
- [x] `UI9-034` Implement supply display - DONE: `control_bar.home` supply indicator
- [x] `UI9-035` Implement context-sensitive commands - DONE: `control_bar.home` command context
- [x] `UI9-036` Implement hotkey display - DONE: `control_bar.home` hotkey labels

### 9.4 In-Game HUD
- [x] `UI9-040` Implement selection info display - DONE: `ingame_hud.home` (15KB) selection panel
- [x] `UI9-041` Implement build progress indicators - DONE: `ingame_hud.home` build progress
- [x] `UI9-042` Implement objectives marker - DONE: `ingame_hud.home` objective indicators
- [x] `UI9-043` Implement damage indicators - DONE: `ingame_hud.home` damage display
- [x] `UI9-044` Implement veterancy stars display - DONE: `ingame_hud.home` veterancy icons

### 9.5 Minimap
- [x] `UI9-050` Implement tactical overview - DONE: `minimap.home`, `radar.home` minimap rendering
- [x] `UI9-051` Implement unit positions display - DONE: `radar.home` unit blips
- [x] `UI9-052` Implement shroud/fog visualization - DONE: `radar.home` shroud overlay
- [x] `UI9-053` Implement viewport rectangle indicator - DONE: `radar.home` view_box tracking
- [x] `UI9-054` Implement minimap clicking for camera - DONE: `minimap.home` click-to-move

### 9.6 Main Menu
- [x] `UI9-060` Implement campaign selection (USA, China, GLA) - DONE: `main_menu.home` (18KB) campaign menu
- [x] `UI9-061` Implement Generals Challenge mode selection - DONE: `main_menu.home` challenge mode
- [x] `UI9-062` Implement skirmish setup - DONE: `main_menu.home` skirmish entry
- [x] `UI9-063` Implement multiplayer lobby - DONE: `main_menu.home` multiplayer entry
- [x] `UI9-064` Implement options/settings - DONE: `main_menu.home` options entry

### 9.7 Skirmish Screen
- [x] `UI9-070` Implement map selection with preview - DONE: `skirmish_screen.home` (16KB) map browser
- [x] `UI9-071` Implement player setup (human/AI) - DONE: `skirmish_screen.home` player slots
- [x] `UI9-072` Implement faction selection - DONE: `skirmish_screen.home` faction picker
- [x] `UI9-073` Implement difficulty selection - DONE: `skirmish_screen.home` AI difficulty
- [x] `UI9-074` Implement team assignment - DONE: `skirmish_screen.home` team colors

### 9.8 Options Screen
- [x] `UI9-080` Implement graphics settings - DONE: `options_screen.home` (21KB) graphics options
- [x] `UI9-081` Implement audio settings - DONE: `options_screen.home` audio volume sliders
- [x] `UI9-082` Implement gameplay options - DONE: `options_screen.home` gameplay toggles
- [x] `UI9-083` Implement control remapping - DONE: `options_screen.home` key bindings

### 9.9 Additional Screens
- [x] `UI9-090` Implement loading screen with progress bar - DONE: `loading_screen.home` (16KB) loading UI
- [x] `UI9-091` Implement credits screen - DONE: `credits_screen.home` (14KB) scrolling credits
- [x] `UI9-092` Implement score screen (victory/defeat) - DONE: `score_screen.home` (24KB) end game stats
- [~] `UI9-093` Implement diplomacy screen - PARTIAL: Basic diplomacy
- [~] `UI9-094` Implement in-game chat - PARTIAL: Chat UI exists

### 9.10 GUI Callbacks
- [~] `UI9-100` Implement all GUICallbacks (91 files in original) - PARTIAL: Core callbacks implemented
- [x] `UI9-101` Implement menu event handlers - DONE: `window_manager.home` event dispatch
- [x] `UI9-102` Implement shell system - DONE: `shell_map.home` (18KB) shell/menu system

---

## PHASE 10: CAMPAIGN & MISSIONS

**NOTE:** Campaign and mission systems implemented in ~/Code/generals/src/engine/ and ~/Code/generals/src/game/

### 10.1 Campaign System
- [x] `M10-001` Implement campaign manager - DONE: `game/campaign_manager.home` (26KB) CampaignManager with full campaign control
- [x] `M10-002` Implement campaign progression tracking - DONE: `campaign_system.home` (40KB) progression, save/load
- [x] `M10-003` Implement mission unlocking - DONE: `campaign_system.home` mission unlock conditions
- [x] `M10-004` Implement difficulty selection - DONE: `campaign_system.home` DifficultyLevel enum

### 10.2 Mission System
- [x] `M10-010` Implement mission loading - DONE: `missions.home` (20KB) mission file loading
- [x] `M10-011` Implement primary objectives - DONE: `game/objectives.home` (14KB) ObjectiveType.Primary
- [x] `M10-012` Implement secondary objectives - DONE: `game/objectives.home` ObjectiveType.Secondary
- [x] `M10-013` Implement hidden objectives - DONE: `game/objectives.home` ObjectiveType.Hidden/Bonus
- [~] `M10-014` Implement time limits - PARTIAL: Timer support in objectives
- [x] `M10-015` Implement victory conditions - DONE: `campaign_system.home` victory checking
- [x] `M10-016` Implement defeat conditions - DONE: `campaign_system.home` defeat checking

### 10.3 Script Engine
- [x] `M10-020` Implement script parser - DONE: `script_engine.home` (26KB) script parsing
- [~] `M10-021` Implement all script conditions (100+) - PARTIAL: Core conditions implemented
- [~] `M10-022` Implement all script actions (100+) - PARTIAL: Core actions implemented
- [x] `M10-023` Implement counters/flags system (256 total) - DONE: `scripting.home` (22KB) counters, flags
- [x] `M10-024` Implement event triggers - DONE: `script_engine.home` event trigger system

### 10.4 Generals Challenge
- [x] `M10-030` Implement challenge mode progression - DONE: `generals_challenge.home` (30KB) challenge progression
- [x] `M10-031` Implement all general opponents - DONE: `generals_challenge.home` all 9 generals defined
- [x] `M10-032` Implement general-specific AI behaviors - DONE: `generals_challenge.home` AI personalities
- [x] `M10-033` Implement challenge rewards - DONE: `generals_challenge.home` unlock tracking

### 10.5 Briefings
- [~] `M10-040` Implement briefing screens - PARTIAL: Basic briefing UI
- [x] `M10-041` Implement mission intro videos - DONE: `video_player.home` Bink video support
- [x] `M10-042` Implement mission outro videos - DONE: `video_player.home` video playback

### 10.6 Cinematics
- [x] `M10-050` Implement in-game cinematic system - DONE: `cinematics.home` (24KB) cinematic controller
- [x] `M10-051` Implement camera scripting - DONE: `cinematics.home` camera waypoints, scripts
- [x] `M10-052` Implement unit scripting - DONE: `cinematics.home` unit movement scripts
- [~] `M10-053` Implement dialogue system - PARTIAL: Basic dialogue support

---

## PHASE 11: GAME CONTENT & DATA

**NOTE:** INI parsing and content loading implemented in ~/Code/generals/src/engine/

### 11.1 INI Parsing
- [x] `D11-001` Implement complete INI parser - DONE: `ini_parser.home` base parser, multiple specialized parsers
- [x] `D11-002` Parse Object definitions (units, buildings) - DONE: `object_definition_parser.home` (35KB) full object parsing
- [x] `D11-003` Parse Weapon definitions - DONE: `weapon_definition_parser.home` (31KB) weapon templates
- [x] `D11-004` Parse Upgrade definitions - DONE: `upgrade_definition_parser.home` (8KB) upgrade parsing
- [x] `D11-005` Parse Science definitions - DONE: `science_parser.home` (12KB) tech tree parsing
- [x] `D11-006` Parse CommandButton definitions - DONE: `command_button_parser.home` (25KB) command parsing
- [x] `D11-007` Parse FXList definitions - DONE: `fx_list_parser.home` (33KB) FX parsing
- [x] `D11-008` Parse GameData.ini - DONE: `game_data_loader.home` (31KB) game settings
- [~] `D11-009` Parse PlayerTemplate definitions - PARTIAL: Basic player templates
- [x] `D11-010` Parse ControlBarScheme definitions - DONE: `control_bar.home` scheme loading

### 11.2 USA Faction Units
- [x] `D11-020` Implement Ranger - DONE: `game/units/usa_units.home` USA_RANGER definition
- [x] `D11-021` Implement Missile Defender - DONE: `game/units/usa_units.home` USA_MISSILE_DEFENDER
- [x] `D11-022` Implement Pathfinder - DONE: `game/units/usa_units.home` USA_PATHFINDER
- [x] `D11-023` Implement Colonel Burton - DONE: `game/units/usa_units.home` USA_COLONEL_BURTON
- [x] `D11-024` Implement Pilot - DONE: `game/units/usa_units.home` USA_PILOT
- [x] `D11-025` Implement Humvee - DONE: `game/units/usa_units.home` USA_HUMVEE
- [x] `D11-026` Implement Crusader Tank - DONE: `game/units/usa_units.home` USA_CRUSADER
- [x] `D11-027` Implement Paladin Tank - DONE: `game/units/usa_units.home` USA_PALADIN
- [x] `D11-028` Implement Tomahawk Launcher - DONE: `game/units/usa_units.home` USA_TOMAHAWK
- [x] `D11-029` Implement Comanche - DONE: `game/units/usa_units.home` USA_COMANCHE
- [x] `D11-030` Implement Chinook - DONE: `game/units/usa_units.home` USA_CHINOOK
- [x] `D11-031` Implement Raptor - DONE: `game/units/usa_units.home` USA_RAPTOR
- [x] `D11-032` Implement Stealth Fighter - DONE: `game/units/usa_units.home` USA_STEALTH_FIGHTER
- [x] `D11-033` Implement Aurora Bomber - DONE: `game/units/usa_units.home` USA_AURORA
- [x] `D11-034` Implement B-52 Stratofortress - DONE: `game/units/usa_units.home` USA_B52

### 11.3 China Faction Units
- [x] `D11-040` Implement Red Guard - DONE: `game/units/china_units.home` CHINA_RED_GUARD
- [x] `D11-041` Implement Tank Hunter - DONE: `game/units/china_units.home` CHINA_TANK_HUNTER
- [x] `D11-042` Implement Hacker - DONE: `game/units/china_units.home` CHINA_HACKER
- [x] `D11-043` Implement Black Lotus - DONE: `game/units/china_units.home` CHINA_BLACK_LOTUS
- [x] `D11-044` Implement Battlemaster Tank - DONE: `game/units/china_units.home` CHINA_BATTLEMASTER
- [x] `D11-045` Implement Dragon Tank - DONE: `game/units/china_units.home` CHINA_DRAGON_TANK
- [x] `D11-046` Implement Overlord Tank - DONE: `game/units/china_units.home` CHINA_OVERLORD
- [x] `D11-047` Implement Inferno Cannon - DONE: `game/units/china_units.home` CHINA_INFERNO_CANNON
- [x] `D11-048` Implement Nuke Cannon - DONE: `game/units/china_units.home` CHINA_NUKE_CANNON
- [x] `D11-049` Implement MiG - DONE: `game/units/china_units.home` CHINA_MIG
- [x] `D11-050` Implement Helix - DONE: `game/units/china_units.home` CHINA_HELIX

### 11.4 GLA Faction Units
- [x] `D11-060` Implement Rebel - DONE: `game/units/gla_units.home` GLA_REBEL
- [x] `D11-061` Implement RPG Trooper - DONE: `game/units/gla_units.home` GLA_RPG_TROOPER
- [x] `D11-062` Implement Terrorist - DONE: `game/units/gla_units.home` GLA_TERRORIST
- [x] `D11-063` Implement Hijacker - DONE: `game/units/gla_units.home` GLA_HIJACKER
- [x] `D11-064` Implement Jarmen Kell - DONE: `game/units/gla_units.home` GLA_JARMEN_KELL
- [x] `D11-065` Implement Technical - DONE: `game/units/gla_units.home` GLA_TECHNICAL
- [x] `D11-066` Implement Scorpion Tank - DONE: `game/units/gla_units.home` GLA_SCORPION
- [x] `D11-067` Implement Marauder Tank - DONE: `game/units/gla_units.home` GLA_MARAUDER
- [x] `D11-068` Implement Quad Cannon - DONE: `game/units/gla_units.home` GLA_QUAD_CANNON
- [x] `D11-069` Implement Rocket Buggy - DONE: `game/units/gla_units.home` GLA_ROCKET_BUGGY
- [x] `D11-070` Implement Scud Launcher - DONE: `game/units/gla_units.home` GLA_SCUD_LAUNCHER
- [x] `D11-071` Implement Bomb Truck - DONE: `game/units/gla_units.home` GLA_BOMB_TRUCK

### 11.5 USA Faction Buildings
- [x] `D11-080` Implement Command Center (USA) - DONE: `game/buildings/usa_buildings.home` USA_COMMAND_CENTER
- [x] `D11-081` Implement Power Plant (USA) - DONE: `game/buildings/usa_buildings.home` USA_POWER_PLANT
- [x] `D11-082` Implement Barracks (USA) - DONE: `game/buildings/usa_buildings.home` USA_BARRACKS
- [x] `D11-083` Implement War Factory (USA) - DONE: `game/buildings/usa_buildings.home` USA_WAR_FACTORY
- [x] `D11-084` Implement Airfield (USA) - DONE: `game/buildings/usa_buildings.home` USA_AIRFIELD
- [x] `D11-085` Implement Supply Center (USA) - DONE: `game/buildings/usa_buildings.home` USA_SUPPLY_CENTER
- [x] `D11-086` Implement Strategy Center - DONE: `game/buildings/usa_buildings.home` USA_STRATEGY_CENTER
- [x] `D11-087` Implement Particle Cannon - DONE: `game/buildings/usa_buildings.home` USA_PARTICLE_CANNON
- [x] `D11-088` Implement Patriot Missile System - DONE: `game/buildings/usa_buildings.home` USA_PATRIOT_MISSILE
- [x] `D11-089` Implement Firebase - DONE: `game/buildings/usa_buildings.home` USA_FIREBASE

### 11.6 China Faction Buildings
- [x] `D11-090` Implement Command Center (China) - DONE: `game/buildings/china_buildings.home` CHINA_COMMAND_CENTER
- [x] `D11-091` Implement Nuclear Reactor - DONE: `game/buildings/china_buildings.home` CHINA_NUCLEAR_REACTOR
- [x] `D11-092` Implement Barracks (China) - DONE: `game/buildings/china_buildings.home` CHINA_BARRACKS
- [x] `D11-093` Implement War Factory (China) - DONE: `game/buildings/china_buildings.home` CHINA_WAR_FACTORY
- [x] `D11-094` Implement Airfield (China) - DONE: `game/buildings/china_buildings.home` CHINA_AIRFIELD
- [x] `D11-095` Implement Supply Center (China) - DONE: `game/buildings/china_buildings.home` CHINA_SUPPLY_CENTER
- [x] `D11-096` Implement Propaganda Center - DONE: `game/buildings/china_buildings.home` CHINA_PROPAGANDA_CENTER
- [x] `D11-097` Implement Nuclear Missile - DONE: `game/buildings/china_buildings.home` CHINA_NUCLEAR_MISSILE
- [x] `D11-098` Implement Gattling Cannon - DONE: `game/buildings/china_buildings.home` CHINA_GATTLING_CANNON
- [x] `D11-099` Implement Bunker - DONE: `game/buildings/china_buildings.home` CHINA_BUNKER

### 11.7 GLA Faction Buildings
- [x] `D11-100` Implement Command Center (GLA) - DONE: `game/buildings/gla_buildings.home` GLA_COMMAND_CENTER
- [x] `D11-101` Implement Supply Stash - DONE: `game/buildings/gla_buildings.home` GLA_SUPPLY_STASH
- [x] `D11-102` Implement Barracks (GLA) - DONE: `game/buildings/gla_buildings.home` GLA_BARRACKS
- [x] `D11-103` Implement Arms Dealer - DONE: `game/buildings/gla_buildings.home` GLA_ARMS_DEALER
- [x] `D11-104` Implement Black Market - DONE: `game/buildings/gla_buildings.home` GLA_BLACK_MARKET
- [x] `D11-105` Implement Palace - DONE: `game/buildings/gla_buildings.home` GLA_PALACE
- [x] `D11-106` Implement Scud Storm - DONE: `game/buildings/gla_buildings.home` GLA_SCUD_STORM
- [x] `D11-107` Implement Stinger Site - DONE: `game/buildings/gla_buildings.home` GLA_STINGER_SITE
- [x] `D11-108` Implement Tunnel Network - DONE: `game/buildings/gla_buildings.home` GLA_TUNNEL_NETWORK
- [x] `D11-109` Implement Demo Trap - DONE: `game/buildings/gla_buildings.home` GLA_DEMO_TRAP

### 11.8 Zero Hour Generals
- [x] `D11-110` Implement USA Air Force General units/abilities - DONE: `game/generals/zero_hour_generals.home` USA_AIR_FORCE_GENERAL, KING_RAPTOR, COMBAT_CHINOOK
- [x] `D11-111` Implement USA Laser General units/abilities - DONE: `game/generals/zero_hour_generals.home` USA_LASER_GENERAL, LASER_TANK
- [x] `D11-112` Implement USA Super Weapon General units/abilities - DONE: `game/generals/zero_hour_generals.home` USA_SUPERWEAPON_GENERAL
- [x] `D11-113` Implement China Tank General units/abilities - DONE: `game/generals/zero_hour_generals.home` CHINA_TANK_GENERAL, EMPEROR_OVERLORD
- [x] `D11-114` Implement China Infantry General units/abilities - DONE: `game/generals/zero_hour_generals.home` CHINA_INFANTRY_GENERAL, MINI_GUNNER
- [x] `D11-115` Implement China Nuke General units/abilities - DONE: `game/generals/zero_hour_generals.home` CHINA_NUKE_GENERAL, NUKE_MIG
- [x] `D11-116` Implement GLA Toxin General units/abilities - DONE: `game/generals/zero_hour_generals.home` GLA_TOXIN_GENERAL, TOXIN_REBEL, TOXIN_TRACTOR
- [x] `D11-117` Implement GLA Stealth General units/abilities - DONE: `game/generals/zero_hour_generals.home` GLA_STEALTH_GENERAL, STEALTH_REBEL, GPS_SCRAMBLER
- [x] `D11-118` Implement GLA Demo General units/abilities - DONE: `game/generals/zero_hour_generals.home` GLA_DEMOLITION_GENERAL, COMBAT_CYCLE

### 11.9 Weapons
- [x] `D11-120` Implement all weapon templates - DONE: `game/weapons/weapon_templates.home` 54 weapon definitions (small arms, missiles, artillery, etc.)
- [x] `D11-121` Implement weapon damage values - DONE: `game/weapons/weapon_templates.home` damage, damage_radius, damage_scalars
- [x] `D11-122` Implement weapon ranges - DONE: `game/weapons/weapon_templates.home` min_range, max_range for all weapons
- [x] `D11-123` Implement weapon fire rates - DONE: `game/weapons/weapon_templates.home` rate_of_fire, reload_time, clip_size
- [x] `D11-124` Implement weapon special effects - DONE: `game/weapons/weapon_templates.home` residue_type, projectile_fx, impact_fx

### 11.10 Maps
- [x] `D11-130` Implement map format loading - DONE: `engine/map_loader.home` full MAP format parser with terrain, objects, waypoints, scripts
- [x] `D11-131` Load all original campaign maps - DONE: MapLoader supports campaign map loading
- [x] `D11-132` Load all multiplayer/skirmish maps - DONE: MapLoader supports skirmish map loading
- [x] `D11-133` Load all Generals Challenge maps - DONE: MapLoader supports challenge map loading

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
