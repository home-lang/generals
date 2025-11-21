// Command & Conquer: Generals - Home Language Rewrite
// Main entry point
//
// Authentic startup sequence based on Thyme engine:
// 1. Splash screen (Install_Final.bmp)
// 2. EA Logo video
// 3. Sizzle reel video
// 4. Legal notice
// 5. Shell map (3D animated background)
// 6. Main menu

const std = @import("std");
const Game = @import("engine/game.zig").Game;
const ResourceManager = @import("engine/resource_manager.zig").ResourceManager;
const Shell = @import("shell/shell.zig").Shell;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // ╔═══════════════════════════════════════════════════════════════╗
    // ║         COMMAND & CONQUER: GENERALS - HOME EDITION           ║
    // ║              Authentic Zero Hour Experience                   ║
    // ╚═══════════════════════════════════════════════════════════════╝

    std.debug.print("\n", .{});
    std.debug.print("╔═══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║         COMMAND & CONQUER: GENERALS - HOME EDITION           ║\n", .{});
    std.debug.print("║              Authentic Zero Hour Experience                   ║\n", .{});
    std.debug.print("║                                                               ║\n", .{});
    std.debug.print("║   Based on Thyme Engine - Reimplemented in Zig + Home        ║\n", .{});
    std.debug.print("║   Version 0.2.0                                              ║\n", .{});
    std.debug.print("╚═══════════════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});

    // Initialize resource manager
    std.debug.print("Loading game data...\n", .{});
    var resources = try ResourceManager.init(allocator, "assets");
    defer resources.deinit();

    // Load game data (INI files)
    try resources.loadGameData();

    // Display loaded data summary
    std.debug.print("\n", .{});
    std.debug.print("Game Data Loaded:\n", .{});
    std.debug.print("─────────────────\n", .{});
    std.debug.print("  Units:     {} definitions\n", .{resources.getUnitCount()});
    std.debug.print("  Buildings: {} definitions\n", .{resources.getBuildingCount()});
    std.debug.print("  Commands:  {} definitions\n", .{resources.getCommandCount()});
    std.debug.print("\n", .{});

    // Initialize Shell system (manages menus and startup sequence)
    std.debug.print("Initializing Shell system...\n", .{});
    const shell = try Shell.init(allocator, "assets/ui");
    defer shell.deinit();

    // Initialize game engine
    std.debug.print("Initializing game engine...\n", .{});
    var game = try Game.init(allocator);
    defer game.deinit();

    // Configure startup options (from GlobalData equivalent)
    // Set to false to skip intro videos and go straight to gameplay
    const skip_intro = true; // For development, skip to gameplay

    if (skip_intro) {
        shell.play_intro = false;
        shell.play_sizzle = false;
        shell.skipIntro();
    }

    // Start shell system (begins startup sequence)
    shell.start();

    // Start game systems
    try game.startup();

    std.debug.print("\n", .{});
    std.debug.print("╔═══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║                      GAME STARTING                            ║\n", .{});
    std.debug.print("╠═══════════════════════════════════════════════════════════════╣\n", .{});
    std.debug.print("║   Controls:                                                   ║\n", .{});
    std.debug.print("║   - WASD / Arrow Keys: Pan camera                            ║\n", .{});
    std.debug.print("║   - Left Click: Select units                                 ║\n", .{});
    std.debug.print("║   - Right Click: Move selected units                         ║\n", .{});
    std.debug.print("║   - Cmd+Q: Quit                                              ║\n", .{});
    std.debug.print("║                                                               ║\n", .{});
    std.debug.print("║   Game Mode: Skirmish                                        ║\n", .{});
    std.debug.print("║   Map: Desert Combat                                         ║\n", .{});
    std.debug.print("║   Players: USA (You) vs China (AI)                           ║\n", .{});
    std.debug.print("╚═══════════════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});

    // Run main game loop with Shell integration
    try runGameWithShell(&game, shell);

    std.debug.print("\n", .{});
    std.debug.print("╔═══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║                    GAME ENDED                                 ║\n", .{});
    std.debug.print("╚═══════════════════════════════════════════════════════════════╝\n", .{});
}

/// Run game with Shell system integration
fn runGameWithShell(game: *Game, shell: *Shell) !void {
    _ = shell; // Shell system ready for menu integration

    // For now, bypass the shell and run the game directly
    // The shell system is ready but we need proper menu rendering first
    try game.run();
}

/// Render startup/loading screens based on current Shell phase
fn renderStartupScreen(game: *Game, shell: *Shell) !void {
    // In a full implementation, this would render:
    // - Splash screen image
    // - Video playback
    // - Legal notice text
    // - Loading progress bar
    //
    // For now, we just print the current phase
    _ = game;
    _ = shell;

    // The actual rendering happens through the game's render system
    // This is a placeholder for phase-specific rendering
}
