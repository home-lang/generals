// C&C Generals - Main AI Controller
// Integrates pathfinding, tactics, and build orders into unified AI system

const std = @import("std");
pub const pathfinding = @import("pathfinding.zig");
pub const tactics = @import("tactics.zig");
pub const build_orders = @import("build_orders.zig");

/// AI Player personality
pub const AIPersonality = struct {
    difficulty: tactics.TacticalAI.AIDifficulty,
    strategy: build_orders.BuildStrategy,
    aggression: f32, // 0.0 - 1.0
    expansion: f32, // 0.0 - 1.0
    defense: f32, // 0.0 - 1.0

    pub fn init(difficulty: tactics.TacticalAI.AIDifficulty) AIPersonality {
        return switch (difficulty) {
            .Easy => AIPersonality{
                .difficulty = difficulty,
                .strategy = .Balanced,
                .aggression = 0.3,
                .expansion = 0.4,
                .defense = 0.5,
            },
            .Medium => AIPersonality{
                .difficulty = difficulty,
                .strategy = .Balanced,
                .aggression = 0.5,
                .expansion = 0.6,
                .defense = 0.5,
            },
            .Hard => AIPersonality{
                .difficulty = difficulty,
                .strategy = .Rush,
                .aggression = 0.7,
                .expansion = 0.7,
                .defense = 0.6,
            },
            .Brutal => AIPersonality{
                .difficulty = difficulty,
                .strategy = .Rush,
                .aggression = 0.9,
                .expansion = 0.9,
                .defense = 0.8,
            },
        };
    }
};

/// Complete AI player state
pub const AIPlayer = struct {
    allocator: std.mem.Allocator,
    personality: AIPersonality,
    pathfinding_manager: pathfinding.PathfindingManager,
    tactical_ai: tactics.TacticalAI,
    economy_manager: build_orders.EconomyManager,
    player_id: usize,
    faction: []const u8,
    game_time: f32,

    pub fn init(
        allocator: std.mem.Allocator,
        player_id: usize,
        faction: []const u8,
        difficulty: tactics.TacticalAI.AIDifficulty,
        map_width: usize,
        map_height: usize,
    ) !AIPlayer {
        const personality = AIPersonality.init(difficulty);

        return AIPlayer{
            .allocator = allocator,
            .personality = personality,
            .pathfinding_manager = try pathfinding.PathfindingManager.init(
                allocator,
                map_width,
                map_height,
                10.0, // 10 units per cell
            ),
            .tactical_ai = tactics.TacticalAI.init(allocator, difficulty),
            .economy_manager = try build_orders.EconomyManager.init(allocator, personality.strategy),
            .player_id = player_id,
            .faction = faction,
            .game_time = 0.0,
        };
    }

    pub fn deinit(self: *AIPlayer) void {
        self.pathfinding_manager.deinit();
        self.economy_manager.deinit();
    }

    /// Main AI update loop
    pub fn update(
        self: *AIPlayer,
        delta_time: f32,
        friendly_units: []tactics.CombatUnit,
        enemy_units: []tactics.CombatUnit,
    ) !void {
        self.game_time += delta_time;

        // Update economy and build orders
        self.economy_manager.update(delta_time);

        // Evaluate tactical situation
        const threat = self.tactical_ai.evaluateThreat(friendly_units, enemy_units);
        const decision = self.tactical_ai.makeTacticalDecision(friendly_units, enemy_units);

        // Update unit behaviors based on tactical decision
        for (friendly_units) |*unit| {
            switch (decision) {
                .Attack => {
                    if (unit.state == .Idle or unit.state == .Defending) {
                        unit.state = .Attacking;
                    }
                },
                .Defend => {
                    if (unit.state == .Idle or unit.state == .Attacking) {
                        unit.state = .Defending;
                    }
                },
                .Retreat => {
                    unit.state = .Retreating;
                },
                .HoldPosition => {
                    unit.state = .Guarding;
                },
                else => {},
            }

            self.tactical_ai.updateUnitBehavior(unit, enemy_units, delta_time);
        }

        // Check if we should switch strategy
        var enemy_strength: f32 = 0.0;
        for (enemy_units) |enemy| {
            if (enemy.isAlive()) {
                enemy_strength += enemy.getCombatValue();
            }
        }

        if (self.economy_manager.shouldSwitchStrategy(self.game_time, enemy_strength)) {
            const new_strategy = self.selectNewStrategy(threat, enemy_strength);
            self.economy_manager.switchStrategy(new_strategy);
        }
    }

    /// Select new strategy based on current situation
    fn selectNewStrategy(
        self: *AIPlayer,
        threat: tactics.ThreatLevel,
        enemy_strength: f32,
    ) build_orders.BuildStrategy {
        _ = enemy_strength;

        // Switch strategy based on threat and personality
        return switch (threat) {
            .Critical, .High => build_orders.BuildStrategy.Turtle,
            .Medium => {
                if (self.personality.aggression > 0.6) {
                    return build_orders.BuildStrategy.Rush;
                } else {
                    return build_orders.BuildStrategy.Balanced;
                }
            },
            .Low => {
                if (self.personality.expansion > 0.7) {
                    return build_orders.BuildStrategy.Boom;
                } else {
                    return build_orders.BuildStrategy.Rush;
                }
            },
            .None => {
                if (self.game_time > 600.0) {
                    return build_orders.BuildStrategy.Tech;
                } else {
                    return build_orders.BuildStrategy.Boom;
                }
            },
        };
    }

    /// Find path for a unit
    pub fn findUnitPath(
        self: *AIPlayer,
        start: pathfinding.Vec2,
        goal: pathfinding.Vec2,
    ) !pathfinding.Path {
        return try self.pathfinding_manager.findPath(start, goal, true);
    }

    /// Get next build recommendation
    pub fn getNextBuild(self: *AIPlayer) ?build_orders.BuildItem {
        return self.economy_manager.getNextBuildRecommendation();
    }

    /// Issue attack order to units
    pub fn issueAttackOrder(
        self: *AIPlayer,
        units: []tactics.CombatUnit,
        target_position: pathfinding.Vec2,
    ) !void {
        // Calculate formation
        const formation_positions = try tactics.FormationManager.calculateFormationPositions(
            self.allocator,
            .Wedge,
            target_position,
            units.len,
            20.0,
        );
        defer self.allocator.free(formation_positions);

        // Assign move orders to each unit
        for (units, 0..) |*unit, i| {
            const path = try self.findUnitPath(unit.position, formation_positions[i]);
            _ = path; // In full implementation, would assign path to unit

            unit.state = .Moving;
            // path would be stored in unit for following
        }
    }

    /// Select best target position for attack
    pub fn selectAttackTarget(
        self: *AIPlayer,
        enemy_units: []tactics.CombatUnit,
    ) ?pathfinding.Vec2 {
        _ = self;

        if (enemy_units.len == 0) return null;

        // Find center of enemy forces
        var center = pathfinding.Vec2{ .x = 0, .y = 0 };
        var count: f32 = 0;

        for (enemy_units) |enemy| {
            if (enemy.isAlive()) {
                center.x += enemy.position.x;
                center.y += enemy.position.y;
                count += 1;
            }
        }

        if (count > 0) {
            center.x /= count;
            center.y /= count;
            return center;
        }

        return null;
    }

    /// Get AI state for debugging
    pub fn getDebugInfo(self: *AIPlayer) AIDebugInfo {
        return AIDebugInfo{
            .player_id = self.player_id,
            .faction = self.faction,
            .difficulty = self.personality.difficulty,
            .strategy = self.economy_manager.strategy,
            .money = self.economy_manager.economy.money,
            .supply_used = self.economy_manager.economy.supply_used,
            .supply_limit = self.economy_manager.economy.supply_limit,
            .build_queue_size = self.economy_manager.build_queue_len,
            .game_time = self.game_time,
        };
    }
};

