// Generals Texture Loading
// Supports TGA and DDS formats (main formats used by Generals)

const std = @import("std");
const Allocator = std.mem.Allocator;

// DDS file format constants
const DDS_MAGIC = 0x20534444; // "DDS "
const DDPF_FOURCC = 0x4;

// DXT compression FourCC codes
const FOURCC_DXT1 = 0x31545844; // "DXT1"
const FOURCC_DXT3 = 0x33545844; // "DXT3"
const FOURCC_DXT5 = 0x35545844; // "DXT5"

// BMP file format constants
const BMP_MAGIC = 0x4D42; // "BM" in little endian

/// BMP file header (14 bytes)
const BMPFileHeader = packed struct {
    magic: u16, // "BM" = 0x4D42
    file_size: u32,
    reserved1: u16,
    reserved2: u16,
    data_offset: u32,
};

/// BMP info header (40 bytes, BITMAPINFOHEADER)
const BMPInfoHeader = packed struct {
    size: u32, // Should be 40 for BITMAPINFOHEADER
    width: i32,
    height: i32, // Negative = top-down, positive = bottom-up
    planes: u16,
    bit_count: u16, // Bits per pixel (1, 4, 8, 16, 24, 32)
    compression: u32, // 0 = BI_RGB (uncompressed)
    image_size: u32,
    x_pixels_per_meter: i32,
    y_pixels_per_meter: i32,
    colors_used: u32,
    colors_important: u32,
};

