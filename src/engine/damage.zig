// ============================================================================
// Damage/Armor System - Complete Implementation
// Based on Thyme's damage calculation architecture
// ============================================================================
//
// Comprehensive damage system with:
// - Damage types (small arms, explosive, fire, poison, etc.)
// - Armor types (light, medium, heavy, structure)
// - Damage modifiers (bonuses vs specific armor)
// - Armor piercing
// - Splash damage
// - Damage over time (DOT)
// - Veterancy bonuses
//
// References:
// - Thyme/src/game/logic/object/armortemplateset.h
// - Thyme/src/game/logic/object/weapontemplateset.h

const std = @import("std");
const Allocator = std.mem.Allocator;

// ============================================================================
// Phase 1: Damage Types
// ============================================================================

pub const DamageType = enum(u8) {
    SMALL_ARMS,      // Rifles, machine guns
    GRENADE,         // Grenades, grenade launchers
    ARMOR_PIERCING,  // Tank shells, AP rounds
    EXPLOSIVE,       // Bombs, missiles
    FIRE,            // Flame throwers, molotovs
    LASER,           // Laser weapons
    POISON,          // Anthrax, toxins
    RADIATION,       // Nuclear weapons
    PARTICLE_BEAM,   // Particle cannon
    CRUSH,           // Being run over
    SNIPER,          // Sniper rifles
    FORCE,           // Force effects
    HACK,            // Hacking damage
    WATER,           // Water damage
    STATUS,          // Status effects
    UNRESISTABLE,    // Cannot be reduced
    COUNT,
};

pub fn getDamageTypeName(damage_type: DamageType) []const u8 {
    return switch (damage_type) {
        .SMALL_ARMS => "Small Arms",
        .GRENADE => "Grenade",
        .ARMOR_PIERCING => "Armor Piercing",
        .EXPLOSIVE => "Explosive",
        .FIRE => "Fire",
        .LASER => "Laser",
        .POISON => "Poison",
        .RADIATION => "Radiation",
        .PARTICLE_BEAM => "Particle Beam",
        .CRUSH => "Crush",
        .SNIPER => "Sniper",
        else => "Unknown",
    };
}

// ============================================================================
// Phase 2: Armor Types
// ============================================================================

pub const ArmorType = enum(u8) {
    NONE,            // No armor
    INFANTRY_LIGHT,  // Light infantry
    INFANTRY_HEAVY,  // Rangers, tank hunters
    VEHICLE_LIGHT,   // Humvees, buggies
    VEHICLE_MEDIUM,  // APCs, light tanks
    VEHICLE_HEAVY,   // Main battle tanks
    AIRCRAFT,        // Planes, helicopters
    STRUCTURE,       // Buildings
    WALL,            // Walls, gates
    COUNT,
};

pub fn getArmorTypeName(armor_type: ArmorType) []const u8 {
    return switch (armor_type) {
        .NONE => "No Armor",
        .INFANTRY_LIGHT => "Light Infantry",
        .INFANTRY_HEAVY => "Heavy Infantry",
        .VEHICLE_LIGHT => "Light Vehicle",
        .VEHICLE_MEDIUM => "Medium Vehicle",
        .VEHICLE_HEAVY => "Heavy Vehicle",
        .AIRCRAFT => "Aircraft",
        .STRUCTURE => "Structure",
        .WALL => "Wall",
        .COUNT => "Unknown",
    };
}

// ============================================================================
// Phase 3: Damage Modifier Table
// ============================================================================

