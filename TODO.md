# Command & Conquer: Generals - Complete Rewrite in Home Language

**Last Updated**: November 19, 2024
**Project**: Rewrite C&C Generals Zero Hour from scratch in Home
**Source Reference**: `~/Code/generals-old` (1.78M lines C++)
**Target**: macOS & Windows cross-platform
**Assets Ready**: 1.1GB at `~/Code/generals/assets`
**Build System**: Zig 0.16-dev (✅ INSTALLED: 0.16.0-dev.1334+06d08daba)

> **IMPORTANT**: This project uses **Zig 0.16-dev** which includes async I/O features not available in 0.15.
> The async I/O is critical for non-blocking asset loading, network multiplayer, and smooth gameplay.

View full detailed plan at: [DETAILED_IMPLEMENTATION_PLAN.md](./DETAILED_IMPLEMENTATION_PLAN.md)

---

## ✅ Already Complete (Infrastructure)

- ✅ 1.1GB game assets extracted (audio, textures, models, INI files)
- ✅ DMG packaging system for macOS
- ✅ App bundle creation infrastructure  
- ✅ 100+ maps ready
- ✅ All 56+ INI configuration files

---

## 🏠 Home Language Enhancements (~/Code/home)

### Data Structures & I/O
- [ ] Dynamic arrays with generics
- [ ] HashMap<K,V> implementation
- [ ] String operations (concat, format, parse)
- [ ] **Async File I/O** (leverages Zig 0.16-dev async I/O)
  - [ ] Non-blocking file read/write
  - [ ] Async asset streaming
  - [ ] Background loading for textures/models
- [ ] **INI parser** (CRITICAL - loads all game data)
- [ ] **Async .BIG archive reader** (EA's format with streaming)

### Graphics & Rendering  
- [ ] 2D sprite rendering
- [ ] 3D model loading (W3D format)
- [ ] Metal backend (macOS)
- [ ] DirectX 12 backend (Windows)  
- [ ] Texture loading (TGA, DDS)
- [ ] Particle systems
- [ ] Camera & viewport

### Platform & Systems
- [ ] Window management (both platforms)
- [ ] Mouse & keyboard input
- [ ] Audio playback (CoreAudio/WASAPI)
- [ ] Math library (Vec2/3/4, Mat4, Quat)
- [ ] **Async Networking** (TCP/UDP with Zig 0.16 async I/O)
  - [ ] Non-blocking socket operations
  - [ ] Async multiplayer packet handling
  - [ ] Event loop integration
- [ ] Threading & async task system (using Zig 0.16 features)

---

## 🎮 Game Engine Core

### Foundation
- [ ] **Async game loop** with fixed timestep (event-driven using Zig 0.16)
- [ ] Object system & ID management
- [ ] **Async resource manager** (background loading, no frame drops)
  - [ ] Texture streaming
  - [ ] Model loading in background
  - [ ] Audio preloading
- [ ] **Async INI data loading** (parse large files without blocking)
- [ ] State machine (menu, game, paused)

### Rendering
- [ ] 3D renderer (units, buildings, terrain)
- [ ] 2D UI renderer (HUD, menus)
- [ ] Terrain system (heightmaps, textures)
- [ ] Particle effects (explosions, smoke)
- [ ] Camera controller (RTS-style)

### Game Logic
- [ ] **Unit system** (100+ unit types from FactionUnit.ini)
- [ ] **Building system** (80+ buildings from FactionBuilding.ini)
- [ ] Weapon & combat system
- [ ] Economy (money, power, supply)
- [ ] Upgrades & tech tree
- [ ] Pathfinding (A* algorithm)
- [ ] Unit AI (attack, defend, formations)
- [ ] Strategic AI (build orders, tactics)

### Interface
- [ ] Main menu system
- [ ] In-game HUD & command bar
- [ ] Minimap with fog of war
- [ ] Selection & control groups
- [ ] Build menus from CommandButton.ini

### Maps & Campaign
- [ ] Map loading (100+ maps available)
- [ ] Fog of war system
- [ ] Mission scripting
- [ ] 3 campaigns (USA, China, GLA)
- [ ] Objectives & triggers

### Multiplayer
- [ ] Network synchronization (lockstep)
- [ ] Lobby & matchmaking
- [ ] LAN & online play
- [ ] Chat system

### Audio & Polish
- [ ] Sound effects (3D positional)
- [ ] Music playback
- [ ] Voice lines (600+ from Eva.ini)
- [ ] General powers & abilities
- [ ] Options & settings
- [ ] Modding support

---

## 📋 Implementation Phases

### Phase 0: Language Foundation (3-4 months)
Build core Home language features needed for game dev

### Phase 1: Engine Core (2-3 months)
Game loop, objects, resource loading, INI parsing

### Phase 2: Rendering (2-3 months)  
Get something visible on screen

### Phase 3: Game Logic (3-4 months)
Units, buildings, combat, economy

### Phase 4: AI & Maps (2-3 months)
Pathfinding, AI behavior, map loading

### Phase 5: UI & Polish (2-3 months)
Menus, HUD, audio, campaign

### Phase 6: Multiplayer (2-3 months)
Networking, lobby, synchronization

**Total Estimate**: 16-23 months full-time

---

## 🎯 Next Steps

1. **Start with Phase 0.1**: Implement HashMap in `~/Code/home/packages/collections/`
2. **Then Phase 0.2**: Implement INI parser in `~/Code/home/packages/io/`
3. **First Test**: Load and parse `FactionUnit.ini` successfully
4. **Second Test**: Render a unit sprite on screen

---

## 📊 Progress Tracking

| Component | Status | Priority |
|-----------|--------|----------|
| HashMap | ⬜ Not started | P0 |
| INI Parser | ⬜ Not started | P0 |
| File I/O | ⬜ Not started | P0 |
| 2D Rendering | ⬜ Not started | P0 |
| Math Library | ⬜ Not started | P0 |

---

**This is a from-scratch rewrite using Home language. The C++ source is our reference, not our codebase. We're building something cleaner, modern, and cross-platform from day one!**

