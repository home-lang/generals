// ============================================================================
// Formations System - Complete Implementation
// Based on Thyme's formation architecture
// ============================================================================
//
// Formations provide organized unit movement and positioning in groups.
// C&C Generals uses formations for:
// - Group movement (maintain relative positions)
// - Combat effectiveness (spread units, flanking)
// - Line of sight and fire arcs
// - Strategic positioning
//
// References:
// - Thyme/src/game/logic/object/armedunit.h (FormationID)
// - Thyme/src/game/common/formation.h

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const Vec3 = math.Vec3(f32);

// ============================================================================
// Phase 1: Formation Types (from C&C Generals)
// ============================================================================

pub const FormationType = enum(u8) {
    TIGHT_LINE,           // Tight horizontal line
    LOOSE_LINE,           // Spread out horizontal line
    COLUMN,               // Single file column
    WEDGE,                // V-shaped wedge
    SCATTERED,            // Random scattered positions
    TIGHT_CIRCLE,         // Defensive circle
    LOOSE_CIRCLE,         // Loose defensive circle
    CUSTOM_1,             // Mission-specific
    CUSTOM_2,
    CUSTOM_3,
    COUNT,
};

// ============================================================================
// Phase 2: Formation Position Entry
// ============================================================================

pub const FormationPositionEntry = struct {
    offset: Vec2,           // Offset from formation center
    angle: f32,             // Facing angle relative to formation
    priority: u8,           // Priority for slot assignment (0 = highest)

    pub fn init(offset: Vec2, angle: f32, priority: u8) FormationPositionEntry {
        return .{
            .offset = offset,
            .angle = angle,
            .priority = priority,
        };
    }
};

// ============================================================================
// Phase 3: Formation Template
// ============================================================================

pub const FormationTemplate = struct {
    formation_type: FormationType,
    name: []const u8,
    positions: std.ArrayList(FormationPositionEntry),
    max_units: u32,
    spacing: f32,           // Base spacing between units
    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        formation_type: FormationType,
        name: []const u8,
        spacing: f32,
        max_units: u32,
    ) !FormationTemplate {
        return FormationTemplate{
            .formation_type = formation_type,
            .name = try allocator.dupe(u8, name),
            .positions = std.ArrayList(FormationPositionEntry){},
            .max_units = max_units,
            .spacing = spacing,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FormationTemplate) void {
        self.allocator.free(self.name);
        self.positions.deinit(self.allocator);
    }

    pub fn addPosition(self: *FormationTemplate, position: FormationPositionEntry) !void {
        try self.positions.append(self.allocator, position);
    }

    /// Generate positions procedurally based on formation type
    pub fn generatePositions(self: *FormationTemplate) !void {
        switch (self.formation_type) {
            .TIGHT_LINE => try self.generateLine(1.0),
            .LOOSE_LINE => try self.generateLine(2.5),
            .COLUMN => try self.generateColumn(1.2),
            .WEDGE => try self.generateWedge(),
            .SCATTERED => try self.generateScattered(),
            .TIGHT_CIRCLE => try self.generateCircle(1.0),
            .LOOSE_CIRCLE => try self.generateCircle(2.0),
            else => {},
        }
    }

    fn generateLine(self: *FormationTemplate, spacing_multiplier: f32) !void {
        const effective_spacing = self.spacing * spacing_multiplier;
        const half_width = @as(f32, @floatFromInt(self.max_units)) * effective_spacing * 0.5;

        var i: u32 = 0;
        while (i < self.max_units) : (i += 1) {
            const x = -half_width + @as(f32, @floatFromInt(i)) * effective_spacing;
            const pos = FormationPositionEntry.init(
                Vec2.init(x, 0.0),
                0.0,
                @as(u8, @intCast(i)),
            );
            try self.addPosition(pos);
        }
    }

    fn generateColumn(self: *FormationTemplate, spacing_multiplier: f32) !void {
        const effective_spacing = self.spacing * spacing_multiplier;

        var i: u32 = 0;
        while (i < self.max_units) : (i += 1) {
            const y = -@as(f32, @floatFromInt(i)) * effective_spacing;
            const pos = FormationPositionEntry.init(
                Vec2.init(0.0, y),
                0.0,
                @as(u8, @intCast(i)),
            );
            try self.addPosition(pos);
        }
    }

    fn generateWedge(self: *FormationTemplate) !void {
        // V-shaped formation: leader at front, units spread back
        const pos_leader = FormationPositionEntry.init(Vec2.init(0.0, 0.0), 0.0, 0);
        try self.addPosition(pos_leader);

        var i: u32 = 1;
        var row: u32 = 1;
        while (i < self.max_units) : (i += 1) {
            const side: f32 = if ((i - 1) % 2 == 0) -1.0 else 1.0;
            const slot: u32 = (i - 1) / 2 + 1;

            const x = side * @as(f32, @floatFromInt(slot)) * self.spacing;
            const y = -@as(f32, @floatFromInt(row)) * self.spacing;

            const pos = FormationPositionEntry.init(
                Vec2.init(x, y),
                0.0,
                @as(u8, @intCast(i)),
            );
            try self.addPosition(pos);

            if ((i - 1) % 2 == 1) {
                row += 1;
            }
        }
    }

    fn generateScattered(self: *FormationTemplate) !void {
        var prng = std.Random.DefaultPrng.init(12345);
        const random = prng.random();

        const radius = self.spacing * @sqrt(@as(f32, @floatFromInt(self.max_units)));

        var i: u32 = 0;
        while (i < self.max_units) : (i += 1) {
            const angle = random.float(f32) * std.math.pi * 2.0;
            const dist = random.float(f32) * radius;

            const x = @cos(angle) * dist;
            const y = @sin(angle) * dist;

            const pos = FormationPositionEntry.init(
                Vec2.init(x, y),
                angle,
                @as(u8, @intCast(i)),
            );
            try self.addPosition(pos);
        }
    }

    fn generateCircle(self: *FormationTemplate, spacing_multiplier: f32) !void {
        const effective_spacing = self.spacing * spacing_multiplier;
        const radius = effective_spacing * @as(f32, @floatFromInt(self.max_units)) / (2.0 * std.math.pi);

        var i: u32 = 0;
        while (i < self.max_units) : (i += 1) {
            const angle = @as(f32, @floatFromInt(i)) * (2.0 * std.math.pi / @as(f32, @floatFromInt(self.max_units)));
            const x = @cos(angle) * radius;
            const y = @sin(angle) * radius;

            const pos = FormationPositionEntry.init(
                Vec2.init(x, y),
                angle,
                @as(u8, @intCast(i)),
            );
            try self.addPosition(pos);
        }
    }
};

