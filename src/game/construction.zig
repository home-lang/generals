// Building construction system
const std = @import("std");
const types = @import("types.zig");

// Construction state for buildings being built
pub const ConstructionState = enum {
    None,
    Placing, // Player is positioning the building
    Building, // Building is under construction
    Complete,
};

// Building placement data
pub const BuildPlacement = struct {
    building_type: types.BuildingType,
    x: f32,
    y: f32,
    is_valid: bool, // Can it be placed here?
    faction: types.Faction,

    pub fn init(btype: types.BuildingType, faction: types.Faction) BuildPlacement {
        return BuildPlacement{
            .building_type = btype,
            .x = 0,
            .y = 0,
            .is_valid = false,
            .faction = faction,
        };
    }

    pub fn updatePosition(self: *BuildPlacement, x: f32, y: f32) void {
        self.x = x;
        self.y = y;
        // For now, always valid if on screen
        self.is_valid = x > 0 and y > 50 and x < 1280 - 100 and y < 720 - 150;
    }
};

// Construction site - a building under construction
pub const ConstructionSite = struct {
    building_type: types.BuildingType,
    x: f32,
    y: f32,
    faction: types.Faction,
    progress: f32, // 0.0 to 1.0
    build_time: f32, // Total time to build
    is_active: bool,

    pub fn create(btype: types.BuildingType, x: f32, y: f32, faction: types.Faction) ConstructionSite {
        const stats = types.getBuildingStats(btype);
        return ConstructionSite{
            .building_type = btype,
            .x = x,
            .y = y,
            .faction = faction,
            .progress = 0,
            .build_time = stats.build_time,
            .is_active = true,
        };
    }

    // Update construction progress
    // Returns true if construction is complete
    pub fn update(self: *ConstructionSite, dt: f32) bool {
        if (!self.is_active) return false;

        self.progress += dt / self.build_time;
        if (self.progress >= 1.0) {
            self.progress = 1.0;
            return true;
        }
        return false;
    }

    pub fn getWidth(self: *const ConstructionSite) f32 {
        const stats = types.getBuildingStats(self.building_type);
        return stats.width;
    }

    pub fn getHeight(self: *const ConstructionSite) f32 {
        const stats = types.getBuildingStats(self.building_type);
        return stats.height;
    }
};

pub const MAX_CONSTRUCTION_SITES = 8;

pub const ConstructionManager = struct {
    sites: [MAX_CONSTRUCTION_SITES]ConstructionSite,
    count: usize,

    // Current placement mode
    placement_mode: bool,
    current_placement: ?BuildPlacement,

    pub fn init() ConstructionManager {
        return ConstructionManager{
            .sites = undefined,
            .count = 0,
            .placement_mode = false,
            .current_placement = null,
        };
    }

    // Start placing a building
    pub fn startPlacement(self: *ConstructionManager, btype: types.BuildingType, faction: types.Faction) void {
        self.placement_mode = true;
        self.current_placement = BuildPlacement.init(btype, faction);
    }

    // Cancel placement
    pub fn cancelPlacement(self: *ConstructionManager) void {
        self.placement_mode = false;
        self.current_placement = null;
    }

    // Update placement position
    pub fn updatePlacementPosition(self: *ConstructionManager, x: f32, y: f32) void {
        if (self.current_placement) |*placement| {
            placement.updatePosition(x, y);
        }
    }

    // Confirm placement and start construction
    pub fn confirmPlacement(self: *ConstructionManager) ?usize {
        if (self.current_placement) |placement| {
            if (!placement.is_valid) return null;
            if (self.count >= MAX_CONSTRUCTION_SITES) return null;

            self.sites[self.count] = ConstructionSite.create(
                placement.building_type,
                placement.x,
                placement.y,
                placement.faction,
            );
            self.count += 1;

            self.placement_mode = false;
            self.current_placement = null;

            return self.count - 1;
        }
        return null;
    }

    // Update all construction sites
    // Returns index of completed site, or null
    pub fn update(self: *ConstructionManager, dt: f32) ?usize {
        var completed_idx: ?usize = null;

        for (self.sites[0..self.count], 0..) |*site, i| {
            if (site.is_active and site.update(dt)) {
                completed_idx = i;
                break;
            }
        }

        return completed_idx;
    }

    // Remove a construction site (after building is placed)
    pub fn removeSite(self: *ConstructionManager, idx: usize) void {
        if (idx >= self.count) return;

        // Swap with last and decrement count
        if (idx < self.count - 1) {
            self.sites[idx] = self.sites[self.count - 1];
        }
        self.count -= 1;
    }

    pub fn getSite(self: *ConstructionManager, idx: usize) ?*ConstructionSite {
        if (idx >= self.count) return null;
        return &self.sites[idx];
    }

    pub fn isPlacing(self: *const ConstructionManager) bool {
        return self.placement_mode;
    }

    pub fn getPlacement(self: *const ConstructionManager) ?*const BuildPlacement {
        if (self.current_placement) |*p| {
            return p;
        }
        return null;
    }
};
