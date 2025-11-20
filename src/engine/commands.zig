// ============================================================================
// Command Queue System - Complete Implementation
// Based on Thyme's command architecture
// ============================================================================
//
// Command system handles all player orders to units/buildings:
// - Move commands (click, waypoints, formations)
// - Attack commands (attack-move, force attack, stop)
// - Build commands (construct building, repair)
// - Special commands (garrison, capture, use special power)
// - Queue management (shift-queue, cancel)
//
// References:
// - Thyme/src/game/logic/object/update.h
// - Thyme/src/game/network/gamelogic.h (CommandSourceType)

const std = @import("std");
const Allocator = std.mem.Allocator;

// ============================================================================
// Phase 1: Command Types
// ============================================================================

pub const CommandType = enum(u8) {
    // Movement
    MOVE,                // Move to location
    ATTACK_MOVE,         // Move and engage enemies
    STOP,                // Stop current action
    GUARD,               // Guard location/unit
    PATROL,              // Patrol between waypoints

    // Combat
    ATTACK,              // Attack specific target
    FORCE_ATTACK,        // Force attack (including friendlies)
    FORCE_FIRE,          // Fire at ground

    // Construction
    BUILD,               // Build structure
    REPAIR,              // Repair building/unit
    SELL,                // Sell building

    // Special
    GARRISON,            // Enter building/transport
    EVACUATE,            // Exit building/transport
    CAPTURE,             // Capture building
    SABOTAGE,            // Sabotage building
    HACK,                // Hack building
    SNIPE,               // Snipe infantry

    // Production
    PRODUCE_UNIT,        // Queue unit production
    CANCEL_PRODUCTION,   // Cancel production
    RALLY_POINT,         // Set rally point

    // Powers
    USE_SPECIAL_POWER,   // Activate special power
    UPGRADE,             // Research upgrade

    // Formation
    SET_FORMATION,       // Change formation
    FORMATION_MOVE,      // Move in formation

    // Misc
    FOLLOW,              // Follow target
    SET_STANCE,          // Set combat stance
    RETREAT,             // Retreat to base
    SCATTER,             // Scatter units

    COUNT,
};

/// Command priority (for queue ordering)
pub const CommandPriority = enum(u8) {
    LOW = 0,
    NORMAL = 1,
    HIGH = 2,
    CRITICAL = 3,
};

/// Combat stance
pub const CombatStance = enum(u8) {
    AGGRESSIVE,    // Attack enemies on sight
    DEFENSIVE,     // Only attack when attacked
    HOLD_POSITION, // Don't move, only attack in range
    HOLD_FIRE,     // Don't attack at all
};

// ============================================================================
// Phase 2: Command Structure
// ============================================================================

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Command = struct {
    command_type: CommandType,
    priority: CommandPriority,

    // Targets
    target_entity_id: ?u32,      // Target unit/building ID
    target_position: ?Vec3,      // Target world position
    waypoints: ?[]Vec3,          // For patrol/waypoint movement

    // Parameters (union-like data, only some fields used per command)
    building_type: ?u32,         // For BUILD command
    formation_type: ?u8,         // For SET_FORMATION
    special_power_id: ?u32,      // For USE_SPECIAL_POWER
    stance: ?CombatStance,       // For SET_STANCE
    queue_shift: bool,           // Shift-queue (add to queue vs replace)

    // Metadata
    issuer_player: i32,          // Who issued this command
    frame_issued: u64,           // Game frame when issued
    is_queued: bool,             // In command queue vs immediate

    pub fn init(command_type: CommandType) Command {
        return .{
            .command_type = command_type,
            .priority = .NORMAL,
            .target_entity_id = null,
            .target_position = null,
            .waypoints = null,
            .building_type = null,
            .formation_type = null,
            .special_power_id = null,
            .stance = null,
            .queue_shift = false,
            .issuer_player = -1,
            .frame_issued = 0,
            .is_queued = false,
        };
    }

    /// Create move command
    pub fn move(position: Vec3, shift_queue: bool) Command {
        var cmd = Command.init(.MOVE);
        cmd.target_position = position;
        cmd.queue_shift = shift_queue;
        return cmd;
    }

    /// Create attack command
    pub fn attack(target_id: u32, shift_queue: bool) Command {
        var cmd = Command.init(.ATTACK);
        cmd.target_entity_id = target_id;
        cmd.queue_shift = shift_queue;
        return cmd;
    }

    /// Create build command
    pub fn build(building_type: u32, position: Vec3) Command {
        var cmd = Command.init(.BUILD);
        cmd.building_type = building_type;
        cmd.target_position = position;
        return cmd;
    }

    /// Create special power command
    pub fn specialPower(power_id: u32, position: Vec3) Command {
        var cmd = Command.init(.USE_SPECIAL_POWER);
        cmd.special_power_id = power_id;
        cmd.target_position = position;
        return cmd;
    }
};

// ============================================================================
// Phase 3: Command Queue (Per Entity)
// ============================================================================

