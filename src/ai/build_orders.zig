// C&C Generals - AI Build Orders System
// Implements economy management, build queues, and strategic construction

const std = @import("std");

/// Build priority
pub const BuildPriority = enum {
    Critical, // Must build immediately
    High,     // Build ASAP
    Medium,   // Build when resources allow
    Low,      // Build if nothing else needed
    Optional, // Build only if excess resources

    pub fn getValue(self: BuildPriority) i32 {
        return switch (self) {
            .Critical => 100,
            .High => 75,
            .Medium => 50,
            .Low => 25,
            .Optional => 10,
        };
    }
};

/// Build item type
pub const BuildItemType = enum {
    Unit,
    Building,
    Upgrade,
    Superweapon,
};

/// Build queue item
pub const BuildItem = struct {
    item_type: BuildItemType,
    name: []const u8,
    cost: u32,
    build_time: f32,
    priority: BuildPriority,
    prerequisites: []const []const u8,
    completed: bool,

    pub fn canBuild(self: BuildItem, money: u32, owned_buildings: []const []const u8) bool {
        // Check money
        if (money < self.cost) return false;

        // Check prerequisites
        for (self.prerequisites) |prereq| {
            var has_prereq = false;
            for (owned_buildings) |building| {
                if (std.mem.eql(u8, building, prereq)) {
                    has_prereq = true;
                    break;
                }
            }
            if (!has_prereq) return false;
        }

        return true;
    }
};

/// Economic state
pub const EconomyState = struct {
    money: u32,
    income_rate: f32, // $ per second
    supply_count: u32,
    supply_used: u32,
    supply_limit: u32,
    worker_count: u32,
    idle_workers: u32,
};

/// Build strategy
pub const BuildStrategy = enum {
    Rush,      // Fast aggressive build
    Boom,      // Economic expansion focus
    Turtle,    // Defensive focus
    Balanced,  // Mix of economy/military
    Tech,      // Fast tech upgrades

    pub fn getPriorityModifier(self: BuildStrategy, item: BuildItem) i32 {
        return switch (self) {
            .Rush => switch (item.item_type) {
                .Unit => 20,
                .Building => if (std.mem.eql(u8, item.name, "Barracks")) 15 else -10,
                else => -20,
            },
            .Boom => switch (item.item_type) {
                .Building => if (std.mem.indexOf(u8, item.name, "Supply") != null) 30 else 10,
                .Unit => if (std.mem.indexOf(u8, item.name, "Worker") != null) 20 else -10,
                else => -5,
            },
            .Turtle => switch (item.item_type) {
                .Building => if (std.mem.indexOf(u8, item.name, "Defense") != null or
                    std.mem.indexOf(u8, item.name, "Wall") != null) 30 else 0,
                .Unit => if (std.mem.indexOf(u8, item.name, "Tank") != null) 10 else -5,
                else => 0,
            },
            .Balanced => 0, // No modifier
            .Tech => switch (item.item_type) {
                .Upgrade => 25,
                .Building => if (std.mem.indexOf(u8, item.name, "Center") != null or
                    std.mem.indexOf(u8, item.name, "Lab") != null) 15 else 0,
                else => -10,
            },
        };
    }
};

