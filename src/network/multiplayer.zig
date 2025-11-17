// C&C Generals - Multiplayer Networking System
// Lockstep synchronization for deterministic multiplayer

const std = @import("std");

/// Network protocol constants
pub const PROTOCOL_VERSION: u32 = 1;
pub const DEFAULT_PORT: u16 = 8086;
pub const MAX_PLAYERS: usize = 8;
pub const LOCKSTEP_FRAME_MS: u32 = 33; // 30 FPS lockstep

/// Player connection info
pub const PlayerInfo = struct {
    player_id: usize,
    name: []const u8,
    faction: []const u8,
    team: u8,
    color: u32,
    is_ready: bool,
    is_host: bool,
    ping_ms: u32,
};

/// Network command types
pub const CommandType = enum(u8) {
    Move = 1,
    Attack = 2,
    Build = 3,
    Stop = 4,
    Guard = 5,
    Special_Power = 6,
    Sell = 7,
    Repair = 8,
};

/// Network command
pub const NetworkCommand = struct {
    frame: u32,
    player_id: usize,
    command_type: CommandType,
    target_x: f32,
    target_y: f32,
    target_id: u32,
    unit_ids: []usize,

    pub fn deinit(self: *NetworkCommand, allocator: std.mem.Allocator) void {
        allocator.free(self.unit_ids);
    }
};

/// Lobby state
pub const LobbyState = struct {
    players: []PlayerInfo,
    player_count: usize,
    map_name: []const u8,
    max_players: usize,
    is_started: bool,
    host_id: usize,

    pub fn deinit(self: *LobbyState, allocator: std.mem.Allocator) void {
        allocator.free(self.players);
    }
};

/// Lockstep frame
pub const LockstepFrame = struct {
    frame_number: u32,
    commands: []NetworkCommand,
    command_count: usize,
    checksum: u32,

    pub fn deinit(self: *LockstepFrame, allocator: std.mem.Allocator) void {
        for (self.commands[0..self.command_count]) |*cmd| {
            cmd.deinit(allocator);
        }
        allocator.free(self.commands);
    }
};

