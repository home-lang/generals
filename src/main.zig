// C&C Generals Zero Hour - Zig Entry Point
// Main entry point that interfaces with the Objective-C/Metal rendering layer

const std = @import("std");
const game = @import("game/game.zig");

// =============================================================================
// External C Functions (implemented in Objective-C)
// =============================================================================

const MacOSWindow = extern struct {
    ns_app: ?*anyopaque,
    ns_window: ?*anyopaque,
    should_close: bool,
    key_up: bool,
    key_down: bool,
    key_left: bool,
    key_right: bool,
    key_w: bool,
    key_a: bool,
    key_s: bool,
    key_d: bool,
    // Number keys (for unit groups)
    key_1: bool,
    key_2: bool,
    key_3: bool,
    key_4: bool,
    key_5: bool,
    key_6: bool,
    key_7: bool,
    key_8: bool,
    key_9: bool,
    key_0: bool,
    // Modifier keys
    key_ctrl: bool,
    key_shift: bool,
    // Number key pressed this frame
    number_key_pressed: i8,
    // Mouse button state
    mouse_left_down: bool,
    mouse_right_down: bool,
    mouse_left_clicked: bool,
    mouse_right_clicked: bool,
};

extern fn macos_window_create(title: [*:0]const u8, width: u32, height: u32, resizable: bool) MacOSWindow;
extern fn macos_window_show(window: *MacOSWindow) void;
extern fn macos_window_poll_events(window: *MacOSWindow) bool;
extern fn macos_window_get_mouse_position(window: *MacOSWindow, x: *f32, y: *f32) void;
extern fn macos_window_get_keyboard_state(window: *MacOSWindow, up: *bool, down: *bool, left: *bool, right: *bool, w: *bool, a: *bool, s: *bool, d: *bool) void;
extern fn macos_window_get_mouse_button_state(window: *MacOSWindow, left_down: *bool, right_down: *bool, left_clicked: *bool, right_clicked: *bool) void;
extern fn macos_window_get_modifier_state(window: *MacOSWindow, ctrl: *bool, shift: *bool, number_pressed: *i8) void;
extern fn macos_window_destroy(window: *MacOSWindow) void;

// Sprite Renderer
const SpriteRenderer = extern struct {
    metal_device: ?*anyopaque,
    metal_command_queue: ?*anyopaque,
    metal_layer: ?*anyopaque,
    pipeline_state: ?*anyopaque,
    sampler_state: ?*anyopaque,
    vertex_buffer: ?*anyopaque,
    color_pipeline_state: ?*anyopaque,
    color_vertex_buffer: ?*anyopaque,
    viewport_width: f32,
    viewport_height: f32,
};

const RenderContext = extern struct {
    drawable: ?*anyopaque,
    command_buffer: ?*anyopaque,
    render_encoder: ?*anyopaque,
};

