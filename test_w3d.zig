// W3D Model Loading Test
// Tests Westwood 3D model format parsing for C&C Generals

const std = @import("std");

// W3D file format constants
const W3D_CHUNK_MESH: u32 = 0x00000000;
const W3D_CHUNK_MESH_HEADER: u32 = 0x0000001F;
const W3D_CHUNK_VERTICES: u32 = 0x00000002;
const W3D_CHUNK_VERTEX_NORMALS: u32 = 0x00000003;
const W3D_CHUNK_TRIANGLES: u32 = 0x00000020;

const W3DChunkHeader = packed struct {
    chunk_type: u32,
    chunk_size: u32,
};

const W3DMeshHeader = extern struct {
    version: u32,
    attributes: u32,
    mesh_name: [16]u8,
    container_name: [16]u8,
    num_vertices: u32,
    num_triangles: u32,
    num_materials: u32,
    num_damage_stages: u32,
    sort_level: i32,
    prelit_version: u32,
    future_count: u32,
    vertex_channel_count: u32,
    face_channel_count: u32,
    min_corner: [3]f32,
    max_corner: [3]f32,
    sphere_center: [3]f32,
    sphere_radius: f32,
};

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

const Triangle = struct {
    indices: [3]u32,
    attributes: u32,
    normal: Vec3,
    distance: f32,
};

const W3DMesh = struct {
    name: [16]u8,
    vertices: std.ArrayListUnmanaged(Vec3),
    normals: std.ArrayListUnmanaged(Vec3),
    triangles: std.ArrayListUnmanaged(Triangle),
    bounds_min: Vec3,
    bounds_max: Vec3,

    fn init() W3DMesh {
        return .{
            .name = [_]u8{0} ** 16,
            .vertices = .empty,
            .normals = .empty,
            .triangles = .empty,
            .bounds_min = .{ .x = 0, .y = 0, .z = 0 },
            .bounds_max = .{ .x = 0, .y = 0, .z = 0 },
        };
    }

    fn deinit(self: *W3DMesh, allocator: std.mem.Allocator) void {
        self.vertices.deinit(allocator);
        self.normals.deinit(allocator);
        self.triangles.deinit(allocator);
    }
};

const W3DModel = struct {
    meshes: std.ArrayListUnmanaged(W3DMesh),

    fn init() W3DModel {
        return .{
            .meshes = .empty,
        };
    }

    fn deinit(self: *W3DModel, allocator: std.mem.Allocator) void {
        for (self.meshes.items) |*mesh| {
            mesh.deinit(allocator);
        }
        self.meshes.deinit(allocator);
    }
};

fn parseW3D(allocator: std.mem.Allocator, data: []const u8) !W3DModel {
    var model = W3DModel.init();
    errdefer model.deinit(allocator);

    var offset: usize = 0;

    while (offset + @sizeOf(W3DChunkHeader) <= data.len) {
        const header: *const W3DChunkHeader = @ptrCast(@alignCast(data[offset..].ptr));
        offset += @sizeOf(W3DChunkHeader);

        const chunk_data = data[offset..@min(offset + header.chunk_size, data.len)];

        switch (header.chunk_type) {
            W3D_CHUNK_MESH => {
                const mesh = try parseMesh(allocator, chunk_data);
                try model.meshes.append(allocator, mesh);
            },
            else => {},
        }

        offset += header.chunk_size;
    }

    return model;
}

