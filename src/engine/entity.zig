// Entity Component System for Generals RTS
// Manages units, buildings, and other game entities

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Path = @import("pathfinding.zig").Path;
const ProductionQueue = @import("production.zig").ProductionQueue;

/// Entity ID - unique identifier for each entity
pub const EntityId = u32;

/// Team ID - for identifying allies/enemies
pub const TeamId = u8;

/// Entity type
pub const EntityType = enum {
    unit,
    building,
    projectile,
    effect,
};

/// Transform component - position, rotation, scale
pub const Transform = struct {
    position: Vec2,
    rotation: f32, // Radians
    scale: f32,

    pub fn init(x: f32, y: f32) Transform {
        return .{
            .position = Vec2.init(x, y),
            .rotation = 0.0,
            .scale = 1.0,
        };
    }

    pub fn initFull(x: f32, y: f32, rotation: f32, scale: f32) Transform {
        return .{
            .position = Vec2.init(x, y),
            .rotation = rotation,
            .scale = scale,
        };
    }
};

/// Sprite component - visual representation
pub const Sprite = struct {
    texture_id: u32, // Index into texture atlas or texture array
    width: f32,
    height: f32,
    // UV coordinates for texture atlas (normalized 0-1)
    uv_min: Vec2,
    uv_max: Vec2,

    pub fn init(texture_id: u32, width: f32, height: f32) Sprite {
        return .{
            .texture_id = texture_id,
            .width = width,
            .height = height,
            .uv_min = Vec2.init(0, 0),
            .uv_max = Vec2.init(1, 1),
        };
    }

    pub fn initAtlas(texture_id: u32, width: f32, height: f32, uv_min: Vec2, uv_max: Vec2) Sprite {
        return .{
            .texture_id = texture_id,
            .width = width,
            .height = height,
            .uv_min = uv_min,
            .uv_max = uv_max,
        };
    }
};

/// AI State for units
pub const AIState = enum {
    idle,       // Standing still, scanning for enemies
    attacking,  // Currently engaged in combat
    chasing,    // Moving toward an enemy
    fleeing,    // Running away (low health)
    player_controlled, // Under player control
};

/// Unit component - unit-specific data
pub const UnitData = struct {
    unit_type: []const u8, // e.g. "AmericaTankCrusader"
    health: f32,
    max_health: f32,
    speed: f32,
    selected: bool,
    // Combat stats
    attack_damage: f32,
    attack_range: f32,
    attack_cooldown: f32, // Seconds between attacks
    time_since_attack: f32, // Accumulator
    target_id: ?EntityId, // Current attack target
    // AI
    ai_state: AIState,
    is_ai_controlled: bool, // If false, player controls this unit

    pub fn init(unit_type: []const u8, max_health: f32, speed: f32) UnitData {
        return .{
            .unit_type = unit_type,
            .health = max_health,
            .max_health = max_health,
            .speed = speed,
            .selected = false,
            .attack_damage = 10.0, // Default damage
            .attack_range = 150.0, // Default range
            .attack_cooldown = 1.0, // 1 second between attacks
            .time_since_attack = 0.0,
            .target_id = null,
            .ai_state = .idle,
            .is_ai_controlled = true, // AI by default
        };
    }

    pub fn canAttack(self: *const UnitData) bool {
        return self.time_since_attack >= self.attack_cooldown;
    }

    pub fn resetAttackTimer(self: *UnitData) void {
        self.time_since_attack = 0.0;
    }
};

/// Building component - building-specific data
pub const BuildingData = struct {
    building_type: []const u8,
    health: f32,
    max_health: f32,
    construction_progress: f32, // 0.0 to 1.0
    production_queue: ?ProductionQueue, // null if building can't produce

    pub fn init(building_type: []const u8, max_health: f32) BuildingData {
        return .{
            .building_type = building_type,
            .health = max_health,
            .max_health = max_health,
            .construction_progress = 1.0,
            .production_queue = null,
        };
    }

    pub fn initWithProduction(allocator: Allocator, building_type: []const u8, max_health: f32) !BuildingData {
        return .{
            .building_type = building_type,
            .health = max_health,
            .max_health = max_health,
            .construction_progress = 1.0,
            .production_queue = try ProductionQueue.init(allocator, 5),
        };
    }

    pub fn deinit(self: *BuildingData) void {
        if (self.production_queue) |*queue| {
            queue.deinit();
        }
    }
};

