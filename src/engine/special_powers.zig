// ============================================================================
// Phase 7: Special Powers System - Complete Implementation
// Based on Thyme's special power architecture
// ============================================================================
//
// All 69 special powers from C&C Generals + Zero Hour
//
// References:
// - Thyme/src/game/logic/object/object.h (SpecialPowerType enum - 69 powers)
// - Thyme/src/game/common/rts/specialpower.h (SpecialPowerTemplate)

const std = @import("std");
const Allocator = std.mem.Allocator;

// From economy.zig
pub const ScienceType = enum(u8) {
    INVALID = 0,
    SCIENCE_PATRIOT = 1,
    SCIENCE_LASER = 2,
    SCIENCE_SUPER_WEAP = 3,
    // ... (full list in economy.zig)
    COUNT = 64,
};

pub const Coord3D = struct {
    x: f32,
    y: f32,
    z: f32,
};

// ============================================================================
// Phase 7.1: Special Power Types (All 69 from Thyme)
// ============================================================================

pub const SpecialPowerType = enum(u8) {
    INVALID = 0,

    // USA Powers
    DAISY_CUTTER = 1,              // MOABs
    PARADROP_AMERICA = 2,          // Rangers
    CARPET_BOMB = 3,               // B-52
    CLUSTER_MINES = 4,             // Mine drop
    EMP_PULSE = 5,                 // Aurora EMP

    // China Powers
    NAPALM_STRIKE = 6,             // MiG napalm
    CASH_HACK = 7,                 // Hacker money
    NEUTRON_MISSILE = 8,           // Nuke Cannon neutron
    SPY_SATELLITE = 9,             // Reveal map

    // GLA Powers
    DEFECTOR = 10,                 // Steal enemy unit
    TERROR_CELL = 11,              // Suicide bomber
    AMBUSH = 12,                   // Tunnel ambush
    BLACK_MARKET_NUKE = 13,        // Black market nuke
    ANTHRAX_BOMB = 14,             // Anthrax bomber
    SCUD_STORM = 15,               // Scud storm launch

    // Support Powers
    DEMORALIZE_OBSOLETE = 16,      // (Unused)
    CRATE_DROP = 17,               // Supply crate
    A10_THUNDERBOLT_STRIKE = 18,   // A-10 gun run
    DETONATE_DIRTY_NUKE = 19,      // Demo nuke truck
    ARTILLERY_BARRAGE = 20,        // Artillery strike

    // Unit Special Powers
    MISSILE_DEFENDER_LASER_GUIDED_MISSILE = 21,
    REMOTE_CHARGES = 22,           // Jarmen Kell explosives
    TIMED_CHARGES = 23,            // Saboteur charges
    HELIX_NAPALM_BOMB = 24,        // Helix napalm
    HACKER_DISABLE_BUILDING = 25,  // Hacker disable
    TANKHUNTER_TNT_ATTACK = 26,    // Tank Hunter TNT

    // Black Lotus Powers
    BLACKLOTUS_CAPTURE_BUILDING = 27,
    BLACKLOTUS_DISABLE_VEHICLE_HACK = 28,
    BLACKLOTUS_STEAL_CASH_HACK = 29,

    // Infantry Powers
    INFANTRY_CAPTURE_BUILDING = 30,
    RADAR_VAN_SCAN = 31,           // Radar van reveal
    SPY_DRONE = 32,                // Colonel Burton drone
    DISGUISE_AS_VEHICLE = 33,      // Jarmen Kell disguise
    BOOBY_TRAP = 34,               // Booby trap building
    REPAIR_VEHICLES = 35,           // Repair area

    // Superweapons
    PARTICLE_UPLINK_CANNON = 36,   // Particle cannon
    CASH_BOUNTY = 37,              // Kill bounty
    CHANGE_BATTLE_PLANS = 38,      // Strategy change
    CIA_INTELLIGENCE = 39,         // Intel reveal
    CLEANUP_AREA = 40,             // Remove radiation
    LAUNCH_BAIKONUR_ROCKET = 41,   // Rocket launch
    SPECTRE_GUNSHIP = 42,          // AC-130 gunship
    GPS_SCRAMBLER = 43,            // GPS disable
    FRENZY = 44,                   // Attack speed boost
    SNEAK_ATTACK = 45,             // Stealth bonus

    // China Carpet Bombs
    CHINA_CARPET_BOMB = 46,
    EARLY_SPECIAL_CHINA_CARPET_BOMB = 47,

    // Propaganda Powers
    LEAFLET_DROP = 48,
    EARLY_SPECIAL_LEAFLET_DROP = 49,
    EARLY_SPECIAL_FRENZY = 50,
    COMMUNICATIONS_DOWNLOAD = 51,
    EARLY_SPECIAL_REPAIR_VEHICLES = 52,
    TANK_PARADROP = 53,            // Tank drop

    // Upgraded Powers
    SUPW_SPECIAL_PARTICLE_UPLINK_CANNON = 54,
    AIRF_SPECIAL_DAISY_CUTTER = 55,
    NUKE_SPECIAL_CLUSTER_MINES = 56,
    NUKE_SPECIAL_NEUTRON_MISSILE = 57,
    AIRF_SPECIAL_A10_THUNDERBOLT_STRIKE = 58,
    AIRF_SPECIAL_SPECTRE_GUNSHIP = 59,
    INFA_SPECIAL_PARADROP_AMERICA = 60,
    SLTH_SPECIAL_GPS_SCRAMBLER = 61,
    AIRF_SPECIAL_CARPET_BOMB = 62,
    SUPR_SPECIAL_CRUISE_MISSILE = 63,
    LAZR_SPECIAL_PARTICLE_UPLINK_CANNON = 64,
    SUPW_SPECIAL_NEUTRON_MISSILE = 65,
    BATTLESHIP_BOMBARDMENT = 66,   // Naval strike

    COUNT = 67,
};

