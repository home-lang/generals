// Home Language - W3D Loader Module
// Load Westwood 3D model format (.w3d files from C&C Generals)
//
// W3D Format Structure:
// - Hierarchical chunk-based binary format
// - Little-endian byte order
// - Each chunk has: type (4 bytes), size (4 bytes), data (variable)
//
// Based on Thyme engine's W3D implementation

const std = @import("std");
const Allocator = std.mem.Allocator;

// ============================================================================
// W3D Chunk Types
// ============================================================================

pub const ChunkType = enum(u32) {
    // Top-level chunks
    Mesh = 0x00000000,
    Hierarchy = 0x00000100,
    Animation = 0x00000200,
    CompressedAnimation = 0x00000280,
    MorphAnimation = 0x000002C0,
    HLod = 0x00000700,
    Box = 0x00000740,
    HModel = 0x00000300,
    LodModel = 0x00000400,
    Collection = 0x00000420,

    // Mesh chunks
    Vertices = 0x00000002,
    VertexNormals = 0x00000003,
    MeshUserText = 0x0000000C,
    VertexInfluences = 0x0000000E,
    MeshHeader3 = 0x0000001F,
    Triangles = 0x00000020,
    VertexShadeIndices = 0x00000022,
    MaterialInfo = 0x00000028,
    Shaders = 0x00000029,
    VertexMaterials = 0x0000002A,
    VertexMaterial = 0x0000002B,
    VertexMaterialName = 0x0000002C,
    VertexMaterialInfo = 0x0000002D,
    VertexMapperArgs0 = 0x0000002E,
    VertexMapperArgs1 = 0x0000002F,
    Textures = 0x00000030,
    Texture = 0x00000031,
    TextureName = 0x00000032,
    TextureInfo = 0x00000033,
    MaterialPass = 0x00000038,
    VertexMaterialIds = 0x00000039,
    ShaderIds = 0x0000003A,
    Dcg = 0x0000003B,
    Dig = 0x0000003C,
    Scg = 0x0000003E,
    TextureStage = 0x00000048,
    TextureIds = 0x00000049,
    StageTexCoords = 0x0000004A,
    PerFaceTexCoordIds = 0x0000004B,

    // Prelit chunks
    PrelitUnlit = 0x00000023,
    PrelitVertex = 0x00000024,
    PrelitLightmapMultiPass = 0x00000025,
    PrelitLightmapMultiTexture = 0x00000026,

    // Hierarchy chunks
    HierarchyHeader = 0x00000101,
    Pivots = 0x00000102,
    PivotFixups = 0x00000103,

    // Animation chunks
    AnimationHeader = 0x00000201,
    AnimationChannel = 0x00000202,
    BitChannel = 0x00000203,

    // Compressed animation chunks
    CompressedAnimationHeader = 0x00000281,
    CompressedAnimationChannel = 0x00000282,
    CompressedBitChannel = 0x00000283,

    // HLOD chunks
    HLodHeader = 0x00000701,
    HLodLodArray = 0x00000702,
    HLodSubObjectArrayHeader = 0x00000703,
    HLodSubObject = 0x00000704,
    HLodAggregateArray = 0x00000705,
    HLodProxyArray = 0x00000706,

    _,
};

// ============================================================================
// W3D Structures
// ============================================================================

/// W3D chunk header (8 bytes)
pub const ChunkHeader = extern struct {
    chunk_type: u32,
    chunk_size: u32, // Size includes header (8 bytes)

    pub fn read(reader: anytype) !ChunkHeader {
        var header: ChunkHeader = undefined;
        header.chunk_type = try reader.readInt(u32, .little);
        header.chunk_size = try reader.readInt(u32, .little);
        return header;
    }
};

/// W3D vector3 (12 bytes)
pub const Vector3 = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

/// W3D vector2 (8 bytes)
pub const Vector2 = extern struct {
    x: f32,
    y: f32,
};

