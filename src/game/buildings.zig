// Building and production module
const std = @import("std");
const types = @import("types.zig");
const units = @import("units.zig");

pub const Building = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    building_type: types.BuildingType,
    faction: types.Faction,
    health: f32,
    max_health: f32,

    pub fn create(x: f32, y: f32, building_type: types.BuildingType, faction: types.Faction) Building {
        const size = getBuildingSize(building_type);
        const health = getBuildingHealth(building_type);
        return Building{
            .x = x,
            .y = y,
            .width = size.width,
            .height = size.height,
            .building_type = building_type,
            .faction = faction,
            .health = health,
            .max_health = health,
        };
    }

    pub fn canProduce(self: *const Building, unit_type: types.UnitType) bool {
        return switch (self.building_type) {
            .Barracks => unit_type == .Infantry,
            .WarFactory => unit_type == .Crusader or unit_type == .Paladin or
                unit_type == .Battlemaster or unit_type == .Overlord or
                unit_type == .Technical or unit_type == .Scorpion,
            else => false,
        };
    }

    pub fn getSpawnPoint(self: *const Building) struct { x: f32, y: f32 } {
        return .{
            .x = self.x + self.width + 20,
            .y = self.y + self.height / 2,
        };
    }
};

const BuildingSize = struct { width: f32, height: f32 };

fn getBuildingSize(building_type: types.BuildingType) BuildingSize {
    return switch (building_type) {
        .CommandCenter => .{ .width = 90, .height = 90 },
        .Barracks => .{ .width = 60, .height = 60 },
        .WarFactory => .{ .width = 70, .height = 70 },
        .SupplyCenter => .{ .width = 60, .height = 60 },
        .PowerPlant => .{ .width = 50, .height = 50 },
    };
}

fn getBuildingHealth(building_type: types.BuildingType) f32 {
    return switch (building_type) {
        .CommandCenter => 2000,
        .Barracks => 500,
        .WarFactory => 800,
        .SupplyCenter => 600,
        .PowerPlant => 400,
    };
}

// Production queue item
pub const ProductionItem = struct {
    unit_type: types.UnitType,
    progress: f32, // 0.0 to 1.0
    build_time: f32,
    cost: i32,
};

// Production queue
pub const ProductionQueue = struct {
    items: [5]ProductionItem,
    count: usize,
    building_idx: usize,

    pub fn init() ProductionQueue {
        return ProductionQueue{
            .items = undefined,
            .count = 0,
            .building_idx = 0,
        };
    }

    pub fn queueUnit(self: *ProductionQueue, unit_type: types.UnitType, faction: types.Faction, building_idx: usize) bool {
        if (self.count >= 5) return false;

        const stats = types.getUnitStats(unit_type, faction);
        self.items[self.count] = ProductionItem{
            .unit_type = unit_type,
            .progress = 0.0,
            .build_time = stats.build_time,
            .cost = stats.cost,
        };
        self.count += 1;
        self.building_idx = building_idx;
        return true;
    }

    pub fn update(self: *ProductionQueue, dt: f32) ?types.UnitType {
        if (self.count == 0) return null;

        self.items[0].progress += dt / self.items[0].build_time;

        if (self.items[0].progress >= 1.0) {
            const completed_type = self.items[0].unit_type;

            // Shift queue
            if (self.count > 1) {
                var i: usize = 0;
                while (i < self.count - 1) : (i += 1) {
                    self.items[i] = self.items[i + 1];
                }
            }
            self.count -= 1;

            return completed_type;
        }
        return null;
    }

    pub fn getProgress(self: *const ProductionQueue) f32 {
        if (self.count == 0) return 0;
        return self.items[0].progress;
    }

    pub fn getCost(unit_type: types.UnitType, faction: types.Faction) i32 {
        return types.getUnitStats(unit_type, faction).cost;
    }
};

pub const MAX_BUILDINGS = 32;

pub const BuildingManager = struct {
    buildings: [MAX_BUILDINGS]Building,
    count: usize,

    pub fn init() BuildingManager {
        return BuildingManager{
            .buildings = undefined,
            .count = 0,
        };
    }

    pub fn addBuilding(self: *BuildingManager, building: Building) ?usize {
        if (self.count >= MAX_BUILDINGS) return null;
        self.buildings[self.count] = building;
        self.count += 1;
        return self.count - 1;
    }

    pub fn getBuilding(self: *BuildingManager, idx: usize) ?*Building {
        if (idx >= self.count) return null;
        return &self.buildings[idx];
    }

    pub fn getBuildingConst(self: *const BuildingManager, idx: usize) ?*const Building {
        if (idx >= self.count) return null;
        return &self.buildings[idx];
    }

    pub fn getBuildings(self: *BuildingManager) []Building {
        return self.buildings[0..self.count];
    }
};
