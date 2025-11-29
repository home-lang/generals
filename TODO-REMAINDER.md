# C&C Generals Zero Hour - Home Language Port
## Complete TODO List for Matching Original Game

This document catalogs ALL remaining work needed to achieve a fully functional C&C Generals Zero Hour game in the Home programming language that matches the original.

---

## PHASE 1: CRITICAL COMPILER BUGS (Must Fix First)

### 1.1 Memory Management Bugs
- [x] Double-free bug in for-loop iterator handling (FIXED: removed errdefer)
- [x] Stack offset integer overflow protection (FIXED: skip zero-length allocations in deinit)
- [ ] Memory leak in type checker (shown in error output)

### 1.2 Parser Critical Fixes
- [x] **Fix `if !optional` syntax** - Parser sees `if` as field name in struct context
  - Location: src/game/unit.home:550, src/game/building.home:526
  - Issue: `if !def { return null }` fails to parse
  - FIXED: Unary ! operator now allows optional types (returns Bool indicating if null)

- [x] **Fix module resolution during type checking**
  - Issue: Imported modules couldn't resolve their own imports (source root not set)
  - FIXED: Added setSourceRoot calls in checkCommand, runCommand, testCommand, and processImport in type_system.zig

- [x] **Support pattern matching on MemberExpr**
  - Issue: Cannot match on `Type::Variant` or `enum.field`
  - Occurrences: 40+ instances across codebase
  - VERIFIED: Already works - tested with `match m { Mode::A => ... }`

- [x] **Implement ArrayRepeat expression `[value; count]`**
  - Location: ui/ui_framework.home and others
  - VERIFIED: Already works - tested with `let arr = [0; 256]`

---

## PHASE 2: TYPE SYSTEM FIXES

### 2.1 Module Path Type Resolution
- [x] **Fix `module::Type` resolution in type annotations**
  - Issue: `kindof::KindOfMask`, `thing::Thing`, `player::Player` etc. not resolving
  - Affects: 30+ type references
  - FIXED: parseTypeName now extracts type name after :: and looks up in environment

### 2.2 Generic Type Support
- [x] **Implement `Vec<T>` generic collection type**
  - Missing: `Vec<TerrainTypeEntry>`, `Vec<i32>`, `Vec<Coord3D>`, etc.
  - VERIFIED: parseTypeName handles Vec<T>, Array<T>, List<T> - treats as array types

- [x] **Support complex generic instantiations**
  - `Vec<TerrainTypeEntry>`, `Vec<ICoord2D>`, etc.
  - VERIFIED: Type parser handles nested generic types

### 2.3 String and Collection Method Type Inference
- [x] **Add string method type inference**
  - Methods like `contains()`, `starts_with()`, `ends_with()` return Bool
  - Methods like `len()`, `find()` return Int
  - Methods like `trim()`, `replace()` return String
  - FIXED: Added method type inference in inferCallExpression for String and Array types

### 2.4 Optional Type Handling
- [x] **Fix optional type conditionals**
  - Issue: `if !optional_var` doesn't work properly
  - Need: Proper truthiness checking for `?T` types
  - FIXED: Optional types now allowed in if/while conditions, ?T type annotation parsing, null literal coercion

- [x] **Implement optional chaining operators**
  - `?.` safe navigation operator - VERIFIED: Already works
  - `??` null coalescing operator - FIXED: Type checking now uses canCoerce for Int literal coercion

### 2.4 Pointer and Reference Types
- [x] **Support `mut T` mutable parameter syntax**
  - Occurrences: `mut Particle`, `mut ParticleEmitter`, `mut ParticleSystem`
  - FIXED: parseTypeName now handles `mut T` prefix for mutable by-value parameters

### 2.5 Stdlib Type Integration
- [x] **Add Zig stdlib type imports**
  - Issue: `std.fs.File`, `Allocator` from Zig not resolving
  - FIXED: parseTypeName now treats `std.*` paths as opaque struct types

---

## PHASE 3: CODEGEN IMPROVEMENTS

### 3.1 Assignment Targets
- [x] **Support tuple destructuring assignments**
  - Issue: "Assignment target must be an identifier, member expression, or dereference"
  - FIXED: Parser now allows TupleExpr as assignment target, codegen handles tuple destructuring

### 3.2 Expression Support
- [x] **Implement RangeExpr as standalone value**
  - Issue: "RangeExpr can only be used in for loop iterables"
  - VERIFIED: Already works - tested with `let range = 0..10`

### 3.3 Struct and Enum Improvements
- [x] **Fix struct field resolution**
  - Issue: "Field format not found in struct Texture"
  - VERIFIED: Struct field access works correctly, no errors found

