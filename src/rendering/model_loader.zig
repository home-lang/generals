// C&C Generals - 3D Model Loader
// Supports W3D (Westwood 3D) format and animations

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

    pub fn zero() Vec3 {
        return Vec3.init(0, 0, 0);
    }
};

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Mat4 = struct {
    data: [16]f32,

    pub fn identity() Mat4 {
        return Mat4{
            .data = [_]f32{
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            },
        };
    }
};

/// Vertex structure
pub const Vertex = struct {
    position: Vec3,
    normal: Vec3,
    tex_coord: Vec2,
    bone_indices: [4]u8,
    bone_weights: [4]f32,

    pub fn init(pos: Vec3) Vertex {
        return Vertex{
            .position = pos,
            .normal = Vec3.init(0, 1, 0),
            .tex_coord = Vec2{ .x = 0, .y = 0 },
            .bone_indices = [_]u8{ 0, 0, 0, 0 },
            .bone_weights = [_]f32{ 1.0, 0, 0, 0 },
        };
    }
};

/// Mesh LOD (Level of Detail)
pub const MeshLOD = struct {
    vertices: []Vertex,
    indices: []u32,
    material_id: u32,
    lod_level: u32,

    pub fn deinit(self: *MeshLOD, allocator: std.mem.Allocator) void {
        allocator.free(self.vertices);
        allocator.free(self.indices);
    }
};

/// Mesh with multiple LODs
pub const Mesh = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    lods: []MeshLOD,
    lod_count: usize,
    bounds_min: Vec3,
    bounds_max: Vec3,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, max_lods: usize) !Mesh {
        const lods = try allocator.alloc(MeshLOD, max_lods);

        return Mesh{
            .allocator = allocator,
            .name = name,
            .lods = lods,
            .lod_count = 0,
            .bounds_min = Vec3.zero(),
            .bounds_max = Vec3.zero(),
        };
    }

    pub fn deinit(self: *Mesh) void {
        for (self.lods[0..self.lod_count]) |*lod| {
            lod.deinit(self.allocator);
        }
        self.allocator.free(self.lods);
    }

    pub fn addLOD(self: *Mesh, lod: MeshLOD) !void {
        if (self.lod_count >= self.lods.len) return error.TooManyLODs;
        self.lods[self.lod_count] = lod;
        self.lod_count += 1;
    }

    pub fn getLOD(self: *Mesh, distance: f32) *MeshLOD {
        // Select LOD based on distance
        const lod_index = if (distance < 50.0)
            0
        else if (distance < 150.0)
            @min(1, self.lod_count - 1)
        else
            @min(2, self.lod_count - 1);

        return &self.lods[@min(lod_index, self.lod_count - 1)];
    }
};

/// Bone for skeletal animation
pub const Bone = struct {
    name: []const u8,
    parent_index: i32,
    local_transform: Mat4,
    inverse_bind_pose: Mat4,
};

/// Animation keyframe
pub const Keyframe = struct {
    time: f32,
    position: Vec3,
    rotation: Vec4, // Quaternion
    scale: Vec3,
};

/// Animation channel for a single bone
pub const AnimationChannel = struct {
    bone_index: usize,
    position_keys: []Keyframe,
    rotation_keys: []Keyframe,
    scale_keys: []Keyframe,
    key_count: usize,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *AnimationChannel) void {
        self.allocator.free(self.position_keys);
        self.allocator.free(self.rotation_keys);
        self.allocator.free(self.scale_keys);
    }
};

/// Complete animation
pub const Animation = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    duration: f32,
    ticks_per_second: f32,
    channels: []AnimationChannel,
    channel_count: usize,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, max_channels: usize) !Animation {
        const channels = try allocator.alloc(AnimationChannel, max_channels);

        return Animation{
            .allocator = allocator,
            .name = name,
            .duration = 0.0,
            .ticks_per_second = 30.0,
            .channels = channels,
            .channel_count = 0,
        };
    }

    pub fn deinit(self: *Animation) void {
        for (self.channels[0..self.channel_count]) |*channel| {
            channel.deinit();
        }
        self.allocator.free(self.channels);
    }

    pub fn addChannel(self: *Animation, channel: AnimationChannel) !void {
        if (self.channel_count >= self.channels.len) return error.TooManyChannels;
        self.channels[self.channel_count] = channel;
        self.channel_count += 1;
    }
};

/// Skeleton for hierarchical bones
pub const Skeleton = struct {
    allocator: std.mem.Allocator,
    bones: []Bone,
    bone_count: usize,

    pub fn init(allocator: std.mem.Allocator, max_bones: usize) !Skeleton {
        const bones = try allocator.alloc(Bone, max_bones);

        return Skeleton{
            .allocator = allocator,
            .bones = bones,
            .bone_count = 0,
        };
    }

    pub fn deinit(self: *Skeleton) void {
        self.allocator.free(self.bones);
    }

    pub fn addBone(self: *Skeleton, bone: Bone) !void {
        if (self.bone_count >= self.bones.len) return error.TooManyBones;
        self.bones[self.bone_count] = bone;
        self.bone_count += 1;
    }
};

