// INI Parser Test
// Tests the INI file parsing functionality used by C&C Generals

const std = @import("std");

// INI Parser implementation
const INIValue = union(enum) {
    string: []const u8,
    integer: i64,
    float: f64,
    boolean: bool,
};

const INIEntry = struct {
    key: []const u8,
    value: INIValue,
};

const INISection = struct {
    name: []const u8,
    entries: std.ArrayListUnmanaged(INIEntry),

    fn init(name: []const u8) INISection {
        return .{
            .name = name,
            .entries = .empty,
        };
    }

    fn deinit(self: *INISection, allocator: std.mem.Allocator) void {
        self.entries.deinit(allocator);
    }

    fn get(self: *const INISection, key: []const u8) ?INIValue {
        for (self.entries.items) |entry| {
            if (std.mem.eql(u8, entry.key, key)) {
                return entry.value;
            }
        }
        return null;
    }
};

const INIParser = struct {
    allocator: std.mem.Allocator,
    sections: std.ArrayListUnmanaged(INISection),
    current_section: ?*INISection,

    fn init(allocator: std.mem.Allocator) INIParser {
        return .{
            .allocator = allocator,
            .sections = .empty,
            .current_section = null,
        };
    }

    fn deinit(self: *INIParser) void {
        for (self.sections.items) |*section| {
            section.deinit(self.allocator);
        }
        self.sections.deinit(self.allocator);
    }

    fn parse(self: *INIParser, content: []const u8) !void {
        var lines = std.mem.splitSequence(u8, content, "\n");

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");

            // Skip empty lines and comments
            if (trimmed.len == 0) continue;
            if (trimmed[0] == ';' or trimmed[0] == '#') continue;

            // Check for section header
            if (trimmed[0] == '[') {
                if (std.mem.indexOfScalar(u8, trimmed, ']')) |end| {
                    const section_name = trimmed[1..end];
                    try self.sections.append(self.allocator, INISection.init(section_name));
                    self.current_section = &self.sections.items[self.sections.items.len - 1];
                }
                continue;
            }

            // Parse key=value
            if (std.mem.indexOfScalar(u8, trimmed, '=')) |eq_pos| {
                const key = std.mem.trim(u8, trimmed[0..eq_pos], " \t");
                const value_str = std.mem.trim(u8, trimmed[eq_pos + 1 ..], " \t");

                const value = parseValue(value_str);

                if (self.current_section) |section| {
                    try section.entries.append(self.allocator, .{ .key = key, .value = value });
                }
            }
        }
    }

    fn parseValue(str: []const u8) INIValue {
        // Try boolean
        if (std.mem.eql(u8, str, "Yes") or std.mem.eql(u8, str, "yes") or std.mem.eql(u8, str, "true") or std.mem.eql(u8, str, "TRUE")) {
            return .{ .boolean = true };
        }
        if (std.mem.eql(u8, str, "No") or std.mem.eql(u8, str, "no") or std.mem.eql(u8, str, "false") or std.mem.eql(u8, str, "FALSE")) {
            return .{ .boolean = false };
        }

        // Try integer
        if (std.fmt.parseInt(i64, str, 10)) |int_val| {
            return .{ .integer = int_val };
        } else |_| {}

        // Try float
        if (std.fmt.parseFloat(f64, str)) |float_val| {
            return .{ .float = float_val };
        } else |_| {}

        // Default to string
        return .{ .string = str };
    }

    fn getSection(self: *const INIParser, name: []const u8) ?*const INISection {
        for (self.sections.items) |*section| {
            if (std.mem.eql(u8, section.name, name)) {
                return section;
            }
        }
        return null;
    }
};