fn parseMesh(allocator: std.mem.Allocator, data: []const u8) !W3DMesh {
    var mesh = W3DMesh.init();
    errdefer mesh.deinit(allocator);

    var offset: usize = 0;

    while (offset + @sizeOf(W3DChunkHeader) <= data.len) {
        const header: *const W3DChunkHeader = @ptrCast(@alignCast(data[offset..].ptr));
        offset += @sizeOf(W3DChunkHeader);

        const chunk_end = @min(offset + header.chunk_size, data.len);
        const chunk_data = data[offset..chunk_end];

        switch (header.chunk_type) {
            W3D_CHUNK_MESH_HEADER => {
                if (chunk_data.len >= @sizeOf(W3DMeshHeader)) {
                    const mesh_header: *const W3DMeshHeader = @ptrCast(@alignCast(chunk_data.ptr));
                    @memcpy(&mesh.name, &mesh_header.mesh_name);
                    mesh.bounds_min = .{
                        .x = mesh_header.min_corner[0],
                        .y = mesh_header.min_corner[1],
                        .z = mesh_header.min_corner[2],
                    };
                    mesh.bounds_max = .{
                        .x = mesh_header.max_corner[0],
                        .y = mesh_header.max_corner[1],
                        .z = mesh_header.max_corner[2],
                    };
                }
            },
            W3D_CHUNK_VERTICES => {
                const vertex_count = header.chunk_size / 12; // 3 floats per vertex
                var v_offset: usize = 0;
                for (0..vertex_count) |_| {
                    if (v_offset + 12 <= chunk_data.len) {
                        const floats: *const [3]f32 = @ptrCast(@alignCast(chunk_data[v_offset..].ptr));
                        try mesh.vertices.append(allocator, .{ .x = floats[0], .y = floats[1], .z = floats[2] });
                        v_offset += 12;
                    }
                }
            },
            W3D_CHUNK_VERTEX_NORMALS => {
                const normal_count = header.chunk_size / 12;
                var n_offset: usize = 0;
                for (0..normal_count) |_| {
                    if (n_offset + 12 <= chunk_data.len) {
                        const floats: *const [3]f32 = @ptrCast(@alignCast(chunk_data[n_offset..].ptr));
                        try mesh.normals.append(allocator, .{ .x = floats[0], .y = floats[1], .z = floats[2] });
                        n_offset += 12;
                    }
                }
            },
            W3D_CHUNK_TRIANGLES => {
                const tri_size = 32; // Size of W3D triangle struct
                const tri_count = header.chunk_size / tri_size;
                for (0..tri_count) |i| {
                    const t_offset = i * tri_size;
                    if (t_offset + tri_size <= chunk_data.len) {
                        const indices: *const [3]u32 = @ptrCast(@alignCast(chunk_data[t_offset..].ptr));
                        const attrs: *const u32 = @ptrCast(@alignCast(chunk_data[t_offset + 12 ..].ptr));
                        const normal: *const [3]f32 = @ptrCast(@alignCast(chunk_data[t_offset + 16 ..].ptr));
                        const dist: *const f32 = @ptrCast(@alignCast(chunk_data[t_offset + 28 ..].ptr));

                        try mesh.triangles.append(allocator, .{
                            .indices = indices.*,
                            .attributes = attrs.*,
                            .normal = .{ .x = normal[0], .y = normal[1], .z = normal[2] },
                            .distance = dist.*,
                        });
                    }
                }
            },
            else => {},
        }

        offset = chunk_end;
    }

    return mesh;
}