extern fn sprite_renderer_create(ns_window: ?*anyopaque) SpriteRenderer;
extern fn sprite_renderer_create_texture(renderer: *SpriteRenderer, width: u32, height: u32, data: [*]const u8) ?*anyopaque;
extern fn sprite_renderer_begin_frame(renderer: *SpriteRenderer) RenderContext;
extern fn sprite_renderer_end_frame(renderer: *SpriteRenderer, ctx: *RenderContext) void;
extern fn sprite_renderer_draw_rect(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, width: f32, height: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_draw_selection_circle(renderer: *SpriteRenderer, ctx: *RenderContext, center_x: f32, center_y: f32, radius: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_destroy_texture(texture: ?*anyopaque) void;
extern fn sprite_renderer_destroy(renderer: *SpriteRenderer) void;

// =============================================================================
// Game Constants
// =============================================================================

const GAME_TITLE = "Command & Conquer: Generals Zero Hour";
const GAME_VERSION = "1.04 (Home Reimplementation)";
const WINDOW_WIDTH: u32 = 1280;
const WINDOW_HEIGHT: u32 = 720;
const TARGET_FPS: f64 = 60.0;
const FRAME_TIME: f64 = 1.0 / TARGET_FPS;

// =============================================================================
// Visual Effects (keep in main for rendering purposes)
// =============================================================================

const Explosion = struct {
    x: f32,
    y: f32,
    radius: f32,
    max_radius: f32,
    lifetime: f32,
    max_lifetime: f32,
    is_active: bool,
};

const MuzzleFlash = struct {
    x: f32,
    y: f32,
    lifetime: f32,
    is_active: bool,
};

// =============================================================================
// Main Game State (combines modules with rendering state)
// =============================================================================

// Unit group (stores unit indices)
const UnitGroup = struct {
    unit_indices: [game.MAX_UNITS]usize,
    count: usize,

    pub fn init() UnitGroup {
        return UnitGroup{
            .unit_indices = undefined,
            .count = 0,
        };
    }

    pub fn clear(self: *UnitGroup) void {
        self.count = 0;
    }

    pub fn add(self: *UnitGroup, idx: usize) void {
        if (self.count < game.MAX_UNITS) {
            self.unit_indices[self.count] = idx;
            self.count += 1;
        }
    }
};

const MainState = struct {
    // Game logic state (from module)
    game_state: game.GameState,

    // Visual effects (rendering only)
    explosions: [32]Explosion,
    explosion_count: usize,
    muzzle_flashes: [32]MuzzleFlash,
    muzzle_flash_count: usize,

    // Selection box (drag selection)
    selection_start_x: f32,
    selection_start_y: f32,
    is_selecting: bool,
    selected_units: [game.MAX_UNITS]usize,
    selected_unit_count: usize,

    // Unit groups (1-9 hotkeys, index 0 = group 1, etc.)
    unit_groups: [10]UnitGroup,

    // Current mouse position (for rendering selection box)
    current_mouse_x: f32,
    current_mouse_y: f32,

    // Fog of War
    fog_of_war: game.FogOfWar,
    fog_enabled: bool,

    // AI Controllers (for enemy factions)
    ai_china: game.AIController,
    ai_gla: game.AIController,
    ai_china_money: i32,
    ai_gla_money: i32,
    ai_china_production: game.ProductionQueue,
    ai_gla_production: game.ProductionQueue,

    // Timing
    is_running: bool,
    frame_count: u64,

    pub fn init() MainState {
        var state = MainState{
            .game_state = game.GameState.init(),
            .explosions = undefined,
            .explosion_count = 0,
            .muzzle_flashes = undefined,
            .muzzle_flash_count = 0,
            .selection_start_x = 0,
            .selection_start_y = 0,
            .is_selecting = false,
            .selected_units = undefined,
            .selected_unit_count = 0,
            .unit_groups = [_]UnitGroup{UnitGroup.init()} ** 10,
            .current_mouse_x = 0,
            .current_mouse_y = 0,
            .fog_of_war = game.FogOfWar.init(),
            .fog_enabled = true,
            .ai_china = game.AIController.init(.China),
            .ai_gla = game.AIController.init(.GLA),
            .ai_china_money = 2000,
            .ai_gla_money = 2000,
            .ai_china_production = game.ProductionQueue.init(),
            .ai_gla_production = game.ProductionQueue.init(),
            .is_running = true,
            .frame_count = 0,
        };

        // Start in skirmish mode with initial units/buildings
        state.game_state.startSkirmish();

        // Add additional enemy units for more interesting combat
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(800, 550, .China, .Infantry));
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(820, 550, .China, .Infantry));
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(800, 600, .China, .Battlemaster));

        // Add GLA units
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(700, 150, .GLA, .Technical));
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(760, 170, .GLA, .Scorpion));
        _ = state.game_state.unit_manager.addUnit(game.Unit.create(680, 220, .GLA, .Infantry));

        // GLA buildings
        _ = state.game_state.building_manager.addBuilding(game.Building.create(650, 50, .CommandCenter, .GLA));
        _ = state.game_state.building_manager.addBuilding(game.Building.create(750, 60, .Barracks, .GLA));

        return state;
    }

    pub fn addExplosion(self: *MainState, x: f32, y: f32, max_radius: f32) void {
        if (self.explosion_count < 32) {
            self.explosions[self.explosion_count] = Explosion{
                .x = x,
                .y = y,
                .radius = 5,
                .max_radius = max_radius,
                .lifetime = 0.5,
                .max_lifetime = 0.5,
                .is_active = true,
            };
            self.explosion_count += 1;
        }
    }

    pub fn addMuzzleFlash(self: *MainState, x: f32, y: f32) void {
        if (self.muzzle_flash_count < 32) {
            self.muzzle_flashes[self.muzzle_flash_count] = MuzzleFlash{
                .x = x,
                .y = y,
                .lifetime = 0.1,
                .is_active = true,
            };
            self.muzzle_flash_count += 1;
        }
    }

    // Clear multi-selection
    pub fn clearMultiSelection(self: *MainState) void {
        // Deselect all previously selected units
        for (self.selected_units[0..self.selected_unit_count]) |idx| {
            if (self.game_state.unit_manager.getUnit(idx)) |unit| {
                unit.selected = false;
            }
        }
        self.selected_unit_count = 0;
        self.game_state.selected_unit_index = null;
    }

    // Add a unit to multi-selection
    pub fn addToSelection(self: *MainState, unit_idx: usize) void {
        // Check if already selected
        for (self.selected_units[0..self.selected_unit_count]) |idx| {
            if (idx == unit_idx) return;
        }
        if (self.selected_unit_count < game.MAX_UNITS) {
            self.selected_units[self.selected_unit_count] = unit_idx;
            self.selected_unit_count += 1;
            if (self.game_state.unit_manager.getUnit(unit_idx)) |unit| {
                unit.selected = true;
            }
            // Set first selected as the main selection for UI purposes
            if (self.selected_unit_count == 1) {
                self.game_state.selected_unit_index = unit_idx;
            }
        }
    }

    // Select units in a rectangle
    pub fn selectUnitsInRect(self: *MainState, x1: f32, y1: f32, x2: f32, y2: f32) void {
        const min_x = @min(x1, x2);
        const max_x = @max(x1, x2);
        const min_y = @min(y1, y2);
        const max_y = @max(y1, y2);

        for (self.game_state.unit_manager.getUnits(), 0..) |*unit, i| {
            if (!unit.is_alive) continue;
            // Only select player's units
            if (unit.faction != self.game_state.player_faction) continue;

            if (unit.x >= min_x and unit.x <= max_x and
                unit.y >= min_y and unit.y <= max_y)
            {
                self.addToSelection(i);
            }
        }
    }

    // Move all selected units
    pub fn moveSelectedUnits(self: *MainState, target_x: f32, target_y: f32) void {
        if (self.selected_unit_count == 0) return;

        // Calculate formation offsets for multiple units
        const spacing: f32 = 30.0;
        var col: usize = 0;
        var row: usize = 0;
        const units_per_row: usize = 5;

        for (self.selected_units[0..self.selected_unit_count]) |idx| {
            if (self.game_state.unit_manager.getUnit(idx)) |unit| {
                const offset_x = @as(f32, @floatFromInt(col)) * spacing - @as(f32, @floatFromInt(units_per_row / 2)) * spacing;
                const offset_y = @as(f32, @floatFromInt(row)) * spacing;
                unit.moveTo(target_x + offset_x, target_y + offset_y);

                col += 1;
                if (col >= units_per_row) {
                    col = 0;
                    row += 1;
                }
            }
        }
    }

    // Assign selected units to a group
    pub fn assignGroup(self: *MainState, group_num: usize) void {
        if (group_num >= 10) return;
        self.unit_groups[group_num].clear();
        for (self.selected_units[0..self.selected_unit_count]) |idx| {
            self.unit_groups[group_num].add(idx);
        }
        std.debug.print("[GROUP] Assigned {d} units to group {d}\n", .{ self.selected_unit_count, group_num + 1 });
    }

    // Recall a unit group
    pub fn recallGroup(self: *MainState, group_num: usize) void {
        if (group_num >= 10) return;
        const group = &self.unit_groups[group_num];
        if (group.count == 0) return;

        self.clearMultiSelection();
        for (group.unit_indices[0..group.count]) |idx| {
            // Verify unit is still alive
            if (self.game_state.unit_manager.getUnit(idx)) |unit| {
                if (unit.is_alive) {
                    self.addToSelection(idx);
                }
            }
        }
        std.debug.print("[GROUP] Recalled group {d} ({d} units)\n", .{ group_num + 1, self.selected_unit_count });
    }
};

