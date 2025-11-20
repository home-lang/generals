// ============================================================================
// Structures/Buildings System - Complete Implementation
// Based on Thyme's structure architecture
// ============================================================================
//
// Buildings provide base construction, production, defenses, and superweapons.
// Key mechanics:
// - Construction (dozer placement, build time, cost)
// - Production queues (units, upgrades)
// - Power management (supply/demand)
// - Defenses (fire weapons, garrison)
// - Superweapons (timers, targeting)
// - Damage states (pristine → damaged → rubble)
//
// References:
// - Thyme/src/game/logic/object/structure.h
// - Thyme/src/game/logic/object/productionupdate.h
// - Thyme/src/game/logic/object/armedstructure.h

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Vec3 = math.Vec3(f32);

// ============================================================================
// Phase 1: Building Types (from C&C Generals)
// ============================================================================

pub const BuildingType = enum(u32) {
    // USA Buildings
    USA_COMMAND_CENTER = 0,
    USA_POWER_PLANT = 1,
    USA_COLD_FUSION_REACTOR = 2,
    USA_SUPPLY_CENTER = 3,
    USA_BARRACKS = 4,
    USA_WAR_FACTORY = 5,
    USA_AIRFIELD = 6,
    USA_STRATEGY_CENTER = 7,
    USA_PATRIOT = 8,
    USA_FIRE_BASE = 9,
    USA_PARTICLE_CANNON = 10,

    // China Buildings
    CHINA_COMMAND_CENTER = 20,
    CHINA_POWER_PLANT = 21,
    CHINA_NUCLEAR_REACTOR = 22,
    CHINA_SUPPLY_CENTER = 23,
    CHINA_BARRACKS = 24,
    CHINA_WAR_FACTORY = 25,
    CHINA_AIRFIELD = 26,
    CHINA_PROPAGANDA_CENTER = 27,
    CHINA_GATLING_CANNON = 28,
    CHINA_BUNKER = 29,
    CHINA_NUCLEAR_MISSILE = 30,

    // GLA Buildings
    GLA_COMMAND_CENTER = 40,
    GLA_SUPPLY_STASH = 41,
    GLA_BARRACKS = 42,
    GLA_ARMS_DEALER = 43,
    GLA_BLACK_MARKET = 44,
    GLA_PALACE = 45,
    GLA_STINGER_SITE = 46,
    GLA_TUNNEL_NETWORK = 47,
    GLA_SCUD_STORM = 48,

    // Neutral
    TECH_BUILDING = 60,
    OIL_DERRICK = 61,
    BRIDGE_REPAIR_HUT = 62,

    COUNT = 100,
};

/// Get building name for display
pub fn getBuildingName(building_type: BuildingType) []const u8 {
    return switch (building_type) {
        .USA_COMMAND_CENTER => "Command Center",
        .USA_POWER_PLANT => "Power Plant",
        .USA_COLD_FUSION_REACTOR => "Cold Fusion Reactor",
        .USA_SUPPLY_CENTER => "Supply Center",
        .USA_BARRACKS => "Barracks",
        .USA_WAR_FACTORY => "War Factory",
        .USA_PARTICLE_CANNON => "Particle Cannon",
        .CHINA_NUCLEAR_MISSILE => "Nuclear Missile",
        .GLA_SCUD_STORM => "SCUD Storm",
        else => "Building",
    };
}

// ============================================================================
// Phase 2: Building States
// ============================================================================

pub const BuildingState = enum(u8) {
    PLACEMENT,        // Being placed by dozer
    CONSTRUCTING,     // Under construction
    ACTIVE,           // Fully operational
    DAMAGED,          // Damaged but functional
    SEVERELY_DAMAGED, // Critical damage
    DISABLED,         // Temporarily disabled (power off, EMP)
    SELLING,          // Being sold
    DESTROYED,        // Dead/rubble
};

pub const DamageState = enum(u8) {
    PRISTINE = 0,
    DAMAGED = 1,
    REALLY_DAMAGED = 2,
    RUBBLE = 3,
};

