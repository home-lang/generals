// Generals Game Engine - Combat System
// Unit combat, damage, and death handling
// Phase 2.1 & 2.2: Enhanced weapon and armor systems

const std = @import("std");
const Entity = @import("entity.zig").Entity;
const ParticleSystem = @import("../renderer/particle_system.zig").ParticleSystem;
const spawnExplosion = @import("../renderer/particle_system.zig").spawnExplosion;
const spawnSmoke = @import("../renderer/particle_system.zig").spawnSmoke;

// ============================================================================
// Phase 2.1: Damage Types
// ============================================================================

/// Damage types matching C&C Generals (from Thyme weapon.h)
pub const DamageType = enum {
    ARMOR_PIERCING,  // Anti-tank rounds
    HOLLOW_POINT,    // Anti-infantry rounds
    SMALL_ARMS,      // Infantry weapons
    EXPLOSION,       // Explosives and artillery
    FIRE,            // Flame weapons
    LASER,           // Laser weapons (Particle Cannon)
    POISON,          // Chemical weapons (Toxin Tractor)
    SNIPER,          // Sniper rifles
    STRUCTURE,       // Building damage
    RADIATION,       // Nuclear damage
};

// ============================================================================
// Phase 2.2: Armor System
// ============================================================================

/// Armor types matching C&C Generals (from Thyme armorset.cpp)
pub const ArmorType = enum {
    NONE,              // Unarmored
    INFANTRY,          // Soldiers
    INFANTRY_HERO,     // Black Lotus, Colonel Burton
    VEHICLE_LIGHT,     // Humvees, Technicals
    VEHICLE_MEDIUM,    // Crusader tanks, Battlemaster
    VEHICLE_HEAVY,     // Overlord tanks
    AIRCRAFT,          // Planes and helicopters
    BUILDING,          // Structures
    STRUCTURE_HEAVY,   // Bunkers, Command Centers
};

/// Armor effectiveness against damage types (% damage taken)
/// From C&C Generals Armor.ini
pub const ArmorMultipliers = struct {
    pub fn getMultiplier(armor: ArmorType, damage: DamageType) f32 {
        return switch (armor) {
            .NONE => switch (damage) {
                .ARMOR_PIERCING => 1.0,
                .HOLLOW_POINT => 1.5,
                .SMALL_ARMS => 1.0,
                .EXPLOSION => 1.0,
                .FIRE => 1.0,
                .LASER => 1.0,
                .POISON => 1.5,
                .SNIPER => 2.0,
                .STRUCTURE => 1.0,
                .RADIATION => 1.0,
            },
            .INFANTRY => switch (damage) {
                .ARMOR_PIERCING => 0.5,
                .HOLLOW_POINT => 1.5,
                .SMALL_ARMS => 1.0,
                .EXPLOSION => 1.2,
                .FIRE => 1.5,
                .LASER => 0.8,
                .POISON => 2.0,
                .SNIPER => 1.5,
                .STRUCTURE => 0.5,
                .RADIATION => 1.5,
            },
            .INFANTRY_HERO => switch (damage) {
                .ARMOR_PIERCING => 0.3,
                .HOLLOW_POINT => 1.0,
                .SMALL_ARMS => 0.7,
                .EXPLOSION => 0.8,
                .FIRE => 1.0,
                .LASER => 0.6,
                .POISON => 0.5,
                .SNIPER => 1.2,
                .STRUCTURE => 0.3,
                .RADIATION => 1.0,
            },
            .VEHICLE_LIGHT => switch (damage) {
                .ARMOR_PIERCING => 1.5,
                .HOLLOW_POINT => 0.3,
                .SMALL_ARMS => 0.5,
                .EXPLOSION => 1.2,
                .FIRE => 0.8,
                .LASER => 1.0,
                .POISON => 0.0,
                .SNIPER => 0.5,
                .STRUCTURE => 0.8,
                .RADIATION => 1.0,
            },
            .VEHICLE_MEDIUM => switch (damage) {
                .ARMOR_PIERCING => 1.0,
                .HOLLOW_POINT => 0.1,
                .SMALL_ARMS => 0.25,
                .EXPLOSION => 1.0,
                .FIRE => 0.6,
                .LASER => 1.2,
                .POISON => 0.0,
                .SNIPER => 0.3,
                .STRUCTURE => 0.9,
                .RADIATION => 1.0,
            },
            .VEHICLE_HEAVY => switch (damage) {
                .ARMOR_PIERCING => 0.8,
                .HOLLOW_POINT => 0.05,
                .SMALL_ARMS => 0.1,
                .EXPLOSION => 0.9,
                .FIRE => 0.4,
                .LASER => 1.5,
                .POISON => 0.0,
                .SNIPER => 0.2,
                .STRUCTURE => 1.0,
                .RADIATION => 1.0,
            },
            .AIRCRAFT => switch (damage) {
                .ARMOR_PIERCING => 0.6,
                .HOLLOW_POINT => 0.2,
                .SMALL_ARMS => 0.4,
                .EXPLOSION => 1.5,
                .FIRE => 0.8,
                .LASER => 1.2,
                .POISON => 0.0,
                .SNIPER => 0.3,
                .STRUCTURE => 0.5,
                .RADIATION => 1.0,
            },
            .BUILDING => switch (damage) {
                .ARMOR_PIERCING => 0.5,
                .HOLLOW_POINT => 0.1,
                .SMALL_ARMS => 0.05,
                .EXPLOSION => 1.5,
                .FIRE => 1.2,
                .LASER => 1.0,
                .POISON => 0.0,
                .SNIPER => 0.1,
                .STRUCTURE => 1.0,
                .RADIATION => 1.2,
            },
            .STRUCTURE_HEAVY => switch (damage) {
                .ARMOR_PIERCING => 0.3,
                .HOLLOW_POINT => 0.05,
                .SMALL_ARMS => 0.02,
                .EXPLOSION => 1.0,
                .FIRE => 0.8,
                .LASER => 0.9,
                .POISON => 0.0,
                .SNIPER => 0.05,
                .STRUCTURE => 1.2,
                .RADIATION => 1.0,
            },
        };
    }
};

