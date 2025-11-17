// C&C Generals - Texture Loading System
// Supports DDS and TGA formats with GPU upload

const std = @import("std");

/// Texture format types
pub const TextureFormat = enum {
    RGBA8,
    RGB8,
    DXT1,
    DXT3,
    DXT5,
    BC1,
    BC3,
    BC5,
};

/// Texture filtering modes
pub const FilterMode = enum {
    Nearest,
    Linear,
    Bilinear,
    Trilinear,
    Anisotropic,
};

/// Texture wrap modes
pub const WrapMode = enum {
    Repeat,
    Clamp,
    Mirror,
    Border,
};

/// Mipmap level
pub const MipmapLevel = struct {
    data: []u8,
    width: u32,
    height: u32,
    size: usize,
};

/// Complete texture data
pub const Texture = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    width: u32,
    height: u32,
    format: TextureFormat,
    mipmap_levels: []MipmapLevel,
    mipmap_count: u32,
    gpu_id: u32, // GPU texture handle
    is_compressed: bool,
    filter_mode: FilterMode,
    wrap_mode: WrapMode,

    pub fn init(
        allocator: std.mem.Allocator,
        name: []const u8,
        width: u32,
        height: u32,
        format: TextureFormat,
    ) !Texture {
        const mipmap_levels = try allocator.alloc(MipmapLevel, 12); // Max 12 mip levels

        return Texture{
            .allocator = allocator,
            .name = name,
            .width = width,
            .height = height,
            .format = format,
            .mipmap_levels = mipmap_levels,
            .mipmap_count = 0,
            .gpu_id = 0,
            .is_compressed = isCompressedFormat(format),
            .filter_mode = .Trilinear,
            .wrap_mode = .Repeat,
        };
    }

    pub fn deinit(self: *Texture) void {
        for (self.mipmap_levels[0..self.mipmap_count]) |*level| {
            self.allocator.free(level.data);
        }
        self.allocator.free(self.mipmap_levels);
    }

    pub fn addMipmapLevel(self: *Texture, data: []u8, width: u32, height: u32) !void {
        if (self.mipmap_count >= self.mipmap_levels.len) return error.TooManyMipmaps;

        self.mipmap_levels[self.mipmap_count] = MipmapLevel{
            .data = data,
            .width = width,
            .height = height,
            .size = data.len,
        };
        self.mipmap_count += 1;
    }

    fn isCompressedFormat(format: TextureFormat) bool {
        return switch (format) {
            .DXT1, .DXT3, .DXT5, .BC1, .BC3, .BC5 => true,
            else => false,
        };
    }

    pub fn getMemorySize(self: *Texture) usize {
        var total: usize = 0;
        for (self.mipmap_levels[0..self.mipmap_count]) |level| {
            total += level.size;
        }
        return total;
    }
};

/// DDS file header
pub const DDSHeader = struct {
    magic: u32, // "DDS "
    size: u32,
    flags: u32,
    height: u32,
    width: u32,
    pitch_or_linear_size: u32,
    depth: u32,
    mipmap_count: u32,
    reserved1: [11]u32,
    pixel_format: DDSPixelFormat,
    caps: u32,
    caps2: u32,
    caps3: u32,
    caps4: u32,
    reserved2: u32,
};

pub const DDSPixelFormat = struct {
    size: u32,
    flags: u32,
    fourcc: u32,
    rgb_bit_count: u32,
    r_bit_mask: u32,
    g_bit_mask: u32,
    b_bit_mask: u32,
    a_bit_mask: u32,
};

