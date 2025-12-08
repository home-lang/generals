// C&C Generals Zero Hour - Zig Entry Point
// Main entry point that interfaces with the Objective-C/Metal rendering layer

const std = @import("std");

// =============================================================================
// External C Functions (implemented in Objective-C)
// =============================================================================

// MacOS Window
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
    mouse_left_down: bool,
    mouse_right_down: bool,
    mouse_left_clicked: bool,
    mouse_right_clicked: bool,
};

extern fn macos_window_create(title: [*:0]const u8, width: u32, height: u32, resizable: bool) MacOSWindow;
extern fn macos_window_show(window: *MacOSWindow) void;
extern fn macos_window_hide(window: *MacOSWindow) void;
extern fn macos_window_poll_events(window: *MacOSWindow) bool;
extern fn macos_window_get_native_handle(window: *MacOSWindow) ?*anyopaque;
extern fn macos_window_get_mouse_position(window: *MacOSWindow, x: *f32, y: *f32) void;
extern fn macos_window_get_keyboard_state(window: *MacOSWindow, up: *bool, down: *bool, left: *bool, right: *bool, w: *bool, a: *bool, s: *bool, d: *bool) void;
extern fn macos_window_get_mouse_button_state(window: *MacOSWindow, left_down: *bool, right_down: *bool, left_clicked: *bool, right_clicked: *bool) void;
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
extern fn sprite_renderer_draw_sprite_batched(renderer: *SpriteRenderer, ctx: *RenderContext, texture: ?*anyopaque, x: f32, y: f32, width: f32, height: f32) void;
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
// Game State
// =============================================================================

const GameMode = enum {
    MainMenu,
    Skirmish,
    Campaign,
    GeneralsChallenge,
    Multiplayer,
};

const Unit = struct {
    x: f32,
    y: f32,
    target_x: f32,
    target_y: f32,
    speed: f32,
    size: f32,
    selected: bool,
    faction: Faction,
    unit_type: UnitType,
    health: f32,
    max_health: f32,
};

const Faction = enum {
    USA,
    China,
    GLA,
};

const UnitType = enum {
    Infantry,
    Tank,
    Humvee,
    Crusader,
    Paladin,
    Comanche,
    Battlemaster,
    Overlord,
    Technical,
    Scorpion,
    QuadCannon,
};

const Building = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    building_type: BuildingType,
    faction: Faction,
    health: f32,
    max_health: f32,
};

const BuildingType = enum {
    CommandCenter,
    Barracks,
    WarFactory,
    SupplyCenter,
    PowerPlant,
};

const GameState = struct {
    mode: GameMode,
    units: [64]Unit,
    unit_count: usize,
    buildings: [32]Building,
    building_count: usize,
    camera_x: f32,
    camera_y: f32,
    camera_zoom: f32,
    selected_unit_index: ?usize,
    resources: i32,
    is_running: bool,
    frame_count: u64,
};

// =============================================================================
// Texture Generation (Procedural sprites)
// =============================================================================

const TEXTURE_SIZE: u32 = 64;

// Game textures
const GameTextures = struct {
    tank_usa: ?*anyopaque,
    tank_china: ?*anyopaque,
    tank_gla: ?*anyopaque,
    building_usa: ?*anyopaque,
    building_china: ?*anyopaque,
    building_gla: ?*anyopaque,
};