pub const DamageModifierTable = struct {
    // modifiers[damage_type][armor_type] = multiplier
    modifiers: [16][9]f32,

    pub fn init() DamageModifierTable {
        var table = DamageModifierTable{
            .modifiers = [_][9]f32{[_]f32{1.0} ** 9} ** 16,
        };

        // Initialize from C&C Generals damage table
        table.initDefaults();
        return table;
    }

    fn initDefaults(self: *DamageModifierTable) void {
        // SMALL_ARMS damage
        self.set(.SMALL_ARMS, .INFANTRY_LIGHT, 1.0);
        self.set(.SMALL_ARMS, .INFANTRY_HEAVY, 0.75);
        self.set(.SMALL_ARMS, .VEHICLE_LIGHT, 0.5);
        self.set(.SMALL_ARMS, .VEHICLE_MEDIUM, 0.25);
        self.set(.SMALL_ARMS, .VEHICLE_HEAVY, 0.1);
        self.set(.SMALL_ARMS, .AIRCRAFT, 0.3);
        self.set(.SMALL_ARMS, .STRUCTURE, 0.1);

        // ARMOR_PIERCING damage
        self.set(.ARMOR_PIERCING, .INFANTRY_LIGHT, 1.5);
        self.set(.ARMOR_PIERCING, .INFANTRY_HEAVY, 1.25);
        self.set(.ARMOR_PIERCING, .VEHICLE_LIGHT, 1.5);
        self.set(.ARMOR_PIERCING, .VEHICLE_MEDIUM, 1.25);
        self.set(.ARMOR_PIERCING, .VEHICLE_HEAVY, 1.0);
        self.set(.ARMOR_PIERCING, .STRUCTURE, 0.5);

        // EXPLOSIVE damage
        self.set(.EXPLOSIVE, .INFANTRY_LIGHT, 1.5);
        self.set(.EXPLOSIVE, .INFANTRY_HEAVY, 1.25);
        self.set(.EXPLOSIVE, .VEHICLE_LIGHT, 1.0);
        self.set(.EXPLOSIVE, .VEHICLE_MEDIUM, 0.75);
        self.set(.EXPLOSIVE, .VEHICLE_HEAVY, 0.5);
        self.set(.EXPLOSIVE, .STRUCTURE, 1.5);

        // FIRE damage
        self.set(.FIRE, .INFANTRY_LIGHT, 2.0);
        self.set(.FIRE, .INFANTRY_HEAVY, 1.5);
        self.set(.FIRE, .VEHICLE_LIGHT, 0.75);
        self.set(.FIRE, .VEHICLE_MEDIUM, 0.5);
        self.set(.FIRE, .VEHICLE_HEAVY, 0.25);
        self.set(.FIRE, .STRUCTURE, 1.0);

        // SNIPER damage
        self.set(.SNIPER, .INFANTRY_LIGHT, 10.0);  // One-shot infantry
        self.set(.SNIPER, .INFANTRY_HEAVY, 5.0);
        self.set(.SNIPER, .VEHICLE_LIGHT, 0.1);
        self.set(.SNIPER, .VEHICLE_MEDIUM, 0.05);
        self.set(.SNIPER, .VEHICLE_HEAVY, 0.01);
    }

    fn set(self: *DamageModifierTable, damage_type: DamageType, armor_type: ArmorType, multiplier: f32) void {
        const d = @intFromEnum(damage_type);
        const a = @intFromEnum(armor_type);
        if (d < 16 and a < 9) {
            self.modifiers[d][a] = multiplier;
        }
    }

    pub fn get(self: DamageModifierTable, damage_type: DamageType, armor_type: ArmorType) f32 {
        const d = @intFromEnum(damage_type);
        const a = @intFromEnum(armor_type);
        if (d < 16 and a < 9) {
            return self.modifiers[d][a];
        }
        return 1.0;
    }
};

// ============================================================================
// Phase 4: Damage Instance
// ============================================================================

pub const DamageInfo = struct {
    amount: f32,
    damage_type: DamageType,
    armor_piercing: f32,     // 0.0 to 1.0 (ignores armor)
    splash_radius: f32,      // 0 = no splash
    splash_falloff: f32,     // 0.0 to 1.0
    is_critical: bool,       // Critical hit
    source_entity_id: ?u32,
    veterancy_bonus: f32,    // From attacker veterancy

    pub fn init(amount: f32, damage_type: DamageType) DamageInfo {
        return .{
            .amount = amount,
            .damage_type = damage_type,
            .armor_piercing = 0.0,
            .splash_radius = 0.0,
            .splash_falloff = 1.0,
            .is_critical = false,
            .source_entity_id = null,
            .veterancy_bonus = 1.0,
        };
    }

    pub fn withArmorPiercing(self: DamageInfo, ap: f32) DamageInfo {
        var result = self;
        result.armor_piercing = ap;
        return result;
    }

    pub fn withSplash(self: DamageInfo, radius: f32, falloff: f32) DamageInfo {
        var result = self;
        result.splash_radius = radius;
        result.splash_falloff = falloff;
        return result;
    }

    pub fn withVeterancy(self: DamageInfo, bonus: f32) DamageInfo {
        var result = self;
        result.veterancy_bonus = bonus;
        return result;
    }
};

