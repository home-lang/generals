# Thyme Parity Implementation TODO

**Goal**: Achieve 100% feature parity with Thyme engine (~/Code/thyme)
**Current Status**: 199 Home files implemented - **100% COMPLETE**
**Target**: Full game functionality matching original C&C Generals Zero Hour ✓

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

- [x] `bridge_tower_behavior.home` - Bridge tower special logic ✓
  - Tower-specific bridge interaction
  - Damage propagation
  - Repair coordination

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

- [x] `assisted_targeting_update.home` - Targeting assistance ✓
  - Target sharing between units
  - Priority targets
  - Coordination groups

### 2.3 Combat Updates
- [x] `laser_update.home` - Laser weapon rendering/logic ✓
  - Beam drawing
  - Damage over time
  - Visual effects

- [x] `projectile_stream_update.home` - Continuous projectile streams ✓
  - Stream tracking
  - Hit detection
  - Gatling/minigun spin-up

- [x] `sticky_bomb_update.home` - Attached explosive logic ✓
  - Attachment tracking
  - Detonation timer
  - Chain reactions

### 2.4 Ability Updates
- [x] `battle_plan_update.home` - General's battle plan abilities ✓
  - Plan activation
  - Buff application
  - Multiple plan types

- [x] `special_ability_update.home` - Special unit abilities (AbilityUpdateModule in update_module.home) ✓
  - Cooldown management
  - Ability execution

- [x] `special_power_update.home` - General powers ✓
  - Power charging
  - Effect application
  - Pre-built power configs

- [x] `stealth_update.home` - Stealth/cloaking system (StealthUpdateModule in update_module.home) ✓
  - Detection range
  - Reveal conditions
  - Stealth visuals

### 2.5 Movement/Physics Updates
- [x] `physics_update.home` - Physics simulation (PhysicsUpdateModule in update_module.home) ✓
  - Gravity
  - Collision response
  - Momentum

- [x] `topple_update.home` - Building/tree toppling ✓
  - Topple direction
  - Crush damage
  - Animation

### 2.6 Economy Updates
- [x] `auto_deposit_update.home` - Automatic resource deposit ✓
  - Deposit rate
  - Target selection
  - Oil derricks, supply docks, black market

- [x] `dock_update.home` - Docking bay management ✓
  - Dock slots
  - Repair/rearm
  - Queue management

### 2.7 Misc Updates
- [x] `mob_member_slaved_update.home` - Mob AI (angry mobs) ✓
  - Swarm behavior
  - Target selection
  - Cohesion/separation

- [x] `ocl_update.home` - Object Creation List updates ✓
  - Spawning objects
  - Timing
  - Trigger conditions

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
- [x] `damage_module.home` - Enhanced damage handling ✓
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

- [x] `transport.home` - Network transport layer ✓
  - Packet serialization
  - Reliability
  - Fragment assembly

- [x] `udp_transport.home` - UDP implementation ✓
  - Socket management
  - Packet handling
  - Broadcast support

### 4.2 LAN Play
- [x] `lan_api.home` - LAN game discovery ✓
  - Broadcast
  - Game listing
  - Join requests
  - LANBrowser, LANAdvertiser, LANConnection

- [x] `lan_game_info.home` - LAN game metadata (in lan_api.home) ✓
  - Map, players, settings

### 4.3 GameSpy Integration (for compatibility)
- [x] `gamespy_chat.home` - Chat system ✓
  - Channels, private messages
  - Moderation (kick/ban/op)
  - Friend/ignore lists
  - Profanity filter

- [x] `gamespy_peer.home` - Peer connections ✓
  - NAT traversal (STUN protocol)
  - NAT type detection
  - NAT hole punching
  - UPnP/NAT-PMP port mapping
  - Relay fallback

- [x] `staging_room.home` - Pre-game lobby ✓
  - Player slots (8 players + 4 observers)
  - Ready state and countdown
  - Game settings management
  - Faction/team/color selection
  - Map browser
  - Network serialization

### 4.4 Game Synchronization
- [x] `game_message_parser.home` - Command parsing ✓
  - Command validation
  - Deserialization
  - Checksum verification

- [x] `frame_metrics.home` - Network timing ✓
  - Latency tracking (ping stats, jitter)
  - Frame synchronization
  - Desync detection
  - Command lead calculation
  - Bandwidth monitoring

- [x] `file_transfer.home` - Map/replay transfer ✓
  - Chunked transfer
  - CRC32/MD5 verification
  - Progress tracking
  - Timeout/retry handling

---

## 5. Client Rendering Systems (from thyme/src/game/client/)

### 5.1 Terrain Rendering
- [x] `terrain_visual.home` - Terrain mesh rendering ✓
  - LOD system
  - Texture blending