/// W3D mesh header (140 bytes)
pub const MeshHeader = extern struct {
    version: u32,
    attributes: u32,
    mesh_name: [32]u8,
    container_name: [32]u8,
    num_triangles: u32,
    num_vertices: u32,
    num_materials: u32,
    num_damage_stages: u32,
    sort_level: u32,
    prelighting: u32,
    future_count: u32,
    vertex_channels: u32,
    face_channels: u32,
    min_corner: Vector3,
    max_corner: Vector3,
    sph_center: Vector3,
    sph_radius: f32,

    pub fn read(reader: anytype) !MeshHeader {
        var header: MeshHeader = undefined;
        header.version = try reader.readInt(u32, .little);
        header.attributes = try reader.readInt(u32, .little);

        _ = try reader.readAll(&header.mesh_name);
        _ = try reader.readAll(&header.container_name);

        header.num_triangles = try reader.readInt(u32, .little);
        header.num_vertices = try reader.readInt(u32, .little);
        header.num_materials = try reader.readInt(u32, .little);
        header.num_damage_stages = try reader.readInt(u32, .little);
        header.sort_level = try reader.readInt(u32, .little);
        header.prelighting = try reader.readInt(u32, .little);
        header.future_count = try reader.readInt(u32, .little);
        header.vertex_channels = try reader.readInt(u32, .little);
        header.face_channels = try reader.readInt(u32, .little);

        header.min_corner.x = @bitCast(try reader.readInt(u32, .little));
        header.min_corner.y = @bitCast(try reader.readInt(u32, .little));
        header.min_corner.z = @bitCast(try reader.readInt(u32, .little));

        header.max_corner.x = @bitCast(try reader.readInt(u32, .little));
        header.max_corner.y = @bitCast(try reader.readInt(u32, .little));
        header.max_corner.z = @bitCast(try reader.readInt(u32, .little));

        header.sph_center.x = @bitCast(try reader.readInt(u32, .little));
        header.sph_center.y = @bitCast(try reader.readInt(u32, .little));
        header.sph_center.z = @bitCast(try reader.readInt(u32, .little));

        header.sph_radius = @bitCast(try reader.readInt(u32, .little));

        return header;
    }
};

/// Triangle (3 vertex indices)
pub const Triangle = extern struct {
    vindex: [3]u32,

    pub fn read(reader: anytype) !Triangle {
        var tri: Triangle = undefined;
        tri.vindex[0] = try reader.readInt(u32, .little);
        tri.vindex[1] = try reader.readInt(u32, .little);
        tri.vindex[2] = try reader.readInt(u32, .little);
        return tri;
    }
};

/// RGB color (4 bytes with padding)
pub const RGB = extern struct {
    r: u8,
    g: u8,
    b: u8,
    pad: u8,
};

/// RGBA color (4 bytes)
pub const RGBA = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

/// Quaternion (16 bytes)
pub const Quaternion = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

/// Hierarchy Header (36 bytes)
pub const HierarchyHeader = extern struct {
    version: u32,
    name: [16]u8,
    num_pivots: u32,
    center: Vector3,

    pub fn read(reader: anytype) !HierarchyHeader {
        var header: HierarchyHeader = undefined;
        header.version = try reader.readInt(u32, .little);
        _ = try reader.readAll(&header.name);
        header.num_pivots = try reader.readInt(u32, .little);
        header.center.x = @bitCast(try reader.readInt(u32, .little));
        header.center.y = @bitCast(try reader.readInt(u32, .little));
        header.center.z = @bitCast(try reader.readInt(u32, .little));
        return header;
    }
};

/// Pivot (bone) in hierarchy (64 bytes)
pub const Pivot = extern struct {
    name: [16]u8,
    parent_idx: u32,
    translation: Vector3,
    euler_angles: Vector3,
    rotation: Quaternion,

    pub fn read(reader: anytype) !Pivot {
        var pivot: Pivot = undefined;
        _ = try reader.readAll(&pivot.name);
        pivot.parent_idx = try reader.readInt(u32, .little);
        pivot.translation.x = @bitCast(try reader.readInt(u32, .little));
        pivot.translation.y = @bitCast(try reader.readInt(u32, .little));
        pivot.translation.z = @bitCast(try reader.readInt(u32, .little));
        pivot.euler_angles.x = @bitCast(try reader.readInt(u32, .little));
        pivot.euler_angles.y = @bitCast(try reader.readInt(u32, .little));
        pivot.euler_angles.z = @bitCast(try reader.readInt(u32, .little));
        pivot.rotation.x = @bitCast(try reader.readInt(u32, .little));
        pivot.rotation.y = @bitCast(try reader.readInt(u32, .little));
        pivot.rotation.z = @bitCast(try reader.readInt(u32, .little));
        pivot.rotation.w = @bitCast(try reader.readInt(u32, .little));
        return pivot;
    }
};