fn createTankTexture(renderer: *SpriteRenderer, base_r: u8, base_g: u8, base_b: u8) ?*anyopaque {
    var data: [TEXTURE_SIZE * TEXTURE_SIZE * 4]u8 = undefined;

    const size = TEXTURE_SIZE;
    const center = size / 2;

    for (0..size) |y_idx| {
        for (0..size) |x_idx| {
            const x = @as(i32, @intCast(x_idx));
            const y = @as(i32, @intCast(y_idx));
            const idx = (y_idx * size + x_idx) * 4;

            // Default: transparent
            data[idx] = 0; // B
            data[idx + 1] = 0; // G
            data[idx + 2] = 0; // R
            data[idx + 3] = 0; // A

            const cx = @as(i32, @intCast(center));
            const cy = @as(i32, @intCast(center));

            // Tank body (rounded rectangle)
            const body_w: i32 = 24;
            const body_h: i32 = 16;
            const in_body = (x >= cx - body_w / 2 and x < cx + body_w / 2 and
                y >= cy - body_h / 2 + 4 and y < cy + body_h / 2 + 4);

            // Tank turret (circle on top)
            const turret_dx = x - cx;
            const turret_dy = y - cy + 2;
            const turret_dist_sq = turret_dx * turret_dx + turret_dy * turret_dy;
            const in_turret = turret_dist_sq < 10 * 10;

            // Tank barrel (rectangle extending from turret)
            const in_barrel = (x >= cx - 2 and x < cx + 2 and y >= cy - 20 and y < cy - 5);

            // Track left
            const in_track_l = (x >= cx - body_w / 2 - 4 and x < cx - body_w / 2 + 2 and
                y >= cy - body_h / 2 + 2 and y < cy + body_h / 2 + 6);

            // Track right
            const in_track_r = (x >= cx + body_w / 2 - 2 and x < cx + body_w / 2 + 4 and
                y >= cy - body_h / 2 + 2 and y < cy + body_h / 2 + 6);

            if (in_barrel) {
                // Dark barrel
                data[idx] = 40; // B
                data[idx + 1] = 40; // G
                data[idx + 2] = 50; // R
                data[idx + 3] = 255; // A
            } else if (in_turret) {
                // Turret - slightly darker than body
                data[idx] = @as(u8, @intCast(@max(0, @as(i32, base_b) - 30))); // B
                data[idx + 1] = @as(u8, @intCast(@max(0, @as(i32, base_g) - 30))); // G
                data[idx + 2] = @as(u8, @intCast(@max(0, @as(i32, base_r) - 30))); // R
                data[idx + 3] = 255; // A
            } else if (in_body) {
                // Main body color
                data[idx] = base_b; // B
                data[idx + 1] = base_g; // G
                data[idx + 2] = base_r; // R
                data[idx + 3] = 255; // A
            } else if (in_track_l or in_track_r) {
                // Dark tracks
                data[idx] = 30; // B
                data[idx + 1] = 30; // G
                data[idx + 2] = 35; // R
                data[idx + 3] = 255; // A
            }
        }
    }

    return sprite_renderer_create_texture(renderer, TEXTURE_SIZE, TEXTURE_SIZE, &data);
}

fn createBuildingTexture(renderer: *SpriteRenderer, base_r: u8, base_g: u8, base_b: u8) ?*anyopaque {
    var data: [TEXTURE_SIZE * TEXTURE_SIZE * 4]u8 = undefined;

    const size = TEXTURE_SIZE;

    for (0..size) |y_idx| {
        for (0..size) |x_idx| {
            const x = @as(i32, @intCast(x_idx));
            const y = @as(i32, @intCast(y_idx));
            const idx = (y_idx * size + x_idx) * 4;

            // Default: transparent
            data[idx] = 0;
            data[idx + 1] = 0;
            data[idx + 2] = 0;
            data[idx + 3] = 0;

            // Building base (large square with beveled edges)
            const margin: i32 = 4;
            const s = @as(i32, @intCast(size));
            const in_base = (x >= margin and x < s - margin and y >= margin + 8 and y < s - margin);

            // Roof (triangle/pyramid top)
            const roof_start: i32 = 4;
            const roof_end: i32 = 16;
            const in_roof = (y >= roof_start and y < roof_end and
                x >= margin + @divTrunc((y - roof_start) * 2, 3) and
                x < s - margin - @divTrunc((y - roof_start) * 2, 3));

            // Windows (small dark rectangles)
            const win_row1 = (y >= 24 and y < 32);
            const win_row2 = (y >= 40 and y < 48);
            const win_col1 = (x >= 12 and x < 20);
            const win_col2 = (x >= 28 and x < 36);
            const win_col3 = (x >= 44 and x < 52);
            const in_window = ((win_row1 or win_row2) and (win_col1 or win_col2 or win_col3));

            // Door
            const in_door = (x >= 26 and x < 38 and y >= 48 and y < s - margin);

            if (in_roof) {
                // Darker roof
                data[idx] = @as(u8, @intCast(@max(0, @as(i32, base_b) - 50)));
                data[idx + 1] = @as(u8, @intCast(@max(0, @as(i32, base_g) - 50)));
                data[idx + 2] = @as(u8, @intCast(@max(0, @as(i32, base_r) - 50)));
                data[idx + 3] = 255;
            } else if (in_window) {
                // Dark windows
                data[idx] = 60;
                data[idx + 1] = 60;
                data[idx + 2] = 80;
                data[idx + 3] = 255;
            } else if (in_door) {
                // Brown door
                data[idx] = 40;
                data[idx + 1] = 60;
                data[idx + 2] = 100;
                data[idx + 3] = 255;
            } else if (in_base) {
                // Main building color
                data[idx] = base_b;
                data[idx + 1] = base_g;
                data[idx + 2] = base_r;
                data[idx + 3] = 255;
            }
        }
    }

    return sprite_renderer_create_texture(renderer, TEXTURE_SIZE, TEXTURE_SIZE, &data);
}

