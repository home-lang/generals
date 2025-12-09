// Combat system module
const std = @import("std");
const types = @import("types.zig");
const units = @import("units.zig");
const buildings = @import("buildings.zig");

pub const CombatSystem = struct {
    // Process combat between units
    pub fn update(unit_manager: *units.UnitManager, dt: f32) void {
        const all_units = unit_manager.getUnits();

        // Find targets and attack
        for (all_units, 0..) |*unit, i| {
            if (!unit.is_alive) continue;

            // Update attack timer
            if (unit.attack_timer > 0) {
                unit.attack_timer -= dt;
            }

            // Find nearest enemy
            var nearest_enemy: ?usize = null;
            var nearest_dist: f32 = unit.attack_range;

            for (all_units, 0..) |*other, j| {
                if (i == j or !other.is_alive) continue;
                if (!unit.isEnemy(other)) continue;

                const dist = unit.distanceTo(other);
                if (dist < nearest_dist) {
                    nearest_dist = dist;
                    nearest_enemy = j;
                }
            }

            // Attack if we have a target and can attack
            if (nearest_enemy) |target_idx| {
                if (unit.canAttack()) {
                    unit.attack(target_idx);

                    // Deal damage to target
                    if (unit_manager.getUnit(target_idx)) |target| {
                        _ = target.takeDamage(unit.damage);
                    }
                }
            }
        }
    }

    // Check if unit can attack target
    pub fn canAttackTarget(attacker: *const units.Unit, target: *const units.Unit) bool {
        if (!attacker.is_alive or !target.is_alive) return false;
        if (!attacker.isEnemy(target)) return false;

        const dist = attacker.distanceTo(target);
        return dist <= attacker.attack_range and attacker.canAttack();
    }

    // Get damage multiplier based on unit types (future expansion)
    pub fn getDamageMultiplier(attacker_type: types.UnitType, target_type: types.UnitType) f32 {
        // Infantry vs vehicles
        if (attacker_type == .Infantry) {
            if (target_type == .Overlord or target_type == .Paladin) {
                return 0.5; // Infantry weak vs heavy armor
            }
        }

        // Tank vs infantry
        if (attacker_type == .Crusader or attacker_type == .Battlemaster) {
            if (target_type == .Infantry) {
                return 1.5; // Tanks effective vs infantry
            }
        }

        return 1.0;
    }

    // Count alive units by faction
    pub fn countFactionUnits(unit_manager: *const units.UnitManager, faction: types.Faction) usize {
        var count: usize = 0;
        for (unit_manager.units[0..unit_manager.count]) |unit| {
            if (unit.is_alive and unit.faction == faction) {
                count += 1;
            }
        }
        return count;
    }

    // Check victory condition
    pub fn checkVictory(unit_manager: *const units.UnitManager, building_manager: *const buildings.BuildingManager) ?types.Faction {
        var usa_alive = false;
        var china_alive = false;
        var gla_alive = false;

        // Check units
        for (unit_manager.units[0..unit_manager.count]) |unit| {
            if (unit.is_alive) {
                switch (unit.faction) {
                    .USA => usa_alive = true,
                    .China => china_alive = true,
                    .GLA => gla_alive = true,
                }
            }
        }

        // Check buildings
        for (building_manager.buildings[0..building_manager.count]) |building| {
            if (building.health > 0) {
                switch (building.faction) {
                    .USA => usa_alive = true,
                    .China => china_alive = true,
                    .GLA => gla_alive = true,
                }
            }
        }

        // Return winner if only one faction remains
        var alive_count: u8 = 0;
        var winner: types.Faction = .USA;

        if (usa_alive) {
            alive_count += 1;
            winner = .USA;
        }
        if (china_alive) {
            alive_count += 1;
            winner = .China;
        }
        if (gla_alive) {
            alive_count += 1;
            winner = .GLA;
        }

        if (alive_count == 1) {
            return winner;
        }
        return null;
    }
};