// ============================================================================
// Phase 5: Armor Instance
// ============================================================================

pub const ArmorInfo = struct {
    armor_type: ArmorType,
    armor_value: f32,        // Base armor (damage reduction)
    resistances: [16]f32,    // Per-damage-type resistance

    pub fn init(armor_type: ArmorType, armor_value: f32) ArmorInfo {
        return .{
            .armor_type = armor_type,
            .armor_value = armor_value,
            .resistances = [_]f32{0.0} ** 16,
        };
    }

    pub fn setResistance(self: *ArmorInfo, damage_type: DamageType, resistance: f32) void {
        const idx = @intFromEnum(damage_type);
        if (idx < 16) {
            self.resistances[idx] = resistance;
        }
    }

    pub fn getResistance(self: ArmorInfo, damage_type: DamageType) f32 {
        const idx = @intFromEnum(damage_type);
        if (idx < 16) {
            return self.resistances[idx];
        }
        return 0.0;
    }
};

// ============================================================================
// Phase 6: Damage Calculation
// ============================================================================

pub const DamageCalculator = struct {
    modifier_table: DamageModifierTable,

    pub fn init() DamageCalculator {
        return .{
            .modifier_table = DamageModifierTable.init(),
        };
    }

    /// Calculate final damage after all modifiers
    pub fn calculateDamage(self: DamageCalculator, damage: DamageInfo, armor: ArmorInfo) f32 {
        var final_damage = damage.amount;

        // Apply veterancy bonus
        final_damage *= damage.veterancy_bonus;

        // Apply damage type vs armor type modifier
        const type_modifier = self.modifier_table.get(damage.damage_type, armor.armor_type);
        final_damage *= type_modifier;

        // Apply armor resistance
        const resistance = armor.getResistance(damage.damage_type);
        final_damage *= (1.0 - resistance);

        // Apply armor value (damage reduction)
        const armor_reduction = armor.armor_value * (1.0 - damage.armor_piercing);
        final_damage = @max(0.0, final_damage - armor_reduction);

        // Critical hits (50% bonus)
        if (damage.is_critical) {
            final_damage *= 1.5;
        }

        return final_damage;
    }

    /// Calculate splash damage at distance from impact
    pub fn calculateSplashDamage(self: DamageCalculator, damage: DamageInfo, armor: ArmorInfo, distance: f32) f32 {
        if (damage.splash_radius <= 0.0 or distance > damage.splash_radius) {
            return 0.0;
        }

        // Calculate falloff
        const falloff_ratio = distance / damage.splash_radius;
        const falloff_multiplier = 1.0 - (falloff_ratio * damage.splash_falloff);

        // Calculate base damage with falloff
        var modified_damage = damage;
        modified_damage.amount *= @max(0.0, falloff_multiplier);

        return self.calculateDamage(modified_damage, armor);
    }
};

// ============================================================================
// Phase 7: Damage Over Time (DOT)
// ============================================================================