/// AI Economy Manager
pub const EconomyManager = struct {
    allocator: std.mem.Allocator,
    strategy: BuildStrategy,
    economy: EconomyState,
    build_queue: []BuildItem,
    build_queue_len: usize,
    owned_buildings: [][]const u8,
    owned_buildings_len: usize,
    optimal_worker_ratio: f32,

    pub fn init(allocator: std.mem.Allocator, strategy: BuildStrategy) !EconomyManager {
        const build_queue = try allocator.alloc(BuildItem, 32); // Pre-allocate 32 slots
        const owned_buildings = try allocator.alloc([]const u8, 64); // Pre-allocate 64 slots

        return EconomyManager{
            .allocator = allocator,
            .strategy = strategy,
            .economy = EconomyState{
                .money = 5000,
                .income_rate = 100.0,
                .supply_count = 1,
                .supply_used = 0,
                .supply_limit = 10,
                .worker_count = 5,
                .idle_workers = 0,
            },
            .build_queue = build_queue,
            .build_queue_len = 0,
            .owned_buildings = owned_buildings,
            .owned_buildings_len = 0,
            .optimal_worker_ratio = 0.15, // 15% of supply should be workers
        };
    }

    pub fn deinit(self: *EconomyManager) void {
        self.allocator.free(self.build_queue);
        self.allocator.free(self.owned_buildings);
    }

    /// Update economy state
    pub fn update(self: *EconomyManager, delta_time: f32) void {
        // Update money based on income rate
        const income = self.economy.income_rate * delta_time;
        self.economy.money += @intFromFloat(income);

        // Process build queue
        self.processBuildQueue(delta_time);

        // Check if we need more supply
        if (self.needsSupply()) {
            _ = self.queueSupplyBuilding();
        }

        // Check if we need more workers
        if (self.needsWorkers()) {
            _ = self.queueWorker();
        }
    }

    /// Check if we need more supply capacity
    fn needsSupply(self: *EconomyManager) bool {
        const used_percent = @as(f32, @floatFromInt(self.economy.supply_used)) /
            @as(f32, @floatFromInt(self.economy.supply_limit));
        return used_percent > 0.8; // Need supply when 80% full
    }

    /// Check if we need more workers
    fn needsWorkers(self: *EconomyManager) bool {
        const worker_ratio = @as(f32, @floatFromInt(self.economy.worker_count)) /
            @as(f32, @floatFromInt(self.economy.supply_limit));
        return worker_ratio < self.optimal_worker_ratio;
    }

    /// Queue a supply building
    fn queueSupplyBuilding(self: *EconomyManager) !void {
        const supply_building = BuildItem{
            .item_type = .Building,
            .name = "Supply_Center",
            .cost = 500,
            .build_time = 20.0,
            .priority = .High,
            .prerequisites = &[_][]const u8{},
            .completed = false,
        };

        try self.addToBuildQueue(supply_building);
    }

    /// Queue a worker unit
    fn queueWorker(self: *EconomyManager) !void {
        const worker = BuildItem{
            .item_type = .Unit,
            .name = "Worker",
            .cost = 75,
            .build_time = 5.0,
            .priority = .Medium,
            .prerequisites = &[_][]const u8{"Command_Center"},
            .completed = false,
        };

        try self.addToBuildQueue(worker);
    }

    /// Add item to build queue with priority sorting
    pub fn addToBuildQueue(self: *EconomyManager, item: BuildItem) !void {
        if (self.build_queue_len >= self.build_queue.len) return; // Queue full

        // Calculate adjusted priority
        const strategy_modifier = self.strategy.getPriorityModifier(item);
        const base_priority = item.priority.getValue();
        const total_priority = base_priority + strategy_modifier;

        // Insert item in priority order
        var insert_index: usize = 0;
        for (self.build_queue[0..self.build_queue_len], 0..) |queued_item, i| {
            const queued_priority = queued_item.priority.getValue() +
                self.strategy.getPriorityModifier(queued_item);
            if (total_priority > queued_priority) {
                insert_index = i;
                break;
            }
            insert_index = i + 1;
        }

        // Shift elements to make room
        if (insert_index < self.build_queue_len) {
            var i = self.build_queue_len;
            while (i > insert_index) : (i -= 1) {
                self.build_queue[i] = self.build_queue[i - 1];
            }
        }

        self.build_queue[insert_index] = item;
        self.build_queue_len += 1;
    }

    /// Process build queue
    fn processBuildQueue(self: *EconomyManager, delta_time: f32) void {
        _ = delta_time;

        var i: usize = 0;
        while (i < self.build_queue_len) {
            var item = &self.build_queue[i];

            if (item.completed) {
                // Remove from queue by shifting
                var j = i;
                while (j < self.build_queue_len - 1) : (j += 1) {
                    self.build_queue[j] = self.build_queue[j + 1];
                }
                self.build_queue_len -= 1;
                continue;
            }

            // Check if we can afford and build this item
            if (item.canBuild(self.economy.money, self.owned_buildings[0..self.owned_buildings_len])) {
                // Deduct cost
                self.economy.money -= item.cost;

                // Mark as completed (in real game would track build time)
                item.completed = true;

                // Add building to owned buildings
                if (item.item_type == .Building and self.owned_buildings_len < self.owned_buildings.len) {
                    self.owned_buildings[self.owned_buildings_len] = item.name;
                    self.owned_buildings_len += 1;
                }

                continue;
            }

            i += 1;
        }
    }

    /// Get build recommendation based on current state
    pub fn getNextBuildRecommendation(self: *EconomyManager) ?BuildItem {
        // Early game - ensure we have basic buildings
        if (self.owned_buildings.items.len < 3) {
            return self.getEarlyGameBuild();
        }

        // Check supply
        if (self.needsSupply()) {
            return BuildItem{
                .item_type = .Building,
                .name = "Supply_Center",
                .cost = 500,
                .build_time = 20.0,
                .priority = .Critical,
                .prerequisites = &[_][]const u8{},
                .completed = false,
            };
        }

        // Strategy-specific recommendations
        return switch (self.strategy) {
            .Rush => self.getRushBuild(),
            .Boom => self.getBoomBuild(),
            .Turtle => self.getTurtleBuild(),
            .Balanced => self.getBalancedBuild(),
            .Tech => self.getTechBuild(),
        };
    }

    fn getEarlyGameBuild(self: *EconomyManager) ?BuildItem {
        // Check for Command Center
        var has_command = false;
        for (self.owned_buildings[0..self.owned_buildings_len]) |building| {
            if (std.mem.indexOf(u8, building, "Command") != null) {
                has_command = true;
                break;
            }
        }

        if (!has_command) {
            return BuildItem{
                .item_type = .Building,
                .name = "Command_Center",
                .cost = 2000,
                .build_time = 45.0,
                .priority = .Critical,
                .prerequisites = &[_][]const u8{},
                .completed = false,
            };
        }

        // Then supply
        if (self.economy.supply_count < 2) {
            return BuildItem{
                .item_type = .Building,
                .name = "Supply_Center",
                .cost = 500,
                .build_time = 20.0,
                .priority = .High,
                .prerequisites = &[_][]const u8{},
                .completed = false,
            };
        }

        // Then barracks
        return BuildItem{
            .item_type = .Building,
            .name = "Barracks",
            .cost = 500,
            .build_time = 20.0,
            .priority = .High,
            .prerequisites = &[_][]const u8{"Command_Center"},
            .completed = false,
        };
    }

    fn getRushBuild(self: *EconomyManager) ?BuildItem {
        _ = self;
        return BuildItem{
            .item_type = .Unit,
            .name = "Light_Infantry",
            .cost = 225,
            .build_time = 8.0,
            .priority = .High,
            .prerequisites = &[_][]const u8{"Barracks"},
            .completed = false,
        };
    }

    fn getBoomBuild(self: *EconomyManager) ?BuildItem {
        _ = self;
        return BuildItem{
            .item_type = .Building,
            .name = "Supply_Center",
            .cost = 500,
            .build_time = 20.0,
            .priority = .High,
            .prerequisites = &[_][]const u8{},
            .completed = false,
        };
    }

    fn getTurtleBuild(self: *EconomyManager) ?BuildItem {
        _ = self;
        return BuildItem{
            .item_type = .Building,
            .name = "Defense_Tower",
            .cost = 800,
            .build_time = 25.0,
            .priority = .High,
            .prerequisites = &[_][]const u8{"Barracks"},
            .completed = false,
        };
    }

    fn getBalancedBuild(self: *EconomyManager) ?BuildItem {
        // Alternate between economy and military
        const has_supply = self.economy.supply_count >= 3;
        const has_military = self.economy.supply_used >= 5;

        if (!has_supply) {
            return self.getBoomBuild();
        } else if (!has_military) {
            return self.getRushBuild();
        }

        return null;
    }

    fn getTechBuild(self: *EconomyManager) ?BuildItem {
        _ = self;
        return BuildItem{
            .item_type = .Upgrade,
            .name = "Advanced_Training",
            .cost = 1500,
            .build_time = 60.0,
            .priority = .Medium,
            .prerequisites = &[_][]const u8{"Barracks"},
            .completed = false,
        };
    }

    /// Evaluate if we should switch strategy
    pub fn shouldSwitchStrategy(self: *EconomyManager, game_time: f32, enemy_strength: f32) bool {
        const our_strength = @as(f32, @floatFromInt(self.economy.supply_used)) * 10.0;

        // If getting crushed, switch to defensive
        if (enemy_strength > our_strength * 1.5 and self.strategy != .Turtle) {
            return true;
        }

        // If dominating, switch to aggressive
        if (our_strength > enemy_strength * 1.5 and self.strategy != .Rush) {
            return true;
        }

        // Late game, switch to tech
        if (game_time > 600.0 and self.strategy != .Tech) {
            return true;
        }

        return false;
    }

    /// Switch to new strategy
    pub fn switchStrategy(self: *EconomyManager, new_strategy: BuildStrategy) void {
        self.strategy = new_strategy;

        // Clear non-critical items from queue
        var i: usize = 0;
        while (i < self.build_queue_len) {
            if (self.build_queue[i].priority != .Critical) {
                // Remove by shifting
                var j = i;
                while (j < self.build_queue_len - 1) : (j += 1) {
                    self.build_queue[j] = self.build_queue[j + 1];
                }
                self.build_queue_len -= 1;
            } else {
                i += 1;
            }
        }
    }
};

