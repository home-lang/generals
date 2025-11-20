// macOS Metal Renderer - Zig wrapper

const std = @import("std");

// C-compatible renderer struct (matches macos_renderer.m)
const MacOSRendererC = extern struct {
    metal_device: ?*anyopaque,
    metal_command_queue: ?*anyopaque,
    metal_layer: ?*anyopaque,
};

// Extern C functions from macos_renderer.m
extern fn macos_renderer_create(ns_window: *anyopaque) MacOSRendererC;
extern fn macos_renderer_render_frame(renderer: *MacOSRendererC, r: f32, g: f32, b: f32, a: f32) bool;
extern fn macos_renderer_destroy(renderer: *MacOSRendererC) void;

/// macOS Metal Renderer
pub const MacOSRenderer = struct {
    renderer: MacOSRendererC,

    pub fn init(ns_window: *anyopaque) !MacOSRenderer {
        const renderer = macos_renderer_create(ns_window);

        if (renderer.metal_device == null) {
            return error.MetalNotSupported;
        }

        return MacOSRenderer{
            .renderer = renderer,
        };
    }

    pub fn deinit(self: *MacOSRenderer) void {
        macos_renderer_destroy(&self.renderer);
    }

    /// Render a frame with solid color (RGBA 0.0-1.0)
    /// Returns false if rendering failed
    pub fn renderFrame(self: *MacOSRenderer, r: f32, g: f32, b: f32, a: f32) bool {
        return macos_renderer_render_frame(&self.renderer, r, g, b, a);
    }
};
