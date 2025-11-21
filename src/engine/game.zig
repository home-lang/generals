// Generals Game Engine - Main Game Class
// Based on C&C Generals game architecture

const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

// Platform-specific imports (macOS for now)
const MacOSWindow = if (builtin.os.tag == .macos) @import("../platform/macos_window.zig").MacOSWindow else void;
const SpriteRenderer = if (builtin.os.tag == .macos) @import("../platform/macos_sprite_renderer.zig").SpriteRenderer else void;
const RenderContext = if (builtin.os.tag == .macos) @import("../platform/macos_sprite_renderer.zig").RenderContext else void;
const GPUTexture = if (builtin.os.tag == .macos) @import("../platform/macos_sprite_renderer.zig").Texture else void;

const TextureLoader = @import("texture.zig").Texture;
const Camera = @import("camera.zig").Camera;
const EntityManager = @import("entity.zig").EntityManager;
const Entity = @import("entity.zig").Entity;
const Sprite = @import("entity.zig").Sprite;
const TeamId = @import("entity.zig").TeamId;
const Pathfinder = @import("pathfinding.zig").Pathfinder;
const ResourceManager = @import("resource.zig").ResourceManager;
const PlayerResources = @import("resource.zig").PlayerResources;
const UIManager = @import("ui.zig").UIManager;
const Minimap = @import("minimap.zig").Minimap;
const MinimapIcon = @import("minimap.zig").MinimapIcon;
const MinimapIconType = @import("minimap.zig").MinimapIconType;
const FogOfWarManager = @import("fog_of_war.zig").FogOfWarManager;
const VisibilityState = @import("fog_of_war.zig").VisibilityState;
const ParticleSystem = @import("../renderer/particle_system.zig").ParticleSystem;
const spawnExplosion = @import("../renderer/particle_system.zig").spawnExplosion;
const CombatSystem = @import("combat.zig").CombatSystem;
const math = @import("math");
const Vec2 = math.Vec2(f32);

/// Game state
pub const GameState = enum {
    loading,
    main_menu,
    in_game,
    paused,
    quitting,
};

/// Input state
pub const InputState = struct {
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    mouse_left_down: bool = false,
    mouse_right_down: bool = false,
    mouse_left_clicked: bool = false,
    mouse_right_clicked: bool = false,
    quit_requested: bool = false,
    // Keyboard state
    key_up: bool = false,
    key_down: bool = false,
    key_left: bool = false,
    key_right: bool = false,
    key_w: bool = false,
    key_a: bool = false,
    key_s: bool = false,
    key_d: bool = false,
};

