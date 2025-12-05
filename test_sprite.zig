// Sprite Rendering Test
// Tests Metal sprite rendering for C&C Generals

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

extern fn macos_window_create(title: [*:0]const u8, width: u32, height: u32, resizable: bool) MacOSWindow;
extern fn macos_window_show(window: *MacOSWindow) void;
extern fn macos_window_poll_events(window: *MacOSWindow) bool;
extern fn macos_window_destroy(window: *MacOSWindow) void;
extern fn macos_window_get_mouse_position(window: *MacOSWindow, x: *f32, y: *f32) void;

extern fn sprite_renderer_create(ns_window: ?*anyopaque) SpriteRenderer;
extern fn sprite_renderer_create_texture(renderer: *SpriteRenderer, width: u32, height: u32, data: [*]const u8) ?*anyopaque;
extern fn sprite_renderer_begin_frame(renderer: *SpriteRenderer) RenderContext;
extern fn sprite_renderer_end_frame(renderer: *SpriteRenderer, ctx: *RenderContext) void;
extern fn sprite_renderer_draw_sprite_batched(renderer: *SpriteRenderer, ctx: *RenderContext, texture: ?*anyopaque, x: f32, y: f32, width: f32, height: f32) void;
extern fn sprite_renderer_draw_rect(renderer: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, width: f32, height: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_draw_selection_circle(renderer: *SpriteRenderer, ctx: *RenderContext, center_x: f32, center_y: f32, radius: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_destroy_texture(texture: ?*anyopaque) void;
extern fn sprite_renderer_destroy(renderer: *SpriteRenderer) void;

fn createTestTexture(renderer: *SpriteRenderer, size: u32) ?*anyopaque {
    // Allocate BGRA data
    _ = size * size * 4;
    var data: [64 * 64 * 4]u8 = undefined;

    // Create a checkerboard pattern (like C&C unit placeholder)
    for (0..size) |y| {
        for (0..size) |x| {
            const idx = (y * size + x) * 4;
            const is_check = ((x / 8) + (y / 8)) % 2 == 0;

            if (is_check) {
                // Green square (USA color)
                data[idx] = 0; // B
                data[idx + 1] = 180; // G
                data[idx + 2] = 60; // R
                data[idx + 3] = 255; // A
            } else {
                // Dark green
                data[idx] = 0; // B
                data[idx + 1] = 100; // G
                data[idx + 2] = 30; // R
                data[idx + 3] = 255; // A
            }
        }
    }

    return sprite_renderer_create_texture(renderer, size, size, &data);
}

const Unit = struct {
    x: f32,
    y: f32,
    target_x: f32,
    target_y: f32,
    speed: f32,
    size: f32,
    selected: bool,
    color_r: f32,
    color_g: f32,
    color_b: f32,
};

pub fn main() !void {
    const print = std.debug.print;

    print("================================================================================\n", .{});
    print("  C&C Generals Sprite Rendering Test\n", .{});
    print("================================================================================\n\n", .{});

    // Create window
    print("Creating window...\n", .{});
    var window = macos_window_create("C&C Generals - Sprite Test", 800, 600, true);

    if (window.ns_window == null) {
        print("ERROR: Failed to create window\n", .{});
        return;
    }

    macos_window_show(&window);
    print("Window created\n", .{});

    // Create sprite renderer
    print("Creating sprite renderer...\n", .{});
    var renderer = sprite_renderer_create(window.ns_window);

    if (renderer.metal_device == null) {
        print("ERROR: Failed to create renderer\n", .{});
        macos_window_destroy(&window);
        return;
    }
    print("Sprite renderer created\n", .{});

    // Create test texture
    print("Creating test texture...\n", .{});
    const texture = createTestTexture(&renderer, 64);
    if (texture == null) {
        print("ERROR: Failed to create texture\n", .{});
        sprite_renderer_destroy(&renderer);
        macos_window_destroy(&window);
        return;
    }
    print("Test texture created\n", .{});

    // Create units (like in C&C Generals)
    var units = [_]Unit{
        .{ .x = 100, .y = 100, .target_x = 100, .target_y = 100, .speed = 100, .size = 48, .selected = false, .color_r = 0.2, .color_g = 0.6, .color_b = 0.9 }, // USA
        .{ .x = 200, .y = 150, .target_x = 200, .target_y = 150, .speed = 80, .size = 56, .selected = false, .color_r = 0.9, .color_g = 0.2, .color_b = 0.2 }, // China
        .{ .x = 300, .y = 200, .target_x = 300, .target_y = 200, .speed = 120, .size = 40, .selected = false, .color_r = 0.7, .color_g = 0.5, .color_b = 0.2 }, // GLA
        .{ .x = 400, .y = 250, .target_x = 400, .target_y = 250, .speed = 90, .size = 52, .selected = true, .color_r = 0.2, .color_g = 0.6, .color_b = 0.9 }, // USA selected
    };

    print("\nStarting render loop (Cmd+Q to quit)...\n", .{});
    print("Click to select units, right-click to move\n\n", .{});

    var frame_count: u32 = 0;
    var last_instant = std.time.Instant.now() catch {
        print("ERROR: Timer not supported\n", .{});
        return;
    };

    while (macos_window_poll_events(&window)) {
        // Delta time
        const current_instant = std.time.Instant.now() catch last_instant;
        const dt_ns = current_instant.since(last_instant);
        const dt: f32 = @as(f32, @floatFromInt(dt_ns)) / 1_000_000_000.0;
        last_instant = current_instant;

        // Get mouse position
        var mouse_x: f32 = 0;
        var mouse_y: f32 = 0;
        macos_window_get_mouse_position(&window, &mouse_x, &mouse_y);

        // Handle left click - select units
        if (window.mouse_left_clicked) {
            for (&units) |*unit| {
                const dx = mouse_x - unit.x;
                const dy = mouse_y - unit.y;
                const dist_sq = dx * dx + dy * dy;
                const radius = unit.size / 2;
                unit.selected = dist_sq < radius * radius;
            }
        }

        // Handle right click - move selected units
        if (window.mouse_right_clicked) {
            for (&units) |*unit| {
                if (unit.selected) {
                    unit.target_x = mouse_x;
                    unit.target_y = mouse_y;
                }
            }
        }

        // Update unit positions
        for (&units) |*unit| {
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

        // Render
        var ctx = sprite_renderer_begin_frame(&renderer);
        if (ctx.render_encoder != null) {
            // Draw units
            for (units) |unit| {
                const half_size = unit.size / 2;

                // Draw unit body
                sprite_renderer_draw_rect(&renderer, &ctx, unit.x - half_size, unit.y - half_size, unit.size, unit.size, unit.color_r, unit.color_g, unit.color_b, 1.0);

                // Draw unit texture
                sprite_renderer_draw_sprite_batched(&renderer, &ctx, texture, unit.x - half_size + 4, unit.y - half_size + 4, unit.size - 8, unit.size - 8);

                // Draw selection circle if selected
                if (unit.selected) {
                    sprite_renderer_draw_selection_circle(&renderer, &ctx, unit.x, unit.y, unit.size * 0.6, 0.0, 1.0, 0.0, 1.0);
                }
            }

            // Draw UI overlay
            sprite_renderer_draw_rect(&renderer, &ctx, 10, 10, 200, 30, 0.1, 0.1, 0.1, 0.8);
            sprite_renderer_draw_rect(&renderer, &ctx, 10, 560, 200, 30, 0.1, 0.1, 0.1, 0.8);

            sprite_renderer_end_frame(&renderer, &ctx);
        }

        frame_count += 1;
        if (frame_count % 60 == 0) {
            print("Frame {d}, FPS: {d:.1}\n", .{ frame_count, 1.0 / dt });
        }

        // Frame rate limiting
        std.posix.nanosleep(0, 16_666_667);
    }

    // Cleanup
    print("\nCleaning up...\n", .{});
    sprite_renderer_destroy_texture(texture);
    sprite_renderer_destroy(&renderer);
    macos_window_destroy(&window);

    print("Sprite test completed. Total frames: {d}\n", .{frame_count});
}