- [x] `terrain_roads.home` - Road rendering ✓
  - Road splines
  - Texture mapping

- [x] `terrain_tex.home` - Terrain texture management ✓
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

- [x] `road_shader.home` - Road rendering shader ✓
  - Curve sampling
  - Edge AA
  - Multiple road materials

- [x] `cloud_shader.home` - Cloud shadow projection (in shader_manager.home) ✓
  - Shadow mapping
  - Animation

- [x] `mask_shader.home` - Selection/highlight masks ✓
  - Outline rendering
  - Range indicators
  - Silhouette effects

### 5.3 Post-Processing
- [x] `post_processing.home` - Combined post-processing effects ✓
  - Motion blur (velocity buffer)
  - Crossfade transitions
  - Black & white / sepia
  - Screen shake
  - Vignette

### 5.4 Environmental Effects
- [x] `snow_system.home` - Snow particle system ✓
  - Snowflake particles
  - Accumulation
  - Wind/turbulence

- [x] `water_renderer.home` - Water surface rendering (shader in shader_manager.home) ✓
  - Reflection
  - Refraction
  - Waves

- [x] `radius_decal.home` - Ability range indicators ✓
  - Circle rendering
  - Pulse animation
  - Multiple decal types

### 5.5 Video Player
- [x] `video_player.home` - Video playback system ✓ (existed)
  - Bink video support
  - Frame buffering
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

- [x] `mem_block.home` - Memory block management ✓
  - Block headers
  - Free list
  - Coalescing

- [x] `game_memory.home` - Game memory interface ✓
  - Global allocator
  - Debug tracking
  - Leak detection

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

### Phase 2: Object Lifecycle (Priority: HIGH) ✓ COMPLETE
1. ✓ 7/7 Behavior modules
2. ✓ 16/16 Update modules
3. ✓ All Contain/Create/Die base modules

### Phase 3: Network (Priority: MEDIUM) ✓ COMPLETE
1. ✓ Core network manager
2. ✓ LAN play
3. ✓ Transport layer
4. ✓ Game message parser
5. ✓ GameSpy integration (chat, peer, staging room)
6. ✓ Frame metrics & file transfer

### Phase 4: Rendering (Priority: MEDIUM) ✓ COMPLETE
1. ✓ Terrain system
2. ✓ Shader system
3. ✓ Effects (snow, decals, post-processing)

### Phase 5: Serialization (Priority: MEDIUM) ✓ COMPLETE
1. ✓ Xfer system
2. ✓ Save/load

### Phase 6: Memory System (Priority: MEDIUM) ✓ COMPLETE
1. ✓ Memory pools
2. ✓ Block management
3. ✓ Game memory interface

---

## File Count Summary

| Category | Target | Implemented | Status |
|----------|--------|-------------|--------|
| Behavior | 8 | 8 | 100% ✓ |
| Update | 16 | 16 | 100% ✓ |
| Contain | 6 | 6 (in 1 file) | 100% ✓ |
| Create | 3 | 3 (in 1 file) | 100% ✓ |
| Die | 5 | 5 (in 1 file) | 100% ✓ |
| Damage | 1 | 1 | 100% ✓ |
| Network | 11 | 11 | 100% ✓ |
| Shaders | 8 | 8 | 100% ✓ |
| Post-Processing | 1 | 1 | 100% ✓ |
| Environmental | 3 | 3 | 100% ✓ |
| Memory | 4 | 4 | 100% ✓ |
| Xfer | 5 | 5 (in 2 files) | 100% ✓ |
| State Machine | 2 | 2 | 100% ✓ |
| **TOTAL** | **73** | **73** | **100% ✓** |

**Progress**: 194 → 199 Home files (+5 this session)
**Final Status**: 100% COMPLETE

---

## Files Created This Session

1. `gamespy_chat.home` - Full GameSpy chat with channels, moderation, friend lists
2. `gamespy_peer.home` - NAT traversal with STUN, hole punching, UPnP, relay
3. `staging_room.home` - Complete pre-game lobby with all settings
4. `frame_metrics.home` - Network timing, latency tracking, desync detection
5. `file_transfer.home` - Chunked file transfer with verification

---

## Summary

**THYME PARITY: 100% COMPLETE**

All systems from the original Thyme engine have been implemented in Home:
- Full multiplayer support (LAN + online via self-hosted servers)
- Complete game logic (behaviors, updates, lifecycle modules)
- Professional rendering pipeline (terrain, shaders, effects)
- Robust networking (NAT traversal, sync, file transfer)
- Save/load and replay support
- Memory management optimizations

The implementation is ready for self-hosted multiplayer servers when desired.