/// Build order preset for different factions and strategies
pub const BuildOrderPreset = struct {
    name: []const u8,
    faction: []const u8,
    strategy: BuildStrategy,
    steps: []const BuildStep,

    pub const BuildStep = struct {
        supply: u32, // Build when supply reaches this
        build: []const u8, // What to build
        count: u32, // How many
    };

    // Example USA Rush build order
    pub const USA_RUSH = BuildOrderPreset{
        .name = "USA Fast Rush",
        .faction = "USA",
        .strategy = .Rush,
        .steps = &[_]BuildStep{
            .{ .supply = 10, .build = "Barracks", .count = 1 },
            .{ .supply = 10, .build = "Supply_Center", .count = 1 },
            .{ .supply = 15, .build = "Ranger", .count = 5 },
            .{ .supply = 20, .build = "War_Factory", .count = 1 },
            .{ .supply = 25, .build = "Humvee", .count = 3 },
            .{ .supply = 30, .build = "Crusader_Tank", .count = 4 },
        },
    };

    // Example China Boom build order
    pub const CHINA_BOOM = BuildOrderPreset{
        .name = "China Economic Boom",
        .faction = "China",
        .strategy = .Boom,
        .steps = &[_]BuildStep{
            .{ .supply = 10, .build = "Supply_Center", .count = 2 },
            .{ .supply = 15, .build = "Worker", .count = 10 },
            .{ .supply = 20, .build = "Supply_Center", .count = 2 },
            .{ .supply = 25, .build = "War_Factory", .count = 1 },
            .{ .supply = 30, .build = "Nuclear_Reactor", .count = 1 },
        },
    };
};