- [x] **Implement enum variant data access**
  - For `Option::Some(value)`, `Result::Ok(data)` patterns
  - FIXED: inferStaticCallExpression now handles enum variant constructors like Result::Ok(value)

- [x] **Fix Vec<T> constructor syntax**
  - Issue: `Vec<i32> {}` was not recognized as valid type
  - FIXED: inferStructLiteral now uses parseTypeName for generic types

---

## PHASE 4: MISSING LANGUAGE FEATURES

### 4.1 Advanced Pattern Matching
- [x] **Match on enum variants with data**
  - `match result { Ok(val) => ..., Err(e) => ... }`
  - VERIFIED: Pattern matching with enum variant data extraction works

- [x] **Match on nested structures**
  - `match point { Point { x: 0, y } => ... }`
  - FIXED: Added struct literal shorthand support in parser (both parsing locations)

- [ ] **Match guards**
  - `match val { x if x > 10 => ... }`
  - SKIPPED: Not used in codebase, not blocking compilation

### 4.2 Type Inference Improvements
- [x] **Infer generic type parameters**
  - `Vec::new()` should infer `T` from usage
  - VERIFIED: Works - tested Vec::new() with return type inference

- [x] **Infer lambda/closure types**
  - `array.map(|x| x * 2)` should infer parameter types
  - VERIFIED: Works - lambdas with typed parameters compile correctly

### 4.3 Trait System
- [ ] **Define and implement traits**
  - Need `trait` keyword support (partially there)
  - Need `impl Trait for Type` support

- [ ] **Trait bounds on generics**
  - `fn foo<T: Display>(x: T)` syntax

---

## PHASE 5: GAME ENGINE IMPLEMENTATION

### 5.1 Core Engine Systems (Partially Implemented)
- [ ] **Fix and complete ECS (Entity Component System)**
  - Files: engine/ecs.home, engine/entity.home
  - Status: Basic structure exists, needs completion

- [ ] **Complete renderer implementation**
  - Files: engine/renderer.home, engine/metal_renderer.home
  - Missing types: IndexType, UniformInfo, VertexLayout, VertexAttribute, VertexFormat
  - Need: Full Metal API bindings

- [ ] **Implement particle system**
  - Files: engine/particle_system.home, engine/effects.home
  - Issues: Pattern matching on effects, mutable particle references

- [ ] **Complete camera system**
  - Files: engine/camera.home
  - Status: Partial implementation

### 5.2 Game Logic Systems
- [ ] **Unit system**
  - Files: game/unit.home, engine/unit_system.home, engine/unit_behaviors.home
  - Critical: Fix parse error at line 550 first

- [ ] **Building system**
  - Files: game/building.home, engine/building_system.home, engine/structures.home
  - Critical: Fix parse error at line 526 first

- [ ] **Combat system**
  - Files: engine/combat.home, engine/damage.home, engine/weapon.home, engine/projectile.home
  - Status: Skeleton implementations

- [ ] **AI system**
  - Files: engine/ai.home, engine/ai_player.home, engine/ai_strategies.home
  - Files: engine/pathfinding.home, engine/hpa_pathfinding.home, engine/flowfield.home
  - Status: Not implemented

### 5.3 World and Map Systems
- [ ] **Terrain system**
  - Files: engine/terrain.home
  - Issues: Vec<TerrainTypeEntry> not working

- [ ] **Map system**
  - Files: engine/map_system.home, engine/map_pack.home
  - Status: Partial

- [ ] **Fog of war**
  - Files: engine/fog_of_war.home
  - Status: Not implemented

- [ ] **Weather system**
  - Files: engine/weather.home
  - Status: Stub only

### 5.4 UI and Shell Systems
- [ ] **Menu system**
  - Files: shell/menu_system.home, shell/wnd_parser_enhanced.home, shell/wnd_elements.home
  - Status: Partial WND file parser

- [ ] **Minimap**
  - Files: ui/minimap.home
  - Status: Basic structure

- [ ] **UI framework**
  - Files: ui/ui_framework.home
  - Issues: ArrayRepeat expression blocking

### 5.5 Resource Management
- [ ] **Asset loading**
  - Files: engine/asset_manifest.home
  - Status: Partial

- [ ] **BIG archive support**
  - Files: engine/big_archive.home
  - Status: Not verified

- [ ] **W3D model loading**
  - Files: engine/w3d_loader.home, engine/w3d_complete.home
  - Status: Partial implementation

- [ ] **INI file parsing**
  - Files: engine/ini_parser.home
  - Status: Implemented but not tested

