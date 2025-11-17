// C&C Generals - Input System
// Mouse, keyboard, and unit selection

const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }

    pub fn distance(self: Vec2, other: Vec2) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        return @sqrt(dx * dx + dy * dy);
    }
};

pub const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn contains(self: Rect, point: Vec2) bool {
        return point.x >= self.x and
            point.x <= self.x + self.width and
            point.y >= self.y and
            point.y <= self.y + self.height;
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return !(self.x + self.width < other.x or
            other.x + other.width < self.x or
            self.y + self.height < other.y or
            other.y + other.height < self.y);
    }
};

/// Mouse button states
pub const MouseButton = enum {
    Left,
    Right,
    Middle,
};

/// Keyboard key codes
pub const Key = enum {
    Unknown,
    W,
    A,
    S,
    D,
    Q,
    E,
    Space,
    Shift,
    Ctrl,
    Alt,
    Escape,
    Enter,
    Delete,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    Num0,
};

/// Mouse state
pub const MouseState = struct {
    position: Vec2,
    delta: Vec2,
    left_pressed: bool,
    left_down: bool,
    left_released: bool,
    right_pressed: bool,
    right_down: bool,
    right_released: bool,
    middle_pressed: bool,
    middle_down: bool,
    middle_released: bool,
    scroll_delta: f32,
    drag_start: ?Vec2,
    drag_end: ?Vec2,
    is_dragging: bool,

    pub fn init() MouseState {
        return MouseState{
            .position = Vec2.init(0, 0),
            .delta = Vec2.init(0, 0),
            .left_pressed = false,
            .left_down = false,
            .left_released = false,
            .right_pressed = false,
            .right_down = false,
            .right_released = false,
            .middle_pressed = false,
            .middle_down = false,
            .middle_released = false,
            .scroll_delta = 0,
            .drag_start = null,
            .drag_end = null,
            .is_dragging = false,
        };
    }

    pub fn updateButton(self: *MouseState, button: MouseButton, pressed: bool) void {
        switch (button) {
            .Left => {
                self.left_pressed = pressed and !self.left_down;
                self.left_released = !pressed and self.left_down;
                self.left_down = pressed;

                if (self.left_pressed) {
                    self.drag_start = self.position;
                    self.is_dragging = true;
                } else if (self.left_released) {
                    self.drag_end = self.position;
                    self.is_dragging = false;
                }
            },
            .Right => {
                self.right_pressed = pressed and !self.right_down;
                self.right_released = !pressed and self.right_down;
                self.right_down = pressed;
            },
            .Middle => {
                self.middle_pressed = pressed and !self.middle_down;
                self.middle_released = !pressed and self.middle_down;
                self.middle_down = pressed;
            },
        }
    }

    pub fn updatePosition(self: *MouseState, new_pos: Vec2) void {
        self.delta = Vec2.init(new_pos.x - self.position.x, new_pos.y - self.position.y);
        self.position = new_pos;
    }

    pub fn getDragRect(self: *MouseState) ?Rect {
        if (self.drag_start == null or !self.is_dragging) return null;

        const start = self.drag_start.?;
        const end = self.position;

        const min_x = @min(start.x, end.x);
        const min_y = @min(start.y, end.y);
        const max_x = @max(start.x, end.x);
        const max_y = @max(start.y, end.y);

        return Rect{
            .x = min_x,
            .y = min_y,
            .width = max_x - min_x,
            .height = max_y - min_y,
        };
    }
};

/// Keyboard state
pub const KeyboardState = struct {
    keys_down: [256]bool,
    keys_pressed: [256]bool,
    keys_released: [256]bool,

    pub fn init() KeyboardState {
        return KeyboardState{
            .keys_down = [_]bool{false} ** 256,
            .keys_pressed = [_]bool{false} ** 256,
            .keys_released = [_]bool{false} ** 256,
        };
    }

    pub fn updateKey(self: *KeyboardState, key: Key, pressed: bool) void {
        const index = @intFromEnum(key);
        if (index >= 256) return;

        self.keys_pressed[index] = pressed and !self.keys_down[index];
        self.keys_released[index] = !pressed and self.keys_down[index];
        self.keys_down[index] = pressed;
    }

    pub fn isKeyDown(self: *KeyboardState, key: Key) bool {
        const index = @intFromEnum(key);
        if (index >= 256) return false;
        return self.keys_down[index];
    }

    pub fn isKeyPressed(self: *KeyboardState, key: Key) bool {
        const index = @intFromEnum(key);
        if (index >= 256) return false;
        return self.keys_pressed[index];
    }

    pub fn isKeyReleased(self: *KeyboardState, key: Key) bool {
        const index = @intFromEnum(key);
        if (index >= 256) return false;
        return self.keys_released[index];
    }

    pub fn resetFrame(self: *KeyboardState) void {
        for (&self.keys_pressed) |*pressed| {
            pressed.* = false;
        }
        for (&self.keys_released) |*released| {
            released.* = false;
        }
    }
};

