// Window Test
// Tests macOS window creation and basic rendering

const std = @import("std");

// External C functions from Objective-C
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

const MacOSRenderer = extern struct {
    metal_device: ?*anyopaque,
    metal_command_queue: ?*anyopaque,
    metal_layer: ?*anyopaque,
};

extern fn macos_window_create(title: [*:0]const u8, width: u32, height: u32, resizable: bool) MacOSWindow;
extern fn macos_window_show(window: *MacOSWindow) void;
extern fn macos_window_poll_events(window: *MacOSWindow) bool;
extern fn macos_window_destroy(window: *MacOSWindow) void;
extern fn macos_window_get_native_handle(window: *MacOSWindow) ?*anyopaque;

extern fn macos_renderer_create(ns_window: ?*anyopaque) MacOSRenderer;
extern fn macos_renderer_render_frame(renderer: *MacOSRenderer, r: f32, g: f32, b: f32, a: f32) bool;
extern fn macos_renderer_destroy(renderer: *MacOSRenderer) void;

pub fn main() !void {
    const print = std.debug.print;

    print("================================================================================\n", .{});
    print("  C&C Generals Window Test\n", .{});
    print("================================================================================\n\n", .{});

    // Create window
    print("Creating window...\n", .{});
    var window = macos_window_create("C&C Generals - Window Test", 800, 600, true);

    if (window.ns_window == null) {
        print("ERROR: Failed to create window\n", .{});
        return;
    }
    print("Window created successfully\n", .{});

    // Show window
    macos_window_show(&window);
    print("Window shown\n", .{});

    // Create renderer
    print("Creating Metal renderer...\n", .{});
    var renderer = macos_renderer_create(window.ns_window);

    if (renderer.metal_device == null) {
        print("ERROR: Failed to create Metal renderer\n", .{});
        macos_window_destroy(&window);
        return;
    }
    print("Metal renderer created successfully\n", .{});

    print("\nRunning render loop (Cmd+Q to quit)...\n", .{});
    print("Window should display cycling colors.\n\n", .{});

    // Animation state
    var frame_count: u32 = 0;
    var hue: f32 = 0.0;

    // Main loop
    while (macos_window_poll_events(&window)) {
        // Cycle through hue for color animation
        hue += 0.01;
        if (hue > 1.0) hue = 0.0;

        // Convert HSV to RGB (simplified)
        const h = hue * 6.0;
        const c: f32 = 1.0;
        const x = c * (1.0 - @abs(@mod(h, 2.0) - 1.0));

        var r: f32 = 0;
        var g: f32 = 0;
        var b: f32 = 0;

        if (h < 1.0) {
            r = c;
            g = x;
        } else if (h < 2.0) {
            r = x;
            g = c;
        } else if (h < 3.0) {
            g = c;
            b = x;
        } else if (h < 4.0) {
            g = x;
            b = c;
        } else if (h < 5.0) {
            r = x;
            b = c;
        } else {
            r = c;
            b = x;
        }

        // Render frame with animated color
        if (!macos_renderer_render_frame(&renderer, r, g, b, 1.0)) {
            print("Warning: Failed to render frame\n", .{});
        }

        frame_count += 1;

        // Print progress every 60 frames
        if (frame_count % 60 == 0) {
            print("Rendered {d} frames\n", .{frame_count});
        }

        // Frame rate limiting (~60 FPS)
        std.posix.nanosleep(0, 16_666_667);
    }

    // Cleanup
    print("\nCleaning up...\n", .{});
    macos_renderer_destroy(&renderer);
    macos_window_destroy(&window);

    print("Window test completed. Total frames: {d}\n", .{frame_count});
}