/// Weapon types
pub const WeaponType = enum {
    Rifle,
    MachineGun,
    Cannon,
    Rocket,
    Flamethrower,
    Sniper,
};

// ============================================================================
// Phase 2.1: Weapon Bonus System (from Thyme)
// ============================================================================

/// Weapon bonus conditions matching Thyme's WeaponBonusConditionType
pub const WeaponBonusCondition = enum(u5) {
    GARRISONED = 0,
    HORDE = 1,
    VETERAN = 2,
    ELITE = 3,
    HERO = 4,
    NATIONALISM = 5,
    PLAYER_UPGRADE = 6,
    DRONE_SPOTTING = 7,
    ENTHUSIASTIC = 8,
    FANATICISM = 9,
    FRENZY_ONE = 10,
    FRENZY_TWO = 11,
    FRENZY_THREE = 12,
};

/// Weapon bonus fields that can be modified
pub const WeaponBonusField = enum {
    DAMAGE,
    RADIUS,
    RANGE,
    RATE_OF_FIRE,
    PRE_ATTACK,
};

/// Weapon bonus set (multipliers for each field)
/// Based on Thyme's WeaponBonus class
pub const WeaponBonus = struct {
    damage_mult: f32 = 1.0,
    radius_mult: f32 = 1.0,
    range_mult: f32 = 1.0,
    rate_of_fire_mult: f32 = 1.0,
    pre_attack_mult: f32 = 1.0,

    pub fn apply(self: WeaponBonus, base_damage: f32, base_range: f32, base_rate: f32) struct {
        damage: f32,
        range: f32,
        rate: f32,
    } {
        return .{
            .damage = base_damage * self.damage_mult,
            .range = base_range * self.range_mult,
            .rate = base_rate * self.rate_of_fire_mult,
        };
    }

    /// Veteran bonus: +25% damage (from Thyme)
    pub fn veteran() WeaponBonus {
        return .{ .damage_mult = 1.25 };
    }

    /// Elite bonus: +50% damage (from Thyme)
    pub fn elite() WeaponBonus {
        return .{ .damage_mult = 1.50 };
    }

    /// Hero bonus: +75% damage (from Thyme)
    pub fn hero() WeaponBonus {
        return .{ .damage_mult = 1.75 };
    }

    /// Horde bonus: +25% damage when near allies (from Thyme)
    pub fn horde() WeaponBonus {
        return .{ .damage_mult = 1.25 };
    }
};

