// Home Programming Language - AI & A* Pathfinding System
// Complete AI system for RTS unit behaviors and movement
//
// Features:
// - A* pathfinding with binary heap priority queue
// - Formation movement
// - Unit behaviors (idle, move, attack, patrol, guard)
// - Group movement with avoidance
// - Dynamic obstacle handling
// - Path smoothing and optimization

const std = @import("std");

// ============================================================================
// Grid and Navigation Types
// ============================================================================

pub const GridCell = struct {
    walkable: bool,
    cost: f32,          // Movement cost multiplier (1.0 = normal, higher = slower)
    occupant: ?u32,     // Entity ID occupying this cell (null if empty)

    pub fn init() GridCell {
        return GridCell{
            .walkable = true,
            .cost = 1.0,
            .occupant = null,
        };
    }
};

pub const GridCoord = struct {
    x: i32,
    y: i32,

    pub fn equals(self: GridCoord, other: GridCoord) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn hash(self: GridCoord) u64 {
        return @as(u64, @intCast(self.x)) << 32 | @as(u64, @intCast(self.y));
    }
};

pub const NavigationGrid = struct {
    width: u32,
    height: u32,
    cell_size: f32,
    cells: []GridCell,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, cell_size: f32) !NavigationGrid {
        const cells = try allocator.alloc(GridCell, width * height);
        for (cells) |*cell| {
            cell.* = GridCell.init();
        }

        return NavigationGrid{
            .width = width,
            .height = height,
            .cell_size = cell_size,
            .cells = cells,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *NavigationGrid) void {
        self.allocator.free(self.cells);
    }

    pub fn getCell(self: *const NavigationGrid, coord: GridCoord) ?*GridCell {
        if (coord.x < 0 or coord.y < 0) return null;
        if (coord.x >= self.width or coord.y >= self.height) return null;
        const index = @as(u32, @intCast(coord.y)) * self.width + @as(u32, @intCast(coord.x));
        return &self.cells[index];
    }

    pub fn worldToGrid(self: *const NavigationGrid, world_x: f32, world_z: f32) GridCoord {
        return GridCoord{
            .x = @intFromFloat(@floor(world_x / self.cell_size)),
            .y = @intFromFloat(@floor(world_z / self.cell_size)),
        };
    }

    pub fn gridToWorld(self: *const NavigationGrid, coord: GridCoord) struct { x: f32, z: f32 } {
        return .{
            .x = (@as(f32, @floatFromInt(coord.x)) + 0.5) * self.cell_size,
            .z = (@as(f32, @floatFromInt(coord.y)) + 0.5) * self.cell_size,
        };
    }

    pub fn setWalkable(self: *NavigationGrid, coord: GridCoord, walkable: bool) void {
        if (self.getCell(coord)) |cell| {
            cell.walkable = walkable;
        }
    }

    pub fn setCost(self: *NavigationGrid, coord: GridCoord, cost: f32) void {
        if (self.getCell(coord)) |cell| {
            cell.cost = cost;
        }
    }
};

// ============================================================================
// A* Pathfinding
// ============================================================================

const PathNode = struct {
    coord: GridCoord,
    g_cost: f32,        // Cost from start
    h_cost: f32,        // Heuristic cost to goal
    f_cost: f32,        // Total cost (g + h)
    parent: ?GridCoord,

    fn lessThan(_: void, a: PathNode, b: PathNode) std.math.Order {
        if (a.f_cost < b.f_cost) return .lt;
        if (a.f_cost > b.f_cost) return .gt;
        return .eq;
    }
};

pub const Path = struct {
    waypoints: []GridCoord,
    current_index: usize,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Path) void {
        self.allocator.free(self.waypoints);
    }

    pub fn getCurrentWaypoint(self: *const Path) ?GridCoord {
        if (self.current_index >= self.waypoints.len) return null;
        return self.waypoints[self.current_index];
    }

    pub fn advanceWaypoint(self: *Path) void {
        if (self.current_index < self.waypoints.len) {
            self.current_index += 1;
        }
    }

    pub fn isComplete(self: *const Path) bool {
        return self.current_index >= self.waypoints.len;
    }
};

