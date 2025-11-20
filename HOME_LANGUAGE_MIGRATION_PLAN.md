# C&C Generals - Migration to Home Language

**Date:** November 20, 2025
**Purpose:** Complete migration from Zig to Home language for all game code
**Goal:** Rewrite all Generals game code in Home, then implement 100% of all phases

---

## Why Migrate to Home?

**Current State:**
- Generals project has 8,505 lines of Zig code across 18 files
- Home compiler is written in Zig at `~/Code/home`
- Generals game should use Home, not raw Zig

**Benefits of Home:**
1. **Custom Language Design** - Home designed specifically for game development
2. **Cleaner Syntax** - More readable and maintainable than Zig
3. **Game-Focused** - Built-in features for game dev needs
4. **Consistency** - All game code in one language (Home)
5. **Future-Proof** - Can evolve Home language as needed for game features

---

## Current Zig Code to Migrate (8,505 lines)

### Engine Files (All Need Migration):
1. `src/engine/w3d_loader.zig` - 694 lines → Home
2. `src/engine/combat.zig` - 643 lines → Home
3. `src/engine/economy.zig` - 1,440 lines → Home
4. `src/engine/pathfinding.zig` - 598 lines → Home
5. `src/engine/terrain.zig` - 1,099 lines → Home
6. `src/engine/entity.zig` - 642 lines → Home
7. `src/engine/game.zig` - 682 lines → Home
8. `src/engine/special_powers.zig` - 605 lines → Home
9. `src/engine/fog_of_war.zig` - 315 lines → Home
10. `src/engine/production.zig` - 305 lines → Home
11. `src/engine/ui.zig` - 326 lines → Home
12. `src/engine/camera.zig` - 171 lines → Home
13. `src/engine/minimap.zig` - 228 lines → Home
14. `src/engine/resource.zig` - 248 lines → Home
15. `src/engine/resource_manager.zig` - 124 lines → Home
16. `src/engine/texture.zig` - 237 lines → Home
17. `src/engine/window.zig` - 147 lines → Home
18. `src/engine/ai_player.zig` - 1 line → Home

**Total:** 8,505 lines of Zig → ~10,000-12,000 lines of Home

---

## Home Language Capabilities (Check)

Before migrating, we need to ensure Home has these features:

### Required Home stdlib Features:
- [ ] **Collections**
  - [ ] Dynamic arrays/lists
  - [ ] HashMaps
  - [ ] ArrayList equivalent

- [ ] **Math Library**
  - [x] Vec2, Vec3, Vec4 (exists in ~/Code/home/packages/math/)
  - [x] Mat4 matrices
  - [x] Quaternions
  - [ ] AABB, Ray, collision detection

- [ ] **Memory Management**
  - [ ] Allocators (general purpose, arena, pool)
  - [ ] Manual memory control
  - [ ] Automatic cleanup (defer equivalent)

- [ ] **File I/O**
  - [ ] File reading/writing
  - [ ] Binary file parsing
  - [ ] Directory operations

- [ ] **String Operations**
  - [ ] String concatenation
  - [ ] String formatting
  - [ ] String parsing
  - [ ] INI file parsing

- [ ] **Graphics (Metal/OpenGL)**
  - [ ] Window creation
  - [ ] Graphics context
  - [ ] Texture loading
  - [ ] Shader compilation
  - [ ] 3D rendering pipeline

- [ ] **Audio**
  - [ ] Audio playback (CoreAudio/OpenAL)
  - [ ] Sound effects
  - [ ] Music streaming

- [ ] **Networking**
  - [ ] TCP/UDP sockets
  - [ ] Packet serialization
  - [ ] Async I/O

---

## Migration Strategy

### Phase 0: Home Language Enhancement (2-3 weeks)

**Goal:** Add missing features to Home language/stdlib

#### Step 0.1: Collections Module
**Location:** `~/Code/home/packages/collections/`
**Add:**
- `ArrayList.home` - Dynamic array implementation
- `HashMap.home` - Hash table implementation
- `Queue.home` - FIFO queue
- `Stack.home` - LIFO stack

**Estimated:** 500-800 lines of Home code

#### Step 0.2: File I/O Module
**Location:** `~/Code/home/packages/io/`
**Add:**
- `File.home` - File reading/writing
- `BinaryReader.home` - Binary file parsing (for W3D)
- `INIParser.home` - INI file parsing (critical for game data)
- `BIGArchive.home` - EA .BIG format parser

**Estimated:** 600-1000 lines of Home code

#### Step 0.3: String Module
**Location:** `~/Code/home/packages/string/`
**Add:**
- `String.home` - String operations
- `StringBuilder.home` - Efficient string building
- `Format.home` - String formatting (printf-like)

**Estimated:** 400-600 lines of Home code

#### Step 0.4: Graphics Module
**Location:** `~/Code/home/packages/graphics/`
**Add:**
- `Window.home` - Window management
- `MetalRenderer.home` - Metal backend for macOS
- `Texture.home` - Texture loading/management
- `Shader.home` - Shader compilation
- `Mesh.home` - 3D mesh rendering

