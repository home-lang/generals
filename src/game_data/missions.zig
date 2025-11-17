// C&C Generals Zero Hour - Campaign Missions Database
// All campaign missions from USA, China, and GLA campaigns

const std = @import("std");

pub const MissionType = enum {
    Story,          // Main campaign story mission
    Tutorial,       // Tutorial mission
    Challenge,      // Bonus challenge mission
    GeneralsChallenge,  // Zero Hour generals challenge
};

pub const Difficulty = enum {
    Easy,
    Medium,
    Hard,
};

pub const MissionObjectiveType = enum {
    Defend,
    Destroy,
    Capture,
    Escort,
    Survive,
    Stealth,
    Assassination,
    Rescue,
    BuildBase,
    DestroyAll,
};

pub const MissionObjective = struct {
    objective_type: MissionObjectiveType,
    description: []const u8,
    required: bool, // Primary or secondary objective
};

pub const MissionDef = struct {
    name: []const u8,
    display_name: []const u8,
    campaign: []const u8,  // "USA", "China", "GLA", "Zero Hour"
    mission_number: u8,
    mission_type: MissionType,
    difficulty: Difficulty,
    map_name: []const u8,
    briefing: []const u8,
    objectives: []const MissionObjective,
    time_limit: ?u32, // Seconds, null if no limit
    starting_money: u32,
    available_units: []const []const u8,
    available_buildings: []const []const u8,
    rewards: []const []const u8,
    unlocks: []const []const u8,
};

