// Victory/Defeat conditions system
const std = @import("std");
const types = @import("types.zig");
const buildings = @import("buildings.zig");
const units = @import("units.zig");

pub const GameResult = enum {
    InProgress,
    Victory,
    Defeat,
};

pub const VictoryCondition = enum {
    DestroyAllEnemyBuildings, // Destroy all enemy buildings
    DestroyAllEnemyCommandCenters, // Destroy all enemy command centers
    DestroyAllEnemyUnits, // Destroy all enemy units and buildings
};

pub const VictoryChecker = struct {
    result: GameResult,
    victory_condition: VictoryCondition,
    check_timer: f32, // Only check periodically for performance
    check_interval: f32,
    victory_message: []const u8,
    defeat_message: []const u8,

    pub fn init() VictoryChecker {
        return VictoryChecker{
            .result = .InProgress,
            .victory_condition = .DestroyAllEnemyCommandCenters,
            .check_timer = 0,
            .check_interval = 1.0, // Check every second
            .victory_message = "VICTORY! All enemy command centers destroyed!",
            .defeat_message = "DEFEAT! Your command center was destroyed!",
        };
    }

    pub fn update(self: *VictoryChecker, dt: f32, building_manager: *buildings.BuildingManager, unit_manager: *units.UnitManager, player_faction: types.Faction) void {
        if (self.result != .InProgress) return;

        self.check_timer += dt;
        if (self.check_timer < self.check_interval) return;
        self.check_timer = 0;

        // Check victory/defeat based on condition
        switch (self.victory_condition) {
            .DestroyAllEnemyCommandCenters => {
                self.checkCommandCenters(building_manager, player_faction);
            },
            .DestroyAllEnemyBuildings => {
                self.checkAllBuildings(building_manager, player_faction);
            },
            .DestroyAllEnemyUnits => {
                self.checkAllUnitsAndBuildings(building_manager, unit_manager, player_faction);
            },
        }
    }

    fn checkCommandCenters(self: *VictoryChecker, building_manager: *buildings.BuildingManager, player_faction: types.Faction) void {
        var player_has_cc = false;
        var enemy_has_cc = false;

        const bldgs = building_manager.getBuildings();
        for (bldgs) |*building| {
            if (building.health <= 0) continue;
            if (building.building_type != .CommandCenter) continue;

            if (building.faction == player_faction) {
                player_has_cc = true;
            } else {
                enemy_has_cc = true;
            }
        }

        if (!player_has_cc) {
            self.result = .Defeat;
            std.debug.print("[GAME OVER] {s}\n", .{self.defeat_message});
        } else if (!enemy_has_cc) {
            self.result = .Victory;
            std.debug.print("[GAME OVER] {s}\n", .{self.victory_message});
        }
    }

    fn checkAllBuildings(self: *VictoryChecker, building_manager: *buildings.BuildingManager, player_faction: types.Faction) void {
        var player_buildings: usize = 0;
        var enemy_buildings: usize = 0;

        const bldgs = building_manager.getBuildings();
        for (bldgs) |*building| {
            if (building.health <= 0) continue;

            if (building.faction == player_faction) {
                player_buildings += 1;
            } else {
                enemy_buildings += 1;
            }
        }

        if (player_buildings == 0) {
            self.result = .Defeat;
            self.defeat_message = "DEFEAT! All your buildings were destroyed!";
            std.debug.print("[GAME OVER] {s}\n", .{self.defeat_message});
        } else if (enemy_buildings == 0) {
            self.result = .Victory;
            self.victory_message = "VICTORY! All enemy buildings destroyed!";
            std.debug.print("[GAME OVER] {s}\n", .{self.victory_message});
        }
    }

    fn checkAllUnitsAndBuildings(self: *VictoryChecker, building_manager: *buildings.BuildingManager, unit_manager: *units.UnitManager, player_faction: types.Faction) void {
        var player_count: usize = 0;
        var enemy_count: usize = 0;

        // Count buildings
        const bldgs = building_manager.getBuildings();
        for (bldgs) |*building| {
            if (building.health <= 0) continue;

            if (building.faction == player_faction) {
                player_count += 1;
            } else {
                enemy_count += 1;
            }
        }

        // Count units
        const unit_list = unit_manager.getUnits();
        for (unit_list) |*unit| {
            if (!unit.is_alive) continue;

            if (unit.faction == player_faction) {
                player_count += 1;
            } else {
                enemy_count += 1;
            }
        }

        if (player_count == 0) {
            self.result = .Defeat;
            self.defeat_message = "DEFEAT! All your forces were destroyed!";
            std.debug.print("[GAME OVER] {s}\n", .{self.defeat_message});
        } else if (enemy_count == 0) {
            self.result = .Victory;
            self.victory_message = "VICTORY! All enemy forces destroyed!";
            std.debug.print("[GAME OVER] {s}\n", .{self.victory_message});
        }
    }

    pub fn isGameOver(self: *const VictoryChecker) bool {
        return self.result != .InProgress;
    }

    pub fn isVictory(self: *const VictoryChecker) bool {
        return self.result == .Victory;
    }

    pub fn isDefeat(self: *const VictoryChecker) bool {
        return self.result == .Defeat;
    }

    pub fn getMessage(self: *const VictoryChecker) []const u8 {
        return switch (self.result) {
            .Victory => self.victory_message,
            .Defeat => self.defeat_message,
            .InProgress => "Game in progress",
        };
    }

    pub fn reset(self: *VictoryChecker) void {
        self.result = .InProgress;
        self.check_timer = 0;
    }
};
