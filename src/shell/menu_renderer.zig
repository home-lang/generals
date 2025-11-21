// Menu Renderer - Renders WND-based menus
// Based on Thyme's gamewindowmanager.cpp and display system
//
// This module renders the parsed WND window definitions using the game's
// rendering system, matching the authentic C&C Generals menu appearance.

const std = @import("std");
const Allocator = std.mem.Allocator;
const wnd_parser = @import("wnd_parser.zig");
const WindowDef = wnd_parser.WindowDef;
const WndFile = wnd_parser.WndFile;
const Color = wnd_parser.Color;
const Rect = wnd_parser.Rect;
const WindowType = wnd_parser.WindowType;

/// Menu button state for interaction
pub const ButtonState = enum {
    normal,
    hovered,
    pressed,
    disabled,
};

/// Interactive menu button
pub const MenuButton = struct {
    window: *WindowDef,
    state: ButtonState,
    callback_id: []const u8,

    pub fn init(window: *WindowDef) MenuButton {
        return MenuButton{
            .window = window,
            .state = .normal,
            .callback_id = window.input_callback,
        };
    }

    pub fn containsPoint(self: *const MenuButton, x: f32, y: f32) bool {
        const rect = self.window.screen_rect;
        return x >= @as(f32, @floatFromInt(rect.x)) and
            x < @as(f32, @floatFromInt(rect.x + rect.width)) and
            y >= @as(f32, @floatFromInt(rect.y)) and
            y < @as(f32, @floatFromInt(rect.y + rect.height));
    }
};

/// Menu click result
pub const MenuAction = enum {
    none,
    single_player,
    skirmish,
    multiplayer,
    replay,
    load_game,
    options,
    exit,
    back,
    start_game,
};

/// Main Menu Renderer
pub const MenuRenderer = struct {
    allocator: Allocator,

    // Currently loaded menu
    current_menu: ?WndFile,
    menu_name: []const u8,

    // Interactive buttons
    buttons: [32]MenuButton,
    button_count: usize,

    // Mouse state
    mouse_x: f32,
    mouse_y: f32,
    mouse_down: bool,

    // Screen dimensions
    screen_width: f32,
    screen_height: f32,

    // Scale factors for resolution adaptation
    scale_x: f32,
    scale_y: f32,

    pub fn init(allocator: Allocator, screen_width: f32, screen_height: f32) MenuRenderer {
        // Original C&C Generals menus were designed for 800x600
        const base_width: f32 = 800.0;
        const base_height: f32 = 600.0;

        return MenuRenderer{
            .allocator = allocator,
            .current_menu = null,
            .menu_name = "",
            .buttons = undefined,
            .button_count = 0,
            .mouse_x = 0,
            .mouse_y = 0,
            .mouse_down = false,
            .screen_width = screen_width,
            .screen_height = screen_height,
            .scale_x = screen_width / base_width,
            .scale_y = screen_height / base_height,
        };
    }

    pub fn deinit(self: *MenuRenderer) void {
        if (self.current_menu) |*menu| {
            menu.deinit();
        }
    }

    /// Load a menu from WND file
    pub fn loadMenu(self: *MenuRenderer, path: []const u8) !void {
        // Unload previous menu
        if (self.current_menu) |*menu| {
            menu.deinit();
        }

        self.current_menu = try wnd_parser.loadWndFile(self.allocator, path);
        self.menu_name = path;

        // Extract buttons from the loaded menu
        self.extractButtons();

        std.debug.print("Loaded menu: {s}\n", .{path});
    }

    /// Extract interactive buttons from the window hierarchy
    fn extractButtons(self: *MenuRenderer) void {
        self.button_count = 0;

        if (self.current_menu) |menu| {
            if (menu.root_window) |root| {
                self.extractButtonsFromWindow(root);
            }
        }
    }

    fn extractButtonsFromWindow(self: *MenuRenderer, window: *WindowDef) void {
        // Check if this is a button
        if (window.window_type == .push_button and self.button_count < 32) {
            self.buttons[self.button_count] = MenuButton.init(window);
            self.button_count += 1;
        }

        // Recurse into children
        for (0..window.child_count) |i| {
            if (window.children[i]) |child| {
                self.extractButtonsFromWindow(child);
            }
        }
    }

    /// Update mouse state
    pub fn updateMouse(self: *MenuRenderer, x: f32, y: f32, down: bool) void {
        self.mouse_x = x;
        self.mouse_y = y;
        self.mouse_down = down;

        // Update button states
        for (0..self.button_count) |i| {
            if (self.buttons[i].containsPoint(x / self.scale_x, y / self.scale_y)) {
                if (down) {
                    self.buttons[i].state = .pressed;
                } else {
                    self.buttons[i].state = .hovered;
                }
            } else {
                self.buttons[i].state = .normal;
            }
        }
    }

    /// Handle click and return action
    pub fn handleClick(self: *MenuRenderer, x: f32, y: f32) MenuAction {
        for (0..self.button_count) |i| {
            if (self.buttons[i].containsPoint(x / self.scale_x, y / self.scale_y)) {
                return self.getActionForCallback(self.buttons[i].callback_id);
            }
        }
        return .none;
    }

    fn getActionForCallback(self: *MenuRenderer, callback: []const u8) MenuAction {
        _ = self;

        // Map callback names to actions (based on Thyme's callback system)
        if (std.mem.indexOf(u8, callback, "SinglePlayer") != null) return .single_player;
        if (std.mem.indexOf(u8, callback, "Skirmish") != null) return .skirmish;
        if (std.mem.indexOf(u8, callback, "Multiplayer") != null) return .multiplayer;
        if (std.mem.indexOf(u8, callback, "Replay") != null) return .replay;
        if (std.mem.indexOf(u8, callback, "LoadGame") != null) return .load_game;
        if (std.mem.indexOf(u8, callback, "Options") != null) return .options;
        if (std.mem.indexOf(u8, callback, "Exit") != null) return .exit;
        if (std.mem.indexOf(u8, callback, "Back") != null) return .back;
        if (std.mem.indexOf(u8, callback, "Start") != null) return .start_game;

        return .none;
    }

    /// Get rendering data for a window
    pub fn getWindowRenderData(self: *const MenuRenderer, window: *const WindowDef) struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        color: [4]f32,
    } {
        const rect = window.screen_rect;

        // Scale to current resolution
        const x = @as(f32, @floatFromInt(rect.x)) * self.scale_x;
        const y = @as(f32, @floatFromInt(rect.y)) * self.scale_y;
        const width = @as(f32, @floatFromInt(rect.width)) * self.scale_x;
        const height = @as(f32, @floatFromInt(rect.height)) * self.scale_y;

        // Get color based on state
        const color = window.enabled_draw[0].color;

        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .color = .{
                @as(f32, @floatFromInt(color.r)) / 255.0,
                @as(f32, @floatFromInt(color.g)) / 255.0,
                @as(f32, @floatFromInt(color.b)) / 255.0,
                @as(f32, @floatFromInt(color.a)) / 255.0,
            },
        };
    }
};