// =============================================================================
// Input Handling
// =============================================================================

fn handleInput(state: *MainState, window: *MacOSWindow, dt: f32) void {
    var up: bool = false;
    var down: bool = false;
    var left: bool = false;
    var right: bool = false;
    var w: bool = false;
    var a: bool = false;
    var s: bool = false;
    var d: bool = false;
    macos_window_get_keyboard_state(window, &up, &down, &left, &right, &w, &a, &s, &d);

    var mouse_x: f32 = 0;
    var mouse_y: f32 = 0;
    macos_window_get_mouse_position(window, &mouse_x, &mouse_y);

    // Store current mouse position for rendering
    state.current_mouse_x = mouse_x;
    state.current_mouse_y = mouse_y;

    var left_down: bool = false;
    var right_down: bool = false;
    var left_clicked: bool = false;
    var right_clicked: bool = false;
    macos_window_get_mouse_button_state(window, &left_down, &right_down, &left_clicked, &right_clicked);

    // Get modifier keys and number key pressed
    var ctrl: bool = false;
    var shift: bool = false;
    var number_pressed: i8 = -1;
    macos_window_get_modifier_state(window, &ctrl, &shift, &number_pressed);

    // Camera movement
    const camera_speed: f32 = 300.0;
    var cam_dx: f32 = 0;
    var cam_dy: f32 = 0;
    if (up or w) cam_dy -= camera_speed * dt;
    if (down or s) cam_dy += camera_speed * dt;
    if (left or a) cam_dx -= camera_speed * dt;
    if (right or d) cam_dx += camera_speed * dt;
    state.game_state.moveCamera(cam_dx, cam_dy);

    // Handle unit group hotkeys (1-9)
    if (number_pressed >= 0 and number_pressed <= 9) {
        const group_idx: usize = @intCast(number_pressed);
        // Map: 1-9 -> groups 0-8, 0 -> group 9
        const actual_group = if (group_idx == 0) 9 else group_idx - 1;

        if (ctrl) {
            // Ctrl+number: Assign selected units to group
            state.assignGroup(actual_group);
        } else {
            // Number only: Recall group
            state.recallGroup(actual_group);
        }
    }

    // Drag selection - start
    if (left_clicked and !state.is_selecting) {
        // Skip if clicking on UI area
        if (mouse_y < 720 - 100 and mouse_y > 40) {
            // Check if clicking directly on a unit first
            var clicked_on_unit = false;
            for (state.game_state.unit_manager.getUnits(), 0..) |*unit, i| {
                if (!unit.is_alive) continue;
                const ux = mouse_x - unit.x;
                const uy = mouse_y - unit.y;
                const dist_sq = ux * ux + uy * uy;
                const radius = unit.size / 2;
                if (dist_sq < radius * radius) {
                    // Direct click on a unit - select just this one (unless shift)
                    if (!shift) {
                        state.clearMultiSelection();
                        state.game_state.clearSelection();
                    }
                    state.addToSelection(i);
                    clicked_on_unit = true;
                    break;
                }
            }

            if (!clicked_on_unit) {
                // Check buildings
                var clicked_on_building = false;
                for (state.game_state.building_manager.getBuildings(), 0..) |building, i| {
                    if (building.faction != state.game_state.player_faction) continue;
                    if (mouse_x >= building.x and mouse_x < building.x + building.width and
                        mouse_y >= building.y and mouse_y < building.y + building.height)
                    {
                        state.clearMultiSelection();
                        state.game_state.clearSelection();
                        state.game_state.selectBuilding(i);
                        clicked_on_building = true;
                        break;
                    }
                }

                if (!clicked_on_building) {
                    // Start drag selection
                    state.selection_start_x = mouse_x;
                    state.selection_start_y = mouse_y;
                    state.is_selecting = true;
                    if (!shift) {
                        state.clearMultiSelection();
                        state.game_state.clearSelection();
                    }
                }
            }
        } else if (mouse_y >= 720 - 100) {
            // Check build buttons
            if (state.game_state.selected_building_index) |bld_idx| {
                if (state.game_state.building_manager.getBuilding(bld_idx)) |building| {
                    handleBuildButtonClick(state, building, bld_idx, mouse_x);
                }
            }
        }
    }

    // Drag selection - end
    if (!left_down and state.is_selecting) {
        state.is_selecting = false;
        // Select units in the rectangle
        state.selectUnitsInRect(state.selection_start_x, state.selection_start_y, mouse_x, mouse_y);
    }

    // Unit movement - right click moves all selected units
    if (right_clicked) {
        if (state.selected_unit_count > 0) {
            state.moveSelectedUnits(mouse_x, mouse_y);
        } else if (state.game_state.selected_unit_index) |idx| {
            // Fallback to single selection
            if (state.game_state.unit_manager.getUnit(idx)) |unit| {
                unit.moveTo(mouse_x, mouse_y);
            }
        }
    }
}

fn handleBuildButtonClick(state: *MainState, building: *game.Building, bld_idx: usize, mouse_x: f32) void {
    const btn_width: f32 = 60;
    const btn_spacing: f32 = 70;

    for (0..6) |btn_i| {
        const btn_x: f32 = 20 + @as(f32, @floatFromInt(btn_i)) * btn_spacing;
        if (mouse_x >= btn_x and mouse_x < btn_x + btn_width) {
            if (building.building_type == .Barracks) {
                if (btn_i == 0) {
                    _ = state.game_state.queueProduction(.Infantry, bld_idx);
                }
            } else if (building.building_type == .WarFactory) {
                if (btn_i == 0) {
                    _ = state.game_state.queueProduction(.Crusader, bld_idx);
                } else if (btn_i == 1) {
                    _ = state.game_state.queueProduction(.Paladin, bld_idx);
                }
            }
            break;
        }
    }
}

