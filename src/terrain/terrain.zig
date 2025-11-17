// C&C Generals - Terrain & Map Rendering System
// Handles heightmaps, terrain tiles, and map loading

const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn distance(self: Vec3, other: Vec3) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }
};

/// Terrain tile types
pub const TerrainType = enum {
    Grass,
    Desert,
    Snow,
    Rock,
    Cliff,
    Water,
    Road,
    Beach,

    pub fn getColor(self: TerrainType) u32 {
        return switch (self) {
            .Grass => 0x00AA00,
            .Desert => 0xCCAA66,
            .Snow => 0xFFFFFF,
            .Rock => 0x666666,
            .Cliff => 0x444444,
            .Water => 0x0066BB,
            .Road => 0x888888,
            .Beach => 0xEECC88,
        };
    }

    pub fn isWalkable(self: TerrainType) bool {
        return switch (self) {
            .Grass, .Desert, .Snow, .Rock, .Road, .Beach => true,
            .Cliff, .Water => false,
        };
    }
};

/// Single terrain tile
pub const TerrainTile = struct {
    tile_type: TerrainType,
    height: f32,
    passable: bool,
    texture_id: u32,
    blend_mask: u8,

    pub fn init(tile_type: TerrainType, height: f32) TerrainTile {
        return TerrainTile{
            .tile_type = tile_type,
            .height = height,
            .passable = tile_type.isWalkable(),
            .texture_id = 0,
            .blend_mask = 0,
        };
    }

    pub fn getWorldPosition(self: *TerrainTile, grid_x: usize, grid_y: usize, tile_size: f32) Vec3 {
        return Vec3.init(
            @as(f32, @floatFromInt(grid_x)) * tile_size,
            self.height,
            @as(f32, @floatFromInt(grid_y)) * tile_size,
        );
    }
};

/// Heightmap for terrain elevation
pub const Heightmap = struct {
    width: usize,
    height: usize,
    heights: []f32,
    min_height: f32,
    max_height: f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Heightmap {
        const heights = try allocator.alloc(f32, width * height);

        // Initialize to flat terrain
        for (heights) |*h| {
            h.* = 0.0;
        }

        return Heightmap{
            .width = width,
            .height = height,
            .heights = heights,
            .min_height = 0.0,
            .max_height = 0.0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Heightmap) void {
        self.allocator.free(self.heights);
    }

    pub fn getHeight(self: *Heightmap, x: usize, y: usize) f32 {
        if (x >= self.width or y >= self.height) return 0.0;
        return self.heights[y * self.width + x];
    }

    pub fn setHeight(self: *Heightmap, x: usize, y: usize, height: f32) void {
        if (x >= self.width or y >= self.height) return;
        self.heights[y * self.width + x] = height;

        // Update min/max
        if (height < self.min_height) self.min_height = height;
        if (height > self.max_height) self.max_height = height;
    }

    /// Get interpolated height at world position
    pub fn getHeightAt(self: *Heightmap, world_x: f32, world_y: f32, tile_size: f32) f32 {
        const grid_x = world_x / tile_size;
        const grid_y = world_y / tile_size;

        const x0 = @as(usize, @intFromFloat(@floor(grid_x)));
        const y0 = @as(usize, @intFromFloat(@floor(grid_y)));
        const x1 = @min(x0 + 1, self.width - 1);
        const y1 = @min(y0 + 1, self.height - 1);

        const fx = grid_x - @as(f32, @floatFromInt(x0));
        const fy = grid_y - @as(f32, @floatFromInt(y0));

        // Bilinear interpolation
        const h00 = self.getHeight(x0, y0);
        const h10 = self.getHeight(x1, y0);
        const h01 = self.getHeight(x0, y1);
        const h11 = self.getHeight(x1, y1);

        const h0 = h00 * (1.0 - fx) + h10 * fx;
        const h1 = h01 * (1.0 - fx) + h11 * fx;

        return h0 * (1.0 - fy) + h1 * fy;
    }

    /// Generate procedural heightmap using Perlin-like noise
    pub fn generateProcedural(self: *Heightmap, seed: u64) void {
        _ = seed;
        // Simple deterministic noise without using rand

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                // Simple multi-octave noise approximation
                var height: f32 = 0.0;
                var amplitude: f32 = 1.0;
                var frequency: f32 = 0.01;

                // Multiple octaves with deterministic noise
                for (0..4) |octave| {
                    const nx = @as(f32, @floatFromInt(x)) * frequency;
                    const ny = @as(f32, @floatFromInt(y)) * frequency;

                    // Deterministic pseudo-random based on position
                    const noise = @sin(nx * 12.9898 + ny * 78.233 + @as(f32, @floatFromInt(octave))) * 43758.5453;
                    const sample = @sin(nx) * @cos(ny) + (noise - @floor(noise)) * 0.2;
                    height += sample * amplitude;

                    amplitude *= 0.5;
                    frequency *= 2.0;
                }

                self.setHeight(x, y, height * 10.0);
            }
        }
    }
};

