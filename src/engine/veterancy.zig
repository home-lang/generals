// ============================================================================
// Veterancy/Experience System - Complete Implementation
// Based on Thyme's veterancy architecture
// ============================================================================
//
// Veterancy provides unit progression through combat experience.
// Units gain XP from kills and level up (Veteran → Elite → Heroic)
// Each level grants bonuses: health, damage, speed, vision, healing
//
// References:
// - Thyme/src/game/logic/object/experiencelevels.h
// - Thyme/src/game/logic/object/armedunit.h (ExperienceScalar)
// - Thyme/ini/Experience.ini

const std = @import("std");
const Allocator = std.mem.Allocator;

// ============================================================================
// Phase 1: Experience Levels
// ============================================================================

pub const ExperienceLevel = enum(u8) {
    ROOKIE = 0,
    VETERAN = 1,
    ELITE = 2,
    HEROIC = 3,
    COUNT = 4,
};

/// Get XP required for each level (from C&C Generals)
pub fn getRequiredXP(level: ExperienceLevel) u32 {
    return switch (level) {
        .ROOKIE => 0,
        .VETERAN => 100,     // 100 XP to reach Veteran
        .ELITE => 300,       // 300 XP total to reach Elite
        .HEROIC => 600,      // 600 XP total to reach Heroic
        .COUNT => 600,
    };
}

/// Get display name for level
pub fn getLevelName(level: ExperienceLevel) []const u8 {
    return switch (level) {
        .ROOKIE => "Rookie",
        .VETERAN => "Veteran",
        .ELITE => "Elite",
        .HEROIC => "Heroic",
        .COUNT => "Unknown",
    };
}

// ============================================================================
// Phase 2: Experience Modifiers
// ============================================================================

/// Modifiers applied at each experience level
pub const ExperienceLevelModifiers = struct {
    health_bonus: f32,        // Multiplier (1.0 = no change, 1.5 = +50%)
    damage_bonus: f32,
    speed_bonus: f32,
    vision_bonus: f32,
    heal_per_second: f32,     // Passive healing
    armor_bonus: f32,

    pub fn init() ExperienceLevelModifiers {
        return .{
            .health_bonus = 1.0,
            .damage_bonus = 1.0,
            .speed_bonus = 1.0,
            .vision_bonus = 1.0,
            .heal_per_second = 0.0,
            .armor_bonus = 0.0,
        };
    }

    /// Get default modifiers for a level (from C&C Generals)
    pub fn forLevel(level: ExperienceLevel) ExperienceLevelModifiers {
        return switch (level) {
            .ROOKIE => .{
                .health_bonus = 1.0,
                .damage_bonus = 1.0,
                .speed_bonus = 1.0,
                .vision_bonus = 1.0,
                .heal_per_second = 0.0,
                .armor_bonus = 0.0,
            },
            .VETERAN => .{
                .health_bonus = 1.25,     // +25% health
                .damage_bonus = 1.25,     // +25% damage
                .speed_bonus = 1.0,
                .vision_bonus = 1.1,      // +10% vision
                .heal_per_second = 0.0,
                .armor_bonus = 0.0,
            },
            .ELITE => .{
                .health_bonus = 1.5,      // +50% health
                .damage_bonus = 1.5,      // +50% damage
                .speed_bonus = 1.1,       // +10% speed
                .vision_bonus = 1.2,      // +20% vision
                .heal_per_second = 2.0,   // +2 HP/sec healing
                .armor_bonus = 25.0,
            },
            .HEROIC => .{
                .health_bonus = 2.0,      // +100% health (double)
                .damage_bonus = 2.0,      // +100% damage
                .speed_bonus = 1.2,       // +20% speed
                .vision_bonus = 1.5,      // +50% vision
                .heal_per_second = 5.0,   // +5 HP/sec healing
                .armor_bonus = 50.0,
            },
            .COUNT => ExperienceLevelModifiers.init(),
        };
    }
};

