// Projectile System
// Physical projectiles with ballistic trajectories, homing, and collision
// Based on Thyme's projectile system

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Vec3 = math.Vec3(f32);
const Entity = @import("entity.zig").Entity;
const EntityId = @import("entity.zig").EntityId;
const combat = @import("combat.zig");
const DamageType = combat.DamageType;
const WeaponBonus = combat.WeaponBonus;

/// Projectile type
pub const ProjectileType = enum {
    BULLET,          // Instant hit
    BALLISTIC,       // Gravity-affected projectile (tank shells)
    GUIDED_MISSILE,  // Homing missile
    ROCKET,          // Non-homing rocket
    BEAM,            // Laser beam (instant)
    GRENADE,         // Lobbed projectile
};

/// Projectile state
pub const ProjectileState = enum {
    ACTIVE,
    HIT_TARGET,
    HIT_GROUND,
    EXPLODED,
    FIZZLED,  // Missed and despawned
};

/// Projectile data
pub const Projectile = struct {
    id: u32,
    projectile_type: ProjectileType,
    state: ProjectileState,

    // Position and movement
    position: Vec3,
    velocity: Vec3,
    acceleration: Vec3, // For gravity
    speed: f32,
    lifetime: f32,
    max_lifetime: f32,

    // Source and target
    source_entity_id: ?EntityId,
    target_entity_id: ?EntityId,
    target_position: Vec3, // Last known target position

    // Homing properties
    is_homing: bool,
    turn_rate: f32,  // Radians per second
    lock_on_delay: f32,
    time_since_launch: f32,

    // Damage properties
    damage: f32,
    damage_type: DamageType,
    piercing: f32,
    bonus: WeaponBonus,
    explosion_radius: f32,
    friendly_fire: bool,

    // Visual properties
    model_id: u32,
    trail_effect_id: u32,
    impact_effect_id: u32,
    rotation: f32,

    // Physics
    gravity: f32,
    air_resistance: f32,
    bounce_count: u8,
    max_bounces: u8,

    pub fn init(
        id: u32,
        projectile_type: ProjectileType,
        start_pos: Vec3,
        target_pos: Vec3,
        speed: f32,
        damage: f32,
    ) Projectile {
        const direction = target_pos.sub(start_pos).normalize();
        const velocity = direction.scale(speed);

        return .{
            .id = id,
            .projectile_type = projectile_type,
            .state = .ACTIVE,
            .position = start_pos,
            .velocity = velocity,
            .acceleration = Vec3.init(0, 0, 0),
            .speed = speed,
            .lifetime = 0.0,
            .max_lifetime = 10.0,
            .source_entity_id = null,
            .target_entity_id = null,
            .target_position = target_pos,
            .is_homing = false,
            .turn_rate = 0.0,
            .lock_on_delay = 0.0,
            .time_since_launch = 0.0,
            .damage = damage,
            .damage_type = .SMALL_ARMS,
            .piercing = 0.0,
            .bonus = .{},
            .explosion_radius = 0.0,
            .friendly_fire = false,
            .model_id = 0,
            .trail_effect_id = 0,
            .impact_effect_id = 0,
            .rotation = 0.0,
            .gravity = 0.0,
            .air_resistance = 0.0,
            .bounce_count = 0,
            .max_bounces = 0,
        };
    }

    /// Update projectile physics and guidance
    pub fn update(self: *Projectile, dt: f32, entities: []Entity) void {
        if (self.state != .ACTIVE) return;

        self.lifetime += dt;
        self.time_since_launch += dt;

        // Check lifetime
        if (self.lifetime >= self.max_lifetime) {
            self.state = .FIZZLED;
            return;
        }

        // Apply gravity
        if (self.gravity != 0.0) {
            self.acceleration.z -= self.gravity * dt;
        }

        // Apply air resistance
        if (self.air_resistance > 0.0) {
            const drag = self.velocity.scale(self.air_resistance * dt);
            self.velocity = self.velocity.sub(drag);
        }

        // Homing logic
        if (self.is_homing and self.time_since_launch > self.lock_on_delay) {
            if (self.target_entity_id) |target_id| {
                // Find target entity
                for (entities) |*entity| {
                    if (entity.id == target_id and entity.active) {
                        // Update target position
                        self.target_position = Vec3.init(
                            entity.transform.position.x,
                            entity.transform.position.y,
                            0.0, // TODO: Add height
                        );

                        // Calculate direction to target
                        const to_target = self.target_position.sub(self.position);
                        const dist = to_target.length();

                        if (dist > 1.0) {
                            const desired_velocity = to_target.normalize().scale(self.speed);

                            // Turn towards target
                            const turn_amount = self.turn_rate * dt;
                            self.velocity = self.velocity.lerp(desired_velocity, turn_amount);
                            self.velocity = self.velocity.normalize().scale(self.speed);
                        }
                        break;
                    }
                }
            }
        }

        // Apply velocity
        self.velocity = self.velocity.add(self.acceleration.scale(dt));
        self.position = self.position.add(self.velocity.scale(dt));

        // Reset acceleration for next frame
        if (self.gravity == 0.0) {
            self.acceleration = Vec3.init(0, 0, 0);
        }

        // Check ground collision
        if (self.position.z < 0.0) {
            if (self.bounce_count < self.max_bounces) {
                // Bounce
                self.position.z = 0.0;
                self.velocity.z = -self.velocity.z * 0.5; // 50% energy retained
                self.bounce_count += 1;
            } else {
                // Hit ground
                self.position.z = 0.0;
                self.state = .HIT_GROUND;
            }
        }

        // Check entity collisions
        self.checkCollisions(entities);
    }

    /// Check for collisions with entities
    fn checkCollisions(self: *Projectile, entities: []Entity) void {
        for (entities) |*entity| {
            if (!entity.active) continue;

            // Don't hit source entity
            if (self.source_entity_id) |source_id| {
                if (entity.id == source_id) continue;
            }

            // Check distance
            const dx = entity.transform.position.x - self.position.x;
            const dy = entity.transform.position.y - self.position.y;
            const dist_sq = dx * dx + dy * dy;

            // Collision radius (approximate entity size)
            const collision_radius: f32 = 5.0;
            if (dist_sq < collision_radius * collision_radius) {
                // Hit!
                self.state = .HIT_TARGET;
                return;
            }
        }
    }

    /// Create ballistic projectile (tank shell)
    pub fn createBallistic(
        id: u32,
        start_pos: Vec3,
        target_pos: Vec3,
        muzzle_velocity: f32,
        damage: f32,
    ) Projectile {
        var proj = Projectile.init(id, .BALLISTIC, start_pos, target_pos, muzzle_velocity, damage);

        // Calculate ballistic arc
        const dx = target_pos.x - start_pos.x;
        const dy = target_pos.y - start_pos.y;
        const dz = target_pos.z - start_pos.z;
        const ground_dist = @sqrt(dx * dx + dy * dy);

        // Simple ballistic calculation (assumes 45-degree optimal angle)
        const gravity: f32 = 9.8;
        const time_of_flight = ground_dist / muzzle_velocity;
        const initial_z_velocity = (dz + 0.5 * gravity * time_of_flight * time_of_flight) / time_of_flight;

        proj.velocity = Vec3.init(
            dx / time_of_flight,
            dy / time_of_flight,
            initial_z_velocity,
        );
        proj.gravity = gravity;
        proj.max_lifetime = time_of_flight * 1.5; // Add margin

        return proj;
    }

    /// Create guided missile
    pub fn createGuidedMissile(
        id: u32,
        start_pos: Vec3,
        target_entity: EntityId,
        speed: f32,
        turn_rate: f32,
        damage: f32,
    ) Projectile {
        var proj = Projectile.init(id, .GUIDED_MISSILE, start_pos, Vec3.init(0, 0, 0), speed, damage);
        proj.target_entity_id = target_entity;
        proj.is_homing = true;
        proj.turn_rate = turn_rate;
        proj.lock_on_delay = 0.5; // Half second before homing activates
        return proj;
    }
};

