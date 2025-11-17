// C&C Generals - Combat System
// Complete combat implementation with damage, projectiles, and explosions

const std = @import("std");
const weapons = @import("../game_data/weapons.zig");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn distance(self: Vec3, other: Vec3) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn scale(self: Vec3, scalar: f32) Vec3 {
        return Vec3{ .x = self.x * scalar, .y = self.y * scalar, .z = self.z * scalar };
    }

    pub fn normalize(self: Vec3) Vec3 {
        const len = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
        if (len == 0) return Vec3{ .x = 0, .y = 0, .z = 0 };
        return Vec3{ .x = self.x / len, .y = self.y / len, .z = self.z / len };
    }
};

/// Armor type for damage calculations
pub const ArmorType = enum {
    None,
    Light,
    Medium,
    Heavy,
    Building,
    Aircraft,
};

/// Combat entity (unit or building)
pub const CombatEntity = struct {
    id: usize,
    position: Vec3,
    health: f32,
    max_health: f32,
    armor: f32,
    armor_type: ArmorType,
    is_alive: bool,
    owner_id: usize,

    pub fn takeDamage(self: *CombatEntity, damage: f32) void {
        self.health -= damage;
        if (self.health <= 0) {
            self.health = 0;
            self.is_alive = false;
        }
    }

    pub fn heal(self: *CombatEntity, amount: f32) void {
        self.health = @min(self.health + amount, self.max_health);
    }
};

/// Projectile in flight
pub const Projectile = struct {
    id: usize,
    position: Vec3,
    velocity: Vec3,
    weapon_type: []const u8,
    damage: f32,
    damage_type: weapons.DamageType,
    area_of_effect: f32,
    penetration: f32,
    owner_id: usize,
    target_id: ?usize,
    lifetime: f32,
    max_lifetime: f32,
    is_active: bool,
    is_homing: bool,

    pub fn update(self: *Projectile, delta_time: f32) void {
        self.position = self.position.add(self.velocity.scale(delta_time));
        self.lifetime += delta_time;

        if (self.lifetime >= self.max_lifetime) {
            self.is_active = false;
        }
    }
};

/// Explosion effect
pub const Explosion = struct {
    position: Vec3,
    radius: f32,
    damage: f32,
    damage_type: weapons.DamageType,
    owner_id: usize,
    lifetime: f32,
    max_lifetime: f32,
    is_active: bool,

    pub fn update(self: *Explosion, delta_time: f32) void {
        self.lifetime += delta_time;
        if (self.lifetime >= self.max_lifetime) {
            self.is_active = false;
        }
    }
};

/// Damage calculator
pub const DamageCalculator = struct {
    /// Calculate effective damage based on armor and damage type
    pub fn calculateDamage(
        base_damage: f32,
        damage_type: weapons.DamageType,
        armor: f32,
        armor_type: ArmorType,
        penetration: f32,
    ) f32 {
        // Base damage calculation
        var effective_damage = base_damage;

        // Apply armor type modifiers
        const armor_modifier = getArmorModifier(damage_type, armor_type);
        effective_damage *= armor_modifier;

        // Apply armor reduction (penetration reduces effective armor)
        const effective_armor = @max(0, armor - penetration);
        const armor_reduction = effective_armor / (effective_armor + 100.0);
        effective_damage *= (1.0 - armor_reduction);

        return @max(0, effective_damage);
    }

    fn getArmorModifier(damage_type: weapons.DamageType, armor_type: ArmorType) f32 {
        return switch (damage_type) {
            .Small_Arms => switch (armor_type) {
                .None => 1.0,
                .Light => 0.8,
                .Medium => 0.5,
                .Heavy => 0.2,
                .Building => 0.1,
                .Aircraft => 0.6,
            },
            .Anti_Tank => switch (armor_type) {
                .None => 0.5,
                .Light => 0.7,
                .Medium => 1.0,
                .Heavy => 1.5,
                .Building => 1.2,
                .Aircraft => 0.3,
            },
            .Anti_Air => switch (armor_type) {
                .None => 0.3,
                .Light => 0.5,
                .Medium => 0.4,
                .Heavy => 0.2,
                .Building => 0.1,
                .Aircraft => 2.0,
            },
            .Artillery => switch (armor_type) {
                .None => 1.5,
                .Light => 1.2,
                .Medium => 1.0,
                .Heavy => 0.8,
                .Building => 1.5,
                .Aircraft => 0.5,
            },
            .Flame => switch (armor_type) {
                .None => 2.0,
                .Light => 1.5,
                .Medium => 0.8,
                .Heavy => 0.3,
                .Building => 1.2,
                .Aircraft => 0.1,
            },
            .Chemical => switch (armor_type) {
                .None => 2.0,
                .Light => 1.8,
                .Medium => 0.5,
                .Heavy => 0.2,
                .Building => 0.1,
                .Aircraft => 0.1,
            },
            .Nuclear => switch (armor_type) {
                .None => 2.5,
                .Light => 2.5,
                .Medium => 2.5,
                .Heavy => 2.0,
                .Building => 3.0,
                .Aircraft => 2.5,
            },
            .Explosive => switch (armor_type) {
                .None => 1.5,
                .Light => 1.3,
                .Medium => 1.2,
                .Heavy => 1.0,
                .Building => 1.8,
                .Aircraft => 1.0,
            },
            .Laser => switch (armor_type) {
                .None => 1.0,
                .Light => 1.2,
                .Medium => 1.5,
                .Heavy => 1.8,
                .Building => 1.5,
                .Aircraft => 2.0,
            },
        };
    }
};