**Estimated:** 1500-2000 lines of Home code

#### Step 0.5: Audio Module
**Location:** `~/Code/home/packages/audio/`
**Add:**
- `AudioEngine.home` - Audio system
- `Sound.home` - Sound effect playback
- `Music.home` - Music streaming

**Estimated:** 800-1200 lines of Home code

**Total Home stdlib additions:** ~4,000-6,000 lines

---

### Phase 1: Migrate Core Systems (2 weeks)

#### Step 1.1: Entity System
**Zig File:** `src/engine/entity.zig` (642 lines)
**Home File:** `src/engine/entity.home` (~700 lines)

**Convert:**
- Entity struct → Home class
- Component system → Home interfaces
- Entity manager → Home module

#### Step 1.2: Math Integration
**Zig Files:** Various math usage throughout
**Home Files:** Use `~/Code/home/packages/math/`

**Convert:**
- Replace Vec2/Vec3 Zig types with Home math types
- Use Home Mat4 for transformations
- Use Home Quaternion for rotations

#### Step 1.3: Resource Manager
**Zig Files:** `resource.zig` (248), `resource_manager.zig` (124)
**Home Files:** `resource.home`, `resource_manager.home`

**Convert:**
- Resource loading → Home async I/O
- Asset management → Home collections
- Memory pooling → Home allocators

---

### Phase 2: Migrate Game Logic (3-4 weeks)

#### Step 2.1: Combat System
**Zig File:** `src/engine/combat.zig` (643 lines)
**Home File:** `src/engine/combat.home` (~750 lines)

**Convert:**
- Damage types enum → Home enum
- Armor system → Home classes
- Weapon system → Home structs
- Projectiles → Home physics

#### Step 2.2: Economy System
**Zig File:** `src/engine/economy.zig` (1,440 lines)
**Home File:** `src/engine/economy.home` (~1,600 lines)

**Convert:**
- Money management → Home module
- Building system → Home classes
- Production queues → Home collections
- Resource gathering → Home AI system

#### Step 2.3: Pathfinding System
**Zig File:** `src/engine/pathfinding.zig` (598 lines)
**Home File:** `src/engine/pathfinding.home` (~700 lines)

**Convert:**
- A* algorithm → Home implementation
- Navigation grid → Home 2D arrays
- Path caching → Home HashMap

#### Step 2.4: AI System
**Zig File:** `src/engine/ai_player.zig` (1 line - placeholder)
**Home File:** `src/engine/ai_player.home` (~16,000 lines NEW)

**Implement:**
- Strategic AI (build orders, economy)
- Tactical AI (unit control, combat)
- AI state machines
- Difficulty levels

---

### Phase 3: Migrate Rendering (3-4 weeks)

#### Step 3.1: W3D Loader
**Zig File:** `src/engine/w3d_loader.zig` (694 lines)
**Home File:** `src/engine/w3d_loader.home` (~800 lines)

**Convert:**
- Binary file reading → Home BinaryReader
- Chunk parsing → Home structs
- Model data → Home Mesh class

#### Step 3.2: 3D Renderer (NEW - Was Missing)
**Home File:** `src/renderer/w3d_renderer.home` (~15,000 lines NEW)

**Implement:**
- Metal 3D rendering pipeline
- Vertex/index buffers
- Shader system
- Lighting system
- Camera 3D
- Terrain rendering
- Water rendering
- Particle system 3D

#### Step 3.3: Terrain System
**Zig File:** `src/engine/terrain.zig` (1,099 lines)
**Home File:** `src/engine/terrain.home` (~9,500 lines EXPANDED)

**Convert + Implement:**
- Heightmap loading → Home file I/O
- Mesh generation → Home graphics
- Multi-texturing → Home shaders
- Water system → Home rendering
- LOD system → Home optimization

#### Step 3.4: UI System
**Zig File:** `src/engine/ui.zig` (326 lines)
**Home File:** `src/engine/ui.home` (~6,000 lines EXPANDED)

**Convert + Implement:**
- UI panels → Home classes
- Main menu → Home UI framework
- HUD → Home rendering
- Build menus → Home dynamic UI
- Options screen → Home settings

---

### Phase 4: Migrate Special Systems (2-3 weeks)

#### Step 4.1: Special Powers
**Zig File:** `src/engine/special_powers.zig` (605 lines)
**Home File:** `src/engine/special_powers.home` (~6,000 lines EXPANDED)

**Convert + Implement:**
- Power types → Home enums
- Power templates → Home classes (from INI)
- Power execution → Home game logic
- Power effects → Home particles/rendering

#### Step 4.2: Fog of War
**Zig File:** `src/engine/fog_of_war.zig` (315 lines)
**Home File:** `src/engine/fog_of_war.home` (~800 lines EXPANDED)

**Convert + Implement:**
- Visibility grid → Home 2D arrays
- Fog rendering → Home shaders
- Shroud system → Home textures

