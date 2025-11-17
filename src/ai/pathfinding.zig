// C&C Generals - AI Pathfinding System
// Implements A* pathfinding with hierarchical grid optimization

const std = @import("std");

/// Grid cell for pathfinding
pub const GridCell = struct {
    x: i32,
    y: i32,
    walkable: bool,
    cost: f32, // Movement cost (terrain-dependent)
    occupant: ?usize, // Unit ID if occupied
};

/// Pathfinding node for A* algorithm
pub const PathNode = struct {
    x: i32,
    y: i32,
    g_cost: f32, // Cost from start
    h_cost: f32, // Heuristic cost to goal
    f_cost: f32, // Total cost (g + h)
    parent: ?*PathNode,

    pub fn init(x: i32, y: i32, g: f32, h: f32, parent: ?*PathNode) PathNode {
        return PathNode{
            .x = x,
            .y = y,
            .g_cost = g,
            .h_cost = h,
            .f_cost = g + h,
            .parent = parent,
        };
    }
};

/// Path result
pub const Path = struct {
    waypoints: []Vec2,
    length: usize,
    valid: bool,

    pub fn deinit(self: *Path, allocator: std.mem.Allocator) void {
        if (self.waypoints.len > 0) {
            allocator.free(self.waypoints);
        }
    }
};

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn distance(self: Vec2, other: Vec2) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return @sqrt(dx * dx + dy * dy);
    }

    pub fn distanceSquared(self: Vec2, other: Vec2) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return dx * dx + dy * dy;
    }
};

/// Pathfinding grid
pub const PathfindingGrid = struct {
    width: usize,
    height: usize,
    cell_size: f32,
    cells: []GridCell,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, cell_size: f32) !PathfindingGrid {
        const cells = try allocator.alloc(GridCell, width * height);

        // Initialize all cells as walkable
        for (cells, 0..) |*cell, i| {
            cell.* = GridCell{
                .x = @intCast(@mod(i, width)),
                .y = @intCast(@divTrunc(i, width)),
                .walkable = true,
                .cost = 1.0,
                .occupant = null,
            };
        }

        return PathfindingGrid{
            .width = width,
            .height = height,
            .cell_size = cell_size,
            .cells = cells,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PathfindingGrid) void {
        self.allocator.free(self.cells);
    }

    pub fn getCell(self: *PathfindingGrid, x: i32, y: i32) ?*GridCell {
        if (x < 0 or y < 0 or x >= self.width or y >= self.height) return null;
        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);
        const index = uy * self.width + ux;
        return &self.cells[index];
    }

    pub fn worldToGrid(self: *PathfindingGrid, world_pos: Vec2) struct { x: i32, y: i32 } {
        return .{
            .x = @intFromFloat(@divTrunc(world_pos.x, self.cell_size)),
            .y = @intFromFloat(@divTrunc(world_pos.y, self.cell_size)),
        };
    }

    pub fn gridToWorld(self: *PathfindingGrid, grid_x: i32, grid_y: i32) Vec2 {
        return Vec2{
            .x = @as(f32, @floatFromInt(grid_x)) * self.cell_size + self.cell_size * 0.5,
            .y = @as(f32, @floatFromInt(grid_y)) * self.cell_size + self.cell_size * 0.5,
        };
    }

    pub fn setWalkable(self: *PathfindingGrid, x: i32, y: i32, walkable: bool) void {
        if (self.getCell(x, y)) |cell| {
            cell.walkable = walkable;
        }
    }

    pub fn setCost(self: *PathfindingGrid, x: i32, y: i32, cost: f32) void {
        if (self.getCell(x, y)) |cell| {
            cell.cost = cost;
        }
    }

    pub fn isWalkable(self: *PathfindingGrid, x: i32, y: i32) bool {
        if (self.getCell(x, y)) |cell| {
            return cell.walkable;
        }
        return false;
    }
};