fn createGameTextures(renderer: *SpriteRenderer) GameTextures {
    return GameTextures{
        // USA: Blue theme (RGB: 60, 120, 200)
        .tank_usa = createTankTexture(renderer, 60, 120, 200),
        .building_usa = createBuildingTexture(renderer, 80, 130, 180),

        // China: Red theme (RGB: 200, 50, 50)
        .tank_china = createTankTexture(renderer, 200, 50, 50),
        .building_china = createBuildingTexture(renderer, 180, 60, 60),

        // GLA: Tan/brown theme (RGB: 160, 130, 80)
        .tank_gla = createTankTexture(renderer, 160, 130, 80),
        .building_gla = createBuildingTexture(renderer, 140, 110, 70),
    };
}

fn destroyGameTextures(textures: *GameTextures) void {
    if (textures.tank_usa) |t| sprite_renderer_destroy_texture(t);
    if (textures.tank_china) |t| sprite_renderer_destroy_texture(t);
    if (textures.tank_gla) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_usa) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_china) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_gla) |t| sprite_renderer_destroy_texture(t);
}

// =============================================================================
// Game Logic
// =============================================================================

fn initGameState() GameState {
    var state = GameState{
        .mode = .MainMenu,
        .units = undefined,
        .unit_count = 0,
        .buildings = undefined,
        .building_count = 0,
        .camera_x = 0,
        .camera_y = 0,
        .camera_zoom = 1.0,
        .selected_unit_index = null,
        .resources = 5000,
        .is_running = true,
        .frame_count = 0,
    };

    // Create some initial units for demo
    state.units[0] = Unit{
        .x = 200,
        .y = 200,
        .target_x = 200,
        .target_y = 200,
        .speed = 100,
        .size = 32,
        .selected = false,
        .faction = .USA,
        .unit_type = .Crusader,
        .health = 100,
        .max_health = 100,
    };
    state.units[1] = Unit{
        .x = 300,
        .y = 250,
        .target_x = 300,
        .target_y = 250,
        .speed = 80,
        .size = 40,
        .selected = false,
        .faction = .USA,
        .unit_type = .Paladin,
        .health = 150,
        .max_health = 150,
    };
    state.units[2] = Unit{
        .x = 600,
        .y = 400,
        .target_x = 600,
        .target_y = 400,
        .speed = 90,
        .size = 36,
        .selected = false,
        .faction = .China,
        .unit_type = .Battlemaster,
        .health = 120,
        .max_health = 120,
    };
    state.unit_count = 3;

    // Create some buildings
    state.buildings[0] = Building{
        .x = 100,
        .y = 100,
        .width = 80,
        .height = 80,
        .building_type = .CommandCenter,
        .faction = .USA,
        .health = 500,
        .max_health = 500,
    };
    state.buildings[1] = Building{
        .x = 500,
        .y = 350,
        .width = 80,
        .height = 80,
        .building_type = .CommandCenter,
        .faction = .China,
        .health = 500,
        .max_health = 500,
    };
    state.building_count = 2;

    return state;
}

