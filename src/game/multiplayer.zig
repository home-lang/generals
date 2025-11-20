// Home Programming Language - Networking & Multiplayer System
// Client-server multiplayer architecture for RTS games
//
// Features:
// - Client-server architecture
// - UDP for game state, TCP for reliable messages
// - State synchronization with delta compression
// - Lag compensation and prediction
// - Lobby system
// - Replay recording integration

const std = @import("std");
const net = std.net;

// ============================================================================
// Network Protocol
// ============================================================================

pub const PacketType = enum(u8) {
    // Connection
    Connect = 0,
    ConnectAck = 1,
    Disconnect = 2,
    Ping = 3,
    Pong = 4,

    // Lobby
    LobbyCreate = 10,
    LobbyJoin = 11,
    LobbyLeave = 12,
    LobbyUpdate = 13,
    LobbyReady = 14,
    LobbyStart = 15,

    // Game
    GameState = 20,
    GameStateDelta = 21,
    PlayerCommand = 22,
    ChatMessage = 23,

    // Synchronization
    SyncRequest = 30,
    SyncResponse = 31,
};

pub const PlayerCommand = struct {
    player_id: u32,
    timestamp: u64,
    command_type: CommandType,
    data: [128]u8,

    pub const CommandType = enum(u8) {
        Move,
        Attack,
        Build,
        Sell,
        Special,
    };
};

pub const GameStateSnapshot = struct {
    tick: u64,
    timestamp: u64,
    player_count: u8,
    entities: []EntityState,

    pub const EntityState = struct {
        id: u32,
        position: @Vector(3, f32),
        rotation: f32,
        health: f32,
        flags: u32,
    };
};

// ============================================================================
// Network Connection
// ============================================================================

pub const Connection = struct {
    address: net.Address,
    player_id: u32,
    connected: bool,
    last_ping_time: i64,
    rtt: u32, // Round-trip time in milliseconds

    pub fn init(address: net.Address, player_id: u32) Connection {
        return Connection{
            .address = address,
            .player_id = player_id,
            .connected = false,
            .last_ping_time = 0,
            .rtt = 0,
        };
    }
};

// ============================================================================
// Server
// ============================================================================

pub const ServerConfig = struct {
    port: u16,
    max_players: u8,
    tick_rate: u32, // Server updates per second (e.g., 30)
    max_latency_ms: u32, // Kick players above this latency
};

pub const GameServer = struct {
    config: ServerConfig,
    socket_udp: net.Stream,
    socket_tcp: net.Server,
    connections: std.ArrayList(Connection),
    current_tick: u64,
    running: bool,
    allocator: std.mem.Allocator,

    // Command queue
    pending_commands: std.ArrayList(PlayerCommand),

    // State history for lag compensation
    state_history: std.RingBuffer(GameStateSnapshot),

    pub fn init(allocator: std.mem.Allocator, config: ServerConfig) !GameServer {
        const tcp_address = try net.Address.parseIp4("0.0.0.0", config.port);
        const udp_address = try net.Address.parseIp4("0.0.0.0", config.port + 1);

        var tcp_server = try tcp_address.listen(.{
            .reuse_address = true,
        });

        // UDP socket setup would go here
        _ = udp_address;

        return GameServer{
            .config = config,
            .socket_udp = undefined, // TODO: Implement UDP socket
            .socket_tcp = tcp_server,
            .connections = std.ArrayList(Connection).init(allocator),
            .current_tick = 0,
            .running = false,
            .allocator = allocator,
            .pending_commands = std.ArrayList(PlayerCommand).init(allocator),
            .state_history = undefined, // TODO: Initialize ring buffer
        };
    }

    pub fn deinit(self: *GameServer) void {
        self.socket_tcp.deinit();
        self.connections.deinit();
        self.pending_commands.deinit();
    }

    pub fn start(self: *GameServer) !void {
        self.running = true;

        std.debug.print("Server started on port {d}\n", .{self.config.port});
        std.debug.print("Tick rate: {d} Hz\n", .{self.config.tick_rate});

        const tick_duration_ns = @divTrunc(std.time.ns_per_s, self.config.tick_rate);

        while (self.running) {
            const tick_start = std.time.nanoTimestamp();

            // Accept new connections (non-blocking)
            self.acceptNewConnections() catch {};

            // Process incoming packets
            try self.processIncomingPackets();

            // Process game logic
            try self.processGameTick();

            // Send state updates to clients
            try self.sendStateUpdates();

            self.current_tick += 1;

            // Sleep until next tick
            const tick_end = std.time.nanoTimestamp();
            const elapsed = tick_end - tick_start;
            if (elapsed < tick_duration_ns) {
                std.time.sleep(@intCast(tick_duration_ns - elapsed));
            }
        }
    }

    pub fn stop(self: *GameServer) void {
        self.running = false;
    }

    fn acceptNewConnections(self: *GameServer) !void {
        // TODO: Non-blocking accept
        _ = self;
    }

    fn processIncomingPackets(self: *GameServer) !void {
        // TODO: Read from UDP socket
        _ = self;
    }

    fn processGameTick(self: *GameServer) !void {
        // Process pending commands in chronological order
        std.mem.sort(PlayerCommand, self.pending_commands.items, {}, struct {
            fn lessThan(_: void, a: PlayerCommand, b: PlayerCommand) bool {
                return a.timestamp < b.timestamp;
            }
        }.lessThan);

        // Execute commands
        for (self.pending_commands.items) |cmd| {
            try self.executeCommand(cmd);
        }

        self.pending_commands.clearRetainingCapacity();

        // Update game state
        // (Game logic would go here)
    }

    fn executeCommand(self: *GameServer, cmd: PlayerCommand) !void {
        _ = self;
        _ = cmd;
        // TODO: Execute player command
    }

    fn sendStateUpdates(self: *GameServer) !void {
        // Send full state snapshot every N ticks
        // Send delta updates in between

        const send_full_snapshot = (self.current_tick % 30) == 0;

        if (send_full_snapshot) {
            // Send full snapshot
            for (self.connections.items) |conn| {
                if (conn.connected) {
                    try self.sendFullSnapshot(conn.address);
                }
            }
        } else {
            // Send delta update
            for (self.connections.items) |conn| {
                if (conn.connected) {
                    try self.sendDeltaUpdate(conn.address);
                }
            }
        }
    }

    fn sendFullSnapshot(self: *GameServer, address: net.Address) !void {
        _ = self;
        _ = address;
        // TODO: Serialize and send full game state
    }

    fn sendDeltaUpdate(self: *GameServer, address: net.Address) !void {
        _ = self;
        _ = address;
        // TODO: Serialize and send delta update
    }

    pub fn broadcastMessage(self: *GameServer, message: []const u8) !void {
        for (self.connections.items) |conn| {
            if (conn.connected) {
                _ = message;
                _ = conn;
                // TODO: Send message
            }
        }
    }
};