// =============================================================================
// Game Update
// =============================================================================

fn updateGame(state: *MainState, dt: f32) void {
    // Update all units
    for (state.game_state.unit_manager.getUnits()) |*unit| {
        unit.update(dt);
    }

    // Combat system
    processCombat(state, dt);

    // Update production (player)
    state.game_state.updateProduction(dt);

    // Update AI production queues
    updateAIProduction(state, dt);

    // Update AI controllers
    state.ai_china.update(
        dt,
        &state.game_state.unit_manager,
        &state.game_state.building_manager,
        &state.ai_china_production,
        &state.ai_china_money,
    );
    state.ai_gla.update(
        dt,
        &state.game_state.unit_manager,
        &state.game_state.building_manager,
        &state.ai_gla_production,
        &state.ai_gla_money,
    );

    // Give AI income over time
    if (state.frame_count % 120 == 0) { // Every 2 seconds at 60fps
        state.ai_china_money += 100;
        state.ai_gla_money += 100;
    }

    // Update fog of war
    updateFogOfWar(state);

    // Update visual effects
    updateExplosions(state, dt);
    updateMuzzleFlashes(state, dt);

    state.frame_count += 1;
}

fn updateAIProduction(state: *MainState, dt: f32) void {
    // Update China AI production
    if (state.ai_china_production.update(dt)) |completed_type| {
        // Find spawn point from building
        const bld_idx = state.ai_china_production.building_idx;
        if (state.game_state.building_manager.getBuilding(bld_idx)) |building| {
            const spawn = building.getSpawnPoint();
            _ = state.game_state.unit_manager.addUnit(game.Unit.create(spawn.x, spawn.y, .China, completed_type));
            std.debug.print("[AI China] Produced unit: {any}\n", .{completed_type});
        }
    }

    // Update GLA AI production
    if (state.ai_gla_production.update(dt)) |completed_type| {
        const bld_idx = state.ai_gla_production.building_idx;
        if (state.game_state.building_manager.getBuilding(bld_idx)) |building| {
            const spawn = building.getSpawnPoint();
            _ = state.game_state.unit_manager.addUnit(game.Unit.create(spawn.x, spawn.y, .GLA, completed_type));
            std.debug.print("[AI GLA] Produced unit: {any}\n", .{completed_type});
        }
    }
}

fn updateFogOfWar(state: *MainState) void {
    if (!state.fog_enabled) return;

    // Reset visibility to explored state
    state.fog_of_war.resetVisibility();

    // Reveal areas around player units
    const vision_radius: f32 = 150.0; // Default unit vision
    for (state.game_state.unit_manager.units[0..state.game_state.unit_manager.count]) |unit| {
        if (unit.faction == state.game_state.player_faction and unit.is_alive) {
            state.fog_of_war.revealArea(unit.x, unit.y, vision_radius);
        }
    }

    // Reveal areas around player buildings
    const building_vision: f32 = 200.0;
    for (state.game_state.building_manager.buildings[0..state.game_state.building_manager.count]) |building| {
        if (building.faction == state.game_state.player_faction) {
            state.fog_of_war.revealArea(
                building.x + building.width / 2,
                building.y + building.height / 2,
                building_vision,
            );
        }
    }
}

fn processCombat(state: *MainState, dt: f32) void {
    const all_units = state.game_state.unit_manager.getUnits();

    for (all_units, 0..) |*unit, i| {
        if (!unit.is_alive) continue;
        if (unit.attack_timer > 0) continue;

        // Find nearest enemy
        var closest_enemy: ?usize = null;
        var closest_dist: f32 = unit.attack_range;

        for (all_units, 0..) |*other, j| {
            if (i == j or !other.is_alive) continue;
            if (other.faction == unit.faction) continue;

            const dist = unit.distanceTo(other);
            if (dist < closest_dist) {
                closest_dist = dist;
                closest_enemy = j;
            }
        }

        // Attack
        if (closest_enemy) |enemy_idx| {
            if (state.game_state.unit_manager.getUnit(enemy_idx)) |target| {
                unit.attack(enemy_idx);

                // Add muzzle flash
                state.addMuzzleFlash(unit.x, unit.y);

                // Deal damage
                const died = target.takeDamage(unit.damage);
                if (died) {
                    state.addExplosion(target.x, target.y, target.size);
                    std.debug.print("[COMBAT] Unit destroyed!\n", .{});
                }
            }
        }
    }
    _ = dt;
}

fn updateExplosions(state: *MainState, dt: f32) void {
    var idx: usize = 0;
    while (idx < state.explosion_count) {
        var exp = &state.explosions[idx];
        if (exp.is_active) {
            exp.lifetime -= dt;
            const progress = 1.0 - (exp.lifetime / exp.max_lifetime);
            exp.radius = exp.max_radius * progress;

            if (exp.lifetime <= 0) {
                exp.is_active = false;
                if (idx < state.explosion_count - 1) {
                    state.explosions[idx] = state.explosions[state.explosion_count - 1];
                }
                state.explosion_count -= 1;
                continue;
            }
        }
        idx += 1;
    }
}

fn updateMuzzleFlashes(state: *MainState, dt: f32) void {
    var idx: usize = 0;
    while (idx < state.muzzle_flash_count) {
        var flash = &state.muzzle_flashes[idx];
        if (flash.is_active) {
            flash.lifetime -= dt;
            if (flash.lifetime <= 0) {
                flash.is_active = false;
                if (idx < state.muzzle_flash_count - 1) {
                    state.muzzle_flashes[idx] = state.muzzle_flashes[state.muzzle_flash_count - 1];
                }
                state.muzzle_flash_count -= 1;
                continue;
            }
        }
        idx += 1;
    }
}

// =============================================================================
// Rendering
// =============================================================================

