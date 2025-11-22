# C&C Generals Zero Hour - Honest Implementation TODO

**Goal**: Generate a DMG that matches the exact same UX and content as the original game
**Current Status**: ~198 Home files - Infrastructure scaffolding exists, NOT a playable game
**Reality Check**: We have code modules but they are NOT integrated into a working game loop

---

## CRITICAL REALITY CHECK

The previous TODO claimed "100% COMPLETE" - this was **inaccurate**. Here's the truth:

| Claim | Reality |
|-------|---------|
| "All W3D chunk types" | Loaders exist, but NOT rendering 3D models |
| "Unit system complete" | Module exists, NOT spawning/controlling units |
| "Menu system complete" | Basics exist, NOT loading real .wnd files |
| "Audio system complete" | Module exists, NOT playing game audio |
| "Campaign complete" | Module exists, NO missions playable |

**A user cannot currently:**
- Start a skirmish game and play against AI
- See 3D units rendered on screen
- Select units with mouse and give commands
- Complete any campaign mission
- See the authentic main menu

---

## TIER 1: CRITICAL BLOCKERS - Without These, No Game

### 1.1 Full 3D Rendering Pipeline (BLOCKER)
**Current**: Have w3d_loader.home, w3d_complete.home (loaders)
**Missing**: Actual GPU rendering of loaded data

**Required**:
- [ ] `w3d_gpu_renderer.home` - Upload meshes to Metal, render with shaders
- [ ] `w3d_material_system.home` - Material/texture binding for W3D
- [ ] `w3d_animation_player.home` - Play skeletal animations in real-time
- [ ] `w3d_bone_transforms.home` - Calculate bone matrices each frame
- [ ] `w3d_skin_shader.home` - Metal shader for skinned meshes
- [ ] `w3d_static_shader.home` - Metal shader for static props
- [ ] `render_queue.home` - Batch and sort draw calls
- [ ] `draw_call.home` - Individual draw call abstraction

**Test**: Can render a single tank model rotating on screen

### 1.2 Object/Thing Instantiation (BLOCKER)
**Current**: Have object.home, thing.home (definitions)
**Missing**: Creating actual game objects from templates

**Required**:
- [ ] `object_creation_list.home` - OCL system for spawning
- [ ] `thing_factory.home` - Instantiate Things from ThingTemplates
- [ ] `object_pool.home` - Object memory management
- [ ] `object_id_manager.home` - Unique ID assignment
- [ ] `drawable_binding.home` - Connect Object to Drawable

**Test**: Can spawn a USA Ranger unit that appears on screen

### 1.3 INI Game Data Loading (BLOCKER)
**Current**: Have ini_parser.home (basic parser)
**Missing**: Actually parsing real game INI files into usable templates

**Required**:
- [ ] `object_definition_parser.home` - Parse Object definitions from INI
- [ ] `weapon_definition_parser.home` - Parse Weapon definitions
- [ ] `locomotor_definition_parser.home` - Parse Locomotor definitions
- [ ] `armor_definition_parser.home` - Parse ArmorSet definitions
- [ ] `fx_definition_parser.home` - Parse FXList definitions
- [ ] `science_definition_parser.home` - Parse Science definitions
- [ ] `upgrade_definition_parser.home` - Parse Upgrade definitions
- [ ] `specialpower_definition_parser.home` - Parse SpecialPower definitions
- [ ] `commandbutton_parser.home` - Parse CommandButton definitions
- [ ] `commandset_parser.home` - Parse CommandSet definitions
- [ ] `player_template_parser.home` - Parse PlayerTemplate (factions)
- [ ] `game_data_coordinator.home` - Load all INI in correct order

**Test**: Load GameData.ini + Object definitions, create a unit from template

### 1.4 Selection & Commands (BLOCKER)
**Current**: None functional
**Missing**: Player input to game action pipeline