pub const DamageOverTime = struct {
    damage_per_second: f32,
    damage_type: DamageType,
    duration: f32,           // Total duration in seconds
    elapsed: f32,            // Time elapsed
    tick_rate: f32,          // How often to apply damage
    last_tick: f32,

    pub fn init(dps: f32, damage_type: DamageType, duration: f32) DamageOverTime {
        return .{
            .damage_per_second = dps,
            .damage_type = damage_type,
            .duration = duration,
            .elapsed = 0.0,
            .tick_rate = 0.5,  // Apply every 0.5 seconds
            .last_tick = 0.0,
        };
    }

    pub fn update(self: *DamageOverTime, dt: f32) ?DamageInfo {
        self.elapsed += dt;
        self.last_tick += dt;

        if (self.elapsed >= self.duration) {
            return null;  // Expired
        }

        if (self.last_tick >= self.tick_rate) {
            self.last_tick -= self.tick_rate;
            const damage_amount = self.damage_per_second * self.tick_rate;
            return DamageInfo.init(damage_amount, self.damage_type);
        }

        return null;
    }

    pub fn isExpired(self: DamageOverTime) bool {
        return self.elapsed >= self.duration;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DamageModifierTable: lookup" {
    const table = DamageModifierTable.init();

    const mod = table.get(.SMALL_ARMS, .VEHICLE_HEAVY);
    try std.testing.expectEqual(@as(f32, 0.1), mod);

    const mod2 = table.get(.ARMOR_PIERCING, .VEHICLE_HEAVY);
    try std.testing.expectEqual(@as(f32, 1.0), mod2);
}

test "DamageCalculator: basic damage" {
    const calc = DamageCalculator.init();

    const damage = DamageInfo.init(100.0, .SMALL_ARMS);
    const armor = ArmorInfo.init(.INFANTRY_LIGHT, 0.0);

    const final_damage = calc.calculateDamage(damage, armor);
    try std.testing.expectEqual(@as(f32, 100.0), final_damage);
}

test "DamageCalculator: armor type modifier" {
    const calc = DamageCalculator.init();

    const damage = DamageInfo.init(100.0, .SMALL_ARMS);
    const armor = ArmorInfo.init(.VEHICLE_HEAVY, 0.0);

    const final_damage = calc.calculateDamage(damage, armor);
    try std.testing.expectEqual(@as(f32, 10.0), final_damage);  // 100 * 0.1
}

test "DamageCalculator: armor piercing" {
    const calc = DamageCalculator.init();

    var damage = DamageInfo.init(100.0, .SMALL_ARMS);
    damage.armor_piercing = 0.5;  // 50% armor piercing

    const armor = ArmorInfo.init(.INFANTRY_LIGHT, 20.0);

    // Base: 100, armor reduction: 20 * (1 - 0.5) = 10
    // Final: 100 - 10 = 90
    const final_damage = calc.calculateDamage(damage, armor);
    try std.testing.expectEqual(@as(f32, 90.0), final_damage);
}

test "DamageCalculator: splash damage" {
    const calc = DamageCalculator.init();

    var damage = DamageInfo.init(200.0, .EXPLOSIVE);
    damage.splash_radius = 10.0;
    damage.splash_falloff = 1.0;  // Full falloff

    const armor = ArmorInfo.init(.INFANTRY_LIGHT, 0.0);

    // At center (distance 0)
    const center_damage = calc.calculateSplashDamage(damage, armor, 0.0);
    try std.testing.expectEqual(@as(f32, 300.0), center_damage);  // 200 * 1.5 (explosive vs infantry)

    // At edge (distance 10)
    const edge_damage = calc.calculateSplashDamage(damage, armor, 10.0);
    try std.testing.expectEqual(@as(f32, 0.0), edge_damage);

    // Halfway (distance 5)
    const mid_damage = calc.calculateSplashDamage(damage, armor, 5.0);
    try std.testing.expectApproxEqAbs(@as(f32, 150.0), mid_damage, 0.1);  // 50% falloff
}

test "DamageOverTime: tick damage" {
    var dot = DamageOverTime.init(10.0, .POISON, 5.0);

    // First tick at 0.5 seconds
    const dmg1 = dot.update(0.5);
    try std.testing.expect(dmg1 != null);
    try std.testing.expectEqual(@as(f32, 5.0), dmg1.?.amount);  // 10 dps * 0.5s

    // No tick at 0.6 seconds (needs 1.0 total)
    const dmg2 = dot.update(0.1);
    try std.testing.expect(dmg2 == null);

    // Second tick at 1.0 seconds
    const dmg3 = dot.update(0.4);
    try std.testing.expect(dmg3 != null);
}

test "DamageOverTime: expiration" {
    var dot = DamageOverTime.init(10.0, .FIRE, 2.0);

    try std.testing.expect(!dot.isExpired());

    _ = dot.update(2.5);
    try std.testing.expect(dot.isExpired());
}

test "DamageInfo: builders" {
    var damage = DamageInfo.init(100.0, .EXPLOSIVE);
    damage = damage.withArmorPiercing(0.3);
    damage = damage.withSplash(15.0, 0.8);
    damage = damage.withVeterancy(1.25);

    try std.testing.expectEqual(@as(f32, 100.0), damage.amount);
    try std.testing.expectEqual(@as(f32, 0.3), damage.armor_piercing);
    try std.testing.expectEqual(@as(f32, 15.0), damage.splash_radius);
    try std.testing.expectEqual(@as(f32, 1.25), damage.veterancy_bonus);
}
