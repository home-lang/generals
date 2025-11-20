// Minimap System for Generals RTS
// Displays a small overview of the game world

const std = @import("std");
const math = @import("math");
const Vec2 = math.Vec2(f32);
const EntityManager = @import("entity.zig").EntityManager;
const Camera = @import("camera.zig").Camera;

/// Minimap configuration
pub const MinimapConfig = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    world_width: f32,
    world_height: f32,
    background_color: [4]f32,
    border_color: [4]f32,
    border_width: f32,

    pub fn init(x: f32, y: f32, size: f32, world_width: f32, world_height: f32) MinimapConfig {
        return .{
            .x = x,
            .y = y,
            .width = size,
            .height = size,
            .world_width = world_width,
            .world_height = world_height,
            .background_color = [4]f32{ 0.05, 0.05, 0.05, 0.9 }, // Very dark gray
            .border_color = [4]f32{ 0.3, 0.3, 0.3, 1.0 },       // Medium gray
            .border_width = 2.0,
        };
    }

    /// Convert world position to minimap position
    pub fn worldToMinimap(self: *const MinimapConfig, world_pos: Vec2) Vec2 {
        const normalized_x = (world_pos.x + self.world_width / 2.0) / self.world_width;
        const normalized_y = (world_pos.y + self.world_height / 2.0) / self.world_height;

        return Vec2.init(
            self.x + normalized_x * self.width,
            self.y + normalized_y * self.height,
        );
    }

    /// Convert minimap position to world position
    pub fn minimapToWorld(self: *const MinimapConfig, minimap_pos: Vec2) Vec2 {
        const normalized_x = (minimap_pos.x - self.x) / self.width;
        const normalized_y = (minimap_pos.y - self.y) / self.height;

        return Vec2.init(
            normalized_x * self.world_width - self.world_width / 2.0,
            normalized_y * self.world_height - self.world_height / 2.0,
        );
    }

    /// Check if screen position is within minimap bounds
    pub fn contains(self: *const MinimapConfig, screen_x: f32, screen_y: f32) bool {
        return screen_x >= self.x and screen_x <= self.x + self.width and
               screen_y >= self.y and screen_y <= self.y + self.height;
    }
};

/// Minimap icon types
pub const MinimapIconType = enum {
    unit_friendly,
    unit_enemy,
    unit_neutral,
    building_friendly,
    building_enemy,
    building_neutral,
    resource,
};

/// Minimap icon (represents an entity on the minimap)
pub const MinimapIcon = struct {
    position: Vec2,
    icon_type: MinimapIconType,
    size: f32,

    pub fn init(position: Vec2, icon_type: MinimapIconType) MinimapIcon {
        const size: f32 = switch (icon_type) {
            .building_friendly, .building_enemy, .building_neutral => 4.0,
            .unit_friendly, .unit_enemy, .unit_neutral => 2.0,
            .resource => 3.0,
        };

        return .{
            .position = position,
            .icon_type = icon_type,
            .size = size,
        };
    }

    pub fn getColor(self: *const MinimapIcon) [4]f32 {
        return switch (self.icon_type) {
            .unit_friendly => [4]f32{ 0.0, 0.8, 0.0, 1.0 },     // Green
            .unit_enemy => [4]f32{ 0.8, 0.0, 0.0, 1.0 },        // Red
            .unit_neutral => [4]f32{ 0.8, 0.8, 0.0, 1.0 },      // Yellow
            .building_friendly => [4]f32{ 0.0, 1.0, 0.0, 1.0 }, // Bright green
            .building_enemy => [4]f32{ 1.0, 0.0, 0.0, 1.0 },    // Bright red
            .building_neutral => [4]f32{ 1.0, 1.0, 0.0, 1.0 },  // Bright yellow
            .resource => [4]f32{ 0.0, 0.5, 1.0, 1.0 },          // Blue
        };
    }
};