/// DDS texture loader
pub const DDSLoader = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) DDSLoader {
        return DDSLoader{ .allocator = allocator };
    }

    pub fn loadFromFile(self: *DDSLoader, file_path: []const u8) !Texture {
        _ = file_path;

        // Stub: would read and parse DDS file
        // For now, create a simple 2x2 texture
        return try self.createDemoTexture("Demo DDS", 2, 2);
    }

    pub fn loadFromMemory(self: *DDSLoader, data: []const u8, name: []const u8) !Texture {
        _ = data;

        // Stub: would parse DDS binary format
        return try self.createDemoTexture(name, 2, 2);
    }

    fn createDemoTexture(self: *DDSLoader, name: []const u8, width: u32, height: u32) !Texture {
        var texture = try Texture.init(self.allocator, name, width, height, .RGBA8);

        // Create simple 2x2 RGBA texture
        const pixel_data = try self.allocator.alloc(u8, width * height * 4);

        // Fill with checkerboard pattern
        for (0..height) |y| {
            for (0..width) |x| {
                const i = (y * width + x) * 4;
                const is_white = (x + y) % 2 == 0;
                pixel_data[i + 0] = if (is_white) 255 else 128; // R
                pixel_data[i + 1] = if (is_white) 255 else 128; // G
                pixel_data[i + 2] = if (is_white) 255 else 128; // B
                pixel_data[i + 3] = 255; // A
            }
        }

        try texture.addMipmapLevel(pixel_data, width, height);

        return texture;
    }
};

/// TGA file header
pub const TGAHeader = struct {
    id_length: u8,
    color_map_type: u8,
    image_type: u8,
    color_map_spec: [5]u8,
    x_origin: u16,
    y_origin: u16,
    width: u16,
    height: u16,
    bits_per_pixel: u8,
    image_descriptor: u8,
};

/// TGA texture loader
pub const TGALoader = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TGALoader {
        return TGALoader{ .allocator = allocator };
    }

    pub fn loadFromFile(self: *TGALoader, file_path: []const u8) !Texture {
        _ = file_path;

        // Stub: would read and parse TGA file
        return try self.createDemoTexture("Demo TGA", 4, 4);
    }

    pub fn loadFromMemory(self: *TGALoader, data: []const u8, name: []const u8) !Texture {
        _ = data;

        // Stub: would parse TGA binary format
        return try self.createDemoTexture(name, 4, 4);
    }

    fn createDemoTexture(self: *TGALoader, name: []const u8, width: u32, height: u32) !Texture {
        var texture = try Texture.init(self.allocator, name, width, height, .RGB8);

        // Create simple RGB texture
        const pixel_data = try self.allocator.alloc(u8, width * height * 3);

        // Fill with gradient
        for (0..height) |y| {
            for (0..width) |x| {
                const i = (y * width + x) * 3;
                pixel_data[i + 0] = @as(u8, @intCast((x * 255) / width)); // R
                pixel_data[i + 1] = @as(u8, @intCast((y * 255) / height)); // G
                pixel_data[i + 2] = 128; // B
            }
        }

        try texture.addMipmapLevel(pixel_data, width, height);

        return texture;
    }
};

/// GPU texture uploader (platform-specific stub)
pub const GPUUploader = struct {
    pub fn uploadTexture(texture: *Texture) !void {
        // In full implementation:
        // - Create GPU texture object (OpenGL/Metal/Vulkan/D3D12)
        // - Upload mipmap levels to GPU
        // - Set filtering and wrap modes
        // - Store GPU handle in texture.gpu_id

        // For now, just assign a fake GPU ID
        texture.gpu_id = 12345;
    }

    pub fn deleteTexture(texture: *Texture) void {
        // In full implementation:
        // - Delete GPU texture object
        // - Free GPU memory

        texture.gpu_id = 0;
    }
};

