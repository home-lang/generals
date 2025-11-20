// Production System for Generals RTS
// Handles building placement and unit production

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const EntityId = @import("entity.zig").EntityId;
const TeamId = @import("entity.zig").TeamId;

/// Production queue item
pub const ProductionItem = struct {
    unit_type: []const u8,
    cost: f32,
    build_time: f32,
    time_elapsed: f32,

    pub fn init(unit_type: []const u8, cost: f32, build_time: f32) ProductionItem {
        return .{
            .unit_type = unit_type,
            .cost = cost,
            .build_time = build_time,
            .time_elapsed = 0.0,
        };
    }

    pub fn update(self: *ProductionItem, dt: f32) bool {
        self.time_elapsed += dt;
        return self.time_elapsed >= self.build_time;
    }

    pub fn getProgress(self: *const ProductionItem) f32 {
        return @min(self.time_elapsed / self.build_time, 1.0);
    }
};

/// Building placement data
pub const BuildingPlacement = struct {
    building_type: []const u8,
    position: Vec2,
    cost: f32,
    is_valid: bool,  // Can be placed here?
    team: TeamId,

    pub fn init(building_type: []const u8, x: f32, y: f32, cost: f32, team: TeamId) BuildingPlacement {
        return .{
            .building_type = building_type,
            .position = Vec2.init(x, y),
            .cost = cost,
            .is_valid = true,
            .team = team,
        };
    }
};

/// Production queue for buildings
pub const ProductionQueue = struct {
    allocator: Allocator,
    queue: std.ArrayList(ProductionItem),
    max_queue_size: usize,
    rally_point: ?Vec2,

    pub fn init(allocator: Allocator, max_size: usize) !ProductionQueue {
        return .{
            .allocator = allocator,
            .queue = try std.ArrayList(ProductionItem).initCapacity(allocator, max_size),
            .max_queue_size = max_size,
            .rally_point = null,
        };
    }

    pub fn deinit(self: *ProductionQueue) void {
        self.queue.deinit(self.allocator);
    }

    pub fn addItem(self: *ProductionQueue, unit_type: []const u8, cost: f32, build_time: f32) !bool {
        if (self.isFull()) return false;

        const item = ProductionItem.init(unit_type, cost, build_time);
        try self.queue.append(self.allocator, item);
        return true;
    }

    pub fn update(self: *ProductionQueue, dt: f32) ?ProductionItem {
        if (self.queue.items.len == 0) return null;

        const dt_f32 = @as(f32, @floatCast(dt));
        var item = &self.queue.items[0];

        if (item.update(dt_f32)) {
            // Production complete
            const completed = item.*;
            _ = self.queue.orderedRemove(0);
            return completed;
        }

        return null;
    }

    pub fn cancelFirst(self: *ProductionQueue) ?ProductionItem {
        if (self.queue.items.len == 0) return null;
        return self.queue.orderedRemove(0);
    }

    pub fn getCurrentItem(self: *const ProductionQueue) ?*const ProductionItem {
        if (self.queue.items.len == 0) return null;
        return &self.queue.items[0];
    }

    pub fn getQueueSize(self: *const ProductionQueue) usize {
        return self.queue.items.len;
    }

    pub fn isFull(self: *const ProductionQueue) bool {
        return self.queue.items.len >= self.max_queue_size;
    }

    pub fn isEmpty(self: *const ProductionQueue) bool {
        return self.queue.items.len == 0;
    }

    pub fn setRallyPoint(self: *ProductionQueue, x: f32, y: f32) void {
        self.rally_point = Vec2.init(x, y);
    }

    pub fn clearRallyPoint(self: *ProductionQueue) void {
        self.rally_point = null;
    }
};

/// Unit template for production
pub const UnitTemplate = struct {
    name: []const u8,
    cost: f32,
    build_time: f32,
    health: f32,
    speed: f32,

    pub fn init(name: []const u8, cost: f32, build_time: f32, health: f32, speed: f32) UnitTemplate {
        return .{
            .name = name,
            .cost = cost,
            .build_time = build_time,
            .health = health,
            .speed = speed,
        };
    }
};

/// Building template
pub const BuildingTemplate = struct {
    name: []const u8,
    cost: f32,
    build_time: f32,
    health: f32,
    width: f32,
    height: f32,
    can_produce_units: bool,

    pub fn init(name: []const u8, cost: f32, build_time: f32, health: f32, width: f32, height: f32) BuildingTemplate {
        return .{
            .name = name,
            .cost = cost,
            .build_time = build_time,
            .health = health,
            .width = width,
            .height = height,
            .can_produce_units = false,
        };
    }

    pub fn withProduction(self: BuildingTemplate) BuildingTemplate {
        var result = self;
        result.can_produce_units = true;
        return result;
    }
};