// ============================================================================
// Phase 3: Experience Tracker
// ============================================================================

pub const ExperienceTracker = struct {
    current_xp: u32,
    current_level: ExperienceLevel,
    lifetime_kills: u32,
    lifetime_damage_dealt: f32,
    lifetime_damage_taken: f32,

    pub fn init() ExperienceTracker {
        return .{
            .current_xp = 0,
            .current_level = .ROOKIE,
            .lifetime_kills = 0,
            .lifetime_damage_dealt = 0.0,
            .lifetime_damage_taken = 0.0,
        };
    }

    /// Award XP and check for level up
    pub fn awardXP(self: *ExperienceTracker, xp: u32) bool {
        self.current_xp += xp;

        // Check if leveled up
        return self.checkLevelUp();
    }

    /// Check and apply level up if threshold reached
    fn checkLevelUp(self: *ExperienceTracker) bool {
        var leveled_up = false;

        while (true) {
            const next_level = @as(u8, @intFromEnum(self.current_level)) + 1;
            if (next_level >= @intFromEnum(ExperienceLevel.COUNT)) break;

            const next_level_enum = @as(ExperienceLevel, @enumFromInt(next_level));
            const required = getRequiredXP(next_level_enum);

            if (self.current_xp >= required) {
                self.current_level = next_level_enum;
                leveled_up = true;
            } else {
                break;
            }
        }

        return leveled_up;
    }

    /// Calculate XP awarded for killing an enemy
    pub fn calculateKillXP(enemy_cost: u32, enemy_level: ExperienceLevel) u32 {
        // Base XP is 10% of enemy cost
        var xp = enemy_cost / 10;

        // Bonus XP for higher level enemies
        const level_bonus: u32 = switch (enemy_level) {
            .ROOKIE => 0,
            .VETERAN => 20,
            .ELITE => 50,
            .HEROIC => 100,
            .COUNT => 0,
        };

        xp += level_bonus;

        return @max(1, xp); // Minimum 1 XP
    }

    /// Record a kill and award XP
    pub fn recordKill(self: *ExperienceTracker, enemy_cost: u32, enemy_level: ExperienceLevel) bool {
        self.lifetime_kills += 1;

        const xp = calculateKillXP(enemy_cost, enemy_level);
        return self.awardXP(xp);
    }

    /// Record damage dealt (for partial XP)
    pub fn recordDamageDealt(self: *ExperienceTracker, damage: f32, enemy_cost: u32) void {
        self.lifetime_damage_dealt += damage;

        // Award small amount of XP for damage (10% of kill XP per 100 damage)
        const kill_xp = calculateKillXP(enemy_cost, .ROOKIE);
        const damage_ratio = damage / 100.0; // Assume 100 HP base
        const damage_xp = @as(u32, @intFromFloat(@as(f32, @floatFromInt(kill_xp)) * damage_ratio * 0.1));

        if (damage_xp > 0) {
            _ = self.awardXP(damage_xp);
        }
    }

    /// Record damage taken
    pub fn recordDamageTaken(self: *ExperienceTracker, damage: f32) void {
        self.lifetime_damage_taken += damage;
    }

    /// Get current modifiers
    pub fn getModifiers(self: ExperienceTracker) ExperienceLevelModifiers {
        return ExperienceLevelModifiers.forLevel(self.current_level);
    }

    /// Get progress to next level (0.0 to 1.0)
    pub fn getProgressToNextLevel(self: ExperienceTracker) f32 {
        const next_level_value = @as(u8, @intFromEnum(self.current_level)) + 1;
        if (next_level_value >= @intFromEnum(ExperienceLevel.COUNT)) {
            return 1.0; // Max level
        }

        const next_level = @as(ExperienceLevel, @enumFromInt(next_level_value));
        const current_threshold = getRequiredXP(self.current_level);
        const next_threshold = getRequiredXP(next_level);

        if (next_threshold <= current_threshold) return 1.0;

        const progress_xp = self.current_xp - current_threshold;
        const required_xp = next_threshold - current_threshold;

        return @as(f32, @floatFromInt(progress_xp)) / @as(f32, @floatFromInt(required_xp));
    }

    /// Check if at max level
    pub fn isMaxLevel(self: ExperienceTracker) bool {
        return self.current_level == .HEROIC;
    }

    /// Get XP needed for next level
    pub fn getXPForNextLevel(self: ExperienceTracker) u32 {
        const next_level_value = @as(u8, @intFromEnum(self.current_level)) + 1;
        if (next_level_value >= @intFromEnum(ExperienceLevel.COUNT)) {
            return 0; // Max level
        }

        const next_level = @as(ExperienceLevel, @enumFromInt(next_level_value));
        const required = getRequiredXP(next_level);

        if (self.current_xp >= required) return 0;
        return required - self.current_xp;
    }
};