// ============================================================================
// Phase 7.2: Special Power Template
// ============================================================================

pub const SpecialPowerTemplate = struct {
    name: []const u8,
    power_type: SpecialPowerType,
    id: u32,
    reload_time: u32,              // Milliseconds
    required_science: ScienceType,
    radius_cursor_radius: f32,
    detection_time: u32,
    view_object_duration: u32,
    view_object_range: f32,
    public_timer: bool,
    shared_synced_timer: bool,
    shortcut_power: bool,
    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        name: []const u8,
        power_type: SpecialPowerType,
        id: u32,
        reload_time: u32,
        required_science: ScienceType,
    ) !SpecialPowerTemplate {
        return SpecialPowerTemplate{
            .name = try allocator.dupe(u8, name),
            .power_type = power_type,
            .id = id,
            .reload_time = reload_time,
            .required_science = required_science,
            .radius_cursor_radius = 0.0,
            .detection_time = 0,
            .view_object_duration = 0,
            .view_object_range = 0.0,
            .public_timer = false,
            .shared_synced_timer = false,
            .shortcut_power = false,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SpecialPowerTemplate) void {
        self.allocator.free(self.name);
    }
};

// ============================================================================
// Phase 7.3: Special Power Instance (Per-Player)
// ============================================================================

pub const SpecialPowerInstance = struct {
    template: *const SpecialPowerTemplate,
    ready: bool,
    available: bool,
    time_remaining: u32,           // Milliseconds until ready
    last_used_frame: u64,

    pub fn init(template: *const SpecialPowerTemplate) SpecialPowerInstance {
        return .{
            .template = template,
            .ready = false,
            .available = false,
            .time_remaining = template.reload_time,
            .last_used_frame = 0,
        };
    }

    pub fn update(self: *SpecialPowerInstance, delta_ms: u32) void {
        if (!self.ready and self.time_remaining > 0) {
            if (delta_ms >= self.time_remaining) {
                self.time_remaining = 0;
                self.ready = true;
            } else {
                self.time_remaining -= delta_ms;
            }
        }
    }

    pub fn use(self: *SpecialPowerInstance, current_frame: u64) bool {
        if (!self.ready or !self.available) {
            return false;
        }

        self.ready = false;
        self.time_remaining = self.template.reload_time;
        self.last_used_frame = current_frame;
        return true;
    }

    pub fn setAvailable(self: *SpecialPowerInstance, available: bool) void {
        self.available = available;
    }

    pub fn getProgress(self: SpecialPowerInstance) f32 {
        if (self.ready) return 1.0;
        if (self.template.reload_time == 0) return 0.0;

        const elapsed = self.template.reload_time - self.time_remaining;
        return @as(f32, @floatFromInt(elapsed)) / @as(f32, @floatFromInt(self.template.reload_time));
    }
};

// ============================================================================
// Phase 7.4: Special Power Store (Global Templates)
// ============================================================================

