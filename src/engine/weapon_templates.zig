// Weapon Templates System
// Loads weapon definitions from INI files (Weapon.ini)
// Based on Thyme's weapon template system

const std = @import("std");
const Allocator = std.mem.Allocator;
const io = @import("io");
const IniFile = io.IniFile;
const combat = @import("combat.zig");
const DamageType = combat.DamageType;
const WeaponStats = combat.WeaponStats;
const WeaponType = combat.WeaponType;
const AntiMask = combat.AntiMask;

/// Weapon template loaded from INI
pub const WeaponTemplate = struct {
    name: []const u8,
    stats: WeaponStats,
    allocator: Allocator,

    pub fn deinit(self: *WeaponTemplate) void {
        self.allocator.free(self.name);
    }
};

/// Weapon template manager
pub const WeaponTemplateManager = struct {
    templates: std.StringHashMap(WeaponTemplate),
    allocator: Allocator,

    pub fn init(allocator: Allocator) WeaponTemplateManager {
        return .{
            .templates = std.StringHashMap(WeaponTemplate).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *WeaponTemplateManager) void {
        var it = self.templates.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            var template = entry.value_ptr;
            template.deinit();
        }
        self.templates.deinit();
    }

    /// Load weapons from INI file
    pub fn loadFromIni(self: *WeaponTemplateManager, ini: *const IniFile) !void {
        var sections_iter = ini.sections.iterator();
        while (sections_iter.next()) |entry| {
            const section_name = entry.key_ptr.*;
            const section = entry.value_ptr;

            // Check if this is a weapon section (starts with "Weapon ")
            if (std.mem.startsWith(u8, section_name, "Weapon ")) {
                const weapon_name = section_name[7..]; // Skip "Weapon "

                var stats = WeaponStats{
                    .damage = 10.0,
                    .range = 200.0,
                    .fire_rate = 1.0,
                    .projectile_speed = 400.0,
                    .area_of_effect = 0.0,
                    .weapon_type = .Rifle,
                };

                // Parse weapon properties
                if (section.getInt("PrimaryDamage")) |damage| {
                    stats.damage = @floatFromInt(damage);
                }

                if (section.getFloat("AttackRange")) |range| {
                    stats.range = @floatCast(range);
                }

                if (section.getInt("DelayBetweenShots")) |delay_ms| {
                    stats.fire_rate = @as(f32, @floatFromInt(delay_ms)) / 1000.0;
                }

                if (section.getFloat("WeaponSpeed")) |speed| {
                    stats.projectile_speed = @floatCast(speed);
                }

                if (section.getFloat("DamageRadius")) |radius| {
                    stats.area_of_effect = @floatCast(radius);
                }

                if (section.getFloat("MinimumAttackRange")) |min_range| {
                    stats.min_range = @floatCast(min_range);
                }

                if (section.getFloat("ScatterRadius")) |scatter| {
                    stats.scatter_radius = @floatCast(scatter);
                }

                if (section.getInt("ClipSize")) |clip| {
                    stats.clip_size = @intCast(clip);
                }

                if (section.getFloat("ClipReloadTime")) |reload| {
                    stats.clip_reload_time = @floatCast(reload);
                }

                // Parse damage type
                if (section.getString("DamageType")) |damage_type_str| {
                    stats.damage_type = parseDamageType(damage_type_str);
                }

                // Parse anti-mask
                stats.anti_mask = parseAntiMask(section);

                // Determine weapon type from properties
                stats.weapon_type = determineWeaponType(weapon_name, &stats);

                // Store template
                const name_copy = try self.allocator.dupe(u8, weapon_name);
                const template = WeaponTemplate{
                    .name = name_copy,
                    .stats = stats,
                    .allocator = self.allocator,
                };

                const key_copy = try self.allocator.dupe(u8, weapon_name);
                try self.templates.put(key_copy, template);
            }
        }
    }

    /// Get weapon template by name
    pub fn getTemplate(self: *const WeaponTemplateManager, name: []const u8) ?*const WeaponTemplate {
        return self.templates.getPtr(name);
    }

    /// Get weapon stats by name
    pub fn getStats(self: *const WeaponTemplateManager, name: []const u8) ?WeaponStats {
        if (self.getTemplate(name)) |template| {
            return template.stats;
        }
        return null;
    }
};