### 5.6 Audio System
- [ ] **Audio engine**
  - Files: audio/audio_engine.home, audio/audio_system.home, engine/audio.home
  - Status: Stub implementations

- [ ] **EVA system (voice announcements)**
  - Files: engine/eva_system.home
  - Status: Not implemented

### 5.7 Networking and Multiplayer
- [ ] **Network layer**
  - Files: engine/network.home, engine/multiplayer_system.home
  - Status: Not implemented

- [ ] **Replay system**
  - Files: engine/replay_system.home
  - Status: Stub only

### 5.8 Game Modes
- [ ] **Campaign system**
  - Files: engine/campaign.home, engine/campaign_system.home, engine/missions.home
  - Status: Not implemented

- [ ] **Generals Challenge**
  - Files: engine/generals_challenge.home
  - Status: Not implemented

- [ ] **Skirmish mode**
  - Status: Not started

---

## PHASE 6: GAME CONTENT AND DATA

### 6.1 Unit Definitions
- [ ] **Define all faction units**
  - USA units (Ranger, Paladin, Crusader, etc.)
  - China units (Red Guard, Battlemaster, Overlord, etc.)
  - GLA units (Rebel, Scorpion, Marauder, etc.)
  - Files: templates/unit_templates.home, templates/complete_units.home

### 6.2 Building Definitions
- [ ] **Define all structures**
  - Base buildings (Command Center, Supply Center, Barracks, etc.)
  - Defense structures (Patriot, Gattling Cannon, Stinger Site, etc.)
  - Superweapons (Particle Cannon, Nuclear Missile, Scud Storm)
  - Files: templates/building_templates.home

### 6.3 Balance and Game Rules
- [ ] **Economy system**
  - Files: engine/economy.home, engine/economy_system.home, engine/resource.home, engine/resource_manager.home
  - Status: Basic structure

- [ ] **Tech tree**
  - Files: engine/tech_tree.home
  - Status: Not implemented

- [ ] **Veterancy system**
  - Files: engine/veterancy.home
  - Status: Stub

- [ ] **Upgrades system**
  - Files: engine/upgrades.home
  - Status: Stub

- [ ] **General powers**
  - Files: engine/special_powers.home, engine/abilities.home
  - Status: Not implemented

### 6.4 Visual Effects
- [ ] **Particle effects**
  - Explosions, weapon fire, smoke, etc.
  - Need particle system working first

- [ ] **Post-processing**
  - Files: engine/postprocessing.home, engine/advanced_rendering.home
  - Status: Partial

- [ ] **Cinematics and videos**
  - Files: engine/cinematics.home, engine/video_player.home
  - Status: Stubs

---

## PHASE 7: ASSETS AND RESOURCES

### 7.1 Required Art Assets
- [ ] **Unit models** (W3D format)
  - All units for 3 factions + generals
  - LODs (Level of Detail variations)
  - Damage states

- [ ] **Building models** (W3D format)
  - All structures for 3 factions
  - Damage states and construction animations

- [ ] **Terrain textures**
  - Grass, sand, dirt, rock, water, etc.
  - Normal maps, specular maps

- [ ] **UI textures and sprites**
  - Buttons, borders, icons
  - Faction-specific UI elements
  - Minimap icons

- [ ] **Effect textures**
  - Particles, explosions, smoke, fire
  - Weapon trails, muzzle flashes

### 7.2 Audio Assets
- [ ] **Sound effects**
  - Weapon sounds (gunfire, explosions, missiles)
  - Unit responses (selections, move orders, attack orders)
  - Ambient sounds (engine rumbles, etc.)

- [ ] **Music tracks**
  - Menu music
  - In-game tracks (varies by faction)
  - Victory/defeat music

- [ ] **Voice acting**
  - EVA announcements
  - Unit voices (for each faction)
  - General taunts and voices

### 7.3 Data Files
- [ ] **INI configuration files**
  - Object definitions (units, buildings, weapons)
  - Game rules and constants
  - Faction-specific data

- [ ] **Map files**
  - Original campaign maps
  - Multiplayer/skirmish maps
  - Map generator data

- [ ] **Script files**
  - Mission scripts
  - Campaign progression
  - Tutorial scripts

---

## PHASE 8: PLATFORM-SPECIFIC IMPLEMENTATION

### 8.1 macOS Platform Layer
- [ ] **Window management**
  - Files: platform/macos_window.home, engine/window.home
  - Status: Partial implementation

- [ ] **Metal renderer bindings**
  - Files: platform/macos_renderer.home, platform/macos_sprite_renderer.home
  - Need: Complete Metal API coverage