/// Anti-type flags (what this weapon is effective against)
/// From Thyme's WeaponAntiType
pub const AntiMask = packed struct(u8) {
    airborne_vehicle: bool = false,  // ANTI_AIRBORNE_VEHICLE
    ground: bool = false,            // ANTI_GROUND
    projectile: bool = false,        // ANTI_PROJECTILE
    small_missile: bool = false,     // ANTI_SMALL_MISSILE
    mine: bool = false,              // ANTI_MINE
    airborne_infantry: bool = false, // ANTI_AIRBORNE_INFANTRY
    ballistic_missile: bool = false, // ANTI_BALLISTIC_MISSILE
    parachute: bool = false,         // ANTI_PARACHUTE

    pub fn canTargetGround(self: AntiMask) bool {
        return self.ground;
    }

    pub fn canTargetAir(self: AntiMask) bool {
        return self.airborne_vehicle or self.airborne_infantry;
    }
};

/// Weapon stats enhanced with Phase 2 features
pub const WeaponStats = struct {
    // Basic stats
    damage: f32,
    range: f32,
    fire_rate: f32, // Seconds between shots
    projectile_speed: f32,
    area_of_effect: f32, // 0 = single target
    weapon_type: WeaponType,

    // Phase 2.1: Enhanced properties (from Thyme)
    damage_type: DamageType = .SMALL_ARMS,
    anti_mask: AntiMask = .{ .ground = true },
    clip_size: u32 = 0,            // 0 = infinite ammo
    clip_reload_time: f32 = 0.0,   // Reload time in seconds
    min_range: f32 = 0.0,          // Minimum attack range
    scatter_radius: f32 = 0.0,     // Weapon scatter (inaccuracy)
    piercing: f32 = 0.0,           // Armor penetration bonus

    pub fn rifle() WeaponStats {
        return .{
            .damage = 10.0,
            .range = 200.0,
            .fire_rate = 0.5,
            .projectile_speed = 500.0,
            .area_of_effect = 0.0,
            .weapon_type = .Rifle,
            .damage_type = .SMALL_ARMS,
            .anti_mask = .{ .ground = true },
            .clip_size = 30,
            .clip_reload_time = 2.0,
            .scatter_radius = 5.0,
        };
    }

    pub fn machineGun() WeaponStats {
        return .{
            .damage = 5.0,
            .range = 250.0,
            .fire_rate = 0.1,
            .projectile_speed = 600.0,
            .area_of_effect = 0.0,
            .weapon_type = .MachineGun,
            .damage_type = .SMALL_ARMS,
            .anti_mask = .{ .ground = true, .airborne_infantry = true },
            .clip_size = 100,
            .clip_reload_time = 3.0,
            .scatter_radius = 10.0,
        };
    }

    pub fn cannon() WeaponStats {
        return .{
            .damage = 50.0,
            .range = 300.0,
            .fire_rate = 2.0,
            .projectile_speed = 400.0,
            .area_of_effect = 30.0,
            .weapon_type = .Cannon,
            .damage_type = .ARMOR_PIERCING,
            .anti_mask = .{ .ground = true },
            .clip_size = 0, // Infinite
            .piercing = 25.0,
        };
    }

    pub fn rocket() WeaponStats {
        return .{
            .damage = 75.0,
            .range = 400.0,
            .fire_rate = 3.0,
            .projectile_speed = 300.0,
            .area_of_effect = 50.0,
            .weapon_type = .Rocket,
            .damage_type = .EXPLOSION,
            .anti_mask = .{ .ground = true, .airborne_vehicle = true },
            .clip_size = 8,
            .clip_reload_time = 5.0,
        };
    }
};

// ============================================================================
// Phase 2.2: Advanced Damage Calculation (from Thyme)
// ============================================================================