fn drawDigit(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, digit: u8, r: f32, g: f32, b: f32) void {
    const w_d: f32 = 8;
    const h: f32 = 14;
    const t: f32 = 2;

    const patterns = [10][7]bool{
        .{ true, true, true, true, true, true, false },
        .{ false, true, true, false, false, false, false },
        .{ true, true, false, true, true, false, true },
        .{ true, true, true, true, false, false, true },
        .{ false, true, true, false, false, true, true },
        .{ true, false, true, true, false, true, true },
        .{ true, false, true, true, true, true, true },
        .{ true, true, true, false, false, false, false },
        .{ true, true, true, true, true, true, true },
        .{ true, true, true, true, false, true, true },
    };

    const d = if (digit < 10) digit else 0;
    const p = patterns[d];

    if (p[0]) sprite_renderer_draw_rect(renderer, ctx, x, y, w_d, t, r, g, b, 1.0);
    if (p[1]) sprite_renderer_draw_rect(renderer, ctx, x + w_d - t, y, t, h / 2, r, g, b, 1.0);
    if (p[2]) sprite_renderer_draw_rect(renderer, ctx, x + w_d - t, y + h / 2, t, h / 2, r, g, b, 1.0);
    if (p[3]) sprite_renderer_draw_rect(renderer, ctx, x, y + h - t, w_d, t, r, g, b, 1.0);
    if (p[4]) sprite_renderer_draw_rect(renderer, ctx, x, y + h / 2, t, h / 2, r, g, b, 1.0);
    if (p[5]) sprite_renderer_draw_rect(renderer, ctx, x, y, t, h / 2, r, g, b, 1.0);
    if (p[6]) sprite_renderer_draw_rect(renderer, ctx, x, y + h / 2 - t / 2, w_d, t, r, g, b, 1.0);
}

fn drawNumber(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, value: i32, r: f32, g: f32, b: f32) void {
    const digit_spacing: f32 = 10;
    const num: u32 = if (value >= 0) @intCast(value) else @intCast(-value);

    var digit_count: u32 = 0;
    var temp = num;
    while (temp > 0) : (temp /= 10) {
        digit_count += 1;
    }
    if (digit_count == 0) digit_count = 1;

    var pos_x = x + @as(f32, @floatFromInt(digit_count - 1)) * digit_spacing;
    var n = num;
    for (0..digit_count) |_| {
        const digit: u8 = @intCast(n % 10);
        drawDigit(renderer, ctx, pos_x, y, digit, r, g, b);
        n /= 10;
        pos_x -= digit_spacing;
    }
}

fn getFactionColors(faction: game.Faction) struct { r: f32, g: f32, b: f32 } {
    return switch (faction) {
        .USA => .{ .r = 0.2, .g = 0.4, .b = 0.8 },
        .China => .{ .r = 0.8, .g = 0.2, .b = 0.2 },
        .GLA => .{ .r = 0.7, .g = 0.5, .b = 0.2 },
    };
}

fn renderGame(renderer: *SpriteRenderer, state: *const MainState) void {
    var ctx = sprite_renderer_begin_frame(renderer);
    if (ctx.render_encoder == null) return;

    // Terrain
    renderTerrain(renderer, &ctx);

    // Buildings (with fog check)
    renderBuildings(renderer, &ctx, state);

    // Units (with fog check)
    renderUnits(renderer, &ctx, state);

    // Selection box (if dragging)
    renderSelectionBox(renderer, &ctx, state);

    // Fog of War overlay
    renderFogOfWar(renderer, &ctx, state);

    // Effects
    renderEffects(renderer, &ctx, state);

    // UI
    renderUI(renderer, &ctx, state);

    sprite_renderer_end_frame(renderer, &ctx);
}

fn renderFogOfWar(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    if (!state.fog_enabled) return;

    const tile_size = game.FOG_TILE_SIZE;

    for (0..game.FOG_MAP_HEIGHT) |ty| {
        for (0..game.FOG_MAP_WIDTH) |tx| {
            const fog_state = state.fog_of_war.getState(tx, ty);
            const px = @as(f32, @floatFromInt(tx)) * tile_size;
            const py = @as(f32, @floatFromInt(ty)) * tile_size;

            switch (fog_state) {
                .Unexplored => {
                    // Completely black
                    sprite_renderer_draw_rect(renderer, ctx, px, py, tile_size, tile_size, 0.0, 0.0, 0.0, 1.0);
                },
                .Explored => {
                    // Semi-transparent dark
                    sprite_renderer_draw_rect(renderer, ctx, px, py, tile_size, tile_size, 0.0, 0.0, 0.0, 0.6);
                },
                .Visible => {
                    // No overlay - fully visible
                },
            }
        }
    }
}

fn renderSelectionBox(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    if (!state.is_selecting) return;

    const x1 = state.selection_start_x;
    const y1 = state.selection_start_y;
    const x2 = state.current_mouse_x;
    const y2 = state.current_mouse_y;

    const min_x = @min(x1, x2);
    const max_x = @max(x1, x2);
    const min_y = @min(y1, y2);
    const max_y = @max(y1, y2);
    const box_w = max_x - min_x;
    const box_h = max_y - min_y;

    // Draw selection box outline (green semi-transparent)
    const line_thickness: f32 = 2;

    // Top line
    sprite_renderer_draw_rect(renderer, ctx, min_x, min_y, box_w, line_thickness, 0.0, 1.0, 0.0, 0.8);
    // Bottom line
    sprite_renderer_draw_rect(renderer, ctx, min_x, max_y - line_thickness, box_w, line_thickness, 0.0, 1.0, 0.0, 0.8);
    // Left line
    sprite_renderer_draw_rect(renderer, ctx, min_x, min_y, line_thickness, box_h, 0.0, 1.0, 0.0, 0.8);
    // Right line
    sprite_renderer_draw_rect(renderer, ctx, max_x - line_thickness, min_y, line_thickness, box_h, 0.0, 1.0, 0.0, 0.8);

    // Draw semi-transparent fill
    sprite_renderer_draw_rect(renderer, ctx, min_x, min_y, box_w, box_h, 0.0, 1.0, 0.0, 0.15);
}