/// Vertex influence (skinning weight) (8 bytes)
pub const VertexInfluence = extern struct {
    bone_idx: u16,
    _pad: u16,
    weight: f32,

    pub fn read(reader: anytype) !VertexInfluence {
        var inf: VertexInfluence = undefined;
        inf.bone_idx = try reader.readInt(u16, .little);
        inf._pad = try reader.readInt(u16, .little);
        inf.weight = @bitCast(try reader.readInt(u32, .little));
        return inf;
    }
};

/// Material Info (12 bytes header)
pub const MaterialInfo = extern struct {
    pass_count: u32,
    vert_matl_count: u32,
    shader_count: u32,
    texture_count: u32,

    pub fn read(reader: anytype) !MaterialInfo {
        var info: MaterialInfo = undefined;
        info.pass_count = try reader.readInt(u32, .little);
        info.vert_matl_count = try reader.readInt(u32, .little);
        info.shader_count = try reader.readInt(u32, .little);
        info.texture_count = try reader.readInt(u32, .little);
        return info;
    }
};

/// Vertex Material (48 bytes)
pub const VertexMaterial = extern struct {
    attributes: u32,
    ambient: RGB,
    diffuse: RGB,
    specular: RGB,
    emissive: RGB,
    shininess: f32,
    opacity: f32,
    translucency: f32,

    pub fn read(reader: anytype) !VertexMaterial {
        var mat: VertexMaterial = undefined;
        mat.attributes = try reader.readInt(u32, .little);
        mat.ambient.r = try reader.readByte();
        mat.ambient.g = try reader.readByte();
        mat.ambient.b = try reader.readByte();
        mat.ambient.pad = try reader.readByte();
        mat.diffuse.r = try reader.readByte();
        mat.diffuse.g = try reader.readByte();
        mat.diffuse.b = try reader.readByte();
        mat.diffuse.pad = try reader.readByte();
        mat.specular.r = try reader.readByte();
        mat.specular.g = try reader.readByte();
        mat.specular.b = try reader.readByte();
        mat.specular.pad = try reader.readByte();
        mat.emissive.r = try reader.readByte();
        mat.emissive.g = try reader.readByte();
        mat.emissive.b = try reader.readByte();
        mat.emissive.pad = try reader.readByte();
        mat.shininess = @bitCast(try reader.readInt(u32, .little));
        mat.opacity = @bitCast(try reader.readInt(u32, .little));
        mat.translucency = @bitCast(try reader.readInt(u32, .little));
        return mat;
    }
};

/// Texture Info (20 bytes)
pub const TextureInfo = extern struct {
    attributes: u16,
    animation_type: u16,
    frame_count: u32,
    frame_rate: f32,
    _reserved: [8]u8,

    pub fn read(reader: anytype) !TextureInfo {
        var info: TextureInfo = undefined;
        info.attributes = try reader.readInt(u16, .little);
        info.animation_type = try reader.readInt(u16, .little);
        info.frame_count = try reader.readInt(u32, .little);
        info.frame_rate = @bitCast(try reader.readInt(u32, .little));
        _ = try reader.readAll(&info._reserved);
        return info;
    }
};

// ============================================================================
// W3D Model
// ============================================================================

/// Hierarchy data (bones/skeleton)
pub const W3DHierarchy = struct {
    header: HierarchyHeader,
    pivots: []Pivot,
};

/// Texture data
pub const W3DTexture = struct {
    name: []u8,
    info: ?TextureInfo,
};

/// Vertex material data
pub const W3DVertexMaterial = struct {
    name: []u8,
    material: VertexMaterial,
    mapper_args0: ?[]u8,
    mapper_args1: ?[]u8,
};