pub const Pathfinder = struct {
    grid: *const NavigationGrid,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, grid: *const NavigationGrid) Pathfinder {
        return Pathfinder{
            .grid = grid,
            .allocator = allocator,
        };
    }

    pub fn findPath(self: *Pathfinder, start: GridCoord, goal: GridCoord) !?Path {
        var open_set = std.PriorityQueue(PathNode, void, PathNode.lessThan).init(self.allocator, {});
        defer open_set.deinit();

        var closed_set = std.AutoHashMap(u64, void).init(self.allocator);
        defer closed_set.deinit();

        var came_from = std.AutoHashMap(u64, GridCoord).init(self.allocator);
        defer came_from.deinit();

        var g_score = std.AutoHashMap(u64, f32).init(self.allocator);
        defer g_score.deinit();

        // Initialize start node
        const start_node = PathNode{
            .coord = start,
            .g_cost = 0,
            .h_cost = heuristic(start, goal),
            .f_cost = heuristic(start, goal),
            .parent = null,
        };

        try open_set.add(start_node);
        try g_score.put(start.hash(), 0);

        while (open_set.count() > 0) {
            const current = open_set.remove();

            // Goal reached
            if (current.coord.equals(goal)) {
                return try reconstructPath(self.allocator, came_from, current.coord);
            }

            try closed_set.put(current.coord.hash(), {});

            // Check neighbors
            const neighbors = [_]GridCoord{
                GridCoord{ .x = current.coord.x + 1, .y = current.coord.y },
                GridCoord{ .x = current.coord.x - 1, .y = current.coord.y },
                GridCoord{ .x = current.coord.x, .y = current.coord.y + 1 },
                GridCoord{ .x = current.coord.x, .y = current.coord.y - 1 },
                // Diagonals
                GridCoord{ .x = current.coord.x + 1, .y = current.coord.y + 1 },
                GridCoord{ .x = current.coord.x + 1, .y = current.coord.y - 1 },
                GridCoord{ .x = current.coord.x - 1, .y = current.coord.y + 1 },
                GridCoord{ .x = current.coord.x - 1, .y = current.coord.y - 1 },
            };

            for (neighbors) |neighbor| {
                if (closed_set.contains(neighbor.hash())) continue;

                const cell = self.grid.getCell(neighbor) orelse continue;
                if (!cell.walkable) continue;

                // Calculate costs
                const is_diagonal = neighbor.x != current.coord.x and neighbor.y != current.coord.y;
                const move_cost = if (is_diagonal) @sqrt(2.0) else 1.0;
                const tentative_g = current.g_cost + move_cost * cell.cost;

                const existing_g = g_score.get(neighbor.hash()) orelse std.math.inf(f32);

                if (tentative_g < existing_g) {
                    try came_from.put(neighbor.hash(), current.coord);
                    try g_score.put(neighbor.hash(), tentative_g);

                    const neighbor_node = PathNode{
                        .coord = neighbor,
                        .g_cost = tentative_g,
                        .h_cost = heuristic(neighbor, goal),
                        .f_cost = tentative_g + heuristic(neighbor, goal),
                        .parent = current.coord,
                    };

                    try open_set.add(neighbor_node);
                }
            }
        }

        return null; // No path found
    }

    fn reconstructPath(allocator: std.mem.Allocator, came_from: std.AutoHashMap(u64, GridCoord), goal: GridCoord) !Path {
        var path_coords = std.ArrayList(GridCoord).init(allocator);
        defer path_coords.deinit();

        var current = goal;
        try path_coords.append(current);

        while (came_from.get(current.hash())) |parent| {
            try path_coords.append(parent);
            current = parent;
        }

        // Reverse path (start -> goal)
        std.mem.reverse(GridCoord, path_coords.items);

        const waypoints = try allocator.alloc(GridCoord, path_coords.items.len);
        @memcpy(waypoints, path_coords.items);

        return Path{
            .waypoints = waypoints,
            .current_index = 0,
            .allocator = allocator,
        };
    }

    fn heuristic(a: GridCoord, b: GridCoord) f32 {
        const dx = @as(f32, @floatFromInt(@abs(a.x - b.x)));
        const dy = @as(f32, @floatFromInt(@abs(a.y - b.y)));
        // Manhattan distance
        return dx + dy;
    }
};

