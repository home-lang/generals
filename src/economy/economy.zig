// C&C Generals - Economy System
// Resource gathering, building construction, and upgrade management

const std = @import("std");
const units = @import("../game_data/units.zig");
const buildings = @import("../game_data/buildings.zig");
const upgrades = @import("../game_data/upgrades.zig");

/// Resource types
pub const ResourceType = enum {
    Money,
    Supply,
    Power,
};

/// Player economy state
pub const PlayerEconomy = struct {
    player_id: usize,
    money: i32,
    money_income_rate: f32, // Per second
    supply_used: u32,
    supply_limit: u32,
    power_produced: i32,
    power_consumed: i32,
    workers: u32,
    idle_workers: u32,

    pub fn init(player_id: usize) PlayerEconomy {
        return PlayerEconomy{
            .player_id = player_id,
            .money = 10000, // Starting money
            .money_income_rate = 0,
            .supply_used = 0,
            .supply_limit = 10,
            .power_produced = 0,
            .power_consumed = 0,
            .workers = 5,
            .idle_workers = 5,
        };
    }

    pub fn canAfford(self: *PlayerEconomy, cost: u32) bool {
        return self.money >= cost;
    }

    pub fn spendMoney(self: *PlayerEconomy, cost: u32) bool {
        if (!self.canAfford(cost)) return false;
        self.money -= @intCast(cost);
        return true;
    }

    pub fn earnMoney(self: *PlayerEconomy, amount: u32) void {
        self.money += @intCast(amount);
    }

    pub fn hasSupply(self: *PlayerEconomy, required: u32) bool {
        return (self.supply_used + required) <= self.supply_limit;
    }

    pub fn hasPower(self: *PlayerEconomy) bool {
        return self.power_produced >= self.power_consumed;
    }

    pub fn getPowerDeficit(self: *PlayerEconomy) i32 {
        return @max(0, self.power_consumed - self.power_produced);
    }
};

