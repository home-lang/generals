// Fog of War system
const std = @import("std");

// Map dimensions in tiles
pub const FOG_TILE_SIZE: f32 = 32.0;
pub const FOG_MAP_WIDTH: usize = 40; // 1280 / 32
pub const FOG_MAP_HEIGHT: usize = 23; // ~720 / 32

// Fog states
pub const FogState = enum(u8) {
    Unexplored, // Never seen - completely black
    Explored, // Was seen but no current vision - dark/gray
    Visible, // Currently visible - fully lit
};

pub const FogOfWar = struct {
    // Current visibility state
    visibility: [FOG_MAP_HEIGHT][FOG_MAP_WIDTH]FogState,
    // Has ever been explored
    explored: [FOG_MAP_HEIGHT][FOG_MAP_WIDTH]bool,

    pub fn init() FogOfWar {
        var fog = FogOfWar{
            .visibility = undefined,
            .explored = undefined,
        };

        // Initialize all tiles as unexplored
        for (0..FOG_MAP_HEIGHT) |y| {
            for (0..FOG_MAP_WIDTH) |x| {
                fog.visibility[y][x] = .Unexplored;
                fog.explored[y][x] = false;
            }
        }

        return fog;
    }

    // Reset visibility to explored state (called each frame before updating vision)
    pub fn resetVisibility(self: *FogOfWar) void {
        for (0..FOG_MAP_HEIGHT) |y| {
            for (0..FOG_MAP_WIDTH) |x| {
                if (self.visibility[y][x] == .Visible) {
                    self.visibility[y][x] = .Explored;
                }
            }
        }
    }

    // Reveal area around a point with given vision radius
    pub fn revealArea(self: *FogOfWar, world_x: f32, world_y: f32, vision_radius: f32) void {
        const center_tile_x = @as(i32, @intFromFloat(world_x / FOG_TILE_SIZE));
        const center_tile_y = @as(i32, @intFromFloat(world_y / FOG_TILE_SIZE));
        const radius_tiles = @as(i32, @intFromFloat(vision_radius / FOG_TILE_SIZE)) + 1;

        var ty: i32 = center_tile_y - radius_tiles;
        while (ty <= center_tile_y + radius_tiles) : (ty += 1) {
            var tx: i32 = center_tile_x - radius_tiles;
            while (tx <= center_tile_x + radius_tiles) : (tx += 1) {
                // Bounds check
                if (tx < 0 or tx >= FOG_MAP_WIDTH or ty < 0 or ty >= FOG_MAP_HEIGHT) continue;

                // Distance check (circular vision)
                const dx = @as(f32, @floatFromInt(tx)) - @as(f32, @floatFromInt(center_tile_x));
                const dy = @as(f32, @floatFromInt(ty)) - @as(f32, @floatFromInt(center_tile_y));
                const dist_sq = dx * dx + dy * dy;
                const radius_sq = @as(f32, @floatFromInt(radius_tiles * radius_tiles));

                if (dist_sq <= radius_sq) {
                    const ux: usize = @intCast(tx);
                    const uy: usize = @intCast(ty);
                    self.visibility[uy][ux] = .Visible;
                    self.explored[uy][ux] = true;
                }
            }
        }
    }

    // Check if a world position is currently visible
    pub fn isVisible(self: *const FogOfWar, world_x: f32, world_y: f32) bool {
        const tx = @as(i32, @intFromFloat(world_x / FOG_TILE_SIZE));
        const ty = @as(i32, @intFromFloat(world_y / FOG_TILE_SIZE));

        if (tx < 0 or tx >= FOG_MAP_WIDTH or ty < 0 or ty >= FOG_MAP_HEIGHT) return false;

        return self.visibility[@intCast(ty)][@intCast(tx)] == .Visible;
    }

    // Check if a world position has been explored
    pub fn isExplored(self: *const FogOfWar, world_x: f32, world_y: f32) bool {
        const tx = @as(i32, @intFromFloat(world_x / FOG_TILE_SIZE));
        const ty = @as(i32, @intFromFloat(world_y / FOG_TILE_SIZE));

        if (tx < 0 or tx >= FOG_MAP_WIDTH or ty < 0 or ty >= FOG_MAP_HEIGHT) return false;

        return self.explored[@intCast(ty)][@intCast(tx)];
    }

    // Get fog state at tile coordinates
    pub fn getState(self: *const FogOfWar, tile_x: usize, tile_y: usize) FogState {
        if (tile_x >= FOG_MAP_WIDTH or tile_y >= FOG_MAP_HEIGHT) return .Unexplored;
        return self.visibility[tile_y][tile_x];
    }
};