fn renderTerrain(renderer: *SpriteRenderer, ctx: *RenderContext) void {
    sprite_renderer_draw_rect(renderer, ctx, 0, 0, 1280, 720, 0.6, 0.5, 0.3, 1.0);

    const tile_size: f32 = 64;
    var row: u32 = 0;
    while (row < 12) : (row += 1) {
        var col: u32 = 0;
        while (col < 20) : (col += 1) {
            const tx = @as(f32, @floatFromInt(col)) * tile_size;
            const ty = @as(f32, @floatFromInt(row)) * tile_size;

            if ((row + col) % 2 == 0) {
                sprite_renderer_draw_rect(renderer, ctx, tx, ty, tile_size, tile_size, 0.4, 0.55, 0.3, 1.0);
            } else {
                sprite_renderer_draw_rect(renderer, ctx, tx, ty, tile_size, tile_size, 0.65, 0.55, 0.35, 1.0);
            }
        }
    }

    // Grid lines
    var y: f32 = 0;
    while (y < 720) : (y += tile_size) {
        sprite_renderer_draw_rect(renderer, ctx, 0, y, 1280, 1, 0.2, 0.2, 0.15, 0.3);
    }
    var x: f32 = 0;
    while (x < 1280) : (x += tile_size) {
        sprite_renderer_draw_rect(renderer, ctx, x, 0, 1, 720, 0.2, 0.2, 0.15, 0.3);
    }
}

fn renderBuildings(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    for (state.game_state.building_manager.buildings[0..state.game_state.building_manager.count], 0..) |building, i| {
        const colors = getFactionColors(building.faction);
        const r = colors.r + 0.1;
        const g = colors.g + 0.1;
        const b = colors.b - 0.1;

        // Building body
        sprite_renderer_draw_rect(renderer, ctx, building.x, building.y, building.width, building.height, r, g, b, 1.0);

        // Border
        sprite_renderer_draw_rect(renderer, ctx, building.x, building.y, building.width, 3, r * 0.6, g * 0.6, b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, building.x, building.y + building.height - 3, building.width, 3, r * 0.6, g * 0.6, b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, building.x, building.y, 3, building.height, r * 0.6, g * 0.6, b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, building.x + building.width - 3, building.y, 3, building.height, r * 0.6, g * 0.6, b * 0.6, 1.0);

        // Detail
        sprite_renderer_draw_rect(renderer, ctx, building.x + building.width * 0.35, building.y + building.height * 0.35, building.width * 0.3, building.height * 0.3, r * 1.3, g * 1.3, b * 1.3, 1.0);

        // Health bar
        const health_pct = building.health / building.max_health;
        sprite_renderer_draw_rect(renderer, ctx, building.x, building.y - 10, building.width, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, ctx, building.x + 1, building.y - 9, (building.width - 2) * health_pct, 4, 0.0, 0.9, 0.0, 1.0);

        // Selection highlight
        if (state.game_state.selected_building_index) |sel_idx| {
            if (sel_idx == i) {
                sprite_renderer_draw_rect(renderer, ctx, building.x - 2, building.y - 2, building.width + 4, 2, 0.0, 1.0, 0.0, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, building.x - 2, building.y + building.height, building.width + 4, 2, 0.0, 1.0, 0.0, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, building.x - 2, building.y, 2, building.height, 0.0, 1.0, 0.0, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, building.x + building.width, building.y, 2, building.height, 0.0, 1.0, 0.0, 1.0);
            }
        }
    }
}

fn renderUnits(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    for (state.game_state.unit_manager.units[0..state.game_state.unit_manager.count]) |unit| {
        if (!unit.is_alive) continue;

        // Skip enemy units not in visible area (fog of war)
        if (state.fog_enabled and unit.faction != state.game_state.player_faction) {
            if (!state.fog_of_war.isVisible(unit.x, unit.y)) continue;
        }

        const half_size = unit.size / 2;
        const colors = getFactionColors(unit.faction);

        // Selection circle
        if (unit.selected) {
            sprite_renderer_draw_selection_circle(renderer, ctx, unit.x, unit.y, unit.size * 0.7, 0.0, 1.0, 0.0, 1.0);
        }

        // Unit body
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size, unit.y - half_size, unit.size, unit.size, colors.r, colors.g, colors.b, 1.0);

        // Border
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size, unit.y - half_size, unit.size, 2, colors.r * 0.5, colors.g * 0.5, colors.b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size, unit.y + half_size - 2, unit.size, 2, colors.r * 0.5, colors.g * 0.5, colors.b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size, unit.y - half_size, 2, unit.size, colors.r * 0.5, colors.g * 0.5, colors.b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, unit.x + half_size - 2, unit.y - half_size, 2, unit.size, colors.r * 0.5, colors.g * 0.5, colors.b * 0.5, 1.0);

        // Unit type detail
        if (unit.unit_type == .Infantry) {
            sprite_renderer_draw_rect(renderer, ctx, unit.x - 4, unit.y - 6, 8, 8, 0.9, 0.75, 0.6, 1.0);
            sprite_renderer_draw_rect(renderer, ctx, unit.x - 5, unit.y + 2, 10, 8, colors.r * 0.8, colors.g * 0.8, colors.b * 0.8, 1.0);
        } else {
            sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size * 0.4, unit.y - half_size * 0.4, unit.size * 0.4, unit.size * 0.4, colors.r * 0.7, colors.g * 0.7, colors.b * 0.7, 1.0);
            sprite_renderer_draw_rect(renderer, ctx, unit.x, unit.y - half_size * 0.2, half_size * 0.8, 4, 0.3, 0.3, 0.3, 1.0);
        }

        // Health bar
        const health_pct = unit.health / unit.max_health;
        const bar_r: f32 = if (health_pct < 0.3) 0.9 else if (health_pct < 0.6) 0.9 else 0.0;
        const bar_g: f32 = if (health_pct < 0.3) 0.0 else if (health_pct < 0.6) 0.7 else 0.9;
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size, unit.y - half_size - 10, unit.size, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, ctx, unit.x - half_size + 1, unit.y - half_size - 9, (unit.size - 2) * health_pct, 4, bar_r, bar_g, 0.0, 1.0);
    }
}

