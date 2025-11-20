// Fog of War System for Generals RTS
// Tracks visibility and exploration state for each team

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Entity = @import("entity.zig").Entity;
const TeamId = @import("entity.zig").TeamId;

/// Visibility state for a grid cell
pub const VisibilityState = enum(u2) {
    unexplored = 0,  // Never seen (black)
    explored = 1,    // Seen before but not visible now (gray)
    visible = 2,     // Currently visible (normal rendering)
};

/// Fog of War grid cell
pub const FogCell = struct {
    visibility: VisibilityState,
    last_visible_frame: u64,

    pub fn init() FogCell {
        return .{
            .visibility = .unexplored,
            .last_visible_frame = 0,
        };
    }

    pub fn setVisible(self: *FogCell, frame: u64) void {
        self.visibility = .visible;
        self.last_visible_frame = frame;
    }

    pub fn setExplored(self: *FogCell) void {
        if (self.visibility == .unexplored) {
            self.visibility = .explored;
        }
    }

    pub fn clearVisibility(self: *FogCell) void {
        if (self.visibility == .visible) {
            self.visibility = .explored;
        }
    }
};

/// Fog of War manager for a single team
pub const TeamFogOfWar = struct {
    allocator: Allocator,
    grid: []FogCell,
    grid_width: usize,
    grid_height: usize,
    cell_size: f32,
    world_width: f32,
    world_height: f32,
    current_frame: u64,

    pub fn init(allocator: Allocator, world_width: f32, world_height: f32, cell_size: f32) !TeamFogOfWar {
        const grid_width = @as(usize, @intFromFloat(@ceil(world_width / cell_size)));
        const grid_height = @as(usize, @intFromFloat(@ceil(world_height / cell_size)));
        const grid_size = grid_width * grid_height;

        const grid = try allocator.alloc(FogCell, grid_size);
        @memset(grid, FogCell.init());

        return .{
            .allocator = allocator,
            .grid = grid,
            .grid_width = grid_width,
            .grid_height = grid_height,
            .cell_size = cell_size,
            .world_width = world_width,
            .world_height = world_height,
            .current_frame = 0,
        };
    }

    pub fn deinit(self: *TeamFogOfWar) void {
        self.allocator.free(self.grid);
    }

    /// Convert world position to grid coordinates
    fn worldToGrid(self: *const TeamFogOfWar, world_pos: Vec2) ?struct { x: usize, y: usize } {
        // Offset world position to grid space (0-based)
        const grid_x_f = (world_pos.x + self.world_width / 2.0) / self.cell_size;
        const grid_y_f = (world_pos.y + self.world_height / 2.0) / self.cell_size;

        if (grid_x_f < 0 or grid_y_f < 0) return null;

        const grid_x = @as(usize, @intFromFloat(@floor(grid_x_f)));
        const grid_y = @as(usize, @intFromFloat(@floor(grid_y_f)));

        if (grid_x >= self.grid_width or grid_y >= self.grid_height) return null;

        return .{ .x = grid_x, .y = grid_y };
    }

    /// Get grid cell at grid coordinates
    fn getCell(self: *TeamFogOfWar, grid_x: usize, grid_y: usize) *FogCell {
        const index = grid_y * self.grid_width + grid_x;
        return &self.grid[index];
    }

    /// Reveal circular area around a position
    pub fn revealArea(self: *TeamFogOfWar, center: Vec2, radius: f32) void {
        const radius_sq = radius * radius;

        // Calculate grid bounds to check
        const min_x_f = (center.x - radius + self.world_width / 2.0) / self.cell_size;
        const max_x_f = (center.x + radius + self.world_width / 2.0) / self.cell_size;
        const min_y_f = (center.y - radius + self.world_height / 2.0) / self.cell_size;
        const max_y_f = (center.y + radius + self.world_height / 2.0) / self.cell_size;

        const min_x = @max(0, @as(isize, @intFromFloat(@floor(min_x_f))));
        const max_x = @min(@as(isize, @intCast(self.grid_width - 1)), @as(isize, @intFromFloat(@ceil(max_x_f))));
        const min_y = @max(0, @as(isize, @intFromFloat(@floor(min_y_f))));
        const max_y = @min(@as(isize, @intCast(self.grid_height - 1)), @as(isize, @intFromFloat(@ceil(max_y_f))));

        var y = min_y;
        while (y <= max_y) : (y += 1) {
            var x = min_x;
            while (x <= max_x) : (x += 1) {
                // Calculate cell center in world space
                const cell_world_x = @as(f32, @floatFromInt(x)) * self.cell_size - self.world_width / 2.0 + self.cell_size / 2.0;
                const cell_world_y = @as(f32, @floatFromInt(y)) * self.cell_size - self.world_height / 2.0 + self.cell_size / 2.0;

                // Check if cell is within vision radius
                const dx = cell_world_x - center.x;
                const dy = cell_world_y - center.y;
                const dist_sq = dx * dx + dy * dy;

                if (dist_sq <= radius_sq) {
                    const cell = self.getCell(@as(usize, @intCast(x)), @as(usize, @intCast(y)));
                    cell.setVisible(self.current_frame);
                }
            }
        }
    }

    /// Clear all visibility (but keep explored state)
    pub fn clearVisibility(self: *TeamFogOfWar) void {
        for (self.grid) |*cell| {
            cell.clearVisibility();
        }
    }

    /// Update fog of war for a new frame
    pub fn update(self: *TeamFogOfWar, entities: []const Entity, team: TeamId) void {
        self.current_frame += 1;
        self.clearVisibility();

        // Reveal areas around friendly units and buildings
        for (entities) |entity| {
            if (!entity.active) continue;
            if (entity.team != team) continue;

            // Calculate vision radius
            var vision_radius: f32 = 0;
            if (entity.unit_data != null) {
                vision_radius = 200.0; // Units have 200 unit vision
            } else if (entity.building_data != null) {
                vision_radius = 300.0; // Buildings have 300 unit vision
            }

            if (vision_radius > 0) {
                self.revealArea(entity.transform.position, vision_radius);
            }
        }
    }

    /// Check visibility of a world position
    pub fn isVisible(self: *const TeamFogOfWar, world_pos: Vec2) bool {
        const coords = self.worldToGrid(world_pos) orelse return false;
        const cell = &self.grid[coords.y * self.grid_width + coords.x];
        return cell.visibility == .visible;
    }

    /// Check if position has been explored
    pub fn isExplored(self: *const TeamFogOfWar, world_pos: Vec2) bool {
        const coords = self.worldToGrid(world_pos) orelse return false;
        const cell = &self.grid[coords.y * self.grid_width + coords.x];
        return cell.visibility != .unexplored;
    }

    /// Get visibility state at world position
    pub fn getVisibilityState(self: *const TeamFogOfWar, world_pos: Vec2) VisibilityState {
        const coords = self.worldToGrid(world_pos) orelse return .unexplored;
        const cell = &self.grid[coords.y * self.grid_width + coords.x];
        return cell.visibility;
    }
};

