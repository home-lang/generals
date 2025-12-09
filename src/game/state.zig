// Game state module
const std = @import("std");
const types = @import("types.zig");
const units = @import("units.zig");
const buildings = @import("buildings.zig");

pub const GameState = struct {
    // Core game state
    camera_x: f32,
    camera_y: f32,
    game_mode: types.GameMode,
    player_faction: types.Faction,

    // Resources
    player_money: i32,
    player_power: i32,

    // Managers
    unit_manager: units.UnitManager,
    building_manager: buildings.BuildingManager,
    production_queue: buildings.ProductionQueue,

    // Selection state
    selected_unit_index: ?usize,
    selected_building_index: ?usize,
    selection_start_x: f32,
    selection_start_y: f32,
    is_selecting: bool,

    // Timing
    last_frame_time: i64,

    pub fn init() GameState {
        return GameState{
            .camera_x = 0,
            .camera_y = 0,
            .game_mode = .MainMenu,
            .player_faction = .USA,
            .player_money = 5000,
            .player_power = 100,
            .unit_manager = units.UnitManager.init(),
            .building_manager = buildings.BuildingManager.init(),
            .production_queue = buildings.ProductionQueue.init(),
            .selected_unit_index = null,
            .selected_building_index = null,
            .selection_start_x = 0,
            .selection_start_y = 0,
            .is_selecting = false,
            .last_frame_time = 0,
        };
    }

    pub fn startSkirmish(self: *GameState) void {
        self.game_mode = .Skirmish;
        self.camera_x = 0;
        self.camera_y = 0;
        self.player_money = 5000;
        self.player_power = 100;

        // Reset managers
        self.unit_manager = units.UnitManager.init();
        self.building_manager = buildings.BuildingManager.init();
        self.production_queue = buildings.ProductionQueue.init();

        // Setup initial units and buildings
        self.setupPlayerBase();
        self.setupEnemyBase();
    }

    fn setupPlayerBase(self: *GameState) void {
        // Player buildings (USA)
        _ = self.building_manager.addBuilding(buildings.Building.create(100, 100, .CommandCenter, .USA));
        _ = self.building_manager.addBuilding(buildings.Building.create(200, 100, .Barracks, .USA));
        _ = self.building_manager.addBuilding(buildings.Building.create(100, 200, .WarFactory, .USA));
        _ = self.building_manager.addBuilding(buildings.Building.create(200, 200, .SupplyCenter, .USA));

        // Player starting units
        _ = self.unit_manager.addUnit(units.Unit.create(300, 150, .USA, .Infantry));
        _ = self.unit_manager.addUnit(units.Unit.create(320, 150, .USA, .Infantry));
        _ = self.unit_manager.addUnit(units.Unit.create(340, 150, .USA, .Infantry));
        _ = self.unit_manager.addUnit(units.Unit.create(300, 200, .USA, .Crusader));
    }

    fn setupEnemyBase(self: *GameState) void {
        // Enemy buildings (China)
        _ = self.building_manager.addBuilding(buildings.Building.create(900, 500, .CommandCenter, .China));
        _ = self.building_manager.addBuilding(buildings.Building.create(1000, 500, .Barracks, .China));
        _ = self.building_manager.addBuilding(buildings.Building.create(900, 600, .WarFactory, .China));

        // Enemy starting units
        _ = self.unit_manager.addUnit(units.Unit.create(800, 550, .China, .Infantry));
        _ = self.unit_manager.addUnit(units.Unit.create(820, 550, .China, .Infantry));
        _ = self.unit_manager.addUnit(units.Unit.create(800, 600, .China, .Battlemaster));
        _ = self.unit_manager.addUnit(units.Unit.create(850, 600, .China, .Battlemaster));
    }

    pub fn selectUnit(self: *GameState, idx: usize) void {
        // Deselect previous
        if (self.selected_unit_index) |prev_idx| {
            if (self.unit_manager.getUnit(prev_idx)) |prev_unit| {
                prev_unit.selected = false;
            }
        }

        self.selected_unit_index = idx;
        self.selected_building_index = null;

        if (self.unit_manager.getUnit(idx)) |unit| {
            unit.selected = true;
        }
    }

    pub fn selectBuilding(self: *GameState, idx: usize) void {
        self.selected_building_index = idx;
        self.selected_unit_index = null;

        // Deselect all units
        for (self.unit_manager.getUnits()) |*unit| {
            unit.selected = false;
        }
    }

    pub fn clearSelection(self: *GameState) void {
        if (self.selected_unit_index) |idx| {
            if (self.unit_manager.getUnit(idx)) |unit| {
                unit.selected = false;
            }
        }
        self.selected_unit_index = null;
        self.selected_building_index = null;
    }

    pub fn moveCamera(self: *GameState, dx: f32, dy: f32) void {
        self.camera_x += dx;
        self.camera_y += dy;

        // Clamp camera
        const map_width: f32 = 2000;
        const map_height: f32 = 2000;
        const screen_width: f32 = 1280;
        const screen_height: f32 = 800;

        if (self.camera_x < 0) self.camera_x = 0;
        if (self.camera_y < 0) self.camera_y = 0;
        if (self.camera_x > map_width - screen_width) self.camera_x = map_width - screen_width;
        if (self.camera_y > map_height - screen_height) self.camera_y = map_height - screen_height;
    }

    pub fn queueProduction(self: *GameState, unit_type: types.UnitType, building_idx: usize) bool {
        const cost = buildings.ProductionQueue.getCost(unit_type, self.player_faction);
        if (self.player_money < cost) return false;

        if (self.production_queue.queueUnit(unit_type, self.player_faction, building_idx)) {
            self.player_money -= cost;
            return true;
        }
        return false;
    }

    pub fn updateProduction(self: *GameState, dt: f32) void {
        if (self.production_queue.update(dt)) |completed_type| {
            // Spawn the unit at the building
            if (self.building_manager.getBuilding(self.production_queue.building_idx)) |building| {
                const spawn = building.getSpawnPoint();
                _ = self.unit_manager.addUnit(units.Unit.create(spawn.x, spawn.y, self.player_faction, completed_type));
            }
        }
    }
};