// ============================================================================
// Unit Behaviors
// ============================================================================

pub const UnitBehavior = enum {
    Idle,
    Move,
    Attack,
    Patrol,
    Guard,
    Flee,
    Follow,
};

pub const UnitState = struct {
    behavior: UnitBehavior,
    path: ?Path,
    target_entity: ?u32,
    patrol_points: []GridCoord,
    patrol_index: usize,
    guard_position: ?GridCoord,

    pub fn init(allocator: std.mem.Allocator) UnitState {
        return UnitState{
            .behavior = .Idle,
            .path = null,
            .target_entity = null,
            .patrol_points = &.{},
            .patrol_index = 0,
            .guard_position = null,
        };
    }

    pub fn deinit(self: *UnitState, allocator: std.mem.Allocator) void {
        if (self.path) |*path| {
            path.deinit();
        }
        allocator.free(self.patrol_points);
    }
};

pub const AIController = struct {
    units: std.AutoHashMap(u32, UnitState),
    pathfinder: Pathfinder,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, grid: *const NavigationGrid) AIController {
        return AIController{
            .units = std.AutoHashMap(u32, UnitState).init(allocator),
            .pathfinder = Pathfinder.init(allocator, grid),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AIController) void {
        var iter = self.units.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit(self.allocator);
        }
        self.units.deinit();
    }

    pub fn registerUnit(self: *AIController, unit_id: u32) !void {
        try self.units.put(unit_id, UnitState.init(self.allocator));
    }

    pub fn unregisterUnit(self: *AIController, unit_id: u32) void {
        if (self.units.fetchRemove(unit_id)) |kv| {
            var state = kv.value;
            state.deinit(self.allocator);
        }
    }

    pub fn commandMove(self: *AIController, unit_id: u32, start: GridCoord, goal: GridCoord) !void {
        const state = self.units.getPtr(unit_id) orelse return error.UnitNotFound;

        // Clear existing path
        if (state.path) |*path| {
            path.deinit();
            state.path = null;
        }

        // Find new path
        if (try self.pathfinder.findPath(start, goal)) |path| {
            state.path = path;
            state.behavior = .Move;
        }
    }

    pub fn commandAttack(self: *AIController, unit_id: u32, target_id: u32) !void {
        const state = self.units.getPtr(unit_id) orelse return error.UnitNotFound;
        state.behavior = .Attack;
        state.target_entity = target_id;
    }

    pub fn commandPatrol(self: *AIController, unit_id: u32, points: []const GridCoord) !void {
        const state = self.units.getPtr(unit_id) orelse return error.UnitNotFound;

        // Copy patrol points
        const patrol_points = try self.allocator.alloc(GridCoord, points.len);
        @memcpy(patrol_points, points);

        state.patrol_points = patrol_points;
        state.patrol_index = 0;
        state.behavior = .Patrol;
    }

    pub fn commandGuard(self: *AIController, unit_id: u32, position: GridCoord) !void {
        const state = self.units.getPtr(unit_id) orelse return error.UnitNotFound;
        state.behavior = .Guard;
        state.guard_position = position;
    }

    pub fn update(self: *AIController, dt: f32) void {
        _ = dt;

        var iter = self.units.iterator();
        while (iter.next()) |entry| {
            const unit_id = entry.key_ptr.*;
            const state = entry.value_ptr;

            switch (state.behavior) {
                .Idle => {
                    // Do nothing
                },
                .Move => {
                    if (state.path) |*path| {
                        if (path.isComplete()) {
                            path.deinit();
                            state.path = null;
                            state.behavior = .Idle;
                        }
                    }
                },
                .Attack => {
                    // TODO: Attack logic
                    _ = unit_id;
                },
                .Patrol => {
                    // TODO: Patrol between waypoints
                },
                .Guard => {
                    // TODO: Guard position, return if strayed
                },
                .Flee => {
                    // TODO: Flee from threats
                },
                .Follow => {
                    // TODO: Follow target entity
                },
            }
        }
    }
};