/// Fog of War manager for all teams
pub const FogOfWarManager = struct {
    allocator: Allocator,
    team_fog: []TeamFogOfWar,
    enabled: bool,

    pub fn init(allocator: Allocator, num_teams: usize, world_width: f32, world_height: f32, cell_size: f32) !FogOfWarManager {
        const team_fog = try allocator.alloc(TeamFogOfWar, num_teams);

        for (0..num_teams) |i| {
            team_fog[i] = try TeamFogOfWar.init(allocator, world_width, world_height, cell_size);
        }

        return .{
            .allocator = allocator,
            .team_fog = team_fog,
            .enabled = true,
        };
    }

    pub fn deinit(self: *FogOfWarManager) void {
        for (self.team_fog) |*fog| {
            fog.deinit();
        }
        self.allocator.free(self.team_fog);
    }

    pub fn update(self: *FogOfWarManager, entities: []const Entity) void {
        if (!self.enabled) return;

        for (0..self.team_fog.len) |team_id| {
            self.team_fog[team_id].update(entities, @as(TeamId, @intCast(team_id)));
        }
    }

    pub fn isVisible(self: *const FogOfWarManager, team: TeamId, world_pos: Vec2) bool {
        if (!self.enabled) return true;
        if (team >= self.team_fog.len) return false;
        return self.team_fog[team].isVisible(world_pos);
    }

    pub fn getVisibilityState(self: *const FogOfWarManager, team: TeamId, world_pos: Vec2) VisibilityState {
        if (!self.enabled) return .visible;
        if (team >= self.team_fog.len) return .unexplored;
        return self.team_fog[team].getVisibilityState(world_pos);
    }

    pub fn toggle(self: *FogOfWarManager) void {
        self.enabled = !self.enabled;
    }
};

