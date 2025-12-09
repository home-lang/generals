// Game module root
// Re-exports all game-related modules for convenience

pub const types = @import("types.zig");
pub const units = @import("units.zig");
pub const buildings = @import("buildings.zig");
pub const combat = @import("combat.zig");
pub const state = @import("state.zig");
pub const fog = @import("fog.zig");
pub const ai = @import("ai.zig");

// Re-export commonly used types at top level
pub const Faction = types.Faction;
pub const UnitType = types.UnitType;
pub const BuildingType = types.BuildingType;
pub const GameMode = types.GameMode;
pub const UnitStats = types.UnitStats;
pub const getUnitStats = types.getUnitStats;

pub const Unit = units.Unit;
pub const UnitManager = units.UnitManager;
pub const MAX_UNITS = units.MAX_UNITS;

pub const Building = buildings.Building;
pub const BuildingManager = buildings.BuildingManager;
pub const ProductionQueue = buildings.ProductionQueue;
pub const ProductionItem = buildings.ProductionItem;
pub const MAX_BUILDINGS = buildings.MAX_BUILDINGS;

pub const GameState = state.GameState;
pub const CombatSystem = combat.CombatSystem;

pub const FogOfWar = fog.FogOfWar;
pub const FogState = fog.FogState;
pub const FOG_TILE_SIZE = fog.FOG_TILE_SIZE;
pub const FOG_MAP_WIDTH = fog.FOG_MAP_WIDTH;
pub const FOG_MAP_HEIGHT = fog.FOG_MAP_HEIGHT;

pub const AIController = ai.AIController;
pub const AIState = ai.AIState;
