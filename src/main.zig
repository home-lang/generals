// Command & Conquer: Generals - Home Language Rewrite
// Main entry point

const std = @import("std");
const Game = @import("engine/game.zig").Game;
const ResourceManager = @import("engine/resource_manager.zig").ResourceManager;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n", .{});
    std.debug.print("╔═══════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║   Command & Conquer: Generals - Home Edition         ║\n", .{});
    std.debug.print("║   Version 0.1.0 - Engine Foundation                  ║\n", .{});
    std.debug.print("╚═══════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});

    // Initialize resource manager
    var resources = try ResourceManager.init(allocator, "assets");
    defer resources.deinit();

    // Load game data
    try resources.loadGameData();

    // Print some loaded data as proof of concept
    std.debug.print("\n", .{});
    std.debug.print("Sample Unit Data:\n", .{});
    std.debug.print("─────────────────\n", .{});

    const sample_units = [_][]const u8{
        "AmericaInfantryRanger",
        "AmericaTankCrusader",
        "GLAInfantryTerrorist",
    };

    for (sample_units) |unit_name| {
        if (resources.getUnitDef(unit_name)) |unit| {
            std.debug.print("\n{s}:\n", .{unit_name});

            if (unit.get("Side")) |side| {
                std.debug.print("  Side: {s}\n", .{side});
            }
            if (unit.getFloat("VisionRange")) |vision| {
                std.debug.print("  Vision Range: {d}\n", .{vision});
            }
            if (unit.getBool("IsTrainable")) |trainable| {
                std.debug.print("  Trainable: {}\n", .{trainable});
            }
        }
    }

    // Initialize game
    std.debug.print("\n", .{});
    var game = try Game.init(allocator);
    defer game.deinit();

    // Start game systems
    try game.startup();

    std.debug.print("\n", .{});

    // Run game loop
    try game.run();

    std.debug.print("\nShutting down...\n", .{});
}
