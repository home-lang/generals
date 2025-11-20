// Phase 3: AI & Pathfinding System
// Based on Thyme's pathfinding implementation
// Reference: ~/Code/Thyme/src/game/logic/ai/aipathfind.h

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);

// ============================================================================
// PHASE 3.1: Grid System & Cell Types
// ============================================================================

/// Cell type (from Thyme's PathfindCell)
pub const CellType = enum(u8) {
    CLEAR = 0, // Walkable terrain
    WATER = 1, // Water (boats only)
    CLIFF = 2, // Cliff / impassable
    RUBBLE = 3, // Damaged terrain
    OBSTACLE = 4, // Building / static obstacle
    BLOCKED = 5, // Blocked by unit
    RESERVED = 6, // Reserved for building placement
};

/// Cell flags (from Thyme's CellFlags)
pub const CellFlags = packed struct(u8) {
    has_unit: bool = false, // Unit present in cell
    unit_goal: bool = false, // Unit's destination
    unit_moving: bool = false, // Unit is moving through
    bridge: bool = false, // Bridge cell
    wall: bool = false, // Wall piece
    _padding: u3 = 0,

    pub fn isEmpty(self: CellFlags) bool {
        return !self.has_unit and !self.unit_goal and !self.unit_moving;
    }
};

/// Pathfinding cell (from Thyme's PathfindCell)
pub const PathfindCell = struct {
    cell_type: CellType = .CLEAR,
    flags: CellFlags = .{},
    cost: u16 = 1, // Movement cost
    zone: u16 = 0, // Connectivity zone

    pub fn isPassable(self: PathfindCell) bool {
        return switch (self.cell_type) {
            .CLEAR, .RUBBLE => true,
            .WATER, .CLIFF, .OBSTACLE, .BLOCKED, .RESERVED => false,
        };
    }

    pub fn getMoveCost(self: PathfindCell) u16 {
        return switch (self.cell_type) {
            .CLEAR => 1,
            .RUBBLE => 2, // Slower movement
            else => 9999, // Impassable
        };
    }
};

/// Pathfinding grid (from Thyme's Pathfinder map structure)
pub const PathfindGrid = struct {
    allocator: Allocator,
    cells: []PathfindCell,
    width: usize,
    height: usize,
    cell_size: f32, // World units per cell (e.g., 10.0)

    pub fn init(allocator: Allocator, width: usize, height: usize, cell_size: f32) !PathfindGrid {
        const total_cells = width * height;
        const cells = try allocator.alloc(PathfindCell, total_cells);

        // Initialize all cells as CLEAR
        for (cells) |*cell| {
            cell.* = .{};
        }

        return .{
            .allocator = allocator,
            .cells = cells,
            .width = width,
            .height = height,
            .cell_size = cell_size,
        };
    }

    pub fn deinit(self: *PathfindGrid) void {
        self.allocator.free(self.cells);
    }

    /// Convert world coordinates to grid coordinates
    pub fn worldToGrid(self: PathfindGrid, world_x: f32, world_y: f32) struct { x: i32, y: i32 } {
        const grid_x = @as(i32, @intFromFloat(world_x / self.cell_size));
        const grid_y = @as(i32, @intFromFloat(world_y / self.cell_size));
        return .{ .x = grid_x, .y = grid_y };
    }

    /// Convert grid coordinates to world coordinates (center of cell)
    pub fn gridToWorld(self: PathfindGrid, grid_x: i32, grid_y: i32) struct { x: f32, y: f32 } {
        const world_x = @as(f32, @floatFromInt(grid_x)) * self.cell_size + self.cell_size / 2.0;
        const world_y = @as(f32, @floatFromInt(grid_y)) * self.cell_size + self.cell_size / 2.0;
        return .{ .x = world_x, .y = world_y };
    }

    /// Get cell at grid coordinates
    pub fn getCell(self: *PathfindGrid, x: i32, y: i32) ?*PathfindCell {
        if (x < 0 or y < 0) return null;
        const ux = @as(usize, @intCast(x));
        const uy = @as(usize, @intCast(y));
        if (ux >= self.width or uy >= self.height) return null;

        const index = uy * self.width + ux;
        return &self.cells[index];
    }

    /// Set cell type at grid coordinates
    pub fn setCellType(self: *PathfindGrid, x: i32, y: i32, cell_type: CellType) void {
        if (self.getCell(x, y)) |cell| {
            cell.cell_type = cell_type;
        }
    }

    /// Check if cell is passable
    pub fn isPassable(self: *PathfindGrid, x: i32, y: i32) bool {
        if (self.getCell(x, y)) |cell| {
            return cell.isPassable();
        }
        return false; // Out of bounds = impassable
    }
};