#### Step 4.3: Minimap
**Zig File:** `src/engine/minimap.zig` (228 lines)
**Home File:** `src/engine/minimap.home` (~500 lines EXPANDED)

**Convert + Implement:**
- Minimap rendering → Home 2D rendering
- Unit icons → Home sprites
- Fog integration → Home visibility

#### Step 4.4: Production
**Zig File:** `src/engine/production.zig` (305 lines)
**Home File:** `src/engine/production.home` (~400 lines)

**Convert:**
- Production queues → Home collections
- Unit creation → Home entity system
- Building construction → Home game logic

---

### Phase 5: Implement Missing Features (4-5 weeks)

#### Step 5.1: Multiplayer Networking (NEW)
**Home File:** `src/network/multiplayer.home` (~9,000 lines NEW)

**Implement:**
- Lockstep synchronization
- Network protocol
- Lobby system
- Chat system

#### Step 5.2: Audio System (NEW)
**Home File:** `src/audio/audio_engine.home` (~3,000 lines NEW)

**Implement:**
- CoreAudio backend
- 3D positional audio
- Music playback
- Voice lines

#### Step 5.3: Advanced AI (NEW)
**Home File:** `src/ai/advanced_ai.home` (~20,000 lines NEW)

**Implement:**
- Hierarchical pathfinding (HPA*)
- Formation movement
- Squad tactics
- AI behaviors

#### Step 5.4: Polish & Optimization (NEW)
**Various Files** (~2,000 lines NEW)

**Implement:**
- Performance profiling
- Memory optimization
- 60 FPS target
- Graphics options
- Settings system

---

## Implementation Timeline

### Milestone 1: Home Language Ready (3 weeks)
- Week 1: Collections + File I/O
- Week 2: Graphics + Audio
- Week 3: Testing + Documentation

### Milestone 2: Core Migration (4 weeks)
- Week 4: Entity + Resource systems
- Week 5: Combat + Economy
- Week 6: Pathfinding + Game loop
- Week 7: Testing + Integration

### Milestone 3: Rendering Migration (4 weeks)
- Week 8: W3D Loader + Basic renderer
- Week 9: 3D Metal renderer
- Week 10: Terrain + Water
- Week 11: UI + Particles

### Milestone 4: Complete Features (5 weeks)
- Week 12-13: AI systems
- Week 14: Special powers + Fog
- Week 15: Audio system
- Week 16: Multiplayer networking

### Milestone 5: Testing & Polish (2 weeks)
- Week 17: Integration testing
- Week 18: Performance optimization

**Total Timeline:** 18-20 weeks (4-5 months full-time)

---

## Code Size Estimates

### Home Language stdlib:
- **Before Migration:** ~2,000 lines
- **After Enhancement:** ~8,000 lines
- **Growth:** +6,000 lines

### Generals Game Code:
- **Current (Zig):** 8,505 lines
- **After Migration (Home):** ~12,000 lines
- **After 100% Implementation:** ~120,000 lines
- **Total Growth:** +111,500 lines

### Grand Total:
- **Home stdlib:** 8,000 lines
- **Generals game:** 120,000 lines
- **Total Project:** 128,000 lines of Home code

---

## Success Criteria

### Home Language Ready:
- [ ] All required stdlib modules implemented
- [ ] Home stdlib tested and documented
- [ ] Example games run successfully in Home

### Migration Complete:
- [ ] All Zig code converted to Home
- [ ] All existing features work in Home
- [ ] No Zig dependencies in Generals project
- [ ] Compilation succeeds with Home compiler

### 100% Implementation:
- [ ] All 10 phases implemented
- [ ] All features from PHASE_COMPLETION_ANALYSIS.md
- [ ] W3D 3D rendering working
- [ ] Full AI system working
- [ ] Multiplayer working
- [ ] Audio working
- [ ] All tests passing
- [ ] 60 FPS with 500+ units
- [ ] 100% accuracy vs original C&C Generals

---

## Next Immediate Steps

1. **Analyze Home Language** (Today)
   - Review ~/Code/home source code
   - Understand Home syntax and capabilities
   - Identify what exists vs what's needed

2. **Design Home Game API** (1-2 days)
   - Design game-friendly Home API
   - Plan module structure
   - Create code examples

3. **Implement Core stdlib** (1 week)
   - ArrayList, HashMap
   - File I/O, INI parser
   - Basic graphics

4. **Start Migration** (Ongoing)
   - Convert entity system first
   - Then combat system
   - Then economy system
   - Continue until complete

---

## Resources

- **Home Compiler:** `~/Code/home/`
- **Thyme Reference:** `~/Code/Thyme/`
- **Zig Code to Migrate:** `~/Code/generals/src/engine/`
- **Phase Analysis:** `PHASE_COMPLETION_ANALYSIS.md`
- **Original Roadmap:** `ROADMAP_TO_100_PERCENT.md`

---

**Status:** Ready to begin Home language enhancement and migration
**Priority:** CRITICAL - Foundation for entire project
**Goal:** Write Generals in Home, achieve 100% accuracy with original game