pub const MISSION_DATABASE = [_]MissionDef{
    // ========================================
    // USA CAMPAIGN
    // ========================================
    .{
        .name = "USA_Mission_01",
        .display_name = "Operation: Final Justice",
        .campaign = "USA",
        .mission_number = 1,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "USA_01_Final_Justice",
        .briefing = "Welcome to the Global Liberation Army crisis, soldier. GLA forces have seized control of vital infrastructure. Your mission: establish a forward operating base and neutralize GLA presence in the region.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .BuildBase, .description = "Build a Command Center", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy all GLA structures", .required = true },
            .{ .objective_type = .Defend, .description = "Protect the supply depot", .required = false },
        },
        .time_limit = null,
        .starting_money = 5000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Humvee", "USA_Chinook" },
        .available_buildings = &[_][]const u8{ "USA_Command_Center", "USA_Supply_Center", "USA_Barracks", "USA_War_Factory" },
        .rewards = &[_][]const u8{ "Unlock Paladin Tank" },
        .unlocks = &[_][]const u8{ "USA_Paladin_Tank" },
    },
    .{
        .name = "USA_Mission_02",
        .display_name = "Operation: Guardian Angel",
        .campaign = "USA",
        .mission_number = 2,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "USA_02_Guardian_Angel",
        .briefing = "Intelligence reports indicate a critical supply convoy is under heavy GLA attack. Your objective: escort the convoy safely to the forward base. Air support available.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Escort, .description = "Escort all supply trucks to base", .required = true },
            .{ .objective_type = .Survive, .description = "Keep at least 3 trucks alive", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA ambush positions", .required = false },
        },
        .time_limit = 1800, // 30 minutes
        .starting_money = 3000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Humvee", "USA_Tomahawk", "USA_Raptor" },
        .available_buildings = &[_][]const u8{},
        .rewards = &[_][]const u8{ "Unlock Comanche Helicopter" },
        .unlocks = &[_][]const u8{ "USA_Comanche" },
    },
    .{
        .name = "USA_Mission_03",
        .display_name = "Operation: Last Call",
        .campaign = "USA",
        .mission_number = 3,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "USA_03_Last_Call",
        .briefing = "The GLA has launched a chemical weapons attack on allied forces. Secure the area and destroy the chemical weapons facility before they can launch again.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Destroy the chemical weapons facility", .required = true },
            .{ .objective_type = .Capture, .description = "Capture the GLA palace", .required = false },
            .{ .objective_type = .Rescue, .description = "Rescue trapped civilians", .required = false },
        },
        .time_limit = null,
        .starting_money = 8000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Paladin_Tank", "USA_Humvee", "USA_Tomahawk", "USA_Comanche" },
        .available_buildings = &[_][]const u8{ "USA_Command_Center", "USA_Supply_Center", "USA_Barracks", "USA_War_Factory", "USA_Airfield" },
        .rewards = &[_][]const u8{ "Unlock Colonel Burton" },
        .unlocks = &[_][]const u8{ "USA_Colonel_Burton" },
    },
    .{
        .name = "USA_Mission_04",
        .display_name = "Operation: Desperate Union",
        .campaign = "USA",
        .mission_number = 4,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "USA_04_Desperate_Union",
        .briefing = "GLA forces are massing for a major offensive. Hold the line and repel all enemy attacks. Reinforcements are limited. Make every shot count.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Defend, .description = "Defend your base for 20 minutes", .required = true },
            .{ .objective_type = .Survive, .description = "Keep Command Center intact", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA forward bases", .required = false },
        },
        .time_limit = 1200, // 20 minutes defense
        .starting_money = 10000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Paladin_Tank", "USA_Tomahawk", "USA_Comanche", "USA_Colonel_Burton" },
        .available_buildings = &[_][]const u8{ "USA_Command_Center", "USA_Supply_Center", "USA_Barracks", "USA_War_Factory", "USA_Airfield", "USA_Patriot_Battery" },
        .rewards = &[_][]const u8{ "Unlock Particle Cannon" },
        .unlocks = &[_][]const u8{ "USA_Particle_Cannon" },
    },
    .{
        .name = "USA_Mission_05",
        .display_name = "Operation: Stormbringer",
        .campaign = "USA",
        .mission_number = 5,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "USA_05_Stormbringer",
        .briefing = "The GLA has fortified their positions in the mountains. Launch a full-scale assault and destroy their command infrastructure. This is total war.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy all GLA bases", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA SCUD Storm", .required = true },
            .{ .objective_type = .Capture, .description = "Capture oil derricks for funding", .required = false },
        },
        .time_limit = null,
        .starting_money = 15000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Paladin_Tank", "USA_Tomahawk", "USA_Comanche", "USA_Raptor", "USA_Colonel_Burton" },
        .available_buildings = &[_][]const u8{ "USA_Command_Center", "USA_Supply_Center", "USA_Barracks", "USA_War_Factory", "USA_Airfield", "USA_Strategy_Center", "USA_Patriot_Battery" },
        .rewards = &[_][]const u8{ "Unlock A-10 Strike" },
        .unlocks = &[_][]const u8{ "USA_A10_Strike" },
    },
    .{
        .name = "USA_Mission_06",
        .display_name = "Operation: Blue Eagle",
        .campaign = "USA",
        .mission_number = 6,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "USA_06_Blue_Eagle",
        .briefing = "GLA leadership is hiding in underground tunnels. Use Colonel Burton to infiltrate and mark targets for air strikes. Stealth is essential.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Stealth, .description = "Infiltrate GLA compound undetected", .required = true },
            .{ .objective_type = .Assassination, .description = "Eliminate GLA commanders", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy tunnel networks", .required = true },
        },
        .time_limit = null,
        .starting_money = 5000,
        .available_units = &[_][]const u8{ "USA_Colonel_Burton", "USA_Ranger", "USA_Comanche", "USA_Raptor" },
        .available_buildings = &[_][]const u8{},
        .rewards = &[_][]const u8{ "Unlock Aurora Bomber" },
        .unlocks = &[_][]const u8{ "USA_Aurora_Bomber" },
    },
    .{
        .name = "USA_Mission_07",
        .display_name = "Operation: Final Strike",
        .campaign = "USA",
        .mission_number = 7,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "USA_07_Final_Strike",
        .briefing = "This is it. The final GLA stronghold. Deploy everything. Use your Particle Cannon. Show them the might of the United States military. Leave nothing standing.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy all GLA forces", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA Palace", .required = true },
            .{ .objective_type = .Survive, .description = "Survive SCUD Storm attacks", .required = true },
        },
        .time_limit = null,
        .starting_money = 20000,
        .available_units = &[_][]const u8{ "USA_Ranger", "USA_Crusader_Tank", "USA_Paladin_Tank", "USA_Tomahawk", "USA_Comanche", "USA_Raptor", "USA_Aurora_Bomber", "USA_Colonel_Burton" },
        .available_buildings = &[_][]const u8{ "USA_Command_Center", "USA_Supply_Center", "USA_Barracks", "USA_War_Factory", "USA_Airfield", "USA_Strategy_Center", "USA_Patriot_Battery", "USA_Particle_Cannon" },
        .rewards = &[_][]const u8{ "Campaign Complete", "Unlock All USA Units" },
        .unlocks = &[_][]const u8{ "All_USA_Units" },
    },

    // ========================================
    // CHINA CAMPAIGN
    // ========================================
    .{
        .name = "China_Mission_01",
        .display_name = "Operation: Dragon Awakens",
        .campaign = "China",
        .mission_number = 1,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "China_01_Dragon_Awakens",
        .briefing = "The GLA has attacked our nuclear facilities. This is an act of war. Build your base and show them the strength of the People's Liberation Army.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .BuildBase, .description = "Establish a supply chain", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA raiders", .required = true },
            .{ .objective_type = .Defend, .description = "Protect nuclear reactor", .required = true },
        },
        .time_limit = null,
        .starting_money = 5000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Battlemaster", "China_Troop_Crawler" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory" },
        .rewards = &[_][]const u8{ "Unlock Gattling Tank" },
        .unlocks = &[_][]const u8{ "China_Gattling_Tank" },
    },
    .{
        .name = "China_Mission_02",
        .display_name = "Operation: Hong Kong Crisis",
        .campaign = "China",
        .mission_number = 2,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "China_02_Hong_Kong",
        .briefing = "GLA terrorists have taken Hong Kong. The city must be liberated. Minimize civilian casualties and restore order to the streets.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Eliminate all GLA in Hong Kong", .required = true },
            .{ .objective_type = .Defend, .description = "Protect civilian buildings", .required = false },
            .{ .objective_type = .Capture, .description = "Secure the Convention Center", .required = true },
        },
        .time_limit = null,
        .starting_money = 7000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Battlemaster", "China_Gattling_Tank", "China_Troop_Crawler" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory" },
        .rewards = &[_][]const u8{ "Unlock Overlord Tank" },
        .unlocks = &[_][]const u8{ "China_Overlord_Tank" },
    },
    .{
        .name = "China_Mission_03",
        .display_name = "Operation: Treasure Hunt",
        .campaign = "China",
        .mission_number = 3,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "China_03_Treasure_Hunt",
        .briefing = "GLA has stolen Chinese artifacts and military intelligence. Track down their convoy and recover the stolen goods before they escape the region.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Destroy GLA convoy before escape", .required = true },
            .{ .objective_type = .Escort, .description = "Protect recovery team", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA airfield", .required = false },
        },
        .time_limit = 1500, // 25 minutes
        .starting_money = 8000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Battlemaster", "China_Gattling_Tank", "China_Overlord_Tank", "China_MiG" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory", "China_Airfield" },
        .rewards = &[_][]const u8{ "Unlock Black Lotus" },
        .unlocks = &[_][]const u8{ "China_Black_Lotus" },
    },
    .{
        .name = "China_Mission_04",
        .display_name = "Operation: Scorched Earth",
        .campaign = "China",
        .mission_number = 4,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "China_04_Scorched_Earth",
        .briefing = "The GLA is using scorched earth tactics, destroying everything in their retreat. Pursue and annihilate them. Show no mercy to terrorists.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy all retreating GLA forces", .required = true },
            .{ .objective_type = .Defend, .description = "Protect villages from GLA", .required = false },
            .{ .objective_type = .Capture, .description = "Capture oil resources", .required = false },
        },
        .time_limit = null,
        .starting_money = 10000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Tank_Hunter", "China_Battlemaster", "China_Gattling_Tank", "China_Overlord_Tank", "China_MiG" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory", "China_Airfield", "China_Gattling_Cannon" },
        .rewards = &[_][]const u8{ "Unlock Nuke Cannon" },
        .unlocks = &[_][]const u8{ "China_Nuke_Cannon" },
    },
    .{
        .name = "China_Mission_05",
        .display_name = "Operation: Dead in Their Tracks",
        .campaign = "China",
        .mission_number = 5,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "China_05_Dead_Tracks",
        .briefing = "GLA forces have hijacked our nuclear train. Stop that train before it reaches the city. If it detonates, millions will die. Failure is not an option.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Stop the nuclear train", .required = true },
            .{ .objective_type = .Survive, .description = "Prevent train from reaching city", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA supply bases", .required = false },
        },
        .time_limit = 1200, // 20 minutes before train reaches city
        .starting_money = 12000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Battlemaster", "China_Overlord_Tank", "China_MiG", "China_Helix", "China_Black_Lotus" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory", "China_Airfield" },
        .rewards = &[_][]const u8{ "Unlock Nuclear Missile" },
        .unlocks = &[_][]const u8{ "China_Nuclear_Missile" },
    },
    .{
        .name = "China_Mission_06",
        .display_name = "Operation: Broken Alliance",
        .campaign = "China",
        .mission_number = 6,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "China_06_Broken_Alliance",
        .briefing = "Intelligence reveals USA forces are preparing to strike our positions. Preemptive action authorized. Destroy their base before they attack us.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy USA forward base", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy Particle Cannon", .required = true },
            .{ .objective_type = .Defend, .description = "Defend your nuclear silos", .required = true },
        },
        .time_limit = null,
        .starting_money = 15000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Tank_Hunter", "China_Battlemaster", "China_Overlord_Tank", "China_Gattling_Tank", "China_MiG", "China_Helix", "China_Nuke_Cannon" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory", "China_Airfield", "China_Nuclear_Missile", "China_Gattling_Cannon" },
        .rewards = &[_][]const u8{ "Unlock Emperor Tank" },
        .unlocks = &[_][]const u8{ "China_Emperor_Tank" },
    },
    .{
        .name = "China_Mission_07",
        .display_name = "Operation: Nuclear Winter",
        .campaign = "China",
        .mission_number = 7,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "China_07_Nuclear_Winter",
        .briefing = "This is the final battle. The GLA's main stronghold awaits. Use your nuclear arsenal. The world will remember this day as the end of the GLA threat.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Annihilate all GLA forces", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy GLA Palace and SCUD Storm", .required = true },
            .{ .objective_type = .Survive, .description = "Withstand GLA counterattacks", .required = true },
        },
        .time_limit = null,
        .starting_money = 20000,
        .available_units = &[_][]const u8{ "China_Red_Guard", "China_Tank_Hunter", "China_Battlemaster", "China_Overlord_Tank", "China_Emperor_Tank", "China_Gattling_Tank", "China_MiG", "China_Helix", "China_Nuke_Cannon", "China_Black_Lotus" },
        .available_buildings = &[_][]const u8{ "China_Command_Center", "China_Supply_Center", "China_Barracks", "China_War_Factory", "China_Airfield", "China_Nuclear_Missile", "China_Gattling_Cannon", "China_Propaganda_Center" },
        .rewards = &[_][]const u8{ "Campaign Complete", "Unlock All China Units" },
        .unlocks = &[_][]const u8{ "All_China_Units" },
    },

    // ========================================
    // GLA CAMPAIGN
    // ========================================
    .{
        .name = "GLA_Mission_01",
        .display_name = "Operation: Black Rain",
        .campaign = "GLA",
        .mission_number = 1,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "GLA_01_Black_Rain",
        .briefing = "The oppressors have taken our land. We fight with what we have. Raid their supply depot and steal what we need. Hit fast, hit hard, disappear.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Capture, .description = "Capture enemy supply depot", .required = true },
            .{ .objective_type = .Stealth, .description = "Avoid detection until raid begins", .required = false },
            .{ .objective_type = .Destroy, .description = "Destroy communications tower", .required = true },
        },
        .time_limit = null,
        .starting_money = 3000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_Technical", "GLA_Scorpion", "GLA_Tunnel_Network" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks" },
        .rewards = &[_][]const u8{ "Unlock Toxin Tractor" },
        .unlocks = &[_][]const u8{ "GLA_Toxin_Tractor" },
    },
    .{
        .name = "GLA_Mission_02",
        .display_name = "Operation: Flames of the Scorpion",
        .campaign = "GLA",
        .mission_number = 2,
        .mission_type = .Story,
        .difficulty = .Easy,
        .map_name = "GLA_02_Scorpion_Flames",
        .briefing = "The Chinese have underestimated us. Show them the fury of the GLA. Destroy their base and take their resources. We will grow stronger from their defeat.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy Chinese base", .required = true },
            .{ .objective_type = .Capture, .description = "Capture supply centers", .required = false },
            .{ .objective_type = .Survive, .description = "Keep your Palace alive", .required = true },
        },
        .time_limit = null,
        .starting_money = 5000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_RPG_Trooper", "GLA_Technical", "GLA_Scorpion", "GLA_Toxin_Tractor" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks", "GLA_Palace" },
        .rewards = &[_][]const u8{ "Unlock Marauder Tank" },
        .unlocks = &[_][]const u8{ "GLA_Marauder_Tank" },
    },
    .{
        .name = "GLA_Mission_03",
        .display_name = "Operation: Broken Chains",
        .campaign = "GLA",
        .mission_number = 3,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "GLA_03_Broken_Chains",
        .briefing = "Our brothers are held in USA prison camps. Free them. Use stealth and surprise. Every freed fighter joins our cause. The revolution grows.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Rescue, .description = "Free all GLA prisoners", .required = true },
            .{ .objective_type = .Stealth, .description = "Infiltrate base undetected", .required = false },
            .{ .objective_type = .Destroy, .description = "Destroy detention facilities", .required = true },
        },
        .time_limit = null,
        .starting_money = 4000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_Terrorist", "GLA_Jarmen_Kell", "GLA_Technical", "GLA_Scorpion" },
        .available_buildings = &[_][]const u8{},
        .rewards = &[_][]const u8{ "Unlock Bomb Truck" },
        .unlocks = &[_][]const u8{ "GLA_Bomb_Truck" },
    },
    .{
        .name = "GLA_Mission_04",
        .display_name = "Operation: Toxic Fury",
        .campaign = "GLA",
        .mission_number = 4,
        .mission_type = .Story,
        .difficulty = .Medium,
        .map_name = "GLA_04_Toxic_Fury",
        .briefing = "We have acquired chemical weapons from the black market. Use them against our enemies. Toxins do not discriminate. Let them choke on their arrogance.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Destroy USA chemical depot", .required = true },
            .{ .objective_type = .Stealth, .description = "Use toxins to clear defenses", .required = false },
            .{ .objective_type = .DestroyAll, .description = "Eliminate all resistance", .required = true },
        },
        .time_limit = null,
        .starting_money = 8000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_Terrorist", "GLA_Technical", "GLA_Scorpion", "GLA_Marauder_Tank", "GLA_Toxin_Tractor", "GLA_Bomb_Truck" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks", "GLA_Palace" },
        .rewards = &[_][]const u8{ "Unlock SCUD Launcher" },
        .unlocks = &[_][]const u8{ "GLA_SCUD_Launcher" },
    },
    .{
        .name = "GLA_Mission_05",
        .display_name = "Operation: Retribution",
        .campaign = "GLA",
        .mission_number = 5,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "GLA_05_Retribution",
        .briefing = "The Americans think they can bomb us with impunity. Capture their airbase. Turn their own weapons against them. Let them taste their own medicine.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Capture, .description = "Capture USA airfield", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy USA Command Center", .required = true },
            .{ .objective_type = .Defend, .description = "Hold airfield against counterattack", .required = true },
        },
        .time_limit = null,
        .starting_money = 10000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_RPG_Trooper", "GLA_Terrorist", "GLA_Technical", "GLA_Scorpion", "GLA_Marauder_Tank", "GLA_SCUD_Launcher", "GLA_Jarmen_Kell" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks", "GLA_Palace", "GLA_Black_Market" },
        .rewards = &[_][]const u8{ "Unlock SCUD Storm" },
        .unlocks = &[_][]const u8{ "GLA_SCUD_Storm" },
    },
    .{
        .name = "GLA_Mission_06",
        .display_name = "Operation: Storm of Fire",
        .campaign = "GLA",
        .mission_number = 6,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "GLA_06_Storm_Fire",
        .briefing = "China and USA have united against us. No matter. We have our SCUD Storm. Rain fire upon them. Let them see the price of opposing the GLA.",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .Destroy, .description = "Destroy Chinese and USA bases", .required = true },
            .{ .objective_type = .Defend, .description = "Protect SCUD Storm", .required = true },
            .{ .objective_type = .Survive, .description = "Withstand superweapon attacks", .required = true },
        },
        .time_limit = null,
        .starting_money = 15000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_RPG_Trooper", "GLA_Terrorist", "GLA_Technical", "GLA_Scorpion", "GLA_Marauder_Tank", "GLA_SCUD_Launcher", "GLA_Bomb_Truck" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks", "GLA_Palace", "GLA_Black_Market", "GLA_SCUD_Storm" },
        .rewards = &[_][]const u8{ "Unlock Anthrax Gamma" },
        .unlocks = &[_][]const u8{ "GLA_Anthrax_Gamma" },
    },
    .{
        .name = "GLA_Mission_07",
        .display_name = "Operation: Scorpion's Sting",
        .campaign = "GLA",
        .mission_number = 7,
        .mission_type = .Story,
        .difficulty = .Hard,
        .map_name = "GLA_07_Scorpion_Sting",
        .briefing = "This is our moment of triumph. The final battle. Destroy the combined forces of our enemies. Show the world that the GLA cannot be defeated. Victory or death!",
        .objectives = &[_]MissionObjective{
            .{ .objective_type = .DestroyAll, .description = "Destroy all enemy forces", .required = true },
            .{ .objective_type = .Destroy, .description = "Destroy Particle Cannon and Nuclear Missile", .required = true },
            .{ .objective_type = .Survive, .description = "Survive final assault", .required = true },
        },
        .time_limit = null,
        .starting_money = 20000,
        .available_units = &[_][]const u8{ "GLA_Rebel", "GLA_RPG_Trooper", "GLA_Terrorist", "GLA_Saboteur", "GLA_Technical", "GLA_Scorpion", "GLA_Marauder_Tank", "GLA_SCUD_Launcher", "GLA_Bomb_Truck", "GLA_Jarmen_Kell" },
        .available_buildings = &[_][]const u8{ "GLA_Supply_Stash", "GLA_Arms_Dealer", "GLA_Barracks", "GLA_Palace", "GLA_Black_Market", "GLA_SCUD_Storm", "GLA_Stinger_Site" },
        .rewards = &[_][]const u8{ "Campaign Complete", "Unlock All GLA Units" },
        .unlocks = &[_][]const u8{ "All_GLA_Units" },
    },
};

pub fn getMissionDef(name: []const u8) ?*const MissionDef {
    for (&MISSION_DATABASE) |*mission| {
        if (std.mem.eql(u8, mission.name, name)) return mission;
    }
    return null;
}

pub fn getMissionsByCampaign(campaign: []const u8) []const MissionDef {
    var count: usize = 0;
    for (MISSION_DATABASE) |mission| {
        if (std.mem.eql(u8, mission.campaign, campaign)) count += 1;
    }
    // Simplified - real implementation would use allocator
    return &[_]MissionDef{};
}

pub fn getMissionCount() usize {
    return MISSION_DATABASE.len;
}

pub fn getCampaignCount() usize {
    return 3; // USA, China, GLA
}