// ============================================================================
// PHASE 3.2: A* Pathfinding Algorithm
// ============================================================================

/// Path node (from Thyme's PathNode)
pub const PathNode = struct {
    x: i32,
    y: i32,
    world_x: f32,
    world_y: f32,
    next: ?*PathNode = null,

    pub fn distanceTo(self: PathNode, other: PathNode) f32 {
        const dx = self.world_x - other.world_x;
        const dy = self.world_y - other.world_y;
        return @sqrt(dx * dx + dy * dy);
    }

    pub fn toVec2(self: PathNode) Vec2 {
        return Vec2.init(self.world_x, self.world_y);
    }
};

/// Path (from Thyme's Path)
pub const Path = struct {
    allocator: Allocator,
    nodes: std.ArrayList(PathNode),
    waypoints: std.ArrayList(Vec2), // Legacy compatibility
    current_index: usize = 0,
    total_length: f32 = 0.0,
    is_blocked: bool = false,

    pub fn init(allocator: Allocator) Path {
        return .{
            .allocator = allocator,
            .nodes = .{},
            .waypoints = .{},
        };
    }

    pub fn deinit(self: *Path) void {
        self.nodes.deinit(self.allocator);
        self.waypoints.deinit(self.allocator);
    }

    pub fn addNode(self: *Path, x: i32, y: i32, world_x: f32, world_y: f32) !void {
        const node = PathNode{
            .x = x,
            .y = y,
            .world_x = world_x,
            .world_y = world_y,
        };

        // Calculate cumulative path length
        if (self.nodes.items.len > 0) {
            const last = self.nodes.items[self.nodes.items.len - 1];
            self.total_length += node.distanceTo(last);
        }

        try self.nodes.append(self.allocator, node);
        try self.waypoints.append(self.allocator, Vec2.init(world_x, world_y));
    }

    // Legacy compatibility methods
    pub fn add(self: *Path, point: Vec2) !void {
        try self.waypoints.append(self.allocator, point);
    }

    pub fn isEmpty(self: Path) bool {
        return self.waypoints.items.len == 0;
    }

    pub fn getNext(self: *Path) ?Vec2 {
        if (self.current_index < self.waypoints.items.len) {
            return self.waypoints.items[self.current_index];
        }
        return null;
    }

    pub fn removeFirst(self: *Path) void {
        if (self.current_index < self.waypoints.items.len) {
            self.current_index += 1;
        }
    }

    pub fn getNextWaypoint(self: *Path) ?PathNode {
        if (self.current_index >= self.nodes.items.len) {
            return null;
        }
        return self.nodes.items[self.current_index];
    }

    pub fn advanceWaypoint(self: *Path) void {
        if (self.current_index < self.nodes.items.len) {
            self.current_index += 1;
        }
    }

    pub fn isComplete(self: Path) bool {
        return self.current_index >= self.nodes.items.len;
    }

    pub fn reset(self: *Path) void {
        self.current_index = 0;
    }
};

/// A* cell info (from Thyme's PathfindCellInfo)
const AStarNode = struct {
    x: i32,
    y: i32,
    g_cost: u32, // Cost from start
    h_cost: u32, // Heuristic cost to goal
    f_cost: u32, // Total cost (g + h)
    parent: ?*AStarNode,

    pub fn init(x: i32, y: i32, g_cost: u32, h_cost: u32, parent: ?*AStarNode) AStarNode {
        return .{
            .x = x,
            .y = y,
            .g_cost = g_cost,
            .h_cost = h_cost,
            .f_cost = g_cost + h_cost,
            .parent = parent,
        };
    }
};