/// Movement component - handles unit movement along a path
pub const Movement = struct {
    path: ?Path,
    move_speed: f32, // Units per second
    is_moving: bool,

    pub fn init(move_speed: f32) Movement {
        return .{
            .path = null,
            .move_speed = move_speed,
            .is_moving = false,
        };
    }

    pub fn deinit(self: *Movement) void {
        if (self.path) |*path| {
            path.deinit();
        }
    }

    pub fn setPath(self: *Movement, path: Path) void {
        // Clean up old path
        if (self.path) |*old_path| {
            old_path.deinit();
        }
        self.path = path;
        self.is_moving = !path.isEmpty();
    }

    pub fn stopMoving(self: *Movement) void {
        if (self.path) |*path| {
            path.deinit();
        }
        self.path = null;
        self.is_moving = false;
    }
};

/// Entity - combines components
pub const Entity = struct {
    id: EntityId,
    entity_type: EntityType,
    team: TeamId,
    transform: Transform,
    sprite: ?Sprite,
    unit_data: ?UnitData,
    building_data: ?BuildingData,
    movement: ?Movement,
    active: bool,

    pub fn createUnit(id: EntityId, x: f32, y: f32, unit_type: []const u8, sprite: Sprite, team: TeamId) Entity {
        return .{
            .id = id,
            .entity_type = .unit,
            .team = team,
            .transform = Transform.init(x, y),
            .sprite = sprite,
            .unit_data = UnitData.init(unit_type, 100.0, 50.0),
            .building_data = null,
            .movement = Movement.init(100.0), // Default movement speed
            .active = true,
        };
    }

    pub fn createBuilding(id: EntityId, x: f32, y: f32, building_type: []const u8, sprite: Sprite, team: TeamId) Entity {
        return .{
            .id = id,
            .entity_type = .building,
            .team = team,
            .transform = Transform.init(x, y),
            .sprite = sprite,
            .unit_data = null,
            .building_data = BuildingData.init(building_type, 500.0),
            .movement = null, // Buildings don't move
            .active = true,
        };
    }

    pub fn deinit(self: *Entity) void {
        if (self.movement) |*movement| {
            movement.deinit();
        }
        if (self.building_data) |*building_data| {
            building_data.deinit();
        }
    }
};