pub const CommandQueue = struct {
    commands: std.ArrayList(Command),
    current_command: ?Command,
    entity_id: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, entity_id: u32) CommandQueue {
        return .{
            .commands = std.ArrayList(Command){},
            .current_command = null,
            .entity_id = entity_id,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CommandQueue) void {
        self.commands.deinit(self.allocator);
    }

    /// Add command to queue
    pub fn addCommand(self: *CommandQueue, command: Command) !void {
        if (command.queue_shift) {
            // Shift-queue: add to end
            try self.commands.append(self.allocator, command);
        } else {
            // Replace queue
            self.clear();
            try self.commands.append(self.allocator, command);
        }
    }

    /// Get next command
    pub fn popCommand(self: *CommandQueue) ?Command {
        if (self.commands.items.len == 0) return null;
        return self.commands.orderedRemove(0);
    }

    /// Clear all commands
    pub fn clear(self: *CommandQueue) void {
        self.commands.clearRetainingCapacity();
        self.current_command = null;
    }

    /// Peek at next command without removing
    pub fn peekCommand(self: *const CommandQueue) ?Command {
        if (self.commands.items.len == 0) return null;
        return self.commands.items[0];
    }

    /// Get queue length
    pub fn getLength(self: *const CommandQueue) usize {
        return self.commands.items.len;
    }

    /// Check if queue is empty
    pub fn isEmpty(self: *const CommandQueue) bool {
        return self.commands.items.len == 0 and self.current_command == null;
    }

    /// Start executing next command
    pub fn executeNext(self: *CommandQueue) bool {
        if (self.current_command != null) return false;

        if (self.popCommand()) |cmd| {
            self.current_command = cmd;
            return true;
        }

        return false;
    }

    /// Complete current command
    pub fn completeCurrentCommand(self: *CommandQueue) void {
        self.current_command = null;
    }

    /// Cancel current command
    pub fn cancelCurrentCommand(self: *CommandQueue) void {
        self.current_command = null;
    }
};

// ============================================================================
// Phase 4: Command Manager (Global)
// ============================================================================

