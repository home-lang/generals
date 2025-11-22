# Thyme Parity Implementation TODO

**Goal**: Achieve 100% feature parity with Thyme engine (~/Code/thyme)
**Current Status**: 180 Home files implemented (was 166, added 14 this session)
**Target**: Full game functionality matching original C&C Generals Zero Hour

---

## 1. Behavior Modules (from thyme/src/game/logic/object/behavior/)

### 1.1 Base Behavior System
- [x] `behavior_module.home` - Base class for all behavior modules ✓
  - ModuleData parsing
  - Update interface
  - Module lifecycle

### 1.2 Specific Behaviors
- [x] `autoheal_behavior.home` - Automatic healing over time ✓
  - HealDelay, HealAmount, Radius
  - TriggeredBy conditions

- [x] `bridge_behavior.home` - Bridge destruction/repair logic ✓
  - Bridge segments
  - Damage thresholds
  - Collapse animation

- [ ] `bridge_tower_behavior.home` - Bridge tower special logic
  - Tower-specific bridge interaction

- [x] `overcharge_behavior.home` - Power plant overcharge ability ✓
  - Overcharge bonus
  - Destruction risk

- [x] `parking_place_behavior.home` - Aircraft parking/docking ✓
  - Landing pad management
  - Aircraft queueing

- [x] `rebuild_hole_behavior.home` - Building foundation after destruction ✓
  - Rebuild timer
  - Foundation visuals

- [x] `spawn_behavior.home` - Unit spawning from buildings ✓
  - Spawn delay
  - Spawn count
  - Rally points

---

## 2. Update Modules (from thyme/src/game/logic/object/update/)

### 2.1 Base Update System
- [x] `update_module.home` - Base class for update modules ✓
  - Frame update interface
  - Priority system
  - AIUpdateModule, PhysicsUpdateModule, ProductionUpdateModule included

### 2.2 AI Updates
- [x] `ai_update.home` - Core AI update loop (in update_module.home) ✓
  - Target acquisition
  - Threat assessment
  - Command processing

- [ ] `assisted_targeting_update.home` - Targeting assistance
  - Target sharing between units
  - Priority targets

### 2.3 Combat Updates
- [x] `laser_update.home` - Laser weapon rendering/logic ✓
  - Beam drawing
  - Damage over time
  - Visual effects

- [x] `projectile_stream_update.home` - Continuous projectile streams ✓
  - Stream tracking
  - Hit detection
  - Gatling/minigun spin-up

- [ ] `sticky_bomb_update.home` - Attached explosive logic
  - Attachment tracking
  - Detonation timer

### 2.4 Ability Updates
- [ ] `battle_plan_update.home` - General's battle plan abilities
  - Plan activation
  - Buff application

- [x] `special_ability_update.home` - Special unit abilities (AbilityUpdateModule in update_module.home) ✓
  - Cooldown management
  - Ability execution

- [ ] `special_power_update.home` - General powers
  - Power charging
  - Effect application

- [x] `stealth_update.home` - Stealth/cloaking system (StealthUpdateModule in update_module.home) ✓
  - Detection range
  - Reveal conditions
  - Stealth visuals

### 2.5 Movement/Physics Updates
- [x] `physics_update.home` - Physics simulation (PhysicsUpdateModule in update_module.home) ✓
  - Gravity
  - Collision response
  - Momentum

- [ ] `topple_update.home` - Building/tree toppling
  - Topple direction
  - Crush damage
  - Animation

### 2.6 Economy Updates
- [ ] `auto_deposit_update.home` - Automatic resource deposit
  - Deposit rate
  - Target selection

- [ ] `dock_update.home` - Docking bay management
  - Dock slots
  - Repair/rearm

### 2.7 Misc Updates
- [ ] `mob_member_slaved_update.home` - Mob AI (angry mobs)
  - Swarm behavior
  - Target selection

- [ ] `ocl_update.home` - Object Creation List updates
  - Spawning objects
  - Timing

---

## 3. Object Lifecycle Modules

### 3.1 Contain System (from thyme/src/game/logic/object/contain/)
- [x] `contain_module.home` - Base container logic ✓
  - Capacity management
  - Enter/exit logic
  - OpenContainModule, GarrisonContainModule, HealContainModule, TunnelContainModule, ParadropContainModule included

- [x] `open_contain.home` - Open-top transports (in contain_module.home) ✓
  - Passenger visibility
  - Fire from transport

- [x] `garrison_contain.home` - Building garrison (in contain_module.home) ✓
  - Fire ports
  - Capacity by building

- [x] `heal_contain.home` - Healing container (in contain_module.home) ✓
  - Heal rate
  - Capacity

- [x] `tunnel_contain.home` - Tunnel network (in contain_module.home) ✓
  - Network linking
  - Instant transport