/// A* pathfinder (from Thyme's Pathfinder)
pub const Pathfinder = struct {
    allocator: Allocator,
    grid: *PathfindGrid,
    grid_size: f32, // Legacy compatibility
    open_list: std.ArrayList(AStarNode),
    closed_set: std.AutoHashMap(u64, void),
    node_pool: std.ArrayList(AStarNode),

    const MAX_ITERATIONS = 10000; // Prevent infinite loops

    pub fn init(allocator: Allocator, grid_size: f32) Pathfinder {
        // For legacy compatibility - create a default grid if none provided
        // This will be replaced when proper grid is initialized
        const dummy_grid = allocator.create(PathfindGrid) catch unreachable;
        dummy_grid.* = PathfindGrid.init(allocator, 100, 100, grid_size) catch unreachable;

        return .{
            .allocator = allocator,
            .grid = dummy_grid,
            .grid_size = grid_size,
            .open_list = .{},
            .closed_set = std.AutoHashMap(u64, void).init(allocator),
            .node_pool = .{},
        };
    }

    pub fn initWithGrid(allocator: Allocator, grid: *PathfindGrid) Pathfinder {
        return .{
            .allocator = allocator,
            .grid = grid,
            .grid_size = grid.cell_size,
            .open_list = .{},
            .closed_set = std.AutoHashMap(u64, void).init(allocator),
            .node_pool = .{},
        };
    }

    pub fn deinit(self: *Pathfinder) void {
        self.open_list.deinit(self.allocator);
        self.closed_set.deinit();
        self.node_pool.deinit(self.allocator);
    }

    /// Find path from start to goal using A* algorithm
    pub fn findPath(self: *Pathfinder, start: Vec2, end: Vec2) !Path {
        // Clear previous search state
        self.open_list.clearRetainingCapacity();
        self.closed_set.clearRetainingCapacity();
        self.node_pool.clearRetainingCapacity();

        // Convert world coordinates to grid
        const start_grid = self.grid.worldToGrid(start.x, start.y);
        const goal_grid = self.grid.worldToGrid(end.x, end.y);

        // Check if start and goal are valid
        if (!self.grid.isPassable(start_grid.x, start_grid.y)) {
            return Path.init(self.allocator); // Empty path - start blocked
        }
        if (!self.grid.isPassable(goal_grid.x, goal_grid.y)) {
            return Path.init(self.allocator); // Empty path - goal blocked
        }

        // Initialize start node
        const h_start = self.heuristic(start_grid.x, start_grid.y, goal_grid.x, goal_grid.y);
        const start_node = AStarNode.init(start_grid.x, start_grid.y, 0, h_start, null);
        try self.open_list.append(self.allocator, start_node);

        var iterations: u32 = 0;

        // A* main loop
        while (self.open_list.items.len > 0) : (iterations += 1) {
            if (iterations > MAX_ITERATIONS) {
                return Path.init(self.allocator); // Path too long
            }

            // Find node with lowest f_cost in open list
            var lowest_index: usize = 0;
            var lowest_f_cost: u32 = self.open_list.items[0].f_cost;
            for (self.open_list.items, 0..) |node, i| {
                if (node.f_cost < lowest_f_cost) {
                    lowest_f_cost = node.f_cost;
                    lowest_index = i;
                }
            }

            // Pop lowest cost node
            const current = self.open_list.swapRemove(lowest_index);

            // Check if reached goal
            if (current.x == goal_grid.x and current.y == goal_grid.y) {
                return try self.reconstructPath(current, end.x, end.y);
            }

            // Mark as closed
            const key = self.coordToKey(current.x, current.y);
            try self.closed_set.put(key, {});

            // Explore neighbors (8 directions)
            const neighbors = [_]struct { dx: i32, dy: i32 }{
                .{ .dx = -1, .dy = 0 }, // Left
                .{ .dx = 1, .dy = 0 }, // Right
                .{ .dx = 0, .dy = -1 }, // Up
                .{ .dx = 0, .dy = 1 }, // Down
                .{ .dx = -1, .dy = -1 }, // Top-left
                .{ .dx = 1, .dy = -1 }, // Top-right
                .{ .dx = -1, .dy = 1 }, // Bottom-left
                .{ .dx = 1, .dy = 1 }, // Bottom-right
            };

            for (neighbors) |neighbor| {
                const nx = current.x + neighbor.dx;
                const ny = current.y + neighbor.dy;

                // Check if neighbor is passable
                if (!self.grid.isPassable(nx, ny)) {
                    continue;
                }

                // Check if already in closed set
                const neighbor_key = self.coordToKey(nx, ny);
                if (self.closed_set.contains(neighbor_key)) {
                    continue;
                }

                // Calculate costs
                const is_diagonal = (neighbor.dx != 0 and neighbor.dy != 0);
                const move_cost: u32 = if (is_diagonal) 14 else 10; // Diagonal = 1.4 * 10

                const cell = self.grid.getCell(nx, ny) orelse continue;
                const terrain_cost = cell.getMoveCost();

                const g_cost = current.g_cost + move_cost * terrain_cost;
                const h_cost = self.heuristic(nx, ny, goal_grid.x, goal_grid.y);

                // Check if neighbor already in open list with lower cost
                var found_better = false;
                for (self.open_list.items) |*open_node| {
                    if (open_node.x == nx and open_node.y == ny) {
                        if (g_cost < open_node.g_cost) {
                            // Update with better path
                            open_node.g_cost = g_cost;
                            open_node.f_cost = g_cost + h_cost;
                            // Store current as parent
                            try self.node_pool.append(self.allocator, current);
                            open_node.parent = &self.node_pool.items[self.node_pool.items.len - 1];
                        }
                        found_better = true;
                        break;
                    }
                }

                if (!found_better) {
                    // Add to open list
                    try self.node_pool.append(self.allocator, current);
                    const parent_ptr = &self.node_pool.items[self.node_pool.items.len - 1];
                    const neighbor_node = AStarNode.init(nx, ny, g_cost, h_cost, parent_ptr);
                    try self.open_list.append(self.allocator, neighbor_node);
                }
            }
        }

        return Path.init(self.allocator); // No path found
    }

    /// Heuristic function (Manhattan distance * 10)
    fn heuristic(self: Pathfinder, x1: i32, y1: i32, x2: i32, y2: i32) u32 {
        _ = self;
        const dx: u32 = @intCast(if (x2 > x1) x2 - x1 else x1 - x2);
        const dy: u32 = @intCast(if (y2 > y1) y2 - y1 else y1 - y2);
        return (dx + dy) * 10;
    }

    /// Convert grid coordinates to hash key
    fn coordToKey(self: Pathfinder, x: i32, y: i32) u64 {
        _ = self;
        const ux: u32 = @bitCast(x);
        const uy: u32 = @bitCast(y);
        return (@as(u64, ux) << 32) | @as(u64, uy);
    }

    /// Reconstruct path from goal node back to start
    fn reconstructPath(self: *Pathfinder, goal_node: AStarNode, goal_x: f32, goal_y: f32) !Path {
        var path = Path.init(self.allocator);
        errdefer path.deinit();

        // Trace back from goal to start
        var current: ?AStarNode = goal_node;
        var reverse_nodes: std.ArrayList(AStarNode) = .{};
        defer reverse_nodes.deinit(self.allocator);

        while (current) |node| {
            try reverse_nodes.append(self.allocator, node);
            current = if (node.parent) |p| p.* else null;
        }

        // Add nodes in forward order (start to goal)
        var i: usize = reverse_nodes.items.len;
        while (i > 0) {
            i -= 1;
            const node = reverse_nodes.items[i];
            const world_pos = self.grid.gridToWorld(node.x, node.y);
            try path.addNode(node.x, node.y, world_pos.x, world_pos.y);
        }

        // Ensure final node is exactly at goal
        if (path.nodes.items.len > 0) {
            path.nodes.items[path.nodes.items.len - 1].world_x = goal_x;
            path.nodes.items[path.nodes.items.len - 1].world_y = goal_y;
            path.waypoints.items[path.waypoints.items.len - 1] = Vec2.init(goal_x, goal_y);
        }

        return path;
    }

    // Legacy compatibility methods
    pub fn worldToGrid(self: *const Pathfinder, pos: Vec2) struct { x: i32, y: i32 } {
        return self.grid.worldToGrid(pos.x, pos.y);
    }

    pub fn gridToWorld(self: *const Pathfinder, x: i32, y: i32) Vec2 {
        const world_pos = self.grid.gridToWorld(x, y);
        return Vec2.init(world_pos.x, world_pos.y);
    }

    pub fn isWalkable(self: *const Pathfinder, pos: Vec2) bool {
        const grid_pos = self.grid.worldToGrid(pos.x, pos.y);
        return self.grid.isPassable(grid_pos.x, grid_pos.y);
    }
};

