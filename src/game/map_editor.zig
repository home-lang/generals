// Home Programming Language - Visual Map Editor
// In-game map editor for terrain, objects, and lighting
//
// Features:
// - Terrain height painting
// - Texture splatting
// - Object placement (buildings, trees, rocks)
// - Lighting setup
// - Waypoint editing
// - Export to game map format

const std = @import("std");
const gl = @import("opengl.zig");
const input = @import("input.zig");

// ============================================================================
// Map Data Structures
// ============================================================================

pub const TerrainTile = struct {
    height: f32,
    texture_indices: [4]u8, // Up to 4 blend textures
    texture_weights: [4]f32, // Blending weights
    walkable: bool,
    water: bool,

    pub fn init() TerrainTile {
        return TerrainTile{
            .height = 0,
            .texture_indices = [_]u8{0} ** 4,
            .texture_weights = [_]f32{ 1, 0, 0, 0 },
            .walkable = true,
            .water = false,
        };
    }
};

pub const MapObject = struct {
    id: u32,
    object_type: []const u8,
    position: @Vector(3, f32),
    rotation: f32,
    scale: f32,
    properties: std.StringHashMap([]const u8),

    pub fn init(allocator: std.mem.Allocator, object_type: []const u8) MapObject {
        return MapObject{
            .id = 0,
            .object_type = object_type,
            .position = @Vector(3, f32){ 0, 0, 0 },
            .rotation = 0,
            .scale = 1,
            .properties = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *MapObject) void {
        self.properties.deinit();
    }
};

pub const EditorMap = struct {
    width: u32,
    height: u32,
    tile_size: f32,
    tiles: []TerrainTile,
    objects: std.ArrayList(MapObject),
    name: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32, tile_size: f32) !EditorMap {
        const tiles = try allocator.alloc(TerrainTile, width * height);
        for (tiles) |*tile| {
            tile.* = TerrainTile.init();
        }

        return EditorMap{
            .width = width,
            .height = height,
            .tile_size = tile_size,
            .tiles = tiles,
            .objects = std.ArrayList(MapObject).init(allocator),
            .name = "Untitled Map",
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *EditorMap) void {
        self.allocator.free(self.tiles);
        for (self.objects.items) |*obj| {
            obj.deinit();
        }
        self.objects.deinit();
    }

    pub fn getTile(self: *EditorMap, x: u32, y: u32) ?*TerrainTile {
        if (x >= self.width or y >= self.height) return null;
        return &self.tiles[y * self.width + x];
    }

    pub fn addObject(self: *EditorMap, object: MapObject) !u32 {
        var obj = object;
        obj.id = @intCast(self.objects.items.len);
        try self.objects.append(obj);
        return obj.id;
    }

    pub fn removeObject(self: *EditorMap, id: u32) void {
        for (self.objects.items, 0..) |obj, i| {
            if (obj.id == id) {
                var removed = self.objects.orderedRemove(i);
                removed.deinit();
                return;
            }
        }
    }

    pub fn save(self: *const EditorMap, path: []const u8) !void {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        var writer = file.writer();

        // Write header
        try writer.writeAll("GENERALSMAP\n");
        try writer.writeInt(u32, self.width, .little);
        try writer.writeInt(u32, self.height, .little);
        try writer.writeAll(std.mem.asBytes(&self.tile_size));

        // Write terrain data
        for (self.tiles) |tile| {
            try writer.writeAll(std.mem.asBytes(&tile));
        }

        // Write objects
        try writer.writeInt(u32, @intCast(self.objects.items.len), .little);
        for (self.objects.items) |obj| {
            try writer.writeInt(u32, obj.id, .little);
            try writer.writeInt(u32, @intCast(obj.object_type.len), .little);
            try writer.writeAll(obj.object_type);
            try writer.writeAll(std.mem.asBytes(&obj.position));
            try writer.writeAll(std.mem.asBytes(&obj.rotation));
            try writer.writeAll(std.mem.asBytes(&obj.scale));
        }
    }
};

// ============================================================================
// Editor Tools
// ============================================================================

pub const EditorTool = enum {
    Select,
    HeightRaise,
    HeightLower,
    HeightSmooth,
    TexturePaint,
    ObjectPlace,
    ObjectRemove,
    WaypointPlace,
};

pub const BrushSettings = struct {
    size: f32,
    strength: f32,
    falloff: f32,

    pub fn default() BrushSettings {
        return BrushSettings{
            .size = 5.0,
            .strength = 1.0,
            .falloff = 0.5,
        };
    }
};

pub const MapEditor = struct {
    map: EditorMap,
    current_tool: EditorTool,
    brush_settings: BrushSettings,
    selected_texture: u8,
    selected_object_type: []const u8,
    selected_object: ?u32,
    camera_position: @Vector(3, f32),
    camera_rotation: @Vector(2, f32),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, map_width: u32, map_height: u32) !MapEditor {
        return MapEditor{
            .map = try EditorMap.init(allocator, map_width, map_height, 1.0),
            .current_tool = .Select,
            .brush_settings = BrushSettings.default(),
            .selected_texture = 0,
            .selected_object_type = "tree",
            .selected_object = null,
            .camera_position = @Vector(3, f32){ 0, 50, 50 },
            .camera_rotation = @Vector(2, f32){ -45, 0 },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *MapEditor) void {
        self.map.deinit();
    }

    pub fn setTool(self: *MapEditor, tool: EditorTool) void {
        self.current_tool = tool;
    }

    pub fn handleInput(self: *MapEditor, input_state: *const input.InputState) void {
        // Camera movement
        if (input_state.isKeyDown(.W)) {
            self.camera_position[2] -= 1.0;
        }
        if (input_state.isKeyDown(.S)) {
            self.camera_position[2] += 1.0;
        }
        if (input_state.isKeyDown(.A)) {
            self.camera_position[0] -= 1.0;
        }
        if (input_state.isKeyDown(.D)) {
            self.camera_position[0] += 1.0;
        }

        // Tool selection
        if (input_state.isKeyPressed(.Num1)) self.setTool(.Select);
        if (input_state.isKeyPressed(.Num2)) self.setTool(.HeightRaise);
        if (input_state.isKeyPressed(.Num3)) self.setTool(.HeightLower);
        if (input_state.isKeyPressed(.Num4)) self.setTool(.TexturePaint);
        if (input_state.isKeyPressed(.Num5)) self.setTool(.ObjectPlace);

        // Apply tool
        if (input_state.isMouseButtonDown(.Left)) {
            const mouse_pos = input_state.getMousePosition();
            self.applyTool(mouse_pos.x, mouse_pos.y);
        }
    }

    fn applyTool(self: *MapEditor, mouse_x: f32, mouse_y: f32) void {
        // Convert mouse position to world position (ray cast)
        const world_pos = self.screenToWorld(mouse_x, mouse_y);

        // Convert to tile coordinates
        const tile_x = @as(u32, @intFromFloat(world_pos[0] / self.map.tile_size));
        const tile_y = @as(u32, @intFromFloat(world_pos[2] / self.map.tile_size));

        switch (self.current_tool) {
            .HeightRaise => {
                self.modifyHeight(tile_x, tile_y, self.brush_settings.strength);
            },
            .HeightLower => {
                self.modifyHeight(tile_x, tile_y, -self.brush_settings.strength);
            },
            .HeightSmooth => {
                self.smoothHeight(tile_x, tile_y);
            },
            .TexturePaint => {
                self.paintTexture(tile_x, tile_y, self.selected_texture);
            },
            .ObjectPlace => {
                self.placeObject(world_pos);
            },
            else => {},
        }
    }

    fn modifyHeight(self: *MapEditor, center_x: u32, center_y: u32, amount: f32) void {
        const brush_radius = @as(u32, @intFromFloat(self.brush_settings.size));

        var y: i32 = @as(i32, @intCast(center_y)) - @as(i32, @intCast(brush_radius));
        while (y <= @as(i32, @intCast(center_y)) + @as(i32, @intCast(brush_radius))) : (y += 1) {
            var x: i32 = @as(i32, @intCast(center_x)) - @as(i32, @intCast(brush_radius));
            while (x <= @as(i32, @intCast(center_x)) + @as(i32, @intCast(brush_radius))) : (x += 1) {
                if (x < 0 or y < 0) continue;

                if (self.map.getTile(@intCast(x), @intCast(y))) |tile| {
                    const dx = @as(f32, @floatFromInt(x)) - @as(f32, @floatFromInt(center_x));
                    const dy = @as(f32, @floatFromInt(y)) - @as(f32, @floatFromInt(center_y));
                    const distance = @sqrt(dx * dx + dy * dy);

                    if (distance <= self.brush_settings.size) {
                        const falloff = 1.0 - (distance / self.brush_settings.size) * self.brush_settings.falloff;
                        tile.height += amount * falloff;
                    }
                }
            }
        }
    }

    fn smoothHeight(self: *MapEditor, center_x: u32, center_y: u32) void {
        // Average surrounding heights
        var sum: f32 = 0;
        var count: u32 = 0;

        const neighbors = [_]struct { dx: i32, dy: i32 }{
            .{ .dx = -1, .dy = 0 },
            .{ .dx = 1, .dy = 0 },
            .{ .dx = 0, .dy = -1 },
            .{ .dx = 0, .dy = 1 },
        };

        for (neighbors) |n| {
            const nx = @as(i32, @intCast(center_x)) + n.dx;
            const ny = @as(i32, @intCast(center_y)) + n.dy;
            if (nx < 0 or ny < 0) continue;

            if (self.map.getTile(@intCast(nx), @intCast(ny))) |tile| {
                sum += tile.height;
                count += 1;
            }
        }

        if (count > 0 and self.map.getTile(center_x, center_y)) |center_tile| {
            const average = sum / @as(f32, @floatFromInt(count));
            center_tile.height += (average - center_tile.height) * 0.5;
        }
    }

    fn paintTexture(self: *MapEditor, tile_x: u32, tile_y: u32, texture_index: u8) void {
        if (self.map.getTile(tile_x, tile_y)) |tile| {
            tile.texture_indices[0] = texture_index;
            tile.texture_weights[0] = 1.0;
            tile.texture_weights[1] = 0.0;
            tile.texture_weights[2] = 0.0;
            tile.texture_weights[3] = 0.0;
        }
    }

    fn placeObject(self: *MapEditor, position: @Vector(3, f32)) void {
        var obj = MapObject.init(self.allocator, self.selected_object_type);
        obj.position = position;
        _ = self.map.addObject(obj) catch {};
    }

    fn screenToWorld(self: *const MapEditor, screen_x: f32, screen_y: f32) @Vector(3, f32) {
        // Simple orthographic projection
        _ = screen_y;
        return @Vector(3, f32){
            screen_x + self.camera_position[0],
            0,
            self.camera_position[2],
        };
    }

    pub fn render(self: *MapEditor) void {
        // Render terrain
        self.renderTerrain();

        // Render objects
        self.renderObjects();

        // Render brush preview
        self.renderBrush();
    }

    fn renderTerrain(self: *MapEditor) void {
        _ = self;
        // TODO: OpenGL terrain rendering
    }

    fn renderObjects(self: *MapEditor) void {
        _ = self;
        // TODO: Render placed objects
    }

    fn renderBrush(self: *MapEditor) void {
        _ = self;
        // TODO: Render brush circle at mouse position
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EditorMap creation" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = try EditorMap.init(allocator, 64, 64, 1.0);
    defer map.deinit();

    try testing.expectEqual(@as(u32, 64), map.width);
    try testing.expectEqual(@as(u32, 64), map.height);
    try testing.expectEqual(@as(usize, 64 * 64), map.tiles.len);
}

test "Tile access" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var map = try EditorMap.init(allocator, 10, 10, 1.0);
    defer map.deinit();

    const tile = map.getTile(5, 5).?;
    tile.height = 10.0;

    try testing.expectEqual(@as(f32, 10.0), map.getTile(5, 5).?.height);
}