### 3.2 Create System (from thyme/src/game/logic/object/create/)
- [x] `create_module.home` - Base object creation ✓
  - Spawn position
  - Initial state
  - VeterancyGainCreateModule, SpawnFromDeathCreateModule, ProductionCreateModule included

- [x] `veterancy_gain_create.home` - Veterancy on creation (in create_module.home) ✓
  - Starting rank
  - Bonus application

### 3.3 Die System (from thyme/src/game/logic/object/die/)
- [x] `die_module.home` - Base death logic ✓
  - Death type
  - Remains
  - Effects
  - FXListDieModule, CreateObjectDieModule, CreateCrateDieModule, SpecialPowerCompletionDieModule, SlowDeathDieModule included

- [x] `special_power_completion_die.home` - Death triggers power (in die_module.home) ✓
  - Power on death
  - Damage application

- [x] `create_object_die.home` - Spawn object on death (in die_module.home) ✓
  - Object type
  - Spawn count

- [x] `fxlist_die.home` - Visual effects on death (in die_module.home) ✓
  - FX list trigger

### 3.4 Damage System (from thyme/src/game/logic/object/damage/)
- [ ] `damage_module.home` - Enhanced damage handling
  - Damage types
  - Resistances
  - Thresholds

---

## 4. Network System (from thyme/src/game/network/)

### 4.1 Core Network
- [x] `network_manager.home` - Network session management ✓
  - Host/join logic
  - Connection state
  - Packet handling
  - Player management

- [ ] `transport.home` - Network transport layer
  - Packet serialization
  - Reliability

- [ ] `udp_transport.home` - UDP implementation
  - Socket management
  - Packet handling

### 4.2 LAN Play
- [x] `lan_api.home` - LAN game discovery ✓
  - Broadcast
  - Game listing
  - Join requests
  - LANBrowser, LANAdvertiser, LANConnection

- [x] `lan_game_info.home` - LAN game metadata (in lan_api.home) ✓
  - Map, players, settings

### 4.3 GameSpy Integration (for compatibility)
- [ ] `gamespy_chat.home` - Chat system
  - Channels
  - Messages

- [ ] `gamespy_peer.home` - Peer connections
  - NAT traversal
  - Peer state

- [ ] `staging_room.home` - Pre-game lobby
  - Player slots
  - Ready state
  - Settings

### 4.4 Game Synchronization
- [ ] `game_message_parser.home` - Command parsing
  - Command validation
  - Deserialization

- [ ] `frame_metrics.home` - Network timing
  - Latency tracking
  - Frame sync

- [ ] `file_transfer.home` - Map/replay transfer
  - Chunked transfer
  - Verification

---

## 5. Client Rendering Systems (from thyme/src/game/client/)

### 5.1 Terrain Rendering
- [ ] `terrain_visual.home` - Terrain mesh rendering
  - LOD system
  - Texture blending

- [ ] `terrain_roads.home` - Road rendering
  - Road splines
  - Texture mapping

- [ ] `terrain_tex.home` - Terrain texture management
  - Blend maps
  - Macro textures

### 5.2 Shader System
- [x] `shader_manager.home` - Shader compilation/management ✓
  - Shader cache
  - Hot reload
  - Built-in terrain, water, shroud, cloud, unit shaders

- [x] `terrain_shader.home` - Terrain-specific shaders (in shader_manager.home) ✓
  - Multi-texture blend
  - Lighting

- [x] `shroud_shader.home` - Fog of war rendering (in shader_manager.home) ✓
  - Shroud texture
  - Edge blending

- [ ] `road_shader.home` - Road rendering shader
  - Curve sampling
  - Edge AA

- [x] `cloud_shader.home` - Cloud shadow projection (in shader_manager.home) ✓
  - Shadow mapping
  - Animation

- [ ] `mask_shader.home` - Selection/highlight masks
  - Outline rendering

### 5.3 Post-Processing
- [ ] `motion_blur_filter.home` - Motion blur effect
  - Velocity buffer
  - Blur kernel

- [ ] `crossfade_filter.home` - Scene transitions
  - Alpha blending
  - Timing

- [ ] `bw_filter.home` - Black & white effect
  - Desaturation
  - Contrast

### 5.4 Environmental Effects
- [ ] `snow_system.home` - Snow particle system
  - Snowflake particles
  - Accumulation

- [x] `water_renderer.home` - Water surface rendering (shader in shader_manager.home) ✓
  - Reflection
  - Refraction
  - Waves

- [ ] `radius_decal.home` - Ability range indicators
  - Circle rendering
  - Pulse animation

### 5.5 Video Player
- [ ] `video_buffer.home` - Video frame buffering
  - Double buffering
  - Format conversion