/// Main game class - entry point for the Generals engine
pub const Game = struct {
    allocator: Allocator,
    state: GameState,
    running: bool,
    delta_time: f64,
    total_time: f64,

    // Platform-specific (macOS)
    window: if (builtin.os.tag == .macos) ?MacOSWindow else void,
    renderer: if (builtin.os.tag == .macos) ?SpriteRenderer else void,

    // Camera
    camera: Camera,

    // Entity management
    entity_manager: EntityManager,

    // Pathfinding
    pathfinder: Pathfinder,

    // Resource management
    resource_manager: ResourceManager,
    player_resources: PlayerResources,

    // UI management
    ui_manager: UIManager,

    // Minimap
    minimap: Minimap,

    // Fog of War
    fog_of_war: FogOfWarManager,

    // Player team (for fog of war rendering)
    player_team: TeamId,

    // Particle system
    particle_system: ParticleSystem,

    // Input state
    input: InputState,

    // Test texture (temporary)
    test_texture: if (builtin.os.tag == .macos) ?GPUTexture else void,

    // Main menu texture
    menu_texture: if (builtin.os.tag == .macos) ?GPUTexture else void,

    // Menu button rects for click detection (positioned for 800x600 authentic layout)
    menu_buttons: [6]struct { x: f32, y: f32, width: f32, height: f32, label: []const u8 } = .{
        .{ .x = 580, .y = 100, .width = 160, .height = 30, .label = "SOLO PLAY" },
        .{ .x = 580, .y = 140, .width = 160, .height = 30, .label = "MULTIPLAYER" },
        .{ .x = 580, .y = 180, .width = 160, .height = 30, .label = "LOAD" },
        .{ .x = 580, .y = 220, .width = 160, .height = 30, .label = "OPTIONS" },
        .{ .x = 580, .y = 260, .width = 160, .height = 30, .label = "CREDITS" },
        .{ .x = 580, .y = 300, .width = 160, .height = 30, .label = "EXIT GAME" },
    },

    // Target frame rate (30 FPS logic, 60 FPS rendering)
    const TARGET_LOGIC_FPS: f64 = 30.0;
    const TARGET_LOGIC_TIME: f64 = 1.0 / TARGET_LOGIC_FPS;
    const TARGET_RENDER_FPS: f64 = 60.0;
    const TARGET_RENDER_TIME: f64 = 1.0 / TARGET_RENDER_FPS;

    pub fn init(allocator: Allocator) !Game {
        const world_width: f32 = 4000.0;
        const world_height: f32 = 4000.0;
        const num_teams: usize = 4; // Support up to 4 teams
        const fog_cell_size: f32 = 64.0; // 64x64 fog grid cells

        return Game{
            .allocator = allocator,
            .state = .loading,
            .running = false,
            .delta_time = 0.0,
            .total_time = 0.0,
            .window = null,
            .renderer = null,
            .camera = Camera.init(800, 600),
            .entity_manager = try EntityManager.init(allocator),
            .pathfinder = Pathfinder.init(allocator, 32.0), // 32-unit grid
            .resource_manager = try ResourceManager.init(allocator),
            .player_resources = PlayerResources.init(),
            .ui_manager = UIManager.init(allocator, 800, 600),
            .minimap = Minimap.init(800, 600, world_width, world_height),
            .fog_of_war = try FogOfWarManager.init(allocator, num_teams, world_width, world_height, fog_cell_size),
            .player_team = 0, // Player is team 0
            .particle_system = try ParticleSystem.init(allocator, 2000), // Max 2000 particles
            .input = .{},
            .test_texture = null,
            .menu_texture = null,
        };
    }

    pub fn deinit(self: *Game) void {
        // Clean up entity manager
        self.entity_manager.deinit();

        // Clean up resource manager
        self.resource_manager.deinit();

        // Clean up UI manager
        self.ui_manager.deinit();

        // Clean up fog of war
        self.fog_of_war.deinit();

        // Clean up particle system
        self.particle_system.deinit();

        // Clean up textures
        if (builtin.os.tag == .macos) {
            if (self.test_texture) |*texture| {
                texture.deinit();
            }

            if (self.menu_texture) |*texture| {
                texture.deinit();
            }

            // Clean up renderer
            if (self.renderer) |*renderer| {
                renderer.deinit();
            }

            // Clean up window
            if (self.window) |*window| {
                window.deinit();
            }
        }
    }

    /// Initialize game systems
    pub fn startup(self: *Game) !void {
        std.debug.print("Generals Engine: Initializing...\n", .{});

        if (builtin.os.tag == .macos) {
            // Create window (authentic title from original game)
            std.debug.print("Creating game window...\n", .{});
            self.window = try MacOSWindow.init("Command and Conquer Generals Zero Hour", 800, 600, false);

            // Create renderer
            std.debug.print("Initializing sprite renderer...\n", .{});
            const native_window = self.window.?.getNativeHandle();
            self.renderer = try SpriteRenderer.init(native_window);

            // Load a test texture
            std.debug.print("Loading test texture...\n", .{});
            var cpu_texture = try TextureLoader.loadTGA(self.allocator, "assets/textures/TXSnow01a_256x256.tga");
            defer cpu_texture.deinit();

            // Convert BGR to BGRA
            const texture_data = try self.allocator.alloc(u8, cpu_texture.width * cpu_texture.height * 4);
            defer self.allocator.free(texture_data);

            var i: usize = 0;
            var j: usize = 0;
            while (i < cpu_texture.data.len) : (i += 3) {
                texture_data[j] = cpu_texture.data[i];         // B
                texture_data[j + 1] = cpu_texture.data[i + 1]; // G
                texture_data[j + 2] = cpu_texture.data[i + 2]; // R
                texture_data[j + 3] = 255;                      // A
                j += 4;
            }

            // Upload to GPU
            self.test_texture = try self.renderer.?.createTexture(cpu_texture.width, cpu_texture.height, texture_data);

            // Load main menu background texture
            std.debug.print("Loading main menu background...\n", .{});
            std.debug.print("  Attempting to load: assets/ui/MainMenuBackground.tga\n", .{});
            if (TextureLoader.loadTGA(self.allocator, "assets/ui/MainMenuBackground.tga")) |menu_tex| {
                std.debug.print("  TGA loaded: {}x{}\n", .{ menu_tex.width, menu_tex.height });
                var cpu_menu = menu_tex;
                defer cpu_menu.deinit();

                // Allocate BGRA buffer
                const menu_data = try self.allocator.alloc(u8, cpu_menu.width * cpu_menu.height * 4);
                defer self.allocator.free(menu_data);

                // Convert based on format (menu may be 24-bit or 32-bit)
                const bytes_per_pixel: usize = cpu_menu.data.len / (cpu_menu.width * cpu_menu.height);
                var mi: usize = 0;
                var mj: usize = 0;
                if (bytes_per_pixel == 3) {
                    while (mi < cpu_menu.data.len) : (mi += 3) {
                        menu_data[mj] = cpu_menu.data[mi];         // B
                        menu_data[mj + 1] = cpu_menu.data[mi + 1]; // G
                        menu_data[mj + 2] = cpu_menu.data[mi + 2]; // R
                        menu_data[mj + 3] = 255;                    // A
                        mj += 4;
                    }
                } else {
                    while (mi < cpu_menu.data.len) : (mi += 4) {
                        menu_data[mj] = cpu_menu.data[mi];         // B
                        menu_data[mj + 1] = cpu_menu.data[mi + 1]; // G
                        menu_data[mj + 2] = cpu_menu.data[mi + 2]; // R
                        menu_data[mj + 3] = cpu_menu.data[mi + 3]; // A
                        mj += 4;
                    }
                }

                self.menu_texture = try self.renderer.?.createTexture(cpu_menu.width, cpu_menu.height, menu_data);
                std.debug.print("  Loaded main menu: {}x{}\n", .{ cpu_menu.width, cpu_menu.height });
            } else |err| {
                std.debug.print("  Warning: Could not load main menu background: {}\n", .{err});
            }

            // Setup skirmish mode
            std.debug.print("Setting up Skirmish Mode...\n", .{});
            const unit_sprite = Sprite.init(0, @floatFromInt(cpu_texture.width / 4), @floatFromInt(cpu_texture.height / 4));
            const building_sprite = Sprite.init(0, @floatFromInt(cpu_texture.width), @floatFromInt(cpu_texture.height));

            // Create Player base (team 0) - bottom left
            const player_base_x: f32 = -400.0;
            const player_base_y: f32 = -400.0;

            // Player Command Center
            _ = try self.entity_manager.createBuilding(player_base_x, player_base_y, "USA_CommandCenter", building_sprite, 0);
            // Player Barracks
            _ = try self.entity_manager.createBuilding(player_base_x + 150, player_base_y, "USA_Barracks", building_sprite, 0);
            // Player Supply Center
            _ = try self.entity_manager.createBuilding(player_base_x, player_base_y + 150, "USA_SupplyCenter", building_sprite, 0);
            // Player starting units
            _ = try self.entity_manager.createUnit(player_base_x + 80, player_base_y + 80, "USA_Ranger", unit_sprite, 0);
            _ = try self.entity_manager.createUnit(player_base_x + 100, player_base_y + 80, "USA_Ranger", unit_sprite, 0);
            _ = try self.entity_manager.createUnit(player_base_x + 120, player_base_y + 80, "USA_Ranger", unit_sprite, 0);
            _ = try self.entity_manager.createUnit(player_base_x + 50, player_base_y + 100, "USA_Humvee", unit_sprite, 0);

            // Create AI base (team 1) - top right
            const ai_base_x: f32 = 400.0;
            const ai_base_y: f32 = 400.0;

            // AI Command Center
            _ = try self.entity_manager.createBuilding(ai_base_x, ai_base_y, "China_CommandCenter", building_sprite, 1);
            // AI Barracks
            _ = try self.entity_manager.createBuilding(ai_base_x - 150, ai_base_y, "China_Barracks", building_sprite, 1);
            // AI Supply Center
            _ = try self.entity_manager.createBuilding(ai_base_x, ai_base_y - 150, "China_SupplyCenter", building_sprite, 1);
            // AI starting units
            _ = try self.entity_manager.createUnit(ai_base_x - 80, ai_base_y - 80, "China_RedGuard", unit_sprite, 1);
            _ = try self.entity_manager.createUnit(ai_base_x - 100, ai_base_y - 80, "China_RedGuard", unit_sprite, 1);
            _ = try self.entity_manager.createUnit(ai_base_x - 120, ai_base_y - 80, "China_RedGuard", unit_sprite, 1);
            _ = try self.entity_manager.createUnit(ai_base_x - 50, ai_base_y - 100, "China_Battlemaster", unit_sprite, 1);

            // Give starting supplies to player
            self.player_resources.supplies = 5000.0;
            self.player_resources.supply_limit = 10000.0;
            std.debug.print("  Player starting supplies: $5000\n", .{});
            std.debug.print("  AI starting supplies: $5000\n", .{});

            std.debug.print("Created {} entities (buildings + units)\n", .{self.entity_manager.getEntityCount()});

            // Initialize particle system
            std.debug.print("Initializing particle system...\n", .{});
            std.debug.print("Particle system initialized with {} max particles\n", .{self.particle_system.max_particles});

            // Show window
            self.window.?.show();
        }

        self.state = .main_menu;
        self.running = true;

        std.debug.print("Generals Engine: Ready!\n", .{});
    }

    /// Main game loop
    pub fn run(self: *Game) !void {
        var timer = try std.time.Timer.start();
        var logic_accumulator: f64 = 0.0;
        var render_accumulator: f64 = 0.0;

        std.debug.print("\nStarting game loop...\n", .{});
        std.debug.print("Press Cmd+Q to quit.\n\n", .{});

        while (self.running) {
            // Calculate delta time
            self.delta_time = @as(f64, @floatFromInt(timer.lap())) / std.time.ns_per_s;
            logic_accumulator += self.delta_time;
            render_accumulator += self.delta_time;

            // Process input
            try self.processInput();

            // Fixed timestep logic update (30 FPS)
            while (logic_accumulator >= TARGET_LOGIC_TIME) {
                try self.update(TARGET_LOGIC_TIME);
                logic_accumulator -= TARGET_LOGIC_TIME;
                self.total_time += TARGET_LOGIC_TIME;
            }

            // Render at 60 FPS
            if (render_accumulator >= TARGET_RENDER_TIME) {
                const alpha = logic_accumulator / TARGET_LOGIC_TIME;
                try self.render(alpha);
                render_accumulator = 0.0;
            }

            // Small sleep to prevent busy-waiting
            std.posix.nanosleep(0, 1_000_000); // 1ms
        }

        std.debug.print("\nGame loop ended.\n", .{});
    }

    pub fn processInput(self: *Game) !void {
        if (builtin.os.tag == .macos) {
            if (self.window) |*window| {
                const still_running = window.pollEvents();
                if (!still_running) {
                    self.quit();
                }

                // Update mouse position
                const mouse_pos = window.getMousePosition();
                self.input.mouse_x = mouse_pos.x;
                self.input.mouse_y = mouse_pos.y;

                // Update keyboard state
                const keyboard = window.getKeyboardState();
                self.input.key_up = keyboard.up;
                self.input.key_down = keyboard.down;
                self.input.key_left = keyboard.left;
                self.input.key_right = keyboard.right;
                self.input.key_w = keyboard.w;
                self.input.key_a = keyboard.a;
                self.input.key_s = keyboard.s;
                self.input.key_d = keyboard.d;

                // Update mouse button state
                const mouse_buttons = window.getMouseButtonState();
                self.input.mouse_left_down = mouse_buttons.left_down;
                self.input.mouse_right_down = mouse_buttons.right_down;
                self.input.mouse_left_clicked = mouse_buttons.left_clicked;
                self.input.mouse_right_clicked = mouse_buttons.right_clicked;
            }
        }
    }

    pub fn update(self: *Game, dt: f64) !void {
        // Update camera movement based on keyboard input
        var dir_x: f32 = 0;
        var dir_y: f32 = 0;

        // Arrow keys or WASD
        if (self.input.key_left or self.input.key_a) dir_x -= 1;
        if (self.input.key_right or self.input.key_d) dir_x += 1;
        if (self.input.key_up or self.input.key_w) dir_y -= 1;
        if (self.input.key_down or self.input.key_s) dir_y += 1;

        // Normalize diagonal movement
        if (dir_x != 0 and dir_y != 0) {
            const len = @sqrt(dir_x * dir_x + dir_y * dir_y);
            dir_x /= len;
            dir_y /= len;
        }

        // Pan camera
        if (dir_x != 0 or dir_y != 0) {
            self.camera.panWithDelta(dir_x, dir_y, @floatCast(dt));
        }

        // Handle unit selection with left click
        if (self.input.mouse_left_clicked) {
            // Convert mouse screen position to world position
            const mouse_screen_pos = Vec2.init(self.input.mouse_x, self.input.mouse_y);
            const world_pos = self.camera.screenToWorld(mouse_screen_pos);

            // Try to select a unit at the clicked position
            const selected_unit = self.entity_manager.selectUnitAt(world_pos, 50.0);
            if (selected_unit) |unit_id| {
                std.debug.print("Selected unit: {}\n", .{unit_id});
            }
        }

        // Handle unit movement with right click
        if (self.input.mouse_right_clicked) {
            // Convert mouse screen position to world position
            const mouse_screen_pos = Vec2.init(self.input.mouse_x, self.input.mouse_y);
            const target_pos = self.camera.screenToWorld(mouse_screen_pos);

            // Find selected unit and give it a move order
            const entities = self.entity_manager.getActiveEntities();
            for (entities) |*entity| {
                if (!entity.active) continue;
                if (entity.unit_data) |unit_data| {
                    if (unit_data.selected) {
                        // Create path to destination
                        const path = try self.pathfinder.findPath(entity.transform.position, target_pos);

                        // Set the path on the unit's movement component
                        if (entity.movement) |*movement| {
                            movement.setPath(path);
                            std.debug.print("Unit {} moving to ({d:.1}, {d:.1})\n", .{ entity.id, target_pos.x, target_pos.y });
                        }
                    }
                }
            }
        }

        // Update entities
        self.entity_manager.update(dt);

        // Update simple AI (enemy team 1 attacks player team 0)
        try self.updateSimpleAI(@floatCast(dt));

        // Update combat system
        CombatSystem.updateCombat(self.entity_manager.getActiveEntities(), &self.particle_system, @floatCast(dt));

        // Update particle system
        self.particle_system.update(@floatCast(dt));

        // Update fog of war
        self.fog_of_war.update(self.entity_manager.getActiveEntities());

        // Update UI
        self.ui_manager.update(self.input.mouse_x, self.input.mouse_y, self.input.mouse_left_clicked);

        // Update minimap
        self.minimap.update(1024); // Screen width

        // Handle minimap clicks (camera navigation)
        if (self.input.mouse_left_clicked) {
            if (self.minimap.handleClick(self.input.mouse_x, self.input.mouse_y)) |world_pos| {
                self.camera.position = world_pos;
                std.debug.print("Minimap click: moved camera to ({d:.1}, {d:.1})\n", .{ world_pos.x, world_pos.y });
            }
        }

        // Update unit info panel based on selection
        const entities = self.entity_manager.getActiveEntities();
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.unit_data) |unit_data| {
                if (unit_data.selected) {
                    self.ui_manager.setSelectedUnit(entity.id, unit_data.unit_type, unit_data.health, unit_data.max_health);
                    break;
                }
            }
        } else {
            self.ui_manager.clearSelection();
        }

        switch (self.state) {
            .loading => {
                // Transition to main menu after loading
                self.state = .main_menu;
            },
            .main_menu => {
                // Handle main menu button clicks
                if (self.input.mouse_left_clicked) {
                    const button_x: f32 = 580;
                    const button_width: f32 = 180;
                    const button_height: f32 = 32;
                    const button_start_y: f32 = 100;
                    const button_spacing: f32 = 40;

                    // Check each button
                    for (0..6) |i| {
                        const button_y: f32 = button_start_y + @as(f32, @floatFromInt(i)) * button_spacing;

                        if (self.input.mouse_x >= button_x and
                            self.input.mouse_x <= button_x + button_width and
                            self.input.mouse_y >= button_y and
                            self.input.mouse_y <= button_y + button_height)
                        {
                            if (i == 0) {
                                // SOLO PLAY - Start game
                                std.debug.print("Starting Solo Play...\n", .{});
                                self.state = .in_game;
                            } else if (i == 5) {
                                // EXIT GAME
                                std.debug.print("Exit requested from menu\n", .{});
                                self.quit();
                            } else {
                                std.debug.print("Button {} clicked (not implemented)\n", .{i});
                            }
                            break;
                        }
                    }
                }
            },
            .in_game => {
                // Update game logic
                // - Unit movement
                // - Combat
                // - AI
                // - Economy
            },
            .paused => {
                // Paused - no updates
            },
            .quitting => {
                self.running = false;
            },
        }
    }

    pub fn render(self: *Game, alpha: f64) !void {
        _ = alpha;

        if (builtin.os.tag == .macos) {
            if (self.renderer) |*renderer| {
                // Begin frame
                var ctx = renderer.beginFrame();
                if (!ctx.isValid()) {
                    return;
                }

                // Render based on game state
                if (self.state == .main_menu) {
                    // Render main menu
                    self.renderMainMenu(renderer, &ctx);
                    renderer.endFrame(&ctx);
                    return;
                }

                if (self.test_texture) |*texture| {
                    // Render terrain grid
                    self.renderTerrain(renderer, &ctx);

                    // Render all entities
                    const entities = self.entity_manager.getActiveEntities();
                    for (entities) |entity| {
                        if (!entity.active) continue;
                        if (entity.sprite == null) continue;

                        // Check fog of war visibility
                        const visibility = self.fog_of_war.getVisibilityState(self.player_team, entity.transform.position);
                        if (visibility == .unexplored) continue; // Don't render unexplored entities

                        const sprite = entity.sprite.?;

                        // Transform world position to screen coordinates
                        const screen_pos = self.camera.worldToScreen(entity.transform.position);

                        // Draw sprite centered on the entity position
                        const sprite_x: f32 = screen_pos.x - sprite.width / 2;
                        const sprite_y: f32 = screen_pos.y - sprite.height / 2;

                        // Only render if visible on screen (simple culling)
                        if (self.camera.isVisible(entity.transform.position, sprite.width)) {
                            renderer.drawSpriteBatched(&ctx, texture, sprite_x, sprite_y, sprite.width, sprite.height);

                            // Draw health bar if unit
                            if (entity.unit_data) |unit_data| {
                                const health_bar_width: f32 = sprite.width;
                                const health_bar_height: f32 = 4.0;
                                const health_bar_x: f32 = screen_pos.x - health_bar_width / 2;
                                const health_bar_y: f32 = screen_pos.y - sprite.height / 2 - 8; // 8 pixels above sprite

                                // Background (dark gray)
                                renderer.drawRect(&ctx, health_bar_x, health_bar_y, health_bar_width, health_bar_height, 0.2, 0.2, 0.2, 1.0);

                                // Health (green/yellow/red based on health percentage)
                                const health_pct: f32 = unit_data.health / unit_data.max_health;
                                const filled_width: f32 = health_bar_width * health_pct;

                                // Color interpolation based on health
                                var health_r: f32 = undefined;
                                var health_g: f32 = undefined;
                                if (health_pct > 0.5) {
                                    // Green to yellow (100% -> 50%)
                                    health_r = (1.0 - health_pct) * 2.0; // 0 -> 1
                                    health_g = 1.0;
                                } else {
                                    // Yellow to red (50% -> 0%)
                                    health_r = 1.0;
                                    health_g = health_pct * 2.0; // 1 -> 0
                                }
                                renderer.drawRect(&ctx, health_bar_x, health_bar_y, filled_width, health_bar_height, health_r, health_g, 0.0, 1.0);

                                // Draw selection circle if unit is selected
                                if (unit_data.selected) {
                                    const selection_radius: f32 = sprite.width / 2 + 10; // 10 pixels outside sprite
                                    // Green selection circle (RGBA)
                                    renderer.drawSelectionCircle(&ctx, screen_pos.x, screen_pos.y, selection_radius, 0.0, 1.0, 0.0, 1.0);
                                }
                            }
                        }
                    }

                    // Render particles
                    self.renderParticles(renderer, &ctx);

                    // Render UI
                    self.renderUI(renderer, &ctx);

                    // End frame
                    renderer.endFrame(&ctx);
                }
            }
        }
    }

    fn renderParticles(self: *Game, renderer: *SpriteRenderer, ctx: *RenderContext) void {
        const particles = self.particle_system.getActiveParticles();
        for (particles) |particle| {
            if (!particle.active) continue;

            // Transform world position to screen coordinates
            const world_pos = Vec2.init(particle.position.x, particle.position.y);
            const screen_pos = self.camera.worldToScreen(world_pos);

            // Draw particle as colored circle
            renderer.drawRect(
                ctx,
                screen_pos.x - particle.size / 2,
                screen_pos.y - particle.size / 2,
                particle.size,
                particle.size,
                particle.color.r,
                particle.color.g,
                particle.color.b,
                particle.color.a,
            );
        }
    }

    fn renderUI(self: *Game, renderer: *SpriteRenderer, ctx: *RenderContext) void {
        if (!self.ui_manager.show_ui) return;

        // Render resource display (top bar)
        const res_panel = &self.ui_manager.resource_display.panel;
        if (res_panel.visible) {
            renderer.drawRect(ctx, res_panel.x, res_panel.y, res_panel.width, res_panel.height,
                res_panel.background_color[0], res_panel.background_color[1],
                res_panel.background_color[2], res_panel.background_color[3]);
            // TODO: Render text for supplies and power values
        }

        // Render unit info panel (bottom left)
        const unit_panel = &self.ui_manager.unit_info_panel.panel;
        if (unit_panel.visible) {
            renderer.drawRect(ctx, unit_panel.x, unit_panel.y, unit_panel.width, unit_panel.height,
                unit_panel.background_color[0], unit_panel.background_color[1],
                unit_panel.background_color[2], unit_panel.background_color[3]);
            // TODO: Render text for unit name and health
        }

        // Render production queue display (bottom right)
        const prod_panel = &self.ui_manager.production_display.panel;
        if (prod_panel.visible) {
            renderer.drawRect(ctx, prod_panel.x, prod_panel.y, prod_panel.width, prod_panel.height,
                prod_panel.background_color[0], prod_panel.background_color[1],
                prod_panel.background_color[2], prod_panel.background_color[3]);
            // TODO: Render production queue items
        }

        // Render command panel (bottom center)
        const cmd_panel = &self.ui_manager.command_panel.panel;
        if (cmd_panel.visible) {
            renderer.drawRect(ctx, cmd_panel.x, cmd_panel.y, cmd_panel.width, cmd_panel.height,
                cmd_panel.background_color[0], cmd_panel.background_color[1],
                cmd_panel.background_color[2], cmd_panel.background_color[3]);

            // Render command buttons
            for (0..self.ui_manager.command_panel.button_count) |i| {
                const button = &self.ui_manager.command_panel.buttons[i];
                const btn_panel = &button.panel;
                if (btn_panel.visible) {
                    renderer.drawRect(ctx, btn_panel.x, btn_panel.y, btn_panel.width, btn_panel.height,
                        btn_panel.background_color[0], btn_panel.background_color[1],
                        btn_panel.background_color[2], btn_panel.background_color[3]);
                    // TODO: Render button label text
                }
            }
        }

        // Render minimap
        self.renderMinimap(renderer, ctx);
    }

    fn renderMinimap(self: *Game, renderer: *SpriteRenderer, ctx: *RenderContext) void {
        if (!self.minimap.visible) return;

        const config = &self.minimap.config;

        // Draw minimap background
        renderer.drawRect(ctx, config.x, config.y, config.width, config.height,
            config.background_color[0], config.background_color[1],
            config.background_color[2], config.background_color[3]);

        // Draw minimap border
        const border = config.border_width;
        renderer.drawRect(ctx, config.x - border, config.y - border,
            config.width + border * 2, border,
            config.border_color[0], config.border_color[1], config.border_color[2], config.border_color[3]);
        renderer.drawRect(ctx, config.x - border, config.y + config.height,
            config.width + border * 2, border,
            config.border_color[0], config.border_color[1], config.border_color[2], config.border_color[3]);
        renderer.drawRect(ctx, config.x - border, config.y,
            border, config.height,
            config.border_color[0], config.border_color[1], config.border_color[2], config.border_color[3]);
        renderer.drawRect(ctx, config.x + config.width, config.y,
            border, config.height,
            config.border_color[0], config.border_color[1], config.border_color[2], config.border_color[3]);

        // Draw entities on minimap
        const entities = self.entity_manager.getActiveEntities();
        for (entities) |entity| {
            if (!entity.active) continue;

            // Determine icon type based on entity type and team
            var icon_type: MinimapIconType = .unit_neutral;
            if (entity.unit_data != null) {
                if (entity.team == 0) {
                    icon_type = .unit_friendly;
                } else {
                    icon_type = .unit_enemy;
                }
            } else if (entity.building_data != null) {
                if (entity.team == 0) {
                    icon_type = .building_friendly;
                } else {
                    icon_type = .building_enemy;
                }
            }

            const icon = MinimapIcon.init(entity.transform.position, icon_type);
            const minimap_pos = config.worldToMinimap(entity.transform.position);
            const color = icon.getColor();

            // Draw icon as a small rectangle
            renderer.drawRect(ctx,
                minimap_pos.x - icon.size / 2, minimap_pos.y - icon.size / 2,
                icon.size, icon.size,
                color[0], color[1], color[2], color[3]);
        }

        // Draw camera viewport rectangle
        const viewport = self.minimap.getCameraViewport(&self.camera);
        const vp_color = self.minimap.camera_viewport_color;
        const vp_border: f32 = 1.0;

        // Draw viewport as outline (4 rectangles forming a frame)
        renderer.drawRect(ctx, viewport.x, viewport.y, viewport.width, vp_border,
            vp_color[0], vp_color[1], vp_color[2], vp_color[3]); // Top
        renderer.drawRect(ctx, viewport.x, viewport.y + viewport.height - vp_border, viewport.width, vp_border,
            vp_color[0], vp_color[1], vp_color[2], vp_color[3]); // Bottom
        renderer.drawRect(ctx, viewport.x, viewport.y, vp_border, viewport.height,
            vp_color[0], vp_color[1], vp_color[2], vp_color[3]); // Left
        renderer.drawRect(ctx, viewport.x + viewport.width - vp_border, viewport.y, vp_border, viewport.height,
            vp_color[0], vp_color[1], vp_color[2], vp_color[3]); // Right
    }

    /// Simple AI: Enemy units seek and attack player units
    fn updateSimpleAI(self: *Game, dt: f32) !void {
        _ = dt;
        const entities = self.entity_manager.getActiveEntities();

        // For each enemy unit (team 1), find nearest player unit (team 0) and move toward it
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.entity_type != .unit) continue;
            if (entity.team != 1) continue; // Only AI team

            // Check if unit has a unit_data component
            if (entity.unit_data) |*unit_data| {
                // Only move units that aren't already attacking or have high health
                if (unit_data.ai_state == .attacking) continue;

                // Find nearest enemy (player team = 0)
                var nearest_enemy: ?*Entity = null;
                var nearest_dist_sq: f32 = 9999999.0;

                for (entities) |*potential_target| {
                    if (!potential_target.active) continue;
                    if (potential_target.entity_type != .unit) continue;
                    if (potential_target.team != 0) continue; // Only player units

                    const dx = potential_target.transform.position.x - entity.transform.position.x;
                    const dy = potential_target.transform.position.y - entity.transform.position.y;
                    const dist_sq = dx * dx + dy * dy;

                    if (dist_sq < nearest_dist_sq) {
                        nearest_dist_sq = dist_sq;
                        nearest_enemy = potential_target;
                    }
                }

                // If found an enemy, set as target and move toward it
                if (nearest_enemy) |target| {
                    // Only update path occasionally (every second or so based on game tick)
                    if (entity.movement) |*movement| {
                        // If not currently moving or far from target
                        if (!movement.is_moving or nearest_dist_sq > 100 * 100) {
                            // Create path to target
                            const path = try self.pathfinder.findPath(entity.transform.position, target.transform.position);
                            movement.setPath(path);
                            unit_data.ai_state = .chasing;
                        }
                    }
                    unit_data.target_id = target.id;
                }
            }
        }
    }

    fn renderTerrain(self: *Game, renderer: *SpriteRenderer, ctx: *RenderContext) void {
        // Render a desert-style terrain grid
        const grid_size: f32 = 128.0;  // Size of each terrain tile
        const world_size: f32 = 2000.0; // Total world size to render

        // Calculate visible area in world space
        const camera_x = self.camera.position.x;
        const camera_y = self.camera.position.y;
        const half_width = self.camera.viewport_width / 2.0 / self.camera.zoom;
        const half_height = self.camera.viewport_height / 2.0 / self.camera.zoom;

        // Get grid bounds (with some margin)
        const start_x = @max(-world_size, camera_x - half_width - grid_size);
        const end_x = @min(world_size, camera_x + half_width + grid_size);
        const start_y = @max(-world_size, camera_y - half_height - grid_size);
        const end_y = @min(world_size, camera_y + half_height + grid_size);

        // Snap to grid
        var x = @floor(start_x / grid_size) * grid_size;
        while (x < end_x) : (x += grid_size) {
            var y = @floor(start_y / grid_size) * grid_size;
            while (y < end_y) : (y += grid_size) {
                const world_pos = Vec2.init(x, y);
                const screen_pos = self.camera.worldToScreen(world_pos);

                // Create checkerboard pattern for visual interest
                const ix = @as(i32, @intFromFloat(x / grid_size));
                const iy = @as(i32, @intFromFloat(y / grid_size));
                const is_light = @mod(ix + iy, 2) == 0;

                // Desert colors
                const base_r: f32 = if (is_light) 0.76 else 0.72; // Sandy tan
                const base_g: f32 = if (is_light) 0.66 else 0.62;
                const base_b: f32 = if (is_light) 0.46 else 0.42;

                const tile_screen_size = grid_size * self.camera.zoom;
                renderer.drawRect(ctx, screen_pos.x, screen_pos.y, tile_screen_size, tile_screen_size, base_r, base_g, base_b, 1.0);
            }
        }

        // Draw grid lines for clarity
        x = @floor(start_x / grid_size) * grid_size;
        while (x < end_x) : (x += grid_size) {
            const world_pos = Vec2.init(x, start_y);
            const screen_start = self.camera.worldToScreen(world_pos);
            const screen_end = self.camera.worldToScreen(Vec2.init(x, end_y));

            // Vertical grid line
            renderer.drawRect(ctx, screen_start.x, screen_start.y, 1.0, screen_end.y - screen_start.y, 0.5, 0.4, 0.3, 0.3);
        }

        var y = @floor(start_y / grid_size) * grid_size;
        while (y < end_y) : (y += grid_size) {
            const world_pos = Vec2.init(start_x, y);
            const screen_start = self.camera.worldToScreen(world_pos);
            const screen_end = self.camera.worldToScreen(Vec2.init(end_x, y));

            // Horizontal grid line
            renderer.drawRect(ctx, screen_start.x, screen_start.y, screen_end.x - screen_start.x, 1.0, 0.5, 0.4, 0.3, 0.3);
        }
    }

    /// Render authentic main menu
    fn renderMainMenu(self: *Game, renderer: *SpriteRenderer, ctx: *RenderContext) void {
        // Draw main menu background (authentic Zero Hour screenshot)
        if (self.menu_texture) |*menu_tex| {
            // Scale to fill 800x600 window (original is 800x600)
            const scale_x: f32 = 800.0 / @as(f32, @floatFromInt(menu_tex.width));
            const scale_y: f32 = 600.0 / @as(f32, @floatFromInt(menu_tex.height));
            renderer.drawSpriteBatched(ctx, menu_tex, 0, 0, @as(f32, @floatFromInt(menu_tex.width)) * scale_x, @as(f32, @floatFromInt(menu_tex.height)) * scale_y);
        } else {
            // Fallback: Draw dark blue background
            renderer.drawRect(ctx, 0, 0, 800, 600, 0.1, 0.15, 0.25, 1.0);

            // Draw title text area
            renderer.drawRect(ctx, 580, 30, 200, 60, 0.2, 0.3, 0.5, 0.8);

            // Draw menu buttons with authentic Zero Hour styling
            const button_x: f32 = 580;
            const button_width: f32 = 180;
            const button_height: f32 = 32;
            const button_start_y: f32 = 100;
            const button_spacing: f32 = 40;

            const button_labels = [_][]const u8{
                "SOLO PLAY",
                "MULTIPLAYER",
                "LOAD",
                "OPTIONS",
                "CREDITS",
                "EXIT GAME",
            };

            for (button_labels, 0..) |_, i| {
                const button_y: f32 = button_start_y + @as(f32, @floatFromInt(i)) * button_spacing;

                // Check if mouse is hovering
                const is_hovered = self.input.mouse_x >= button_x and
                    self.input.mouse_x <= button_x + button_width and
                    self.input.mouse_y >= button_y and
                    self.input.mouse_y <= button_y + button_height;

                // Button background (darker blue with lighter border when hovered)
                if (is_hovered) {
                    renderer.drawRect(ctx, button_x - 2, button_y - 2, button_width + 4, button_height + 4, 0.2, 0.4, 0.8, 1.0);
                }
                renderer.drawRect(ctx, button_x, button_y, button_width, button_height, 0.1, 0.15, 0.3, 1.0);

                // Button border (blue gradient)
                renderer.drawRect(ctx, button_x, button_y, button_width, 2, 0.3, 0.5, 0.8, 1.0); // Top
                renderer.drawRect(ctx, button_x, button_y + button_height - 2, button_width, 2, 0.2, 0.3, 0.5, 1.0); // Bottom
                renderer.drawRect(ctx, button_x, button_y, 2, button_height, 0.3, 0.5, 0.8, 1.0); // Left
                renderer.drawRect(ctx, button_x + button_width - 2, button_y, 2, button_height, 0.2, 0.3, 0.5, 1.0); // Right
            }

            // Draw decorative frame around shell map area
            renderer.drawRect(ctx, 20, 50, 580, 2, 0.3, 0.5, 0.8, 1.0); // Top
            renderer.drawRect(ctx, 20, 550, 580, 2, 0.3, 0.5, 0.8, 1.0); // Bottom
            renderer.drawRect(ctx, 20, 50, 2, 502, 0.3, 0.5, 0.8, 1.0); // Left
            renderer.drawRect(ctx, 598, 50, 2, 502, 0.3, 0.5, 0.8, 1.0); // Right
        }
    }

    pub fn quit(self: *Game) void {
        std.debug.print("Quit requested...\n", .{});
        self.state = .quitting;
    }
};