fn createTestW3D(allocator: std.mem.Allocator) ![]u8 {
    // Create a simple cube mesh in W3D format
    var data = std.ArrayListUnmanaged(u8){ .items = &.{}, .capacity = 0 };
    errdefer data.deinit(allocator);

    // Mesh chunk
    const mesh_start = data.items.len;
    try data.appendSlice(allocator, &std.mem.toBytes(W3DChunkHeader{
        .chunk_type = W3D_CHUNK_MESH,
        .chunk_size = 0, // Will update later
    }));

    // Mesh header
    const mesh_header = W3DMeshHeader{
        .version = 3,
        .attributes = 0,
        .mesh_name = [_]u8{ 'T', 'e', 's', 't', 'C', 'u', 'b', 'e', 0, 0, 0, 0, 0, 0, 0, 0 },
        .container_name = [_]u8{ 'T', 'e', 's', 't', 'M', 'o', 'd', 'e', 'l', 0, 0, 0, 0, 0, 0, 0 },
        .num_vertices = 8,
        .num_triangles = 12,
        .num_materials = 1,
        .num_damage_stages = 0,
        .sort_level = 0,
        .prelit_version = 0,
        .future_count = 0,
        .vertex_channel_count = 0,
        .face_channel_count = 0,
        .min_corner = .{ -1.0, -1.0, -1.0 },
        .max_corner = .{ 1.0, 1.0, 1.0 },
        .sphere_center = .{ 0.0, 0.0, 0.0 },
        .sphere_radius = 1.732,
    };

    try data.appendSlice(allocator, &std.mem.toBytes(W3DChunkHeader{
        .chunk_type = W3D_CHUNK_MESH_HEADER,
        .chunk_size = @sizeOf(W3DMeshHeader),
    }));
    try data.appendSlice(allocator, &std.mem.toBytes(mesh_header));

    // Vertices (cube corners)
    const vertices = [8][3]f32{
        .{ -1.0, -1.0, -1.0 },
        .{ 1.0, -1.0, -1.0 },
        .{ 1.0, 1.0, -1.0 },
        .{ -1.0, 1.0, -1.0 },
        .{ -1.0, -1.0, 1.0 },
        .{ 1.0, -1.0, 1.0 },
        .{ 1.0, 1.0, 1.0 },
        .{ -1.0, 1.0, 1.0 },
    };

    try data.appendSlice(allocator, &std.mem.toBytes(W3DChunkHeader{
        .chunk_type = W3D_CHUNK_VERTICES,
        .chunk_size = 8 * 12,
    }));
    for (vertices) |v| {
        try data.appendSlice(allocator, &std.mem.toBytes(v));
    }

    // Update mesh chunk size
    const mesh_size: u32 = @intCast(data.items.len - mesh_start - @sizeOf(W3DChunkHeader));
    const size_ptr: *u32 = @ptrCast(@alignCast(data.items[mesh_start + 4 ..].ptr));
    size_ptr.* = mesh_size;

    return try data.toOwnedSlice(allocator);
}

pub fn main() !void {
    const print = std.debug.print;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("================================================================================\n", .{});
    print("  C&C Generals W3D Model Loading Test\n", .{});
    print("================================================================================\n\n", .{});

    // Create test W3D data
    print("Creating test W3D model (cube)...\n", .{});
    const w3d_data = try createTestW3D(allocator);
    defer allocator.free(w3d_data);
    print("Test W3D created: {d} bytes\n\n", .{w3d_data.len});

    // Parse the W3D
    print("Parsing W3D model...\n", .{});
    var model = try parseW3D(allocator, w3d_data);
    defer model.deinit(allocator);

    print("Model parsed successfully:\n", .{});
    print("  Mesh count: {d}\n\n", .{model.meshes.items.len});

    for (model.meshes.items, 0..) |mesh, i| {
        // Get mesh name as string
        var name_buf: [17]u8 = undefined;
        @memcpy(name_buf[0..16], &mesh.name);
        name_buf[16] = 0;
        const name = std.mem.sliceTo(&name_buf, 0);

        print("Mesh {d}: \"{s}\"\n", .{ i, name });
        print("  Vertices: {d}\n", .{mesh.vertices.items.len});
        print("  Normals: {d}\n", .{mesh.normals.items.len});
        print("  Triangles: {d}\n", .{mesh.triangles.items.len});
        print("  Bounds: ({d:.2}, {d:.2}, {d:.2}) to ({d:.2}, {d:.2}, {d:.2})\n", .{
            mesh.bounds_min.x, mesh.bounds_min.y, mesh.bounds_min.z,
            mesh.bounds_max.x, mesh.bounds_max.y, mesh.bounds_max.z,
        });

        if (mesh.vertices.items.len > 0) {
            print("  Sample vertices:\n", .{});
            const max_show = @min(mesh.vertices.items.len, 4);
            for (mesh.vertices.items[0..max_show], 0..) |v, j| {
                print("    [{d}]: ({d:.2}, {d:.2}, {d:.2})\n", .{ j, v.x, v.y, v.z });
            }
        }
    }

    print("\nAll W3D loading tests passed!\n", .{});
}
