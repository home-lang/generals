// Game type definitions
// Shared types used across all game modules

pub const Faction = enum {
    USA,
    China,
    GLA,
};

pub const UnitType = enum {
    Infantry,
    Tank,
    Humvee,
    Crusader,
    Paladin,
    Comanche,
    Battlemaster,
    Overlord,
    Technical,
    Scorpion,
    QuadCannon,
    Worker, // Resource gatherer (Dozer for USA, Worker for China, Worker for GLA)
};

pub const BuildingType = enum {
    CommandCenter,
    Barracks,
    WarFactory,
    SupplyCenter,
    PowerPlant,
};

pub const GameMode = enum {
    MainMenu,
    Skirmish,
    Campaign,
    GeneralsChallenge,
    Multiplayer,
};

// Unit stats by type
pub const UnitStats = struct {
    size: f32,
    speed: f32,
    health: f32,
    damage: f32,
    range: f32,
    build_time: f32,
    cost: i32,
};

pub fn getUnitStats(unit_type: UnitType, faction: Faction) UnitStats {
    _ = faction; // TODO: faction-specific adjustments
    return switch (unit_type) {
        .Infantry => .{ .size = 24, .speed = 60, .health = 50, .damage = 8, .range = 100, .build_time = 5.0, .cost = 200 },
        .Crusader => .{ .size = 36, .speed = 100, .health = 100, .damage = 25, .range = 150, .build_time = 10.0, .cost = 800 },
        .Paladin => .{ .size = 42, .speed = 80, .health = 150, .damage = 35, .range = 160, .build_time = 15.0, .cost = 1100 },
        .Battlemaster => .{ .size = 38, .speed = 90, .health = 120, .damage = 30, .range = 140, .build_time = 10.0, .cost = 800 },
        .Overlord => .{ .size = 48, .speed = 70, .health = 200, .damage = 50, .range = 170, .build_time = 20.0, .cost = 2000 },
        .Technical => .{ .size = 30, .speed = 120, .health = 60, .damage = 15, .range = 120, .build_time = 5.0, .cost = 500 },
        .Scorpion => .{ .size = 34, .speed = 85, .health = 80, .damage = 20, .range = 130, .build_time = 8.0, .cost = 600 },
        .Worker => .{ .size = 28, .speed = 50, .health = 100, .damage = 0, .range = 0, .build_time = 10.0, .cost = 400 },
        else => .{ .size = 30, .speed = 80, .health = 80, .damage = 15, .range = 120, .build_time = 8.0, .cost = 500 },
    };
}

// Building stats
pub const BuildingStats = struct {
    width: f32,
    height: f32,
    health: f32,
    cost: i32,
    build_time: f32,
    power: i32, // Positive = produces, negative = consumes
};

pub fn getBuildingStats(building_type: BuildingType) BuildingStats {
    return switch (building_type) {
        .CommandCenter => .{ .width = 100, .height = 80, .health = 2000, .cost = 0, .build_time = 0, .power = 0 },
        .PowerPlant => .{ .width = 60, .height = 60, .health = 500, .cost = 500, .build_time = 10.0, .power = 10 },
        .Barracks => .{ .width = 70, .height = 60, .health = 800, .cost = 600, .build_time = 15.0, .power = -2 },
        .WarFactory => .{ .width = 90, .height = 70, .health = 1200, .cost = 1000, .build_time = 20.0, .power = -3 },
        .SupplyCenter => .{ .width = 80, .height = 60, .health = 600, .cost = 800, .build_time = 15.0, .power = -1 },
    };
}