/// Entity Manager - manages all entities in the game
pub const EntityManager = struct {
    allocator: Allocator,
    entities: std.ArrayList(Entity),
    next_id: EntityId,

    pub fn init(allocator: Allocator) !EntityManager {
        return .{
            .allocator = allocator,
            .entities = try std.ArrayList(Entity).initCapacity(allocator, 0),
            .next_id = 1,
        };
    }

    /// Create a new unit entity
    pub fn createUnit(self: *EntityManager, x: f32, y: f32, unit_type: []const u8, sprite: Sprite, team: TeamId) !EntityId {
        const id = self.next_id;
        self.next_id += 1;

        const entity = Entity.createUnit(id, x, y, unit_type, sprite, team);
        try self.entities.append(self.allocator, entity);

        return id;
    }

    /// Create a new building entity
    pub fn createBuilding(self: *EntityManager, x: f32, y: f32, building_type: []const u8, sprite: Sprite, team: TeamId) !EntityId {
        const id = self.next_id;
        self.next_id += 1;

        const entity = Entity.createBuilding(id, x, y, building_type, sprite, team);
        try self.entities.append(self.allocator, entity);

        return id;
    }

    /// Get entity by ID
    pub fn getEntity(self: *EntityManager, id: EntityId) ?*Entity {
        for (self.entities.items) |*entity| {
            if (entity.id == id and entity.active) {
                return entity;
            }
        }
        return null;
    }

    /// Remove entity
    pub fn removeEntity(self: *EntityManager, id: EntityId) void {
        for (self.entities.items) |*entity| {
            if (entity.id == id) {
                entity.active = false;
                return;
            }
        }
    }

    /// Get all active entities
    pub fn getActiveEntities(self: *EntityManager) []Entity {
        // Filter out inactive entities (in a real implementation, we'd compact the array periodically)
        return self.entities.items;
    }

    /// Get entity count
    pub fn getEntityCount(self: *EntityManager) usize {
        var count: usize = 0;
        for (self.entities.items) |entity| {
            if (entity.active) count += 1;
        }
        return count;
    }

    /// Select unit at world position (click selection)
    pub fn selectUnitAt(self: *EntityManager, world_pos: Vec2, radius: f32) ?EntityId {
        for (self.entities.items) |*entity| {
            if (!entity.active) continue;
            if (entity.entity_type != .unit) continue;

            // Check if click is within entity bounds
            const dx = entity.transform.position.x - world_pos.x;
            const dy = entity.transform.position.y - world_pos.y;
            const dist_sq = dx * dx + dy * dy;

            if (dist_sq <= radius * radius) {
                // Deselect all other units first
                for (self.entities.items) |*e| {
                    if (e.unit_data) |*unit_data| {
                        unit_data.selected = false;
                    }
                }

                // Select this unit
                if (entity.unit_data) |*unit_data| {
                    unit_data.selected = true;
                }

                return entity.id;
            }
        }

        // No unit found, deselect all
        for (self.entities.items) |*entity| {
            if (entity.unit_data) |*unit_data| {
                unit_data.selected = false;
            }
        }

        return null;
    }

    /// Find nearest enemy unit within range
    fn findNearestEnemy(self: *EntityManager, attacker_id: EntityId, attacker_team: TeamId, position: Vec2, max_range: f32) ?EntityId {
        var nearest_id: ?EntityId = null;
        var nearest_dist_sq: f32 = max_range * max_range;

        for (self.entities.items) |*entity| {
            if (!entity.active) continue;
            if (entity.id == attacker_id) continue; // Don't target self
            if (entity.entity_type != .unit) continue; // Only attack units for now
            if (entity.team == attacker_team) continue; // Don't attack allies

            const dx = entity.transform.position.x - position.x;
            const dy = entity.transform.position.y - position.y;
            const dist_sq = dx * dx + dy * dy;

            if (dist_sq < nearest_dist_sq) {
                nearest_dist_sq = dist_sq;
                nearest_id = entity.id;
            }
        }

        return nearest_id;
    }

    /// Deal damage to an entity
    fn damageEntity(self: *EntityManager, entity_id: EntityId, damage: f32) void {
        for (self.entities.items) |*entity| {
            if (entity.id == entity_id and entity.active) {
                if (entity.unit_data) |*unit_data| {
                    unit_data.health -= damage;
                    if (unit_data.health <= 0) {
                        // Unit destroyed
                        entity.active = false;
                        std.debug.print("Unit {} destroyed!\n", .{entity_id});
                    }
                }
                break;
            }
        }
    }

    /// Update all entities
    pub fn update(self: *EntityManager, dt: f64) void {
        const dt_f32 = @as(f32, @floatCast(dt));

        for (self.entities.items) |*entity| {
            if (!entity.active) continue;

            // Update AI and combat for units
            if (entity.unit_data) |*unit_data| {
                // Update attack cooldown
                unit_data.time_since_attack += dt_f32;

                // AI behavior (only for AI-controlled units)
                if (unit_data.is_ai_controlled) {
                    // Check health for flee behavior
                    const health_pct = unit_data.health / unit_data.max_health;

                    // Find nearest enemy for awareness
                    const nearest_enemy = self.findNearestEnemy(entity.id, entity.team, entity.transform.position, unit_data.attack_range * 2.0);

                    // State machine
                    switch (unit_data.ai_state) {
                        .idle => {
                            // Scan for enemies
                            if (nearest_enemy != null) {
                                unit_data.ai_state = .chasing;
                                unit_data.target_id = nearest_enemy;
                            }
                        },
                        .chasing => {
                            // If low health, flee
                            if (health_pct < 0.3) {
                                unit_data.ai_state = .fleeing;
                                unit_data.target_id = null;
                            }
                            // If enemy in attack range, switch to attacking
                            else if (unit_data.target_id != null) {
                                var in_attack_range = false;
                                for (self.entities.items) |*target| {
                                    if (target.id == unit_data.target_id.? and target.active) {
                                        const dx = target.transform.position.x - entity.transform.position.x;
                                        const dy = target.transform.position.y - entity.transform.position.y;
                                        const dist_sq = dx * dx + dy * dy;
                                        if (dist_sq <= unit_data.attack_range * unit_data.attack_range) {
                                            in_attack_range = true;
                                            unit_data.ai_state = .attacking;
                                        }
                                        break;
                                    }
                                }
                                // Target lost, return to idle
                                if (!in_attack_range and nearest_enemy == null) {
                                    unit_data.ai_state = .idle;
                                    unit_data.target_id = null;
                                }
                            }
                        },
                        .attacking => {
                            // If low health, flee
                            if (health_pct < 0.3) {
                                unit_data.ai_state = .fleeing;
                                unit_data.target_id = null;
                            }
                            // If target out of range, chase
                            else if (unit_data.target_id != null) {
                                var still_in_range = false;
                                for (self.entities.items) |*target| {
                                    if (target.id == unit_data.target_id.? and target.active) {
                                        const dx = target.transform.position.x - entity.transform.position.x;
                                        const dy = target.transform.position.y - entity.transform.position.y;
                                        const dist_sq = dx * dx + dy * dy;
                                        if (dist_sq <= unit_data.attack_range * unit_data.attack_range) {
                                            still_in_range = true;
                                        }
                                        break;
                                    }
                                }
                                if (!still_in_range) {
                                    unit_data.ai_state = .chasing;
                                }
                            } else {
                                unit_data.ai_state = .idle;
                            }
                        },
                        .fleeing => {
                            // If health recovered, return to idle
                            if (health_pct > 0.5) {
                                unit_data.ai_state = .idle;
                            }
                        },
                        .player_controlled => {
                            // Player controls this unit, no AI
                        },
                    }
                }

                // Find target if we don't have one (for both AI and player units)
                if (unit_data.target_id == null and unit_data.ai_state != .fleeing) {
                    unit_data.target_id = self.findNearestEnemy(entity.id, entity.team, entity.transform.position, unit_data.attack_range);
                }

                // Attack target if in range and cooldown ready
                if (unit_data.target_id) |target_id| {
                    // Check if target still exists and is in range
                    var target_in_range = false;
                    for (self.entities.items) |*target| {
                        if (target.id == target_id and target.active) {
                            const dx = target.transform.position.x - entity.transform.position.x;
                            const dy = target.transform.position.y - entity.transform.position.y;
                            const dist_sq = dx * dx + dy * dy;
                            const range_sq = unit_data.attack_range * unit_data.attack_range;

                            if (dist_sq <= range_sq) {
                                target_in_range = true;

                                // Attack if cooldown ready
                                if (unit_data.canAttack()) {
                                    self.damageEntity(target_id, unit_data.attack_damage);
                                    unit_data.resetAttackTimer();
                                    std.debug.print("Unit {} attacks Unit {} for {} damage!\n", .{ entity.id, target_id, unit_data.attack_damage });
                                }
                            }
                            break;
                        }
                    }

                    // Clear target if out of range or dead
                    if (!target_in_range) {
                        unit_data.target_id = null;
                    }
                }
            }

            // Update movement for entities that can move
            if (entity.movement) |*movement| {
                if (movement.is_moving and movement.path != null) {
                    var path = &movement.path.?;

                    // Get next waypoint
                    if (path.getNext()) |target| {
                        // Calculate direction to target
                        const dx = target.x - entity.transform.position.x;
                        const dy = target.y - entity.transform.position.y;
                        const dist_sq = dx * dx + dy * dy;

                        // Check if we've reached the waypoint
                        const threshold: f32 = 5.0; // 5 units tolerance
                        if (dist_sq < threshold * threshold) {
                            // Remove this waypoint and move to next
                            path.removeFirst();

                            // Check if we've reached final destination
                            if (path.isEmpty()) {
                                movement.stopMoving();
                            }
                        } else {
                            // Move towards waypoint
                            const dist = @sqrt(dist_sq);
                            const move_amount = movement.move_speed * dt_f32;

                            if (move_amount >= dist) {
                                // Will overshoot, just snap to target
                                entity.transform.position.x = target.x;
                                entity.transform.position.y = target.y;
                            } else {
                                // Move towards target
                                const ratio = move_amount / dist;
                                entity.transform.position.x += dx * ratio;
                                entity.transform.position.y += dy * ratio;
                            }
                        }
                    }
                }
            }

            // Update logic per entity type
            switch (entity.entity_type) {
                .unit => {
                    // Unit AI, etc.
                },
                .building => {
                    // Building production, etc.
                },
                .projectile => {
                    // Projectile movement
                },
                .effect => {
                    // Effect animation
                },
            }
        }
    }

    pub fn deinit(self: *EntityManager) void {
        // Clean up all entities
        for (self.entities.items) |*entity| {
            entity.deinit();
        }
        self.entities.deinit(self.allocator);
    }
};