- [ ] **Input handling**
  - Files: platform/input.home, engine/input.home, engine/input_system.home
  - Keyboard, mouse, gamepad support

- [ ] **File I/O**
  - Files: platform/file.home
  - Status: Basic implementation

- [ ] **Timing and performance**
  - Files: platform/time.home
  - Status: Basic implementation

### 8.2 App Bundle and Distribution
- [ ] **Info.plist configuration**
  - Location: packaging/Info.plist
  - Status: Template exists

- [ ] **Icon and resources**
  - App icon (Generals.icns)
  - Status: Exists

- [ ] **Code signing**
  - Required for distribution
  - Status: Not configured

- [ ] **Notarization**
  - Required for macOS Catalina+
  - Status: Not started

---

## PHASE 9: TESTING AND QA

### 9.1 Unit Tests
- [ ] Create unit tests for:
  - Math library (vectors, matrices, quaternions)
  - ECS system
  - Pathfinding algorithms
  - Combat calculations
  - Resource management

### 9.2 Integration Tests
- [ ] Test full game scenarios:
  - Unit movement and combat
  - Building construction
  - Resource collection
  - Tech tree progression
  - AI behavior

### 9.3 Performance Testing
- [ ] Benchmark critical paths:
  - Rendering (target 60 FPS minimum)
  - Pathfinding (must handle 100+ units)
  - AI decision making
  - Network sync (for multiplayer)

### 9.4 Compatibility Testing
- [ ] Test on various macOS versions:
  - macOS 12 (Monterey) minimum
  - macOS 13 (Ventura)
  - macOS 14 (Sonoma)
  - macOS 15 (Sequoia)

- [ ] Test on different hardware:
  - Intel Macs
  - Apple Silicon (M1, M2, M3, M4)

---

## PHASE 10: DOCUMENTATION

### 10.1 User Documentation
- [ ] **Installation guide**
- [ ] **Controls and gameplay guide**
- [ ] **Troubleshooting guide**
- [ ] **FAQ**

### 10.2 Developer Documentation
- [ ] **Architecture overview**
- [ ] **Build instructions**
- [ ] **Modding guide**
- [ ] **API documentation**

### 10.3 Legal Documentation
- [ ] **License file** (GPL-3.0 likely, matching Thyme)
- [ ] **Attribution for assets** (if using original EA assets legally)
- [ ] **Third-party licenses** (for libraries used)

---

## PRIORITY ORDERING FOR IMPLEMENTATION

### IMMEDIATE (Week 1-2)
1. Fix double-free bug (DONE)
2. Fix `if !optional` parser issue
3. Fix pattern matching on MemberExpr
4. Implement ArrayRepeat expressions
5. Fix module::Type resolution in type system

### SHORT TERM (Week 3-4)
6. Implement Vec<T> generic type
7. Support mut pointer types
8. Fix tuple destructuring assignments
9. Complete basic ECS system
10. Get renderer producing simple graphics

### MEDIUM TERM (Month 2)
11. Complete unit and building systems
12. Implement combat mechanics
13. Basic AI pathfinding
14. Load and display W3D models
15. Parse and apply INI data files

### LONG TERM (Month 3+)
16. Full AI implementation
17. All game modes (campaign, skirmish, multiplayer)
18. Complete visual effects
19. Audio system integration
20. Polish and optimization

---

## SUCCESS CRITERIA

The port is considered "matching the original game" when:

1. ✅ All compiler errors resolved
2. ✅ All 267 .home files compile successfully
3. ✅ Game launches and shows main menu
4. ✅ Can start a skirmish match with all 3 factions
5. ✅ Units move, attack, and behave correctly
6. ✅ Buildings construct and function properly
7. ✅ Economy system (resource collection) works
8. ✅ Tech tree and upgrades functional
9. ✅ AI provides challenging gameplay
10. ✅ Graphics match original quality
11. ✅ Audio and music play correctly
12. ✅ Runs at 60 FPS on modern Macs
13. ✅ Campaign mode completable
14. ✅ Multiplayer functional (if implementing)
15. ✅ No critical bugs in normal gameplay

---

## ESTIMATED TOTAL EFFORT

**Compiler Fixes**: 80-120 hours
**Game Engine Implementation**: 200-300 hours
**Game Content and Balance**: 150-200 hours
**Asset Creation/Acquisition**: 100-150 hours (if not using originals)
**Testing and Polish**: 100-150 hours
**Documentation**: 40-60 hours

**TOTAL: 670-980 hours** (approximately 4-6 months full-time)

---

*Last Updated: 2025-11-24*
*Status: Phase 1 in progress - Critical compiler bugs being fixed*