// ============================================================================
// PHASE 3.3: Path Smoothing & Optimization
// ============================================================================

/// Smooth path by removing unnecessary waypoints (from Thyme's path optimization)
pub fn smoothPath(grid: *PathfindGrid, path: *Path) !void {
    if (path.nodes.items.len <= 2) {
        return; // Can't smooth path with 2 or fewer nodes
    }

    var optimized: std.ArrayList(PathNode) = .{};
    defer optimized.deinit(path.allocator);

    // Always keep start node
    try optimized.append(path.allocator, path.nodes.items[0]);

    var current_index: usize = 0;
    while (current_index < path.nodes.items.len - 1) {
        const start_node = path.nodes.items[current_index];

        // Try to find furthest visible node
        var furthest_index = current_index + 1;
        var i = current_index + 2;
        while (i < path.nodes.items.len) : (i += 1) {
            const test_node = path.nodes.items[i];
            if (hasLineOfSight(grid, start_node, test_node)) {
                furthest_index = i;
            } else {
                break; // Can't see further, stop
            }
        }

        // Add furthest visible node
        try optimized.append(path.allocator, path.nodes.items[furthest_index]);
        current_index = furthest_index;
    }

    // Replace path nodes with optimized version
    path.nodes.clearRetainingCapacity();
    path.waypoints.clearRetainingCapacity();
    for (optimized.items) |node| {
        try path.nodes.append(path.allocator, node);
        try path.waypoints.append(path.allocator, Vec2.init(node.world_x, node.world_y));
    }
}

