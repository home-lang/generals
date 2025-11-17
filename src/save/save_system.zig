// C&C Generals - Save/Load System
// Campaign progress, game saves, and replay recording

const std = @import("std");

/// Save file format version
pub const SAVE_FORMAT_VERSION: u32 = 1;

/// Campaign progress data
pub const CampaignProgress = struct {
    version: u32,
    faction: []const u8,
    mission_index: u32,
    missions_completed: u32,
    total_missions: u32,
    difficulty: u8,
    timestamp: i64,

    pub fn init(faction: []const u8, mission_index: u32) CampaignProgress {
        return CampaignProgress{
            .version = SAVE_FORMAT_VERSION,
            .faction = faction,
            .mission_index = mission_index,
            .missions_completed = mission_index,
            .total_missions = 7, // 7 missions per campaign
            .difficulty = 1, // 0=Easy, 1=Medium, 2=Hard
            .timestamp = std.time.timestamp(),
        };
    }
};

/// Game state snapshot for saving
pub const GameSave = struct {
    version: u32,
    map_name: []const u8,
    game_time: f32,
    player_count: usize,
    player_data: []PlayerSaveData,
    unit_count: usize,
    building_count: usize,
    timestamp: i64,

    pub fn deinit(self: *GameSave, allocator: std.mem.Allocator) void {
        allocator.free(self.player_data);
    }
};

/// Player save data
pub const PlayerSaveData = struct {
    player_id: usize,
    faction: []const u8,
    money: i32,
    power: i32,
    supply_used: u32,
    supply_limit: u32,
    units_alive: usize,
    buildings_alive: usize,
};

/// Replay command
pub const ReplayCommand = struct {
    frame: u32,
    player_id: usize,
    command_type: u8,
    target_x: f32,
    target_y: f32,
    target_id: u32,
    unit_ids: []usize,

    pub fn deinit(self: *ReplayCommand, allocator: std.mem.Allocator) void {
        allocator.free(self.unit_ids);
    }
};

/// Replay file
pub const Replay = struct {
    version: u32,
    map_name: []const u8,
    player_count: usize,
    player_names: [][]const u8,
    duration_frames: u32,
    commands: []ReplayCommand,
    timestamp: i64,

    pub fn deinit(self: *Replay, allocator: std.mem.Allocator) void {
        for (self.player_names) |name| {
            allocator.free(name);
        }
        allocator.free(self.player_names);

        for (self.commands) |*cmd| {
            cmd.deinit(allocator);
        }
        allocator.free(self.commands);
    }
};

