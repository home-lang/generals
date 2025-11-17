// C&C Generals - Skirmish Mode
// Singleplayer vs AI or multiplayer skirmish battles

const std = @import("std");

/// Game difficulty settings
pub const Difficulty = enum {
    Easy,
    Medium,
    Hard,
    Brutal,

    pub fn getAIMultiplier(self: Difficulty) f32 {
        return switch (self) {
            .Easy => 0.7,
            .Medium => 1.0,
            .Hard => 1.3,
            .Brutal => 1.6,
        };
    }
};

/// Starting resources preset
pub const StartingResources = enum {
    Low,        // $5,000
    Standard,   // $10,000
    High,       // $20,000
    Unlimited,  // Infinite money

    pub fn getMoney(self: StartingResources) i32 {
        return switch (self) {
            .Low => 5000,
            .Standard => 10000,
            .High => 20000,
            .Unlimited => 999999,
        };
    }
};

/// Game speed settings
pub const GameSpeed = enum {
    Slow,       // 0.75x
    Normal,     // 1.0x
    Fast,       // 1.5x
    VeryFast,   // 2.0x

    pub fn getMultiplier(self: GameSpeed) f32 {
        return switch (self) {
            .Slow => 0.75,
            .Normal => 1.0,
            .Fast => 1.5,
            .VeryFast => 2.0,
        };
    }
};

/// Player setup for skirmish
pub const SkirmishPlayer = struct {
    player_id: usize,
    name: []const u8,
    faction: []const u8,
    team: u8,
    color: u32,
    start_position: usize,
    is_human: bool,
    ai_difficulty: Difficulty,
};

/// Skirmish game settings
pub const SkirmishSettings = struct {
    map_name: []const u8,
    players: []SkirmishPlayer,
    player_count: usize,
    starting_resources: StartingResources,
    game_speed: GameSpeed,
    tech_level: u8, // 0-5
    superweapons_enabled: bool,
    fog_of_war: bool,
    time_limit_minutes: u32, // 0 = no limit
    score_limit: u32, // 0 = no limit
    allow_cheats: bool,

    pub fn deinit(self: *SkirmishSettings, allocator: std.mem.Allocator) void {
        allocator.free(self.players);
    }
};

/// Skirmish game state
pub const SkirmishGame = struct {
    allocator: std.mem.Allocator,
    settings: SkirmishSettings,
    game_time: f32,
    is_paused: bool,
    is_finished: bool,
    winner_id: ?usize,
    player_scores: []u32,

    pub fn init(allocator: std.mem.Allocator, settings: SkirmishSettings) !SkirmishGame {
        const player_scores = try allocator.alloc(u32, settings.player_count);
        for (player_scores) |*score| {
            score.* = 0;
        }

        return SkirmishGame{
            .allocator = allocator,
            .settings = settings,
            .game_time = 0.0,
            .is_paused = false,
            .is_finished = false,
            .winner_id = null,
            .player_scores = player_scores,
        };
    }

    pub fn deinit(self: *SkirmishGame) void {
        self.allocator.free(self.player_scores);
        self.settings.deinit(self.allocator);
    }

    pub fn update(self: *SkirmishGame, delta_time: f32) void {
        if (self.is_paused or self.is_finished) return;

        // Apply game speed multiplier
        const adjusted_dt = delta_time * self.settings.game_speed.getMultiplier();
        self.game_time += adjusted_dt;

        // Check time limit
        if (self.settings.time_limit_minutes > 0) {
            const time_limit_seconds = @as(f32, @floatFromInt(self.settings.time_limit_minutes)) * 60.0;
            if (self.game_time >= time_limit_seconds) {
                self.endGame();
            }
        }

        // Check score limit
        if (self.settings.score_limit > 0) {
            for (self.player_scores, 0..) |score, player_id| {
                if (score >= self.settings.score_limit) {
                    self.winner_id = player_id;
                    self.endGame();
                    return;
                }
            }
        }

        // In full implementation: update game logic
        // - Update all units
        // - Update AI players
        // - Process combat
        // - Check victory conditions
    }

    pub fn pause(self: *SkirmishGame) void {
        self.is_paused = true;
    }

    pub fn resumeGame(self: *SkirmishGame) void {
        self.is_paused = false;
    }

    pub fn endGame(self: *SkirmishGame) void {
        self.is_finished = true;

        // Find winner by highest score if not already set
        if (self.winner_id == null) {
            var highest_score: u32 = 0;
            var winner: usize = 0;

            for (self.player_scores, 0..) |score, player_id| {
                if (score > highest_score) {
                    highest_score = score;
                    winner = player_id;
                }
            }

            self.winner_id = winner;
        }

        std.debug.print("Game finished! Winner: Player {}\n", .{self.winner_id.?});
    }

    pub fn addScore(self: *SkirmishGame, player_id: usize, points: u32) void {
        if (player_id < self.player_scores.len) {
            self.player_scores[player_id] += points;
        }
    }
};