// Tests
test "EntityManager: create and retrieve unit" {
    var manager = try EntityManager.init(std.testing.allocator);
    defer manager.deinit();

    const sprite = Sprite.init(0, 64, 64);
    const id = try manager.createUnit(100, 200, "TestUnit", sprite, 0);

    const entity = manager.getEntity(id);
    try std.testing.expect(entity != null);
    try std.testing.expectEqual(@as(f32, 100), entity.?.transform.position.x);
    try std.testing.expectEqual(@as(f32, 200), entity.?.transform.position.y);
    try std.testing.expectEqual(EntityType.unit, entity.?.entity_type);
}

test "EntityManager: remove entity" {
    var manager = try EntityManager.init(std.testing.allocator);
    defer manager.deinit();

    const sprite = Sprite.init(0, 64, 64);
    const id = try manager.createUnit(100, 200, "TestUnit", sprite, 0);

    manager.removeEntity(id);
    const entity = manager.getEntity(id);
    try std.testing.expect(entity == null);
}

test "EntityManager: entity count" {
    var manager = try EntityManager.init(std.testing.allocator);
    defer manager.deinit();

    const sprite = Sprite.init(0, 64, 64);
    _ = try manager.createUnit(100, 200, "Unit1", sprite, 0);
    _ = try manager.createUnit(150, 250, "Unit2", sprite, 0);
    _ = try manager.createBuilding(300, 400, "Building1", sprite, 0);

    try std.testing.expectEqual(@as(usize, 3), manager.getEntityCount());
}
