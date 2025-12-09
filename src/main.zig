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
    damage: f32,
    attack_range: f32,
    attack_cooldown: f32,
    attack_timer: f32,
    target_unit: ?usize,
    is_alive: bool,
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

const Explosion = struct {
    x: f32,
    y: f32,
    radius: f32,
    max_radius: f32,
    lifetime: f32,
    max_lifetime: f32,
    is_active: bool,
};

const Projectile = struct {
    x: f32,
    y: f32,
    target_x: f32,
    target_y: f32,
    speed: f32,
    damage: f32,
    faction: Faction,
    is_active: bool,
};

const MuzzleFlash = struct {
    x: f32,
    y: f32,
    lifetime: f32,
    is_active: bool,
};

const ProductionItem = struct {
    unit_type: UnitType,
    progress: f32, // 0.0 to 1.0
    build_time: f32, // total time in seconds
    cost: i32,
};

const ProductionQueue = struct {
    items: [5]ProductionItem,
    count: usize,
    building_idx: usize, // which building is producing

    fn init() ProductionQueue {
        return ProductionQueue{
            .items = undefined,
            .count = 0,
            .building_idx = 0,
        };
    }
};

const GameState = struct {
    mode: GameMode,
    units: [64]Unit,
    unit_count: usize,
    buildings: [32]Building,
    building_count: usize,
    explosions: [32]Explosion,
    explosion_count: usize,
    projectiles: [64]Projectile,
    projectile_count: usize,
    muzzle_flashes: [32]MuzzleFlash,
    muzzle_flash_count: usize,
    camera_x: f32,
    camera_y: f32,
    camera_zoom: f32,
    selected_unit_index: ?usize,
    selected_building_index: ?usize,
    resources: i32,
    power: i32,
    is_running: bool,
    frame_count: u64,
    // Production
    production_queue: ProductionQueue,
    player_faction: Faction,
    // Selection box
    selection_start_x: f32,
    selection_start_y: f32,
    is_selecting: bool,
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
    infantry_usa: ?*anyopaque,
    infantry_china: ?*anyopaque,
    infantry_gla: ?*anyopaque,
    terrain_grass: ?*anyopaque,
    terrain_sand: ?*anyopaque,
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

fn createInfantryTexture(renderer: *SpriteRenderer, base_r: u8, base_g: u8, base_b: u8) ?*anyopaque {
    var data: [TEXTURE_SIZE * TEXTURE_SIZE * 4]u8 = undefined;

    const size = TEXTURE_SIZE;
    const center = size / 2;

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

            const cx = @as(i32, @intCast(center));
            const cy = @as(i32, @intCast(center));

            // Head (circle at top)
            const head_dx = x - cx;
            const head_dy = y - (cy - 16);
            const head_dist_sq = head_dx * head_dx + head_dy * head_dy;
            const in_head = head_dist_sq < 8 * 8;

            // Body (oval/rectangle)
            const in_body = (x >= cx - 8 and x < cx + 8 and y >= cy - 8 and y < cy + 10);

            // Arms (two rectangles)
            const in_left_arm = (x >= cx - 16 and x < cx - 6 and y >= cy - 6 and y < cy + 2);
            const in_right_arm = (x >= cx + 6 and x < cx + 16 and y >= cy - 6 and y < cy + 2);

            // Gun (small rectangle from right arm)
            const in_gun = (x >= cx + 12 and x < cx + 22 and y >= cy - 8 and y < cy - 2);

            // Legs (two rectangles)
            const in_left_leg = (x >= cx - 6 and x < cx - 1 and y >= cy + 8 and y < cy + 22);
            const in_right_leg = (x >= cx + 1 and x < cx + 6 and y >= cy + 8 and y < cy + 22);

            // Helmet (arc on head)
            const helmet_dy = y - (cy - 18);
            const in_helmet = head_dist_sq < 9 * 9 and helmet_dy < 4;

            if (in_helmet) {
                // Dark helmet
                data[idx] = 40;
                data[idx + 1] = 50;
                data[idx + 2] = 50;
                data[idx + 3] = 255;
            } else if (in_head) {
                // Skin tone
                data[idx] = 140;
                data[idx + 1] = 180;
                data[idx + 2] = 220;
                data[idx + 3] = 255;
            } else if (in_gun) {
                // Dark gun
                data[idx] = 30;
                data[idx + 1] = 30;
                data[idx + 2] = 35;
                data[idx + 3] = 255;
            } else if (in_body or in_left_arm or in_right_arm) {
                // Uniform color
                data[idx] = base_b;
                data[idx + 1] = base_g;
                data[idx + 2] = base_r;
                data[idx + 3] = 255;
            } else if (in_left_leg or in_right_leg) {
                // Darker pants
                data[idx] = @as(u8, @intCast(@max(0, @as(i32, base_b) - 40)));
                data[idx + 1] = @as(u8, @intCast(@max(0, @as(i32, base_g) - 40)));
                data[idx + 2] = @as(u8, @intCast(@max(0, @as(i32, base_r) - 40)));
                data[idx + 3] = 255;
            }
        }
    }

    return sprite_renderer_create_texture(renderer, TEXTURE_SIZE, TEXTURE_SIZE, &data);
}