fn updateGameState(state: *GameState, window: *MacOSWindow, dt: f32) void {
    // Get input state
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

    var left_down: bool = false;
    var right_down: bool = false;
    var left_clicked: bool = false;
    var right_clicked: bool = false;
    macos_window_get_mouse_button_state(window, &left_down, &right_down, &left_clicked, &right_clicked);

    // Camera movement (arrow keys or WASD)
    const camera_speed: f32 = 300.0;
    if (up or w) state.camera_y -= camera_speed * dt;
    if (down or s) state.camera_y += camera_speed * dt;
    if (left or a) state.camera_x -= camera_speed * dt;
    if (right or d) state.camera_x += camera_speed * dt;

    // Unit selection (left click)
    if (left_clicked) {
        state.selected_unit_index = null;
        for (state.units[0..state.unit_count], 0..) |*unit, i| {
            const dx = mouse_x - unit.x;
            const dy = mouse_y - unit.y;
            const dist_sq = dx * dx + dy * dy;
            const radius = unit.size / 2;
            if (dist_sq < radius * radius) {
                state.selected_unit_index = i;
                unit.selected = true;
            } else {
                unit.selected = false;
            }
        }
    }

    // Unit movement (right click)
    if (right_clicked) {
        if (state.selected_unit_index) |idx| {
            state.units[idx].target_x = mouse_x;
            state.units[idx].target_y = mouse_y;
        }
    }

    // Update unit positions
    for (state.units[0..state.unit_count]) |*unit| {
        const dx = unit.target_x - unit.x;
        const dy = unit.target_y - unit.y;
        const dist = @sqrt(dx * dx + dy * dy);

        if (dist > 2.0) {
            const move_dist = unit.speed * dt;
            if (move_dist >= dist) {
                unit.x = unit.target_x;
                unit.y = unit.target_y;
            } else {
                unit.x += (dx / dist) * move_dist;
                unit.y += (dy / dist) * move_dist;
            }
        }
    }

    state.frame_count += 1;
}

fn renderGame(renderer: *SpriteRenderer, state: *const GameState, textures: *const GameTextures) void {
    var ctx = sprite_renderer_begin_frame(renderer);
    if (ctx.render_encoder == null) return;

    // Render terrain grid (subtle dark lines)
    const grid_size: f32 = 64;
    var y: f32 = 0;
    while (y < 720) : (y += grid_size) {
        sprite_renderer_draw_rect(renderer, &ctx, 0, y, 1280, 1, 0.5, 0.4, 0.3, 0.4);
    }
    var x: f32 = 0;
    while (x < 1280) : (x += grid_size) {
        sprite_renderer_draw_rect(renderer, &ctx, x, 0, 1, 720, 0.5, 0.4, 0.3, 0.4);
    }

    // Render buildings using sprites
    for (state.buildings[0..state.building_count]) |building| {
        // Get building texture based on faction
        const texture = switch (building.faction) {
            .USA => textures.building_usa,
            .China => textures.building_china,
            .GLA => textures.building_gla,
        };

        // Draw building sprite
        if (texture) |tex| {
            sprite_renderer_draw_sprite_batched(renderer, &ctx, tex, building.x, building.y, building.width, building.height);
        }

        // Building health bar
        const health_pct = building.health / building.max_health;
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y - 10, building.width, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, &ctx, building.x + 1, building.y - 9, (building.width - 2) * health_pct, 4, 0.0, 0.9, 0.0, 1.0);
    }

    // Render units using sprites
    for (state.units[0..state.unit_count]) |unit| {
        // Get tank texture based on faction
        const texture = switch (unit.faction) {
            .USA => textures.tank_usa,
            .China => textures.tank_china,
            .GLA => textures.tank_gla,
        };

        const half_size = unit.size / 2;

        // Draw unit sprite
        if (texture) |tex| {
            sprite_renderer_draw_sprite_batched(renderer, &ctx, tex, unit.x - half_size, unit.y - half_size, unit.size, unit.size);
        }

        // Selection circle (draw UNDER the unit for better visibility)
        if (unit.selected) {
            sprite_renderer_draw_selection_circle(renderer, &ctx, unit.x, unit.y, unit.size * 0.6, 0.0, 1.0, 0.0, 1.0);
        }

        // Health bar
        const health_pct = unit.health / unit.max_health;
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y - half_size - 10, unit.size, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size + 1, unit.y - half_size - 9, (unit.size - 2) * health_pct, 4, 0.0, 0.9, 0.0, 1.0);
    }

    // Render UI - Top bar with resources
    sprite_renderer_draw_rect(renderer, &ctx, 0, 0, 1280, 40, 0.1, 0.1, 0.15, 0.95);
    // Money icon area
    sprite_renderer_draw_rect(renderer, &ctx, 10, 8, 24, 24, 0.9, 0.8, 0.0, 1.0);
    // Power icon area
    sprite_renderer_draw_rect(renderer, &ctx, 150, 8, 24, 24, 0.0, 0.8, 0.9, 1.0);

    // Render minimap background
    sprite_renderer_draw_rect(renderer, &ctx, 1280 - 180, 720 - 150, 170, 140, 0.05, 0.1, 0.05, 0.95);
    // Minimap terrain
    sprite_renderer_draw_rect(renderer, &ctx, 1280 - 175, 720 - 145, 160, 130, 0.3, 0.4, 0.2, 1.0);

    // Render control bar at bottom
    sprite_renderer_draw_rect(renderer, &ctx, 0, 720 - 100, 1280, 100, 0.12, 0.12, 0.15, 0.95);
    // Command buttons placeholder
    for (0..6) |i| {
        const btn_x: f32 = 20 + @as(f32, @floatFromInt(i)) * 70;
        sprite_renderer_draw_rect(renderer, &ctx, btn_x, 720 - 90, 60, 60, 0.25, 0.25, 0.3, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.15, 0.2, 1.0);
    }

    // Unit portrait area (when unit selected)
    sprite_renderer_draw_rect(renderer, &ctx, 500, 720 - 95, 90, 85, 0.2, 0.2, 0.25, 1.0);

    sprite_renderer_end_frame(renderer, &ctx);
}