/// Check if there's a clear line of sight between two nodes
fn hasLineOfSight(grid: *PathfindGrid, start: PathNode, end: PathNode) bool {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const steps = @max(@abs(dx), @abs(dy));

    if (steps == 0) return true;

    const steps_f = @as(f32, @floatFromInt(steps));
    const dx_f = @as(f32, @floatFromInt(dx)) / steps_f;
    const dy_f = @as(f32, @floatFromInt(dy)) / steps_f;

    var i: i32 = 0;
    while (i <= steps) : (i += 1) {
        const x = start.x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(i)) * dx_f));
        const y = start.y + @as(i32, @intFromFloat(@as(f32, @floatFromInt(i)) * dy_f));

        if (!grid.isPassable(x, y)) {
            return false;
        }
    }

    return true;
}

// ============================================================================
// Tests
// ============================================================================

test "PathfindGrid: init and deinit" {
    var grid = try PathfindGrid.init(std.testing.allocator, 100, 100, 10.0);
    defer grid.deinit();

    try std.testing.expectEqual(@as(usize, 100), grid.width);
    try std.testing.expectEqual(@as(usize, 100), grid.height);
}

test "PathfindGrid: world to grid conversion" {
    var grid = try PathfindGrid.init(std.testing.allocator, 100, 100, 10.0);
    defer grid.deinit();

    const grid_pos = grid.worldToGrid(55.0, 75.0);
    try std.testing.expectEqual(@as(i32, 5), grid_pos.x);
    try std.testing.expectEqual(@as(i32, 7), grid_pos.y);
}

test "Pathfinder: find simple path" {
    var grid = try PathfindGrid.init(std.testing.allocator, 100, 100, 10.0);
    defer grid.deinit();

    var pathfinder = Pathfinder.initWithGrid(std.testing.allocator, &grid);
    defer pathfinder.deinit();

    const start = Vec2.init(0.0, 0.0);
    const end = Vec2.init(200.0, 200.0);

    var path = try pathfinder.findPath(start, end);
    defer path.deinit();

    try std.testing.expect(path.nodes.items.len > 0);
}
