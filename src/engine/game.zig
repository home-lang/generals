// Generals Game Engine - Main Game Class
// Based on C&C Generals game architecture

const std = @import("std");
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");

// Platform-specific imports (macOS for now)
const MacOSWindow = if (builtin.os.tag == .macos) @import("../platform/macos_window.zig").MacOSWindow else void;
const SpriteRenderer = if (builtin.os.tag == .macos) @import("../platform/macos_sprite_renderer.zig").SpriteRenderer else void;
const GPUTexture = if (builtin.os.tag == .macos) @import("../platform/macos_sprite_renderer.zig").Texture else void;

const TextureLoader = @import("texture.zig").Texture;
const Camera = @import("camera.zig").Camera;
const EntityManager = @import("entity.zig").EntityManager;
const Sprite = @import("entity.zig").Sprite;
const Pathfinder = @import("pathfinding.zig").Pathfinder;
const ResourceManager = @import("resource.zig").ResourceManager;
const PlayerResources = @import("resource.zig").PlayerResources;
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

    // Input state
    input: InputState,

    // Test texture (temporary)
    test_texture: if (builtin.os.tag == .macos) ?GPUTexture else void,

    // Target frame rate (30 FPS logic, 60 FPS rendering)
    const TARGET_LOGIC_FPS: f64 = 30.0;
    const TARGET_LOGIC_TIME: f64 = 1.0 / TARGET_LOGIC_FPS;
    const TARGET_RENDER_FPS: f64 = 60.0;
    const TARGET_RENDER_TIME: f64 = 1.0 / TARGET_RENDER_FPS;

    pub fn init(allocator: Allocator) !Game {
        return Game{
            .allocator = allocator,
            .state = .loading,
            .running = false,
            .delta_time = 0.0,
            .total_time = 0.0,
            .window = null,
            .renderer = null,
            .camera = Camera.init(1024, 768),
            .entity_manager = try EntityManager.init(allocator),
            .pathfinder = Pathfinder.init(allocator, 32.0), // 32-unit grid
            .resource_manager = try ResourceManager.init(allocator),
            .player_resources = PlayerResources.init(),
            .input = .{},
            .test_texture = null,
        };
    }

    pub fn deinit(self: *Game) void {
        // Clean up entity manager
        self.entity_manager.deinit();

        // Clean up resource manager
        self.resource_manager.deinit();

        // Clean up test texture
        if (builtin.os.tag == .macos) {
            if (self.test_texture) |*texture| {
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
            // Create window
            std.debug.print("Creating game window...\n", .{});
            self.window = try MacOSWindow.init("Command & Conquer: Generals - Home Edition", 1024, 768, false);

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

            // Create some test units
            std.debug.print("Creating test units...\n", .{});
            const sprite = Sprite.init(0, @floatFromInt(cpu_texture.width), @floatFromInt(cpu_texture.height));

            // Create units in a close pattern to test combat (within 150 unit range)
            // Team 0 (left side) - 3 units
            _ = try self.entity_manager.createUnit(-60, 0, "TestUnit1", sprite, 0);
            _ = try self.entity_manager.createUnit(-60, 80, "TestUnit2", sprite, 0);
            _ = try self.entity_manager.createUnit(-60, -80, "TestUnit3", sprite, 0);

            // Team 1 (right side) - 2 units
            _ = try self.entity_manager.createUnit(60, 0, "TestUnit4", sprite, 1);
            _ = try self.entity_manager.createUnit(60, 80, "TestUnit5", sprite, 1);

            std.debug.print("Created {} entities\n", .{self.entity_manager.getEntityCount()});

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

    fn processInput(self: *Game) !void {
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

    fn update(self: *Game, dt: f64) !void {
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

        switch (self.state) {
            .loading => {
                // Transition to main menu after loading
                self.state = .main_menu;
            },
            .main_menu => {
                // Update main menu
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

    fn render(self: *Game, alpha: f64) !void {
        _ = alpha;

        if (builtin.os.tag == .macos) {
            if (self.renderer) |*renderer| {
                if (self.test_texture) |*texture| {
                    // Begin frame
                    var ctx = renderer.beginFrame();
                    if (!ctx.isValid()) return;

                    // Render all entities
                    const entities = self.entity_manager.getActiveEntities();
                    for (entities) |entity| {
                        if (!entity.active) continue;
                        if (entity.sprite == null) continue;

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

                    // End frame
                    renderer.endFrame(&ctx);
                }
            }
        }
    }

    pub fn quit(self: *Game) void {
        std.debug.print("Quit requested...\n", .{});
        self.state = .quitting;
    }
};