/// Calculate effective damage with armor, pierce, and bonuses
/// Based on Thyme's damage calculation system
pub const DamageCalculator = struct {
    /// Calculate final damage dealt (Phase 2.2 enhanced)
    /// Implements Thyme's damage formula:
    /// damage = base_damage * bonus_mult * armor_mult * (1 + pierce_bonus) * random(0.9, 1.1)
    pub fn calculateDamage(
        base_damage: f32,
        damage_type: DamageType,
        armor_type: ArmorType,
        piercing: f32,
        bonus: WeaponBonus,
        random: *std.Random,
    ) f32 {
        // Apply weapon bonus
        var damage = base_damage * bonus.damage_mult;

        // Apply armor multiplier
        const armor_mult = ArmorMultipliers.getMultiplier(armor_type, damage_type);
        damage *= armor_mult;

        // Apply piercing (reduces armor effectiveness)
        // Piercing reduces armor by a percentage
        // Example: 25% pierce vs 50% armor resist = 37.5% effective resist
        if (piercing > 0.0) {
            const pierce_factor = piercing / 100.0; // Convert to decimal
            const armor_reduction = armor_mult - 1.0; // Negative = resist, positive = vulnerable
            if (armor_reduction < 0.0) { // Only apply pierce to resistance
                const reduced_armor = armor_reduction * (1.0 - pierce_factor);
                damage = base_damage * bonus.damage_mult * (1.0 + reduced_armor);
            }
        }

        // Random variation ±10% (from Thyme)
        const random_mult = 0.9 + random.float(f32) * 0.2; // 0.9 to 1.1
        damage *= random_mult;

        // Critical hit: 5% chance for 2x damage (from C&C Generals)
        if (random.float(f32) < 0.05) {
            damage *= 2.0;
        }

        return damage;
    }

    /// Check if attack should hit based on scatter (weapon inaccuracy)
    pub fn shouldHit(scatter_radius: f32, distance_to_target: f32, random: *std.rand.Random) bool {
        if (scatter_radius <= 0.0) return true;

        // Scatter increases with distance
        const effective_scatter = scatter_radius * (1.0 + distance_to_target / 100.0);

        // Roll for hit
        const scatter_roll = random.float(f32) * effective_scatter;
        return scatter_roll < scatter_radius;
    }
};

/// Combat component for entities
pub const CombatComponent = struct {
    weapon: WeaponStats,
    cooldown: f32,
    target_id: ?u32,
    aggressive: bool, // Auto-attack enemies in range

    pub fn init(weapon: WeaponStats) CombatComponent {
        return .{
            .weapon = weapon,
            .cooldown = 0.0,
            .target_id = null,
            .aggressive = true,
        };
    }

    pub fn canFire(self: *const CombatComponent) bool {
        return self.cooldown <= 0.0;
    }

    pub fn fire(self: *CombatComponent) void {
        self.cooldown = self.weapon.fire_rate;
    }

    pub fn update(self: *CombatComponent, dt: f32) void {
        if (self.cooldown > 0.0) {
            self.cooldown -= dt;
            if (self.cooldown < 0.0) {
                self.cooldown = 0.0;
            }
        }
    }
};