/// Create a simple fallback main menu (when WND files aren't available)
pub const FallbackMainMenu = struct {
    buttons: [6]FallbackButton,

    pub const FallbackButton = struct {
        label: []const u8,
        action: MenuAction,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        hovered: bool,
    };

    pub fn init(screen_width: f32, screen_height: f32) FallbackMainMenu {
        const button_width: f32 = 200.0;
        const button_height: f32 = 40.0;
        const center_x = (screen_width - button_width) / 2.0;
        const start_y = screen_height / 2.0 - 100.0;
        const spacing: f32 = 50.0;

        return FallbackMainMenu{
            .buttons = [_]FallbackButton{
                .{ .label = "SINGLE PLAYER", .action = .single_player, .x = center_x, .y = start_y, .width = button_width, .height = button_height, .hovered = false },
                .{ .label = "SKIRMISH", .action = .skirmish, .x = center_x, .y = start_y + spacing, .width = button_width, .height = button_height, .hovered = false },
                .{ .label = "MULTIPLAYER", .action = .multiplayer, .x = center_x, .y = start_y + spacing * 2, .width = button_width, .height = button_height, .hovered = false },
                .{ .label = "REPLAY", .action = .replay, .x = center_x, .y = start_y + spacing * 3, .width = button_width, .height = button_height, .hovered = false },
                .{ .label = "OPTIONS", .action = .options, .x = center_x, .y = start_y + spacing * 4, .width = button_width, .height = button_height, .hovered = false },
                .{ .label = "EXIT", .action = .exit, .x = center_x, .y = start_y + spacing * 5, .width = button_width, .height = button_height, .hovered = false },
            },
        };
    }

    pub fn updateMouse(self: *FallbackMainMenu, x: f32, y: f32) void {
        for (&self.buttons) |*button| {
            button.hovered = x >= button.x and x < button.x + button.width and
                            y >= button.y and y < button.y + button.height;
        }
    }

    pub fn handleClick(self: *FallbackMainMenu, x: f32, y: f32) MenuAction {
        for (self.buttons) |button| {
            if (x >= button.x and x < button.x + button.width and
                y >= button.y and y < button.y + button.height) {
                return button.action;
            }
        }
        return .none;
    }
};
