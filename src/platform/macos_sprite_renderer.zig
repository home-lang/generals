// macOS Sprite Renderer - Zig wrapper

const std = @import("std");

// C-compatible renderer struct
const SpriteRendererC = extern struct {
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

// Render context
const RenderContextC = extern struct {
    drawable: ?*anyopaque,
    command_buffer: ?*anyopaque,
    render_encoder: ?*anyopaque,
};

// Extern C functions
extern fn sprite_renderer_create(ns_window: *anyopaque) SpriteRendererC;
extern fn sprite_renderer_create_texture(renderer: *SpriteRendererC, width: u32, height: u32, data: [*]const u8) ?*anyopaque;
extern fn sprite_renderer_draw_sprite(renderer: *SpriteRendererC, texture: *anyopaque, x: f32, y: f32, width: f32, height: f32) bool;
extern fn sprite_renderer_begin_frame(renderer: *SpriteRendererC) RenderContextC;
extern fn sprite_renderer_draw_sprite_batched(renderer: *SpriteRendererC, ctx: *RenderContextC, texture: *anyopaque, x: f32, y: f32, width: f32, height: f32) void;
extern fn sprite_renderer_draw_rect(renderer: *SpriteRendererC, ctx: *RenderContextC, x: f32, y: f32, width: f32, height: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_draw_selection_circle(renderer: *SpriteRendererC, ctx: *RenderContextC, center_x: f32, center_y: f32, radius: f32, r: f32, g: f32, b: f32, a: f32) void;
extern fn sprite_renderer_end_frame(renderer: *SpriteRendererC, ctx: *RenderContextC) void;
extern fn sprite_renderer_destroy_texture(texture: *anyopaque) void;
extern fn sprite_renderer_destroy(renderer: *SpriteRendererC) void;

/// Sprite Renderer
pub const SpriteRenderer = struct {
    renderer: SpriteRendererC,

    pub fn init(ns_window: *anyopaque) !SpriteRenderer {
        const renderer = sprite_renderer_create(ns_window);

        if (renderer.metal_device == null) {
            return error.MetalNotSupported;
        }

        return SpriteRenderer{
            .renderer = renderer,
        };
    }

    pub fn deinit(self: *SpriteRenderer) void {
        sprite_renderer_destroy(&self.renderer);
    }

    /// Create a texture from BGRA data
    pub fn createTexture(self: *SpriteRenderer, width: u32, height: u32, data: []const u8) !Texture {
        const texture_ptr = sprite_renderer_create_texture(&self.renderer, width, height, data.ptr);

        if (texture_ptr == null) {
            return error.FailedToCreateTexture;
        }

        return Texture{
            .ptr = texture_ptr.?,
            .width = width,
            .height = height,
        };
    }

    /// Draw a sprite at position (x, y) with size (width, height)
    pub fn drawSprite(self: *SpriteRenderer, texture: *const Texture, x: f32, y: f32, width: f32, height: f32) bool {
        return sprite_renderer_draw_sprite(&self.renderer, texture.ptr, x, y, width, height);
    }

    /// Begin a new frame (returns render context)
    pub fn beginFrame(self: *SpriteRenderer) RenderContext {
        const ctx_c = sprite_renderer_begin_frame(&self.renderer);
        return RenderContext{ .ctx = ctx_c };
    }

    /// Draw a sprite (batched - within render pass)
    pub fn drawSpriteBatched(self: *SpriteRenderer, ctx: *RenderContext, texture: *const Texture, x: f32, y: f32, width: f32, height: f32) void {
        sprite_renderer_draw_sprite_batched(&self.renderer, &ctx.ctx, texture.ptr, x, y, width, height);
    }

    /// Draw filled rectangle (batched - within render pass)
    pub fn drawRect(self: *SpriteRenderer, ctx: *RenderContext, x: f32, y: f32, width: f32, height: f32, r: f32, g: f32, b: f32, a: f32) void {
        sprite_renderer_draw_rect(&self.renderer, &ctx.ctx, x, y, width, height, r, g, b, a);
    }

    /// Draw selection circle (batched - within render pass)
    pub fn drawSelectionCircle(self: *SpriteRenderer, ctx: *RenderContext, center_x: f32, center_y: f32, radius: f32, r: f32, g: f32, b: f32, a: f32) void {
        sprite_renderer_draw_selection_circle(&self.renderer, &ctx.ctx, center_x, center_y, radius, r, g, b, a);
    }

    /// End frame and present
    pub fn endFrame(self: *SpriteRenderer, ctx: *RenderContext) void {
        sprite_renderer_end_frame(&self.renderer, &ctx.ctx);
    }
};

/// Render context for batched rendering
pub const RenderContext = struct {
    ctx: RenderContextC,

    pub fn isValid(self: *const RenderContext) bool {
        return self.ctx.render_encoder != null;
    }
};

/// GPU Texture handle
pub const Texture = struct {
    ptr: *anyopaque,
    width: u32,
    height: u32,

    pub fn deinit(self: *Texture) void {
        sprite_renderer_destroy_texture(self.ptr);
    }
};