/// DDS file header (124 bytes)
const DDSHeader = packed struct {
    magic: u32,
    size: u32,
    flags: u32,
    height: u32,
    width: u32,
    pitch_or_linear_size: u32,
    depth: u32,
    mip_map_count: u32,
    reserved1: [11]u32,
    // Pixel format
    pf_size: u32,
    pf_flags: u32,
    pf_fourcc: u32,
    pf_rgb_bit_count: u32,
    pf_r_bit_mask: u32,
    pf_g_bit_mask: u32,
    pf_b_bit_mask: u32,
    pf_a_bit_mask: u32,
    // Caps
    caps: u32,
    caps2: u32,
    caps3: u32,
    caps4: u32,
    reserved2: u32,
};

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

        // For uncompressed images, check file size
        // For RLE images, the compressed data can be smaller than image_size
        if (header.image_type == @intFromEnum(TGAImageType.true_color)) {
            if (file_data.len < image_data_offset + image_size) {
                return error.InvalidTGAFile;
            }
        } else {
            // For RLE, just ensure we have at least the header
            if (file_data.len <= image_data_offset) {
                return error.InvalidTGAFile;
            }
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
        const bpp = @as(usize, bytes_per_pixel);

        while (dest_pos < dest.len) {
            if (src_pos >= source.len) {
                // If we've filled the destination, that's OK
                if (dest_pos >= dest.len) break;
                // Pad remaining with zeros
                while (dest_pos < dest.len) {
                    dest[dest_pos] = 0;
                    dest_pos += 1;
                }
                break;
            }

            const packet_header = source[src_pos];
            src_pos += 1;

            const is_rle = (packet_header & 0x80) != 0;
            const count = @as(usize, (packet_header & 0x7F)) + 1;

            if (is_rle) {
                // RLE packet - repeat next pixel
                if (src_pos + bpp > source.len) {
                    // Not enough data - fill with zeros
                    while (dest_pos < dest.len) {
                        dest[dest_pos] = 0;
                        dest_pos += 1;
                    }
                    break;
                }

                var i: usize = 0;
                while (i < count and dest_pos + bpp <= dest.len) : (i += 1) {
                    var j: usize = 0;
                    while (j < bpp) : (j += 1) {
                        dest[dest_pos + j] = source[src_pos + j];
                    }
                    dest_pos += bpp;
                }
                src_pos += bpp;
            } else {
                // Raw packet - copy pixels directly
                var i: usize = 0;
                while (i < count and dest_pos + bpp <= dest.len) : (i += 1) {
                    if (src_pos + bpp > source.len) {
                        // Not enough source data - fill with zeros
                        var j: usize = 0;
                        while (j < bpp) : (j += 1) {
                            dest[dest_pos + j] = 0;
                        }
                    } else {
                        var j: usize = 0;
                        while (j < bpp) : (j += 1) {
                            dest[dest_pos + j] = source[src_pos + j];
                        }
                        src_pos += bpp;
                    }
                    dest_pos += bpp;
                }
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

    /// Load texture from DDS file
    pub fn loadDDS(allocator: Allocator, file_path: []const u8) !Texture {
        // Read file
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const file_data = try allocator.alloc(u8, file_size);
        defer allocator.free(file_data);

        var bytes_read: usize = 0;
        while (bytes_read < file_size) {
            const n = try file.read(file_data[bytes_read..]);
            if (n == 0) break;
            bytes_read += n;
        }

        if (bytes_read < @sizeOf(DDSHeader)) {
            return error.InvalidDDSFile;
        }

        // Parse header
        const header: *const DDSHeader = @ptrCast(@alignCast(file_data.ptr));

        // Verify magic number
        if (header.magic != DDS_MAGIC) {
            return error.InvalidDDSFile;
        }

        const width = header.width;
        const height = header.height;
        const fourcc = header.pf_fourcc;

        // Determine compression type
        const is_dxt1 = fourcc == FOURCC_DXT1;
        const is_dxt3 = fourcc == FOURCC_DXT3;
        const is_dxt5 = fourcc == FOURCC_DXT5;

        if (!is_dxt1 and !is_dxt3 and !is_dxt5) {
            std.debug.print("DDS: Unsupported fourcc: 0x{X}\n", .{fourcc});
            return error.UnsupportedDDSFormat;
        }

        // Calculate compressed data size
        const blocks_x = (width + 3) / 4;
        const blocks_y = (height + 3) / 4;
        const block_size: usize = if (is_dxt1) 8 else 16;
        const compressed_size = blocks_x * blocks_y * block_size;

        // Offset to image data (skip header)
        const data_offset: usize = @sizeOf(DDSHeader);
        if (file_data.len < data_offset + compressed_size) {
            return error.InvalidDDSFile;
        }

        const compressed_data = file_data[data_offset..][0..compressed_size];

        // Allocate output RGBA data
        const output_size = @as(usize, width) * @as(usize, height) * 4;
        const texture_data = try allocator.alloc(u8, output_size);
        errdefer allocator.free(texture_data);

        // Decompress DXT data
        if (is_dxt1) {
            decompressDXT1(compressed_data, texture_data, width, height);
        } else if (is_dxt3) {
            decompressDXT3(compressed_data, texture_data, width, height);
        } else {
            decompressDXT5(compressed_data, texture_data, width, height);
        }

        return Texture{
            .width = width,
            .height = height,
            .format = .rgba,
            .data = texture_data,
            .allocator = allocator,
        };
    }

    /// Decompress DXT1 block compressed data
    fn decompressDXT1(source: []const u8, dest: []u8, width: u32, height: u32) void {
        const blocks_x = (width + 3) / 4;
        const blocks_y = (height + 3) / 4;
        var block_idx: usize = 0;

        var by: u32 = 0;
        while (by < blocks_y) : (by += 1) {
            var bx: u32 = 0;
            while (bx < blocks_x) : (bx += 1) {
                const block_offset = block_idx * 8;
                if (block_offset + 8 > source.len) break;

                // Read colors
                const c0 = @as(u16, source[block_offset]) | (@as(u16, source[block_offset + 1]) << 8);
                const c1 = @as(u16, source[block_offset + 2]) | (@as(u16, source[block_offset + 3]) << 8);
                const indices = @as(u32, source[block_offset + 4]) |
                    (@as(u32, source[block_offset + 5]) << 8) |
                    (@as(u32, source[block_offset + 6]) << 16) |
                    (@as(u32, source[block_offset + 7]) << 24);

                // Decode colors from RGB565
                var colors: [4][4]u8 = undefined;
                colors[0] = rgb565ToRGBA(c0);
                colors[1] = rgb565ToRGBA(c1);

                if (c0 > c1) {
                    // 4-color mode
                    colors[2][0] = @intCast((@as(u16, colors[0][0]) * 2 + @as(u16, colors[1][0])) / 3);
                    colors[2][1] = @intCast((@as(u16, colors[0][1]) * 2 + @as(u16, colors[1][1])) / 3);
                    colors[2][2] = @intCast((@as(u16, colors[0][2]) * 2 + @as(u16, colors[1][2])) / 3);
                    colors[2][3] = 255;

                    colors[3][0] = @intCast((@as(u16, colors[0][0]) + @as(u16, colors[1][0]) * 2) / 3);
                    colors[3][1] = @intCast((@as(u16, colors[0][1]) + @as(u16, colors[1][1]) * 2) / 3);
                    colors[3][2] = @intCast((@as(u16, colors[0][2]) + @as(u16, colors[1][2]) * 2) / 3);
                    colors[3][3] = 255;
                } else {
                    // 3-color mode with transparency
                    colors[2][0] = @intCast((@as(u16, colors[0][0]) + @as(u16, colors[1][0])) / 2);
                    colors[2][1] = @intCast((@as(u16, colors[0][1]) + @as(u16, colors[1][1])) / 2);
                    colors[2][2] = @intCast((@as(u16, colors[0][2]) + @as(u16, colors[1][2])) / 2);
                    colors[2][3] = 255;

                    colors[3] = .{ 0, 0, 0, 0 }; // Transparent
                }

                // Write pixels
                var py: u32 = 0;
                while (py < 4) : (py += 1) {
                    var px: u32 = 0;
                    while (px < 4) : (px += 1) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x < width and y < height) {
                            const idx = @as(u2, @truncate((indices >> @truncate(((py * 4 + px) * 2)))));
                            const dest_offset = (y * width + x) * 4;
                            if (dest_offset + 4 <= dest.len) {
                                dest[dest_offset] = colors[idx][0];
                                dest[dest_offset + 1] = colors[idx][1];
                                dest[dest_offset + 2] = colors[idx][2];
                                dest[dest_offset + 3] = colors[idx][3];
                            }
                        }
                    }
                }

                block_idx += 1;
            }
        }
    }

    /// Decompress DXT3 (explicit alpha)
    fn decompressDXT3(source: []const u8, dest: []u8, width: u32, height: u32) void {
        const blocks_x = (width + 3) / 4;
        const blocks_y = (height + 3) / 4;
        var block_idx: usize = 0;

        var by: u32 = 0;
        while (by < blocks_y) : (by += 1) {
            var bx: u32 = 0;
            while (bx < blocks_x) : (bx += 1) {
                const block_offset = block_idx * 16;
                if (block_offset + 16 > source.len) break;

                // First 8 bytes are alpha (4 bits per pixel)
                const alpha_data = source[block_offset..][0..8];

                // Next 8 bytes are color (same as DXT1)
                const color_offset = block_offset + 8;
                const c0 = @as(u16, source[color_offset]) | (@as(u16, source[color_offset + 1]) << 8);
                const c1 = @as(u16, source[color_offset + 2]) | (@as(u16, source[color_offset + 3]) << 8);
                const indices = @as(u32, source[color_offset + 4]) |
                    (@as(u32, source[color_offset + 5]) << 8) |
                    (@as(u32, source[color_offset + 6]) << 16) |
                    (@as(u32, source[color_offset + 7]) << 24);

                var colors: [4][4]u8 = undefined;
                colors[0] = rgb565ToRGBA(c0);
                colors[1] = rgb565ToRGBA(c1);
                colors[2][0] = @intCast((@as(u16, colors[0][0]) * 2 + @as(u16, colors[1][0])) / 3);
                colors[2][1] = @intCast((@as(u16, colors[0][1]) * 2 + @as(u16, colors[1][1])) / 3);
                colors[2][2] = @intCast((@as(u16, colors[0][2]) * 2 + @as(u16, colors[1][2])) / 3);
                colors[2][3] = 255;
                colors[3][0] = @intCast((@as(u16, colors[0][0]) + @as(u16, colors[1][0]) * 2) / 3);
                colors[3][1] = @intCast((@as(u16, colors[0][1]) + @as(u16, colors[1][1]) * 2) / 3);
                colors[3][2] = @intCast((@as(u16, colors[0][2]) + @as(u16, colors[1][2]) * 2) / 3);
                colors[3][3] = 255;

                var py: u32 = 0;
                while (py < 4) : (py += 1) {
                    var px: u32 = 0;
                    while (px < 4) : (px += 1) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x < width and y < height) {
                            const idx = @as(u2, @truncate((indices >> @truncate(((py * 4 + px) * 2)))));
                            const dest_offset = (y * width + x) * 4;

                            // Get alpha from alpha data
                            const alpha_idx = py * 4 + px;
                            const alpha_byte = alpha_data[alpha_idx / 2];
                            const alpha_nibble: u8 = if (alpha_idx % 2 == 0) (alpha_byte & 0x0F) else (alpha_byte >> 4);
                            const alpha: u8 = alpha_nibble * 17; // Scale 0-15 to 0-255

                            if (dest_offset + 4 <= dest.len) {
                                dest[dest_offset] = colors[idx][0];
                                dest[dest_offset + 1] = colors[idx][1];
                                dest[dest_offset + 2] = colors[idx][2];
                                dest[dest_offset + 3] = alpha;
                            }
                        }
                    }
                }

                block_idx += 1;
            }
        }
    }

    /// Decompress DXT5 (interpolated alpha)
    fn decompressDXT5(source: []const u8, dest: []u8, width: u32, height: u32) void {
        const blocks_x = (width + 3) / 4;
        const blocks_y = (height + 3) / 4;
        var block_idx: usize = 0;

        var by: u32 = 0;
        while (by < blocks_y) : (by += 1) {
            var bx: u32 = 0;
            while (bx < blocks_x) : (bx += 1) {
                const block_offset = block_idx * 16;
                if (block_offset + 16 > source.len) break;

                // Alpha block (8 bytes)
                const a0 = source[block_offset];
                const a1 = source[block_offset + 1];

                // Build alpha lookup table
                var alphas: [8]u8 = undefined;
                alphas[0] = a0;
                alphas[1] = a1;

                if (a0 > a1) {
                    alphas[2] = @intCast((@as(u16, a0) * 6 + @as(u16, a1) * 1) / 7);
                    alphas[3] = @intCast((@as(u16, a0) * 5 + @as(u16, a1) * 2) / 7);
                    alphas[4] = @intCast((@as(u16, a0) * 4 + @as(u16, a1) * 3) / 7);
                    alphas[5] = @intCast((@as(u16, a0) * 3 + @as(u16, a1) * 4) / 7);
                    alphas[6] = @intCast((@as(u16, a0) * 2 + @as(u16, a1) * 5) / 7);
                    alphas[7] = @intCast((@as(u16, a0) * 1 + @as(u16, a1) * 6) / 7);
                } else {
                    alphas[2] = @intCast((@as(u16, a0) * 4 + @as(u16, a1) * 1) / 5);
                    alphas[3] = @intCast((@as(u16, a0) * 3 + @as(u16, a1) * 2) / 5);
                    alphas[4] = @intCast((@as(u16, a0) * 2 + @as(u16, a1) * 3) / 5);
                    alphas[5] = @intCast((@as(u16, a0) * 1 + @as(u16, a1) * 4) / 5);
                    alphas[6] = 0;
                    alphas[7] = 255;
                }

                // Read alpha indices (48 bits = 6 bytes starting at offset 2)
                var alpha_bits: u64 = 0;
                var i: usize = 0;
                while (i < 6) : (i += 1) {
                    alpha_bits |= @as(u64, source[block_offset + 2 + i]) << @truncate(i * 8);
                }

                // Color block (same as DXT1, offset 8)
                const color_offset = block_offset + 8;
                const c0 = @as(u16, source[color_offset]) | (@as(u16, source[color_offset + 1]) << 8);
                const c1 = @as(u16, source[color_offset + 2]) | (@as(u16, source[color_offset + 3]) << 8);
                const indices = @as(u32, source[color_offset + 4]) |
                    (@as(u32, source[color_offset + 5]) << 8) |
                    (@as(u32, source[color_offset + 6]) << 16) |
                    (@as(u32, source[color_offset + 7]) << 24);

                var colors: [4][4]u8 = undefined;
                colors[0] = rgb565ToRGBA(c0);
                colors[1] = rgb565ToRGBA(c1);
                colors[2][0] = @intCast((@as(u16, colors[0][0]) * 2 + @as(u16, colors[1][0])) / 3);
                colors[2][1] = @intCast((@as(u16, colors[0][1]) * 2 + @as(u16, colors[1][1])) / 3);
                colors[2][2] = @intCast((@as(u16, colors[0][2]) * 2 + @as(u16, colors[1][2])) / 3);
                colors[2][3] = 255;
                colors[3][0] = @intCast((@as(u16, colors[0][0]) + @as(u16, colors[1][0]) * 2) / 3);
                colors[3][1] = @intCast((@as(u16, colors[0][1]) + @as(u16, colors[1][1]) * 2) / 3);
                colors[3][2] = @intCast((@as(u16, colors[0][2]) + @as(u16, colors[1][2]) * 2) / 3);
                colors[3][3] = 255;

                var py: u32 = 0;
                while (py < 4) : (py += 1) {
                    var px: u32 = 0;
                    while (px < 4) : (px += 1) {
                        const x = bx * 4 + px;
                        const y = by * 4 + py;
                        if (x < width and y < height) {
                            const color_idx = @as(u2, @truncate((indices >> @truncate(((py * 4 + px) * 2)))));
                            const alpha_shift: u6 = @truncate((py * 4 + px) * 3);
                            const alpha_idx = @as(u3, @truncate(alpha_bits >> alpha_shift));

                            const dest_offset = (y * width + x) * 4;
                            if (dest_offset + 4 <= dest.len) {
                                dest[dest_offset] = colors[color_idx][0];
                                dest[dest_offset + 1] = colors[color_idx][1];
                                dest[dest_offset + 2] = colors[color_idx][2];
                                dest[dest_offset + 3] = alphas[alpha_idx];
                            }
                        }
                    }
                }

                block_idx += 1;
            }
        }
    }

    /// Convert RGB565 to RGBA
    fn rgb565ToRGBA(color: u16) [4]u8 {
        const r = @as(u8, @truncate((color >> 11) & 0x1F)) << 3;
        const g = @as(u8, @truncate((color >> 5) & 0x3F)) << 2;
        const b = @as(u8, @truncate(color & 0x1F)) << 3;
        return .{ r, g, b, 255 };
    }

    /// Load texture from BMP file (used for splash screens like Install_Final.bmp)
    pub fn loadBMP(allocator: Allocator, file_path: []const u8) !Texture {
        // Read file
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        const file_data = try allocator.alloc(u8, file_size);
        defer allocator.free(file_data);

        var bytes_read: usize = 0;
        while (bytes_read < file_size) {
            const n = try file.read(file_data[bytes_read..]);
            if (n == 0) break;
            bytes_read += n;
        }

        // Validate file size for headers
        const min_header_size = @sizeOf(BMPFileHeader) + @sizeOf(BMPInfoHeader);
        if (bytes_read < min_header_size) {
            return error.InvalidBMPFile;
        }

        // Parse file header
        const file_header: *const BMPFileHeader = @ptrCast(@alignCast(file_data.ptr));

        // Verify BMP magic
        if (file_header.magic != BMP_MAGIC) {
            return error.InvalidBMPFile;
        }

        // Parse info header
        const info_header: *const BMPInfoHeader = @ptrCast(@alignCast(file_data.ptr + @sizeOf(BMPFileHeader)));

        // Get dimensions (handle negative height for top-down BMPs)
        const width: u32 = @intCast(@abs(info_header.width));
        const height: u32 = @intCast(@abs(info_header.height));
        const is_top_down = info_header.height < 0;
        const bit_count = info_header.bit_count;

        // Only support uncompressed BMPs for now
        if (info_header.compression != 0) {
            std.debug.print("BMP: Unsupported compression: {}\n", .{info_header.compression});
            return error.UnsupportedBMPFormat;
        }

        // Only support 24-bit and 32-bit BMPs
        if (bit_count != 24 and bit_count != 32) {
            std.debug.print("BMP: Unsupported bit depth: {}\n", .{bit_count});
            return error.UnsupportedPixelDepth;
        }

        const bytes_per_pixel: u32 = bit_count / 8;
        const data_offset = file_header.data_offset;

        // BMP rows are padded to 4-byte boundaries
        const row_size_unpadded = width * bytes_per_pixel;
        const row_padding = (4 - (row_size_unpadded % 4)) % 4;
        const row_size_padded = row_size_unpadded + row_padding;

        // Validate data offset and size
        const expected_data_size = row_size_padded * height;
        if (file_data.len < data_offset + expected_data_size) {
            return error.InvalidBMPFile;
        }

        // Allocate output (always RGBA for consistency)
        const output_size = @as(usize, width) * @as(usize, height) * 4;
        const texture_data = try allocator.alloc(u8, output_size);
        errdefer allocator.free(texture_data);

        // Copy pixel data, converting BGR to RGBA and handling row order
        const src_data = file_data[data_offset..];

        var y: u32 = 0;
        while (y < height) : (y += 1) {
            // BMP is bottom-up by default, unless height is negative
            const src_y = if (is_top_down) y else (height - 1 - y);
            const src_row_offset = src_y * row_size_padded;
            const dest_row_offset = y * width * 4;

            var x: u32 = 0;
            while (x < width) : (x += 1) {
                const src_offset = src_row_offset + x * bytes_per_pixel;
                const dest_offset = dest_row_offset + x * 4;

                // BMP stores BGR(A), convert to RGBA
                if (src_offset + bytes_per_pixel <= src_data.len and dest_offset + 4 <= texture_data.len) {
                    texture_data[dest_offset] = src_data[src_offset + 2]; // R from B
                    texture_data[dest_offset + 1] = src_data[src_offset + 1]; // G
                    texture_data[dest_offset + 2] = src_data[src_offset]; // B from R
                    texture_data[dest_offset + 3] = if (bytes_per_pixel == 4) src_data[src_offset + 3] else 255; // A
                }
            }
        }

        return Texture{
            .width = width,
            .height = height,
            .format = .rgba,
            .data = texture_data,
            .allocator = allocator,
        };
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

test "BMP header sizes" {
    try std.testing.expectEqual(@as(usize, 14), @sizeOf(BMPFileHeader));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(BMPInfoHeader));
}

test "DDS header size" {
    try std.testing.expectEqual(@as(usize, 128), @sizeOf(DDSHeader));
}
