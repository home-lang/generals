// AI Player System
// High-level AI strategic decision making
// Based on Thyme's AI system

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Entity = @import("entity.zig").Entity;
const EntityId = @import("entity.zig").EntityId;
const EntityManager = @import("entity.zig").EntityManager;
const BuildingType = @import("economy.zig").BuildingType;
const EconomyManager = @import("economy.zig").EconomyManager;

/// AI difficulty level
pub const AIDifficulty = enum {
    EASY,
    MEDIUM,
    HARD,
    BRUTAL,
};

/// AI personality type (from Thyme's AI scripts)
pub const AIPersonality = enum {
    AGGRESSIVE,  // Rush-focused
    DEFENSIVE,   // Turtle, tech up
    BALANCED,    // Mix of both
    ECONOMIC,    // Economy-focused
};

/// AI strategic state
pub const AIState = enum {
    EARLY_GAME,    // 0-5 minutes: Build base, scouts
    MID_GAME,      // 5-15 minutes: Expand, tech up
    LATE_GAME,     // 15+ minutes: Mass armies
    DESPERATE,     // Losing badly
    WINNING,       // Ahead
};

/// Build order entry
pub const BuildOrderEntry = struct {
    building_type: BuildingType,
    priority: u8,          // 0-255, higher = more important
    min_money: u32,        // Don't build until we have this much
    prerequisite: ?BuildingType, // Requires this building first
};