// ============================================================================
// Phase 4: Formation Assignment (Slots)
// ============================================================================

pub const FormationSlot = struct {
    position_index: u32,    // Index into template positions
    unit_id: ?u32,          // Assigned unit ID (null if empty)
    world_position: Vec2,   // Calculated world position
    world_angle: f32,       // Calculated world angle
};

// ============================================================================
// Phase 5: Formation Instance (Active Formation)
// ============================================================================

pub const Formation = struct {
    id: u32,
    template: *const FormationTemplate,
    center: Vec2,           // Formation center position
    angle: f32,             // Formation facing angle
    slots: std.ArrayList(FormationSlot),
    allocator: Allocator,

    pub fn init(allocator: Allocator, id: u32, template: *const FormationTemplate, center: Vec2, angle: f32) !Formation {
        var slots = std.ArrayList(FormationSlot){};

        // Create slots from template positions
        for (template.positions.items, 0..) |entry, i| {
            const slot = FormationSlot{
                .position_index = @as(u32, @intCast(i)),
                .unit_id = null,
                .world_position = calculateWorldPosition(center, angle, entry.offset),
                .world_angle = normalizeAngle(angle + entry.angle),
            };
            try slots.append(allocator, slot);
        }

        return Formation{
            .id = id,
            .template = template,
            .center = center,
            .angle = angle,
            .slots = slots,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Formation) void {
        self.slots.deinit(self.allocator);
    }

    /// Assign a unit to the nearest available slot
    pub fn assignUnit(self: *Formation, unit_id: u32, unit_pos: Vec2) ?u32 {
        var best_slot_idx: ?usize = null;
        var best_dist: f32 = std.math.floatMax(f32);

        for (self.slots.items, 0..) |*slot, i| {
            if (slot.unit_id != null) continue;

            const dx = slot.world_position.x - unit_pos.x;
            const dy = slot.world_position.y - unit_pos.y;
            const dist = @sqrt(dx * dx + dy * dy);

            if (dist < best_dist) {
                best_dist = dist;
                best_slot_idx = i;
            }
        }

        if (best_slot_idx) |idx| {
            self.slots.items[idx].unit_id = unit_id;
            return @as(u32, @intCast(idx));
        }

        return null;
    }

    /// Remove a unit from the formation
    pub fn removeUnit(self: *Formation, unit_id: u32) bool {
        for (self.slots.items) |*slot| {
            if (slot.unit_id) |id| {
                if (id == unit_id) {
                    slot.unit_id = null;
                    return true;
                }
            }
        }
        return false;
    }

    /// Update formation center and recalculate all slot positions
    pub fn updatePosition(self: *Formation, new_center: Vec2, new_angle: f32) void {
        self.center = new_center;
        self.angle = new_angle;

        for (self.slots.items, 0..) |*slot, i| {
            const entry = self.template.positions.items[i];
            slot.world_position = calculateWorldPosition(new_center, new_angle, entry.offset);
            slot.world_angle = normalizeAngle(new_angle + entry.angle);
        }
    }

    /// Get the world position for a specific slot
    pub fn getSlotPosition(self: Formation, slot_index: u32) ?Vec2 {
        if (slot_index >= self.slots.items.len) return null;
        return self.slots.items[slot_index].world_position;
    }

    /// Get the world angle for a specific slot
    pub fn getSlotAngle(self: Formation, slot_index: u32) ?f32 {
        if (slot_index >= self.slots.items.len) return null;
        return self.slots.items[slot_index].world_angle;
    }

    /// Count assigned units
    pub fn getUnitCount(self: Formation) u32 {
        var count: u32 = 0;
        for (self.slots.items) |slot| {
            if (slot.unit_id != null) count += 1;
        }
        return count;
    }

    /// Check if formation is full
    pub fn isFull(self: Formation) bool {
        return self.getUnitCount() == self.template.max_units;
    }

    /// Check if formation is empty
    pub fn isEmpty(self: Formation) bool {
        return self.getUnitCount() == 0;
    }
};

// ============================================================================
// Phase 6: Formation Manager
// ============================================================================

pub const FormationManager = struct {
    templates: std.ArrayList(FormationTemplate),
    formations: std.ArrayList(Formation),
    next_formation_id: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator) FormationManager {
        return .{
            .templates = std.ArrayList(FormationTemplate){},
            .formations = std.ArrayList(Formation){},
            .next_formation_id = 1,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *FormationManager) void {
        for (self.templates.items) |*template| {
            template.deinit();
        }
        self.templates.deinit(self.allocator);

        for (self.formations.items) |*formation| {
            formation.deinit();
        }
        self.formations.deinit(self.allocator);
    }

    /// Initialize default C&C Generals formations
    pub fn initializeDefaults(self: *FormationManager) !void {
        // Tight line formation
        var tight_line = try FormationTemplate.init(self.allocator, .TIGHT_LINE, "TightLine", 10.0, 20);
        try tight_line.generatePositions();
        try self.templates.append(self.allocator, tight_line);

        // Loose line formation
        var loose_line = try FormationTemplate.init(self.allocator, .LOOSE_LINE, "LooseLine", 10.0, 20);
        try loose_line.generatePositions();
        try self.templates.append(self.allocator, loose_line);

        // Column formation
        var column = try FormationTemplate.init(self.allocator, .COLUMN, "Column", 10.0, 20);
        try column.generatePositions();
        try self.templates.append(self.allocator, column);

        // Wedge formation
        var wedge = try FormationTemplate.init(self.allocator, .WEDGE, "Wedge", 12.0, 20);
        try wedge.generatePositions();
        try self.templates.append(self.allocator, wedge);

        // Scattered formation
        var scattered = try FormationTemplate.init(self.allocator, .SCATTERED, "Scattered", 8.0, 20);
        try scattered.generatePositions();
        try self.templates.append(self.allocator, scattered);

        // Circle formations
        var tight_circle = try FormationTemplate.init(self.allocator, .TIGHT_CIRCLE, "TightCircle", 10.0, 16);
        try tight_circle.generatePositions();
        try self.templates.append(self.allocator, tight_circle);

        var loose_circle = try FormationTemplate.init(self.allocator, .LOOSE_CIRCLE, "LooseCircle", 10.0, 16);
        try loose_circle.generatePositions();
        try self.templates.append(self.allocator, loose_circle);
    }

    /// Get template by type
    pub fn getTemplate(self: *FormationManager, formation_type: FormationType) ?*const FormationTemplate {
        for (self.templates.items) |*template| {
            if (template.formation_type == formation_type) {
                return template;
            }
        }
        return null;
    }

    /// Create a new formation instance
    pub fn createFormation(
        self: *FormationManager,
        formation_type: FormationType,
        center: Vec2,
        angle: f32,
    ) !u32 {
        const template = self.getTemplate(formation_type) orelse return error.TemplateNotFound;

        const id = self.next_formation_id;
        self.next_formation_id += 1;

        const formation = try Formation.init(self.allocator, id, template, center, angle);
        try self.formations.append(self.allocator, formation);

        return id;
    }

    /// Get formation by ID
    pub fn getFormation(self: *FormationManager, formation_id: u32) ?*Formation {
        for (self.formations.items) |*formation| {
            if (formation.id == formation_id) {
                return formation;
            }
        }
        return null;
    }

    /// Remove a formation
    pub fn removeFormation(self: *FormationManager, formation_id: u32) bool {
        for (self.formations.items, 0..) |*formation, i| {
            if (formation.id == formation_id) {
                formation.deinit();
                _ = self.formations.swapRemove(i);
                return true;
            }
        }
        return false;
    }

    /// Update all formations
    pub fn update(self: *FormationManager, _: f32) void {
        // Formation positions are updated on-demand via updatePosition()
        // This can be used for dynamic behaviors like rotating formations
        _ = self;
    }

    /// Cleanup empty formations
    pub fn cleanupEmptyFormations(self: *FormationManager) void {
        var i: usize = 0;
        while (i < self.formations.items.len) {
            if (self.formations.items[i].isEmpty()) {
                self.formations.items[i].deinit();
                _ = self.formations.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
};

// ============================================================================
// Utility Functions
// ============================================================================

fn calculateWorldPosition(center: Vec2, angle: f32, offset: Vec2) Vec2 {
    const cos_a = @cos(angle);
    const sin_a = @sin(angle);

    const rotated_x = offset.x * cos_a - offset.y * sin_a;
    const rotated_y = offset.x * sin_a + offset.y * cos_a;

    return Vec2.init(
        center.x + rotated_x,
        center.y + rotated_y,
    );
}

fn normalizeAngle(angle: f32) f32 {
    var result = angle;
    while (result > std.math.pi) result -= 2.0 * std.math.pi;
    while (result < -std.math.pi) result += 2.0 * std.math.pi;
    return result;
}

// ============================================================================
// Tests
// ============================================================================

test "FormationTemplate: line generation" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .TIGHT_LINE, "TestLine", 10.0, 5);
    defer template.deinit();

    try template.generatePositions();

    try std.testing.expectEqual(@as(usize, 5), template.positions.items.len);

    // Check symmetry around center
    const first = template.positions.items[0].offset.x;
    const last = template.positions.items[4].offset.x;
    try std.testing.expectApproxEqAbs(first, -last, 0.1);
}

test "FormationTemplate: wedge generation" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .WEDGE, "TestWedge", 10.0, 7);
    defer template.deinit();

    try template.generatePositions();

    try std.testing.expectEqual(@as(usize, 7), template.positions.items.len);

    // Leader should be at origin
    try std.testing.expectEqual(@as(f32, 0.0), template.positions.items[0].offset.x);
    try std.testing.expectEqual(@as(f32, 0.0), template.positions.items[0].offset.y);
}

