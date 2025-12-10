// Resource gathering system
const std = @import("std");
const types = @import("types.zig");

// Supply pile (resource deposit on the map)
pub const SupplyPile = struct {
    x: f32,
    y: f32,
    resources: i32,
    max_resources: i32,
    is_depleted: bool,

    pub fn create(x: f32, y: f32, resources: i32) SupplyPile {
        return SupplyPile{
            .x = x,
            .y = y,
            .resources = resources,
            .max_resources = resources,
            .is_depleted = false,
        };
    }

    pub fn harvest(self: *SupplyPile, amount: i32) i32 {
        if (self.is_depleted) return 0;
        const harvested = @min(amount, self.resources);
        self.resources -= harvested;
        if (self.resources <= 0) {
            self.is_depleted = true;
        }
        return harvested;
    }

    pub fn getPercentRemaining(self: *const SupplyPile) f32 {
        if (self.max_resources == 0) return 0;
        return @as(f32, @floatFromInt(self.resources)) / @as(f32, @floatFromInt(self.max_resources));
    }
};

pub const MAX_SUPPLY_PILES = 16;

pub const SupplyManager = struct {
    piles: [MAX_SUPPLY_PILES]SupplyPile,
    count: usize,

    pub fn init() SupplyManager {
        return SupplyManager{
            .piles = undefined,
            .count = 0,
        };
    }

    pub fn addPile(self: *SupplyManager, pile: SupplyPile) ?usize {
        if (self.count >= MAX_SUPPLY_PILES) return null;
        self.piles[self.count] = pile;
        self.count += 1;
        return self.count - 1;
    }

    pub fn findNearest(self: *const SupplyManager, x: f32, y: f32) ?usize {
        var nearest: ?usize = null;
        var nearest_dist: f32 = 100000;

        for (0..self.count) |i| {
            const pile = &self.piles[i];
            if (pile.is_depleted) continue;

            const dx = pile.x - x;
            const dy = pile.y - y;
            const dist = @sqrt(dx * dx + dy * dy);
            if (dist < nearest_dist) {
                nearest_dist = dist;
                nearest = i;
            }
        }
        return nearest;
    }

    pub fn getPile(self: *SupplyManager, idx: usize) ?*SupplyPile {
        if (idx >= self.count) return null;
        return &self.piles[idx];
    }
};

// Worker state for resource gathering
pub const WorkerState = enum {
    Idle,
    MovingToSupply,
    Harvesting,
    ReturningToBase,
    Building, // For construction mode
};

// Worker extension data (stored separately from Unit)
pub const WorkerData = struct {
    state: WorkerState,
    target_pile: ?usize,
    target_building: ?usize, // Supply center to return to
    carried_resources: i32,
    max_carry: i32,
    harvest_timer: f32,
    harvest_time: f32, // Time to harvest one load

    pub fn init() WorkerData {
        return WorkerData{
            .state = .Idle,
            .target_pile = null,
            .target_building = null,
            .carried_resources = 0,
            .max_carry = 300, // Amount carried per trip
            .harvest_timer = 0,
            .harvest_time = 3.0, // 3 seconds to harvest
        };
    }

    pub fn reset(self: *WorkerData) void {
        self.state = .Idle;
        self.target_pile = null;
        self.target_building = null;
        self.carried_resources = 0;
        self.harvest_timer = 0;
    }
};

pub const MAX_WORKERS = 32;

pub const WorkerManager = struct {
    // Maps unit index to worker data
    worker_data: [MAX_WORKERS]WorkerData,
    unit_to_worker: [64]?usize, // Maps unit index to worker data index (64 = MAX_UNITS)
    count: usize,

    pub fn init() WorkerManager {
        var wm = WorkerManager{
            .worker_data = undefined,
            .unit_to_worker = [_]?usize{null} ** 64,
            .count = 0,
        };
        for (0..MAX_WORKERS) |i| {
            wm.worker_data[i] = WorkerData.init();
        }
        return wm;
    }

    pub fn registerWorker(self: *WorkerManager, unit_idx: usize) ?usize {
        if (self.count >= MAX_WORKERS) return null;
        if (unit_idx >= 64) return null;

        const worker_idx = self.count;
        self.worker_data[worker_idx] = WorkerData.init();
        self.unit_to_worker[unit_idx] = worker_idx;
        self.count += 1;
        return worker_idx;
    }

    pub fn getWorkerData(self: *WorkerManager, unit_idx: usize) ?*WorkerData {
        if (unit_idx >= 64) return null;
        if (self.unit_to_worker[unit_idx]) |worker_idx| {
            return &self.worker_data[worker_idx];
        }
        return null;
    }

    pub fn isWorker(self: *const WorkerManager, unit_idx: usize) bool {
        if (unit_idx >= 64) return false;
        return self.unit_to_worker[unit_idx] != null;
    }
};