/// Production manager - handles all production and building placement
pub const ProductionManager = struct {
    allocator: Allocator,
    unit_templates: std.StringHashMap(UnitTemplate),
    building_templates: std.StringHashMap(BuildingTemplate),

    pub fn init(allocator: Allocator) !ProductionManager {
        var manager = ProductionManager{
            .allocator = allocator,
            .unit_templates = std.StringHashMap(UnitTemplate).init(allocator),
            .building_templates = std.StringHashMap(BuildingTemplate).init(allocator),
        };

        // Register default templates
        try manager.registerDefaultTemplates();

        return manager;
    }

    pub fn deinit(self: *ProductionManager) void {
        self.unit_templates.deinit();
        self.building_templates.deinit();
    }

    fn registerDefaultTemplates(self: *ProductionManager) !void {
        // Default units
        try self.registerUnitTemplate("Ranger", 200.0, 5.0, 100.0, 50.0);
        try self.registerUnitTemplate("Tank", 800.0, 15.0, 300.0, 30.0);
        try self.registerUnitTemplate("Worker", 100.0, 3.0, 50.0, 60.0);

        // Default buildings
        try self.registerBuildingTemplate("Barracks", 500.0, 20.0, 1000.0, 128.0, 128.0, true);
        try self.registerBuildingTemplate("WarFactory", 2000.0, 40.0, 2000.0, 192.0, 192.0, true);
        try self.registerBuildingTemplate("SupplyDepot", 800.0, 15.0, 800.0, 96.0, 96.0, false);
    }

    pub fn registerUnitTemplate(self: *ProductionManager, name: []const u8, cost: f32, build_time: f32, health: f32, speed: f32) !void {
        const template = UnitTemplate.init(name, cost, build_time, health, speed);
        try self.unit_templates.put(name, template);
    }

    pub fn registerBuildingTemplate(self: *ProductionManager, name: []const u8, cost: f32, build_time: f32, health: f32, width: f32, height: f32, can_produce: bool) !void {
        var template = BuildingTemplate.init(name, cost, build_time, health, width, height);
        if (can_produce) {
            template = template.withProduction();
        }
        try self.building_templates.put(name, template);
    }

    pub fn getUnitTemplate(self: *const ProductionManager, name: []const u8) ?UnitTemplate {
        return self.unit_templates.get(name);
    }

    pub fn getBuildingTemplate(self: *const ProductionManager, name: []const u8) ?BuildingTemplate {
        return self.building_templates.get(name);
    }

    pub fn canAffordUnit(self: *const ProductionManager, name: []const u8, resources: f32) bool {
        if (self.getUnitTemplate(name)) |template| {
            return resources >= template.cost;
        }
        return false;
    }

    pub fn canAffordBuilding(self: *const ProductionManager, name: []const u8, resources: f32) bool {
        if (self.getBuildingTemplate(name)) |template| {
            return resources >= template.cost;
        }
        return false;
    }
};

// Tests
test "ProductionItem: update and progress" {
    var item = ProductionItem.init("TestUnit", 100.0, 10.0);

    try std.testing.expectEqual(@as(f32, 0.0), item.time_elapsed);
    try std.testing.expectEqual(@as(f32, 0.0), item.getProgress());

    // Update for 5 seconds (50% complete)
    _ = item.update(5.0);
    try std.testing.expectEqual(@as(f32, 5.0), item.time_elapsed);
    try std.testing.expectApproxEqRel(@as(f32, 0.5), item.getProgress(), 0.01);

    // Update for another 5 seconds (100% complete)
    const done = item.update(5.0);
    try std.testing.expect(done);
    try std.testing.expectEqual(@as(f32, 1.0), item.getProgress());
}

test "ProductionQueue: add and update" {
    const allocator = std.testing.allocator;
    var queue = try ProductionQueue.init(allocator, 5);
    defer queue.deinit();

    try std.testing.expect(queue.isEmpty());

    _ = try queue.addItem("Unit1", 100.0, 10.0);
    _ = try queue.addItem("Unit2", 200.0, 15.0);

    try std.testing.expectEqual(@as(usize, 2), queue.getQueueSize());

    // Update for 10 seconds - first item should complete
    const completed = queue.update(10.0);
    try std.testing.expect(completed != null);
    try std.testing.expectEqualStrings("Unit1", completed.?.unit_type);
    try std.testing.expectEqual(@as(usize, 1), queue.getQueueSize());
}

test "ProductionManager: templates" {
    const allocator = std.testing.allocator;
    var manager = try ProductionManager.init(allocator);
    defer manager.deinit();

    // Check default templates exist
    const ranger = manager.getUnitTemplate("Ranger");
    try std.testing.expect(ranger != null);
    try std.testing.expectEqual(@as(f32, 200.0), ranger.?.cost);

    const barracks = manager.getBuildingTemplate("Barracks");
    try std.testing.expect(barracks != null);
    try std.testing.expect(barracks.?.can_produce_units);

    // Test affordability
    try std.testing.expect(manager.canAffordUnit("Ranger", 300.0));
    try std.testing.expect(!manager.canAffordUnit("Tank", 500.0));
}