test "FormationTemplate: circle generation" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .TIGHT_CIRCLE, "TestCircle", 10.0, 8);
    defer template.deinit();

    try template.generatePositions();

    try std.testing.expectEqual(@as(usize, 8), template.positions.items.len);

    // All positions should be roughly same distance from center
    const first_dist = template.positions.items[0].offset.length();
    for (template.positions.items) |pos| {
        const dist = pos.offset.length();
        try std.testing.expectApproxEqAbs(first_dist, dist, 0.1);
    }
}

test "Formation: slot assignment" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .TIGHT_LINE, "TestLine", 10.0, 5);
    defer template.deinit();
    try template.generatePositions();

    var formation = try Formation.init(allocator, 1, &template, Vec2.init(100.0, 100.0), 0.0);
    defer formation.deinit();

    // Assign units
    const slot1 = formation.assignUnit(101, Vec2.init(90.0, 100.0));
    try std.testing.expect(slot1 != null);

    const slot2 = formation.assignUnit(102, Vec2.init(110.0, 100.0));
    try std.testing.expect(slot2 != null);

    try std.testing.expectEqual(@as(u32, 2), formation.getUnitCount());
}

test "Formation: position updates" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .TIGHT_LINE, "TestLine", 10.0, 3);
    defer template.deinit();
    try template.generatePositions();

    var formation = try Formation.init(allocator, 1, &template, Vec2.init(0.0, 0.0), 0.0);
    defer formation.deinit();

    const old_pos = formation.slots.items[0].world_position;

    // Move formation
    formation.updatePosition(Vec2.init(100.0, 100.0), 0.0);

    const new_pos = formation.slots.items[0].world_position;

    try std.testing.expect(new_pos.x != old_pos.x);
    try std.testing.expect(new_pos.y != old_pos.y);
}

