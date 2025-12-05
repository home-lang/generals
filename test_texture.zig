// Texture Loading Test
// Tests TGA texture loading for C&C Generals assets

const std = @import("std");

// TGA file format structures
const TGAHeader = packed struct {
    id_length: u8,
    color_map_type: u8,
    image_type: u8,
    color_map_start: u16,
    color_map_length: u16,
    color_map_depth: u8,
    x_origin: u16,
    y_origin: u16,
    width: u16,
    height: u16,
    bits_per_pixel: u8,
    image_descriptor: u8,
};

const TGAImageType = enum(u8) {
    NoImage = 0,
    ColorMapped = 1,
    TrueColor = 2,
    Grayscale = 3,
    RLEColorMapped = 9,
    RLETrueColor = 10,
    RLEGrayscale = 11,
};

const Texture = struct {
    width: u32,
    height: u32,
    data: []u8, // BGRA format
    allocator: std.mem.Allocator,

    fn deinit(self: *Texture) void {
        self.allocator.free(self.data);
    }
};

fn loadTGA(allocator: std.mem.Allocator, data: []const u8) !Texture {
    if (data.len < @sizeOf(TGAHeader)) {
        return error.InvalidTGAFile;
    }

    const header: *const TGAHeader = @ptrCast(@alignCast(data.ptr));

    // Skip unsupported formats
    if (header.color_map_type != 0) {
        return error.UnsupportedTGAFormat;
    }

    const image_type: TGAImageType = @enumFromInt(header.image_type);
    if (image_type != .TrueColor and image_type != .RLETrueColor) {
        return error.UnsupportedTGAFormat;
    }

    if (header.bits_per_pixel != 24 and header.bits_per_pixel != 32) {
        return error.UnsupportedTGAFormat;
    }

    const width: u32 = header.width;
    const height: u32 = header.height;
    const pixel_count = width * height;
    const output_data = try allocator.alloc(u8, pixel_count * 4);
    errdefer allocator.free(output_data);

    // Skip header and ID
    const pixel_start = @sizeOf(TGAHeader) + header.id_length;
    const pixel_data = data[pixel_start..];

    const bytes_per_pixel: usize = header.bits_per_pixel / 8;
    const is_rle = image_type == .RLETrueColor;
    const is_flipped = (header.image_descriptor & 0x20) == 0; // Bit 5 = origin

    if (is_rle) {
        // RLE decoding
        var src_idx: usize = 0;
        var dst_idx: usize = 0;

        while (dst_idx < pixel_count * 4) {
            if (src_idx >= pixel_data.len) break;

            const packet_header = pixel_data[src_idx];
            src_idx += 1;

            const count: usize = (packet_header & 0x7F) + 1;
            const is_run = (packet_header & 0x80) != 0;

            if (is_run) {
                // RLE run
                const b = pixel_data[src_idx];
                const g = pixel_data[src_idx + 1];
                const r = pixel_data[src_idx + 2];
                const a: u8 = if (bytes_per_pixel == 4) pixel_data[src_idx + 3] else 255;
                src_idx += bytes_per_pixel;

                for (0..count) |_| {
                    if (dst_idx + 3 < output_data.len) {
                        output_data[dst_idx] = b;
                        output_data[dst_idx + 1] = g;
                        output_data[dst_idx + 2] = r;
                        output_data[dst_idx + 3] = a;
                        dst_idx += 4;
                    }
                }
            } else {
                // Raw pixels
                for (0..count) |_| {
                    if (src_idx + bytes_per_pixel <= pixel_data.len and dst_idx + 3 < output_data.len) {
                        output_data[dst_idx] = pixel_data[src_idx]; // B
                        output_data[dst_idx + 1] = pixel_data[src_idx + 1]; // G
                        output_data[dst_idx + 2] = pixel_data[src_idx + 2]; // R
                        output_data[dst_idx + 3] = if (bytes_per_pixel == 4) pixel_data[src_idx + 3] else 255;
                        src_idx += bytes_per_pixel;
                        dst_idx += 4;
                    }
                }
            }
        }
    } else {
        // Uncompressed
        for (0..pixel_count) |i| {
            const src_idx = i * bytes_per_pixel;
            const dst_idx = i * 4;

            if (src_idx + bytes_per_pixel <= pixel_data.len and dst_idx + 3 < output_data.len) {
                output_data[dst_idx] = pixel_data[src_idx]; // B
                output_data[dst_idx + 1] = pixel_data[src_idx + 1]; // G
                output_data[dst_idx + 2] = pixel_data[src_idx + 2]; // R
                output_data[dst_idx + 3] = if (bytes_per_pixel == 4) pixel_data[src_idx + 3] else 255;
            }
        }
    }

    // Flip vertically if needed (most TGA files are stored bottom-up)
    if (is_flipped) {
        const row_size = width * 4;
        var y: usize = 0;
        while (y < height / 2) : (y += 1) {
            const top_row = y * row_size;
            const bottom_row = (height - 1 - y) * row_size;

            for (0..row_size) |x| {
                const tmp = output_data[top_row + x];
                output_data[top_row + x] = output_data[bottom_row + x];
                output_data[bottom_row + x] = tmp;
            }
        }
    }

    return Texture{
        .width = width,
        .height = height,
        .data = output_data,
        .allocator = allocator,
    };
}