/// Minimap manager
pub const Minimap = struct {
    config: MinimapConfig,
    visible: bool,
    camera_viewport_color: [4]f32,

    pub fn init(screen_width: f32, screen_height: f32, world_width: f32, world_height: f32) Minimap {
        _ = screen_height; // Unused for now, but kept for API compatibility
        const minimap_size: f32 = 200.0;
        const margin: f32 = 10.0;
        const x = screen_width - minimap_size - margin;
        const y = margin;

        return .{
            .config = MinimapConfig.init(x, y, minimap_size, world_width, world_height),
            .visible = true,
            .camera_viewport_color = [4]f32{ 1.0, 1.0, 1.0, 0.5 }, // White, semi-transparent
        };
    }

    pub fn update(self: *Minimap, screen_width: f32) void {
        const minimap_size: f32 = 200.0;
        const margin: f32 = 10.0;
        self.config.x = screen_width - minimap_size - margin;
    }

    pub fn toggle(self: *Minimap) void {
        self.visible = !self.visible;
    }

    /// Handle click on minimap (returns world position)
    pub fn handleClick(self: *const Minimap, screen_x: f32, screen_y: f32) ?Vec2 {
        if (!self.visible) return null;
        if (!self.config.contains(screen_x, screen_y)) return null;

        const minimap_pos = Vec2.init(screen_x, screen_y);
        return self.config.minimapToWorld(minimap_pos);
    }

    /// Get camera viewport rectangle on minimap
    pub fn getCameraViewport(self: *const Minimap, camera: *const Camera) MinimapViewport {
        const camera_center = camera.position;
        const half_view_width = (camera.viewport_width / camera.zoom) / 2.0;
        const half_view_height = (camera.viewport_height / camera.zoom) / 2.0;

        // Calculate world-space corners
        const top_left = Vec2.init(camera_center.x - half_view_width, camera_center.y - half_view_height);
        const bottom_right = Vec2.init(camera_center.x + half_view_width, camera_center.y + half_view_height);

        // Convert to minimap space
        const minimap_top_left = self.config.worldToMinimap(top_left);
        const minimap_bottom_right = self.config.worldToMinimap(bottom_right);

        return .{
            .x = minimap_top_left.x,
            .y = minimap_top_left.y,
            .width = minimap_bottom_right.x - minimap_top_left.x,
            .height = minimap_bottom_right.y - minimap_top_left.y,
        };
    }
};

/// Camera viewport rectangle on minimap
pub const MinimapViewport = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

// Tests
test "MinimapConfig: world to minimap conversion" {
    const config = MinimapConfig.init(100, 100, 200, 2000, 2000);

    // Center of world (0, 0) should map to center of minimap (200, 200)
    const center_world = Vec2.init(0, 0);
    const center_minimap = config.worldToMinimap(center_world);
    try std.testing.expectApproxEqRel(@as(f32, 200), center_minimap.x, 0.01);
    try std.testing.expectApproxEqRel(@as(f32, 200), center_minimap.y, 0.01);

    // World bounds (-1000, -1000) should map to minimap (100, 100)
    const top_left_world = Vec2.init(-1000, -1000);
    const top_left_minimap = config.worldToMinimap(top_left_world);
    try std.testing.expectApproxEqRel(@as(f32, 100), top_left_minimap.x, 0.01);
    try std.testing.expectApproxEqRel(@as(f32, 100), top_left_minimap.y, 0.01);
}

test "MinimapConfig: minimap to world conversion" {
    const config = MinimapConfig.init(100, 100, 200, 2000, 2000);

    // Center of minimap (200, 200) should map to center of world (0, 0)
    const center_minimap = Vec2.init(200, 200);
    const center_world = config.minimapToWorld(center_minimap);
    try std.testing.expectApproxEqRel(@as(f32, 0), center_world.x, 0.01);
    try std.testing.expectApproxEqRel(@as(f32, 0), center_world.y, 0.01);
}

test "MinimapConfig: contains point" {
    const config = MinimapConfig.init(100, 100, 200, 2000, 2000);

    try std.testing.expect(config.contains(200, 200));  // Center
    try std.testing.expect(config.contains(100, 100));  // Top-left
    try std.testing.expect(config.contains(300, 300));  // Bottom-right
    try std.testing.expect(!config.contains(50, 200));  // Left of minimap
    try std.testing.expect(!config.contains(350, 200)); // Right of minimap
}

test "Minimap: handle click" {
    var minimap = Minimap.init(1024, 768, 2000, 2000);

    // Click in center of minimap should return world (0, 0)
    const world_pos = minimap.handleClick(200, 200);
    try std.testing.expect(world_pos != null);
    try std.testing.expectApproxEqRel(@as(f32, 0), world_pos.?.x, 1.0);
    try std.testing.expectApproxEqRel(@as(f32, 0), world_pos.?.y, 1.0);

    // Click outside minimap should return null
    const outside = minimap.handleClick(50, 50);
    try std.testing.expect(outside == null);
}
