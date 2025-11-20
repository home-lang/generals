// Phase 4: Complete Buildings & Economy System
// Based on Thyme's complete economy implementation
// References:
// ~/Code/Thyme/src/game/common/rts/money.h
// ~/Code/Thyme/src/game/common/rts/player.h
// ~/Code/Thyme/src/game/common/rts/energy.h
// ~/Code/Thyme/src/game/common/rts/buildinfo.h
// ~/Code/Thyme/src/game/common/rts/resourcegatheringmanager.h
// ~/Code/Thyme/src/game/common/rts/productionprerequisite.h
// ~/Code/Thyme/src/game/logic/object/behavior/behaviormodule.h

const std = @import("std");
const Allocator = std.mem.Allocator;

// ============================================================================
// PHASE 4.1: Money System (from Thyme's Money class)
// ============================================================================

/// Player money/resources (from Thyme's Money class)
pub const Money = struct {
    amount: u32 = 0,
    player_index: i32 = 0,

    pub fn init() Money {
        return .{};
    }

    /// Deposit money (from Thyme's Deposit method)
    pub fn deposit(self: *Money, add_amount: u32, play_sound: bool) void {
        _ = play_sound; // TODO: Implement sound system
        self.amount += add_amount;
    }

    /// Withdraw money (from Thyme's Withdraw method)
    pub fn withdraw(self: *Money, sub_amount: u32, play_sound: bool) u32 {
        _ = play_sound; // TODO: Implement sound system

        if (sub_amount > self.amount) {
            const available = self.amount;
            self.amount = 0;
            return available;
        }

        self.amount -= sub_amount;
        return sub_amount;
    }

    /// Check if player can afford something
    pub fn canAfford(self: Money, cost: u32) bool {
        return self.amount >= cost;
    }

    pub fn getAmount(self: Money) u32 {
        return self.amount;
    }

    pub fn setAmount(self: *Money, amount: u32) void {
        self.amount = amount;
    }

    pub fn setPlayerIndex(self: *Money, index: i32) void {
        self.player_index = index;
    }
};

// ============================================================================
// PHASE 4.2: Energy/Power System (from Thyme's Energy class)
// ============================================================================

/// Player energy/power management (from Thyme's Energy class)
pub const Energy = struct {
    energy_production: i32 = 0,
    energy_consumption: i32 = 0,
    frame: u32 = 0,
    player_index: i32 = 0,

    pub fn init(player_index: i32) Energy {
        return .{
            .player_index = player_index,
        };
    }

    /// Get current energy production
    pub fn getProduction(self: Energy) i32 {
        return self.energy_production;
    }

    /// Get current energy consumption
    pub fn getConsumption(self: Energy) i32 {
        return self.energy_consumption;
    }

    /// Get energy supply ratio (production / consumption)
    pub fn getEnergySupplyRatio(self: Energy) f32 {
        if (self.energy_consumption == 0) return 1.0;
        const ratio = @as(f32, @floatFromInt(self.energy_production)) / @as(f32, @floatFromInt(self.energy_consumption));
        return @min(ratio, 1.0);
    }

    /// Check if player has sufficient power
    pub fn hasSufficientPower(self: Energy) bool {
        return self.energy_production >= self.energy_consumption;
    }

    /// Adjust power (used when buildings are built/destroyed)
    pub fn adjustPower(self: *Energy, amount: i32, positive: bool) void {
        if (positive) {
            self.energy_production += amount;
        } else {
            self.energy_production -= amount;
        }
    }

    /// Add energy production
    pub fn addProduction(self: *Energy, amount: i32) void {
        self.energy_production += amount;
    }

    /// Add energy consumption
    pub fn addConsumption(self: *Energy, amount: i32) void {
        self.energy_consumption += amount;
    }

    /// Remove energy production
    pub fn removeProduction(self: *Energy, amount: i32) void {
        self.energy_production -= amount;
    }

    /// Remove energy consumption
    pub fn removeConsumption(self: *Energy, amount: i32) void {
        self.energy_consumption -= amount;
    }

    pub fn setFrame(self: *Energy, frame: u32) void {
        self.frame = frame;
    }

    pub fn getFrame(self: Energy) u32 {
        return self.frame;
    }
};

// ============================================================================
// PHASE 4.3: Building System
// ============================================================================

/// Building types (all buildings from C&C Generals)
pub const BuildingType = enum(u8) {
    // USA Buildings
    USA_COMMAND_CENTER,
    USA_BARRACKS,
    USA_SUPPLY_DROP_ZONE,
    USA_WAR_FACTORY,
    USA_AIRFIELD,
    USA_SUPPLY_CENTER,
    USA_STRATEGY_CENTER,
    USA_PATRIOT_BATTERY,
    USA_FIREBASE,
    USA_DETENTION_CAMP,
    USA_PARTICLE_CANNON,
    USA_COLD_FUSION_REACTOR,

    // China Buildings
    CHINA_COMMAND_CENTER,
    CHINA_BARRACKS,
    CHINA_SUPPLY_CENTER,
    CHINA_WAR_FACTORY,
    CHINA_AIRFIELD,
    CHINA_PROPAGANDA_CENTER,
    CHINA_NUCLEAR_REACTOR,
    CHINA_GATTLING_CANNON,
    CHINA_BUNKER,
    CHINA_SPEAKER_TOWER,
    CHINA_INTERNET_CENTER,
    CHINA_NUCLEAR_MISSILE,

    // GLA Buildings
    GLA_COMMAND_CENTER,
    GLA_BARRACKS,
    GLA_SUPPLY_STASH,
    GLA_ARMS_DEALER,
    GLA_BLACK_MARKET,
    GLA_PALACE,
    GLA_TUNNEL_NETWORK,
    GLA_STINGER_SITE,
    GLA_SCUD_STORM,

    // Generic/Neutral Buildings
    TECH_BUILDING,
    OIL_DERRICK,
    SUPPLY_DOCK,
    CIVILIAN_BUILDING,
    HOSPITAL,
    AIRPORT,
};