/// Selectable entity (unit/building)
pub const SelectableEntity = struct {
    id: usize,
    position: Vec2,
    radius: f32,
    is_selected: bool,
    selection_priority: u32, // Higher = selected first

    pub fn isPointInside(self: *SelectableEntity, point: Vec2) bool {
        return self.position.distance(point) <= self.radius;
    }

    pub fn isInsideRect(self: *SelectableEntity, rect: Rect) bool {
        const center = self.position;
        const rect_center = Vec2.init(rect.x + rect.width / 2, rect.y + rect.height / 2);
        const half_width = rect.width / 2;
        const half_height = rect.height / 2;

        const dx = @abs(center.x - rect_center.x);
        const dy = @abs(center.y - rect_center.y);

        if (dx > (half_width + self.radius)) return false;
        if (dy > (half_height + self.radius)) return false;

        if (dx <= half_width) return true;
        if (dy <= half_height) return true;

        const corner_dist_sq = (dx - half_width) * (dx - half_width) +
            (dy - half_height) * (dy - half_height);

        return corner_dist_sq <= (self.radius * self.radius);
    }
};

/// Selection manager
pub const SelectionManager = struct {
    allocator: std.mem.Allocator,
    selected_entities: []usize,
    selected_count: usize,
    max_selection: usize,

    pub fn init(allocator: std.mem.Allocator, max_selection: usize) !SelectionManager {
        const selected_entities = try allocator.alloc(usize, max_selection);

        return SelectionManager{
            .allocator = allocator,
            .selected_entities = selected_entities,
            .selected_count = 0,
            .max_selection = max_selection,
        };
    }

    pub fn deinit(self: *SelectionManager) void {
        self.allocator.free(self.selected_entities);
    }

    pub fn clearSelection(self: *SelectionManager) void {
        self.selected_count = 0;
    }

    pub fn selectEntity(self: *SelectionManager, entity_id: usize) !void {
        // Check if already selected
        for (self.selected_entities[0..self.selected_count]) |id| {
            if (id == entity_id) return;
        }

        if (self.selected_count >= self.max_selection) return error.SelectionFull;

        self.selected_entities[self.selected_count] = entity_id;
        self.selected_count += 1;
    }

    pub fn deselectEntity(self: *SelectionManager, entity_id: usize) void {
        var i: usize = 0;
        while (i < self.selected_count) {
            if (self.selected_entities[i] == entity_id) {
                // Shift remaining elements
                if (i < self.selected_count - 1) {
                    var j = i;
                    while (j < self.selected_count - 1) : (j += 1) {
                        self.selected_entities[j] = self.selected_entities[j + 1];
                    }
                }
                self.selected_count -= 1;
                return;
            }
            i += 1;
        }
    }

    pub fn isSelected(self: *SelectionManager, entity_id: usize) bool {
        for (self.selected_entities[0..self.selected_count]) |id| {
            if (id == entity_id) return true;
        }
        return false;
    }

    pub fn getSelectedCount(self: *SelectionManager) usize {
        return self.selected_count;
    }
};