/// A* Pathfinder
pub const AStar = struct {
    grid: *PathfindingGrid,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, grid: *PathfindingGrid) AStar {
        return AStar{
            .grid = grid,
            .allocator = allocator,
        };
    }

    /// Calculate heuristic (Manhattan distance for grid-based pathfinding)
    fn heuristic(from: Vec2, to: Vec2) f32 {
        const dx = @abs(from.x - to.x);
        const dy = @abs(from.y - to.y);
        return dx + dy;
    }

    /// Find path from start to goal using A* algorithm
    pub fn findPath(self: *AStar, start: Vec2, goal: Vec2) !Path {
        const start_grid = self.grid.worldToGrid(start);
        const goal_grid = self.grid.worldToGrid(goal);

        // Check if start and goal are valid
        if (!self.grid.isWalkable(start_grid.x, start_grid.y) or
            !self.grid.isWalkable(goal_grid.x, goal_grid.y)) {
            return Path{ .waypoints = &[_]Vec2{}, .length = 0, .valid = false };
        }

        var open_list = std.ArrayList(*PathNode).init(self.allocator);
        defer open_list.deinit();

        var closed_set = std.AutoHashMap(i64, void).init(self.allocator);
        defer closed_set.deinit();

        var node_pool = std.ArrayList(PathNode).init(self.allocator);
        defer node_pool.deinit();

        // Create start node
        const start_node = try node_pool.addOne();
        start_node.* = PathNode.init(
            start_grid.x,
            start_grid.y,
            0,
            heuristic(start, goal),
            null
        );
        try open_list.append(start_node);

        var current_node: ?*PathNode = null;

        // A* main loop
        while (open_list.items.len > 0) {
            // Find node with lowest f_cost
            var lowest_index: usize = 0;
            for (open_list.items, 0..) |node, i| {
                if (node.f_cost < open_list.items[lowest_index].f_cost) {
                    lowest_index = i;
                }
            }

            current_node = open_list.orderedRemove(lowest_index);
            const current = current_node.?;

            // Check if we reached the goal
            if (current.x == goal_grid.x and current.y == goal_grid.y) {
                break;
            }

            // Add to closed set
            const key = (@as(i64, current.x) << 32) | @as(i64, current.y);
            try closed_set.put(key, {});

            // Check all neighbors (8 directions)
            const neighbors = [_]struct { dx: i32, dy: i32 }{
                .{ .dx = -1, .dy = 0 },  // Left
                .{ .dx = 1, .dy = 0 },   // Right
                .{ .dx = 0, .dy = -1 },  // Up
                .{ .dx = 0, .dy = 1 },   // Down
                .{ .dx = -1, .dy = -1 }, // Top-Left
                .{ .dx = 1, .dy = -1 },  // Top-Right
                .{ .dx = -1, .dy = 1 },  // Bottom-Left
                .{ .dx = 1, .dy = 1 },   // Bottom-Right
            };

            for (neighbors) |n| {
                const nx = current.x + n.dx;
                const ny = current.y + n.dy;

                // Check if neighbor is walkable
                if (!self.grid.isWalkable(nx, ny)) continue;

                // Check if in closed set
                const neighbor_key = (@as(i64, nx) << 32) | @as(i64, ny);
                if (closed_set.contains(neighbor_key)) continue;

                // Calculate costs
                const neighbor_world = self.grid.gridToWorld(nx, ny);
                const diagonal = (n.dx != 0 and n.dy != 0);
                const movement_cost: f32 = if (diagonal) 1.414 else 1.0;

                const cell = self.grid.getCell(nx, ny).?;
                const g_cost = current.g_cost + movement_cost * cell.cost;
                const h_cost = heuristic(neighbor_world, goal);

                // Check if neighbor already in open list
                var found = false;
                for (open_list.items) |open_node| {
                    if (open_node.x == nx and open_node.y == ny) {
                        if (g_cost < open_node.g_cost) {
                            open_node.g_cost = g_cost;
                            open_node.f_cost = g_cost + open_node.h_cost;
                            open_node.parent = current;
                        }
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    const new_node = try node_pool.addOne();
                    new_node.* = PathNode.init(nx, ny, g_cost, h_cost, current);
                    try open_list.append(new_node);
                }
            }
        }

        // Reconstruct path
        if (current_node) |final_node| {
            if (final_node.x == goal_grid.x and final_node.y == goal_grid.y) {
                return try self.reconstructPath(final_node);
            }
        }

        // No path found
        return Path{ .waypoints = &[_]Vec2{}, .length = 0, .valid = false };
    }

    fn reconstructPath(self: *AStar, end_node: *PathNode) !Path {
        var waypoints = std.ArrayList(Vec2).init(self.allocator);

        var current: ?*PathNode = end_node;
        while (current) |node| {
            const world_pos = self.grid.gridToWorld(node.x, node.y);
            try waypoints.append(world_pos);
            current = node.parent;
        }

        // Reverse the path
        std.mem.reverse(Vec2, waypoints.items);

        return Path{
            .waypoints = try waypoints.toOwnedSlice(),
            .length = waypoints.items.len,
            .valid = true,
        };
    }

    /// Smooth path by removing unnecessary waypoints
    pub fn smoothPath(self: *AStar, path: *Path) !void {
        if (path.length < 3) return;

        var smoothed = std.ArrayList(Vec2).init(self.allocator);
        defer smoothed.deinit();

        try smoothed.append(path.waypoints[0]);

        var i: usize = 0;
        while (i < path.length - 1) {
            var j = i + 2;
            var last_valid = i + 1;

            while (j < path.length) {
                if (self.hasLineOfSight(path.waypoints[i], path.waypoints[j])) {
                    last_valid = j;
                }
                j += 1;
            }

            try smoothed.append(path.waypoints[last_valid]);
            i = last_valid;
        }

        // Replace old waypoints with smoothed ones
        self.allocator.free(path.waypoints);
        path.waypoints = try smoothed.toOwnedSlice();
        path.length = smoothed.items.len;
    }

    fn hasLineOfSight(self: *AStar, from: Vec2, to: Vec2) bool {
        const dx = to.x - from.x;
        const dy = to.y - from.y;
        const distance = @sqrt(dx * dx + dy * dy);
        const steps = @as(usize, @intFromFloat(@ceil(distance / self.grid.cell_size)));

        if (steps == 0) return true;

        var i: usize = 0;
        while (i <= steps) : (i += 1) {
            const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            const x = from.x + dx * t;
            const y = from.y + dy * t;
            const grid = self.grid.worldToGrid(Vec2{ .x = x, .y = y });

            if (!self.grid.isWalkable(grid.x, grid.y)) {
                return false;
            }
        }

        return true;
    }
};

/// Pathfinding manager for multiple units
pub const PathfindingManager = struct {
    grid: PathfindingGrid,
    astar: AStar,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, map_width: usize, map_height: usize, cell_size: f32) !PathfindingManager {
        var grid = try PathfindingGrid.init(allocator, map_width, map_height, cell_size);
        const astar = AStar.init(allocator, &grid);

        return PathfindingManager{
            .grid = grid,
            .astar = astar,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PathfindingManager) void {
        self.grid.deinit();
    }

    pub fn findPath(self: *PathfindingManager, start: Vec2, goal: Vec2, smooth: bool) !Path {
        var path = try self.astar.findPath(start, goal);
        if (smooth and path.valid) {
            try self.astar.smoothPath(&path);
        }
        return path;
    }

    pub fn updateObstacle(self: *PathfindingManager, x: i32, y: i32, walkable: bool) void {
        self.grid.setWalkable(x, y, walkable);
    }

    pub fn updateTerrainCost(self: *PathfindingManager, x: i32, y: i32, cost: f32) void {
        self.grid.setCost(x, y, cost);
    }
};