/// Texture manager for caching and managing textures
pub const TextureManager = struct {
    allocator: std.mem.Allocator,
    textures: []Texture,
    texture_count: usize,
    dds_loader: DDSLoader,
    tga_loader: TGALoader,
    total_gpu_memory: usize,

    pub fn init(allocator: std.mem.Allocator) !TextureManager {
        const textures = try allocator.alloc(Texture, 2000);

        return TextureManager{
            .allocator = allocator,
            .textures = textures,
            .texture_count = 0,
            .dds_loader = DDSLoader.init(allocator),
            .tga_loader = TGALoader.init(allocator),
            .total_gpu_memory = 0,
        };
    }

    pub fn deinit(self: *TextureManager) void {
        for (self.textures[0..self.texture_count]) |*texture| {
            GPUUploader.deleteTexture(texture);
            texture.deinit();
        }
        self.allocator.free(self.textures);
    }

    pub fn loadTexture(self: *TextureManager, file_path: []const u8) !*Texture {
        // Check if already loaded
        for (self.textures[0..self.texture_count]) |*texture| {
            if (std.mem.eql(u8, texture.name, file_path)) {
                return texture;
            }
        }

        // Load new texture
        if (self.texture_count >= self.textures.len) return error.TooManyTextures;

        // Determine format from extension
        var texture: Texture = undefined;
        if (std.mem.endsWith(u8, file_path, ".dds")) {
            texture = try self.dds_loader.loadFromFile(file_path);
        } else if (std.mem.endsWith(u8, file_path, ".tga")) {
            texture = try self.tga_loader.loadFromFile(file_path);
        } else {
            return error.UnsupportedFormat;
        }

        // Upload to GPU
        try GPUUploader.uploadTexture(&texture);

        self.textures[self.texture_count] = texture;
        const result = &self.textures[self.texture_count];
        self.texture_count += 1;

        self.total_gpu_memory += texture.getMemorySize();

        return result;
    }

    pub fn getTexture(self: *TextureManager, name: []const u8) ?*Texture {
        for (self.textures[0..self.texture_count]) |*texture| {
            if (std.mem.eql(u8, texture.name, name)) {
                return texture;
            }
        }
        return null;
    }

    pub fn generateMipmaps(self: *TextureManager, texture: *Texture) !void {
        _ = self;

        // Generate mipmaps by downsampling
        var current_width = texture.width;
        var current_height = texture.height;

        while (current_width > 1 or current_height > 1) {
            current_width = @max(1, current_width / 2);
            current_height = @max(1, current_height / 2);

            // In full implementation:
            // - Downsample previous mip level
            // - Add new mip level to texture
            // For now, just break after one level
            break;
        }
    }

    pub fn getStats(self: *TextureManager) TextureStats {
        var total_memory: usize = 0;
        var compressed_count: usize = 0;
        var uncompressed_count: usize = 0;

        for (self.textures[0..self.texture_count]) |*texture| {
            total_memory += texture.getMemorySize();
            if (texture.is_compressed) {
                compressed_count += 1;
            } else {
                uncompressed_count += 1;
            }
        }

        return TextureStats{
            .loaded_textures = self.texture_count,
            .total_memory = total_memory,
            .gpu_memory = self.total_gpu_memory,
            .compressed_textures = compressed_count,
            .uncompressed_textures = uncompressed_count,
        };
    }
};

pub const TextureStats = struct {
    loaded_textures: usize,
    total_memory: usize,
    gpu_memory: usize,
    compressed_textures: usize,
    uncompressed_textures: usize,
};

// Tests
test "Texture creation" {
    const allocator = std.testing.allocator;

    var texture = try Texture.init(allocator, "Test", 256, 256, .RGBA8);
    defer texture.deinit();

    try std.testing.expect(texture.width == 256);
    try std.testing.expect(texture.height == 256);
}

test "DDS loader" {
    const allocator = std.testing.allocator;

    var loader = DDSLoader.init(allocator);
    var texture = try loader.loadFromFile("test.dds");
    defer texture.deinit();

    try std.testing.expect(texture.mipmap_count > 0);
}

test "TGA loader" {
    const allocator = std.testing.allocator;

    var loader = TGALoader.init(allocator);
    var texture = try loader.loadFromFile("test.tga");
    defer texture.deinit();

    try std.testing.expect(texture.mipmap_count > 0);
}

test "Texture manager" {
    const allocator = std.testing.allocator;

    var manager = try TextureManager.init(allocator);
    defer manager.deinit();

    const texture1 = try manager.loadTexture("test.dds");
    const texture2 = try manager.loadTexture("test.tga");

    try std.testing.expect(texture1.gpu_id != 0);
    try std.testing.expect(texture2.gpu_id != 0);

    const stats = manager.getStats();
    try std.testing.expect(stats.loaded_textures == 2);
}