/// Map boundary and playable area
pub const MapBounds = struct {
    min_x: f32,
    min_z: f32,
    max_x: f32,
    max_z: f32,

    pub fn contains(self: MapBounds, x: f32, z: f32) bool {
        return x >= self.min_x and x <= self.max_x and z >= self.min_z and z <= self.max_z;
    }

    pub fn clamp(self: MapBounds, x: f32, z: f32) Vec2 {
        return Vec2{
            .x = @max(self.min_x, @min(self.max_x, x)),
            .y = @max(self.min_z, @min(self.max_z, z)),
        };
    }
};

/// Complete terrain map
pub const TerrainMap = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    tile_size: f32,
    tiles: []TerrainTile,
    heightmap: Heightmap,
    bounds: MapBounds,
    name: []const u8,
    player_starts: []Vec3,
    player_start_count: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, tile_size: f32, map_name: []const u8) !TerrainMap {
        const tiles = try allocator.alloc(TerrainTile, width * height);
        const player_starts = try allocator.alloc(Vec3, 8);

        // Initialize all tiles as grass at height 0
        for (tiles) |*tile| {
            tile.* = TerrainTile.init(.Grass, 0.0);
        }

        const heightmap = try Heightmap.init(allocator, width, height);

        const world_width = @as(f32, @floatFromInt(width)) * tile_size;
        const world_height = @as(f32, @floatFromInt(height)) * tile_size;

        return TerrainMap{
            .allocator = allocator,
            .width = width,
            .height = height,
            .tile_size = tile_size,
            .tiles = tiles,
            .heightmap = heightmap,
            .bounds = MapBounds{
                .min_x = 0.0,
                .min_z = 0.0,
                .max_x = world_width,
                .max_z = world_height,
            },
            .name = map_name,
            .player_starts = player_starts,
            .player_start_count = 0,
        };
    }

    pub fn deinit(self: *TerrainMap) void {
        self.allocator.free(self.tiles);
        self.allocator.free(self.player_starts);
        self.heightmap.deinit();
    }

    pub fn getTile(self: *TerrainMap, x: usize, y: usize) ?*TerrainTile {
        if (x >= self.width or y >= self.height) return null;
        return &self.tiles[y * self.width + x];
    }

    pub fn setTile(self: *TerrainMap, x: usize, y: usize, tile_type: TerrainType, height: f32) void {
        if (x >= self.width or y >= self.height) return;

        self.tiles[y * self.width + x] = TerrainTile.init(tile_type, height);
        self.heightmap.setHeight(x, y, height);
    }

    pub fn isPassable(self: *TerrainMap, x: usize, y: usize) bool {
        if (x >= self.width or y >= self.height) return false;
        return self.tiles[y * self.width + x].passable;
    }

    pub fn addPlayerStart(self: *TerrainMap, position: Vec3) !void {
        if (self.player_start_count >= self.player_starts.len) return error.TooManyPlayerStarts;

        self.player_starts[self.player_start_count] = position;
        self.player_start_count += 1;
    }

    pub fn getPlayerStart(self: *TerrainMap, player_id: usize) ?Vec3 {
        if (player_id >= self.player_start_count) return null;
        return self.player_starts[player_id];
    }

    /// Generate a simple test map
    pub fn generateTestMap(self: *TerrainMap) void {
        // Generate heightmap
        self.heightmap.generateProcedural(12345);

        // Set terrain types based on height
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const height = self.heightmap.getHeight(x, y);

                const terrain_type: TerrainType = if (height < -5.0)
                    .Water
                else if (height < 0.0)
                    .Beach
                else if (height < 5.0)
                    .Grass
                else if (height < 10.0)
                    .Rock
                else
                    .Cliff;

                self.setTile(x, y, terrain_type, height);
            }
        }

        // Add some roads
        for (0..self.width) |x| {
            const y = self.height / 2;
            if (self.getTile(x, y)) |tile| {
                tile.tile_type = .Road;
            }
        }

        // Add player starting positions
        const margin = 10;
        _ = self.addPlayerStart(Vec3.init(
            @as(f32, @floatFromInt(margin)) * self.tile_size,
            0.0,
            @as(f32, @floatFromInt(margin)) * self.tile_size,
        )) catch {};

        _ = self.addPlayerStart(Vec3.init(
            @as(f32, @floatFromInt(self.width - margin)) * self.tile_size,
            0.0,
            @as(f32, @floatFromInt(self.height - margin)) * self.tile_size,
        )) catch {};
    }
};