/// Skirmish mode manager
pub const SkirmishManager = struct {
    allocator: std.mem.Allocator,
    current_game: ?SkirmishGame,
    available_maps: [][]const u8,
    available_maps_count: usize,

    pub fn init(allocator: std.mem.Allocator) !SkirmishManager {
        const available_maps = try allocator.alloc([]const u8, 50);

        return SkirmishManager{
            .allocator = allocator,
            .current_game = null,
            .available_maps = available_maps,
            .available_maps_count = 0,
        };
    }

    pub fn deinit(self: *SkirmishManager) void {
        if (self.current_game) |*game| {
            game.deinit();
        }
        self.allocator.free(self.available_maps);
    }

    /// Create a new skirmish game
    pub fn createGame(self: *SkirmishManager, settings: SkirmishSettings) !void {
        // End current game if exists
        if (self.current_game) |*game| {
            game.deinit();
        }

        self.current_game = try SkirmishGame.init(self.allocator, settings);
        std.debug.print("Skirmish game created: {s}\n", .{settings.map_name});
    }

    /// Create quick match (1v1 vs AI)
    pub fn createQuickMatch(
        self: *SkirmishManager,
        map_name: []const u8,
        player_faction: []const u8,
        ai_faction: []const u8,
        ai_difficulty: Difficulty,
    ) !void {
        const players = try self.allocator.alloc(SkirmishPlayer, 2);

        players[0] = SkirmishPlayer{
            .player_id = 0,
            .name = "Player",
            .faction = player_faction,
            .team = 0,
            .color = 0xFF0000,
            .start_position = 0,
            .is_human = true,
            .ai_difficulty = .Medium,
        };

        players[1] = SkirmishPlayer{
            .player_id = 1,
            .name = "Computer",
            .faction = ai_faction,
            .team = 1,
            .color = 0x0000FF,
            .start_position = 1,
            .is_human = false,
            .ai_difficulty = ai_difficulty,
        };

        const settings = SkirmishSettings{
            .map_name = map_name,
            .players = players,
            .player_count = 2,
            .starting_resources = .Standard,
            .game_speed = .Normal,
            .tech_level = 5,
            .superweapons_enabled = true,
            .fog_of_war = true,
            .time_limit_minutes = 0,
            .score_limit = 0,
            .allow_cheats = false,
        };

        try self.createGame(settings);
    }

    /// Create 2v2 team game
    pub fn createTeamGame(
        self: *SkirmishManager,
        map_name: []const u8,
        ai_difficulty: Difficulty,
    ) !void {
        const players = try self.allocator.alloc(SkirmishPlayer, 4);

        players[0] = SkirmishPlayer{
            .player_id = 0,
            .name = "Player",
            .faction = "USA",
            .team = 0,
            .color = 0xFF0000,
            .start_position = 0,
            .is_human = true,
            .ai_difficulty = .Medium,
        };

        players[1] = SkirmishPlayer{
            .player_id = 1,
            .name = "Ally AI",
            .faction = "USA",
            .team = 0,
            .color = 0xFF8800,
            .start_position = 1,
            .is_human = false,
            .ai_difficulty = ai_difficulty,
        };

        players[2] = SkirmishPlayer{
            .player_id = 2,
            .name = "Enemy AI 1",
            .faction = "China",
            .team = 1,
            .color = 0x0000FF,
            .start_position = 2,
            .is_human = false,
            .ai_difficulty = ai_difficulty,
        };

        players[3] = SkirmishPlayer{
            .player_id = 3,
            .name = "Enemy AI 2",
            .faction = "GLA",
            .team = 1,
            .color = 0x00FF00,
            .start_position = 3,
            .is_human = false,
            .ai_difficulty = ai_difficulty,
        };

        const settings = SkirmishSettings{
            .map_name = map_name,
            .players = players,
            .player_count = 4,
            .starting_resources = .Standard,
            .game_speed = .Normal,
            .tech_level = 5,
            .superweapons_enabled = true,
            .fog_of_war = true,
            .time_limit_minutes = 0,
            .score_limit = 0,
            .allow_cheats = false,
        };

        try self.createGame(settings);
    }

    /// Update current game
    pub fn update(self: *SkirmishManager, delta_time: f32) void {
        if (self.current_game) |*game| {
            game.update(delta_time);
        }
    }

    /// Get statistics
    pub fn getStats(self: *SkirmishManager) SkirmishStats {
        const has_game = self.current_game != null;
        const player_count = if (self.current_game) |game| game.settings.player_count else 0;
        const game_time = if (self.current_game) |game| game.game_time else 0.0;

        return SkirmishStats{
            .has_active_game = has_game,
            .player_count = player_count,
            .game_time = game_time,
            .available_maps = self.available_maps_count,
        };
    }
};

pub const SkirmishStats = struct {
    has_active_game: bool,
    player_count: usize,
    game_time: f32,
    available_maps: usize,
};

// Tests
test "Skirmish settings" {
    const allocator = std.testing.allocator;

    const players = try allocator.alloc(SkirmishPlayer, 2);
    defer allocator.free(players);

    players[0] = SkirmishPlayer{
        .player_id = 0,
        .name = "Player",
        .faction = "USA",
        .team = 0,
        .color = 0xFF0000,
        .start_position = 0,
        .is_human = true,
        .ai_difficulty = .Medium,
    };

    players[1] = SkirmishPlayer{
        .player_id = 1,
        .name = "AI",
        .faction = "China",
        .team = 1,
        .color = 0x0000FF,
        .start_position = 1,
        .is_human = false,
        .ai_difficulty = .Hard,
    };

    try std.testing.expect(players[0].is_human == true);
    try std.testing.expect(players[1].is_human == false);
}

test "Skirmish game" {
    const allocator = std.testing.allocator;

    var manager = try SkirmishManager.init(allocator);
    defer manager.deinit();

    try manager.createQuickMatch("Tournament Desert", "USA", "China", .Medium);

    const stats = manager.getStats();
    try std.testing.expect(stats.has_active_game == true);
    try std.testing.expect(stats.player_count == 2);
}

test "Game time and speed" {
    const allocator = std.testing.allocator;

    var manager = try SkirmishManager.init(allocator);
    defer manager.deinit();

    try manager.createQuickMatch("Tournament Desert", "USA", "GLA", .Easy);

    manager.update(1.0);

    const stats = manager.getStats();
    try std.testing.expect(stats.game_time > 0);
}