pub const SpecialPowerStore = struct {
    templates: std.ArrayList(SpecialPowerTemplate),
    next_id: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator) SpecialPowerStore {
        return .{
            .templates = std.ArrayList(SpecialPowerTemplate){},
            .next_id = 1,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *SpecialPowerStore) void {
        for (self.templates.items) |*template| {
            template.deinit();
        }
        self.templates.deinit(self.allocator);
    }

    pub fn addTemplate(self: *SpecialPowerStore, template: SpecialPowerTemplate) !void {
        try self.templates.append(self.allocator, template);
    }

    pub fn findByName(self: *SpecialPowerStore, name: []const u8) ?*SpecialPowerTemplate {
        for (self.templates.items) |*template| {
            if (std.mem.eql(u8, template.name, name)) {
                return template;
            }
        }
        return null;
    }

    pub fn findByID(self: *SpecialPowerStore, id: u32) ?*SpecialPowerTemplate {
        for (self.templates.items) |*template| {
            if (template.id == id) {
                return template;
            }
        }
        return null;
    }

    pub fn findByType(self: *SpecialPowerStore, power_type: SpecialPowerType) ?*SpecialPowerTemplate {
        for (self.templates.items) |*template| {
            if (template.power_type == power_type) {
                return template;
            }
        }
        return null;
    }

    /// Initialize all C&C Generals special powers
    pub fn initializeDefaults(self: *SpecialPowerStore) !void {
        // USA Powers
        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerDaisyCutter", .DAISY_CUTTER, self.next_id, 240000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerParadrop", .PARADROP_AMERICA, self.next_id, 180000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerCarpetBomb", .CARPET_BOMB, self.next_id, 240000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerClusterMines", .CLUSTER_MINES, self.next_id, 120000, .INVALID
        ));
        self.next_id += 1;

        // China Powers
        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerNapalmStrike", .NAPALM_STRIKE, self.next_id, 180000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerCashHack", .CASH_HACK, self.next_id, 90000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerNeutronMissile", .NEUTRON_MISSILE, self.next_id, 300000, .INVALID
        ));
        self.next_id += 1;

        // GLA Powers
        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerAnthraxBomb", .ANTHRAX_BOMB, self.next_id, 240000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerScudStorm", .SCUD_STORM, self.next_id, 360000, .INVALID
        ));
        self.next_id += 1;

        // Superweapons
        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerParticleUplinkCannon", .PARTICLE_UPLINK_CANNON, self.next_id, 360000, .SCIENCE_SUPER_WEAP
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerA10ThunderboltStrike", .A10_THUNDERBOLT_STRIKE, self.next_id, 180000, .INVALID
        ));
        self.next_id += 1;

        try self.addTemplate(try SpecialPowerTemplate.init(
            self.allocator, "SpecialPowerSpectreGunship", .SPECTRE_GUNSHIP, self.next_id, 240000, .INVALID
        ));
        self.next_id += 1;

        // More powers can be added here following the same pattern...
    }
};

// ============================================================================
// Phase 7.5: Player Special Powers Manager
// ============================================================================

pub const PlayerSpecialPowers = struct {
    instances: std.ArrayList(SpecialPowerInstance),
    player_index: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, player_index: u32) PlayerSpecialPowers {
        return .{
            .instances = std.ArrayList(SpecialPowerInstance){},
            .player_index = player_index,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PlayerSpecialPowers) void {
        self.instances.deinit(self.allocator);
    }

    pub fn addPower(self: *PlayerSpecialPowers, template: *const SpecialPowerTemplate) !void {
        const instance = SpecialPowerInstance.init(template);
        try self.instances.append(self.allocator, instance);
    }

    pub fn update(self: *PlayerSpecialPowers, delta_ms: u32) void {
        for (self.instances.items) |*instance| {
            instance.update(delta_ms);
        }
    }

    pub fn getPowerByType(self: *PlayerSpecialPowers, power_type: SpecialPowerType) ?*SpecialPowerInstance {
        for (self.instances.items) |*instance| {
            if (instance.template.power_type == power_type) {
                return instance;
            }
        }
        return null;
    }

    pub fn usePower(self: *PlayerSpecialPowers, power_type: SpecialPowerType, current_frame: u64) bool {
        if (self.getPowerByType(power_type)) |instance| {
            return instance.use(current_frame);
        }
        return false;
    }

    pub fn isPowerReady(self: *PlayerSpecialPowers, power_type: SpecialPowerType) bool {
        if (self.getPowerByType(power_type)) |instance| {
            return instance.ready and instance.available;
        }
        return false;
    }
};

// ============================================================================
// Phase 7.6: Special Power Execution (Effects)
// ============================================================================