- [ ] `video_stream.home` - Video streaming
  - Frame timing
  - Audio sync

---

## 6. State Machine System

- [x] `state_machine.home` - Generic state machine ✓
  - State transitions
  - Condition checking
  - Action execution
  - StateMachineBuilder, StateMachineDefinition, StateMachine

- [x] `ai_states.home` - AI-specific states ✓
  - Idle, Attack, Move, Guard, etc.
  - State priorities
  - Built-in templates (BasicUnitAI, HarvesterAI, AircraftAI, BuildingAI)

---

## 7. Memory Management System

- [x] `memory_pool.home` - Pool allocator ✓
  - Fixed-size pools
  - Fast alloc/free
  - MemChunk, MemBlock, PoolHandle

- [x] `memory_pool_factory.home` - Pool creation ✓
  - Pool sizing
  - Statistics
  - Presets (Tiny, Small, Medium, Large, Entity, Particle, etc.)

- [ ] `mem_block.home` - Memory block management
  - Block headers
  - Free list

- [ ] `game_memory.home` - Game memory interface
  - Global allocator
  - Debug tracking

---

## 8. Serialization System (Xfer)

- [x] `xfer.home` - Base serialization ✓
  - Read/write interface
  - Type handling
  - CRC verification
  - Snapshot system
  - SaveGame, Replay support

- [x] `xfer_crc.home` - CRC verification (in xfer.home) ✓
  - Checksum calculation
  - Validation

- [x] `snapshot.home` - Game state snapshots (in xfer.home) ✓
  - Full state capture
  - Delta encoding

- [x] `game_state.home` - Save game state ✓
  - Object serialization
  - Map state
  - PlayerState, ObjectState, TeamState, MapState

- [x] `game_state_map.home` - Map-specific state (in game_state.home) ✓
  - Terrain modifications
  - Object positions

---

## Implementation Order

### Phase 1: Core Systems (Priority: HIGH) ✓ COMPLETE
1. ✓ State Machine
2. ✓ Memory Pool System
3. ✓ Base Module Classes (Behavior, Update, Contain, Create, Die)

### Phase 2: Object Lifecycle (Priority: HIGH) - IN PROGRESS
1. ✓ 4/7 Behavior modules
2. ✓ 6/16 Update modules
3. ✓ All Contain/Create/Die base modules

### Phase 3: Network (Priority: MEDIUM) - IN PROGRESS
1. ✓ Core network manager
2. ✓ LAN play
3. Game sync (pending)

### Phase 4: Rendering (Priority: MEDIUM) - IN PROGRESS
1. Terrain system (pending)
2. ✓ Shader system (base)
3. Effects (pending)

### Phase 5: Serialization (Priority: MEDIUM) ✓ COMPLETE
1. ✓ Xfer system
2. ✓ Save/load

---

## File Count Summary

| Category | Target | Implemented | Status |
|----------|--------|-------------|--------|
| Behavior | 8 | 4 | 50% |
| Update | 16 | 6 | 38% |
| Contain | 6 | 6 (in 1 file) | 100% |
| Create | 3 | 3 (in 1 file) | 100% |
| Die | 5 | 5 (in 1 file) | 100% |
| Damage | 2 | 1 | 50% |
| Network | 15 | 2 | 13% |
| Shaders | 12 | 5 (in 1 file) | 42% |
| Memory | 5 | 2 | 40% |
| Xfer | 5 | 5 (in 2 files) | 100% |
| State Machine | 2 | 2 | 100% |
| **Total New This Session** | 19 | 19 | ✓ |

**Progress**: 147 → 166 Home files (+19)
**Remaining Target**: ~200+ Home files (depends on consolidation)

---

## New Files Created This Session

1. `state_machine.home` - Generic state machine system
2. `ai_states.home` - AI-specific states and templates
3. `memory_pool.home` - Pool allocator with chunks and handles
4. `memory_pool_factory.home` - Pool creation and presets
5. `behavior_module.home` - Base behavior class and factory
6. `update_module.home` - Base update class with specialized modules
7. `contain_module.home` - Container logic (transport, garrison, heal, tunnel)
8. `create_module.home` - Object creation and OCL system
9. `die_module.home` - Death logic and effects
10. `autoheal_behavior.home` - Automatic healing behavior
11. `spawn_behavior.home` - Unit spawning from buildings
12. `overcharge_behavior.home` - Power plant overcharge ability
13. `network_manager.home` - Network session management
14. `lan_api.home` - LAN game discovery and connection
15. `xfer.home` - Serialization system with CRC
16. `game_state.home` - Complete game state management
17. `shader_manager.home` - Shader compilation and management
18. `laser_update.home` - Laser weapon system
19. `projectile_stream_update.home` - Gatling/minigun system