// ============================================================================
// Client
// ============================================================================

pub const ClientConfig = struct {
    server_address: []const u8,
    server_port: u16,
    player_name: []const u8,
};

pub const GameClient = struct {
    config: ClientConfig,
    socket_udp: net.Stream,
    socket_tcp: net.Stream,
    player_id: u32,
    connected: bool,
    current_tick: u64,
    allocator: std.mem.Allocator,

    // Prediction
    predicted_state: ?GameStateSnapshot,
    last_confirmed_state: ?GameStateSnapshot,

    // Input buffering
    pending_commands: std.ArrayList(PlayerCommand),

    pub fn init(allocator: std.mem.Allocator, config: ClientConfig) !GameClient {
        const server_addr = try net.Address.parseIp4(config.server_address, config.server_port);

        const tcp_socket = try net.tcpConnectToAddress(server_addr);

        return GameClient{
            .config = config,
            .socket_udp = undefined, // TODO: UDP socket
            .socket_tcp = tcp_socket,
            .player_id = 0,
            .connected = false,
            .current_tick = 0,
            .allocator = allocator,
            .predicted_state = null,
            .last_confirmed_state = null,
            .pending_commands = std.ArrayList(PlayerCommand).init(allocator),
        };
    }

    pub fn deinit(self: *GameClient) void {
        self.socket_tcp.close();
        self.pending_commands.deinit();
    }

    pub fn connect(self: *GameClient) !void {
        // Send connect packet
        try self.sendPacket(.Connect, &.{});

        // Wait for connect ack
        // TODO: Implement packet receiving

        self.connected = true;
        std.debug.print("Connected to server\n", .{});
    }

    pub fn disconnect(self: *GameClient) !void {
        try self.sendPacket(.Disconnect, &.{});
        self.connected = false;
    }

    pub fn sendCommand(self: *GameClient, command: PlayerCommand) !void {
        try self.pending_commands.append(command);
        try self.sendPacket(.PlayerCommand, std.mem.asBytes(&command));
    }

    pub fn update(self: *GameClient, dt: f32) !void {
        _ = dt;

        // Receive packets
        try self.receivePackets();

        // Update prediction
        self.updatePrediction();

        // Send pending commands
        for (self.pending_commands.items) |cmd| {
            try self.sendPacket(.PlayerCommand, std.mem.asBytes(&cmd));
        }
        self.pending_commands.clearRetainingCapacity();

        self.current_tick += 1;
    }

    fn receivePackets(self: *GameClient) !void {
        // TODO: Non-blocking receive from UDP and TCP
        _ = self;
    }

    fn updatePrediction(self: *GameClient) void {
        // Client-side prediction
        // Apply pending commands to predicted state
        _ = self;
    }

    fn sendPacket(self: *GameClient, packet_type: PacketType, data: []const u8) !void {
        var buffer: [1024]u8 = undefined;
        buffer[0] = @intFromEnum(packet_type);
        @memcpy(buffer[1 .. 1 + data.len], data);

        _ = try self.socket_tcp.write(buffer[0 .. 1 + data.len]);
    }

    pub fn reconcileState(self: *GameClient, server_state: GameStateSnapshot) void {
        // Server reconciliation
        // Compare predicted state with authoritative server state
        // If mismatch, rewind and replay commands
        _ = self;
        _ = server_state;
    }
};