/// Supply gathering site
pub const SupplySite = struct {
    id: usize,
    position: Vec3,
    total_supply: u32,
    remaining_supply: u32,
    is_depleted: bool,
    workers_assigned: u32,
    owner_id: ?usize,

    pub fn gather(self: *SupplySite, amount: u32) u32 {
        const actual_amount = @min(amount, self.remaining_supply);
        self.remaining_supply -= actual_amount;

        if (self.remaining_supply == 0) {
            self.is_depleted = true;
        }

        return actual_amount;
    }
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

/// Building construction state
pub const Construction = struct {
    id: usize,
    building_type: []const u8,
    position: Vec3,
    cost: u32,
    build_time: f32,
    elapsed_time: f32,
    progress: f32, // 0.0 to 1.0
    owner_id: usize,
    is_complete: bool,
    is_cancelled: bool,

    pub fn update(self: *Construction, delta_time: f32) void {
        if (self.is_complete or self.is_cancelled) return;

        self.elapsed_time += delta_time;
        self.progress = @min(1.0, self.elapsed_time / self.build_time);

        if (self.progress >= 1.0) {
            self.is_complete = true;
        }
    }

    pub fn cancel(self: *Construction) u32 {
        self.is_cancelled = true;
        // Refund half the cost
        return self.cost / 2;
    }
};

/// Upgrade research state
pub const Research = struct {
    id: usize,
    upgrade_name: []const u8,
    cost: u32,
    research_time: f32,
    elapsed_time: f32,
    progress: f32,
    owner_id: usize,
    is_complete: bool,
    is_cancelled: bool,

    pub fn update(self: *Research, delta_time: f32) void {
        if (self.is_complete or self.is_cancelled) return;

        self.elapsed_time += delta_time;
        self.progress = @min(1.0, self.elapsed_time / self.research_time);

        if (self.progress >= 1.0) {
            self.is_complete = true;
        }
    }

    pub fn cancel(self: *Research) u32 {
        self.is_cancelled = true;
        return self.cost / 2;
    }
};

/// Economy manager
pub const EconomyManager = struct {
    allocator: std.mem.Allocator,
    player_economies: []PlayerEconomy,
    player_count: usize,
    supply_sites: []SupplySite,
    supply_site_count: usize,
    constructions: []Construction,
    construction_count: usize,
    researches: []Research,
    research_count: usize,
    next_construction_id: usize,
    next_research_id: usize,
    next_supply_site_id: usize,

    pub fn init(allocator: std.mem.Allocator, max_players: usize) !EconomyManager {
        const player_economies = try allocator.alloc(PlayerEconomy, max_players);

        return EconomyManager{
            .allocator = allocator,
            .player_economies = player_economies,
            .player_count = 0,
            .supply_sites = try allocator.alloc(SupplySite, 100),
            .supply_site_count = 0,
            .constructions = try allocator.alloc(Construction, 200),
            .construction_count = 0,
            .researches = try allocator.alloc(Research, 50),
            .research_count = 0,
            .next_construction_id = 0,
            .next_research_id = 0,
            .next_supply_site_id = 0,
        };
    }

    pub fn deinit(self: *EconomyManager) void {
        self.allocator.free(self.player_economies);
        self.allocator.free(self.supply_sites);
        self.allocator.free(self.constructions);
        self.allocator.free(self.researches);
    }

    /// Add player to economy system
    pub fn addPlayer(self: *EconomyManager, player_id: usize) !void {
        if (self.player_count >= self.player_economies.len) return error.TooManyPlayers;

        self.player_economies[self.player_count] = PlayerEconomy.init(player_id);
        self.player_count += 1;
    }

    /// Get player economy
    pub fn getPlayerEconomy(self: *EconomyManager, player_id: usize) ?*PlayerEconomy {
        for (self.player_economies[0..self.player_count]) |*econ| {
            if (econ.player_id == player_id) return econ;
        }
        return null;
    }

    /// Add supply site to map
    pub fn addSupplySite(self: *EconomyManager, position: Vec3, supply_amount: u32) !usize {
        if (self.supply_site_count >= self.supply_sites.len) return error.TooManySupplySites;

        const id = self.next_supply_site_id;
        self.supply_sites[self.supply_site_count] = SupplySite{
            .id = id,
            .position = position,
            .total_supply = supply_amount,
            .remaining_supply = supply_amount,
            .is_depleted = false,
            .workers_assigned = 0,
            .owner_id = null,
        };

        self.next_supply_site_id += 1;
        self.supply_site_count += 1;
        return id;
    }

    /// Start building construction
    pub fn startConstruction(
        self: *EconomyManager,
        player_id: usize,
        building_name: []const u8,
        position: Vec3,
        cost: u32,
        build_time: f32,
    ) !usize {
        if (self.construction_count >= self.constructions.len) return error.TooManyConstructions;

        const player_econ = self.getPlayerEconomy(player_id) orelse return error.PlayerNotFound;

        // Check if player can afford
        if (!player_econ.spendMoney(cost)) return error.InsufficientFunds;

        const id = self.next_construction_id;
        self.constructions[self.construction_count] = Construction{
            .id = id,
            .building_type = building_name,
            .position = position,
            .cost = cost,
            .build_time = build_time,
            .elapsed_time = 0,
            .progress = 0,
            .owner_id = player_id,
            .is_complete = false,
            .is_cancelled = false,
        };

        self.next_construction_id += 1;
        self.construction_count += 1;
        return id;
    }

    /// Start upgrade research
    pub fn startResearch(
        self: *EconomyManager,
        player_id: usize,
        upgrade_name: []const u8,
        cost: u32,
        research_time: f32,
    ) !usize {
        if (self.research_count >= self.researches.len) return error.TooManyResearches;

        const player_econ = self.getPlayerEconomy(player_id) orelse return error.PlayerNotFound;

        if (!player_econ.spendMoney(cost)) return error.InsufficientFunds;

        const id = self.next_research_id;
        self.researches[self.research_count] = Research{
            .id = id,
            .upgrade_name = upgrade_name,
            .cost = cost,
            .research_time = research_time,
            .elapsed_time = 0,
            .progress = 0,
            .owner_id = player_id,
            .is_complete = false,
            .is_cancelled = false,
        };

        self.next_research_id += 1;
        self.research_count += 1;
        return id;
    }

    /// Update economy system
    pub fn update(self: *EconomyManager, delta_time: f32) void {
        // Update player economies (income)
        for (self.player_economies[0..self.player_count]) |*econ| {
            const income = @as(i32, @intFromFloat(econ.money_income_rate * delta_time));
            econ.money += income;
        }

        // Update constructions
        var i: usize = 0;
        while (i < self.construction_count) {
            var construction = &self.constructions[i];

            if (construction.is_complete or construction.is_cancelled) {
                // Handle completed or cancelled construction
                if (construction.is_cancelled) {
                    if (self.getPlayerEconomy(construction.owner_id)) |econ| {
                        const refund = construction.cancel();
                        econ.earnMoney(refund);
                    }
                }

                // Remove from active constructions
                if (i < self.construction_count - 1) {
                    self.constructions[i] = self.constructions[self.construction_count - 1];
                }
                self.construction_count -= 1;
                continue;
            }

            construction.update(delta_time);
            i += 1;
        }

        // Update researches
        i = 0;
        while (i < self.research_count) {
            var research = &self.researches[i];

            if (research.is_complete or research.is_cancelled) {
                if (research.is_cancelled) {
                    if (self.getPlayerEconomy(research.owner_id)) |econ| {
                        const refund = research.cancel();
                        econ.earnMoney(refund);
                    }
                }

                // Remove from active researches
                if (i < self.research_count - 1) {
                    self.researches[i] = self.researches[self.research_count - 1];
                }
                self.research_count -= 1;
                continue;
            }

            research.update(delta_time);
            i += 1;
        }
    }

    /// Gather resources from supply site
    pub fn gatherResources(
        self: *EconomyManager,
        player_id: usize,
        supply_site_id: usize,
        workers: u32,
    ) !u32 {
        const player_econ = self.getPlayerEconomy(player_id) orelse return error.PlayerNotFound;

        // Find supply site
        var supply_site: ?*SupplySite = null;
        for (self.supply_sites[0..self.supply_site_count]) |*site| {
            if (site.id == supply_site_id) {
                supply_site = site;
                break;
            }
        }

        if (supply_site == null) return error.SupplySiteNotFound;
        const site = supply_site.?;

        if (site.is_depleted) return error.SupplySiteDepleted;

        // Gather rate: 10 money per worker per second (assuming 1 second tick)
        const gather_amount = workers * 10;
        const actual_amount = site.gather(gather_amount);

        player_econ.earnMoney(actual_amount);
        player_econ.money_income_rate = @as(f32, @floatFromInt(workers)) * 10.0;

        return actual_amount;
    }

    /// Get economy statistics
    pub fn getStats(self: *EconomyManager) EconomyStats {
        var total_money: i32 = 0;
        var total_supply_sites: usize = 0;
        var depleted_sites: usize = 0;

        for (self.player_economies[0..self.player_count]) |econ| {
            total_money += econ.money;
        }

        for (self.supply_sites[0..self.supply_site_count]) |site| {
            total_supply_sites += 1;
            if (site.is_depleted) depleted_sites += 1;
        }

        return EconomyStats{
            .total_players = self.player_count,
            .total_money = total_money,
            .total_supply_sites = total_supply_sites,
            .depleted_sites = depleted_sites,
            .active_constructions = self.construction_count,
            .active_researches = self.research_count,
        };
    }
};

pub const EconomyStats = struct {
    total_players: usize,
    total_money: i32,
    total_supply_sites: usize,
    depleted_sites: usize,
    active_constructions: usize,
    active_researches: usize,
};