/// Input manager
pub const InputManager = struct {
    allocator: std.mem.Allocator,
    mouse: MouseState,
    keyboard: KeyboardState,
    selection: SelectionManager,
    camera_speed: f32,
    edge_pan_margin: f32,
    screen_width: f32,
    screen_height: f32,

    pub fn init(allocator: std.mem.Allocator, screen_width: f32, screen_height: f32) !InputManager {
        return InputManager{
            .allocator = allocator,
            .mouse = MouseState.init(),
            .keyboard = KeyboardState.init(),
            .selection = try SelectionManager.init(allocator, 100),
            .camera_speed = 500.0,
            .edge_pan_margin = 10.0,
            .screen_width = screen_width,
            .screen_height = screen_height,
        };
    }

    pub fn deinit(self: *InputManager) void {
        self.selection.deinit();
    }

    pub fn update(self: *InputManager, delta_time: f32) void {
        _ = delta_time;
        self.keyboard.resetFrame();
    }

    pub fn handleMouseButton(self: *InputManager, button: MouseButton, pressed: bool) void {
        self.mouse.updateButton(button, pressed);
    }

    pub fn handleMouseMove(self: *InputManager, x: f32, y: f32) void {
        self.mouse.updatePosition(Vec2.init(x, y));
    }

    pub fn handleMouseScroll(self: *InputManager, delta: f32) void {
        self.mouse.scroll_delta = delta;
    }

    pub fn handleKeyPress(self: *InputManager, key: Key, pressed: bool) void {
        self.keyboard.updateKey(key, pressed);
    }

    pub fn getCameraPanDirection(self: *InputManager) Vec2 {
        var direction = Vec2.init(0, 0);

        // Keyboard camera movement (WASD)
        if (self.keyboard.isKeyDown(.W)) direction.y -= 1.0;
        if (self.keyboard.isKeyDown(.S)) direction.y += 1.0;
        if (self.keyboard.isKeyDown(.A)) direction.x -= 1.0;
        if (self.keyboard.isKeyDown(.D)) direction.x += 1.0;

        // Edge panning
        if (self.mouse.position.x < self.edge_pan_margin) {
            direction.x -= 1.0;
        } else if (self.mouse.position.x > self.screen_width - self.edge_pan_margin) {
            direction.x += 1.0;
        }

        if (self.mouse.position.y < self.edge_pan_margin) {
            direction.y -= 1.0;
        } else if (self.mouse.position.y > self.screen_height - self.edge_pan_margin) {
            direction.y += 1.0;
        }

        return direction;
    }

    pub fn selectEntitiesInRect(
        self: *InputManager,
        entities: []SelectableEntity,
        add_to_selection: bool,
    ) !void {
        const drag_rect = self.mouse.getDragRect() orelse return;

        if (!add_to_selection) {
            self.selection.clearSelection();
        }

        for (entities) |*entity| {
            if (entity.isInsideRect(drag_rect)) {
                try self.selection.selectEntity(entity.id);
                entity.is_selected = true;
            } else if (!add_to_selection) {
                entity.is_selected = false;
            }
        }
    }

    pub fn selectEntityAtPoint(
        self: *InputManager,
        entities: []SelectableEntity,
        point: Vec2,
        add_to_selection: bool,
    ) !void {
        if (!add_to_selection) {
            self.selection.clearSelection();
            for (entities) |*entity| {
                entity.is_selected = false;
            }
        }

        // Find closest entity to click point
        var closest_entity: ?*SelectableEntity = null;
        var closest_dist: f32 = std.math.floatMax(f32);

        for (entities) |*entity| {
            if (entity.isPointInside(point)) {
                const dist = entity.position.distance(point);
                if (dist < closest_dist) {
                    closest_dist = dist;
                    closest_entity = entity;
                }
            }
        }

        if (closest_entity) |entity| {
            try self.selection.selectEntity(entity.id);
            entity.is_selected = true;
        }
    }

    pub fn getStats(self: *InputManager) InputStats {
        return InputStats{
            .mouse_position = self.mouse.position,
            .selected_count = self.selection.selected_count,
            .is_dragging = self.mouse.is_dragging,
            .keys_down = countKeysDown(&self.keyboard),
        };
    }

    fn countKeysDown(keyboard: *const KeyboardState) usize {
        var count: usize = 0;
        for (keyboard.keys_down) |is_down| {
            if (is_down) count += 1;
        }
        return count;
    }
};

pub const InputStats = struct {
    mouse_position: Vec2,
    selected_count: usize,
    is_dragging: bool,
    keys_down: usize,
};

// Tests
test "Mouse state" {
    var mouse = MouseState.init();

    mouse.updateButton(.Left, true);
    try std.testing.expect(mouse.left_pressed == true);
    try std.testing.expect(mouse.left_down == true);

    mouse.updateButton(.Left, true);
    try std.testing.expect(mouse.left_pressed == false);
    try std.testing.expect(mouse.left_down == true);
}

test "Keyboard state" {
    var keyboard = KeyboardState.init();

    keyboard.updateKey(.W, true);
    try std.testing.expect(keyboard.isKeyDown(.W) == true);
    try std.testing.expect(keyboard.isKeyPressed(.W) == true);

    keyboard.resetFrame();
    try std.testing.expect(keyboard.isKeyPressed(.W) == false);
    try std.testing.expect(keyboard.isKeyDown(.W) == true);
}

test "Selection manager" {
    const allocator = std.testing.allocator;

    var manager = try SelectionManager.init(allocator, 10);
    defer manager.deinit();

    try manager.selectEntity(1);
    try manager.selectEntity(2);
    try manager.selectEntity(3);

    try std.testing.expect(manager.getSelectedCount() == 3);
    try std.testing.expect(manager.isSelected(2) == true);

    manager.deselectEntity(2);
    try std.testing.expect(manager.getSelectedCount() == 2);
    try std.testing.expect(manager.isSelected(2) == false);
}

test "Input manager" {
    const allocator = std.testing.allocator;

    var manager = try InputManager.init(allocator, 1920, 1080);
    defer manager.deinit();

    manager.handleMouseMove(100, 200);
    try std.testing.expect(manager.mouse.position.x == 100);
    try std.testing.expect(manager.mouse.position.y == 200);

    manager.handleKeyPress(.W, true);
    try std.testing.expect(manager.keyboard.isKeyDown(.W) == true);
}