// Tests
test "FogCell: initialization" {
    const cell = FogCell.init();
    try std.testing.expectEqual(VisibilityState.unexplored, cell.visibility);
    try std.testing.expectEqual(@as(u64, 0), cell.last_visible_frame);
}

test "FogCell: visibility transitions" {
    var cell = FogCell.init();

    // Initially unexplored
    try std.testing.expectEqual(VisibilityState.unexplored, cell.visibility);

    // Set visible
    cell.setVisible(1);
    try std.testing.expectEqual(VisibilityState.visible, cell.visibility);
    try std.testing.expectEqual(@as(u64, 1), cell.last_visible_frame);

    // Clear visibility (visible -> explored)
    cell.clearVisibility();
    try std.testing.expectEqual(VisibilityState.explored, cell.visibility);

    // Clear again (should stay explored)
    cell.clearVisibility();
    try std.testing.expectEqual(VisibilityState.explored, cell.visibility);
}

test "TeamFogOfWar: initialization" {
    const allocator = std.testing.allocator;
    var fog = try TeamFogOfWar.init(allocator, 1000.0, 1000.0, 50.0);
    defer fog.deinit();

    try std.testing.expectEqual(@as(usize, 20), fog.grid_width); // 1000 / 50
    try std.testing.expectEqual(@as(usize, 20), fog.grid_height);
    try std.testing.expectEqual(@as(usize, 400), fog.grid.len); // 20 * 20
}

test "TeamFogOfWar: world to grid conversion" {
    const allocator = std.testing.allocator;
    var fog = try TeamFogOfWar.init(allocator, 1000.0, 1000.0, 50.0);
    defer fog.deinit();

    // Center of world (0, 0) should map to grid (10, 10)
    const center = fog.worldToGrid(Vec2.init(0, 0)).?;
    try std.testing.expectEqual(@as(usize, 10), center.x);
    try std.testing.expectEqual(@as(usize, 10), center.y);

    // Top-left corner (-500, -500) should map to grid (0, 0)
    const top_left = fog.worldToGrid(Vec2.init(-500, -500)).?;
    try std.testing.expectEqual(@as(usize, 0), top_left.x);
    try std.testing.expectEqual(@as(usize, 0), top_left.y);
}

test "TeamFogOfWar: reveal area" {
    const allocator = std.testing.allocator;
    var fog = try TeamFogOfWar.init(allocator, 1000.0, 1000.0, 50.0);
    defer fog.deinit();

    // Reveal area at center with radius 100
    fog.revealArea(Vec2.init(0, 0), 100.0);

    // Center should be visible
    try std.testing.expect(fog.isVisible(Vec2.init(0, 0)));

    // Point within radius should be visible
    try std.testing.expect(fog.isVisible(Vec2.init(50, 50)));

    // Point far away should not be visible
    try std.testing.expect(!fog.isVisible(Vec2.init(300, 300)));
}
