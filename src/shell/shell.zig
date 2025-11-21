// Shell System - Screen Stack and Menu Management
// Based on Thyme's shell.cpp - manages the game's menu screens and shell map background
//
// The Shell is responsible for:
// - Managing a stack of up to 16 menu screens
// - Rendering the 3D animated shell map background
// - Handling screen transitions with animations
// - Coordinating the startup sequence (splash → videos → main menu)

const std = @import("std");
const Allocator = std.mem.Allocator;
const wnd_parser = @import("wnd_parser.zig");

/// Maximum screens that can be on the stack
const MAX_SCREEN_STACK = 16;

/// Animation types for screen transitions (from Thyme's animatewindowmanager.h)
pub const AnimationType = enum {
    none,
    slide_right,
    slide_right_fast,
    slide_left,
    slide_top,
    slide_top_fast,
    slide_bottom,
    slide_bottom_timed,
    spiral,
};

/// Screen transition state
pub const TransitionState = enum {
    idle,
    pushing,
    popping,
    animating_in,
    animating_out,
};

/// A loaded menu screen (WindowLayout equivalent from Thyme)
pub const Screen = struct {
    filename: []const u8,
    wnd_file: ?wnd_parser.WndFile,
    is_hidden: bool,

    // Animation state
    anim_type: AnimationType,
    anim_progress: f32, // 0.0 to 1.0
    anim_start_x: f32,
    anim_start_y: f32,
    anim_end_x: f32,
    anim_end_y: f32,
    current_x: f32,
    current_y: f32,

    allocator: Allocator,

    pub fn init(allocator: Allocator, filename: []const u8) Screen {
        return Screen{
            .filename = filename,
            .wnd_file = null,
            .is_hidden = false,
            .anim_type = .none,
            .anim_progress = 1.0,
            .anim_start_x = 0,
            .anim_start_y = 0,
            .anim_end_x = 0,
            .anim_end_y = 0,
            .current_x = 0,
            .current_y = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Screen) void {
        if (self.wnd_file) |*wnd| {
            wnd.deinit();
        }
    }

    pub fn load(self: *Screen, base_path: []const u8) !void {
        var path_buf: [512]u8 = undefined;
        const full_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base_path, self.filename }) catch self.filename;

        self.wnd_file = wnd_parser.loadWndFile(self.allocator, full_path) catch |err| {
            std.debug.print("Warning: Could not load WND file {s}: {}\n", .{ full_path, err });
            return;
        };
    }
};

/// Game phase for startup sequence
pub const GamePhase = enum {
    initializing,
    splash_screen,       // Install_Final.bmp splash
    playing_logo,        // EA logo video
    playing_sizzle,      // Sizzle reel video
    legal_notice,        // Legal disclaimer
    loading_shell_map,   // Loading 3D background
    main_menu,           // In main menu
    in_game,             // Playing game
    loading_game,        // Loading a game/map
};

/// Shell Menu Scheme Line (decorative)
pub const SchemeLine = struct {
    start_x: i32,
    start_y: i32,
    end_x: i32,
    end_y: i32,
    width: i32,
    color: u32,
};