fn renderEffects(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    // Explosions
    for (state.explosions[0..state.explosion_count]) |exp| {
        if (exp.is_active) {
            const alpha = exp.lifetime / exp.max_lifetime;
            sprite_renderer_draw_selection_circle(renderer, ctx, exp.x, exp.y, exp.radius, 1.0, 0.5, 0.0, alpha);
            sprite_renderer_draw_rect(renderer, ctx, exp.x - exp.radius * 0.5, exp.y - exp.radius * 0.5, exp.radius, exp.radius, 1.0, 0.8, 0.2, alpha * 0.8);
        }
    }

    // Muzzle flashes
    for (state.muzzle_flashes[0..state.muzzle_flash_count]) |flash| {
        if (flash.is_active) {
            const alpha = flash.lifetime / 0.1;
            sprite_renderer_draw_rect(renderer, ctx, flash.x - 8, flash.y - 8, 16, 16, 1.0, 1.0, 0.5, alpha);
            sprite_renderer_draw_rect(renderer, ctx, flash.x - 4, flash.y - 4, 8, 8, 1.0, 1.0, 1.0, alpha);
        }
    }

    // Attack lines
    for (state.game_state.unit_manager.units[0..state.game_state.unit_manager.count]) |unit| {
        if (!unit.is_alive or unit.attack_timer <= 0.8) continue;
        if (unit.target_unit) |target_idx| {
            if (target_idx < state.game_state.unit_manager.count) {
                const target = state.game_state.unit_manager.units[target_idx];
                if (target.is_alive) {
                    const dx = target.x - unit.x;
                    const dy = target.y - unit.y;
                    const dist = @sqrt(dx * dx + dy * dy);
                    const steps: usize = @intFromFloat(dist / 8.0);
                    if (steps > 0) {
                        const step_x = dx / @as(f32, @floatFromInt(steps));
                        const step_y = dy / @as(f32, @floatFromInt(steps));
                        var px = unit.x;
                        var py = unit.y;
                        for (0..@min(steps, 20)) |_| {
                            sprite_renderer_draw_rect(renderer, ctx, px - 1, py - 1, 2, 2, 1.0, 0.3, 0.0, 0.7);
                            px += step_x;
                            py += step_y;
                        }
                    }
                }
            }
        }
    }
}

fn renderUI(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    // Top bar
    sprite_renderer_draw_rect(renderer, ctx, 0, 0, 1280, 40, 0.1, 0.1, 0.15, 0.95);

    // Money
    sprite_renderer_draw_rect(renderer, ctx, 10, 8, 24, 24, 0.9, 0.8, 0.0, 1.0);
    sprite_renderer_draw_rect(renderer, ctx, 14, 12, 16, 16, 0.7, 0.6, 0.0, 1.0);
    drawNumber(renderer, ctx, 40, 12, state.game_state.player_money, 0.9, 0.8, 0.0);

    // Power
    sprite_renderer_draw_rect(renderer, ctx, 150, 8, 24, 24, 0.0, 0.8, 0.9, 1.0);
    drawNumber(renderer, ctx, 180, 12, state.game_state.player_power, 0.0, 0.9, 0.9);

    // Minimap
    renderMinimap(renderer, ctx, state);

    // Control bar
    sprite_renderer_draw_rect(renderer, ctx, 0, 720 - 100, 1280, 100, 0.12, 0.12, 0.15, 0.95);

    // Build buttons
    renderBuildButtons(renderer, ctx, state);

    // Production progress
    if (state.game_state.production_queue.count > 0) {
        const progress = state.game_state.production_queue.getProgress();
        sprite_renderer_draw_rect(renderer, ctx, 450, 720 - 85, 100, 12, 0.2, 0.2, 0.2, 1.0);
        sprite_renderer_draw_rect(renderer, ctx, 451, 720 - 84, 98 * progress, 10, 0.0, 0.8, 0.3, 1.0);
    }

    // Unit portrait
    sprite_renderer_draw_rect(renderer, ctx, 600, 720 - 95, 90, 85, 0.2, 0.2, 0.25, 1.0);
    if (state.game_state.selected_unit_index) |idx| {
        if (state.game_state.unit_manager.getUnitConst(idx)) |unit| {
            if (unit.is_alive) {
                const px: f32 = 610;
                const py: f32 = 720 - 85;
                if (unit.unit_type == .Infantry) {
                    sprite_renderer_draw_rect(renderer, ctx, px + 30, py + 10, 15, 15, 0.8, 0.7, 0.5, 1.0);
                    sprite_renderer_draw_rect(renderer, ctx, px + 25, py + 30, 25, 35, 0.2, 0.4, 0.8, 1.0);
                } else {
                    sprite_renderer_draw_rect(renderer, ctx, px + 10, py + 35, 55, 25, 0.2, 0.4, 0.8, 1.0);
                    sprite_renderer_draw_rect(renderer, ctx, px + 25, py + 15, 25, 22, 0.15, 0.35, 0.7, 1.0);
                }
                const hp_ratio = unit.health / unit.max_health;
                sprite_renderer_draw_rect(renderer, ctx, px, py + 65, 70, 8, 0.3, 0.1, 0.1, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, px + 1, py + 66, 68 * hp_ratio, 6, 0.1, 0.8, 0.1, 1.0);
            }
        }
    }
}

