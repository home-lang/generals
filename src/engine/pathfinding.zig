// A* Pathfinding System for Generals RTS
// Simple grid-based pathfinding for unit movement

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);

/// Grid-based pathfinding node
const Node = struct {
    x: i32,
    y: i32,
    g_cost: f32, // Cost from start
    h_cost: f32, // Heuristic cost to end
    f_cost: f32, // Total cost (g + h)
    parent: ?*Node,

    fn init(x: i32, y: i32) Node {
        return .{
            .x = x,
            .y = y,
            .g_cost = 0,
            .h_cost = 0,
            .f_cost = 0,
            .parent = null,
        };
    }

    fn calculateFCost(self: *Node) void {
        self.f_cost = self.g_cost + self.h_cost;
    }
};

/// Simple pathfinding result - list of waypoints
pub const Path = struct {
    waypoints: std.ArrayList(Vec2),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Path {
        return .{
            .waypoints = std.ArrayList(Vec2).initCapacity(allocator, 0) catch unreachable,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Path) void {
        self.waypoints.deinit(self.allocator);
    }

    pub fn add(self: *Path, point: Vec2) !void {
        try self.waypoints.append(self.allocator, point);
    }

    pub fn isEmpty(self: *const Path) bool {
        return self.waypoints.items.len == 0;
    }

    pub fn getNext(self: *Path) ?Vec2 {
        if (self.waypoints.items.len > 0) {
            return self.waypoints.items[0];
        }
        return null;
    }

    pub fn removeFirst(self: *Path) void {
        if (self.waypoints.items.len > 0) {
            _ = self.waypoints.orderedRemove(0);
        }
    }
};

/// Simple pathfinding system
pub const Pathfinder = struct {
    allocator: Allocator,
    grid_size: f32, // Size of each grid cell in world units

    pub fn init(allocator: Allocator, grid_size: f32) Pathfinder {
        return .{
            .allocator = allocator,
            .grid_size = grid_size,
        };
    }

    /// Convert world position to grid coordinates
    fn worldToGrid(self: *const Pathfinder, pos: Vec2) struct { x: i32, y: i32 } {
        return .{
            .x = @as(i32, @intFromFloat(@floor(pos.x / self.grid_size))),
            .y = @as(i32, @intFromFloat(@floor(pos.y / self.grid_size))),
        };
    }

    /// Convert grid coordinates to world position (center of cell)
    fn gridToWorld(self: *const Pathfinder, x: i32, y: i32) Vec2 {
        return Vec2.init(
            @as(f32, @floatFromInt(x)) * self.grid_size + self.grid_size / 2,
            @as(f32, @floatFromInt(y)) * self.grid_size + self.grid_size / 2,
        );
    }

    /// Calculate heuristic distance (Manhattan distance)
    fn heuristic(from_x: i32, from_y: i32, to_x: i32, to_y: i32) f32 {
        const dx = @abs(to_x - from_x);
        const dy = @abs(to_y - from_y);
        return @as(f32, @floatFromInt(dx + dy));
    }

    /// Simple pathfinding - straight line with basic obstacle avoidance
    /// For now, we'll use a simplified version without full A*
    pub fn findPath(self: *Pathfinder, start: Vec2, end: Vec2) !Path {
        var path = Path.init(self.allocator);

        // For simple RTS movement, we'll create a straight-line path with intermediate waypoints
        // This is a simplified version - full A* would check for obstacles

        const start_grid = self.worldToGrid(start);
        const end_grid = self.worldToGrid(end);

        // Calculate direction
        const dx = end_grid.x - start_grid.x;
        const dy = end_grid.y - start_grid.y;
        const steps = @max(@abs(dx), @abs(dy));

        if (steps == 0) {
            // Already at destination
            try path.add(end);
            return path;
        }

        // Create waypoints along the path
        var i: i32 = 1;
        while (i <= steps) : (i += 1) {
            const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            const x = start_grid.x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(dx)) * t));
            const y = start_grid.y + @as(i32, @intFromFloat(@as(f32, @floatFromInt(dy)) * t));

            const waypoint = self.gridToWorld(x, y);
            try path.add(waypoint);
        }

        // Ensure we end exactly at the target
        try path.add(end);

        return path;
    }

    /// Simple collision check (placeholder - would check against obstacles)
    pub fn isWalkable(self: *const Pathfinder, pos: Vec2) bool {
        _ = self;
        _ = pos;
        // For now, everything is walkable
        // In a full implementation, we'd check:
        // - Terrain passability
        // - Other units
        // - Buildings
        // - Map boundaries
        return true;
    }
};

// Tests
test "Pathfinder: world to grid conversion" {
    const pathfinder = Pathfinder.init(std.testing.allocator, 64.0);

    const grid = pathfinder.worldToGrid(Vec2.init(100, 100));
    try std.testing.expectEqual(@as(i32, 1), grid.x);
    try std.testing.expectEqual(@as(i32, 1), grid.y);
}

test "Pathfinder: grid to world conversion" {
    const pathfinder = Pathfinder.init(std.testing.allocator, 64.0);

    const world = pathfinder.gridToWorld(1, 1);
    try std.testing.expectApproxEqAbs(@as(f32, 96.0), world.x, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 96.0), world.y, 0.01);
}

test "Pathfinder: find simple path" {
    var pathfinder = Pathfinder.init(std.testing.allocator, 64.0);

    const start = Vec2.init(0, 0);
    const end = Vec2.init(200, 200);

    var path = try pathfinder.findPath(start, end);
    defer path.deinit();

    try std.testing.expect(path.waypoints.items.len > 0);
}