// ============================================================================
// Phase 4: Experience Level Collection (INI Loading)
// ============================================================================

pub const ExperienceLevelTemplate = struct {
    name: []const u8,
    target_level: ExperienceLevel,
    required_xp: u32,
    modifiers: ExperienceLevelModifiers,
    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        name: []const u8,
        target_level: ExperienceLevel,
        required_xp: u32,
        modifiers: ExperienceLevelModifiers,
    ) !ExperienceLevelTemplate {
        return ExperienceLevelTemplate{
            .name = try allocator.dupe(u8, name),
            .target_level = target_level,
            .required_xp = required_xp,
            .modifiers = modifiers,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ExperienceLevelTemplate) void {
        self.allocator.free(self.name);
    }
};

pub const ExperienceLevelCollection = struct {
    levels: std.ArrayList(ExperienceLevelTemplate),
    allocator: Allocator,

    pub fn init(allocator: Allocator) ExperienceLevelCollection {
        return .{
            .levels = std.ArrayList(ExperienceLevelTemplate){},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ExperienceLevelCollection) void {
        for (self.levels.items) |*level| {
            level.deinit();
        }
        self.levels.deinit(self.allocator);
    }

    pub fn addLevel(self: *ExperienceLevelCollection, level: ExperienceLevelTemplate) !void {
        try self.levels.append(self.allocator, level);
    }

    /// Initialize default C&C Generals experience levels
    pub fn initializeDefaults(self: *ExperienceLevelCollection) !void {
        // Veteran
        try self.addLevel(try ExperienceLevelTemplate.init(
            self.allocator,
            "VETERAN",
            .VETERAN,
            100,
            ExperienceLevelModifiers.forLevel(.VETERAN),
        ));

        // Elite
        try self.addLevel(try ExperienceLevelTemplate.init(
            self.allocator,
            "ELITE",
            .ELITE,
            300,
            ExperienceLevelModifiers.forLevel(.ELITE),
        ));

        // Heroic
        try self.addLevel(try ExperienceLevelTemplate.init(
            self.allocator,
            "HEROIC",
            .HEROIC,
            600,
            ExperienceLevelModifiers.forLevel(.HEROIC),
        ));
    }

    pub fn findLevel(self: *ExperienceLevelCollection, name: []const u8) ?*ExperienceLevelTemplate {
        for (self.levels.items) |*level| {
            if (std.mem.eql(u8, level.name, name)) {
                return level;
            }
        }
        return null;
    }
};

// ============================================================================
// Phase 5: Global Experience Settings
// ============================================================================

pub const ExperienceSettings = struct {
    xp_multiplier: f32,            // Global XP gain multiplier
    enable_passive_healing: bool,  // Enable healing at Elite+
    veteran_health_bonus: f32,
    veteran_damage_bonus: f32,
    elite_health_bonus: f32,
    elite_damage_bonus: f32,
    heroic_health_bonus: f32,
    heroic_damage_bonus: f32,

    pub fn initDefaults() ExperienceSettings {
        return .{
            .xp_multiplier = 1.0,
            .enable_passive_healing = true,
            .veteran_health_bonus = 1.25,
            .veteran_damage_bonus = 1.25,
            .elite_health_bonus = 1.5,
            .elite_damage_bonus = 1.5,
            .heroic_health_bonus = 2.0,
            .heroic_damage_bonus = 2.0,
        };
    }
};

// ============================================================================
// Tests
// ============================================================================

test "ExperienceTracker: initialization" {
    var tracker = ExperienceTracker.init();

    try std.testing.expectEqual(ExperienceLevel.ROOKIE, tracker.current_level);
    try std.testing.expectEqual(@as(u32, 0), tracker.current_xp);
    try std.testing.expectEqual(@as(u32, 0), tracker.lifetime_kills);
}

test "ExperienceTracker: level up from XP" {
    var tracker = ExperienceTracker.init();

    // Award 100 XP → should reach Veteran
    const leveled_up = tracker.awardXP(100);
    try std.testing.expect(leveled_up);
    try std.testing.expectEqual(ExperienceLevel.VETERAN, tracker.current_level);

    // Award another 200 XP (total 300) → should reach Elite
    const leveled_up2 = tracker.awardXP(200);
    try std.testing.expect(leveled_up2);
    try std.testing.expectEqual(ExperienceLevel.ELITE, tracker.current_level);

    // Award another 300 XP (total 600) → should reach Heroic
    const leveled_up3 = tracker.awardXP(300);
    try std.testing.expect(leveled_up3);
    try std.testing.expectEqual(ExperienceLevel.HEROIC, tracker.current_level);

    // Check max level
    try std.testing.expect(tracker.isMaxLevel());
}

test "ExperienceTracker: kill XP calculation" {
    const xp1 = ExperienceTracker.calculateKillXP(1000, .ROOKIE);
    try std.testing.expectEqual(@as(u32, 100), xp1); // 10% of 1000

    const xp2 = ExperienceTracker.calculateKillXP(1000, .VETERAN);
    try std.testing.expectEqual(@as(u32, 120), xp2); // 100 + 20 bonus

    const xp3 = ExperienceTracker.calculateKillXP(1000, .HEROIC);
    try std.testing.expectEqual(@as(u32, 200), xp3); // 100 + 100 bonus
}

test "ExperienceTracker: record kill" {
    var tracker = ExperienceTracker.init();

    // Kill cheap unit (100 cost) → 10 XP
    const leveled_up = tracker.recordKill(100, .ROOKIE);
    try std.testing.expect(!leveled_up);
    try std.testing.expectEqual(@as(u32, 1), tracker.lifetime_kills);
    try std.testing.expectEqual(@as(u32, 10), tracker.current_xp);

    // Kill expensive unit (1000 cost) → 100 XP (total 110)
    _ = tracker.recordKill(1000, .ROOKIE);
    try std.testing.expectEqual(@as(u32, 2), tracker.lifetime_kills);
    try std.testing.expectEqual(@as(u32, 110), tracker.current_xp);
    try std.testing.expectEqual(ExperienceLevel.VETERAN, tracker.current_level);
}

test "ExperienceTracker: progress to next level" {
    var tracker = ExperienceTracker.init();

    // 0 XP → 0% progress to Veteran (needs 100)
    try std.testing.expectEqual(@as(f32, 0.0), tracker.getProgressToNextLevel());

    // 50 XP → 50% progress to Veteran
    _ = tracker.awardXP(50);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), tracker.getProgressToNextLevel(), 0.01);

    // 100 XP → Veteran, 0% progress to Elite
    _ = tracker.awardXP(50);
    try std.testing.expectEqual(@as(f32, 0.0), tracker.getProgressToNextLevel());

    // 200 XP → 50% progress to Elite (needs 200 more, from 100 to 300)
    _ = tracker.awardXP(100);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), tracker.getProgressToNextLevel(), 0.01);
}