fn renderMinimap(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    const mx: f32 = 1280 - 180;
    const my: f32 = 720 - 150;
    const mw: f32 = 170;
    const mh: f32 = 140;

    sprite_renderer_draw_rect(renderer, ctx, mx, my, mw, mh, 0.05, 0.1, 0.05, 0.95);
    sprite_renderer_draw_rect(renderer, ctx, mx + 5, my + 5, mw - 10, mh - 10, 0.3, 0.4, 0.2, 1.0);

    const scale_x = (mw - 10) / 1280.0;
    const scale_y = (mh - 10) / 720.0;

    // Buildings
    for (state.game_state.building_manager.buildings[0..state.game_state.building_manager.count]) |building| {
        const bx = mx + 5 + building.x * scale_x;
        const by = my + 5 + building.y * scale_y;
        const colors = getFactionColors(building.faction);
        sprite_renderer_draw_rect(renderer, ctx, bx - 3, by - 3, 6, 6, colors.r, colors.g, colors.b, 1.0);
    }

    // Units
    for (state.game_state.unit_manager.units[0..state.game_state.unit_manager.count]) |unit| {
        if (!unit.is_alive) continue;
        const ux = mx + 5 + unit.x * scale_x;
        const uy = my + 5 + unit.y * scale_y;
        const colors = getFactionColors(unit.faction);
        const dot_size: f32 = if (unit.selected) 5 else 3;
        sprite_renderer_draw_rect(renderer, ctx, ux - dot_size / 2, uy - dot_size / 2, dot_size, dot_size, colors.r + 0.1, colors.g + 0.1, colors.b + 0.1, 1.0);
    }
}

fn renderBuildButtons(renderer: *SpriteRenderer, ctx: *RenderContext, state: *const MainState) void {
    if (state.game_state.selected_building_index) |bld_idx| {
        if (state.game_state.building_manager.getBuildingConst(bld_idx)) |building| {
            if (building.building_type == .Barracks) {
                sprite_renderer_draw_rect(renderer, ctx, 20, 720 - 90, 60, 60, 0.3, 0.4, 0.3, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, 22, 720 - 88, 56, 56, 0.15, 0.25, 0.15, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, 45, 720 - 80, 10, 10, 0.8, 0.7, 0.5, 1.0);
                sprite_renderer_draw_rect(renderer, ctx, 42, 720 - 68, 16, 20, 0.2, 0.4, 0.8, 1.0);
                drawNumber(renderer, ctx, 25, 720 - 42, 200, 0.9, 0.8, 0.0);
            } else if (building.building_type == .WarFactory) {
                for (0..2) |btn_i| {
                    const btn_x: f32 = 20 + @as(f32, @floatFromInt(btn_i)) * 70;
                    sprite_renderer_draw_rect(renderer, ctx, btn_x, 720 - 90, 60, 60, 0.3, 0.35, 0.4, 1.0);
                    sprite_renderer_draw_rect(renderer, ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.2, 0.25, 1.0);
                    sprite_renderer_draw_rect(renderer, ctx, btn_x + 10, 720 - 70, 40, 20, 0.2, 0.4, 0.8, 1.0);
                    sprite_renderer_draw_rect(renderer, ctx, btn_x + 20, 720 - 80, 20, 15, 0.15, 0.35, 0.7, 1.0);
                    const cost: i32 = if (btn_i == 0) 800 else 1100;
                    drawNumber(renderer, ctx, btn_x + 5, 720 - 42, cost, 0.9, 0.8, 0.0);
                }
            }
        }
    }

    // Empty buttons
    for (0..6) |i| {
        const btn_x: f32 = 20 + @as(f32, @floatFromInt(i)) * 70;
        if (state.game_state.selected_building_index == null) {
            sprite_renderer_draw_rect(renderer, ctx, btn_x, 720 - 90, 60, 60, 0.25, 0.25, 0.3, 1.0);
            sprite_renderer_draw_rect(renderer, ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.15, 0.2, 1.0);
        }
    }
}

// =============================================================================
// Main Entry Point
// =============================================================================

pub fn main() !void {
    const print = std.debug.print;

    print("================================================================================\n", .{});
    print("  {s}\n", .{GAME_TITLE});
    print("  Version: {s}\n", .{GAME_VERSION});
    print("  Modular Architecture - Clean Code Refactor\n", .{});
    print("================================================================================\n\n", .{});

    // Create window
    print("Creating window...\n", .{});
    var window = macos_window_create(GAME_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, true);
    defer macos_window_destroy(&window);

    if (window.ns_window == null) {
        print("ERROR: Failed to create window\n", .{});
        return;
    }

    macos_window_show(&window);
    print("Window created and shown\n", .{});

    // Create renderer
    print("Creating Metal renderer...\n", .{});
    var renderer = sprite_renderer_create(window.ns_window);
    defer sprite_renderer_destroy(&renderer);

    if (renderer.metal_device == null) {
        print("ERROR: Failed to create renderer\n", .{});
        return;
    }
    print("Renderer created successfully\n", .{});

    // Initialize game state
    var state = MainState.init();
    print("Game state initialized (modular)\n", .{});

    print("\nStarting game loop...\n", .{});
    print("Controls:\n", .{});
    print("  - Arrow keys or WASD: Move camera\n", .{});
    print("  - Left click: Select unit/building\n", .{});
    print("  - Left drag: Box select multiple units\n", .{});
    print("  - Shift+click: Add to selection\n", .{});
    print("  - Right click: Move selected unit(s)\n", .{});
    print("  - Ctrl+1-9: Assign units to group\n", .{});
    print("  - 1-9: Recall unit group\n", .{});
    print("  - Click build buttons when building selected\n", .{});
    print("  - Cmd+Q: Quit\n\n", .{});

    // Game loop
    var last_instant = std.time.Instant.now() catch {
        print("ERROR: Timer not supported\n", .{});
        return;
    };

    while (state.is_running) {
        const current_instant = std.time.Instant.now() catch last_instant;
        const dt_ns = current_instant.since(last_instant);
        const dt: f32 = @as(f32, @floatFromInt(dt_ns)) / 1_000_000_000.0;
        last_instant = current_instant;

        if (!macos_window_poll_events(&window)) {
            state.is_running = false;
            break;
        }

        handleInput(&state, &window, dt);
        updateGame(&state, dt);
        renderGame(&renderer, &state);

        // Frame rate limiting
        const frame_end = std.time.Instant.now() catch current_instant;
        const frame_duration_ns = frame_end.since(current_instant);
        const target_ns: u64 = @intFromFloat(FRAME_TIME * 1_000_000_000.0);
        if (frame_duration_ns < target_ns) {
            std.posix.nanosleep(0, target_ns - frame_duration_ns);
        }
    }

    print("\nGame shut down successfully. Frames rendered: {d}\n", .{state.frame_count});
}
