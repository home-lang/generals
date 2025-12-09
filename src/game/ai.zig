// Simple AI Opponent system
const std = @import("std");
const types = @import("types.zig");
const units = @import("units.zig");
const buildings = @import("buildings.zig");

pub const AIState = enum {
    Idle,
    Attacking,
    Defending,
    Producing,
};

pub const AIController = struct {
    faction: types.Faction,
    state: AIState,
    think_timer: f32,
    think_interval: f32,
    attack_timer: f32,
    attack_interval: f32,
    last_attack_target_x: f32,
    last_attack_target_y: f32,

    pub fn init(faction: types.Faction) AIController {
        return AIController{
            .faction = faction,
            .state = .Idle,
            .think_timer = 0,
            .think_interval = 2.0, // Think every 2 seconds
            .attack_timer = 0,
            .attack_interval = 15.0, // Attack wave every 15 seconds
            .last_attack_target_x = 0,
            .last_attack_target_y = 0,
        };
    }

    pub fn update(
        self: *AIController,
        dt: f32,
        unit_manager: *units.UnitManager,
        building_manager: *buildings.BuildingManager,
        production_queue: *buildings.ProductionQueue,
        ai_money: *i32,
    ) void {
        self.think_timer += dt;
        self.attack_timer += dt;

        // Periodic thinking
        if (self.think_timer >= self.think_interval) {
            self.think_timer = 0;
            self.think(unit_manager, building_manager, production_queue, ai_money);
        }

        // Periodic attack waves
        if (self.attack_timer >= self.attack_interval) {
            self.attack_timer = 0;
            self.launchAttack(unit_manager, building_manager);
        }

        // Update AI unit behavior
        self.updateUnits(unit_manager, building_manager);
    }

    fn think(
        self: *AIController,
        unit_manager: *units.UnitManager,
        building_manager: *buildings.BuildingManager,
        production_queue: *buildings.ProductionQueue,
        ai_money: *i32,
    ) void {
        // Count AI units
        var ai_unit_count: usize = 0;
        for (unit_manager.units[0..unit_manager.count]) |unit| {
            if (unit.faction == self.faction and unit.is_alive) {
                ai_unit_count += 1;
            }
        }

        // Find AI barracks or war factory
        var barracks_idx: ?usize = null;
        var factory_idx: ?usize = null;
        for (building_manager.buildings[0..building_manager.count], 0..) |building, i| {
            if (building.faction == self.faction) {
                if (building.building_type == .Barracks) {
                    barracks_idx = i;
                } else if (building.building_type == .WarFactory) {
                    factory_idx = i;
                }
            }
        }

        // Produce units if we have few
        if (ai_unit_count < 8 and production_queue.count == 0) {
            const infantry_cost = types.getUnitStats(.Infantry, self.faction).cost;
            const tank_cost = types.getUnitStats(.Battlemaster, self.faction).cost;

            // Prefer tanks if we can afford them
            if (factory_idx) |idx| {
                if (ai_money.* >= tank_cost) {
                    const unit_type: types.UnitType = switch (self.faction) {
                        .China => .Battlemaster,
                        .GLA => .Scorpion,
                        .USA => .Crusader,
                    };
                    if (production_queue.queueUnit(unit_type, self.faction, idx)) {
                        ai_money.* -= tank_cost;
                        std.debug.print("[AI] Queued tank production, money: {d}\n", .{ai_money.*});
                    }
                }
            } else if (barracks_idx) |idx| {
                // Fall back to infantry
                if (ai_money.* >= infantry_cost) {
                    if (production_queue.queueUnit(.Infantry, self.faction, idx)) {
                        ai_money.* -= infantry_cost;
                        std.debug.print("[AI] Queued infantry production, money: {d}\n", .{ai_money.*});
                    }
                }
            }
        }
    }

    fn launchAttack(
        self: *AIController,
        unit_manager: *units.UnitManager,
        building_manager: *buildings.BuildingManager,
    ) void {
        // Find enemy command center or units to attack
        var target_x: f32 = 400; // Default target area
        var target_y: f32 = 400;

        // Find player command center
        for (building_manager.buildings[0..building_manager.count]) |building| {
            if (building.faction != self.faction and building.building_type == .CommandCenter) {
                target_x = building.x + building.width / 2;
                target_y = building.y + building.height / 2;
                break;
            }
        }

        // Find closest enemy unit if no command center
        var found_enemy = false;
        var closest_dist: f32 = 10000;
        for (unit_manager.units[0..unit_manager.count]) |unit| {
            if (unit.faction != self.faction and unit.is_alive) {
                // Calculate distance from our base
                const dx = unit.x - 700; // Approximate AI base position
                const dy = unit.y - 400;
                const dist = @sqrt(dx * dx + dy * dy);
                if (dist < closest_dist) {
                    closest_dist = dist;
                    target_x = unit.x;
                    target_y = unit.y;
                    found_enemy = true;
                }
            }
        }

        self.last_attack_target_x = target_x;
        self.last_attack_target_y = target_y;

        // Send AI units to attack
        var sent_count: usize = 0;
        for (unit_manager.units[0..unit_manager.count]) |*unit| {
            if (unit.faction == self.faction and unit.is_alive) {
                // Add some spread to the attack
                const spread_x = @as(f32, @floatFromInt(@mod(@as(i32, @intCast(sent_count)), 3))) * 30.0 - 30.0;
                const spread_y = @as(f32, @floatFromInt(sent_count / 3)) * 30.0;
                unit.moveTo(target_x + spread_x, target_y + spread_y);
                sent_count += 1;
            }
        }

        if (sent_count > 0) {
            std.debug.print("[AI] Launched attack with {d} units to ({d:.0}, {d:.0})\n", .{ sent_count, target_x, target_y });
        }
    }

    fn updateUnits(
        self: *AIController,
        unit_manager: *units.UnitManager,
        building_manager: *buildings.BuildingManager,
    ) void {
        _ = building_manager;

        // Make idle units patrol or defend
        for (unit_manager.units[0..unit_manager.count]) |*unit| {
            if (unit.faction != self.faction or !unit.is_alive) continue;

            // Check if unit is idle (at target position)
            const dx = unit.target_x - unit.x;
            const dy = unit.target_y - unit.y;
            const dist = @sqrt(dx * dx + dy * dy);

            if (dist < 5.0) {
                // Unit is idle - look for nearby enemies
                var closest_enemy: ?usize = null;
                var closest_dist: f32 = unit.attack_range * 1.5; // Slightly beyond attack range

                for (unit_manager.units[0..unit_manager.count], 0..) |other, j| {
                    if (other.faction == self.faction or !other.is_alive) continue;

                    const enemy_dx = other.x - unit.x;
                    const enemy_dy = other.y - unit.y;
                    const enemy_dist = @sqrt(enemy_dx * enemy_dx + enemy_dy * enemy_dy);

                    if (enemy_dist < closest_dist) {
                        closest_dist = enemy_dist;
                        closest_enemy = j;
                    }
                }

                // Move towards nearby enemy
                if (closest_enemy) |enemy_idx| {
                    const enemy = &unit_manager.units[enemy_idx];
                    unit.moveTo(enemy.x, enemy.y);
                }
            }
        }
    }
};