// ============================================================================
// Phase 3: Production Queue Entry
// ============================================================================

pub const ProductionType = enum(u8) {
    UNIT,
    UPGRADE,
    SPECIAL_POWER,
};

pub const ProductionEntry = struct {
    production_type: ProductionType,
    object_id: u32,        // Unit type, upgrade ID, etc.
    progress: f32,         // 0.0 to 1.0
    time_remaining: f32,   // Seconds
    total_time: f32,       // Total build time
    cost: u32,             // Cost in money
    can_cancel: bool,

    pub fn init(
        production_type: ProductionType,
        object_id: u32,
        build_time: f32,
        cost: u32,
    ) ProductionEntry {
        return .{
            .production_type = production_type,
            .object_id = object_id,
            .progress = 0.0,
            .time_remaining = build_time,
            .total_time = build_time,
            .cost = cost,
            .can_cancel = true,
        };
    }

    pub fn update(self: *ProductionEntry, dt: f32) bool {
        self.time_remaining -= dt;
        self.progress = 1.0 - (self.time_remaining / self.total_time);

        return self.time_remaining <= 0.0;
    }

    pub fn isComplete(self: ProductionEntry) bool {
        return self.progress >= 1.0;
    }
};

// ============================================================================
// Phase 4: Building Template
// ============================================================================

pub const BuildingTemplate = struct {
    name: []const u8,
    building_type: BuildingType,
    display_name: []const u8,

    // Cost and build time
    cost: u32,
    build_time: f32,          // Seconds
    refund_percent: f32,      // 0.5 = 50% refund on sell

    // Physical properties
    footprint_width: u32,     // Grid cells
    footprint_height: u32,
    max_health: f32,

    // Power
    provides_power: i32,      // Negative = consumes
    requires_power: bool,

    // Production
    can_produce_units: bool,
    can_produce_upgrades: bool,
    production_queue_size: u32,

    // Defense
    is_defensive: bool,
    weapon_range: f32,
    weapon_damage: f32,

    // Prerequisites
    required_building: ?BuildingType,
    required_upgrade: ?u32,

    // Special
    is_superweapon: bool,
    superweapon_recharge_time: f32,

    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        name: []const u8,
        building_type: BuildingType,
        cost: u32,
        build_time: f32,
    ) !BuildingTemplate {
        return BuildingTemplate{
            .name = try allocator.dupe(u8, name),
            .building_type = building_type,
            .display_name = try allocator.dupe(u8, getBuildingName(building_type)),
            .cost = cost,
            .build_time = build_time,
            .refund_percent = 0.5,
            .footprint_width = 2,
            .footprint_height = 2,
            .max_health = 1000.0,
            .provides_power = 0,
            .requires_power = false,
            .can_produce_units = false,
            .can_produce_upgrades = false,
            .production_queue_size = 0,
            .is_defensive = false,
            .weapon_range = 0.0,
            .weapon_damage = 0.0,
            .required_building = null,
            .required_upgrade = null,
            .is_superweapon = false,
            .superweapon_recharge_time = 0.0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BuildingTemplate) void {
        self.allocator.free(self.name);
        self.allocator.free(self.display_name);
    }
};

// ============================================================================
// Phase 5: Building Instance
// ============================================================================

