// macOS Window - Zig wrapper for Objective-C implementation

const std = @import("std");

// C-compatible window struct (matches macos_window.m)
const MacOSWindowC = extern struct {
    ns_app: ?*anyopaque,
    ns_window: ?*anyopaque,
    should_close: bool,
    // Keyboard state
    key_up: bool,
    key_down: bool,
    key_left: bool,
    key_right: bool,
    key_w: bool,
    key_a: bool,
    key_s: bool,
    key_d: bool,
    // Mouse button state
    mouse_left_down: bool,
    mouse_right_down: bool,
    mouse_left_clicked: bool,
    mouse_right_clicked: bool,
};

// Extern C functions from macos_window.m
extern fn macos_window_create(title: [*:0]const u8, width: u32, height: u32, resizable: bool) MacOSWindowC;
extern fn macos_window_show(window: *MacOSWindowC) void;
extern fn macos_window_hide(window: *MacOSWindowC) void;
extern fn macos_window_poll_events(window: *MacOSWindowC) bool;
extern fn macos_window_get_native_handle(window: *MacOSWindowC) *anyopaque;
extern fn macos_window_get_mouse_position(window: *MacOSWindowC, x: *f32, y: *f32) void;
extern fn macos_window_get_keyboard_state(window: *MacOSWindowC, up: *bool, down: *bool, left: *bool, right: *bool, w: *bool, a: *bool, s: *bool, d: *bool) void;
extern fn macos_window_get_mouse_button_state(window: *MacOSWindowC, left_down: *bool, right_down: *bool, left_clicked: *bool, right_clicked: *bool) void;
extern fn macos_window_destroy(window: *MacOSWindowC) void;

/// macOS Window
pub const MacOSWindow = struct {
    window: MacOSWindowC,

    pub fn init(title: [:0]const u8, width: u32, height: u32, resizable: bool) !MacOSWindow {
        const window = macos_window_create(title.ptr, width, height, resizable);

        return MacOSWindow{
            .window = window,
        };
    }

    pub fn deinit(self: *MacOSWindow) void {
        macos_window_destroy(&self.window);
    }

    pub fn show(self: *MacOSWindow) void {
        macos_window_show(&self.window);
    }

    pub fn hide(self: *MacOSWindow) void {
        macos_window_hide(&self.window);
    }

    pub fn pollEvents(self: *MacOSWindow) bool {
        return macos_window_poll_events(&self.window);
    }

    pub fn getNativeHandle(self: *MacOSWindow) *anyopaque {
        return macos_window_get_native_handle(&self.window);
    }

    pub fn getMousePosition(self: *MacOSWindow) struct { x: f32, y: f32 } {
        var x: f32 = 0;
        var y: f32 = 0;
        macos_window_get_mouse_position(&self.window, &x, &y);
        return .{ .x = x, .y = y };
    }

    pub const KeyboardState = struct {
        up: bool,
        down: bool,
        left: bool,
        right: bool,
        w: bool,
        a: bool,
        s: bool,
        d: bool,
    };

    pub fn getKeyboardState(self: *MacOSWindow) KeyboardState {
        var state: KeyboardState = undefined;
        macos_window_get_keyboard_state(&self.window, &state.up, &state.down, &state.left, &state.right, &state.w, &state.a, &state.s, &state.d);
        return state;
    }

    pub const MouseButtonState = struct {
        left_down: bool,
        right_down: bool,
        left_clicked: bool,
        right_clicked: bool,
    };

    pub fn getMouseButtonState(self: *MacOSWindow) MouseButtonState {
        var state: MouseButtonState = undefined;
        macos_window_get_mouse_button_state(&self.window, &state.left_down, &state.right_down, &state.left_clicked, &state.right_clicked);
        return state;
    }
};