/// Material properties
pub const Material = struct {
    name: []const u8,
    diffuse_texture: []const u8,
    normal_texture: []const u8,
    specular_texture: []const u8,
    diffuse_color: Vec4,
    specular_color: Vec4,
    shininess: f32,
    alpha: f32,
};

/// Complete 3D model
pub const Model = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    meshes: []Mesh,
    mesh_count: usize,
    materials: []Material,
    material_count: usize,
    skeleton: ?Skeleton,
    animations: []Animation,
    animation_count: usize,
    bounds_min: Vec3,
    bounds_max: Vec3,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) !Model {
        const meshes = try allocator.alloc(Mesh, 32);
        const materials = try allocator.alloc(Material, 16);
        const animations = try allocator.alloc(Animation, 64);

        return Model{
            .allocator = allocator,
            .name = name,
            .meshes = meshes,
            .mesh_count = 0,
            .materials = materials,
            .material_count = 0,
            .skeleton = null,
            .animations = animations,
            .animation_count = 0,
            .bounds_min = Vec3.zero(),
            .bounds_max = Vec3.zero(),
        };
    }

    pub fn deinit(self: *Model) void {
        for (self.meshes[0..self.mesh_count]) |*mesh| {
            mesh.deinit();
        }
        self.allocator.free(self.meshes);
        self.allocator.free(self.materials);

        if (self.skeleton) |*skeleton| {
            skeleton.deinit();
        }

        for (self.animations[0..self.animation_count]) |*anim| {
            anim.deinit();
        }
        self.allocator.free(self.animations);
    }

    pub fn addMesh(self: *Model, mesh: Mesh) !void {
        if (self.mesh_count >= self.meshes.len) return error.TooManyMeshes;
        self.meshes[self.mesh_count] = mesh;
        self.mesh_count += 1;
    }

    pub fn addMaterial(self: *Model, material: Material) !void {
        if (self.material_count >= self.materials.len) return error.TooManyMaterials;
        self.materials[self.material_count] = material;
        self.material_count += 1;
    }

    pub fn addAnimation(self: *Model, animation: Animation) !void {
        if (self.animation_count >= self.animations.len) return error.TooManyAnimations;
        self.animations[self.animation_count] = animation;
        self.animation_count += 1;
    }

    pub fn getAnimation(self: *Model, name: []const u8) ?*Animation {
        for (self.animations[0..self.animation_count]) |*anim| {
            if (std.mem.eql(u8, anim.name, name)) {
                return anim;
            }
        }
        return null;
    }
};

/// W3D File format chunk types
pub const W3DChunkType = enum(u32) {
    MESH = 0x00000000,
    VERTICES = 0x00000002,
    VERTEX_NORMALS = 0x00000003,
    MESH_USER_TEXT = 0x0000000C,
    VERTEX_INFLUENCES = 0x0000000E,
    MESH_HEADER3 = 0x0000001F,
    TRIANGLES = 0x00000020,
    VERTEX_SHADE_INDICES = 0x00000022,
    MATERIAL_INFO = 0x00000028,
    TEXTURES = 0x00000030,
    MATERIAL_PASS = 0x00000038,
    VERTEX_MATERIALS = 0x00000039,
    SHADER_MATERIALS = 0x00000048,
    TEXTURE_STAGE = 0x00000049,
    TEXTURE_IDS = 0x0000004A,
    STAGE_TEXCOORDS = 0x0000004B,
    HIERARCHY = 0x00000100,
    ANIMATION = 0x00000200,
    _,
};

/// W3D file chunk header
pub const W3DChunkHeader = struct {
    chunk_type: u32,
    chunk_size: u32,
};