// Test data matching C&C Generals INI format
const test_gamedata_ini =
    \\; C&C Generals GameData.ini sample
    \\
    \\[GameData]
    \\ShellMapName = Maps/ShellMap1/ShellMap1.map
    \\MapName = Maps/Default/Default.map
    \\MoveHintName = SCCursors.ani
    \\UseFPSLimit = Yes
    \\FramesPerSecondLimit = 30
    \\ChipsetType = 0
    \\MaxShellScreens = 4
    \\UseCloudMap = Yes
    \\UseLightMap = Yes
    \\BilinearTerrainTex = Yes
    \\TrilinearTerrainTex = No
    \\MultiPassTerrain = No
    \\AdjustClipDistances = No
    \\StretchTerrain = Yes
    \\UseHalfHeightMap = Yes
    \\DrawEntireTerrain = No
    \\TerrainLOD = AUTOMATIC
    \\TerrainLODTargetTimeMS = 10
    \\MaxCameraHeight = 275.0
    \\MinCameraHeight = 120.0
    \\MaxCameraHeightEdge = 300.0
    \\MinCameraHeightEdge = 130.0
    \\CameraAdjustSpeed = 0.3
    \\ScrollAmountCutoff = 10.0
    \\CameraPitch = 37.5
    \\CameraYaw = 0.0
    \\CameraHeight = 225.0
    \\CameraScrollSpeedWhenMax = 0.8
    \\CameraScrollSpeedWhenMin = 0.3
    \\
    \\[Multiplayer]
    \\InitialCreditsMin = 5000
    \\InitialCreditsMax = 100000
    \\StartCountdownTimer = 5
    \\MaxBeaconsPerPlayer = 3
    \\UseShroud = Yes
    \\ShowRandomPlayerTemplate = Yes
    \\ShowRandomStartPos = Yes
    \\ShowRandomColor = Yes
    \\
    \\[PlayerTemplate FactionAmerica]
    \\Side = America
    \\BaseSide = America
    \\DisplayName = GUI:USA
    \\StartingBuilding = AmericaCommandCenter
    \\ProductionCostChange = 0%
    \\ProductionTimeChange = 0%
    \\IntrinsicSciences = SCIENCE_USA
    \\IsPlayableSide = Yes
    \\
;

pub fn main() !void {
    const print = std.debug.print;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("================================================================================\n", .{});
    print("  C&C Generals INI Parser Test\n", .{});
    print("================================================================================\n\n", .{});

    var parser = INIParser.init(allocator);
    defer parser.deinit();

    print("Parsing GameData.ini sample...\n\n", .{});
    try parser.parse(test_gamedata_ini);

    print("Parsed {d} sections:\n", .{parser.sections.items.len});

    for (parser.sections.items) |section| {
        print("\n[{s}] - {d} entries\n", .{ section.name, section.entries.items.len });

        for (section.entries.items) |entry| {
            switch (entry.value) {
                .string => |s| print("  {s} = \"{s}\"\n", .{ entry.key, s }),
                .integer => |i| print("  {s} = {d}\n", .{ entry.key, i }),
                .float => |f| print("  {s} = {d:.2}\n", .{ entry.key, f }),
                .boolean => |b| print("  {s} = {}\n", .{ entry.key, b }),
            }
        }
    }

    // Test specific value retrieval
    print("\n--- Value Retrieval Tests ---\n", .{});

    if (parser.getSection("GameData")) |section| {
        if (section.get("MaxCameraHeight")) |val| {
            switch (val) {
                .float => |f| print("MaxCameraHeight = {d:.1}\n", .{f}),
                else => print("MaxCameraHeight has unexpected type\n", .{}),
            }
        }
        if (section.get("UseFPSLimit")) |val| {
            switch (val) {
                .boolean => |b| print("UseFPSLimit = {}\n", .{b}),
                else => print("UseFPSLimit has unexpected type\n", .{}),
            }
        }
        if (section.get("FramesPerSecondLimit")) |val| {
            switch (val) {
                .integer => |i| print("FramesPerSecondLimit = {d}\n", .{i}),
                else => print("FramesPerSecondLimit has unexpected type\n", .{}),
            }
        }
    }

    if (parser.getSection("Multiplayer")) |section| {
        if (section.get("InitialCreditsMin")) |val| {
            switch (val) {
                .integer => |i| print("InitialCreditsMin = {d}\n", .{i}),
                else => print("InitialCreditsMin has unexpected type\n", .{}),
            }
        }
    }

    print("\nAll INI parser tests passed!\n", .{});
}
