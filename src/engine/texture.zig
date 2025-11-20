// Generals Texture Loading
// Supports TGA format (main format used by Generals)

const std = @import("std");
const Allocator = std.mem.Allocator;

/// TGA file header (18 bytes)
const TGAHeader = packed struct {
    id_length: u8,
    color_map_type: u8,
    image_type: u8,
    color_map_start: u16,
    color_map_length: u16,
    color_map_depth: u8,
    x_offset: u16,
    y_offset: u16,
    width: u16,
    height: u16,
    pixel_depth: u8,
    image_descriptor: u8,
};

/// TGA image types
const TGAImageType = enum(u8) {
    no_image = 0,
    color_mapped = 1,
    true_color = 2,
    monochrome = 3,
    color_mapped_rle = 9,
    true_color_rle = 10,
    monochrome_rle = 11,
};

/// Texture pixel format
pub const PixelFormat = enum {
    rgb,
    rgba,
    bgr,
    bgra,
};

/// Loaded texture data
pub const Texture = struct {
    width: u32,
    height: u32,
    format: PixelFormat,
    data: []u8,
    allocator: Allocator,

    pub fn deinit(self: *Texture) void {
        self.allocator.free(self.data);
    }

    /// Load texture from TGA file
    pub fn loadTGA(allocator: Allocator, file_path: []const u8) !Texture {
        // Read file
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const file_data = try allocator.alloc(u8, file_size);
        defer allocator.free(file_data);

        // Read entire file
        var bytes_read: usize = 0;
        while (bytes_read < file_size) {
            const n = try file.read(file_data[bytes_read..]);
            if (n == 0) break;
            bytes_read += n;
        }

        if (bytes_read != file_size) {
            return error.InvalidTGAFile;
        }

        // Parse header
        if (file_data.len < @sizeOf(TGAHeader)) {
            return error.InvalidTGAFile;
        }

        const header: *const TGAHeader = @ptrCast(@alignCast(file_data.ptr));

        // Validate header
        if (header.image_type != @intFromEnum(TGAImageType.true_color) and
            header.image_type != @intFromEnum(TGAImageType.true_color_rle))
        {
            std.debug.print("Unsupported TGA image type: {}\n", .{header.image_type});
            return error.UnsupportedTGAType;
        }

        if (header.pixel_depth != 24 and header.pixel_depth != 32) {
            std.debug.print("Unsupported TGA pixel depth: {}\n", .{header.pixel_depth});
            return error.UnsupportedPixelDepth;
        }

        const width = header.width;
        const height = header.height;
        const bytes_per_pixel: u32 = header.pixel_depth / 8;
        const image_size: usize = @as(usize, width) * @as(usize, height) * bytes_per_pixel;

        // Calculate offset to image data (skip header + ID field)
        const image_data_offset: usize = @sizeOf(TGAHeader) + header.id_length;

        if (file_data.len < image_data_offset + image_size) {
            return error.InvalidTGAFile;
        }

        // Allocate texture data
        const texture_data = try allocator.alloc(u8, image_size);
        errdefer allocator.free(texture_data);

        // Determine format (TGA is usually BGR/BGRA)
        const format: PixelFormat = if (bytes_per_pixel == 4) .bgra else .bgr;

        // Handle uncompressed vs RLE
        if (header.image_type == @intFromEnum(TGAImageType.true_color)) {
            // Uncompressed - direct copy
            const source_data = file_data[image_data_offset..][0..image_size];
            @memcpy(texture_data, source_data);
        } else if (header.image_type == @intFromEnum(TGAImageType.true_color_rle)) {
            // RLE compressed
            try decompressRLE(
                file_data[image_data_offset..],
                texture_data,
                bytes_per_pixel,
            );
        }

        // TGA images are typically stored bottom-up, check if we need to flip
        const origin_top = (header.image_descriptor & 0x20) != 0;
        if (!origin_top) {
            // Flip vertically
            try flipVertical(texture_data, width, height, bytes_per_pixel);
        }

        return Texture{
            .width = width,
            .height = height,
            .format = format,
            .data = texture_data,
            .allocator = allocator,
        };
    }

    /// Decompress RLE-encoded TGA data
    fn decompressRLE(source: []const u8, dest: []u8, bytes_per_pixel: u32) !void {
        var src_pos: usize = 0;
        var dest_pos: usize = 0;

        while (dest_pos < dest.len) {
            if (src_pos >= source.len) {
                return error.InvalidRLEData;
            }

            const packet_header = source[src_pos];
            src_pos += 1;

            const is_rle = (packet_header & 0x80) != 0;
            const count = @as(usize, (packet_header & 0x7F)) + 1;

            if (is_rle) {
                // RLE packet - repeat next pixel
                if (src_pos + bytes_per_pixel > source.len) {
                    return error.InvalidRLEData;
                }

                const pixel = source[src_pos..][0..bytes_per_pixel];
                src_pos += bytes_per_pixel;

                var i: usize = 0;
                while (i < count) : (i += 1) {
                    if (dest_pos + bytes_per_pixel > dest.len) {
                        return error.InvalidRLEData;
                    }

                    @memcpy(dest[dest_pos..][0..bytes_per_pixel], pixel);
                    dest_pos += bytes_per_pixel;
                }
            } else {
                // Raw packet - copy pixels directly
                const bytes_to_copy = count * bytes_per_pixel;
                if (src_pos + bytes_to_copy > source.len or dest_pos + bytes_to_copy > dest.len) {
                    return error.InvalidRLEData;
                }

                @memcpy(dest[dest_pos..][0..bytes_to_copy], source[src_pos..][0..bytes_to_copy]);
                src_pos += bytes_to_copy;
                dest_pos += bytes_to_copy;
            }
        }
    }

    /// Flip image vertically
    fn flipVertical(data: []u8, width: u32, height: u32, bytes_per_pixel: u32) !void {
        const row_size = width * bytes_per_pixel;
        const temp_row = try std.heap.page_allocator.alloc(u8, row_size);
        defer std.heap.page_allocator.free(temp_row);

        var y: u32 = 0;
        while (y < height / 2) : (y += 1) {
            const top_offset = y * row_size;
            const bottom_offset = (height - 1 - y) * row_size;

            const top_row = data[top_offset..][0..row_size];
            const bottom_row = data[bottom_offset..][0..row_size];

            // Swap rows
            @memcpy(temp_row, top_row);
            @memcpy(top_row, bottom_row);
            @memcpy(bottom_row, temp_row);
        }
    }

    /// Convert BGR to RGB (if needed for certain APIs)
    pub fn convertBGRtoRGB(self: *Texture) void {
        if (self.format != .bgr and self.format != .bgra) {
            return; // Already in RGB format
        }

        const bytes_per_pixel: u32 = if (self.format == .bgra) 4 else 3;

        var i: usize = 0;
        while (i < self.data.len) : (i += bytes_per_pixel) {
            // Swap B and R channels
            const temp = self.data[i];
            self.data[i] = self.data[i + 2];
            self.data[i + 2] = temp;
        }

        self.format = if (self.format == .bgra) .rgba else .rgb;
    }
};

// Tests
test "TGA header size" {
    try std.testing.expectEqual(@as(usize, 18), @sizeOf(TGAHeader));
}