/// AI debug information
pub const AIDebugInfo = struct {
    player_id: usize,
    faction: []const u8,
    difficulty: tactics.TacticalAI.AIDifficulty,
    strategy: build_orders.BuildStrategy,
    money: u32,
    supply_used: u32,
    supply_limit: u32,
    build_queue_size: usize,
    game_time: f32,

    pub fn print(self: AIDebugInfo) void {
        std.debug.print("AI Player {}: {s}\n", .{ self.player_id, self.faction });
        std.debug.print("  Difficulty: {}\n", .{self.difficulty});
        std.debug.print("  Strategy: {}\n", .{self.strategy});
        std.debug.print("  Money: ${}\n", .{self.money});
        std.debug.print("  Supply: {}/{}\n", .{ self.supply_used, self.supply_limit });
        std.debug.print("  Build Queue: {} items\n", .{self.build_queue_size});
        std.debug.print("  Game Time: {d:.1}s\n", .{self.game_time});
    }
};

/// AI Manager for multiple AI players (simplified for demo)
pub const AIManager = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AIManager {
        return AIManager{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AIManager) void {
        _ = self;
    }
};

// Tests
test "AI initialization" {
    const allocator = std.testing.allocator;

    var ai_player = try AIPlayer.init(
        allocator,
        0,
        "USA",
        .Medium,
        128,
        128,
    );
    defer ai_player.deinit();

    try std.testing.expect(ai_player.player_id == 0);
    try std.testing.expect(std.mem.eql(u8, ai_player.faction, "USA"));
}

test "AI pathfinding" {
    const allocator = std.testing.allocator;

    var ai_player = try AIPlayer.init(
        allocator,
        0,
        "USA",
        .Medium,
        128,
        128,
    );
    defer ai_player.deinit();

    const start = pathfinding.Vec2{ .x = 10.0, .y = 10.0 };
    const goal = pathfinding.Vec2{ .x = 50.0, .y = 50.0 };

    var path = try ai_player.findUnitPath(start, goal);
    defer path.deinit(allocator);

    try std.testing.expect(path.valid);
    try std.testing.expect(path.length > 0);
}