test "ExperienceTracker: XP for next level" {
    var tracker = ExperienceTracker.init();

    // Rookie → needs 100 for Veteran
    try std.testing.expectEqual(@as(u32, 100), tracker.getXPForNextLevel());

    // Award 50 XP → needs 50 more
    _ = tracker.awardXP(50);
    try std.testing.expectEqual(@as(u32, 50), tracker.getXPForNextLevel());

    // Reach Veteran → needs 200 for Elite (300 - 100)
    _ = tracker.awardXP(50);
    try std.testing.expectEqual(@as(u32, 200), tracker.getXPForNextLevel());

    // Reach max level → 0 needed
    _ = tracker.awardXP(500);
    try std.testing.expectEqual(@as(u32, 0), tracker.getXPForNextLevel());
}

test "ExperienceLevelModifiers: bonuses per level" {
    const rookie_mods = ExperienceLevelModifiers.forLevel(.ROOKIE);
    try std.testing.expectEqual(@as(f32, 1.0), rookie_mods.health_bonus);
    try std.testing.expectEqual(@as(f32, 1.0), rookie_mods.damage_bonus);

    const veteran_mods = ExperienceLevelModifiers.forLevel(.VETERAN);
    try std.testing.expectEqual(@as(f32, 1.25), veteran_mods.health_bonus);
    try std.testing.expectEqual(@as(f32, 1.25), veteran_mods.damage_bonus);

    const elite_mods = ExperienceLevelModifiers.forLevel(.ELITE);
    try std.testing.expectEqual(@as(f32, 1.5), elite_mods.health_bonus);
    try std.testing.expectEqual(@as(f32, 2.0), elite_mods.heal_per_second);

    const heroic_mods = ExperienceLevelModifiers.forLevel(.HEROIC);
    try std.testing.expectEqual(@as(f32, 2.0), heroic_mods.health_bonus);
    try std.testing.expectEqual(@as(f32, 5.0), heroic_mods.heal_per_second);
}