test "Formation: rotation" {
    const allocator = std.testing.allocator;

    var template = try FormationTemplate.init(allocator, .TIGHT_LINE, "TestLine", 10.0, 3);
    defer template.deinit();
    try template.generatePositions();

    var formation = try Formation.init(allocator, 1, &template, Vec2.init(0.0, 0.0), 0.0);
    defer formation.deinit();

    // Rotate 90 degrees
    formation.updatePosition(Vec2.init(0.0, 0.0), std.math.pi / 2.0);

    // Line should now be vertical instead of horizontal
    // (positions rotated by 90 degrees)
    const pos = formation.slots.items[0].world_position;
    try std.testing.expect(@abs(pos.y) > 1.0); // Should have Y offset now
}

test "FormationManager: creation and lookup" {
    const allocator = std.testing.allocator;

    var manager = FormationManager.init(allocator);
    defer manager.deinit();

    try manager.initializeDefaults();

    const template = manager.getTemplate(.WEDGE);
    try std.testing.expect(template != null);
    try std.testing.expectEqual(FormationType.WEDGE, template.?.formation_type);

    const formation_id = try manager.createFormation(.WEDGE, Vec2.init(0.0, 0.0), 0.0);
    const formation = manager.getFormation(formation_id);
    try std.testing.expect(formation != null);
    try std.testing.expectEqual(formation_id, formation.?.id);
}