pub const W3DModel = struct {
    allocator: Allocator,

    // Mesh data
    header: MeshHeader,
    vertices: []Vector3,
    normals: []Vector3,
    uvs: []Vector2,
    indices: []u32,
    vertex_colors: []RGBA,
    name: []u8,

    // Hierarchy (bones)
    hierarchy: ?W3DHierarchy,
    vertex_influences: []VertexInfluence,

    // Materials and textures
    material_info: ?MaterialInfo,
    vertex_materials: []W3DVertexMaterial,
    textures: []W3DTexture,

    pub fn loadFromFile(allocator: Allocator, path: []const u8) !W3DModel {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const data = try allocator.alloc(u8, file_size);
        defer allocator.free(data);

        const bytes_read = try file.read(data);
        if (bytes_read != file_size) return error.UnexpectedEof;

        return try loadFromBytes(allocator, data);
    }

    pub fn loadFromBytes(allocator: Allocator, data: []const u8) !W3DModel {
        var stream = std.io.fixedBufferStream(data);
        return try loadFromReader(allocator, stream.reader());
    }

    fn loadFromReader(allocator: Allocator, reader: anytype) !W3DModel {
        var model = W3DModel{
            .allocator = allocator,
            .header = undefined,
            .vertices = &.{},
            .normals = &.{},
            .uvs = &.{},
            .indices = &.{},
            .vertex_colors = &.{},
            .name = &.{},
            .hierarchy = null,
            .vertex_influences = &.{},
            .material_info = null,
            .vertex_materials = &.{},
            .textures = &.{},
        };
        errdefer model.deinit();

        // Read root chunk header
        const root_header = try ChunkHeader.read(reader);
        if (root_header.chunk_type != @intFromEnum(ChunkType.Mesh)) {
            return error.InvalidW3DFile;
        }

        const end_pos = try reader.context.getPos() + root_header.chunk_size - 8;

        // Parse mesh chunks
        while ((try reader.context.getPos()) < end_pos) {
            const chunk_header = try ChunkHeader.read(reader);
            const chunk_type: ChunkType = @enumFromInt(chunk_header.chunk_type);
            const data_size = chunk_header.chunk_size - 8;

            switch (chunk_type) {
                .MeshHeader3 => {
                    model.header = try MeshHeader.read(reader);

                    // Extract mesh name
                    const name_len = std.mem.indexOfScalar(u8, &model.header.mesh_name, 0) orelse 32;
                    model.name = try allocator.dupe(u8, model.header.mesh_name[0..name_len]);
                },

                .Vertices => {
                    const num_verts = data_size / 12;
                    model.vertices = try allocator.alloc(Vector3, num_verts);

                    for (model.vertices) |*vertex| {
                        vertex.* = try readVector3(reader);
                    }
                },

                .VertexNormals => {
                    const num_normals = data_size / 12;
                    model.normals = try allocator.alloc(Vector3, num_normals);

                    for (model.normals) |*normal| {
                        normal.* = try readVector3(reader);
                    }
                },

                .Triangles => {
                    const num_triangles = data_size / 12;
                    model.indices = try allocator.alloc(u32, num_triangles * 3);

                    var idx: usize = 0;
                    var i: usize = 0;
                    while (i < num_triangles) : (i += 1) {
                        const tri = try Triangle.read(reader);
                        model.indices[idx + 0] = tri.vindex[0];
                        model.indices[idx + 1] = tri.vindex[1];
                        model.indices[idx + 2] = tri.vindex[2];
                        idx += 3;
                    }
                },

                .VertexInfluences => {
                    const num_influences = data_size / 8;
                    model.vertex_influences = try allocator.alloc(VertexInfluence, num_influences);

                    for (model.vertex_influences) |*influence| {
                        influence.* = try VertexInfluence.read(reader);
                    }
                },

                .MaterialInfo => {
                    model.material_info = try MaterialInfo.read(reader);
                    // Note: The actual pass_count is stored, but we skip the rest
                    // Material passes are in separate chunks
                },

                .Textures => {
                    // This is a wrapper chunk, contains nested Texture chunks
                    const textures_end = try reader.context.getPos() + data_size;
                    var texture_list = std.ArrayList(W3DTexture).init(allocator);

                    while ((try reader.context.getPos()) < textures_end) {
                        const tex_header = try ChunkHeader.read(reader);
                        const tex_type: ChunkType = @enumFromInt(tex_header.chunk_type);
                        const tex_data_size = tex_header.chunk_size - 8;

                        if (tex_type == .Texture) {
                            // Parse individual texture
                            const tex_end = try reader.context.getPos() + tex_data_size;
                            var texture = W3DTexture{
                                .name = &.{},
                                .info = null,
                            };

                            while ((try reader.context.getPos()) < tex_end) {
                                const tex_sub_header = try ChunkHeader.read(reader);
                                const tex_sub_type: ChunkType = @enumFromInt(tex_sub_header.chunk_type);
                                const tex_sub_size = tex_sub_header.chunk_size - 8;

                                switch (tex_sub_type) {
                                    .TextureName => {
                                        var name_buf: [256]u8 = undefined;
                                        const bytes_read = try reader.readAll(name_buf[0..tex_sub_size]);
                                        const name_len = std.mem.indexOfScalar(u8, name_buf[0..bytes_read], 0) orelse bytes_read;
                                        texture.name = try allocator.dupe(u8, name_buf[0..name_len]);
                                    },
                                    .TextureInfo => {
                                        texture.info = try TextureInfo.read(reader);
                                    },
                                    else => {
                                        try reader.context.seekBy(@intCast(tex_sub_size));
                                    },
                                }
                            }

                            try texture_list.append(texture);
                        } else {
                            try reader.context.seekBy(@intCast(tex_data_size));
                        }
                    }

                    model.textures = try texture_list.toOwnedSlice();
                },

                .VertexMapperArgs0, .StageTexCoords => {
                    // These are UV coordinates
                    const num_uvs = data_size / 8;
                    model.uvs = try allocator.alloc(Vector2, num_uvs);

                    for (model.uvs) |*uv| {
                        uv.* = try readVector2(reader);
                    }
                },

                .Dcg => {
                    // Diffuse vertex colors (RGBA)
                    const num_colors = data_size / 4;
                    model.vertex_colors = try allocator.alloc(RGBA, num_colors);

                    for (model.vertex_colors) |*color| {
                        color.r = try reader.readByte();
                        color.g = try reader.readByte();
                        color.b = try reader.readByte();
                        color.a = try reader.readByte();
                    }
                },

                else => {
                    // Skip unknown chunks (there are many we don't need yet)
                    try reader.context.seekBy(@intCast(data_size));
                },
            }
        }

        // Validate model data
        if (model.vertices.len == 0) {
            return error.NoVertexData;
        }
        if (model.indices.len == 0) {
            return error.NoIndexData;
        }

        return model;
    }

    pub fn deinit(self: *W3DModel) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.normals);
        self.allocator.free(self.uvs);
        self.allocator.free(self.indices);
        self.allocator.free(self.vertex_colors);
        self.allocator.free(self.name);
        self.allocator.free(self.vertex_influences);

        // Free hierarchy
        if (self.hierarchy) |hier| {
            self.allocator.free(hier.pivots);
        }

        // Free textures
        for (self.textures) |texture| {
            self.allocator.free(texture.name);
        }
        self.allocator.free(self.textures);

        // Free vertex materials
        for (self.vertex_materials) |mat| {
            self.allocator.free(mat.name);
            if (mat.mapper_args0) |args| self.allocator.free(args);
            if (mat.mapper_args1) |args| self.allocator.free(args);
        }
        self.allocator.free(self.vertex_materials);
    }

    pub fn getVertexCount(self: *const W3DModel) usize {
        return self.vertices.len;
    }

    pub fn getTriangleCount(self: *const W3DModel) usize {
        return self.indices.len / 3;
    }

    pub fn hasNormals(self: *const W3DModel) bool {
        return self.normals.len > 0;
    }

    pub fn hasUVs(self: *const W3DModel) bool {
        return self.uvs.len > 0;
    }

    pub fn getMeshName(self: *const W3DModel) []const u8 {
        return self.name;
    }
};