/// AI squad (group of units)
pub const AISquad = struct {
    id: u32,
    unit_ids: std.ArrayList(EntityId),
    role: SquadRole,
    target_position: ?Vec2,
    state: SquadState,
    allocator: Allocator,

    pub fn init(allocator: Allocator, id: u32, role: SquadRole) AISquad {
        return .{
            .id = id,
            .unit_ids = std.ArrayList(EntityId){},
            .role = role,
            .target_position = null,
            .state = .IDLE,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *AISquad) void {
        self.unit_ids.deinit(self.allocator);
    }

    pub fn addUnit(self: *AISquad, unit_id: EntityId) !void {
        try self.unit_ids.append(self.allocator, unit_id);
    }

    pub fn removeUnit(self: *AISquad, unit_id: EntityId) void {
        for (self.unit_ids.items, 0..) |id, i| {
            if (id == unit_id) {
                _ = self.unit_ids.swapRemove(i);
                return;
            }
        }
    }

    pub fn getSize(self: *const AISquad) usize {
        return self.unit_ids.items.len;
    }
};

/// Squad role
pub const SquadRole = enum {
    SCOUT,
    ATTACK,
    DEFEND,
    HARASS,
    SUPPORT,
};

/// Squad state
pub const SquadState = enum {
    IDLE,
    MOVING,
    ATTACKING,
    DEFENDING,
    RETREATING,
};

/// AI Player controller
pub const AIPlayer = struct {
    player_index: i32,
    team_id: u8,
    difficulty: AIDifficulty,
    personality: AIPersonality,
    state: AIState,

    // Managers
    economy: *EconomyManager,
    entity_manager: *EntityManager,
    allocator: Allocator,

    // Squads
    squads: std.ArrayList(AISquad),
    next_squad_id: u32,

    // Build queue
    build_queue: std.ArrayList(BuildOrderEntry),

    // Timers
    game_time: f32,
    last_build_check: f32,
    last_attack_check: f32,
    last_scout_check: f32,
    last_economy_check: f32,

    // Statistics
    units_built: u32,
    units_lost: u32,
    enemies_killed: u32,

    // Thresholds (vary by difficulty)
    build_check_interval: f32,
    attack_threshold: u32,  // Min units before attacking
    max_squads: u32,

    pub fn init(
        allocator: Allocator,
        player_index: i32,
        team_id: u8,
        difficulty: AIDifficulty,
        personality: AIPersonality,
        economy: *EconomyManager,
        entity_manager: *EntityManager,
    ) AIPlayer {
        // Set difficulty parameters
        const build_interval = switch (difficulty) {
            .EASY => 5.0,
            .MEDIUM => 3.0,
            .HARD => 2.0,
            .BRUTAL => 1.0,
        };

        const attack_threshold = switch (difficulty) {
            .EASY => 15,
            .MEDIUM => 10,
            .HARD => 7,
            .BRUTAL => 5,
        };

        return .{
            .player_index = player_index,
            .team_id = team_id,
            .difficulty = difficulty,
            .personality = personality,
            .state = .EARLY_GAME,
            .economy = economy,
            .entity_manager = entity_manager,
            .allocator = allocator,
            .squads = std.ArrayList(AISquad){},
            .next_squad_id = 1,
            .build_queue = std.ArrayList(BuildOrderEntry){},
            .game_time = 0.0,
            .last_build_check = 0.0,
            .last_attack_check = 0.0,
            .last_scout_check = 0.0,
            .last_economy_check = 0.0,
            .units_built = 0,
            .units_lost = 0,
            .enemies_killed = 0,
            .build_check_interval = build_interval,
            .attack_threshold = attack_threshold,
            .max_squads = 10,
        };
    }

    pub fn deinit(self: *AIPlayer) void {
        for (self.squads.items) |*squad| {
            squad.deinit();
        }
        self.squads.deinit(self.allocator);
        self.build_queue.deinit(self.allocator);
    }

    /// Main AI update
    pub fn update(self: *AIPlayer, dt: f32) void {
        self.game_time += dt;

        // Update game state
        self.updateGameState();

        // Check timers for different AI tasks
        if (self.game_time - self.last_economy_check > 2.0) {
            self.updateEconomy();
            self.last_economy_check = self.game_time;
        }

        if (self.game_time - self.last_build_check > self.build_check_interval) {
            self.updateBuilding();
            self.last_build_check = self.game_time;
        }

        if (self.game_time - self.last_scout_check > 10.0) {
            self.updateScouting();
            self.last_scout_check = self.game_time;
        }

        if (self.game_time - self.last_attack_check > 5.0) {
            self.updateAttacks();
            self.last_attack_check = self.game_time;
        }

        // Update squads
        self.updateSquads(dt);
    }

    /// Update game state based on time and situation
    fn updateGameState(self: *AIPlayer) void {
        if (self.game_time < 300.0) { // 5 minutes
            self.state = .EARLY_GAME;
        } else if (self.game_time < 900.0) { // 15 minutes
            self.state = .MID_GAME;
        } else {
            self.state = .LATE_GAME;
        }

        // Check if desperate (few buildings left)
        if (self.economy.countBuildings() < 3) {
            self.state = .DESPERATE;
        }

        // Check if winning (lots of units)
        const unit_count = self.countOwnUnits();
        if (unit_count > 50) {
            self.state = .WINNING;
        }
    }

    /// Update economy decisions
    fn updateEconomy(self: *AIPlayer) void {
        const money = self.economy.money.getAmount();

        // Always try to build supply buildings if low on income
        if (money < 1000) {
            // Queue supply building
            self.queueBuilding(.USA_SUPPLY_CENTER, 200);
        }

        // Build power if needed
        if (!self.economy.energy.hasSufficientPower()) {
            self.queueBuilding(.USA_COLD_FUSION_REACTOR, 255);
        }
    }

    /// Update building decisions
    fn updateBuilding(self: *AIPlayer) void {
        // Early game: Command Center → Barracks → Supply
        switch (self.state) {
            .EARLY_GAME => {
                if (!self.hasBuilding(.USA_COMMAND_CENTER)) {
                    self.queueBuilding(.USA_COMMAND_CENTER, 255);
                } else if (!self.hasBuilding(.USA_BARRACKS)) {
                    self.queueBuilding(.USA_BARRACKS, 200);
                } else if (!self.hasBuilding(.USA_SUPPLY_CENTER)) {
                    self.queueBuilding(.USA_SUPPLY_CENTER, 190);
                }
            },
            .MID_GAME => {
                // Tech up
                if (!self.hasBuilding(.USA_WAR_FACTORY)) {
                    self.queueBuilding(.USA_WAR_FACTORY, 180);
                }
                if (!self.hasBuilding(.USA_STRATEGY_CENTER)) {
                    self.queueBuilding(.USA_STRATEGY_CENTER, 150);
                }
            },
            .LATE_GAME => {
                // Build superweapons
                if (!self.hasBuilding(.USA_PARTICLE_CANNON)) {
                    self.queueBuilding(.USA_PARTICLE_CANNON, 100);
                }
            },
            .DESPERATE => {
                // Just try to rebuild basics
                if (!self.hasBuilding(.USA_BARRACKS)) {
                    self.queueBuilding(.USA_BARRACKS, 255);
                }
            },
            .WINNING => {
                // Keep pressure
            },
        }

        // Process build queue
        self.processBuildQueue();
    }

    /// Update scouting
    fn updateScouting(self: *AIPlayer) void {
        // Check if we have a scout squad
        var has_scout = false;
        for (self.squads.items) |squad| {
            if (squad.role == .SCOUT) {
                has_scout = true;
                break;
            }
        }

        if (!has_scout and self.countOwnUnits() > 3) {
            // Create scout squad
            self.createSquad(.SCOUT) catch {};
        }
    }

    /// Update attack decisions
    fn updateAttacks(self: *AIPlayer) void {
        const unit_count = self.countOwnUnits();

        // Aggressive personality attacks sooner
        const threshold = switch (self.personality) {
            .AGGRESSIVE => self.attack_threshold / 2,
            .DEFENSIVE => self.attack_threshold * 2,
            .BALANCED => self.attack_threshold,
            .ECONOMIC => self.attack_threshold * 3,
        };

        if (unit_count >= threshold) {
            // Create attack squad if we don't have one
            var has_attack_squad = false;
            for (self.squads.items) |squad| {
                if (squad.role == .ATTACK and squad.state != .IDLE) {
                    has_attack_squad = true;
                    break;
                }
            }

            if (!has_attack_squad) {
                self.launchAttack() catch {};
            }
        }
    }

    /// Update all squads
    fn updateSquads(self: *AIPlayer, dt: f32) void {
        _ = dt;

        for (self.squads.items) |*squad| {
            switch (squad.state) {
                .IDLE => {
                    // Assign orders based on role
                    switch (squad.role) {
                        .SCOUT => {
                            // Send to random location
                            squad.target_position = Vec2.init(
                                @floatFromInt(std.crypto.random.intRangeAtMost(u32, 0, 1000)),
                                @floatFromInt(std.crypto.random.intRangeAtMost(u32, 0, 1000)),
                            );
                            squad.state = .MOVING;
                        },
                        .ATTACK => {
                            // Find enemy base
                            squad.state = .ATTACKING;
                        },
                        else => {},
                    }
                },
                .MOVING => {
                    // Check if reached destination
                },
                .ATTACKING => {
                    // Continue attacking
                },
                .DEFENDING => {
                    // Hold position
                },
                .RETREATING => {
                    // Fall back to base
                },
            }
        }
    }

    /// Queue a building for construction
    fn queueBuilding(self: *AIPlayer, building_type: BuildingType, priority: u8) void {
        const entry = BuildOrderEntry{
            .building_type = building_type,
            .priority = priority,
            .min_money = 0,
            .prerequisite = null,
        };
        self.build_queue.append(self.allocator, entry) catch {};
    }

    /// Process build queue
    fn processBuildQueue(self: *AIPlayer) void {
        if (self.build_queue.items.len == 0) return;

        // Sort by priority (simple bubble sort for now)
        var i: usize = 0;
        while (i < self.build_queue.items.len - 1) : (i += 1) {
            if (self.build_queue.items[i].priority < self.build_queue.items[i + 1].priority) {
                const temp = self.build_queue.items[i];
                self.build_queue.items[i] = self.build_queue.items[i + 1];
                self.build_queue.items[i + 1] = temp;
            }
        }

        // Try to build first item
        const entry = self.build_queue.items[0];
        if (self.economy.canAffordBuilding(entry.building_type)) {
            // TODO: Find placement location
            const x: f32 = 500.0;
            const y: f32 = 500.0;
            _ = self.economy.purchaseBuilding(entry.building_type, x, y, self.player_index) catch null;

            // Remove from queue
            _ = self.build_queue.orderedRemove(0);
        }
    }

    /// Check if AI has a specific building
    fn hasBuilding(self: *AIPlayer, building_type: BuildingType) bool {
        return self.economy.findBuildingByType(building_type) != null;
    }

    /// Count units owned by this AI
    fn countOwnUnits(self: *AIPlayer) u32 {
        var count: u32 = 0;
        for (self.entity_manager.entities.items) |*entity| {
            if (entity.active and entity.team == self.team_id and entity.entity_type == .unit) {
                count += 1;
            }
        }
        return count;
    }

    /// Create a new squad
    fn createSquad(self: *AIPlayer, role: SquadRole) !u32 {
        const id = self.next_squad_id;
        self.next_squad_id += 1;

        var squad = AISquad.init(self.allocator, id, role);
        try self.squads.append(self.allocator, squad);

        return id;
    }

    /// Launch attack
    fn launchAttack(self: *AIPlayer) !void {
        const squad_id = try self.createSquad(.ATTACK);
        _ = squad_id;

        // Add units to squad
        var added: u32 = 0;
        for (self.entity_manager.entities.items) |*entity| {
            if (entity.active and entity.team == self.team_id and entity.entity_type == .unit) {
                if (self.squads.items.len > 0) {
                    var squad = &self.squads.items[self.squads.items.len - 1];
                    try squad.addUnit(entity.id);
                    added += 1;

                    if (added >= 10) break; // Squad of 10 units
                }
            }
        }
    }
};

// Tests
test "AIPlayer: initialization" {
    var economy = EconomyManager.init(std.testing.allocator, 5000, 0);
    defer economy.deinit();

    var entity_manager = try EntityManager.init(std.testing.allocator);
    defer entity_manager.deinit();

    var ai = AIPlayer.init(
        std.testing.allocator,
        0,
        0,
        .MEDIUM,
        .BALANCED,
        &economy,
        &entity_manager,
    );
    defer ai.deinit();

    try std.testing.expectEqual(AIDifficulty.MEDIUM, ai.difficulty);
    try std.testing.expectEqual(AIState.EARLY_GAME, ai.state);
}