**Required**:
- [ ] `selection_manager.home` - Track selected objects
- [ ] `drag_select_box.home` - Mouse drag selection
- [ ] `selection_ui.home` - Draw selection circles/boxes
- [ ] `command_center.home` - Process player commands
- [ ] `move_order.home` - Issue move commands
- [ ] `attack_order.home` - Issue attack commands
- [ ] `stop_order.home` - Issue stop commands
- [ ] `guard_order.home` - Issue guard commands
- [ ] `control_group.home` - Ctrl+1-9 control groups
- [ ] `context_command.home` - Right-click context commands

**Test**: Click unit, right-click ground, unit moves there

### 1.5 Control Bar UI (BLOCKER)
**Current**: None
**Missing**: The entire bottom UI panel

**Required**:
- [ ] `control_bar.home` - Main control bar frame
- [ ] `command_button_ui.home` - Clickable command buttons
- [ ] `unit_portrait.home` - Selected unit portrait
- [ ] `unit_health_bar.home` - Health/shields display
- [ ] `build_queue_ui.home` - Production queue display
- [ ] `multi_select_ui.home` - Multi-unit selection view
- [ ] `upgrade_buttons.home` - Available upgrade buttons
- [ ] `resource_display.home` - Money/power display
- [ ] `general_powers_ui.home` - General's abilities bar

**Test**: Select Command Center, see build buttons, click to build unit

### 1.6 Game Window Framework (BLOCKER)
**Current**: Have window.home (basic)
**Missing**: Full WND-based UI system

**Required**:
- [ ] `wnd_loader.home` - Load real .wnd files from game data
- [ ] `wnd_window.home` - Window base class matching WND spec
- [ ] `wnd_button.home` - Button widget
- [ ] `wnd_listbox.home` - List widget
- [ ] `wnd_textentry.home` - Text input widget
- [ ] `wnd_slider.home` - Slider widget
- [ ] `wnd_checkbox.home` - Checkbox widget
- [ ] `wnd_combobox.home` - Dropdown widget
- [ ] `wnd_progressbar.home` - Progress bar widget
- [ ] `wnd_statictext.home` - Static text widget
- [ ] `window_manager.home` - Window stack and transitions

**Test**: Load MainMenu.wnd, display working main menu

---

## TIER 2: ESSENTIAL - Required for Playable Skirmish

### 2.1 AI Player System
**Current**: Have ai.home, ai_player.home (basic)
**Missing**: Actual computer player brain

**Required**:
- [ ] `ai_brain.home` - High-level decision making
- [ ] `ai_build_controller.home` - Build order logic
- [ ] `ai_army_controller.home` - Army management
- [ ] `ai_attack_controller.home` - Attack decisions
- [ ] `ai_defense_controller.home` - Defense positioning
- [ ] `ai_economy_controller.home` - Resource management
- [ ] `ai_difficulty_settings.home` - Easy/Medium/Hard/Brutal
- [ ] `ai_personality.home` - Different AI behaviors (tank rush, etc)

**Test**: Start skirmish vs AI, AI builds base and attacks

### 2.2 Pathfinding Integration
**Current**: Have pathfinding.home, ai_pathfinding.home
**Missing**: Integration with unit movement

**Required**:
- [ ] `path_request.home` - Request path for unit
- [ ] `path_cache.home` - Cache computed paths
- [ ] `formation_pathfinding.home` - Group movement
- [ ] `obstacle_avoidance.home` - Dynamic obstacle avoidance
- [ ] `terrain_passability.home` - What can go where

**Test**: Units navigate around obstacles to destination

### 2.3 Weapon Firing System
**Current**: Have weapon.home, weapon_templates.home
**Missing**: Actually firing weapons

**Required**:
- [ ] `weapon_firing.home` - Fire weapon at target
- [ ] `projectile_manager.home` - Manage projectiles in flight
- [ ] `hit_detection.home` - Projectile hit detection
- [ ] `damage_dealer.home` - Apply damage to target
- [ ] `weapon_effect.home` - Muzzle flash, sound, etc