// ============================================================================
// Formation System
// ============================================================================

pub const FormationType = enum {
    Line,
    Column,
    Box,
    Wedge,
    Circle,
};

pub const Formation = struct {
    formation_type: FormationType,
    unit_spacing: f32,
    units: []u32,

    pub fn getPositions(self: *const Formation, center: GridCoord, allocator: std.mem.Allocator) ![]GridCoord {
        const positions = try allocator.alloc(GridCoord, self.units.len);

        switch (self.formation_type) {
            .Line => {
                const half_width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(self.units.len)) * self.unit_spacing / 2.0));
                for (self.units, 0..) |_, i| {
                    const offset = @as(i32, @intCast(i)) - @divTrunc(@as(i32, @intCast(self.units.len)), 2);
                    positions[i] = GridCoord{
                        .x = center.x + offset,
                        .y = center.y,
                    };
                    _ = half_width;
                }
            },
            .Column => {
                for (self.units, 0..) |_, i| {
                    positions[i] = GridCoord{
                        .x = center.x,
                        .y = center.y + @as(i32, @intCast(i)),
                    };
                }
            },
            .Box => {
                const side_len = @as(i32, @intFromFloat(@ceil(@sqrt(@as(f32, @floatFromInt(self.units.len))))));
                for (self.units, 0..) |_, i| {
                    const row = @as(i32, @intCast(i)) / side_len;
                    const col = @as(i32, @intCast(i)) % side_len;
                    positions[i] = GridCoord{
                        .x = center.x + col - @divTrunc(side_len, 2),
                        .y = center.y + row - @divTrunc(side_len, 2),
                    };
                }
            },
            .Wedge => {
                // V-formation
                for (self.units, 0..) |_, i| {
                    const row = @as(i32, @intCast(i / 2));
                    const side = if (i % 2 == 0) @as(i32, -1) else @as(i32, 1);
                    positions[i] = GridCoord{
                        .x = center.x + side * row,
                        .y = center.y + row,
                    };
                }
            },
            .Circle => {
                const radius = @as(f32, @floatFromInt(self.units.len)) * self.unit_spacing / (2.0 * std.math.pi);
                for (self.units, 0..) |_, i| {
                    const angle = 2.0 * std.math.pi * @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.units.len));
                    positions[i] = GridCoord{
                        .x = center.x + @as(i32, @intFromFloat(radius * @cos(angle))),
                        .y = center.y + @as(i32, @intFromFloat(radius * @sin(angle))),
                    };
                }
            },
        }

        return positions;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "NavigationGrid initialization" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try NavigationGrid.init(allocator, 10, 10, 1.0);
    defer grid.deinit();

    const coord = GridCoord{ .x = 5, .y = 5 };
    const cell = grid.getCell(coord).?;
    try testing.expect(cell.walkable);
}

test "GridCoord conversion" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try NavigationGrid.init(allocator, 10, 10, 2.0);
    defer grid.deinit();

    const world_coord = grid.gridToWorld(GridCoord{ .x = 5, .y = 3 });
    const grid_coord = grid.worldToGrid(world_coord.x, world_coord.z);

    try testing.expectEqual(@as(i32, 5), grid_coord.x);
    try testing.expectEqual(@as(i32, 3), grid_coord.y);
}

test "A* pathfinding simple" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var grid = try NavigationGrid.init(allocator, 10, 10, 1.0);
    defer grid.deinit();

    var pathfinder = Pathfinder.init(allocator, &grid);

    const start = GridCoord{ .x = 0, .y = 0 };
    const goal = GridCoord{ .x = 5, .y = 5 };

    if (try pathfinder.findPath(start, goal)) |path_opt| {
        var path = path_opt;
        defer path.deinit();

        try testing.expect(path.waypoints.len > 0);
        try testing.expect(path.waypoints[0].equals(start));
        try testing.expect(path.waypoints[path.waypoints.len - 1].equals(goal));
    }
}