fn createTerrainTexture(renderer: *SpriteRenderer, base_r: u8, base_g: u8, base_b: u8, is_grass: bool) ?*anyopaque {
    var data: [TEXTURE_SIZE * TEXTURE_SIZE * 4]u8 = undefined;

    const size = TEXTURE_SIZE;

    // Simple random seed based on base color
    var seed: u32 = @as(u32, base_r) * 256 + @as(u32, base_g);

    for (0..size) |y_idx| {
        for (0..size) |x_idx| {
            const idx = (y_idx * size + x_idx) * 4;

            // Simple noise variation
            seed = seed *% 1103515245 +% 12345;
            const noise = @as(i32, @intCast((seed >> 16) & 31)) - 16;

            var r = @as(i32, base_r) + noise;
            var g = @as(i32, base_g) + noise;
            var b = @as(i32, base_b) + noise;

            // Add grass blades pattern for grass terrain
            if (is_grass) {
                const blade_pattern = ((x_idx + y_idx * 3) % 7 == 0);
                if (blade_pattern) {
                    g = @min(255, g + 30);
                }
            }

            // Clamp values
            r = @max(0, @min(255, r));
            g = @max(0, @min(255, g));
            b = @max(0, @min(255, b));

            data[idx] = @as(u8, @intCast(b));
            data[idx + 1] = @as(u8, @intCast(g));
            data[idx + 2] = @as(u8, @intCast(r));
            data[idx + 3] = 255;
        }
    }

    return sprite_renderer_create_texture(renderer, TEXTURE_SIZE, TEXTURE_SIZE, &data);
}

fn createGameTextures(renderer: *SpriteRenderer) GameTextures {
    return GameTextures{
        // USA: Blue theme (RGB: 60, 120, 200)
        .tank_usa = createTankTexture(renderer, 60, 120, 200),
        .building_usa = createBuildingTexture(renderer, 80, 130, 180),
        .infantry_usa = createInfantryTexture(renderer, 60, 100, 160),

        // China: Red theme (RGB: 200, 50, 50)
        .tank_china = createTankTexture(renderer, 200, 50, 50),
        .building_china = createBuildingTexture(renderer, 180, 60, 60),
        .infantry_china = createInfantryTexture(renderer, 180, 40, 40),

        // GLA: Tan/brown theme (RGB: 160, 130, 80)
        .tank_gla = createTankTexture(renderer, 160, 130, 80),
        .building_gla = createBuildingTexture(renderer, 140, 110, 70),
        .infantry_gla = createInfantryTexture(renderer, 140, 120, 70),

        // Terrain textures
        .terrain_grass = createTerrainTexture(renderer, 60, 120, 50, true),
        .terrain_sand = createTerrainTexture(renderer, 180, 160, 120, false),
    };
}