**Test**: Unit fires at enemy, projectile flies, enemy takes damage

### 2.4 Complete Terrain Rendering
**Current**: Have terrain.home, terrain_visual.home
**Missing**: Full terrain rendering with all features

**Required**:
- [ ] `heightmap_renderer.home` - Render terrain heightmap
- [ ] `terrain_texture_blend.home` - Blend terrain textures
- [ ] `water_renderer.home` - Water with reflection/refraction
- [ ] `cliff_renderer.home` - Cliff faces
- [ ] `road_renderer.home` - Roads on terrain
- [ ] `bridge_renderer.home` - Bridge models
- [ ] `tree_renderer.home` - Instanced trees
- [ ] `prop_renderer.home` - Map decorations

**Test**: Load a map file, see complete terrain with water

### 2.5 Shroud/Fog of War
**Current**: Have fog_of_war.home
**Missing**: Per-team visibility system

**Required**:
- [ ] `shroud_manager.home` - Shroud state management
- [ ] `vision_update.home` - Update visibility from units
- [ ] `shroud_renderer.home` - Render fog/shroud on terrain
- [ ] `reveal_handler.home` - Handle reveal events

**Test**: Fog covers map, exploring reveals terrain

### 2.6 Minimap
**Current**: Have minimap.home (basic)
**Missing**: Functional minimap

**Required**:
- [ ] `minimap_renderer.home` - Render minimap texture
- [ ] `minimap_icons.home` - Unit/building icons
- [ ] `minimap_events.home` - Attack/ping indicators
- [ ] `minimap_camera.home` - Click to move camera

**Test**: Minimap shows terrain, units, can click to move view

---

## TIER 3: IMPORTANT - Full Game Experience

### 3.1 Shell/Menu System
**Required**:
- [ ] `main_menu_screen.home` - Main menu
- [ ] `options_screen.home` - Options menus
- [ ] `skirmish_screen.home` - Skirmish setup
- [ ] `multiplayer_screen.home` - Multiplayer lobby
- [ ] `load_screen.home` - Load game
- [ ] `credits_screen.home` - Credits
- [ ] `loading_screen.home` - Mission loading with tips

### 3.2 Audio Integration
**Required**:
- [ ] `audio_events.home` - Trigger audio from game events
- [ ] `3d_audio_source.home` - Positional audio from units
- [ ] `music_controller.home` - Background music control
- [ ] `voice_selector.home` - Unit voice line selection
- [ ] `eva_controller.home` - EVA announcer control

### 3.3 Particle/FX System
**Required**:
- [ ] `fx_system.home` - FXList execution
- [ ] `particle_renderer.home` - GPU particle rendering
- [ ] `laser_fx.home` - Laser beam effects
- [ ] `explosion_fx.home` - Explosion effects
- [ ] `smoke_fx.home` - Smoke trails

### 3.4 Camera System
**Current**: Have camera.home, camera_system.home
**Required**:
- [ ] `rts_camera_controller.home` - RTS-style camera control
- [ ] `camera_constraints.home` - Map boundary constraints
- [ ] `camera_shake.home` - Screen shake effects
- [ ] `camera_zoom_levels.home` - Zoom presets

---

## TIER 4: CAMPAIGN MODE

### 4.1 Script Engine
**Required**:
- [ ] `script_action_executor.home` - Execute script actions
- [ ] `script_condition_checker.home` - Check script conditions
- [ ] `trigger_manager.home` - Map trigger system
- [ ] `team_manager.home` - AI team definitions
- [ ] `waypoint_manager.home` - Waypoint system
- [ ] `objective_tracker.home` - Mission objectives