/// W3D Model Loader
pub const W3DModelLoader = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) W3DModelLoader {
        return W3DModelLoader{ .allocator = allocator };
    }

    /// Load W3D model from file
    pub fn loadFromFile(self: *W3DModelLoader, file_path: []const u8) !Model {
        _ = file_path;

        // For now, create a simple cube model as demonstration
        // In full implementation, would parse binary W3D format
        return try self.createCubeDemoModel("Demo Cube");
    }

    /// Load W3D model from memory
    pub fn loadFromMemory(self: *W3DModelLoader, data: []const u8, model_name: []const u8) !Model {
        _ = data;

        // Stub: would parse W3D binary format
        return try self.createCubeDemoModel(model_name);
    }

    /// Create a simple cube model for demonstration
    fn createCubeDemoModel(self: *W3DModelLoader, name: []const u8) !Model {
        var model = try Model.init(self.allocator, name);

        // Create cube mesh
        var mesh = try Mesh.init(self.allocator, "Cube", 1);

        // Cube vertices
        const cube_vertices = [_]Vec3{
            Vec3.init(-1, -1, -1), Vec3.init(1, -1, -1),
            Vec3.init(1, 1, -1),   Vec3.init(-1, 1, -1),
            Vec3.init(-1, -1, 1),  Vec3.init(1, -1, 1),
            Vec3.init(1, 1, 1),    Vec3.init(-1, 1, 1),
        };

        const vertices = try self.allocator.alloc(Vertex, 8);
        for (cube_vertices, 0..) |pos, i| {
            vertices[i] = Vertex.init(pos);
        }

        // Cube indices (triangles)
        const indices = try self.allocator.alloc(u32, 36);
        const cube_indices = [_]u32{
            0, 1, 2, 2, 3, 0, // Front
            1, 5, 6, 6, 2, 1, // Right
            5, 4, 7, 7, 6, 5, // Back
            4, 0, 3, 3, 7, 4, // Left
            3, 2, 6, 6, 7, 3, // Top
            4, 5, 1, 1, 0, 4, // Bottom
        };
        @memcpy(indices, &cube_indices);

        const lod = MeshLOD{
            .vertices = vertices,
            .indices = indices,
            .material_id = 0,
            .lod_level = 0,
        };

        try mesh.addLOD(lod);
        mesh.bounds_min = Vec3.init(-1, -1, -1);
        mesh.bounds_max = Vec3.init(1, 1, 1);

        try model.addMesh(mesh);

        // Add default material
        const material = Material{
            .name = "Default",
            .diffuse_texture = "default.dds",
            .normal_texture = "",
            .specular_texture = "",
            .diffuse_color = Vec4{ .x = 1, .y = 1, .z = 1, .w = 1 },
            .specular_color = Vec4{ .x = 0.5, .y = 0.5, .z = 0.5, .w = 1 },
            .shininess = 32.0,
            .alpha = 1.0,
        };

        try model.addMaterial(material);

        model.bounds_min = Vec3.init(-1, -1, -1);
        model.bounds_max = Vec3.init(1, 1, 1);

        return model;
    }
};

/// Model manager for caching loaded models
pub const ModelManager = struct {
    allocator: std.mem.Allocator,
    models: []Model,
    model_count: usize,
    loader: W3DModelLoader,

    pub fn init(allocator: std.mem.Allocator) !ModelManager {
        const models = try allocator.alloc(Model, 1000);

        return ModelManager{
            .allocator = allocator,
            .models = models,
            .model_count = 0,
            .loader = W3DModelLoader.init(allocator),
        };
    }

    pub fn deinit(self: *ModelManager) void {
        for (self.models[0..self.model_count]) |*model| {
            model.deinit();
        }
        self.allocator.free(self.models);
    }

    pub fn loadModel(self: *ModelManager, file_path: []const u8) !*Model {
        // Check if already loaded
        for (self.models[0..self.model_count]) |*model| {
            if (std.mem.eql(u8, model.name, file_path)) {
                return model;
            }
        }

        // Load new model
        if (self.model_count >= self.models.len) return error.TooManyModels;

        const model = try self.loader.loadFromFile(file_path);
        self.models[self.model_count] = model;
        const result = &self.models[self.model_count];
        self.model_count += 1;

        return result;
    }

    pub fn getModel(self: *ModelManager, name: []const u8) ?*Model {
        for (self.models[0..self.model_count]) |*model| {
            if (std.mem.eql(u8, model.name, name)) {
                return model;
            }
        }
        return null;
    }

    pub fn getStats(self: *ModelManager) ModelStats {
        var total_vertices: usize = 0;
        var total_triangles: usize = 0;
        var total_animations: usize = 0;

        for (self.models[0..self.model_count]) |*model| {
            for (model.meshes[0..model.mesh_count]) |*mesh| {
                if (mesh.lod_count > 0) {
                    const lod = &mesh.lods[0];
                    total_vertices += lod.vertices.len;
                    total_triangles += lod.indices.len / 3;
                }
            }
            total_animations += model.animation_count;
        }

        return ModelStats{
            .loaded_models = self.model_count,
            .total_vertices = total_vertices,
            .total_triangles = total_triangles,
            .total_animations = total_animations,
        };
    }
};

pub const ModelStats = struct {
    loaded_models: usize,
    total_vertices: usize,
    total_triangles: usize,
    total_animations: usize,
};

// Tests
test "Model creation" {
    const allocator = std.testing.allocator;

    var model = try Model.init(allocator, "Test Model");
    defer model.deinit();

    try std.testing.expect(model.mesh_count == 0);
    try std.testing.expect(std.mem.eql(u8, model.name, "Test Model"));
}

test "W3D loader demo" {
    const allocator = std.testing.allocator;

    var loader = W3DModelLoader.init(allocator);
    var model = try loader.loadFromFile("test.w3d");
    defer model.deinit();

    try std.testing.expect(model.mesh_count > 0);
}

test "Model manager" {
    const allocator = std.testing.allocator;

    var manager = try ModelManager.init(allocator);
    defer manager.deinit();

    const model = try manager.loadModel("cube.w3d");
    try std.testing.expect(model.mesh_count > 0);

    const stats = manager.getStats();
    try std.testing.expect(stats.loaded_models == 1);
}