fn destroyGameTextures(textures: *GameTextures) void {
    if (textures.tank_usa) |t| sprite_renderer_destroy_texture(t);
    if (textures.tank_china) |t| sprite_renderer_destroy_texture(t);
    if (textures.tank_gla) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_usa) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_china) |t| sprite_renderer_destroy_texture(t);
    if (textures.building_gla) |t| sprite_renderer_destroy_texture(t);
    if (textures.infantry_usa) |t| sprite_renderer_destroy_texture(t);
    if (textures.infantry_china) |t| sprite_renderer_destroy_texture(t);
    if (textures.infantry_gla) |t| sprite_renderer_destroy_texture(t);
    if (textures.terrain_grass) |t| sprite_renderer_destroy_texture(t);
    if (textures.terrain_sand) |t| sprite_renderer_destroy_texture(t);
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
        .explosions = undefined,
        .explosion_count = 0,
        .projectiles = undefined,
        .projectile_count = 0,
        .muzzle_flashes = undefined,
        .muzzle_flash_count = 0,
        .camera_x = 0,
        .camera_y = 0,
        .camera_zoom = 1.0,
        .selected_unit_index = null,
        .selected_building_index = null,
        .resources = 5000,
        .power = 100,
        .is_running = true,
        .frame_count = 0,
        .production_queue = ProductionQueue.init(),
        .player_faction = .USA,
        .selection_start_x = 0,
        .selection_start_y = 0,
        .is_selecting = false,
    };

    // Helper to create unit with combat stats
    const createUnit = struct {
        fn create(x: f32, y: f32, speed: f32, size: f32, faction: Faction, unit_type: UnitType, health: f32, damage: f32, range: f32) Unit {
            return Unit{
                .x = x,
                .y = y,
                .target_x = x,
                .target_y = y,
                .speed = speed,
                .size = size,
                .selected = false,
                .faction = faction,
                .unit_type = unit_type,
                .health = health,
                .max_health = health,
                .damage = damage,
                .attack_range = range,
                .attack_cooldown = 1.0,
                .attack_timer = 0,
                .target_unit = null,
                .is_alive = true,
            };
        }
    }.create;

    // USA units - Tanks have high damage, infantry lower
    state.units[0] = createUnit(200, 200, 100, 36, .USA, .Crusader, 100, 25, 150);
    state.units[1] = createUnit(260, 220, 80, 42, .USA, .Paladin, 150, 35, 160);
    state.units[2] = createUnit(180, 280, 60, 24, .USA, .Infantry, 50, 8, 100);
    state.units[3] = createUnit(210, 285, 60, 24, .USA, .Infantry, 50, 8, 100);
    state.units[4] = createUnit(240, 280, 60, 24, .USA, .Infantry, 50, 8, 100);

    // China units - Overlord is powerful but slow
    state.units[5] = createUnit(900, 400, 90, 38, .China, .Battlemaster, 120, 30, 140);
    state.units[6] = createUnit(960, 420, 70, 48, .China, .Overlord, 200, 50, 170);
    state.units[7] = createUnit(880, 480, 55, 24, .China, .Infantry, 40, 6, 90);
    state.units[8] = createUnit(910, 485, 55, 24, .China, .Infantry, 40, 6, 90);

    // GLA units - Fast but fragile
    state.units[9] = createUnit(700, 150, 120, 30, .GLA, .Technical, 60, 15, 120);
    state.units[10] = createUnit(760, 170, 85, 34, .GLA, .Scorpion, 80, 20, 130);
    state.units[11] = createUnit(680, 220, 65, 22, .GLA, .Infantry, 35, 5, 85);
    state.units[12] = createUnit(710, 225, 65, 22, .GLA, .Infantry, 35, 5, 85);

    state.unit_count = 13;

    // Create USA buildings
    state.buildings[0] = Building{
        .x = 80,
        .y = 80,
        .width = 90,
        .height = 90,
        .building_type = .CommandCenter,
        .faction = .USA,
        .health = 2000,
        .max_health = 2000,
    };
    state.buildings[1] = Building{
        .x = 180,
        .y = 100,
        .width = 60,
        .height = 60,
        .building_type = .Barracks,
        .faction = .USA,
        .health = 500,
        .max_health = 500,
    };
    state.buildings[2] = Building{
        .x = 80,
        .y = 180,
        .width = 70,
        .height = 70,
        .building_type = .WarFactory,
        .faction = .USA,
        .health = 800,
        .max_health = 800,
    };

    // Create China buildings
    state.buildings[3] = Building{
        .x = 950,
        .y = 300,
        .width = 90,
        .height = 90,
        .building_type = .CommandCenter,
        .faction = .China,
        .health = 2000,
        .max_health = 2000,
    };
    state.buildings[4] = Building{
        .x = 1050,
        .y = 320,
        .width = 60,
        .height = 60,
        .building_type = .Barracks,
        .faction = .China,
        .health = 500,
        .max_health = 500,
    };

    // Create GLA buildings
    state.buildings[5] = Building{
        .x = 650,
        .y = 50,
        .width = 80,
        .height = 80,
        .building_type = .CommandCenter,
        .faction = .GLA,
        .health = 1500,
        .max_health = 1500,
    };
    state.buildings[6] = Building{
        .x = 750,
        .y = 60,
        .width = 55,
        .height = 55,
        .building_type = .Barracks,
        .faction = .GLA,
        .health = 400,
        .max_health = 400,
    };

    state.building_count = 7;

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

    // Selection (left click) - check units then buildings
    if (left_clicked) {
        state.selected_unit_index = null;
        state.selected_building_index = null;

        // First check if clicking on a unit
        var found_unit = false;
        for (state.units[0..state.unit_count], 0..) |*unit, i| {
            const dx = mouse_x - unit.x;
            const dy = mouse_y - unit.y;
            const dist_sq = dx * dx + dy * dy;
            const radius = unit.size / 2;
            if (dist_sq < radius * radius and unit.is_alive) {
                state.selected_unit_index = i;
                unit.selected = true;
                found_unit = true;
            } else {
                unit.selected = false;
            }
        }

        // If no unit found, check buildings (only player faction)
        if (!found_unit) {
            for (state.buildings[0..state.building_count], 0..) |building, i| {
                if (building.faction != state.player_faction) continue;

                if (mouse_x >= building.x and mouse_x < building.x + building.width and
                    mouse_y >= building.y and mouse_y < building.y + building.height) {
                    state.selected_building_index = i;
                    break;
                }
            }
        }

        // Check if clicking on build buttons when a building is selected
        if (state.selected_building_index) |bld_idx| {
            const building = state.buildings[bld_idx];
            // Check if clicking in command panel area
            if (mouse_y >= 720 - 100) {
                const btn_width: f32 = 60;
                const btn_spacing: f32 = 70;
                const btn_y: f32 = 720 - 90;

                // Check each build button
                for (0..6) |btn_i| {
                    const btn_x: f32 = 20 + @as(f32, @floatFromInt(btn_i)) * btn_spacing;
                    if (mouse_x >= btn_x and mouse_x < btn_x + btn_width and
                        mouse_y >= btn_y and mouse_y < btn_y + 60) {
                        // Queue a unit based on building type
                        if (building.building_type == .Barracks and state.production_queue.count < 5) {
                            if (btn_i == 0 and state.resources >= 200) {
                                // Build infantry
                                state.production_queue.items[state.production_queue.count] = ProductionItem{
                                    .unit_type = .Infantry,
                                    .progress = 0.0,
                                    .build_time = 5.0,
                                    .cost = 200,
                                };
                                state.production_queue.count += 1;
                                state.production_queue.building_idx = bld_idx;
                                state.resources -= 200;
                                std.debug.print("[PRODUCTION] Queued Infantry (cost: 200)\n", .{});
                            }
                        } else if (building.building_type == .WarFactory and state.production_queue.count < 5) {
                            if (btn_i == 0 and state.resources >= 800) {
                                // Build tank
                                state.production_queue.items[state.production_queue.count] = ProductionItem{
                                    .unit_type = .Crusader,
                                    .progress = 0.0,
                                    .build_time = 10.0,
                                    .cost = 800,
                                };
                                state.production_queue.count += 1;
                                state.production_queue.building_idx = bld_idx;
                                state.resources -= 800;
                                std.debug.print("[PRODUCTION] Queued Crusader Tank (cost: 800)\n", .{});
                            } else if (btn_i == 1 and state.resources >= 1100) {
                                // Build Paladin
                                state.production_queue.items[state.production_queue.count] = ProductionItem{
                                    .unit_type = .Paladin,
                                    .progress = 0.0,
                                    .build_time = 15.0,
                                    .cost = 1100,
                                };
                                state.production_queue.count += 1;
                                state.production_queue.building_idx = bld_idx;
                                state.resources -= 1100;
                                std.debug.print("[PRODUCTION] Queued Paladin Tank (cost: 1100)\n", .{});
                            }
                        }
                        break;
                    }
                }
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

    // Update unit positions and combat
    for (state.units[0..state.unit_count], 0..) |*unit, i| {
        if (!unit.is_alive) continue;

        // Movement
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

        // Update attack timer
        if (unit.attack_timer > 0) {
            unit.attack_timer -= dt;
        }

        // Auto-attack: Find nearby enemy and attack
        if (unit.attack_timer <= 0) {
            var closest_enemy: ?usize = null;
            var closest_dist: f32 = unit.attack_range;

            for (state.units[0..state.unit_count], 0..) |*other, j| {
                if (i == j or !other.is_alive) continue;
                if (other.faction == unit.faction) continue; // Don't attack allies

                const ex = other.x - unit.x;
                const ey = other.y - unit.y;
                const enemy_dist = @sqrt(ex * ex + ey * ey);

                if (enemy_dist < closest_dist) {
                    closest_dist = enemy_dist;
                    closest_enemy = j;
                }
            }

            // Attack if enemy in range
            if (closest_enemy) |enemy_idx| {
                state.units[enemy_idx].health -= unit.damage;
                unit.attack_timer = unit.attack_cooldown;
                unit.target_unit = enemy_idx;

                // Create muzzle flash at attacker position
                if (state.muzzle_flash_count < 32) {
                    state.muzzle_flashes[state.muzzle_flash_count] = MuzzleFlash{
                        .x = unit.x,
                        .y = unit.y,
                        .lifetime = 0.1,
                        .is_active = true,
                    };
                    state.muzzle_flash_count += 1;
                }

                // Sound placeholder (print to console occasionally)
                if (state.frame_count % 30 == 0) {
                    const sound_name = if (unit.unit_type == .Infantry) "rifle_shot.wav" else "cannon_fire.wav";
                    std.debug.print("[SOUND] Playing: {s}\n", .{sound_name});
                }

                // Check if enemy dies
                if (state.units[enemy_idx].health <= 0) {
                    state.units[enemy_idx].is_alive = false;
                    state.units[enemy_idx].health = 0;

                    // Sound placeholder for explosion
                    std.debug.print("[SOUND] Playing: explosion.wav\n", .{});

                    // Create explosion at death location
                    if (state.explosion_count < 32) {
                        state.explosions[state.explosion_count] = Explosion{
                            .x = state.units[enemy_idx].x,
                            .y = state.units[enemy_idx].y,
                            .radius = 5,
                            .max_radius = state.units[enemy_idx].size,
                            .lifetime = 0.5,
                            .max_lifetime = 0.5,
                            .is_active = true,
                        };
                        state.explosion_count += 1;
                    }
                }
            }
        }
    }

    // Update explosions
    var exp_idx: usize = 0;
    while (exp_idx < state.explosion_count) {
        var exp = &state.explosions[exp_idx];
        if (exp.is_active) {
            exp.lifetime -= dt;
            // Expand radius as explosion grows
            const progress = 1.0 - (exp.lifetime / exp.max_lifetime);
            exp.radius = exp.max_radius * progress;

            if (exp.lifetime <= 0) {
                exp.is_active = false;
                // Remove by swapping with last
                if (exp_idx < state.explosion_count - 1) {
                    state.explosions[exp_idx] = state.explosions[state.explosion_count - 1];
                }
                state.explosion_count -= 1;
                continue; // Don't increment, check swapped element
            }
        }
        exp_idx += 1;
    }

    // Update muzzle flashes
    var flash_idx: usize = 0;
    while (flash_idx < state.muzzle_flash_count) {
        var flash = &state.muzzle_flashes[flash_idx];
        if (flash.is_active) {
            flash.lifetime -= dt;
            if (flash.lifetime <= 0) {
                flash.is_active = false;
                // Remove by swapping with last
                if (flash_idx < state.muzzle_flash_count - 1) {
                    state.muzzle_flashes[flash_idx] = state.muzzle_flashes[state.muzzle_flash_count - 1];
                }
                state.muzzle_flash_count -= 1;
                continue;
            }
        }
        flash_idx += 1;
    }

    // Update production queue
    if (state.production_queue.count > 0) {
        // Update first item in queue
        var item = &state.production_queue.items[0];
        item.progress += dt / item.build_time;

        if (item.progress >= 1.0) {
            // Production complete! Spawn the unit
            if (state.unit_count < 64) {
                const building = state.buildings[state.production_queue.building_idx];
                const spawn_x = building.x + building.width + 20;
                const spawn_y = building.y + building.height / 2;

                // Create unit based on type
                var unit_size: f32 = 24;
                var unit_speed: f32 = 60;
                var unit_health: f32 = 50;
                var unit_damage: f32 = 8;
                var unit_range: f32 = 100;

                switch (item.unit_type) {
                    .Infantry => {
                        unit_size = 24;
                        unit_speed = 60;
                        unit_health = 50;
                        unit_damage = 8;
                        unit_range = 100;
                    },
                    .Crusader => {
                        unit_size = 36;
                        unit_speed = 100;
                        unit_health = 100;
                        unit_damage = 25;
                        unit_range = 150;
                    },
                    .Paladin => {
                        unit_size = 42;
                        unit_speed = 80;
                        unit_health = 150;
                        unit_damage = 35;
                        unit_range = 160;
                    },
                    else => {},
                }

                state.units[state.unit_count] = Unit{
                    .x = spawn_x,
                    .y = spawn_y,
                    .target_x = spawn_x,
                    .target_y = spawn_y,
                    .speed = unit_speed,
                    .size = unit_size,
                    .selected = false,
                    .faction = state.player_faction,
                    .unit_type = item.unit_type,
                    .health = unit_health,
                    .max_health = unit_health,
                    .damage = unit_damage,
                    .attack_range = unit_range,
                    .attack_cooldown = 1.0,
                    .attack_timer = 0,
                    .target_unit = null,
                    .is_alive = true,
                };
                state.unit_count += 1;
                std.debug.print("[PRODUCTION] Unit ready! Total units: {d}\n", .{state.unit_count});
            }

            // Remove completed item from queue (shift remaining)
            if (state.production_queue.count > 1) {
                var q_idx: usize = 0;
                while (q_idx < state.production_queue.count - 1) : (q_idx += 1) {
                    state.production_queue.items[q_idx] = state.production_queue.items[q_idx + 1];
                }
            }
            state.production_queue.count -= 1;
        }
    }

    state.frame_count += 1;
}

// Draw a 7-segment style digit
fn drawDigit(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, digit: u8, r: f32, g: f32, b: f32) void {
    const w: f32 = 8; // digit width
    const h: f32 = 14; // digit height
    const t: f32 = 2; // segment thickness

    // 7-segment patterns: [top, top-right, bottom-right, bottom, bottom-left, top-left, middle]
    const patterns = [10][7]bool{
        .{ true, true, true, true, true, true, false }, // 0
        .{ false, true, true, false, false, false, false }, // 1
        .{ true, true, false, true, true, false, true }, // 2
        .{ true, true, true, true, false, false, true }, // 3
        .{ false, true, true, false, false, true, true }, // 4
        .{ true, false, true, true, false, true, true }, // 5
        .{ true, false, true, true, true, true, true }, // 6
        .{ true, true, true, false, false, false, false }, // 7
        .{ true, true, true, true, true, true, true }, // 8
        .{ true, true, true, true, false, true, true }, // 9
    };

    const d = if (digit < 10) digit else 0;
    const p = patterns[d];

    // Top segment
    if (p[0]) sprite_renderer_draw_rect(renderer, ctx, x, y, w, t, r, g, b, 1.0);
    // Top-right segment
    if (p[1]) sprite_renderer_draw_rect(renderer, ctx, x + w - t, y, t, h / 2, r, g, b, 1.0);
    // Bottom-right segment
    if (p[2]) sprite_renderer_draw_rect(renderer, ctx, x + w - t, y + h / 2, t, h / 2, r, g, b, 1.0);
    // Bottom segment
    if (p[3]) sprite_renderer_draw_rect(renderer, ctx, x, y + h - t, w, t, r, g, b, 1.0);
    // Bottom-left segment
    if (p[4]) sprite_renderer_draw_rect(renderer, ctx, x, y + h / 2, t, h / 2, r, g, b, 1.0);
    // Top-left segment
    if (p[5]) sprite_renderer_draw_rect(renderer, ctx, x, y, t, h / 2, r, g, b, 1.0);
    // Middle segment
    if (p[6]) sprite_renderer_draw_rect(renderer, ctx, x, y + h / 2 - t / 2, w, t, r, g, b, 1.0);
}

// Draw a number (integer) using 7-segment digits
fn drawNumber(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, value: i32, r: f32, g: f32, b: f32) void {
    const digit_spacing: f32 = 10;
    const num: u32 = if (value >= 0) @intCast(value) else @intCast(-value);

    // Count digits
    var digit_count: u32 = 0;
    var temp = num;
    while (temp > 0) : (temp /= 10) {
        digit_count += 1;
    }
    if (digit_count == 0) digit_count = 1;

    // Draw digits from right to left
    var pos_x = x + @as(f32, @floatFromInt(digit_count - 1)) * digit_spacing;
    var n = num;
    for (0..digit_count) |_| {
        const digit: u8 = @intCast(n % 10);
        drawDigit(renderer, ctx, pos_x, y, digit, r, g, b);
        n /= 10;
        pos_x -= digit_spacing;
    }
}

fn renderGame(renderer: *SpriteRenderer, state: *const GameState, _: *const GameTextures) void {
    var ctx = sprite_renderer_begin_frame(renderer);
    if (ctx.render_encoder == null) return;

    // Render terrain background first (solid color)
    sprite_renderer_draw_rect(renderer, &ctx, 0, 0, 1280, 720, 0.6, 0.5, 0.3, 1.0);

    // Render terrain with textured tiles (checkerboard pattern)
    const tile_size: f32 = 64;
    var tile_row: u32 = 0;
    while (tile_row < 12) : (tile_row += 1) {
        var tile_col: u32 = 0;
        while (tile_col < 20) : (tile_col += 1) {
            const tx: f32 = @as(f32, @floatFromInt(tile_col)) * tile_size;
            const ty: f32 = @as(f32, @floatFromInt(tile_row)) * tile_size;

            // Checkerboard pattern - alternate colors
            const is_grass = ((tile_row + tile_col) % 2 == 0);

            // Draw colored rectangles for terrain tiles (textures may not be loading)
            if (is_grass) {
                sprite_renderer_draw_rect(renderer, &ctx, tx, ty, tile_size, tile_size, 0.4, 0.55, 0.3, 1.0);
            } else {
                sprite_renderer_draw_rect(renderer, &ctx, tx, ty, tile_size, tile_size, 0.65, 0.55, 0.35, 1.0);
            }
        }
    }

    // Grid lines overlay (subtle)
    var y: f32 = 0;
    while (y < 720) : (y += tile_size) {
        sprite_renderer_draw_rect(renderer, &ctx, 0, y, 1280, 1, 0.2, 0.2, 0.15, 0.3);
    }
    var x: f32 = 0;
    while (x < 1280) : (x += tile_size) {
        sprite_renderer_draw_rect(renderer, &ctx, x, 0, 1, 720, 0.2, 0.2, 0.15, 0.3);
    }

    // Render buildings using colored rectangles
    for (state.buildings[0..state.building_count]) |building| {
        // Get faction colors
        var bld_r: f32 = 0.5;
        var bld_g: f32 = 0.5;
        var bld_b: f32 = 0.5;
        switch (building.faction) {
            .USA => {
                bld_r = 0.3;
                bld_g = 0.5;
                bld_b = 0.7;
            },
            .China => {
                bld_r = 0.7;
                bld_g = 0.3;
                bld_b = 0.3;
            },
            .GLA => {
                bld_r = 0.6;
                bld_g = 0.45;
                bld_b = 0.25;
            },
        }

        // Draw building base
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y, building.width, building.height, bld_r, bld_g, bld_b, 1.0);

        // Draw building border
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y, building.width, 3, bld_r * 0.6, bld_g * 0.6, bld_b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y + building.height - 3, building.width, 3, bld_r * 0.6, bld_g * 0.6, bld_b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y, 3, building.height, bld_r * 0.6, bld_g * 0.6, bld_b * 0.6, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x + building.width - 3, building.y, 3, building.height, bld_r * 0.6, bld_g * 0.6, bld_b * 0.6, 1.0);

        // Draw building detail (window/door pattern)
        const detail_w = building.width * 0.3;
        const detail_h = building.height * 0.3;
        sprite_renderer_draw_rect(renderer, &ctx, building.x + building.width * 0.35, building.y + building.height * 0.35, detail_w, detail_h, bld_r * 1.3, bld_g * 1.3, bld_b * 1.3, 1.0);

        // Building health bar
        const health_pct = building.health / building.max_health;
        sprite_renderer_draw_rect(renderer, &ctx, building.x, building.y - 10, building.width, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, &ctx, building.x + 1, building.y - 9, (building.width - 2) * health_pct, 4, 0.0, 0.9, 0.0, 1.0);
    }

    // Render units using colored rectangles (with faction colors)
    for (state.units[0..state.unit_count]) |unit| {
        // Skip dead units
        if (!unit.is_alive) continue;

        const half_size = unit.size / 2;

        // Get faction colors
        var unit_r: f32 = 0.5;
        var unit_g: f32 = 0.5;
        var unit_b: f32 = 0.5;
        switch (unit.faction) {
            .USA => {
                unit_r = 0.2;
                unit_g = 0.4;
                unit_b = 0.8;
            },
            .China => {
                unit_r = 0.8;
                unit_g = 0.2;
                unit_b = 0.2;
            },
            .GLA => {
                unit_r = 0.7;
                unit_g = 0.5;
                unit_b = 0.2;
            },
        }

        // Selection circle (draw UNDER the unit)
        if (unit.selected) {
            sprite_renderer_draw_selection_circle(renderer, &ctx, unit.x, unit.y, unit.size * 0.7, 0.0, 1.0, 0.0, 1.0);
        }

        // Draw unit body as colored rectangle
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y - half_size, unit.size, unit.size, unit_r, unit_g, unit_b, 1.0);

        // Draw darker border
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y - half_size, unit.size, 2, unit_r * 0.5, unit_g * 0.5, unit_b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y + half_size - 2, unit.size, 2, unit_r * 0.5, unit_g * 0.5, unit_b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y - half_size, 2, unit.size, unit_r * 0.5, unit_g * 0.5, unit_b * 0.5, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, unit.x + half_size - 2, unit.y - half_size, 2, unit.size, unit_r * 0.5, unit_g * 0.5, unit_b * 0.5, 1.0);

        // Draw inner detail based on unit type
        if (unit.unit_type == .Infantry) {
            // Infantry: smaller inner circle (head)
            sprite_renderer_draw_rect(renderer, &ctx, unit.x - 4, unit.y - 6, 8, 8, 0.9, 0.75, 0.6, 1.0);
            // Body
            sprite_renderer_draw_rect(renderer, &ctx, unit.x - 5, unit.y + 2, 10, 8, unit_r * 0.8, unit_g * 0.8, unit_b * 0.8, 1.0);
        } else {
            // Tank/Vehicle: turret
            sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size * 0.4, unit.y - half_size * 0.4, unit.size * 0.4, unit.size * 0.4, unit_r * 0.7, unit_g * 0.7, unit_b * 0.7, 1.0);
            // Cannon
            sprite_renderer_draw_rect(renderer, &ctx, unit.x, unit.y - half_size * 0.2, half_size * 0.8, 4, 0.3, 0.3, 0.3, 1.0);
        }

        // Health bar - color based on health percentage
        const health_pct = unit.health / unit.max_health;
        const bar_r: f32 = if (health_pct < 0.3) 0.9 else if (health_pct < 0.6) 0.9 else 0.0;
        const bar_g: f32 = if (health_pct < 0.3) 0.0 else if (health_pct < 0.6) 0.7 else 0.9;
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size, unit.y - half_size - 10, unit.size, 6, 0.1, 0.1, 0.1, 0.9);
        sprite_renderer_draw_rect(renderer, &ctx, unit.x - half_size + 1, unit.y - half_size - 9, (unit.size - 2) * health_pct, 4, bar_r, bar_g, 0.0, 1.0);
    }

    // Render explosions
    for (state.explosions[0..state.explosion_count]) |exp| {
        if (exp.is_active) {
            // Draw explosion as expanding orange/red circle
            const alpha = exp.lifetime / exp.max_lifetime;
            // Outer ring
            sprite_renderer_draw_selection_circle(renderer, &ctx, exp.x, exp.y, exp.radius, 1.0, 0.5, 0.0, alpha);
            // Inner glow
            sprite_renderer_draw_rect(renderer, &ctx, exp.x - exp.radius * 0.5, exp.y - exp.radius * 0.5, exp.radius, exp.radius, 1.0, 0.8, 0.2, alpha * 0.8);
        }
    }

    // Render muzzle flashes
    for (state.muzzle_flashes[0..state.muzzle_flash_count]) |flash| {
        if (flash.is_active) {
            // Draw muzzle flash as bright yellow/white burst
            const alpha = flash.lifetime / 0.1;
            sprite_renderer_draw_rect(renderer, &ctx, flash.x - 8, flash.y - 8, 16, 16, 1.0, 1.0, 0.5, alpha);
            sprite_renderer_draw_rect(renderer, &ctx, flash.x - 4, flash.y - 4, 8, 8, 1.0, 1.0, 1.0, alpha);
        }
    }

    // Render attack lines (from attacker to target)
    for (state.units[0..state.unit_count]) |unit| {
        if (!unit.is_alive) continue;
        if (unit.attack_timer > 0.8) { // Show line briefly after attack
            if (unit.target_unit) |target_idx| {
                if (target_idx < state.unit_count and state.units[target_idx].is_alive) {
                    const target = state.units[target_idx];
                    // Draw attack line segments (since we don't have line primitive)
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
                            sprite_renderer_draw_rect(renderer, &ctx, px - 1, py - 1, 2, 2, 1.0, 0.3, 0.0, 0.7);
                            px += step_x;
                            py += step_y;
                        }
                    }
                }
            }
        }
    }

    // Render UI - Top bar with resources
    sprite_renderer_draw_rect(renderer, &ctx, 0, 0, 1280, 40, 0.1, 0.1, 0.15, 0.95);
    // Money icon (gold coin style)
    sprite_renderer_draw_rect(renderer, &ctx, 10, 8, 24, 24, 0.9, 0.8, 0.0, 1.0);
    sprite_renderer_draw_rect(renderer, &ctx, 14, 12, 16, 16, 0.7, 0.6, 0.0, 1.0);
    sprite_renderer_draw_rect(renderer, &ctx, 18, 16, 8, 8, 0.9, 0.8, 0.0, 1.0);
    // Draw money value using simple rectangles for digits
    drawNumber(renderer, &ctx, 40, 12, state.resources, 0.9, 0.8, 0.0);

    // Power icon (lightning bolt style)
    sprite_renderer_draw_rect(renderer, &ctx, 150, 8, 24, 24, 0.0, 0.8, 0.9, 1.0);
    sprite_renderer_draw_rect(renderer, &ctx, 158, 10, 8, 12, 1.0, 1.0, 0.3, 1.0);
    sprite_renderer_draw_rect(renderer, &ctx, 154, 18, 12, 4, 1.0, 1.0, 0.3, 1.0);
    sprite_renderer_draw_rect(renderer, &ctx, 158, 18, 8, 12, 1.0, 1.0, 0.3, 1.0);
    // Draw power value
    drawNumber(renderer, &ctx, 180, 12, state.power, 0.0, 0.9, 0.9);

    // Render minimap background
    const minimap_x: f32 = 1280 - 180;
    const minimap_y: f32 = 720 - 150;
    const minimap_w: f32 = 170;
    const minimap_h: f32 = 140;
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x, minimap_y, minimap_w, minimap_h, 0.05, 0.1, 0.05, 0.95);
    // Minimap terrain
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x + 5, minimap_y + 5, minimap_w - 10, minimap_h - 10, 0.3, 0.4, 0.2, 1.0);

    // Draw buildings on minimap
    const scale_x: f32 = (minimap_w - 10) / 1280.0;
    const scale_y: f32 = (minimap_h - 10) / 720.0;

    for (state.buildings[0..state.building_count]) |building| {
        const bx = minimap_x + 5 + building.x * scale_x;
        const by = minimap_y + 5 + building.y * scale_y;
        // Color based on faction
        switch (building.faction) {
            .USA => sprite_renderer_draw_rect(renderer, &ctx, bx - 3, by - 3, 6, 6, 0.2, 0.5, 0.9, 1.0),
            .China => sprite_renderer_draw_rect(renderer, &ctx, bx - 3, by - 3, 6, 6, 0.9, 0.2, 0.2, 1.0),
            .GLA => sprite_renderer_draw_rect(renderer, &ctx, bx - 3, by - 3, 6, 6, 0.7, 0.5, 0.2, 1.0),
        }
    }

    // Draw units on minimap (skip dead units)
    for (state.units[0..state.unit_count]) |unit| {
        if (!unit.is_alive) continue; // Skip dead units

        const ux = minimap_x + 5 + unit.x * scale_x;
        const uy = minimap_y + 5 + unit.y * scale_y;
        // Color based on faction, brighter if selected
        var r: f32 = 0;
        var g: f32 = 0;
        var b: f32 = 0;
        switch (unit.faction) {
            .USA => {
                r = 0.3;
                g = 0.6;
                b = 1.0;
            },
            .China => {
                r = 1.0;
                g = 0.3;
                b = 0.3;
            },
            .GLA => {
                r = 0.9;
                g = 0.7;
                b = 0.3;
            },
        }
        const dot_size: f32 = if (unit.selected) 5 else 3;
        sprite_renderer_draw_rect(renderer, &ctx, ux - dot_size / 2, uy - dot_size / 2, dot_size, dot_size, r, g, b, 1.0);
    }

    // Minimap viewport frame (shows current view area)
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x + 5, minimap_y + 5, (minimap_w - 10), 1, 1.0, 1.0, 1.0, 0.5);
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x + 5, minimap_y + minimap_h - 6, (minimap_w - 10), 1, 1.0, 1.0, 1.0, 0.5);
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x + 5, minimap_y + 5, 1, (minimap_h - 10), 1.0, 1.0, 1.0, 0.5);
    sprite_renderer_draw_rect(renderer, &ctx, minimap_x + minimap_w - 6, minimap_y + 5, 1, (minimap_h - 10), 1.0, 1.0, 1.0, 0.5);

    // Render control bar at bottom
    sprite_renderer_draw_rect(renderer, &ctx, 0, 720 - 100, 1280, 100, 0.12, 0.12, 0.15, 0.95);

    // Show building selection highlight
    if (state.selected_building_index) |bld_idx| {
        const building = state.buildings[bld_idx];
        // Draw selection box around building
        sprite_renderer_draw_rect(renderer, &ctx, building.x - 2, building.y - 2, building.width + 4, 2, 0.0, 1.0, 0.0, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x - 2, building.y + building.height, building.width + 4, 2, 0.0, 1.0, 0.0, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x - 2, building.y, 2, building.height, 0.0, 1.0, 0.0, 1.0);
        sprite_renderer_draw_rect(renderer, &ctx, building.x + building.width, building.y, 2, building.height, 0.0, 1.0, 0.0, 1.0);

        // Show build buttons based on building type
        if (building.building_type == .Barracks) {
            // Infantry button
            const btn_x: f32 = 20;
            sprite_renderer_draw_rect(renderer, &ctx, btn_x, 720 - 90, 60, 60, 0.3, 0.4, 0.3, 1.0);
            sprite_renderer_draw_rect(renderer, &ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.25, 0.15, 1.0);
            // Infantry icon (simple person shape)
            sprite_renderer_draw_rect(renderer, &ctx, btn_x + 25, 720 - 80, 10, 10, 0.8, 0.7, 0.5, 1.0); // head
            sprite_renderer_draw_rect(renderer, &ctx, btn_x + 22, 720 - 68, 16, 20, 0.2, 0.4, 0.8, 1.0); // body
            // Cost label
            drawNumber(renderer, &ctx, btn_x + 5, 720 - 42, 200, 0.9, 0.8, 0.0);
        } else if (building.building_type == .WarFactory) {
            // Tank buttons
            for (0..2) |btn_i| {
                const btn_x: f32 = 20 + @as(f32, @floatFromInt(btn_i)) * 70;
                sprite_renderer_draw_rect(renderer, &ctx, btn_x, 720 - 90, 60, 60, 0.3, 0.35, 0.4, 1.0);
                sprite_renderer_draw_rect(renderer, &ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.2, 0.25, 1.0);
                // Tank icon
                sprite_renderer_draw_rect(renderer, &ctx, btn_x + 10, 720 - 70, 40, 20, 0.2, 0.4, 0.8, 1.0); // body
                sprite_renderer_draw_rect(renderer, &ctx, btn_x + 20, 720 - 80, 20, 15, 0.15, 0.35, 0.7, 1.0); // turret
                sprite_renderer_draw_rect(renderer, &ctx, btn_x + 26, 720 - 90, 8, 12, 0.1, 0.1, 0.15, 1.0); // barrel
                // Cost label
                const cost: i32 = if (btn_i == 0) 800 else 1100;
                drawNumber(renderer, &ctx, btn_x + 5, 720 - 42, cost, 0.9, 0.8, 0.0);
            }
        } else {
            // Other buildings - empty buttons
            for (0..6) |i| {
                const btn_x: f32 = 20 + @as(f32, @floatFromInt(i)) * 70;
                sprite_renderer_draw_rect(renderer, &ctx, btn_x, 720 - 90, 60, 60, 0.25, 0.25, 0.3, 1.0);
                sprite_renderer_draw_rect(renderer, &ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.15, 0.2, 1.0);
            }
        }
    } else {
        // No building selected - show empty buttons
        for (0..6) |i| {
            const btn_x: f32 = 20 + @as(f32, @floatFromInt(i)) * 70;
            sprite_renderer_draw_rect(renderer, &ctx, btn_x, 720 - 90, 60, 60, 0.25, 0.25, 0.3, 1.0);
            sprite_renderer_draw_rect(renderer, &ctx, btn_x + 2, 720 - 88, 56, 56, 0.15, 0.15, 0.2, 1.0);
        }
    }

    // Production progress bar
    if (state.production_queue.count > 0) {
        const progress = state.production_queue.items[0].progress;
        const bar_x: f32 = 450;
        const bar_y: f32 = 720 - 85;
        const bar_w: f32 = 100;
        const bar_h: f32 = 12;

        // Background
        sprite_renderer_draw_rect(renderer, &ctx, bar_x, bar_y, bar_w, bar_h, 0.2, 0.2, 0.2, 1.0);
        // Progress fill
        sprite_renderer_draw_rect(renderer, &ctx, bar_x + 1, bar_y + 1, (bar_w - 2) * progress, bar_h - 2, 0.0, 0.8, 0.3, 1.0);

        // Queue count
        if (state.production_queue.count > 1) {
            const queue_txt_x: f32 = bar_x + bar_w + 10;
            drawNumber(renderer, &ctx, queue_txt_x, bar_y, @intCast(state.production_queue.count), 0.9, 0.9, 0.9);
        }
    }

    // Unit/Building portrait area
    sprite_renderer_draw_rect(renderer, &ctx, 600, 720 - 95, 90, 85, 0.2, 0.2, 0.25, 1.0);

    // Show unit info if selected
    if (state.selected_unit_index) |unit_idx| {
        const unit = state.units[unit_idx];
        if (unit.is_alive) {
            // Draw unit portrait based on type
            const portrait_x: f32 = 610;
            const portrait_y: f32 = 720 - 85;

            // Unit type icon
            if (unit.unit_type == .Infantry) {
                sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 30, portrait_y + 10, 15, 15, 0.8, 0.7, 0.5, 1.0);
                sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 25, portrait_y + 30, 25, 35, 0.2, 0.4, 0.8, 1.0);
            } else {
                sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 10, portrait_y + 35, 55, 25, 0.2, 0.4, 0.8, 1.0);
                sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 25, portrait_y + 15, 25, 22, 0.15, 0.35, 0.7, 1.0);
                sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 33, portrait_y + 5, 10, 15, 0.1, 0.1, 0.15, 1.0);
            }

            // Health bar in portrait
            const hp_ratio = unit.health / unit.max_health;
            sprite_renderer_draw_rect(renderer, &ctx, portrait_x, portrait_y + 65, 70, 8, 0.3, 0.1, 0.1, 1.0);
            sprite_renderer_draw_rect(renderer, &ctx, portrait_x + 1, portrait_y + 66, 68 * hp_ratio, 6, 0.1, 0.8, 0.1, 1.0);
        }
    }

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