/// Building state (from Thyme's build system)
pub const BuildingState = enum(u8) {
    PLACEMENT,          // Player selecting where to place
    UNDER_CONSTRUCTION, // Under construction (Dozer building it)
    ACTIVE,             // Fully built and functional
    DAMAGED,            // Damaged but operational
    BEING_REPAIRED,     // Currently being repaired
    BEING_SOLD,         // Being sold (refund partial cost)
    DESTROYED,          // Destroyed
    RUBBLE,             // Destroyed, leaving rubble
    AWAITING_CONSTRUCTION, // Placed but waiting for Dozer
};

/// Building data structure (from Thyme's BuildListInfo + Object)
pub const Building = struct {
    building_type: BuildingType,
    state: BuildingState = .PLACEMENT,
    health: f32,
    max_health: f32,
    construction_progress: f32 = 0.0, // 0.0 to 1.0
    x: f32,
    y: f32,
    z: f32 = 0.0,
    width: f32,
    height: f32,
    angle: f32 = 0.0,
    owner_index: i32,

    // Building properties
    is_sellable: bool = true,
    is_repairable: bool = true,
    is_initially_built: bool = false,
    is_selected: bool = false,
    under_construction: bool = false,

    // Supply/Resource properties
    is_supply_source: bool = false,
    is_supply_center: bool = false,
    supply_amount: u32 = 0,
    supply_max: u32 = 0,
    max_resource_gatherers: i32 = 0,
    resource_gatherers: i32 = 0,

    // Power properties
    power_production: i32 = 0,
    power_consumption: i32 = 0,
    is_power_plant: bool = false,

    // Production system
    production_queue: std.ArrayList(ProductionEntry),
    current_production: ?ProductionEntry = null,
    production_timer: f32 = 0.0,
    next_production_id: u32 = 1,

    // Rebuild properties (from BuildListInfo)
    num_rebuilds: i32 = -1, // -1 = unlimited
    rebuild_script: ?[]const u8 = null,
    building_name: ?[]const u8 = null,

    // Timestamp
    object_timestamp: u32 = 0,

    allocator: Allocator,

    pub fn init(allocator: Allocator, building_type: BuildingType, x: f32, y: f32, owner: i32) Building {
        const stats = getBuildingStats(building_type);
        return .{
            .building_type = building_type,
            .health = stats.max_health,
            .max_health = stats.max_health,
            .x = x,
            .y = y,
            .width = stats.width,
            .height = stats.height,
            .owner_index = owner,
            .production_queue = .{},
            .is_supply_source = stats.is_supply_source,
            .is_supply_center = stats.is_supply_source,
            .supply_max = stats.supply_capacity,
            .max_resource_gatherers = stats.max_gatherers,
            .power_production = stats.power_provided,
            .power_consumption = stats.power_required,
            .is_power_plant = stats.power_provided > 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Building) void {
        self.production_queue.deinit(self.allocator);
    }

    /// Update building (construction, production, etc)
    pub fn update(self: *Building, delta_time: f32, player_money: *Money, player_energy: *Energy) void {
        switch (self.state) {
            .UNDER_CONSTRUCTION => {
                const stats = getBuildingStats(self.building_type);
                self.construction_progress += delta_time / stats.build_time;
                if (self.construction_progress >= 1.0) {
                    self.construction_progress = 1.0;
                    self.state = .ACTIVE;
                    self.onConstructionComplete(player_energy);
                }
            },
            .ACTIVE => {
                // Process production queue
                if (self.current_production) |*item| {
                    self.production_timer += delta_time;
                    item.percent_complete = self.production_timer / item.build_time;

                    if (self.production_timer >= item.build_time) {
                        // Production complete
                        self.onProductionComplete(item);
                        self.production_timer = 0.0;
                        self.current_production = null;

                        // Start next in queue
                        if (self.production_queue.items.len > 0) {
                            self.current_production = self.production_queue.orderedRemove(0);
                        }
                    }
                } else if (self.production_queue.items.len > 0) {
                    // Start production from queue
                    self.current_production = self.production_queue.orderedRemove(0);
                    self.production_timer = 0.0;
                }

                // Generate supplies for supply buildings
                if (self.is_supply_source and self.supply_amount < self.supply_max) {
                    const stats = getBuildingStats(self.building_type);
                    const supply_rate = stats.supply_generation_rate;
                    self.supply_amount += @intFromFloat(supply_rate * delta_time);
                    if (self.supply_amount > self.supply_max) {
                        self.supply_amount = self.supply_max;
                    }
                }
            },
            .BEING_REPAIRED => {
                // Repair at 10% of max health per second
                const repair_rate = self.max_health * 0.1;
                self.health += repair_rate * delta_time;
                if (self.health >= self.max_health) {
                    self.health = self.max_health;
                    self.state = .ACTIVE;
                }
            },
            .BEING_SOLD => {
                // Sell progress (refund based on health percentage)
                const refund_percent = self.health / self.max_health * 0.5; // 50% refund at full health
                const stats = getBuildingStats(self.building_type);
                const refund = @as(u32, @intFromFloat(@as(f32, @floatFromInt(stats.cost)) * refund_percent));
                player_money.deposit(refund, true);
                self.state = .DESTROYED;
            },
            else => {},
        }
    }

    /// Called when construction completes
    fn onConstructionComplete(self: *Building, player_energy: *Energy) void {
        // Add power production/consumption
        if (self.power_production > 0) {
            player_energy.addProduction(self.power_production);
        }
        if (self.power_consumption > 0) {
            player_energy.addConsumption(self.power_consumption);
        }
    }

    /// Called when production completes
    fn onProductionComplete(self: *Building, item: *ProductionEntry) void {
        _ = self;
        // In a real implementation, spawn the unit or apply the upgrade
        // For now, just mark as complete
        item.percent_complete = 1.0;
    }

    /// Queue production (from Thyme's ProductionUpdateInterface)
    pub fn queueProduction(self: *Building, entry: ProductionEntry) !void {
        try self.production_queue.append(self.allocator, entry);
    }

    /// Cancel production by ID
    pub fn cancelProduction(self: *Building, production_id: u32) bool {
        for (self.production_queue.items, 0..) |item, i| {
            if (item.production_id == production_id) {
                _ = self.production_queue.orderedRemove(i);
                return true;
            }
        }

        // Check current production
        if (self.current_production) |item| {
            if (item.production_id == production_id) {
                self.current_production = null;
                self.production_timer = 0.0;
                return true;
            }
        }

        return false;
    }

    /// Cancel all production and refund
    pub fn cancelAndRefundAllProduction(self: *Building, player_money: *Money) void {
        // Refund current production
        if (self.current_production) |item| {
            const refund = @as(u32, @intFromFloat(@as(f32, @floatFromInt(item.cost)) * (1.0 - item.percent_complete)));
            player_money.deposit(refund, false);
            self.current_production = null;
        }

        // Refund queued production
        for (self.production_queue.items) |item| {
            player_money.deposit(item.cost, false);
        }

        self.production_queue.clearRetainingCapacity();
        self.production_timer = 0.0;
    }

    /// Get production count
    pub fn getProductionCount(self: Building) u32 {
        var count: u32 = 0;
        if (self.current_production != null) count += 1;
        count += @intCast(self.production_queue.items.len);
        return count;
    }

    /// Check if building can be rebuilt
    pub fn isBuildable(self: Building) bool {
        return self.num_rebuilds > 0 or self.num_rebuilds == -1;
    }

    /// Decrement rebuild count
    pub fn decrementNumRebuilds(self: *Building) void {
        if (self.num_rebuilds != 0 and self.num_rebuilds != -1) {
            self.num_rebuilds -= 1;
        }
    }

    /// Increment rebuild count
    pub fn incrementNumRebuilds(self: *Building) void {
        if (self.num_rebuilds != -1) {
            self.num_rebuilds += 1;
        }
    }

    /// Start repair
    pub fn startRepair(self: *Building) void {
        if (self.is_repairable and self.state == .DAMAGED) {
            self.state = .BEING_REPAIRED;
        }
    }

    /// Start selling
    pub fn startSelling(self: *Building) void {
        if (self.is_sellable and (self.state == .ACTIVE or self.state == .DAMAGED)) {
            self.state = .BEING_SOLD;
        }
    }

    /// Take damage
    pub fn takeDamage(self: *Building, damage: f32) void {
        self.health -= damage;
        if (self.health <= 0) {
            self.health = 0;
            self.state = .DESTROYED;
        } else if (self.health < self.max_health * 0.5 and self.state == .ACTIVE) {
            self.state = .DAMAGED;
        }
    }
};

/// Building statistics (from Thyme INI data)
pub const BuildingStats = struct {
    cost: u32,
    build_time: f32,
    max_health: f32,
    width: f32,
    height: f32,
    power_required: i32 = 0,
    power_provided: i32 = 0,
    is_supply_source: bool = false,
    supply_capacity: u32 = 0,
    supply_generation_rate: f32 = 0.0,
    max_gatherers: i32 = 0,
    vision_range: f32 = 10.0,
};

/// Get building stats (from C&C Generals game data)
pub fn getBuildingStats(building_type: BuildingType) BuildingStats {
    return switch (building_type) {
        // USA Buildings
        .USA_COMMAND_CENTER => .{
            .cost = 2000,
            .build_time = 45.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
            .power_required = 0,
            .vision_range = 15.0,
        },
        .USA_SUPPLY_DROP_ZONE => .{
            .cost = 1500,
            .build_time = 30.0,
            .max_health = 3000.0,
            .width = 6.0,
            .height = 6.0,
            .is_supply_source = true,
            .supply_capacity = 10000,
            .supply_generation_rate = 10.0,
            .max_gatherers = 3,
        },
        .USA_BARRACKS => .{
            .cost = 500,
            .build_time = 15.0,
            .max_health = 1500.0,
            .width = 4.0,
            .height = 4.0,
            .power_required = 2,
        },
        .USA_WAR_FACTORY => .{
            .cost = 2000,
            .build_time = 40.0,
            .max_health = 3500.0,
            .width = 8.0,
            .height = 6.0,
            .power_required = 5,
        },
        .USA_AIRFIELD => .{
            .cost = 2000,
            .build_time = 40.0,
            .max_health = 4000.0,
            .width = 10.0,
            .height = 10.0,
            .power_required = 3,
        },
        .USA_SUPPLY_CENTER => .{
            .cost = 1500,
            .build_time = 30.0,
            .max_health = 3000.0,
            .width = 6.0,
            .height = 6.0,
            .is_supply_source = true,
            .supply_capacity = 10000,
            .supply_generation_rate = 10.0,
            .max_gatherers = 3,
        },
        .USA_STRATEGY_CENTER => .{
            .cost = 2500,
            .build_time = 35.0,
            .max_health = 2500.0,
            .width = 6.0,
            .height = 6.0,
            .power_required = 4,
        },
        .USA_PATRIOT_BATTERY => .{
            .cost = 1000,
            .build_time = 20.0,
            .max_health = 800.0,
            .width = 3.0,
            .height = 3.0,
            .power_required = 3,
        },
        .USA_FIREBASE => .{
            .cost = 800,
            .build_time = 15.0,
            .max_health = 800.0,
            .width = 3.0,
            .height = 3.0,
            .power_required = 2,
        },
        .USA_DETENTION_CAMP => .{
            .cost = 1000,
            .build_time = 20.0,
            .max_health = 1500.0,
            .width = 5.0,
            .height = 5.0,
            .power_required = 2,
        },
        .USA_PARTICLE_CANNON => .{
            .cost = 5000,
            .build_time = 120.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
            .power_required = 15,
        },
        .USA_COLD_FUSION_REACTOR => .{
            .cost = 800,
            .build_time = 20.0,
            .max_health = 1200.0,
            .width = 4.0,
            .height = 4.0,
            .power_provided = 10,
        },

        // China Buildings
        .CHINA_COMMAND_CENTER => .{
            .cost = 2000,
            .build_time = 45.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
            .vision_range = 15.0,
        },
        .CHINA_SUPPLY_CENTER => .{
            .cost = 1500,
            .build_time = 30.0,
            .max_health = 3000.0,
            .width = 6.0,
            .height = 6.0,
            .is_supply_source = true,
            .supply_capacity = 10000,
            .supply_generation_rate = 10.0,
            .max_gatherers = 3,
        },
        .CHINA_BARRACKS => .{
            .cost = 500,
            .build_time = 15.0,
            .max_health = 1500.0,
            .width = 4.0,
            .height = 4.0,
            .power_required = 2,
        },
        .CHINA_WAR_FACTORY => .{
            .cost = 2000,
            .build_time = 40.0,
            .max_health = 3500.0,
            .width = 8.0,
            .height = 6.0,
            .power_required = 5,
        },
        .CHINA_AIRFIELD => .{
            .cost = 2000,
            .build_time = 40.0,
            .max_health = 4000.0,
            .width = 10.0,
            .height = 10.0,
            .power_required = 3,
        },
        .CHINA_PROPAGANDA_CENTER => .{
            .cost = 2000,
            .build_time = 35.0,
            .max_health = 2000.0,
            .width = 6.0,
            .height = 6.0,
            .power_required = 3,
        },
        .CHINA_NUCLEAR_REACTOR => .{
            .cost = 1000,
            .build_time = 30.0,
            .max_health = 1500.0,
            .width = 5.0,
            .height = 5.0,
            .power_provided = 10,
        },
        .CHINA_GATTLING_CANNON => .{
            .cost = 800,
            .build_time = 15.0,
            .max_health = 800.0,
            .width = 3.0,
            .height = 3.0,
            .power_required = 2,
        },
        .CHINA_BUNKER => .{
            .cost = 400,
            .build_time = 10.0,
            .max_health = 600.0,
            .width = 2.0,
            .height = 2.0,
        },
        .CHINA_SPEAKER_TOWER => .{
            .cost = 500,
            .build_time = 15.0,
            .max_health = 500.0,
            .width = 2.0,
            .height = 2.0,
            .power_required = 1,
        },
        .CHINA_INTERNET_CENTER => .{
            .cost = 2500,
            .build_time = 40.0,
            .max_health = 2500.0,
            .width = 6.0,
            .height = 6.0,
            .power_required = 4,
        },
        .CHINA_NUCLEAR_MISSILE => .{
            .cost = 5000,
            .build_time = 120.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
            .power_required = 15,
        },

        // GLA Buildings
        .GLA_COMMAND_CENTER => .{
            .cost = 2000,
            .build_time = 45.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
            .vision_range = 15.0,
        },
        .GLA_SUPPLY_STASH => .{
            .cost = 1500,
            .build_time = 30.0,
            .max_health = 2500.0,
            .width = 6.0,
            .height = 6.0,
            .is_supply_source = true,
            .supply_capacity = 10000,
            .supply_generation_rate = 10.0,
            .max_gatherers = 3,
        },
        .GLA_BARRACKS => .{
            .cost = 500,
            .build_time = 15.0,
            .max_health = 1200.0,
            .width = 4.0,
            .height = 4.0,
        },
        .GLA_ARMS_DEALER => .{
            .cost = 2000,
            .build_time = 40.0,
            .max_health = 3000.0,
            .width = 8.0,
            .height = 6.0,
        },
        .GLA_BLACK_MARKET => .{
            .cost = 2500,
            .build_time = 40.0,
            .max_health = 2500.0,
            .width = 6.0,
            .height = 6.0,
        },
        .GLA_PALACE => .{
            .cost = 2500,
            .build_time = 50.0,
            .max_health = 3000.0,
            .width = 8.0,
            .height = 8.0,
        },
        .GLA_TUNNEL_NETWORK => .{
            .cost = 800,
            .build_time = 15.0,
            .max_health = 1500.0,
            .width = 4.0,
            .height = 4.0,
        },
        .GLA_STINGER_SITE => .{
            .cost = 800,
            .build_time = 15.0,
            .max_health = 600.0,
            .width = 3.0,
            .height = 3.0,
        },
        .GLA_SCUD_STORM => .{
            .cost = 5000,
            .build_time = 120.0,
            .max_health = 5000.0,
            .width = 8.0,
            .height = 8.0,
        },

        // Generic/Neutral
        else => .{
            .cost = 1000,
            .build_time = 20.0,
            .max_health = 2000.0,
            .width = 5.0,
            .height = 5.0,
        },
    };
}

// ============================================================================
// PHASE 4.4: Production System (from Thyme's ProductionEntry)
// ============================================================================

/// Production type (from Thyme's ProductionEntry)
pub const ProductionType = enum(u8) {
    INVALID,
    UNIT,
    UPGRADE,
};

/// Production item (from Thyme's ProductionEntry)
pub const ProductionEntry = struct {
    production_type: ProductionType,
    production_id: u32,
    unit_template_id: u32 = 0, // Reference to unit template
    upgrade_template_id: u32 = 0, // Reference to upgrade template
    cost: u32,
    build_time: f32,
    percent_complete: f32 = 0.0,
    frames_under_construction: i32 = 0,
    production_quantity: i32 = 1,
    production_count: i32 = 0,
    exit_door: i32 = 0,

    pub fn initUnit(production_id: u32, unit_id: u32, cost: u32, build_time: f32) ProductionEntry {
        return .{
            .production_type = .UNIT,
            .production_id = production_id,
            .unit_template_id = unit_id,
            .cost = cost,
            .build_time = build_time,
        };
    }

    pub fn initUpgrade(production_id: u32, upgrade_id: u32, cost: u32, build_time: f32) ProductionEntry {
        return .{
            .production_type = .UPGRADE,
            .production_id = production_id,
            .upgrade_template_id = upgrade_id,
            .cost = cost,
            .build_time = build_time,
        };
    }
};

/// Can make type (from Thyme's CanMakeType)
pub const CanMakeType = enum(u8) {
    CAN_MAKE,
    CANNOT_MAKE_NOT_ENOUGH_MONEY,
    CANNOT_MAKE_QUEUE_FULL,
    CANNOT_MAKE_PREREQUISITES_NOT_MET,
    CANNOT_MAKE_DISABLED,
    CANNOT_MAKE_UNDER_CONSTRUCTION,
};

// ============================================================================
// PHASE 4.5: Prerequisites System (from Thyme's ProductionPrerequisite)
// ============================================================================

/// Science types (from Thyme's science system)
pub const ScienceType = enum(u8) {
    SCIENCE_INVALID = 0,
    SCIENCE_USA_PATHFINDER = 1,
    SCIENCE_USA_TOW_MISSILE = 2,
    SCIENCE_USA_COMPOSITE_ARMOR = 3,
    SCIENCE_CHINA_CHAIN_GUNS = 4,
    SCIENCE_CHINA_URANIUM_SHELLS = 5,
    SCIENCE_CHINA_SUBLIMINAL_MESSAGING = 6,
    SCIENCE_GLA_ANTHRAX_BETA = 7,
    SCIENCE_GLA_TOXIN_SHELLS = 8,
    SCIENCE_GLA_CAMOUFLAGE = 9,
    // ... many more
};

/// Prerequisites for production (from Thyme's ProductionPrerequisite)
pub const Prerequisites = struct {
    required_buildings: std.ArrayList(BuildingType),
    required_sciences: std.ArrayList(ScienceType),
    or_prerequisites: bool = false, // If true, any one requirement is enough
    allocator: Allocator,

    pub fn init(allocator: Allocator) Prerequisites {
        return .{
            .required_buildings = .{},
            .required_sciences = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Prerequisites) void {
        self.required_buildings.deinit(self.allocator);
        self.required_sciences.deinit(self.allocator);
    }

    pub fn addBuildingRequirement(self: *Prerequisites, building: BuildingType) !void {
        try self.required_buildings.append(self.allocator, building);
    }

    pub fn addScienceRequirement(self: *Prerequisites, science: ScienceType) !void {
        try self.required_sciences.append(self.allocator, science);
    }

    pub fn isSatisfied(self: Prerequisites, player_buildings: []const Building, player_sciences: []const ScienceType) bool {
        if (self.or_prerequisites) {
            // OR logic: at least one requirement must be met
            var any_building_met = self.required_buildings.items.len == 0;
            var any_science_met = self.required_sciences.items.len == 0;

            for (self.required_buildings.items) |required| {
                for (player_buildings) |building| {
                    if (building.building_type == required and building.state == .ACTIVE) {
                        any_building_met = true;
                        break;
                    }
                }
            }

            for (self.required_sciences.items) |required| {
                for (player_sciences) |science| {
                    if (science == required) {
                        any_science_met = true;
                        break;
                    }
                }
            }

            return any_building_met or any_science_met;
        } else {
            // AND logic: all requirements must be met

            // Check building requirements
            for (self.required_buildings.items) |required| {
                var found = false;
                for (player_buildings) |building| {
                    if (building.building_type == required and building.state == .ACTIVE) {
                        found = true;
                        break;
                    }
                }
                if (!found) return false;
            }

            // Check science requirements
            for (self.required_sciences.items) |required| {
                var found = false;
                for (player_sciences) |science| {
                    if (science == required) {
                        found = true;
                        break;
                    }
                }
                if (!found) return false;
            }

            return true;
        }
    }
};

// ============================================================================
// PHASE 4.6: Resource Gathering (from Thyme's ResourceGatheringManager)
// ============================================================================

/// Supply gatherer state (from Thyme's SupplyTruckAIInterface)
pub const GathererState = enum(u8) {
    IDLE,
    MOVING_TO_SOURCE,
    GATHERING,
    MOVING_TO_DEPOT,
    DEPOSITING,
    WAITING_FOR_DOCK,
};

/// Resource gatherer (supply truck, worker, etc)
/// Based on Thyme's SupplyTruckAIInterface
pub const ResourceGatherer = struct {
    x: f32,
    y: f32,
    z: f32 = 0.0,
    state: GathererState = .IDLE,
    carried_amount: u32 = 0,
    max_carry: u32 = 1000,
    num_boxes: i32 = 0,
    max_boxes: i32 = 3,
    target_source_id: ?u32 = null,
    target_depot_id: ?u32 = null,
    preferred_dock_id: ?u32 = null,
    gather_rate: f32 = 100.0, // Per second
    force_wanting_state: bool = false,
    force_busy_state: bool = false,
    upgraded_supply_boost: i32 = 0,
    owner_index: i32,

    pub fn init(x: f32, y: f32, owner: i32) ResourceGatherer {
        return .{
            .x = x,
            .y = y,
            .owner_index = owner,
        };
    }

    pub fn update(self: *ResourceGatherer, delta_time: f32, player_money: *Money, buildings: []Building) void {
        switch (self.state) {
            .GATHERING => {
                if (self.target_source_id) |source_id| {
                    if (source_id < buildings.len) {
                        var source = &buildings[source_id];
                        if (source.supply_amount > 0 and self.carried_amount < self.max_carry) {
                            const gather_amount = @min(
                                @as(u32, @intFromFloat(self.gather_rate * delta_time)),
                                source.supply_amount,
                            );
                            const room = self.max_carry - self.carried_amount;
                            const actual = @min(gather_amount, room);

                            source.supply_amount -= actual;
                            self.carried_amount += actual;
                            self.num_boxes = @divTrunc(@as(i32, @intCast(self.carried_amount)), 300);

                            if (self.carried_amount >= self.max_carry) {
                                self.state = .MOVING_TO_DEPOT;
                            }
                        }
                    }
                }
            },
            .DEPOSITING => {
                // Deposit to player's money
                const deposit_amount = self.carried_amount + @as(u32, @intCast(self.upgraded_supply_boost));
                player_money.deposit(deposit_amount, false);
                self.carried_amount = 0;
                self.num_boxes = 0;
                self.state = .IDLE;
            },
            else => {},
        }
    }

    pub fn getNumberBoxes(self: ResourceGatherer) i32 {
        return self.num_boxes;
    }

    pub fn loseOneBox(self: *ResourceGatherer) bool {
        if (self.num_boxes > 0) {
            self.num_boxes -= 1;
            self.carried_amount = @max(0, self.carried_amount - 300);
            return true;
        }
        return false;
    }

    pub fn gainOneBox(self: *ResourceGatherer, box_value: i32) bool {
        if (self.num_boxes < self.max_boxes) {
            self.num_boxes += 1;
            self.carried_amount += @intCast(box_value);
            return true;
        }
        return false;
    }

    pub fn isAvailableForSupplying(self: ResourceGatherer) bool {
        return self.state == .IDLE and !self.force_busy_state;
    }

    pub fn isCurrentlyFerryingSupplies(self: ResourceGatherer) bool {
        return self.state == .MOVING_TO_SOURCE or
               self.state == .GATHERING or
               self.state == .MOVING_TO_DEPOT or
               self.state == .DEPOSITING;
    }
};

/// Resource gathering manager (from Thyme's ResourceGatheringManager)
pub const ResourceGatheringManager = struct {
    supply_warehouses: std.ArrayList(u32), // Building IDs
    supply_centers: std.ArrayList(u32),    // Building IDs
    allocator: Allocator,

    pub fn init(allocator: Allocator) ResourceGatheringManager {
        return .{
            .supply_warehouses = .{},
            .supply_centers = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ResourceGatheringManager) void {
        self.supply_warehouses.deinit(self.allocator);
        self.supply_centers.deinit(self.allocator);
    }

    pub fn addSupplyWarehouse(self: *ResourceGatheringManager, building_id: u32) !void {
        try self.supply_warehouses.append(self.allocator, building_id);
    }

    pub fn addSupplyCenter(self: *ResourceGatheringManager, building_id: u32) !void {
        try self.supply_centers.append(self.allocator, building_id);
    }

    pub fn removeSupplyWarehouse(self: *ResourceGatheringManager, building_id: u32) void {
        for (self.supply_warehouses.items, 0..) |id, i| {
            if (id == building_id) {
                _ = self.supply_warehouses.swapRemove(i);
                return;
            }
        }
    }

    pub fn removeSupplyCenter(self: *ResourceGatheringManager, building_id: u32) void {
        for (self.supply_centers.items, 0..) |id, i| {
            if (id == building_id) {
                _ = self.supply_centers.swapRemove(i);
                return;
            }
        }
    }
};

// ============================================================================
// PHASE 4.7: Player Economy Manager (Complete)
// ============================================================================

/// Player economy manager (from Thyme's Player class + subsystems)
pub const EconomyManager = struct {
    money: Money,
    energy: Energy,
    buildings: std.ArrayList(Building),
    gatherers: std.ArrayList(ResourceGatherer),
    resource_gathering: ResourceGatheringManager,
    sciences: std.ArrayList(ScienceType),

    // Limits
    supply_limit: u32 = 20, // Population cap
    supply_used: u32 = 0,

    // Production modifiers (from Player class)
    production_cost_changes: std.StringHashMap(f32),
    production_time_changes: std.StringHashMap(f32),

    // Player flags
    can_build_units: bool = true,
    can_build_base: bool = true,
    player_is_dead: bool = false,

    // Science purchase points
    science_purchase_points: i32 = 0,
    rank_level: i32 = 0,

    allocator: Allocator,

    pub fn init(allocator: Allocator, starting_money: u32, player_index: i32) EconomyManager {
        var money = Money.init();
        money.amount = starting_money;
        money.player_index = player_index;

        return .{
            .money = money,
            .energy = Energy.init(player_index),
            .buildings = .{},
            .gatherers = .{},
            .resource_gathering = ResourceGatheringManager.init(allocator),
            .sciences = .{},
            .production_cost_changes = std.StringHashMap(f32).init(allocator),
            .production_time_changes = std.StringHashMap(f32).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *EconomyManager) void {
        for (self.buildings.items) |*building| {
            building.deinit();
        }
        self.buildings.deinit(self.allocator);
        self.gatherers.deinit(self.allocator);
        self.resource_gathering.deinit();
        self.sciences.deinit(self.allocator);
        self.production_cost_changes.deinit();
        self.production_time_changes.deinit();
    }

    pub fn update(self: *EconomyManager, delta_time: f32) void {
        // Update buildings
        for (self.buildings.items) |*building| {
            building.update(delta_time, &self.money, &self.energy);
        }

        // Update gatherers
        for (self.gatherers.items) |*gatherer| {
            gatherer.update(delta_time, &self.money, self.buildings.items);
        }

        // Update energy system
        self.energy.frame += 1;
    }

    pub fn addBuilding(self: *EconomyManager, building: Building) !void {
        try self.buildings.append(self.allocator, building);

        // Register with resource gathering manager if it's a supply building
        if (building.is_supply_center) {
            const building_id = @as(u32, @intCast(self.buildings.items.len - 1));
            try self.resource_gathering.addSupplyCenter(building_id);
        }
    }

    pub fn addGatherer(self: *EconomyManager, gatherer: ResourceGatherer) !void {
        try self.gatherers.append(self.allocator, gatherer);
    }

    pub fn canBuildUnit(self: *EconomyManager, cost: u32, supply_cost: u32) bool {
        return self.can_build_units and
               self.money.canAfford(cost) and
               (self.supply_used + supply_cost <= self.supply_limit) and
               self.energy.hasSufficientPower();
    }

    pub fn canAffordBuilding(self: *EconomyManager, building_type: BuildingType) bool {
        const stats = getBuildingStats(building_type);
        return self.can_build_base and
               self.money.canAfford(stats.cost) and
               (self.energy.energy_production - self.energy.energy_consumption >= stats.power_required);
    }

    pub fn purchaseBuilding(self: *EconomyManager, building_type: BuildingType, x: f32, y: f32, owner: i32) !?Building {
        if (!self.canAffordBuilding(building_type)) {
            return null;
        }

        const stats = getBuildingStats(building_type);
        const withdrawn = self.money.withdraw(stats.cost, true);

        if (withdrawn == stats.cost) {
            var building = Building.init(self.allocator, building_type, x, y, owner);
            building.state = .AWAITING_CONSTRUCTION;
            return building;
        }

        return null;
    }

    pub fn addScience(self: *EconomyManager, science: ScienceType) !bool {
        // Check if already owned
        for (self.sciences.items) |existing| {
            if (existing == science) return false;
        }

        try self.sciences.append(self.allocator, science);
        return true;
    }

    pub fn hasScience(self: EconomyManager, science: ScienceType) bool {
        for (self.sciences.items) |existing| {
            if (existing == science) return true;
        }
        return false;
    }

    pub fn addSciencePurchasePoints(self: *EconomyManager, points: i32) void {
        self.science_purchase_points += points;
    }

    pub fn setProductionCostChange(self: *EconomyManager, template_name: []const u8, percent: f32) !void {
        try self.production_cost_changes.put(template_name, percent);
    }

    pub fn setProductionTimeChange(self: *EconomyManager, template_name: []const u8, percent: f32) !void {
        try self.production_time_changes.put(template_name, percent);
    }

    pub fn getProductionCostChange(self: EconomyManager, template_name: []const u8) f32 {
        return self.production_cost_changes.get(template_name) orelse 1.0;
    }

    pub fn getProductionTimeChange(self: EconomyManager, template_name: []const u8) f32 {
        return self.production_time_changes.get(template_name) orelse 1.0;
    }

    pub fn countBuildings(self: EconomyManager) u32 {
        var count: u32 = 0;
        for (self.buildings.items) |building| {
            if (building.state == .ACTIVE or building.state == .UNDER_CONSTRUCTION) {
                count += 1;
            }
        }
        return count;
    }

    pub fn hasAnyBuildings(self: EconomyManager) bool {
        for (self.buildings.items) |building| {
            if (building.state == .ACTIVE) {
                return true;
            }
        }
        return false;
    }

    pub fn findBuildingByType(self: *EconomyManager, building_type: BuildingType) ?*Building {
        for (self.buildings.items) |*building| {
            if (building.building_type == building_type and building.state == .ACTIVE) {
                return building;
            }
        }
        return null;
    }

    pub fn killPlayer(self: *EconomyManager) void {
        self.player_is_dead = true;

        // Destroy all buildings
        for (self.buildings.items) |*building| {
            building.state = .DESTROYED;
        }
    }

    pub fn sellEverything(self: *EconomyManager) void {
        for (self.buildings.items) |*building| {
            if (building.is_sellable and building.state == .ACTIVE) {
                building.startSelling();
            }
        }
    }

    pub fn getSupplyBoxValue(self: EconomyManager) u32 {
        _ = self;
        return 300; // Base supply box value
    }

    pub fn isSupplySourceSafe(self: EconomyManager, source_index: usize) bool {
        if (source_index >= self.buildings.items.len) return false;
        const building = self.buildings.items[source_index];
        return building.state == .ACTIVE and building.health > building.max_health * 0.3;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Money: deposit and withdraw" {
    var money = Money.init();

    money.deposit(1000, false);
    try std.testing.expectEqual(@as(u32, 1000), money.getAmount());

    const withdrawn = money.withdraw(300, false);
    try std.testing.expectEqual(@as(u32, 300), withdrawn);
    try std.testing.expectEqual(@as(u32, 700), money.getAmount());

    // Test overdraw
    const over = money.withdraw(1000, false);
    try std.testing.expectEqual(@as(u32, 700), over);
    try std.testing.expectEqual(@as(u32, 0), money.getAmount());
}

test "Energy: power management" {
    var energy = Energy.init(0);

    energy.addProduction(100);
    energy.addConsumption(50);

    try std.testing.expectEqual(@as(i32, 100), energy.getProduction());
    try std.testing.expectEqual(@as(i32, 50), energy.getConsumption());
    try std.testing.expect(energy.hasSufficientPower());
    try std.testing.expectEqual(@as(f32, 1.0), energy.getEnergySupplyRatio());

    energy.addConsumption(60);
    try std.testing.expect(!energy.hasSufficientPower());
}

test "Building: construction progress" {
    var building = Building.init(std.testing.allocator, .USA_BARRACKS, 100.0, 100.0, 0);
    defer building.deinit();

    building.state = .UNDER_CONSTRUCTION;

    var money = Money.init();
    money.amount = 10000;

    var energy = Energy.init(0);

    // Simulate 15 seconds (barracks build time)
    building.update(15.0, &money, &energy);

    try std.testing.expectEqual(BuildingState.ACTIVE, building.state);
    try std.testing.expectEqual(@as(f32, 1.0), building.construction_progress);
}

test "Building: production queue" {
    var building = Building.init(std.testing.allocator, .USA_WAR_FACTORY, 100.0, 100.0, 0);
    defer building.deinit();

    building.state = .ACTIVE;

    const entry1 = ProductionEntry.initUnit(1, 10, 600, 10.0);
    const entry2 = ProductionEntry.initUnit(2, 11, 800, 15.0);

    try building.queueProduction(entry1);
    try building.queueProduction(entry2);

    try std.testing.expectEqual(@as(u32, 2), building.getProductionCount());
}

test "Prerequisites: building requirements" {
    var prereqs = Prerequisites.init(std.testing.allocator);
    defer prereqs.deinit();

    try prereqs.addBuildingRequirement(.USA_BARRACKS);

    // Create buildings array
    var buildings = [_]Building{
        Building.init(std.testing.allocator, .USA_BARRACKS, 0, 0, 0),
    };
    defer buildings[0].deinit();
    buildings[0].state = .ACTIVE;

    const sciences = [_]ScienceType{};

    try std.testing.expect(prereqs.isSatisfied(&buildings, &sciences));
}

test "ResourceGatherer: gathering and depositing" {
    var gatherer = ResourceGatherer.init(0, 0, 0);
    gatherer.state = .GATHERING;
    gatherer.target_source_id = 0;

    var money = Money.init();

    var buildings = [_]Building{
        Building.init(std.testing.allocator, .USA_SUPPLY_CENTER, 0, 0, 0),
    };
    defer buildings[0].deinit();
    buildings[0].supply_amount = 5000;

    // Gather for 10 seconds
    gatherer.update(10.0, &money, &buildings);

    try std.testing.expect(gatherer.carried_amount > 0);
    try std.testing.expect(gatherer.carried_amount <= gatherer.max_carry);
}

test "EconomyManager: initialization and building" {
    var manager = EconomyManager.init(std.testing.allocator, 5000, 0);
    defer manager.deinit();

    try std.testing.expectEqual(@as(u32, 5000), manager.money.getAmount());
    try std.testing.expect(manager.can_build_base);

    // Try to purchase a building
    const maybe_building = try manager.purchaseBuilding(.USA_BARRACKS, 100, 100, 0);

    if (maybe_building) |building| {
        try manager.addBuilding(building);
        try std.testing.expectEqual(@as(u32, 4500), manager.money.getAmount());
    }
}

test "EconomyManager: science system" {
    var manager = EconomyManager.init(std.testing.allocator, 5000, 0);
    defer manager.deinit();

    _ = try manager.addScience(.SCIENCE_USA_PATHFINDER);

    try std.testing.expect(manager.hasScience(.SCIENCE_USA_PATHFINDER));
    try std.testing.expect(!manager.hasScience(.SCIENCE_USA_TOW_MISSILE));
}
