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
        else => .{ .size = 30, .speed = 80, .health = 80, .damage = 15, .range = 120, .build_time = 8.0, .cost = 500 },
    };
}