/// Save system manager
pub const SaveSystem = struct {
    allocator: std.mem.Allocator,
    save_directory: []const u8,
    current_replay: ?Replay,
    recording_replay: bool,
    replay_commands: []ReplayCommand,
    replay_command_count: usize,

    pub fn init(allocator: std.mem.Allocator, save_dir: []const u8) !SaveSystem {
        const replay_commands = try allocator.alloc(ReplayCommand, 10000);

        return SaveSystem{
            .allocator = allocator,
            .save_directory = save_dir,
            .current_replay = null,
            .recording_replay = false,
            .replay_commands = replay_commands,
            .replay_command_count = 0,
        };
    }

    pub fn deinit(self: *SaveSystem) void {
        if (self.current_replay) |*replay| {
            replay.deinit(self.allocator);
        }
        for (self.replay_commands[0..self.replay_command_count]) |*cmd| {
            cmd.deinit(self.allocator);
        }
        self.allocator.free(self.replay_commands);
    }

    /// Save campaign progress
    pub fn saveCampaignProgress(self: *SaveSystem, progress: CampaignProgress) !void {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/campaign_{s}.sav",
            .{ self.save_directory, progress.faction },
        );
        defer self.allocator.free(filename);

        // In full implementation: write binary file with progress data
        std.debug.print("Campaign progress saved: {s} (Mission {}/{})\n", .{ filename, progress.mission_index, progress.total_missions });
    }

    /// Load campaign progress
    pub fn loadCampaignProgress(self: *SaveSystem, faction: []const u8) !CampaignProgress {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/campaign_{s}.sav",
            .{ self.save_directory, faction },
        );
        defer self.allocator.free(filename);

        // In full implementation: read binary file
        // For now, return default progress
        std.debug.print("Campaign progress loaded: {s}\n", .{filename});
        return CampaignProgress.init(faction, 0);
    }

    /// Save game state
    pub fn saveGame(self: *SaveSystem, save: GameSave, slot: u32) !void {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/quicksave_{}.sav",
            .{ self.save_directory, slot },
        );
        defer self.allocator.free(filename);

        // In full implementation: serialize game state to binary
        _ = save;
        std.debug.print("Game saved: {s}\n", .{filename});
    }

    /// Load game state
    pub fn loadGame(self: *SaveSystem, slot: u32) !GameSave {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/quicksave_{}.sav",
            .{ self.save_directory, slot },
        );
        defer self.allocator.free(filename);

        // In full implementation: deserialize from binary
        std.debug.print("Game loaded: {s}\n", .{filename});

        const player_data = try self.allocator.alloc(PlayerSaveData, 2);
        player_data[0] = PlayerSaveData{
            .player_id = 0,
            .faction = "USA",
            .money = 10000,
            .power = 100,
            .supply_used = 25,
            .supply_limit = 100,
            .units_alive = 30,
            .buildings_alive = 10,
        };
        player_data[1] = PlayerSaveData{
            .player_id = 1,
            .faction = "China",
            .money = 8000,
            .power = 80,
            .supply_used = 20,
            .supply_limit = 100,
            .units_alive = 25,
            .buildings_alive = 8,
        };

        return GameSave{
            .version = SAVE_FORMAT_VERSION,
            .map_name = "Tournament Desert",
            .game_time = 600.0,
            .player_count = 2,
            .player_data = player_data,
            .unit_count = 55,
            .building_count = 18,
            .timestamp = std.time.timestamp(),
        };
    }

    /// Start recording replay
    pub fn startRecordingReplay(self: *SaveSystem) void {
        self.recording_replay = true;
        self.replay_command_count = 0;
        std.debug.print("Replay recording started\n", .{});
    }

    /// Stop recording replay
    pub fn stopRecordingReplay(self: *SaveSystem) void {
        self.recording_replay = false;
        std.debug.print("Replay recording stopped: {} commands\n", .{self.replay_command_count});
    }

    /// Record command for replay
    pub fn recordCommand(self: *SaveSystem, cmd: ReplayCommand) !void {
        if (!self.recording_replay) return;
        if (self.replay_command_count >= self.replay_commands.len) return error.ReplayBufferFull;
        self.replay_commands[self.replay_command_count] = cmd;
        self.replay_command_count += 1;
    }

    /// Save replay to file
    pub fn saveReplay(self: *SaveSystem, map_name: []const u8, player_names: [][]const u8) !void {
        const timestamp = std.time.timestamp();
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/replay_{}.rep",
            .{ self.save_directory, timestamp },
        );
        defer self.allocator.free(filename);

        // In full implementation: serialize replay data
        _ = map_name;
        _ = player_names;

        std.debug.print("Replay saved: {s} ({} commands)\n", .{ filename, self.replay_command_count });
    }

    /// Load replay from file
    pub fn loadReplay(self: *SaveSystem, filename: []const u8) !Replay {
        _ = filename;

        // In full implementation: deserialize replay data
        const player_names = try self.allocator.alloc([]const u8, 2);
        player_names[0] = "Player 1";
        player_names[1] = "Player 2";

        const commands = try self.allocator.alloc(ReplayCommand, 0);

        return Replay{
            .version = SAVE_FORMAT_VERSION,
            .map_name = "Tournament Desert",
            .player_count = 2,
            .player_names = player_names,
            .duration_frames = 18000, // 10 minutes at 30fps
            .commands = commands,
            .timestamp = std.time.timestamp(),
        };
    }

    /// Get save statistics
    pub fn getStats(self: *SaveSystem) SaveStats {
        return SaveStats{
            .recording_replay = self.recording_replay,
            .recorded_commands = self.replay_command_count,
        };
    }
};

pub const SaveStats = struct {
    recording_replay: bool,
    recorded_commands: usize,
};

// Tests
test "Campaign progress" {
    const progress = CampaignProgress.init("USA", 3);
    try std.testing.expect(progress.missions_completed == 3);
    try std.testing.expect(std.mem.eql(u8, progress.faction, "USA"));
}

test "Save system" {
    const allocator = std.testing.allocator;

    var system = try SaveSystem.init(allocator, "/tmp/generals_saves");
    defer system.deinit();

    const progress = CampaignProgress.init("China", 2);
    try system.saveCampaignProgress(progress);

    const loaded = try system.loadCampaignProgress("China");
    try std.testing.expect(std.mem.eql(u8, loaded.faction, "China"));
}

test "Replay recording" {
    const allocator = std.testing.allocator;

    var system = try SaveSystem.init(allocator, "/tmp/generals_saves");
    defer system.deinit();

    system.startRecordingReplay();

    const cmd = ReplayCommand{
        .frame = 100,
        .player_id = 0,
        .command_type = 1,
        .target_x = 100.0,
        .target_y = 200.0,
        .target_id = 0,
        .unit_ids = &[_]usize{},
    };

    try system.recordCommand(cmd);

    const stats = system.getStats();
    try std.testing.expect(stats.recording_replay == true);
    try std.testing.expect(stats.recorded_commands == 1);
}