pub const CommandManager = struct {
    command_queues: std.AutoHashMap(u32, CommandQueue),  // entity_id -> queue
    command_history: std.ArrayList(Command),             // For replay/network
    current_frame: u64,
    allocator: Allocator,

    pub fn init(allocator: Allocator) CommandManager {
        return .{
            .command_queues = std.AutoHashMap(u32, CommandQueue).init(allocator),
            .command_history = std.ArrayList(Command){},
            .current_frame = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CommandManager) void {
        var iter = self.command_queues.valueIterator();
        while (iter.next()) |queue| {
            queue.deinit();
        }
        self.command_queues.deinit();
        self.command_history.deinit(self.allocator);
    }

    /// Issue command to entity
    pub fn issueCommand(self: *CommandManager, entity_id: u32, command: Command) !void {
        // Get or create queue for entity
        const queue = try self.getOrCreateQueue(entity_id);

        // Add command
        var cmd = command;
        cmd.frame_issued = self.current_frame;
        try queue.addCommand(cmd);

        // Record in history (for network/replay)
        try self.command_history.append(self.allocator, cmd);
    }

    /// Issue command to multiple entities
    pub fn issueGroupCommand(self: *CommandManager, entity_ids: []const u32, command: Command) !void {
        for (entity_ids) |entity_id| {
            try self.issueCommand(entity_id, command);
        }
    }

    /// Get queue for entity
    pub fn getQueue(self: *CommandManager, entity_id: u32) ?*CommandQueue {
        return self.command_queues.getPtr(entity_id);
    }

    /// Get or create queue for entity
    fn getOrCreateQueue(self: *CommandManager, entity_id: u32) !*CommandQueue {
        if (self.command_queues.getPtr(entity_id)) |queue| {
            return queue;
        }

        const queue = CommandQueue.init(self.allocator, entity_id);
        try self.command_queues.put(entity_id, queue);
        return self.command_queues.getPtr(entity_id).?;
    }

    /// Remove entity queue (when entity dies)
    pub fn removeEntity(self: *CommandManager, entity_id: u32) void {
        if (self.command_queues.getPtr(entity_id)) |queue| {
            queue.deinit();
            _ = self.command_queues.remove(entity_id);
        }
    }

    /// Update frame counter
    pub fn update(self: *CommandManager, frame: u64) void {
        self.current_frame = frame;
    }

    /// Clear all commands for all entities
    pub fn clearAll(self: *CommandManager) void {
        var iter = self.command_queues.valueIterator();
        while (iter.next()) |queue| {
            queue.clear();
        }
    }

    /// Get total queued commands
    pub fn getTotalQueuedCommands(self: *const CommandManager) usize {
        var total: usize = 0;
        var iter = self.command_queues.valueIterator();
        while (iter.next()) |queue| {
            total += queue.getLength();
            if (queue.current_command != null) total += 1;
        }
        return total;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Command: creation" {
    const cmd = Command.init(.MOVE);
    try std.testing.expectEqual(CommandType.MOVE, cmd.command_type);
    try std.testing.expectEqual(CommandPriority.NORMAL, cmd.priority);
}

test "Command: move helper" {
    const pos = Vec3{ .x = 100.0, .y = 100.0, .z = 0.0 };
    const cmd = Command.move(pos, false);

    try std.testing.expectEqual(CommandType.MOVE, cmd.command_type);
    try std.testing.expect(cmd.target_position != null);
    try std.testing.expectEqual(@as(f32, 100.0), cmd.target_position.?.x);
}

test "Command: attack helper" {
    const cmd = Command.attack(42, true);

    try std.testing.expectEqual(CommandType.ATTACK, cmd.command_type);
    try std.testing.expect(cmd.target_entity_id != null);
    try std.testing.expectEqual(@as(u32, 42), cmd.target_entity_id.?);
    try std.testing.expect(cmd.queue_shift);
}

test "CommandQueue: add and pop" {
    const allocator = std.testing.allocator;

    var queue = CommandQueue.init(allocator, 1);
    defer queue.deinit();

    var cmd1 = Command.init(.MOVE);
    cmd1.queue_shift = true;  // Add to queue
    var cmd2 = Command.init(.ATTACK);
    cmd2.queue_shift = true;  // Add to queue

    try queue.addCommand(cmd1);
    try queue.addCommand(cmd2);

    try std.testing.expectEqual(@as(usize, 2), queue.getLength());

    const popped = queue.popCommand();
    try std.testing.expect(popped != null);
    try std.testing.expectEqual(CommandType.MOVE, popped.?.command_type);
    try std.testing.expectEqual(@as(usize, 1), queue.getLength());
}

test "CommandQueue: shift queue" {
    const allocator = std.testing.allocator;

    var queue = CommandQueue.init(allocator, 1);
    defer queue.deinit();

    var cmd1 = Command.init(.MOVE);
    cmd1.queue_shift = false;  // Replace queue
    try queue.addCommand(cmd1);

    var cmd2 = Command.init(.ATTACK);
    cmd2.queue_shift = true;  // Add to queue
    try queue.addCommand(cmd2);

    try std.testing.expectEqual(@as(usize, 2), queue.getLength());

    var cmd3 = Command.init(.STOP);
    cmd3.queue_shift = false;  // Replace queue
    try queue.addCommand(cmd3);

    try std.testing.expectEqual(@as(usize, 1), queue.getLength());
}

test "CommandQueue: execute and complete" {
    const allocator = std.testing.allocator;

    var queue = CommandQueue.init(allocator, 1);
    defer queue.deinit();

    const cmd = Command.init(.MOVE);
    try queue.addCommand(cmd);

    try std.testing.expect(queue.current_command == null);

    const started = queue.executeNext();
    try std.testing.expect(started);
    try std.testing.expect(queue.current_command != null);

    queue.completeCurrentCommand();
    try std.testing.expect(queue.current_command == null);
}

test "CommandManager: issue command" {
    const allocator = std.testing.allocator;

    var manager = CommandManager.init(allocator);
    defer manager.deinit();

    const cmd = Command.init(.MOVE);
    try manager.issueCommand(1, cmd);

    const queue = manager.getQueue(1);
    try std.testing.expect(queue != null);
    try std.testing.expectEqual(@as(usize, 1), queue.?.getLength());
}

test "CommandManager: group command" {
    const allocator = std.testing.allocator;

    var manager = CommandManager.init(allocator);
    defer manager.deinit();

    const entity_ids = [_]u32{ 1, 2, 3 };
    const cmd = Command.init(.ATTACK);

    try manager.issueGroupCommand(&entity_ids, cmd);

    try std.testing.expectEqual(@as(usize, 1), manager.getQueue(1).?.getLength());
    try std.testing.expectEqual(@as(usize, 1), manager.getQueue(2).?.getLength());
    try std.testing.expectEqual(@as(usize, 1), manager.getQueue(3).?.getLength());
}

test "CommandManager: remove entity" {
    const allocator = std.testing.allocator;

    var manager = CommandManager.init(allocator);
    defer manager.deinit();

    const cmd = Command.init(.MOVE);
    try manager.issueCommand(1, cmd);

    try std.testing.expect(manager.getQueue(1) != null);

    manager.removeEntity(1);
    try std.testing.expect(manager.getQueue(1) == null);
}

test "CommandManager: total queued commands" {
    const allocator = std.testing.allocator;

    var manager = CommandManager.init(allocator);
    defer manager.deinit();

    var cmd = Command.init(.MOVE);
    cmd.queue_shift = true;  // Add to queue instead of replace
    try manager.issueCommand(1, cmd);
    try manager.issueCommand(2, cmd);
    try manager.issueCommand(2, cmd);

    const total = manager.getTotalQueuedCommands();
    try std.testing.expectEqual(@as(usize, 3), total);
}