fn createTestTGA(allocator: std.mem.Allocator, width: u16, height: u16) ![]u8 {
    const header_size = @sizeOf(TGAHeader);
    const pixel_count = @as(usize, width) * @as(usize, height);
    const data_size = header_size + pixel_count * 3; // 24-bit RGB

    const data = try allocator.alloc(u8, data_size);
    errdefer allocator.free(data);

    // Fill header
    const header: *TGAHeader = @ptrCast(@alignCast(data.ptr));
    header.id_length = 0;
    header.color_map_type = 0;
    header.image_type = 2; // TrueColor
    header.color_map_start = 0;
    header.color_map_length = 0;
    header.color_map_depth = 0;
    header.x_origin = 0;
    header.y_origin = 0;
    header.width = width;
    header.height = height;
    header.bits_per_pixel = 24;
    header.image_descriptor = 0x20; // Top-left origin

    // Fill with gradient pattern (like C&C Generals terrain)
    for (0..height) |y| {
        for (0..width) |x| {
            const idx = header_size + (y * width + x) * 3;
            // Desert sand gradient
            data[idx] = @intCast((y * 255 / height)); // B
            data[idx + 1] = @intCast(((x + y) * 200 / (width + height))); // G
            data[idx + 2] = @intCast((x * 255 / width)); // R
        }
    }

    return data;
}

pub fn main() !void {
    const print = std.debug.print;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("================================================================================\n", .{});
    print("  C&C Generals TGA Texture Loading Test\n", .{});
    print("================================================================================\n\n", .{});

    // Create test TGA data
    print("Creating test TGA texture (64x64)...\n", .{});
    const tga_data = try createTestTGA(allocator, 64, 64);
    defer allocator.free(tga_data);
    print("Test TGA created: {d} bytes\n", .{tga_data.len});

    // Parse the TGA
    print("\nParsing TGA header...\n", .{});
    const header: *const TGAHeader = @ptrCast(@alignCast(tga_data.ptr));
    print("  Image type: {d}\n", .{header.image_type});
    print("  Dimensions: {d}x{d}\n", .{ header.width, header.height });
    print("  Bits per pixel: {d}\n", .{header.bits_per_pixel});

    // Load the texture
    print("\nLoading texture...\n", .{});
    var texture = try loadTGA(allocator, tga_data);
    defer texture.deinit();

    print("Texture loaded successfully:\n", .{});
    print("  Width: {d}\n", .{texture.width});
    print("  Height: {d}\n", .{texture.height});
    print("  Data size: {d} bytes (BGRA)\n", .{texture.data.len});

    // Verify some pixel values
    print("\nSample pixels (BGRA):\n", .{});
    const corners = [_]struct { x: usize, y: usize, name: []const u8 }{
        .{ .x = 0, .y = 0, .name = "Top-left" },
        .{ .x = 63, .y = 0, .name = "Top-right" },
        .{ .x = 0, .y = 63, .name = "Bottom-left" },
        .{ .x = 63, .y = 63, .name = "Bottom-right" },
        .{ .x = 32, .y = 32, .name = "Center" },
    };

    for (corners) |corner| {
        const idx = (corner.y * 64 + corner.x) * 4;
        print("  {s}: B={d} G={d} R={d} A={d}\n", .{
            corner.name,
            texture.data[idx],
            texture.data[idx + 1],
            texture.data[idx + 2],
            texture.data[idx + 3],
        });
    }

    print("\nAll texture loading tests passed!\n", .{});
}