pub const Building = struct {
    id: u32,
    template: *const BuildingTemplate,
    player_index: i32,
    team: u8,

    // State
    state: BuildingState,
    damage_state: DamageState,
    health: f32,
    construction_progress: f32,

    // Position
    position: Vec2,
    angle: f32,

    // Production
    production_queue: std.ArrayList(ProductionEntry),
    current_production: ?ProductionEntry,
    production_paused: bool,

    // Power
    is_powered: bool,
    power_consumption: i32,

    // Superweapon
    superweapon_ready: bool,
    superweapon_timer: f32,

    // Garrison (for bunkers, etc.)
    garrisoned_units: std.ArrayList(u32),
    max_garrison: u32,

    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        id: u32,
        template: *const BuildingTemplate,
        player_index: i32,
        team: u8,
        position: Vec2,
    ) Building {
        return .{
            .id = id,
            .template = template,
            .player_index = player_index,
            .team = team,
            .state = .CONSTRUCTING,
            .damage_state = .PRISTINE,
            .health = template.max_health,
            .construction_progress = 0.0,
            .position = position,
            .angle = 0.0,
            .production_queue = std.ArrayList(ProductionEntry){},
            .current_production = null,
            .production_paused = false,
            .is_powered = true,
            .power_consumption = if (template.provides_power < 0) @abs(template.provides_power) else 0,
            .superweapon_ready = false,
            .superweapon_timer = 0.0,
            .garrisoned_units = std.ArrayList(u32){},
            .max_garrison = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Building) void {
        self.production_queue.deinit(self.allocator);
        self.garrisoned_units.deinit(self.allocator);
    }

    /// Update building
    pub fn update(self: *Building, dt: f32) void {
        switch (self.state) {
            .CONSTRUCTING => self.updateConstruction(dt),
            .ACTIVE => {
                self.updateProduction(dt);
                if (self.template.is_superweapon) {
                    self.updateSuperweapon(dt);
                }
            },
            .SELLING => {
                // TODO: Selling animation
                self.state = .DESTROYED;
            },
            else => {},
        }

        self.updateDamageState();
    }

    fn updateConstruction(self: *Building, dt: f32) void {
        if (self.template.build_time <= 0.0) {
            self.construction_progress = 1.0;
        } else {
            const rate = dt / self.template.build_time;
            self.construction_progress += rate;
        }

        if (self.construction_progress >= 1.0) {
            self.construction_progress = 1.0;
            self.state = .ACTIVE;
        }
    }

    fn updateProduction(self: *Building, dt: f32) void {
        if (!self.is_powered or self.production_paused) return;

        // Process current production
        if (self.current_production) |*prod| {
            if (prod.update(dt)) {
                // Production complete
                // TODO: Spawn unit or apply upgrade
                self.current_production = null;
            }
        }

        // Start next production
        if (self.current_production == null and self.production_queue.items.len > 0) {
            self.current_production = self.production_queue.orderedRemove(0);
        }
    }

    fn updateSuperweapon(self: *Building, dt: f32) void {
        if (self.superweapon_ready) return;

        self.superweapon_timer += dt;
        if (self.superweapon_timer >= self.template.superweapon_recharge_time) {
            self.superweapon_ready = true;
        }
    }

    fn updateDamageState(self: *Building) void {
        const health_percent = self.health / self.template.max_health;

        if (health_percent <= 0.0) {
            self.damage_state = .RUBBLE;
            self.state = .DESTROYED;
        } else if (health_percent < 0.25) {
            self.damage_state = .REALLY_DAMAGED;
            self.state = .SEVERELY_DAMAGED;
        } else if (health_percent < 0.5) {
            self.damage_state = .DAMAGED;
            self.state = .DAMAGED;
        } else {
            self.damage_state = .PRISTINE;
            if (self.state == .DAMAGED or self.state == .SEVERELY_DAMAGED) {
                self.state = .ACTIVE;
            }
        }
    }

    /// Queue production
    pub fn queueProduction(self: *Building, entry: ProductionEntry) !void {
        if (self.production_queue.items.len >= self.template.production_queue_size) {
            return error.QueueFull;
        }
        try self.production_queue.append(self.allocator, entry);
    }

    /// Cancel production
    pub fn cancelProduction(self: *Building, index: usize) ?ProductionEntry {
        if (index >= self.production_queue.items.len) return null;
        return self.production_queue.orderedRemove(index);
    }

    /// Take damage
    pub fn takeDamage(self: *Building, damage: f32) void {
        self.health -= damage;
        if (self.health < 0.0) {
            self.health = 0.0;
            self.state = .DESTROYED;
        }
    }

    /// Repair
    pub fn repair(self: *Building, amount: f32) void {
        self.health += amount;
        if (self.health > self.template.max_health) {
            self.health = self.template.max_health;
        }
    }

    /// Sell building
    pub fn sell(self: *Building) u32 {
        const refund = @as(u32, @intFromFloat(@as(f32, @floatFromInt(self.template.cost)) * self.template.refund_percent));
        self.state = .SELLING;
        return refund;
    }

    /// Fire superweapon
    pub fn fireSuperweapon(self: *Building) bool {
        if (!self.superweapon_ready) return false;

        self.superweapon_ready = false;
        self.superweapon_timer = 0.0;
        return true;
    }

    /// Garrison unit
    pub fn garrisonUnit(self: *Building, unit_id: u32) !void {
        if (self.garrisoned_units.items.len >= self.max_garrison) {
            return error.GarrisonFull;
        }
        try self.garrisoned_units.append(self.allocator, unit_id);
    }

    /// Ungarrison unit
    pub fn ungarrisonUnit(self: *Building, unit_id: u32) bool {
        for (self.garrisoned_units.items, 0..) |id, i| {
            if (id == unit_id) {
                _ = self.garrisoned_units.swapRemove(i);
                return true;
            }
        }
        return false;
    }

    /// Check if construction is complete
    pub fn isConstructionComplete(self: Building) bool {
        return self.state != .CONSTRUCTING and self.state != .PLACEMENT;
    }

    /// Check if operational
    pub fn isOperational(self: Building) bool {
        return self.state == .ACTIVE and self.is_powered;
    }

    /// Get production progress
    pub fn getProductionProgress(self: Building) f32 {
        if (self.current_production) |prod| {
            return prod.progress;
        }
        return 0.0;
    }
};