/// Multiplayer manager
pub const MultiplayerManager = struct {
    allocator: std.mem.Allocator,
    is_host: bool,
    local_player_id: usize,
    lobby: ?LobbyState,
    current_frame: u32,
    pending_commands: []NetworkCommand,
    pending_command_count: usize,
    frame_queue: []LockstepFrame,
    frame_queue_count: usize,
    port: u16,
    connection_count: usize,

    pub fn init(allocator: std.mem.Allocator) !MultiplayerManager {
        const pending_commands = try allocator.alloc(NetworkCommand, 1000);
        const frame_queue = try allocator.alloc(LockstepFrame, 1000);

        return MultiplayerManager{
            .allocator = allocator,
            .is_host = false,
            .local_player_id = 0,
            .lobby = null,
            .current_frame = 0,
            .pending_commands = pending_commands,
            .pending_command_count = 0,
            .frame_queue = frame_queue,
            .frame_queue_count = 0,
            .port = DEFAULT_PORT,
            .connection_count = 0,
        };
    }

    pub fn deinit(self: *MultiplayerManager) void {
        if (self.lobby) |*lobby| {
            lobby.deinit(self.allocator);
        }
        for (self.frame_queue[0..self.frame_queue_count]) |*frame| {
            frame.deinit(self.allocator);
        }
        self.allocator.free(self.pending_commands);
        self.allocator.free(self.frame_queue);
    }

    /// Create a multiplayer lobby (host)
    pub fn createLobby(self: *MultiplayerManager, map_name: []const u8, max_players: usize) !void {
        self.is_host = true;
        self.local_player_id = 0;
        self.connection_count = 1;

        const players = try self.allocator.alloc(PlayerInfo, max_players);

        // Add host as first player
        players[0] = PlayerInfo{
            .player_id = 0,
            .name = "Host",
            .faction = "USA",
            .team = 0,
            .color = 0xFF0000,
            .is_ready = true,
            .is_host = true,
            .ping_ms = 0,
        };

        self.lobby = LobbyState{
            .players = players,
            .player_count = 1,
            .map_name = map_name,
            .max_players = max_players,
            .is_started = false,
            .host_id = 0,
        };

        std.debug.print("Lobby created: {s} ({} players)\n", .{ map_name, max_players });
    }

    /// Join an existing lobby
    pub fn joinLobby(self: *MultiplayerManager, host_address: []const u8, port: u16) !void {
        self.is_host = false;
        self.port = port;

        // In full implementation: establish TCP connection to host_address

        self.local_player_id = 1; // Will be assigned by host
        self.connection_count = 1;

        std.debug.print("Joining lobby at {s}:{}\n", .{ host_address, port });
    }

    /// Add player to lobby (host only)
    pub fn addPlayer(self: *MultiplayerManager, name: []const u8, faction: []const u8) !usize {
        if (!self.is_host) return error.NotHost;
        if (self.lobby == null) return error.NoLobby;

        var lobby = &self.lobby.?;
        if (lobby.player_count >= lobby.max_players) return error.LobbyFull;

        const player_id = lobby.player_count;
        lobby.players[player_id] = PlayerInfo{
            .player_id = player_id,
            .name = name,
            .faction = faction,
            .team = 0,
            .color = 0x00FF00,
            .is_ready = false,
            .is_host = false,
            .ping_ms = 0,
        };

        lobby.player_count += 1;
        self.connection_count = lobby.player_count;

        std.debug.print("Player {} joined: {s} ({s})\n", .{ player_id, name, faction });

        return player_id;
    }

    /// Set player ready state
    pub fn setPlayerReady(self: *MultiplayerManager, player_id: usize, ready: bool) !void {
        if (self.lobby == null) return error.NoLobby;

        var lobby = &self.lobby.?;
        if (player_id >= lobby.player_count) return error.InvalidPlayer;

        lobby.players[player_id].is_ready = ready;
    }

    /// Start the game (host only)
    pub fn startGame(self: *MultiplayerManager) !void {
        if (!self.is_host) return error.NotHost;
        if (self.lobby == null) return error.NoLobby;

        var lobby = &self.lobby.?;

        // Check all players ready
        for (lobby.players[0..lobby.player_count]) |player| {
            if (!player.is_ready) return error.PlayersNotReady;
        }

        lobby.is_started = true;
        self.current_frame = 0;

        std.debug.print("Game starting with {} players!\n", .{lobby.player_count});
    }

    /// Send command (will be synchronized via lockstep)
    pub fn sendCommand(self: *MultiplayerManager, cmd: NetworkCommand) !void {
        // Add to pending commands for next lockstep frame
        if (self.pending_command_count >= self.pending_commands.len) return error.CommandBufferFull;
        self.pending_commands[self.pending_command_count] = cmd;
        self.pending_command_count += 1;
    }

    /// Process lockstep frame
    pub fn processLockstepFrame(self: *MultiplayerManager) !?LockstepFrame {
        if (self.lobby == null or !self.lobby.?.is_started) return null;

        // In full implementation:
        // 1. Send our pending commands to all players
        // 2. Wait for all players' commands for this frame
        // 3. Verify checksums match
        // 4. Execute all commands deterministically

        const commands = try self.allocator.alloc(NetworkCommand, self.pending_command_count);
        for (self.pending_commands[0..self.pending_command_count], 0..) |cmd, i| {
            commands[i] = cmd;
        }

        const frame = LockstepFrame{
            .frame_number = self.current_frame,
            .commands = commands,
            .command_count = self.pending_command_count,
            .checksum = self.calculateChecksum(),
        };

        self.pending_command_count = 0;
        self.current_frame += 1;

        return frame;
    }

    /// Calculate game state checksum for sync verification
    fn calculateChecksum(self: *MultiplayerManager) u32 {
        // In full implementation: hash all game state
        // For now, just return frame number
        return self.current_frame;
    }

    /// Disconnect from multiplayer session
    pub fn disconnect(self: *MultiplayerManager) void {
        if (self.lobby) |*lobby| {
            lobby.deinit(self.allocator);
            self.lobby = null;
        }

        self.connection_count = 0;
        std.debug.print("Disconnected from multiplayer session\n", .{});
    }

    /// Get network statistics
    pub fn getStats(self: *MultiplayerManager) NetworkStats {
        const in_lobby = self.lobby != null;
        const player_count = if (self.lobby) |lobby| lobby.player_count else 0;

        return NetworkStats{
            .is_host = self.is_host,
            .is_connected = self.connection_count > 0,
            .in_lobby = in_lobby,
            .player_count = player_count,
            .current_frame = self.current_frame,
            .pending_commands = self.pending_command_count,
        };
    }
};

pub const NetworkStats = struct {
    is_host: bool,
    is_connected: bool,
    in_lobby: bool,
    player_count: usize,
    current_frame: u32,
    pending_commands: usize,
};

// Tests
test "Create lobby" {
    const allocator = std.testing.allocator;

    var manager = MultiplayerManager.init(allocator);
    defer manager.deinit();

    try manager.createLobby("Tournament Desert", 4);

    const stats = manager.getStats();
    try std.testing.expect(stats.is_host == true);
    try std.testing.expect(stats.in_lobby == true);
    try std.testing.expect(stats.player_count == 1);
}

test "Add players" {
    const allocator = std.testing.allocator;

    var manager = MultiplayerManager.init(allocator);
    defer manager.deinit();

    try manager.createLobby("Tournament Desert", 4);

    const player2 = try manager.addPlayer("Player 2", "China");
    const player3 = try manager.addPlayer("Player 3", "GLA");

    try std.testing.expect(player2 == 1);
    try std.testing.expect(player3 == 2);

    const stats = manager.getStats();
    try std.testing.expect(stats.player_count == 3);
}

test "Lockstep frame" {
    const allocator = std.testing.allocator;

    var manager = MultiplayerManager.init(allocator);
    defer manager.deinit();

    try manager.createLobby("Tournament Desert", 2);
    try manager.startGame();

    const cmd = NetworkCommand{
        .frame = 0,
        .player_id = 0,
        .command_type = .Move,
        .target_x = 100.0,
        .target_y = 200.0,
        .target_id = 0,
        .unit_ids = &[_]usize{},
    };

    try manager.sendCommand(cmd);

    if (try manager.processLockstepFrame()) |frame| {
        try std.testing.expect(frame.command_count == 1);
        try std.testing.expect(frame.frame_number == 0);
    }
}