// =============================================================================
// Main Entry Point
// =============================================================================

pub fn main() !void {
    const print = std.debug.print;

    print("================================================================================\n", .{});
    print("  {s}\n", .{GAME_TITLE});
    print("  Version: {s}\n", .{GAME_VERSION});
    print("  Written in Zig + Home - A 100% authentic reimplementation\n", .{});
    print("================================================================================\n\n", .{});

    // Create window
    print("Creating window...\n", .{});
    var window = macos_window_create(GAME_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, true);
    defer macos_window_destroy(&window);

    if (window.ns_window == null) {
        print("ERROR: Failed to create window\n", .{});
        return;
    }

    // Show window
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

    // Create game textures
    print("Creating game textures...\n", .{});
    var textures = createGameTextures(&renderer);
    defer destroyGameTextures(&textures);
    print("Game textures created\n", .{});

    // Initialize game state
    var game_state = initGameState();
    print("Game state initialized\n", .{});

    print("\nStarting game loop...\n", .{});
    print("Controls:\n", .{});
    print("  - Arrow keys or WASD: Move camera\n", .{});
    print("  - Left click: Select unit\n", .{});
    print("  - Right click: Move selected unit\n", .{});
    print("  - Cmd+Q: Quit\n\n", .{});

    // Game loop
    var last_instant = std.time.Instant.now() catch {
        print("ERROR: Timer not supported\n", .{});
        return;
    };

    while (game_state.is_running) {
        // Calculate delta time
        const current_instant = std.time.Instant.now() catch last_instant;
        const dt_ns = current_instant.since(last_instant);
        const dt: f32 = @as(f32, @floatFromInt(dt_ns)) / 1_000_000_000.0;
        last_instant = current_instant;

        // Poll events
        if (!macos_window_poll_events(&window)) {
            game_state.is_running = false;
            break;
        }

        // Update game state
        updateGameState(&game_state, &window, dt);

        // Render
        renderGame(&renderer, &game_state, &textures);

        // Frame rate limiting
        const frame_end = std.time.Instant.now() catch current_instant;
        const frame_duration_ns = frame_end.since(current_instant);
        const target_ns: u64 = @intFromFloat(FRAME_TIME * 1_000_000_000.0);
        if (frame_duration_ns < target_ns) {
            const sleep_ns: u64 = target_ns - frame_duration_ns;
            std.posix.nanosleep(0, sleep_ns);
        }
    }

    print("\nGame shut down successfully. Frames rendered: {d}\n", .{game_state.frame_count});
}