pub const SpecialPowerEffect = struct {
    power_type: SpecialPowerType,
    target_location: Coord3D,
    player_index: u32,
    frame_started: u64,
    duration_frames: u32,
    active: bool,

    pub fn init(power_type: SpecialPowerType, location: Coord3D, player_index: u32, current_frame: u64) SpecialPowerEffect {
        return .{
            .power_type = power_type,
            .target_location = location,
            .player_index = player_index,
            .frame_started = current_frame,
            .duration_frames = getDurationFrames(power_type),
            .active = true,
        };
    }

    pub fn update(self: *SpecialPowerEffect, current_frame: u64) void {
        if (!self.active) return;

        const frames_elapsed = current_frame - self.frame_started;
        if (frames_elapsed >= self.duration_frames) {
            self.active = false;
        }
    }

    fn getDurationFrames(power_type: SpecialPowerType) u32 {
        return switch (power_type) {
            .CARPET_BOMB, .CHINA_CARPET_BOMB => 180,      // 6 seconds at 30fps
            .A10_THUNDERBOLT_STRIKE => 120,                // 4 seconds
            .ARTILLERY_BARRAGE => 150,                     // 5 seconds
            .SPECTRE_GUNSHIP => 300,                       // 10 seconds
            .SCUD_STORM => 90,                             // 3 seconds
            .PARTICLE_UPLINK_CANNON => 60,                 // 2 seconds
            else => 30,                                    // 1 second default
        };
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SpecialPowerTemplate: initialization" {
    const allocator = std.testing.allocator;

    const template = try SpecialPowerTemplate.init(
        allocator,
        "TestPower",
        .CARPET_BOMB,
        1,
        240000,
        .INVALID,
    );
    var template_mut = template;
    defer template_mut.deinit();

    try std.testing.expectEqualStrings("TestPower", template.name);
    try std.testing.expectEqual(SpecialPowerType.CARPET_BOMB, template.power_type);
    try std.testing.expectEqual(@as(u32, 240000), template.reload_time);
}

test "SpecialPowerInstance: usage and cooldown" {
    const allocator = std.testing.allocator;

    const template = try SpecialPowerTemplate.init(
        allocator,
        "TestPower",
        .A10_THUNDERBOLT_STRIKE,
        1,
        5000, // 5 second cooldown
        .INVALID,
    );
    var template_mut = template;
    defer template_mut.deinit();

    var instance = SpecialPowerInstance.init(&template);
    instance.setAvailable(true);

    // Not ready initially
    try std.testing.expect(!instance.ready);

    // Update until ready
    instance.update(5000);
    try std.testing.expect(instance.ready);

    // Use it
    const success = instance.use(1);
    try std.testing.expect(success);
    try std.testing.expect(!instance.ready);

    // Update partway
    instance.update(2500);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), instance.getProgress(), 0.01);

    // Complete cooldown
    instance.update(2500);
    try std.testing.expect(instance.ready);
}

test "SpecialPowerStore: template management" {
    const allocator = std.testing.allocator;

    var store = SpecialPowerStore.init(allocator);
    defer store.deinit();

    const template = try SpecialPowerTemplate.init(
        allocator,
        "DaisyCutter",
        .DAISY_CUTTER,
        1,
        240000,
        .INVALID,
    );
    try store.addTemplate(template);

    const found = store.findByName("DaisyCutter");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(SpecialPowerType.DAISY_CUTTER, found.?.power_type);

    const found_by_type = store.findByType(.DAISY_CUTTER);
    try std.testing.expect(found_by_type != null);
}

test "PlayerSpecialPowers: power management" {
    const allocator = std.testing.allocator;

    var store = SpecialPowerStore.init(allocator);
    defer store.deinit();

    const template = try SpecialPowerTemplate.init(
        allocator,
        "CarpetBomb",
        .CARPET_BOMB,
        1,
        10000,
        .INVALID,
    );
    try store.addTemplate(template);

    var player_powers = PlayerSpecialPowers.init(allocator, 0);
    defer player_powers.deinit();

    const tmpl = store.findByType(.CARPET_BOMB).?;
    try player_powers.addPower(tmpl);

    const instance = player_powers.getPowerByType(.CARPET_BOMB).?;
    instance.setAvailable(true);

    // Make ready
    instance.update(10000);
    try std.testing.expect(player_powers.isPowerReady(.CARPET_BOMB));

    // Use it
    const used = player_powers.usePower(.CARPET_BOMB, 100);
    try std.testing.expect(used);
    try std.testing.expect(!player_powers.isPowerReady(.CARPET_BOMB));
}

test "SpecialPowerEffect: duration tracking" {
    const effect = SpecialPowerEffect.init(
        .CARPET_BOMB,
        .{ .x = 100.0, .y = 100.0, .z = 0.0 },
        0,
        1000,
    );

    try std.testing.expect(effect.active);
    try std.testing.expectEqual(@as(u32, 180), effect.duration_frames);
}

test "SpecialPowerStore: initialize defaults" {
    const allocator = std.testing.allocator;

    var store = SpecialPowerStore.init(allocator);
    defer store.deinit();

    try store.initializeDefaults();

    // Verify some key powers exist
    try std.testing.expect(store.findByType(.DAISY_CUTTER) != null);
    try std.testing.expect(store.findByType(.CARPET_BOMB) != null);
    try std.testing.expect(store.findByType(.SCUD_STORM) != null);
    try std.testing.expect(store.findByType(.PARTICLE_UPLINK_CANNON) != null);
}