/// Combat system
pub const CombatSystem = struct {
    /// Find nearest enemy within range
    pub fn findNearestEnemy(entities: []Entity, source_entity: *const Entity, max_range: f32) ?u32 {
        var nearest_id: ?u32 = null;
        var nearest_dist: f32 = max_range;

        for (entities) |*target| {
            if (!target.active) continue;
            if (target.id == source_entity.id) continue;
            if (target.team == source_entity.team) continue;
            if (target.unit_data == null) continue;

            const dx = target.transform.position.x - source_entity.transform.position.x;
            const dy = target.transform.position.y - source_entity.transform.position.y;
            const dist = @sqrt(dx * dx + dy * dy);

            if (dist < nearest_dist) {
                nearest_dist = dist;
                nearest_id = target.id;
            }
        }

        return nearest_id;
    }

    /// Apply damage to entity (Phase 2.2 enhanced with armor system)
    pub fn applyDamage(
        entity: *Entity,
        base_damage: f32,
        damage_type: DamageType,
        piercing: f32,
        bonus: WeaponBonus,
        particle_system: *ParticleSystem,
        random: *std.Random,
    ) void {
        if (entity.unit_data) |*unit_data| {
            // Determine armor type (default to INFANTRY for now)
            // TODO: Add armor_type field to UnitData
            const armor_type: ArmorType = .INFANTRY;

            // Calculate effective damage using Phase 2.2 system
            const effective_damage = DamageCalculator.calculateDamage(
                base_damage,
                damage_type,
                armor_type,
                piercing,
                bonus,
                random,
            );

            unit_data.health -= effective_damage;

            // Spawn damage effect
            spawnSmoke(particle_system, entity.transform.position.x, entity.transform.position.y) catch {};

            // Check if unit died
            if (unit_data.health <= 0.0) {
                unit_data.health = 0.0;
                entity.active = false;

                // Spawn death explosion
                spawnExplosion(particle_system, entity.transform.position.x, entity.transform.position.y) catch {};
            }
        }
    }

    /// Legacy function for compatibility - uses default armor/bonus
    pub fn applyDamageSimple(entity: *Entity, damage: f32, particle_system: *ParticleSystem) void {
        var prng = std.Random.DefaultPrng.init(0);
        var random = prng.random();
        applyDamage(
            entity,
            damage,
            .SMALL_ARMS,
            0.0,
            .{},
            particle_system,
            &random,
        );
    }

    /// Process combat for all entities using existing UnitData
    pub fn updateCombat(
        entities: []Entity,
        particle_system: *ParticleSystem,
        dt: f32,
    ) void {
        // Update attack cooldowns
        for (entities) |*entity| {
            if (!entity.active) continue;
            if (entity.unit_data) |*unit_data| {
                unit_data.time_since_attack += dt;
            }
        }

        // Process attacks
        for (entities) |*entity| {
            if (!entity.active) continue;
            var unit_data = &(entity.unit_data orelse continue);

            // Find target if no current target and AI controlled
            if (unit_data.is_ai_controlled and unit_data.target_id == null) {
                unit_data.target_id = findNearestEnemy(entities, entity, unit_data.attack_range);
                if (unit_data.target_id != null) {
                    unit_data.ai_state = .attacking;
                }
            }

            // Validate current target
            if (unit_data.target_id) |target_id| {
                var target_valid = false;
                var target_entity: ?*Entity = null;

                for (entities) |*e| {
                    if (e.id == target_id and e.active) {
                        target_entity = e;

                        // Check range
                        const dx = e.transform.position.x - entity.transform.position.x;
                        const dy = e.transform.position.y - entity.transform.position.y;
                        const dist = @sqrt(dx * dx + dy * dy);

                        if (dist <= unit_data.attack_range) {
                            target_valid = true;
                        }
                        break;
                    }
                }

                if (!target_valid) {
                    unit_data.target_id = null;
                    if (unit_data.is_ai_controlled) {
                        unit_data.ai_state = .idle;
                    }
                } else if (unit_data.canAttack() and target_entity != null) {
                    // Fire at target
                    unit_data.resetAttackTimer();
                    applyDamageSimple(target_entity.?, unit_data.attack_damage, particle_system);
                }
            }
        }
    }
};

/// Unit behavior states
pub const UnitBehavior = enum {
    Idle,
    Move,
    Attack,
    Patrol,
    Guard,
    Follow,
};

/// Behavior component
pub const BehaviorComponent = struct {
    state: UnitBehavior,
    patrol_points: [4]@Vector(2, f32),
    patrol_count: u8,
    patrol_index: u8,
    guard_position: @Vector(2, f32),
    follow_target_id: ?u32,

    pub fn init() BehaviorComponent {
        return .{
            .state = .Idle,
            .patrol_points = [_]@Vector(2, f32){
                @Vector(2, f32){ 0, 0 },
                @Vector(2, f32){ 0, 0 },
                @Vector(2, f32){ 0, 0 },
                @Vector(2, f32){ 0, 0 },
            },
            .patrol_count = 0,
            .patrol_index = 0,
            .guard_position = @Vector(2, f32){ 0, 0 },
            .follow_target_id = null,
        };
    }

    pub fn setPatrol(self: *BehaviorComponent, points: []const @Vector(2, f32)) void {
        self.state = .Patrol;
        self.patrol_count = @min(points.len, 4);
        for (points, 0..) |point, i| {
            if (i >= 4) break;
            self.patrol_points[i] = point;
        }
        self.patrol_index = 0;
    }

    pub fn setGuard(self: *BehaviorComponent, position: @Vector(2, f32)) void {
        self.state = .Guard;
        self.guard_position = position;
    }

    pub fn setFollow(self: *BehaviorComponent, target_id: u32) void {
        self.state = .Follow;
        self.follow_target_id = target_id;
    }
};
