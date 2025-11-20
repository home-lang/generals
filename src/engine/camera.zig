// Camera System for 2D RTS View
// Handles world-to-screen coordinate transformation

const std = @import("std");
const math = @import("math");
const Vec2 = math.Vec2(f32);

/// 2D Camera for RTS game
pub const Camera = struct {
    /// Camera position in world space
    position: Vec2,

    /// Zoom level (1.0 = normal, 2.0 = 2x zoom in, 0.5 = 2x zoom out)
    zoom: f32,

    /// Viewport size (screen dimensions)
    viewport_width: f32,
    viewport_height: f32,

    /// Camera movement speed (units per second)
    pan_speed: f32,

    /// Zoom speed (zoom factor per second)
    zoom_speed: f32,

    /// Min/max zoom levels
    min_zoom: f32,
    max_zoom: f32,

    pub fn init(viewport_width: f32, viewport_height: f32) Camera {
        return Camera{
            .position = Vec2.init(0, 0),
            .zoom = 1.0,
            .viewport_width = viewport_width,
            .viewport_height = viewport_height,
            .pan_speed = 500.0, // pixels per second
            .zoom_speed = 2.0,   // zoom factor per second
            .min_zoom = 0.25,    // 4x zoom out
            .max_zoom = 4.0,     // 4x zoom in
        };
    }

    /// Convert world coordinates to screen coordinates
    pub fn worldToScreen(self: *const Camera, world_pos: Vec2) Vec2 {
        // Apply camera transformation
        const relative = world_pos.sub(self.position);
        const scaled = relative.scale(self.zoom);

        // Center on screen
        const screen_x = scaled.x + self.viewport_width / 2.0;
        const screen_y = scaled.y + self.viewport_height / 2.0;

        return Vec2.init(screen_x, screen_y);
    }

    /// Convert screen coordinates to world coordinates
    pub fn screenToWorld(self: *const Camera, screen_pos: Vec2) Vec2 {
        // Uncenter from screen
        const centered_x = screen_pos.x - self.viewport_width / 2.0;
        const centered_y = screen_pos.y - self.viewport_height / 2.0;

        // Unscale and add camera position
        const world_x = centered_x / self.zoom + self.position.x;
        const world_y = centered_y / self.zoom + self.position.y;

        return Vec2.init(world_x, world_y);
    }

    /// Pan camera (move in world space)
    pub fn pan(self: *Camera, delta_x: f32, delta_y: f32) void {
        self.position.x += delta_x;
        self.position.y += delta_y;
    }

    /// Pan with delta time (for smooth movement)
    pub fn panWithDelta(self: *Camera, dir_x: f32, dir_y: f32, dt: f32) void {
        const distance = self.pan_speed * dt / self.zoom; // Adjust speed based on zoom
        self.position.x += dir_x * distance;
        self.position.y += dir_y * distance;
    }

    /// Zoom in/out
    pub fn setZoom(self: *Camera, new_zoom: f32) void {
        self.zoom = std.math.clamp(new_zoom, self.min_zoom, self.max_zoom);
    }

    /// Zoom with delta (smooth zoom)
    pub fn zoomWithDelta(self: *Camera, zoom_delta: f32, dt: f32) void {
        const new_zoom = self.zoom * (1.0 + zoom_delta * self.zoom_speed * dt);
        self.setZoom(new_zoom);
    }

    /// Reset camera to default position and zoom
    pub fn reset(self: *Camera) void {
        self.position = Vec2.init(0, 0);
        self.zoom = 1.0;
    }

    /// Update viewport size (called when window is resized)
    pub fn setViewportSize(self: *Camera, width: f32, height: f32) void {
        self.viewport_width = width;
        self.viewport_height = height;
    }

    /// Check if a world position is visible on screen
    pub fn isVisible(self: *const Camera, world_pos: Vec2, margin: f32) bool {
        const screen_pos = self.worldToScreen(world_pos);

        return screen_pos.x >= -margin and
            screen_pos.x <= self.viewport_width + margin and
            screen_pos.y >= -margin and
            screen_pos.y <= self.viewport_height + margin;
    }

    /// Get visible world bounds
    pub fn getVisibleBounds(self: *const Camera) struct { min: Vec2, max: Vec2 } {
        const top_left = self.screenToWorld(Vec2.init(0, 0));
        const bottom_right = self.screenToWorld(Vec2.init(self.viewport_width, self.viewport_height));

        return .{
            .min = top_left,
            .max = bottom_right,
        };
    }
};

// Tests
test "Camera: world to screen conversion" {
    var camera = Camera.init(800, 600);

    // Center of world should map to center of screen
    const world_center = Vec2.init(0, 0);
    const screen_center = camera.worldToScreen(world_center);

    try std.testing.expectApproxEqAbs(@as(f32, 400), screen_center.x, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 300), screen_center.y, 0.01);
}

test "Camera: screen to world conversion" {
    var camera = Camera.init(800, 600);

    // Center of screen should map to center of world
    const screen_center = Vec2.init(400, 300);
    const world_center = camera.screenToWorld(screen_center);

    try std.testing.expectApproxEqAbs(@as(f32, 0), world_center.x, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 0), world_center.y, 0.01);
}

test "Camera: pan" {
    var camera = Camera.init(800, 600);

    camera.pan(100, 50);

    try std.testing.expectEqual(@as(f32, 100), camera.position.x);
    try std.testing.expectEqual(@as(f32, 50), camera.position.y);
}

test "Camera: zoom" {
    var camera = Camera.init(800, 600);

    camera.setZoom(2.0);
    try std.testing.expectEqual(@as(f32, 2.0), camera.zoom);

    // Test clamping
    camera.setZoom(10.0);
    try std.testing.expectEqual(@as(f32, 4.0), camera.zoom); // Clamped to max

    camera.setZoom(0.1);
    try std.testing.expectEqual(@as(f32, 0.25), camera.zoom); // Clamped to min
}