/// Combat manager
pub const CombatManager = struct {
    allocator: std.mem.Allocator,
    entities: []CombatEntity,
    entity_count: usize,
    projectiles: []Projectile,
    projectile_count: usize,
    explosions: []Explosion,
    explosion_count: usize,
    next_projectile_id: usize,

    pub fn init(allocator: std.mem.Allocator, max_entities: usize) !CombatManager {
        return CombatManager{
            .allocator = allocator,
            .entities = try allocator.alloc(CombatEntity, max_entities),
            .entity_count = 0,
            .projectiles = try allocator.alloc(Projectile, 1000),
            .projectile_count = 0,
            .explosions = try allocator.alloc(Explosion, 500),
            .explosion_count = 0,
            .next_projectile_id = 0,
        };
    }

    pub fn deinit(self: *CombatManager) void {
        self.allocator.free(self.entities);
        self.allocator.free(self.projectiles);
        self.allocator.free(self.explosions);
    }

    /// Add entity to combat system
    pub fn addEntity(self: *CombatManager, entity: CombatEntity) !usize {
        if (self.entity_count >= self.entities.len) return error.TooManyEntities;

        self.entities[self.entity_count] = entity;
        const id = self.entity_count;
        self.entity_count += 1;
        return id;
    }

    /// Fire projectile from attacker to target
    pub fn fireProjectile(
        self: *CombatManager,
        attacker_pos: Vec3,
        target_pos: Vec3,
        weapon_name: []const u8,
        weapon_damage: f32,
        weapon_type: weapons.DamageType,
        projectile_speed: f32,
        aoe: f32,
        penetration: f32,
        owner_id: usize,
        target_id: ?usize,
    ) !void {
        if (self.projectile_count >= self.projectiles.len) return;

        const direction = target_pos.sub(attacker_pos).normalize();
        const velocity = direction.scale(projectile_speed);

        const distance = attacker_pos.distance(target_pos);
        const max_lifetime = if (projectile_speed > 0) distance / projectile_speed + 1.0 else 10.0;

        self.projectiles[self.projectile_count] = Projectile{
            .id = self.next_projectile_id,
            .position = attacker_pos,
            .velocity = velocity,
            .weapon_type = weapon_name,
            .damage = weapon_damage,
            .damage_type = weapon_type,
            .area_of_effect = aoe,
            .penetration = penetration,
            .owner_id = owner_id,
            .target_id = target_id,
            .lifetime = 0,
            .max_lifetime = max_lifetime,
            .is_active = true,
            .is_homing = false,
        };

        self.next_projectile_id += 1;
        self.projectile_count += 1;
    }

    /// Create explosion at position
    pub fn createExplosion(
        self: *CombatManager,
        position: Vec3,
        radius: f32,
        damage: f32,
        damage_type: weapons.DamageType,
        owner_id: usize,
    ) !void {
        if (self.explosion_count >= self.explosions.len) return;

        self.explosions[self.explosion_count] = Explosion{
            .position = position,
            .radius = radius,
            .damage = damage,
            .damage_type = damage_type,
            .owner_id = owner_id,
            .lifetime = 0,
            .max_lifetime = 2.0, // Explosion lasts 2 seconds
            .is_active = true,
        };

        self.explosion_count += 1;

        // Apply damage to all entities in radius
        try self.applyExplosionDamage(position, radius, damage, damage_type, owner_id);
    }

    fn applyExplosionDamage(
        self: *CombatManager,
        position: Vec3,
        radius: f32,
        damage: f32,
        damage_type: weapons.DamageType,
        owner_id: usize,
    ) !void {
        for (self.entities[0..self.entity_count]) |*entity| {
            if (!entity.is_alive) continue;
            if (entity.owner_id == owner_id) continue; // Don't damage own units

            const distance = entity.position.distance(position);
            if (distance > radius) continue;

            // Calculate falloff (full damage at center, 50% at edge)
            const falloff = 1.0 - (distance / radius) * 0.5;
            const effective_damage = DamageCalculator.calculateDamage(
                damage * falloff,
                damage_type,
                entity.armor,
                entity.armor_type,
                0, // Explosions don't have penetration
            );

            entity.takeDamage(effective_damage);
        }
    }

    /// Update combat system
    pub fn update(self: *CombatManager, delta_time: f32) !void {
        // Update projectiles
        var i: usize = 0;
        while (i < self.projectile_count) {
            var proj = &self.projectiles[i];

            if (!proj.is_active) {
                // Remove inactive projectile
                if (i < self.projectile_count - 1) {
                    self.projectiles[i] = self.projectiles[self.projectile_count - 1];
                }
                self.projectile_count -= 1;
                continue;
            }

            proj.update(delta_time);

            // Check for hits
            if (try self.checkProjectileHit(proj)) {
                proj.is_active = false;
            }

            i += 1;
        }

        // Update explosions
        i = 0;
        while (i < self.explosion_count) {
            var explosion = &self.explosions[i];

            if (!explosion.is_active) {
                // Remove inactive explosion
                if (i < self.explosion_count - 1) {
                    self.explosions[i] = self.explosions[self.explosion_count - 1];
                }
                self.explosion_count -= 1;
                continue;
            }

            explosion.update(delta_time);
            i += 1;
        }
    }

    fn checkProjectileHit(self: *CombatManager, proj: *Projectile) !bool {
        const hit_radius: f32 = 2.0; // Collision radius

        for (self.entities[0..self.entity_count]) |*entity| {
            if (!entity.is_alive) continue;
            if (entity.owner_id == proj.owner_id) continue;

            const distance = entity.position.distance(proj.position);
            if (distance <= hit_radius) {
                // Direct hit
                if (proj.area_of_effect > 0) {
                    // Create explosion
                    try self.createExplosion(
                        proj.position,
                        proj.area_of_effect,
                        proj.damage,
                        proj.damage_type,
                        proj.owner_id,
                    );
                } else {
                    // Single target damage
                    const effective_damage = DamageCalculator.calculateDamage(
                        proj.damage,
                        proj.damage_type,
                        entity.armor,
                        entity.armor_type,
                        proj.penetration,
                    );
                    entity.takeDamage(effective_damage);
                }
                return true;
            }
        }

        return false;
    }

    /// Get combat statistics
    pub fn getStats(self: *CombatManager) CombatStats {
        var alive_count: usize = 0;
        var dead_count: usize = 0;

        for (self.entities[0..self.entity_count]) |entity| {
            if (entity.is_alive) {
                alive_count += 1;
            } else {
                dead_count += 1;
            }
        }

        return CombatStats{
            .total_entities = self.entity_count,
            .alive_entities = alive_count,
            .dead_entities = dead_count,
            .active_projectiles = self.projectile_count,
            .active_explosions = self.explosion_count,
        };
    }
};

pub const CombatStats = struct {
    total_entities: usize,
    alive_entities: usize,
    dead_entities: usize,
    active_projectiles: usize,
    active_explosions: usize,
};