test "FormationManager: cleanup empty formations" {
    const allocator = std.testing.allocator;

    var manager = FormationManager.init(allocator);
    defer manager.deinit();

    try manager.initializeDefaults();

    const id1 = try manager.createFormation(.TIGHT_LINE, Vec2.init(0.0, 0.0), 0.0);
    const id2 = try manager.createFormation(.WEDGE, Vec2.init(100.0, 100.0), 0.0);

    // id1 is empty, id2 has a unit
    if (manager.getFormation(id2)) |f| {
        _ = f.assignUnit(101, Vec2.init(100.0, 100.0));
    }

    try std.testing.expectEqual(@as(usize, 2), manager.formations.items.len);

    manager.cleanupEmptyFormations();

    // Only formation with unit should remain
    try std.testing.expectEqual(@as(usize, 1), manager.formations.items.len);
    try std.testing.expect(manager.getFormation(id1) == null);
    try std.testing.expect(manager.getFormation(id2) != null);
}

test "calculateWorldPosition: rotation" {
    const center = Vec2.init(100.0, 100.0);
    const offset = Vec2.init(10.0, 0.0);

    // No rotation
    const pos1 = calculateWorldPosition(center, 0.0, offset);
    try std.testing.expectApproxEqAbs(@as(f32, 110.0), pos1.x, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 100.0), pos1.y, 0.01);

    // 90 degree rotation
    const pos2 = calculateWorldPosition(center, std.math.pi / 2.0, offset);
    try std.testing.expectApproxEqAbs(@as(f32, 100.0), pos2.x, 0.01);
    try std.testing.expectApproxEqAbs(@as(f32, 110.0), pos2.y, 0.01);
}

test "normalizeAngle: wrapping" {
    const angle1 = normalizeAngle(4.0 * std.math.pi);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), angle1, 0.01);

    const angle2 = normalizeAngle(-4.0 * std.math.pi);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), angle2, 0.01);

    const angle3 = normalizeAngle(std.math.pi + 0.5);
    try std.testing.expect(angle3 < std.math.pi and angle3 > -std.math.pi);
}