// ============================================================================
// Phase 6: Building Manager
// ============================================================================

pub const BuildingManager = struct {
    templates: std.ArrayList(BuildingTemplate),
    buildings: std.ArrayList(Building),
    next_id: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator) BuildingManager {
        return .{
            .templates = std.ArrayList(BuildingTemplate){},
            .buildings = std.ArrayList(Building){},
            .next_id = 1,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BuildingManager) void {
        for (self.templates.items) |*template| {
            template.deinit();
        }
        self.templates.deinit(self.allocator);

        for (self.buildings.items) |*building| {
            building.deinit();
        }
        self.buildings.deinit(self.allocator);
    }

    /// Add template
    pub fn addTemplate(self: *BuildingManager, template: BuildingTemplate) !void {
        try self.templates.append(self.allocator, template);
    }

    /// Find template by type
    pub fn findTemplate(self: *BuildingManager, building_type: BuildingType) ?*const BuildingTemplate {
        for (self.templates.items) |*template| {
            if (template.building_type == building_type) {
                return template;
            }
        }
        return null;
    }

    /// Create building
    pub fn createBuilding(
        self: *BuildingManager,
        building_type: BuildingType,
        player_index: i32,
        team: u8,
        position: Vec2,
    ) !u32 {
        const template = self.findTemplate(building_type) orelse return error.TemplateNotFound;

        const id = self.next_id;
        self.next_id += 1;

        const building = Building.init(self.allocator, id, template, player_index, team, position);
        try self.buildings.append(self.allocator, building);

        return id;
    }

    /// Get building by ID
    pub fn getBuilding(self: *BuildingManager, id: u32) ?*Building {
        for (self.buildings.items) |*building| {
            if (building.id == id) {
                return building;
            }
        }
        return null;
    }

    /// Remove building
    pub fn removeBuilding(self: *BuildingManager, id: u32) bool {
        for (self.buildings.items, 0..) |*building, i| {
            if (building.id == id) {
                building.deinit();
                _ = self.buildings.swapRemove(i);
                return true;
            }
        }
        return false;
    }

    /// Update all buildings
    pub fn update(self: *BuildingManager, dt: f32) void {
        var i: usize = 0;
        while (i < self.buildings.items.len) {
            var building = &self.buildings.items[i];
            building.update(dt);

            if (building.state == .DESTROYED) {
                building.deinit();
                _ = self.buildings.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    /// Initialize default building templates
    pub fn initializeDefaults(self: *BuildingManager) !void {
        // USA Buildings
        var usa_cc = try BuildingTemplate.init(
            self.allocator, "AmericaCommandCenter", .USA_COMMAND_CENTER, 2000, 20.0
        );
        usa_cc.footprint_width = 3;
        usa_cc.footprint_height = 3;
        usa_cc.max_health = 5000.0;
        try self.addTemplate(usa_cc);

        var usa_barracks = try BuildingTemplate.init(
            self.allocator, "AmericaBarracks", .USA_BARRACKS, 500, 10.0
        );
        usa_barracks.can_produce_units = true;
        usa_barracks.production_queue_size = 5;
        usa_barracks.requires_power = true;
        try self.addTemplate(usa_barracks);

        var usa_particle = try BuildingTemplate.init(
            self.allocator, "AmericaParticleCannon", .USA_PARTICLE_CANNON, 5000, 60.0
        );
        usa_particle.is_superweapon = true;
        usa_particle.superweapon_recharge_time = 360.0;  // 6 minutes
        usa_particle.footprint_width = 3;
        usa_particle.footprint_height = 3;
        try self.addTemplate(usa_particle);

        // China Buildings
        var china_nuke = try BuildingTemplate.init(
            self.allocator, "ChinaNuclearMissile", .CHINA_NUCLEAR_MISSILE, 5000, 60.0
        );
        china_nuke.is_superweapon = true;
        china_nuke.superweapon_recharge_time = 360.0;
        try self.addTemplate(china_nuke);

        // GLA Buildings
        var gla_scud = try BuildingTemplate.init(
            self.allocator, "GLAScudStorm", .GLA_SCUD_STORM, 5000, 60.0
        );
        gla_scud.is_superweapon = true;
        gla_scud.superweapon_recharge_time = 360.0;
        try self.addTemplate(gla_scud);
    }

    /// Get player's buildings
    pub fn getPlayerBuildings(self: *BuildingManager, player_index: i32) std.ArrayList(*Building) {
        var result = std.ArrayList(*Building){};

        for (self.buildings.items) |*building| {
            if (building.player_index == player_index) {
                result.append(self.allocator, building) catch {};
            }
        }

        return result;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "BuildingTemplate: initialization" {
    const allocator = std.testing.allocator;

    const template = try BuildingTemplate.init(
        allocator, "TestBuilding", .USA_COMMAND_CENTER, 1000, 20.0
    );
    var template_mut = template;
    defer template_mut.deinit();

    try std.testing.expectEqualStrings("TestBuilding", template.name);
    try std.testing.expectEqual(@as(u32, 1000), template.cost);
    try std.testing.expectEqual(@as(f32, 20.0), template.build_time);
}

test "Building: construction" {
    const allocator = std.testing.allocator;

    const template = try BuildingTemplate.init(
        allocator, "TestBuilding", .USA_BARRACKS, 500, 10.0
    );
    var template_mut = template;
    defer template_mut.deinit();

    var building = Building.init(allocator, 1, &template, 0, 0, Vec2.init(100.0, 100.0));
    defer building.deinit();

    try std.testing.expectEqual(BuildingState.CONSTRUCTING, building.state);
    try std.testing.expectEqual(@as(f32, 0.0), building.construction_progress);

    // Update for 5 seconds (50% complete)
    building.update(5.0);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), building.construction_progress, 0.01);
    try std.testing.expectEqual(BuildingState.CONSTRUCTING, building.state);

    // Complete construction
    building.update(5.0);
    try std.testing.expectEqual(@as(f32, 1.0), building.construction_progress);
    try std.testing.expectEqual(BuildingState.ACTIVE, building.state);
}

test "Building: production queue" {
    const allocator = std.testing.allocator;

    var template = try BuildingTemplate.init(
        allocator, "TestBarracks", .USA_BARRACKS, 500, 10.0
    );
    template.can_produce_units = true;
    template.production_queue_size = 5;
    var template_mut = template;
    defer template_mut.deinit();

    var building = Building.init(allocator, 1, &template, 0, 0, Vec2.init(0.0, 0.0));
    defer building.deinit();

    // Complete construction first
    building.state = .ACTIVE;
    building.construction_progress = 1.0;

    // Queue production
    const entry = ProductionEntry.init(.UNIT, 101, 15.0, 300);
    try building.queueProduction(entry);

    try std.testing.expectEqual(@as(usize, 1), building.production_queue.items.len);

    // Update to start production
    building.update(0.1);
    try std.testing.expect(building.current_production != null);
    try std.testing.expectEqual(@as(usize, 0), building.production_queue.items.len);

    // Update production
    building.update(7.5);  // 50%
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), building.getProductionProgress(), 0.01);

    // Complete production
    building.update(7.5);
    try std.testing.expect(building.current_production == null);
}

test "Building: damage and repair" {
    const allocator = std.testing.allocator;

    const template = try BuildingTemplate.init(
        allocator, "TestBuilding", .USA_COMMAND_CENTER, 1000, 10.0
    );
    var template_mut = template;
    defer template_mut.deinit();

    var building = Building.init(allocator, 1, &template, 0, 0, Vec2.init(0.0, 0.0));
    defer building.deinit();

    building.state = .ACTIVE;
    const initial_health = building.health;

    // Take damage
    building.takeDamage(300.0);
    try std.testing.expect(building.health < initial_health);

    // Repair
    building.repair(100.0);
    try std.testing.expect(building.health > initial_health - 300.0);

    // Destroy
    building.takeDamage(10000.0);
    try std.testing.expectEqual(BuildingState.DESTROYED, building.state);
}

test "Building: sell" {
    const allocator = std.testing.allocator;

    const template = try BuildingTemplate.init(
        allocator, "TestBuilding", .USA_BARRACKS, 1000, 10.0
    );
    var template_mut = template;
    defer template_mut.deinit();

    var building = Building.init(allocator, 1, &template, 0, 0, Vec2.init(0.0, 0.0));
    defer building.deinit();

    const refund = building.sell();
    try std.testing.expectEqual(@as(u32, 500), refund);  // 50% refund
    try std.testing.expectEqual(BuildingState.SELLING, building.state);
}

test "Building: superweapon" {
    const allocator = std.testing.allocator;

    var template = try BuildingTemplate.init(
        allocator, "ParticleCannon", .USA_PARTICLE_CANNON, 5000, 60.0
    );
    template.is_superweapon = true;
    template.superweapon_recharge_time = 30.0;
    var template_mut = template;
    defer template_mut.deinit();

    var building = Building.init(allocator, 1, &template, 0, 0, Vec2.init(0.0, 0.0));
    defer building.deinit();

    building.state = .ACTIVE;

    // Not ready initially
    try std.testing.expect(!building.superweapon_ready);

    // Charge halfway
    building.update(15.0);
    try std.testing.expect(!building.superweapon_ready);

    // Fully charged
    building.update(15.0);
    try std.testing.expect(building.superweapon_ready);

    // Fire
    const fired = building.fireSuperweapon();
    try std.testing.expect(fired);
    try std.testing.expect(!building.superweapon_ready);
}

test "BuildingManager: creation and lookup" {
    const allocator = std.testing.allocator;

    var manager = BuildingManager.init(allocator);
    defer manager.deinit();

    try manager.initializeDefaults();

    const template = manager.findTemplate(.USA_BARRACKS);
    try std.testing.expect(template != null);

    const building_id = try manager.createBuilding(.USA_BARRACKS, 0, 0, Vec2.init(100.0, 100.0));
    const building = manager.getBuilding(building_id);

    try std.testing.expect(building != null);
    try std.testing.expectEqual(building_id, building.?.id);
}

test "getBuildingName: names" {
    try std.testing.expectEqualStrings("Command Center", getBuildingName(.USA_COMMAND_CENTER));
    try std.testing.expectEqualStrings("Particle Cannon", getBuildingName(.USA_PARTICLE_CANNON));
    try std.testing.expectEqualStrings("SCUD Storm", getBuildingName(.GLA_SCUD_STORM));
}
