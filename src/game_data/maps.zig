// C&C Generals - Maps Database

const std = @import("std");

pub const MapSize = enum {
    Small,      // 2-4 players
    Medium,     // 4-6 players
    Large,      // 6-8 players
};

pub const MapType = enum {
    Skirmish,
    Multiplayer,
    Campaign,
    Challenge,
};

pub const MapDef = struct {
    name: []const u8,
    display_name: []const u8,
    map_type: MapType,
    size: MapSize,
    max_players: u8,
    width: u32,
    height: u32,
    description: []const u8,
    features: []const []const u8,
};

pub const MAP_DATABASE = [_]MapDef{
    // Small Maps
    .{
        .name = "Tournament_Desert",
        .display_name = "Tournament Desert",
        .map_type = .Multiplayer,
        .size = .Small,
        .max_players = 2,
        .width = 256,
        .height = 256,
        .description = "Classic 1v1 tournament map. Symmetrical desert terrain with limited resources.",
        .features = &[_][]const u8{ "Symmetrical", "Limited Resources", "Competitive" },
    },
    .{
        .name = "Tournament_City",
        .display_name = "Tournament City",
        .map_type = .Multiplayer,
        .size = .Small,
        .max_players = 2,
        .width = 256,
        .height = 256,
        .description = "Urban warfare. Buildings provide cover and strategic positions.",
        .features = &[_][]const u8{ "Urban", "Building Garrisons", "Symmetrical" },
    },
    .{
        .name = "Tournament_Island",
        .display_name = "Tournament Island",
        .map_type = .Multiplayer,
        .size = .Small,
        .max_players = 2,
        .width = 256,
        .height = 256,
        .description = "Two islands separated by water. Naval and air units essential.",
        .features = &[_][]const u8{ "Naval Combat", "Island Bases", "Air Superiority" },
    },
    // Medium Maps
    .{
        .name = "Green_Pastures",
        .display_name = "Green Pastures",
        .map_type = .Skirmish,
        .size = .Medium,
        .max_players = 4,
        .width = 512,
        .height = 512,
        .description = "Lush green terrain with plenty of resources. Good for beginners.",
        .features = &[_][]const u8{ "Abundant Resources", "Open Terrain", "Balanced" },
    },
    .{
        .name = "Wasteland_Warlords",
        .display_name = "Wasteland Warlords",
        .map_type = .Skirmish,
        .size = .Medium,
        .max_players = 4,
        .width = 512,
        .height = 512,
        .description = "Post-apocalyptic wasteland. Scarce resources lead to intense competition.",
        .features = &[_][]const u8{ "Scarce Resources", "Desert Terrain", "Aggressive" },
    },
    .{
        .name = "Golden_Oasis",
        .display_name = "Golden Oasis",
        .map_type = .Skirmish,
        .size = .Medium,
        .max_players = 4,
        .width = 512,
        .height = 512,
        .description = "Desert map with central oasis. Control the center to win.",
        .features = &[_][]const u8{ "Central Objective", "Desert", "King of the Hill" },
    },
    .{
        .name = "Urban_Jungle",
        .display_name = "Urban Jungle",
        .map_type = .Multiplayer,
        .size = .Medium,
        .max_players = 4,
        .width = 512,
        .height = 512,
        .description = "Dense urban environment. Buildings everywhere provide cover.",
        .features = &[_][]const u8{ "Urban Warfare", "Building Capture", "Close Quarters" },
    },
    .{
        .name = "Frozen_Fury",
        .display_name = "Frozen Fury",
        .map_type = .Skirmish,
        .size = .Medium,
        .max_players = 4,
        .width = 512,
        .height = 512,
        .description = "Frozen tundra. Icy terrain affects movement speed.",
        .features = &[_][]const u8{ "Snow Terrain", "Slow Movement", "Strategic Choke Points" },
    },
    // Large Maps
    .{
        .name = "Final_Crusade",
        .display_name = "Final Crusade",
        .map_type = .Multiplayer,
        .size = .Large,
        .max_players = 8,
        .width = 1024,
        .height = 1024,
        .description = "Massive 8-player free-for-all. Epic battles with full armies.",
        .features = &[_][]const u8{ "8 Players", "Massive Scale", "Long Games" },
    },
    .{
        .name = "Battle_for_Oil",
        .display_name = "Battle for Oil",
        .map_type = .Multiplayer,
        .size = .Large,
        .max_players = 6,
        .width = 768,
        .height = 768,
        .description = "Oil fields in the center. Control the oil to fund your war machine.",
        .features = &[_][]const u8{ "Resource Control", "Oil Derricks", "Economic Warfare" },
    },
    .{
        .name = "Desert_Fury",
        .display_name = "Desert Fury",
        .map_type = .Skirmish,
        .size = .Large,
        .max_players = 8,
        .width = 1024,
        .height = 1024,
        .description = "Vast desert expanse. Room for massive tank battles.",
        .features = &[_][]const u8{ "Tank Warfare", "Open Terrain", "Air Combat" },
    },
    .{
        .name = "Mountain_Stronghold",
        .display_name = "Mountain Stronghold",
        .map_type = .Multiplayer,
        .size = .Large,
        .max_players = 6,
        .width = 768,
        .height = 768,
        .description = "Mountainous terrain with narrow passes. Defensible positions.",
        .features = &[_][]const u8{ "Mountains", "Choke Points", "Defensive" },
    },
    .{
        .name = "Coastal_Clash",
        .display_name = "Coastal Clash",
        .map_type = .Multiplayer,
        .size = .Large,
        .max_players = 6,
        .width = 768,
        .height = 768,
        .description = "Coastal battleground. Land and sea combat combined.",
        .features = &[_][]const u8{ "Coastal", "Naval Units", "Amphibious" },
    },
    // Campaign Maps
    .{
        .name = "Operation_Desperate_Union",
        .display_name = "Operation: Desperate Union",
        .map_type = .Campaign,
        .size = .Medium,
        .max_players = 1,
        .width = 512,
        .height = 512,
        .description = "USA Campaign Mission 1. Defend the base from GLA attacks.",
        .features = &[_][]const u8{ "Defense Mission", "Tutorial", "Story Mode" },
    },
    .{
        .name = "Operation_Guardian_Angel",
        .display_name = "Operation: Guardian Angel",
        .map_type = .Campaign,
        .size = .Medium,
        .max_players = 1,
        .width = 512,
        .height = 512,
        .description = "USA Campaign Mission 2. Secure the supply convoy.",
        .features = &[_][]const u8{ "Escort Mission", "Limited Units", "Story Mode" },
    },
    .{
        .name = "Operation_Sword_of_Tianzi",
        .display_name = "Operation: Sword of Tianzi",
        .map_type = .Campaign,
        .size = .Large,
        .max_players = 1,
        .width = 768,
        .height = 768,
        .description = "China Campaign Mission 1. Reclaim the nuclear reactor.",
        .features = &[_][]const u8{ "Assault Mission", "Nuclear Threat", "Story Mode" },
    },
    .{
        .name = "Operation_Red_Tide",
        .display_name = "Operation: Red Tide",
        .map_type = .Campaign,
        .size = .Large,
        .max_players = 1,
        .width = 768,
        .height = 768,
        .description = "China Campaign Mission 2. Push back GLA forces.",
        .features = &[_][]const u8{ "Offensive Mission", "Tank Rush", "Story Mode" },
    },
    .{
        .name = "Operation_Black_Gold",
        .display_name = "Operation: Black Gold",
        .map_type = .Campaign,
        .size = .Medium,
        .max_players = 1,
        .width = 512,
        .height = 512,
        .description = "GLA Campaign Mission 1. Capture the oil refinery.",
        .features = &[_][]const u8{ "Stealth Mission", "Guerrilla Tactics", "Story Mode" },
    },
    .{
        .name = "Operation_Scorched_Earth",
        .display_name = "Operation: Scorched Earth",
        .map_type = .Campaign,
        .size = .Large,
        .max_players = 1,
        .width = 768,
        .height = 768,
        .description = "GLA Campaign Mission 2. Destroy the enemy base.",
        .features = &[_][]const u8{ "Destruction Mission", "SCUD Missiles", "Story Mode" },
    },
    // Challenge Maps
    .{
        .name = "Challenge_Survival",
        .display_name = "Challenge: Survival",
        .map_type = .Challenge,
        .size = .Small,
        .max_players = 1,
        .width = 256,
        .height = 256,
        .description = "Survive endless waves of enemies. How long can you last?",
        .features = &[_][]const u8{ "Endless Waves", "Survival", "High Score" },
    },
    .{
        .name = "Challenge_Speed_Build",
        .display_name = "Challenge: Speed Build",
        .map_type = .Challenge,
        .size = .Small,
        .max_players = 1,
        .width = 256,
        .height = 256,
        .description = "Build the fastest army possible. Time trial mode.",
        .features = &[_][]const u8{ "Time Trial", "Economic Test", "Speed Run" },
    },
    .{
        .name = "Challenge_Last_Stand",
        .display_name = "Challenge: Last Stand",
        .map_type = .Challenge,
        .size = .Medium,
        .max_players = 1,
        .width = 512,
        .height = 512,
        .description = "Limited resources. Defeat overwhelming enemy forces.",
        .features = &[_][]const u8{ "Limited Resources", "Overwhelming Odds", "Strategic" },
    },
};

pub fn getMapDef(name: []const u8) ?*const MapDef {
    for (&MAP_DATABASE) |*map| {
        if (std.mem.eql(u8, map.name, name)) return map;
    }
    return null;
}

pub fn getMapsByType(map_type: MapType) []const MapDef {
    var count: usize = 0;
    for (MAP_DATABASE) |map| {
        if (map.map_type == map_type) count += 1;
    }
    // Simplified - real implementation would use allocator
    return &[_]MapDef{};
}

pub fn getMapsBySize(size: MapSize) []const MapDef {
    var count: usize = 0;
    for (MAP_DATABASE) |map| {
        if (map.size == size) count += 1;
    }
    return &[_]MapDef{};
}