/// Parse damage type from string
fn parseDamageType(str: []const u8) DamageType {
    if (std.mem.eql(u8, str, "ARMOR_PIERCING")) return .ARMOR_PIERCING;
    if (std.mem.eql(u8, str, "HOLLOW_POINT")) return .HOLLOW_POINT;
    if (std.mem.eql(u8, str, "SMALL_ARMS")) return .SMALL_ARMS;
    if (std.mem.eql(u8, str, "EXPLOSION")) return .EXPLOSION;
    if (std.mem.eql(u8, str, "FIRE")) return .FIRE;
    if (std.mem.eql(u8, str, "LASER")) return .LASER;
    if (std.mem.eql(u8, str, "POISON")) return .POISON;
    if (std.mem.eql(u8, str, "SNIPER")) return .SNIPER;
    if (std.mem.eql(u8, str, "STRUCTURE")) return .STRUCTURE;
    if (std.mem.eql(u8, str, "RADIATION")) return .RADIATION;
    return .SMALL_ARMS; // Default
}

/// Parse anti-mask from INI section
fn parseAntiMask(section: *const io.IniFile.IniSection) AntiMask {
    var mask = AntiMask{};

    // Check RadiusDamageAffects field
    if (section.getString("RadiusDamageAffects")) |affects| {
        if (std.mem.indexOf(u8, affects, "ENEMIES") != null) {
            mask.ground = true;
            mask.airborne_vehicle = true;
        }
        if (std.mem.indexOf(u8, affects, "ALLIES") != null) {
            mask.ground = true;
        }
    }

    // Check ProjectileFilterInContainer
    if (section.getString("ProjectileFilterInContainer")) |filter| {
        if (std.mem.indexOf(u8, filter, "AIRCRAFT") != null) {
            mask.airborne_vehicle = true;
        }
    }

    // Default to ground
    if (!mask.ground and !mask.airborne_vehicle) {
        mask.ground = true;
    }

    return mask;
}

/// Determine weapon type from name and stats
fn determineWeaponType(name: []const u8, stats: *const WeaponStats) WeaponType {
    const name_lower = name; // Would need to lowercase for proper comparison

    if (std.mem.indexOf(u8, name_lower, "Rifle") != null or
        std.mem.indexOf(u8, name_lower, "AK47") != null) {
        return .Rifle;
    }

    if (std.mem.indexOf(u8, name_lower, "MachineGun") != null or
        std.mem.indexOf(u8, name_lower, "Gatling") != null) {
        return .MachineGun;
    }

    if (std.mem.indexOf(u8, name_lower, "Cannon") != null or
        std.mem.indexOf(u8, name_lower, "Tank") != null) {
        return .Cannon;
    }

    if (std.mem.indexOf(u8, name_lower, "Rocket") != null or
        std.mem.indexOf(u8, name_lower, "Missile") != null) {
        return .Rocket;
    }

    if (std.mem.indexOf(u8, name_lower, "Flame") != null) {
        return .Flamethrower;
    }

    if (std.mem.indexOf(u8, name_lower, "Sniper") != null) {
        return .Sniper;
    }

    // Default based on fire rate
    if (stats.fire_rate < 0.3) {
        return .MachineGun;
    } else if (stats.fire_rate > 2.0) {
        return .Cannon;
    }

    return .Rifle;
}

// Tests
test "WeaponTemplateManager: parse weapon from INI" {
    const test_ini =
        \\Weapon TestRifle
        \\  PrimaryDamage = 15
        \\  AttackRange = 250.0
        \\  DelayBetweenShots = 500
        \\  WeaponSpeed = 600.0
        \\  DamageType = SMALL_ARMS
        \\End
    ;

    var ini = try IniFile.parse(std.testing.allocator, test_ini);
    defer ini.deinit();

    var manager = WeaponTemplateManager.init(std.testing.allocator);
    defer manager.deinit();

    try manager.loadFromIni(&ini);

    const template = manager.getTemplate("TestRifle");
    try std.testing.expect(template != null);

    if (template) |t| {
        try std.testing.expectEqual(@as(f32, 15.0), t.stats.damage);
        try std.testing.expectEqual(@as(f32, 250.0), t.stats.range);
        try std.testing.expectEqual(@as(f32, 0.5), t.stats.fire_rate);
    }
}