### 4.2 Campaign Flow
**Required**:
- [ ] `campaign_progression.home` - Track campaign progress
- [ ] `mission_loader.home` - Load mission maps
- [ ] `briefing_screen.home` - Mission briefings
- [ ] `cutscene_player.home` - In-engine cutscenes
- [ ] `mission_end_screen.home` - Victory/defeat screen

---

## TIER 5: MULTIPLAYER

### 5.1 Network Sync
**Current**: Have network modules
**Required**:
- [ ] `lockstep_sync.home` - Lockstep command execution
- [ ] `command_buffer.home` - Buffered command execution
- [ ] `sync_hash.home` - Game state hashing for desync
- [ ] `reconnect_handler.home` - Reconnection logic

### 5.2 Multiplayer UI
**Required**:
- [ ] `lobby_ui.home` - Game lobby
- [ ] `chat_ui.home` - In-game chat
- [ ] `player_list_ui.home` - Player listing
- [ ] `map_transfer.home` - Custom map transfer

---

## TIER 6: POLISH

### 6.1 Quality of Life
- [ ] `hotkey_config.home` - Customizable hotkeys
- [ ] `replay_controls.home` - Replay playback UI
- [ ] `statistics_tracker.home` - End game stats
- [ ] `auto_save.home` - Automatic saving

### 6.2 Performance
- [ ] `occlusion_culling.home` - Don't render hidden objects
- [ ] `lod_manager.home` - Level of detail switching
- [ ] `instanced_rendering.home` - Batch similar objects
- [ ] `memory_profiler.home` - Track memory usage

---

## IMPLEMENTATION PRIORITY

### Phase 1: Proof of Concept (~2-4 weeks)
1. Get ONE 3D unit model rendering on screen via Metal
2. Load ONE unit definition from real INI files
3. Click to select that unit
4. Right-click to move that unit
5. Display basic terrain

**Deliverable**: Single unit controllable on a flat map

### Phase 2: Basic Combat (~2-4 weeks)
1. Add enemy units
2. Implement weapon firing
3. Add basic AI (chase and attack)
4. Add unit death

**Deliverable**: Units can fight and die

### Phase 3: Economy & Building (~2-4 weeks)
1. Add resource collection
2. Add building placement
3. Add production queues
4. Add tech tree

**Deliverable**: Can build a base and army

### Phase 4: Full Skirmish (~2-4 weeks)
1. Full AI opponent
2. Victory conditions
3. All unit types
4. Full UI

**Deliverable**: Playable skirmish mode

### Phase 5: Campaign (~2-4 weeks)
1. Script engine
2. Mission loading
3. Campaign progression

**Deliverable**: Playable campaign

### Phase 6: Multiplayer & Polish (~2-4 weeks)
1. Network sync
2. Menus and options
3. Audio integration
4. Polish

**Deliverable**: Shippable DMG

---

## File Count Summary

| Category | Have (scaffolding) | Need (working) | Gap |
|----------|-------------------|----------------|-----|
| 3D Rendering | Loaders only | Full pipeline | HIGH |
| Object System | Definitions | Instantiation | HIGH |
| INI Parsing | Basic parser | All data types | HIGH |
| Selection/Input | Basic | Full system | HIGH |
| Control Bar | None | Complete | CRITICAL |
| AI Player | Basic | Full brain | MEDIUM |
| Terrain | Basic | Complete | MEDIUM |
| Audio | System exists | Integrated | MEDIUM |
| Menus | Basic | All screens | MEDIUM |

---

## Honest Timeline

With focused effort, achieving a **basic playable skirmish** could take 2-3 months.
A **full game matching original UX** would take 6-12 months.

The scaffolding we have is valuable, but significant integration work remains.

---

## Next Actions

1. **TODAY**: Get ONE W3D model rendering on screen
2. **THIS WEEK**: Load real INI data for one unit type
3. **THIS SPRINT**: Make that unit selectable and moveable
4. **BUILD FROM THERE**: Add systems incrementally

Focus on **vertical slice** first - one complete path through the game.
