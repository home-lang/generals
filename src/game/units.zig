// Unit management module
const std = @import("std");
const types = @import("types.zig");

pub const Unit = struct {
    x: f32,
    y: f32,
    target_x: f32,
    target_y: f32,
    speed: f32,
    size: f32,
    selected: bool,
    faction: types.Faction,
    unit_type: types.UnitType,
    health: f32,
    max_health: f32,
    damage: f32,
    attack_range: f32,
    attack_cooldown: f32,
    attack_timer: f32,
    target_unit: ?usize,
    is_alive: bool,

    pub fn create(x: f32, y: f32, faction: types.Faction, unit_type: types.UnitType) Unit {
        const stats = types.getUnitStats(unit_type, faction);
        return Unit{
            .x = x,
            .y = y,
            .target_x = x,
            .target_y = y,
            .speed = stats.speed,
            .size = stats.size,
            .selected = false,
            .faction = faction,
            .unit_type = unit_type,
            .health = stats.health,
            .max_health = stats.health,
            .damage = stats.damage,
            .attack_range = stats.range,
            .attack_cooldown = 1.0,
            .attack_timer = 0,
            .target_unit = null,
            .is_alive = true,
        };
    }

    pub fn createWithStats(x: f32, y: f32, speed: f32, size: f32, faction: types.Faction, unit_type: types.UnitType, health: f32, damage: f32, range: f32) Unit {
        return Unit{
            .x = x,
            .y = y,
            .target_x = x,
            .target_y = y,
            .speed = speed,
            .size = size,
            .selected = false,
            .faction = faction,
            .unit_type = unit_type,
            .health = health,
            .max_health = health,
            .damage = damage,
            .attack_range = range,
            .attack_cooldown = 1.0,
            .attack_timer = 0,
            .target_unit = null,
            .is_alive = true,
        };
    }

    pub fn update(self: *Unit, dt: f32) void {
        if (!self.is_alive) return;

        // Movement
        const dx = self.target_x - self.x;
        const dy = self.target_y - self.y;
        const dist = @sqrt(dx * dx + dy * dy);

        if (dist > 2.0) {
            const move_dist = self.speed * dt;
            if (move_dist >= dist) {
                self.x = self.target_x;
                self.y = self.target_y;
            } else {
                self.x += (dx / dist) * move_dist;
                self.y += (dy / dist) * move_dist;
            }
        }

        // Update attack timer
        if (self.attack_timer > 0) {
            self.attack_timer -= dt;
        }
    }

    pub fn moveTo(self: *Unit, x: f32, y: f32) void {
        self.target_x = x;
        self.target_y = y;
    }

    pub fn takeDamage(self: *Unit, damage: f32) bool {
        self.health -= damage;
        if (self.health <= 0) {
            self.health = 0;
            self.is_alive = false;
            return true; // died
        }
        return false;
    }

    pub fn canAttack(self: *const Unit) bool {
        return self.is_alive and self.attack_timer <= 0;
    }

    pub fn distanceTo(self: *const Unit, other: *const Unit) f32 {
        const dx = other.x - self.x;
        const dy = other.y - self.y;
        return @sqrt(dx * dx + dy * dy);
    }

    pub fn isEnemy(self: *const Unit, other: *const Unit) bool {
        return self.faction != other.faction;
    }

    pub fn attack(self: *Unit, target_idx: usize) void {
        self.attack_timer = self.attack_cooldown;
        self.target_unit = target_idx;
    }
};

pub const MAX_UNITS = 64;

pub const UnitManager = struct {
    units: [MAX_UNITS]Unit,
    count: usize,

    pub fn init() UnitManager {
        return UnitManager{
            .units = undefined,
            .count = 0,
        };
    }

    pub fn addUnit(self: *UnitManager, unit: Unit) ?usize {
        if (self.count >= MAX_UNITS) return null;
        self.units[self.count] = unit;
        self.count += 1;
        return self.count - 1;
    }

    pub fn getUnit(self: *UnitManager, idx: usize) ?*Unit {
        if (idx >= self.count) return null;
        return &self.units[idx];
    }

    pub fn getUnitConst(self: *const UnitManager, idx: usize) ?*const Unit {
        if (idx >= self.count) return null;
        return &self.units[idx];
    }

    pub fn getUnits(self: *UnitManager) []Unit {
        return self.units[0..self.count];
    }

    pub fn aliveCount(self: *const UnitManager) usize {
        var alive: usize = 0;
        for (self.units[0..self.count]) |unit| {
            if (unit.is_alive) alive += 1;
        }
        return alive;
    }
};