/// Shell Menu Scheme Image (decorative)
pub const SchemeImage = struct {
    name: []const u8,
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

/// Shell Menu Scheme - visual customization for menus
pub const ShellMenuScheme = struct {
    name: []const u8,
    // Simplified: use fixed-size arrays for now
    lines: [32]SchemeLine,
    line_count: usize,
    images: [16]SchemeImage,
    image_count: usize,

    pub fn init(name: []const u8) ShellMenuScheme {
        return ShellMenuScheme{
            .name = name,
            .lines = undefined,
            .line_count = 0,
            .images = undefined,
            .image_count = 0,
        };
    }

    pub fn deinit(self: *ShellMenuScheme) void {
        _ = self;
        // No dynamic memory to free
    }
};

/// Main Shell system - manages all menu screens and startup sequence
pub const Shell = struct {
    allocator: Allocator,

    // Screen stack (max 16 screens like Thyme)
    screen_stack: [MAX_SCREEN_STACK]?*Screen,
    screen_count: usize,

    // Background (shell map)
    background: ?*Screen,
    shell_map_on: bool,
    shell_map_name: []const u8,
    clear_background: bool,

    // Game phase / startup sequence
    phase: GamePhase,
    phase_timer: f64,
    phase_start_time: f64,

    // Pending operations
    pending_push: bool,
    pending_pop: bool,
    pending_push_name: []const u8,

    // Animation state
    transition_state: TransitionState,

    // Menu schemes
    current_scheme: ?*ShellMenuScheme,
    schemes: [8]ShellMenuScheme,
    scheme_count: usize,

    // Configuration
    play_intro: bool,
    play_sizzle: bool,
    after_intro: bool,
    is_shell_active: bool,

    // Asset paths
    asset_path: []const u8,

    // Timing constants (in seconds)
    const SPLASH_DURATION: f64 = 2.0;
    const LOGO_DURATION: f64 = 5.0;
    const LOGO_FADE_DURATION: f64 = 3.0;
    const SIZZLE_DURATION: f64 = 8.0;
    const LEGAL_DURATION: f64 = 4.0;

    pub fn init(allocator: Allocator, asset_path: []const u8) !*Shell {
        const self = try allocator.create(Shell);
        self.* = Shell{
            .allocator = allocator,
            .screen_stack = [_]?*Screen{null} ** MAX_SCREEN_STACK,
            .screen_count = 0,
            .background = null,
            .shell_map_on = true,
            .shell_map_name = "maps/shell/shell.map",
            .clear_background = true,
            .phase = .initializing,
            .phase_timer = 0,
            .phase_start_time = 0,
            .pending_push = false,
            .pending_pop = false,
            .pending_push_name = "",
            .transition_state = .idle,
            .current_scheme = null,
            .schemes = undefined,
            .scheme_count = 0,
            .play_intro = true,
            .play_sizzle = true,
            .after_intro = false,
            .is_shell_active = false,
            .asset_path = asset_path,
        };

        return self;
    }

    pub fn deinit(self: *Shell) void {
        // Clean up screen stack
        for (&self.screen_stack) |*screen_opt| {
            if (screen_opt.*) |screen| {
                screen.deinit();
                self.allocator.destroy(screen);
            }
        }

        // Clean up background
        if (self.background) |bg| {
            bg.deinit();
            self.allocator.destroy(bg);
        }

        // Clean up schemes
        for (0..self.scheme_count) |i| {
            self.schemes[i].deinit();
        }

        self.allocator.destroy(self);
    }

    /// Start the shell (begins startup sequence)
    pub fn start(self: *Shell) void {
        std.debug.print("\n", .{});
        std.debug.print("╔═══════════════════════════════════════════════════════╗\n", .{});
        std.debug.print("║         Starting Shell System                         ║\n", .{});
        std.debug.print("╚═══════════════════════════════════════════════════════╝\n", .{});

        self.phase = .splash_screen;
        self.phase_start_time = 0;
        self.phase_timer = 0;

        std.debug.print("Phase: Splash Screen\n", .{});
    }

    /// Update shell state (called each frame)
    pub fn update(self: *Shell, delta_time: f64) void {
        self.phase_timer += delta_time;

        switch (self.phase) {
            .initializing => {
                self.start();
            },
            .splash_screen => {
                // Display splash for SPLASH_DURATION seconds
                if (self.phase_timer >= SPLASH_DURATION) {
                    self.advancePhase();
                }
            },
            .playing_logo => {
                // Play EA logo for LOGO_DURATION + fade
                if (self.phase_timer >= LOGO_DURATION + LOGO_FADE_DURATION) {
                    self.advancePhase();
                }
            },
            .playing_sizzle => {
                // Play sizzle reel
                if (!self.play_sizzle or self.phase_timer >= SIZZLE_DURATION) {
                    self.advancePhase();
                }
            },
            .legal_notice => {
                // Show legal notice
                if (self.phase_timer >= LEGAL_DURATION) {
                    self.advancePhase();
                }
            },
            .loading_shell_map => {
                // Load the 3D shell map background
                self.loadShellMap();
                self.advancePhase();
            },
            .main_menu => {
                // Main menu active - process pending operations
                self.processPendingOperations();
                self.updateAnimations(delta_time);
            },
            .in_game => {
                // Game is running
            },
            .loading_game => {
                // Loading screen
            },
        }
    }

    fn advancePhase(self: *Shell) void {
        self.phase_timer = 0;

        switch (self.phase) {
            .initializing => self.phase = .splash_screen,
            .splash_screen => {
                if (self.play_intro) {
                    self.phase = .playing_logo;
                    std.debug.print("Phase: Playing Logo Video\n", .{});
                } else {
                    self.phase = .loading_shell_map;
                }
            },
            .playing_logo => {
                self.after_intro = true;
                if (self.play_sizzle) {
                    self.phase = .playing_sizzle;
                    std.debug.print("Phase: Playing Sizzle Reel\n", .{});
                } else {
                    self.phase = .legal_notice;
                }
            },
            .playing_sizzle => {
                self.phase = .legal_notice;
                std.debug.print("Phase: Legal Notice\n", .{});
            },
            .legal_notice => {
                self.phase = .loading_shell_map;
                std.debug.print("Phase: Loading Shell Map\n", .{});
            },
            .loading_shell_map => {
                self.phase = .main_menu;
                self.is_shell_active = true;
                std.debug.print("Phase: Main Menu\n", .{});

                // Push the main menu screen
                self.pushScreen("Menus/MainMenu.wnd", .slide_right);
            },
            .main_menu => {},
            .in_game => {},
            .loading_game => {},
        }
    }

    fn loadShellMap(self: *Shell) void {
        if (!self.shell_map_on) return;

        std.debug.print("Loading shell map: {s}\n", .{self.shell_map_name});

        // Create background screen for shell map
        const bg = self.allocator.create(Screen) catch return;
        bg.* = Screen.init(self.allocator, self.shell_map_name);
        self.background = bg;

        // In full implementation, this would load the 3D map
        // For now, we'll use a placeholder that the renderer can recognize
    }

    /// Push a new screen onto the stack with animation
    pub fn pushScreen(self: *Shell, filename: []const u8, anim: AnimationType) void {
        if (self.screen_count >= MAX_SCREEN_STACK) {
            std.debug.print("Error: Screen stack full!\n", .{});
            return;
        }

        std.debug.print("Pushing screen: {s}\n", .{filename});

        const screen = self.allocator.create(Screen) catch return;
        screen.* = Screen.init(self.allocator, filename);
        screen.anim_type = anim;

        // Load the WND file
        screen.load(self.asset_path) catch {};

        // Setup animation
        self.setupPushAnimation(screen, anim);

        self.screen_stack[self.screen_count] = screen;
        self.screen_count += 1;
        self.transition_state = .animating_in;
    }

    /// Pop the top screen with animation
    pub fn popScreen(self: *Shell, anim: AnimationType) void {
        if (self.screen_count == 0) return;

        if (self.top()) |screen| {
            std.debug.print("Popping screen: {s}\n", .{screen.filename});
            self.setupPopAnimation(screen, anim);
            self.transition_state = .animating_out;
        }
    }

    /// Pop screen immediately without animation
    pub fn popImmediate(self: *Shell) void {
        if (self.screen_count == 0) return;

        const idx = self.screen_count - 1;
        if (self.screen_stack[idx]) |screen| {
            screen.deinit();
            self.allocator.destroy(screen);
            self.screen_stack[idx] = null;
            self.screen_count -= 1;
        }
    }

    /// Get top screen on stack
    pub fn top(self: *Shell) ?*Screen {
        if (self.screen_count == 0) return null;
        return self.screen_stack[self.screen_count - 1];
    }

    /// Show/hide shell map background
    pub fn showShellMap(self: *Shell, show: bool) void {
        self.shell_map_on = show;
        std.debug.print("Shell map: {s}\n", .{if (show) "ON" else "OFF"});
    }

    /// Show shell (enter menu mode)
    pub fn showShell(self: *Shell) void {
        self.is_shell_active = true;
        self.shell_map_on = true;
    }

    /// Hide shell (exit to game)
    pub fn hideShell(self: *Shell) void {
        self.is_shell_active = false;
    }

    fn setupPushAnimation(self: *Shell, screen: *Screen, anim: AnimationType) void {
        _ = self;
        const screen_width: f32 = 1024.0;
        const screen_height: f32 = 768.0;

        screen.anim_progress = 0.0;
        screen.anim_end_x = 0;
        screen.anim_end_y = 0;

        switch (anim) {
            .slide_right, .slide_right_fast => {
                screen.anim_start_x = screen_width;
                screen.anim_start_y = 0;
            },
            .slide_left => {
                screen.anim_start_x = -screen_width;
                screen.anim_start_y = 0;
            },
            .slide_top, .slide_top_fast => {
                screen.anim_start_x = 0;
                screen.anim_start_y = -screen_height;
            },
            .slide_bottom, .slide_bottom_timed => {
                screen.anim_start_x = 0;
                screen.anim_start_y = screen_height;
            },
            .spiral => {
                screen.anim_start_x = screen_width / 2;
                screen.anim_start_y = -screen_height;
            },
            .none => {
                screen.anim_progress = 1.0;
            },
        }

        screen.current_x = screen.anim_start_x;
        screen.current_y = screen.anim_start_y;
    }

    fn setupPopAnimation(self: *Shell, screen: *Screen, anim: AnimationType) void {
        _ = self;
        const screen_width: f32 = 1024.0;
        const screen_height: f32 = 768.0;

        screen.anim_progress = 0.0;
        screen.anim_start_x = screen.current_x;
        screen.anim_start_y = screen.current_y;

        switch (anim) {
            .slide_right, .slide_right_fast => {
                screen.anim_end_x = screen_width;
                screen.anim_end_y = 0;
            },
            .slide_left => {
                screen.anim_end_x = -screen_width;
                screen.anim_end_y = 0;
            },
            .slide_top, .slide_top_fast => {
                screen.anim_end_x = 0;
                screen.anim_end_y = -screen_height;
            },
            .slide_bottom, .slide_bottom_timed => {
                screen.anim_end_x = 0;
                screen.anim_end_y = screen_height;
            },
            .spiral => {
                screen.anim_end_x = screen_width / 2;
                screen.anim_end_y = screen_height;
            },
            .none => {
                screen.anim_progress = 1.0;
            },
        }
    }

    fn updateAnimations(self: *Shell, delta_time: f64) void {
        const anim_speed: f32 = 3.0; // Animation speed multiplier

        for (0..self.screen_count) |i| {
            if (self.screen_stack[i]) |screen| {
                if (screen.anim_progress < 1.0) {
                    screen.anim_progress += @as(f32, @floatCast(delta_time)) * anim_speed;
                    if (screen.anim_progress > 1.0) screen.anim_progress = 1.0;

                    // Ease out interpolation
                    const t = easeOutQuad(screen.anim_progress);
                    screen.current_x = lerp(screen.anim_start_x, screen.anim_end_x, t);
                    screen.current_y = lerp(screen.anim_start_y, screen.anim_end_y, t);
                }
            }
        }

        // Check if pop animation finished
        if (self.transition_state == .animating_out) {
            if (self.top()) |screen| {
                if (screen.anim_progress >= 1.0) {
                    self.popImmediate();
                    self.transition_state = .idle;
                }
            }
        } else if (self.transition_state == .animating_in) {
            if (self.top()) |screen| {
                if (screen.anim_progress >= 1.0) {
                    self.transition_state = .idle;
                }
            }
        }
    }

    fn processPendingOperations(self: *Shell) void {
        if (self.pending_pop) {
            self.pending_pop = false;
            self.popScreen(.slide_left);
        }

        if (self.pending_push) {
            self.pending_push = false;
            self.pushScreen(self.pending_push_name, .slide_right);
        }
    }

    /// Get current phase name for display
    pub fn getPhaseName(self: *Shell) []const u8 {
        return switch (self.phase) {
            .initializing => "Initializing",
            .splash_screen => "Splash Screen",
            .playing_logo => "EA Logo",
            .playing_sizzle => "Sizzle Reel",
            .legal_notice => "Legal Notice",
            .loading_shell_map => "Loading Shell Map",
            .main_menu => "Main Menu",
            .in_game => "In Game",
            .loading_game => "Loading",
        };
    }

    /// Check if shell is in menu mode
    pub fn isInMenu(self: *Shell) bool {
        return self.is_shell_active and self.phase == .main_menu;
    }

    /// Skip intro sequence (go directly to main menu)
    pub fn skipIntro(self: *Shell) void {
        if (self.phase != .main_menu and self.phase != .in_game) {
            std.debug.print("Skipping intro...\n", .{});
            self.phase = .loading_shell_map;
            self.phase_timer = 0;
        }
    }

    /// Navigate to a specific menu
    pub fn navigateTo(self: *Shell, menu_name: []const u8) void {
        // Common menu navigation
        if (std.mem.eql(u8, menu_name, "skirmish")) {
            self.pushScreen("Menus/SkirmishGameOptionsMenu.wnd", .slide_right);
        } else if (std.mem.eql(u8, menu_name, "campaign")) {
            self.pushScreen("Menus/SinglePlayer.wnd", .slide_right);
        } else if (std.mem.eql(u8, menu_name, "multiplayer")) {
            self.pushScreen("Menus/LanLobbyMenu.wnd", .slide_right);
        } else if (std.mem.eql(u8, menu_name, "options")) {
            self.pushScreen("Menus/OptionsMenu.wnd", .slide_right);
        } else if (std.mem.eql(u8, menu_name, "replay")) {
            self.pushScreen("Menus/ReplayMenu.wnd", .slide_right);
        } else if (std.mem.eql(u8, menu_name, "back")) {
            self.popScreen(.slide_left);
        }
    }

    /// Start a game (exit shell)
    pub fn startGame(self: *Shell, mode: []const u8) void {
        std.debug.print("Starting game: {s}\n", .{mode});
        self.phase = .loading_game;
        self.hideShell();
    }
};

// Math utilities
fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

fn easeOutQuad(t: f32) f32 {
    return 1 - (1 - t) * (1 - t);
}

// Tests
test "shell initialization" {
    const allocator = std.testing.allocator;
    const shell = try Shell.init(allocator, "assets");
    defer shell.deinit();

    try std.testing.expectEqual(GamePhase.initializing, shell.phase);
    try std.testing.expectEqual(@as(usize, 0), shell.screen_count);
}

test "shell startup sequence" {
    const allocator = std.testing.allocator;
    const shell = try Shell.init(allocator, "assets");
    defer shell.deinit();

    shell.start();
    try std.testing.expectEqual(GamePhase.splash_screen, shell.phase);

    // Skip intro to go directly to main menu
    shell.skipIntro();
    shell.update(0.1);
    try std.testing.expectEqual(GamePhase.main_menu, shell.phase);
}