// ============================================================================
// Helper Functions
// ============================================================================

fn readVector3(reader: anytype) !Vector3 {
    var vec: Vector3 = undefined;
    vec.x = @bitCast(try reader.readInt(u32, .little));
    vec.y = @bitCast(try reader.readInt(u32, .little));
    vec.z = @bitCast(try reader.readInt(u32, .little));
    return vec;
}

fn readVector2(reader: anytype) !Vector2 {
    var vec: Vector2 = undefined;
    vec.x = @bitCast(try reader.readInt(u32, .little));
    vec.y = @bitCast(try reader.readInt(u32, .little));
    return vec;
}

// ============================================================================
// Tests
// ============================================================================

test "ChunkHeader size" {
    const testing = std.testing;
    try testing.expectEqual(@as(usize, 8), @sizeOf(ChunkHeader));
}

test "MeshHeader size" {
    const testing = std.testing;
    try testing.expectEqual(@as(usize, 140), @sizeOf(MeshHeader));
}

test "Triangle size" {
    const testing = std.testing;
    try testing.expectEqual(@as(usize, 12), @sizeOf(Triangle));
}

test "Vector3 conversion" {
    const testing = std.testing;
    const v = Vector3{ .x = 1.0, .y = 2.0, .z = 3.0 };
    const v3d = v.toMath3D();
    try testing.expectEqual(@as(f32, 1.0), v3d.x);
    try testing.expectEqual(@as(f32, 2.0), v3d.y);
    try testing.expectEqual(@as(f32, 3.0), v3d.z);
}