test "ExperienceTracker: get current modifiers" {
    var tracker = ExperienceTracker.init();

    // Rookie has 1.0x bonuses
    const mods1 = tracker.getModifiers();
    try std.testing.expectEqual(@as(f32, 1.0), mods1.damage_bonus);

    // Level to Veteran
    _ = tracker.awardXP(100);
    const mods2 = tracker.getModifiers();
    try std.testing.expectEqual(@as(f32, 1.25), mods2.damage_bonus);

    // Level to Heroic
    _ = tracker.awardXP(500);
    const mods3 = tracker.getModifiers();
    try std.testing.expectEqual(@as(f32, 2.0), mods3.damage_bonus);
}

test "ExperienceLevelCollection: initialization" {
    const allocator = std.testing.allocator;

    var collection = ExperienceLevelCollection.init(allocator);
    defer collection.deinit();

    try collection.initializeDefaults();

    try std.testing.expectEqual(@as(usize, 3), collection.levels.items.len);

    const veteran = collection.findLevel("VETERAN");
    try std.testing.expect(veteran != null);
    try std.testing.expectEqual(@as(u32, 100), veteran.?.required_xp);
}

test "ExperienceSettings: defaults" {
    const settings = ExperienceSettings.initDefaults();

    try std.testing.expectEqual(@as(f32, 1.0), settings.xp_multiplier);
    try std.testing.expect(settings.enable_passive_healing);
    try std.testing.expectEqual(@as(f32, 1.25), settings.veteran_health_bonus);
}

test "ExperienceTracker: damage dealt XP" {
    var tracker = ExperienceTracker.init();

    // Deal 50 damage to 1000-cost enemy
    tracker.recordDamageDealt(50.0, 1000);

    try std.testing.expect(tracker.current_xp > 0);
    try std.testing.expectApproxEqAbs(@as(f32, 50.0), tracker.lifetime_damage_dealt, 0.01);
}