/// Projectile manager
pub const ProjectileManager = struct {
    projectiles: std.ArrayList(Projectile),
    next_id: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator) ProjectileManager {
        return .{
            .projectiles = std.ArrayList(Projectile){},
            .next_id = 1,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ProjectileManager) void {
        self.projectiles.deinit(self.allocator);
    }

    /// Spawn a new projectile
    pub fn spawn(self: *ProjectileManager, projectile: Projectile) !u32 {
        const id = self.next_id;
        self.next_id += 1;

        var proj = projectile;
        proj.id = id;

        try self.projectiles.append(self.allocator, proj);
        return id;
    }

    /// Update all projectiles
    pub fn update(self: *ProjectileManager, dt: f32, entities: []Entity) void {
        var i: usize = 0;
        while (i < self.projectiles.items.len) {
            var proj = &self.projectiles.items[i];
            proj.update(dt, entities);

            // Remove inactive projectiles
            if (proj.state != .ACTIVE) {
                _ = self.projectiles.swapRemove(i);
                // Don't increment i, check same index again
            } else {
                i += 1;
            }
        }
    }

    /// Get projectile count
    pub fn getCount(self: *const ProjectileManager) usize {
        return self.projectiles.items.len;
    }

    /// Apply projectile damage to entities
    pub fn applyDamage(
        self: *ProjectileManager,
        proj: *const Projectile,
        entities: []Entity,
        random: *std.Random,
    ) void {
        if (proj.explosion_radius > 0.0) {
            // Area damage
            for (entities) |*entity| {
                if (!entity.active) continue;

                const dx = entity.transform.position.x - proj.position.x;
                const dy = entity.transform.position.y - proj.position.y;
                const dist = @sqrt(dx * dx + dy * dy);

                if (dist <= proj.explosion_radius) {
                    // Calculate falloff
                    const falloff = 1.0 - (dist / proj.explosion_radius);
                    const effective_damage = proj.damage * falloff;

                    // Apply damage (would need particle system reference)
                    if (entity.unit_data) |*unit_data| {
                        unit_data.health -= effective_damage;
                        if (unit_data.health <= 0) {
                            entity.active = false;
                        }
                    }
                }
            }
        } else {
            // Single target damage
            if (proj.target_entity_id) |target_id| {
                for (entities) |*entity| {
                    if (entity.id == target_id and entity.active) {
                        if (entity.unit_data) |*unit_data| {
                            unit_data.health -= proj.damage;
                            if (unit_data.health <= 0) {
                                entity.active = false;
                            }
                        }
                        break;
                    }
                }
            }
        }

        _ = random; // TODO: Use for damage variation
    }
};

// Tests
test "Projectile: basic initialization" {
    const start = Vec3.init(0, 0, 0);
    const target = Vec3.init(100, 100, 0);
    const proj = Projectile.init(1, .BULLET, start, target, 500.0, 50.0);

    try std.testing.expectEqual(@as(u32, 1), proj.id);
    try std.testing.expectEqual(ProjectileType.BULLET, proj.projectile_type);
    try std.testing.expectEqual(ProjectileState.ACTIVE, proj.state);
}

test "ProjectileManager: spawn and update" {
    var manager = ProjectileManager.init(std.testing.allocator);
    defer manager.deinit();

    const start = Vec3.init(0, 0, 0);
    const target = Vec3.init(100, 0, 0);
    const proj = Projectile.init(1, .BULLET, start, target, 100.0, 50.0);

    _ = try manager.spawn(proj);
    try std.testing.expectEqual(@as(usize, 1), manager.getCount());

    var entities: [0]Entity = .{};
    manager.update(0.1, &entities);

    // Projectile should have moved
    if (manager.projectiles.items.len > 0) {
        const moved_proj = &manager.projectiles.items[0];
        try std.testing.expect(moved_proj.position.x > 0);
    }
}