// ============================================================================
// Lobby System
// ============================================================================

pub const LobbyPlayer = struct {
    id: u32,
    name: []const u8,
    ready: bool,
    team: u8,
};

pub const Lobby = struct {
    id: u32,
    name: []const u8,
    host_player_id: u32,
    players: std.ArrayList(LobbyPlayer),
    max_players: u8,
    map_name: []const u8,
    game_started: bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: u32, name: []const u8, host_id: u32) Lobby {
        return Lobby{
            .id = id,
            .name = name,
            .host_player_id = host_id,
            .players = std.ArrayList(LobbyPlayer).init(allocator),
            .max_players = 8,
            .map_name = "default",
            .game_started = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Lobby) void {
        self.players.deinit();
    }

    pub fn addPlayer(self: *Lobby, player: LobbyPlayer) !void {
        if (self.players.items.len >= self.max_players) {
            return error.LobbyFull;
        }
        try self.players.append(player);
    }

    pub fn removePlayer(self: *Lobby, player_id: u32) void {
        for (self.players.items, 0..) |player, i| {
            if (player.id == player_id) {
                _ = self.players.orderedRemove(i);
                return;
            }
        }
    }

    pub fn setPlayerReady(self: *Lobby, player_id: u32, ready: bool) void {
        for (self.players.items) |*player| {
            if (player.id == player_id) {
                player.ready = ready;
                return;
            }
        }
    }

    pub fn allPlayersReady(self: *const Lobby) bool {
        if (self.players.items.len == 0) return false;

        for (self.players.items) |player| {
            if (!player.ready) return false;
        }
        return true;
    }

    pub fn canStart(self: *const Lobby) bool {
        return self.players.items.len >= 2 and self.allPlayersReady();
    }
};

// ============================================================================
// Replay Recording
// ============================================================================

pub const ReplayRecorder = struct {
    file: std.fs.File,
    recording: bool,
    start_time: i64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) !ReplayRecorder {
        const file = try std.fs.cwd().createFile(path, .{});

        return ReplayRecorder{
            .file = file,
            .recording = true,
            .start_time = std.time.milliTimestamp(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ReplayRecorder) void {
        self.file.close();
    }

    pub fn recordCommand(self: *ReplayRecorder, command: PlayerCommand) !void {
        if (!self.recording) return;

        // Write timestamp + command to file
        const timestamp = std.time.milliTimestamp() - self.start_time;
        try self.file.writer().writeInt(u64, @intCast(timestamp), .little);
        try self.file.writer().writeAll(std.mem.asBytes(&command));
    }

    pub fn recordState(self: *ReplayRecorder, state: GameStateSnapshot) !void {
        if (!self.recording) return;

        // Write timestamp + state snapshot
        const timestamp = std.time.milliTimestamp() - self.start_time;
        try self.file.writer().writeInt(u64, @intCast(timestamp), .little);
        try self.file.writer().writeInt(u64, state.tick, .little);
        // TODO: Serialize full state
        _ = state;
    }

    pub fn stop(self: *ReplayRecorder) void {
        self.recording = false;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Lobby creation" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lobby = Lobby.init(allocator, 1, "Test Lobby", 1);
    defer lobby.deinit();

    try testing.expectEqual(@as(u32, 1), lobby.id);
    try testing.expectEqual(@as(usize, 0), lobby.players.items.len);
}

test "Lobby player management" {
    const testing = std.testing;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var lobby = Lobby.init(allocator, 1, "Test Lobby", 1);
    defer lobby.deinit();

    const player = LobbyPlayer{
        .id = 1,
        .name = "Player1",
        .ready = false,
        .team = 0,
    };

    try lobby.addPlayer(player);
    try testing.expectEqual(@as(usize, 1), lobby.players.items.len);

    lobby.setPlayerReady(1, true);
    try testing.expect(lobby.players.items[0].ready);
}