/// Map file format parser (simplified)
pub const MapLoader = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) MapLoader {
        return MapLoader{ .allocator = allocator };
    }

    /// Load map from file (stub for actual .map format)
    pub fn loadFromFile(self: *MapLoader, file_path: []const u8) !TerrainMap {
        _ = file_path;

        // For now, create a default map
        // In full implementation, would parse binary .map format
        var map = try TerrainMap.init(self.allocator, 128, 128, 10.0, "Test Map");
        map.generateTestMap();

        return map;
    }

    /// Load map from memory
    pub fn loadFromMemory(self: *MapLoader, data: []const u8, map_name: []const u8) !TerrainMap {
        _ = data;

        // Stub: would parse binary map format
        var map = try TerrainMap.init(self.allocator, 128, 128, 10.0, map_name);
        map.generateTestMap();

        return map;
    }
};

/// Terrain rendering manager
pub const TerrainRenderer = struct {
    allocator: std.mem.Allocator,
    current_map: ?*TerrainMap,
    render_distance: f32,
    lod_levels: u32,

    pub fn init(allocator: std.mem.Allocator) TerrainRenderer {
        return TerrainRenderer{
            .allocator = allocator,
            .current_map = null,
            .render_distance = 500.0,
            .lod_levels = 3,
        };
    }

    pub fn deinit(self: *TerrainRenderer) void {
        _ = self;
    }

    pub fn setMap(self: *TerrainRenderer, map: *TerrainMap) void {
        self.current_map = map;
    }

    /// Render terrain (stub - would generate vertex buffers and draw calls)
    pub fn render(self: *TerrainRenderer, camera_pos: Vec3) void {
        if (self.current_map == null) return;

        const map = self.current_map.?;

        // Calculate visible tiles based on camera position
        const min_tile_x: usize = @intFromFloat(@max(0, (camera_pos.x - self.render_distance) / map.tile_size));
        const max_tile_x: usize = @intFromFloat(@min(@as(f32, @floatFromInt(map.width)), (camera_pos.x + self.render_distance) / map.tile_size));
        const min_tile_z: usize = @intFromFloat(@max(0, (camera_pos.z - self.render_distance) / map.tile_size));
        const max_tile_z: usize = @intFromFloat(@min(@as(f32, @floatFromInt(map.height)), (camera_pos.z + self.render_distance) / map.tile_size));

        // In full implementation:
        // 1. Generate terrain mesh vertices and indices
        // 2. Upload to GPU buffers
        // 3. Bind terrain textures
        // 4. Issue draw calls with appropriate LOD

        // For now, just track what would be rendered
        const tiles_rendered = (max_tile_x - min_tile_x) * (max_tile_z - min_tile_z);
        _ = tiles_rendered;
    }

    /// Get render statistics
    pub fn getStats(self: *TerrainRenderer) RenderStats {
        if (self.current_map) |map| {
            return RenderStats{
                .total_tiles = map.width * map.height,
                .visible_tiles = 0, // Would calculate based on frustum culling
                .draw_calls = 1,
                .vertices = map.width * map.height * 4,
                .triangles = map.width * map.height * 2,
            };
        }

        return RenderStats{
            .total_tiles = 0,
            .visible_tiles = 0,
            .draw_calls = 0,
            .vertices = 0,
            .triangles = 0,
        };
    }
};

pub const RenderStats = struct {
    total_tiles: usize,
    visible_tiles: usize,
    draw_calls: usize,
    vertices: usize,
    triangles: usize,
};

// Tests
test "Heightmap creation" {
    const allocator = std.testing.allocator;

    var heightmap = try Heightmap.init(allocator, 64, 64);
    defer heightmap.deinit();

    try std.testing.expect(heightmap.width == 64);
    try std.testing.expect(heightmap.height == 64);

    heightmap.setHeight(10, 10, 5.0);
    try std.testing.expect(heightmap.getHeight(10, 10) == 5.0);
}

test "TerrainMap creation" {
    const allocator = std.testing.allocator;

    var map = try TerrainMap.init(allocator, 128, 128, 10.0, "Test Map");
    defer map.deinit();

    try std.testing.expect(map.width == 128);
    try std.testing.expect(map.height == 128);
    try std.testing.expect(map.tile_size == 10.0);
}

test "Terrain tile passability" {
    const grass_tile = TerrainTile.init(.Grass, 0.0);
    const water_tile = TerrainTile.init(.Water, -5.0);

    try std.testing.expect(grass_tile.passable == true);
    try std.testing.expect(water_tile.passable == false);
}
