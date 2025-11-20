// UI System for Generals RTS
// Handles HUD, resource display, and game interface

const std = @import("std");
const Allocator = std.mem.Allocator;
const math = @import("math");
const Vec2 = math.Vec2(f32);
const PlayerResources = @import("resource.zig").PlayerResources;
const ProductionQueue = @import("production.zig").ProductionQueue;
const EntityId = @import("entity.zig").EntityId;

/// UI Panel - rectangular area for UI elements
pub const UIPanel = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    background_color: [4]f32, // RGBA
    visible: bool,

    pub fn init(x: f32, y: f32, width: f32, height: f32) UIPanel {
        return .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .background_color = [4]f32{ 0.1, 0.1, 0.1, 0.8 }, // Dark gray, semi-transparent
            .visible = true,
        };
    }

    pub fn contains(self: *const UIPanel, px: f32, py: f32) bool {
        return px >= self.x and px <= self.x + self.width and
               py >= self.y and py <= self.y + self.height;
    }

    pub fn setColor(self: *UIPanel, r: f32, g: f32, b: f32, a: f32) void {
        self.background_color = [4]f32{ r, g, b, a };
    }
};

/// UI Button
pub const UIButton = struct {
    panel: UIPanel,
    label: []const u8,
    enabled: bool,
    hovered: bool,
    clicked: bool,

    pub fn init(x: f32, y: f32, width: f32, height: f32, label: []const u8) UIButton {
        return .{
            .panel = UIPanel.init(x, y, width, height),
            .label = label,
            .enabled = true,
            .hovered = false,
            .clicked = false,
        };
    }

    pub fn update(self: *UIButton, mouse_x: f32, mouse_y: f32, mouse_clicked: bool) void {
        self.hovered = self.panel.contains(mouse_x, mouse_y);

        if (self.hovered and mouse_clicked and self.enabled) {
            self.clicked = true;
        } else {
            self.clicked = false;
        }

        // Visual feedback colors
        if (!self.enabled) {
            self.panel.setColor(0.3, 0.3, 0.3, 0.5);
        } else if (self.clicked) {
            self.panel.setColor(0.8, 0.8, 0.8, 0.9);
        } else if (self.hovered) {
            self.panel.setColor(0.5, 0.5, 0.5, 0.9);
        } else {
            self.panel.setColor(0.2, 0.2, 0.2, 0.8);
        }
    }

    pub fn wasClicked(self: *const UIButton) bool {
        return self.clicked and self.enabled;
    }
};

/// Resource display (top bar)
pub const ResourceDisplay = struct {
    panel: UIPanel,
    supplies_label: []const u8 = "Supplies:",
    power_label: []const u8 = "Power:",

    pub fn init(screen_width: f32) ResourceDisplay {
        const panel_height: f32 = 40.0;
        return .{
            .panel = UIPanel.init(0, 0, screen_width, panel_height),
        };
    }

    pub fn update(self: *ResourceDisplay, screen_width: f32) void {
        self.panel.width = screen_width;
    }
};

/// Unit info panel (bottom left)
pub const UnitInfoPanel = struct {
    panel: UIPanel,
    selected_unit: ?EntityId,
    unit_name: []const u8,
    health_text: []const u8,

    pub fn init() UnitInfoPanel {
        const panel_width: f32 = 300.0;
        const panel_height: f32 = 120.0;
        const panel_x: f32 = 10.0;
        return .{
            .panel = UIPanel.init(panel_x, 768.0 - panel_height - 10.0, panel_width, panel_height),
            .selected_unit = null,
            .unit_name = "No Unit Selected",
            .health_text = "N/A",
        };
    }

    pub fn setSelectedUnit(self: *UnitInfoPanel, unit_id: ?EntityId, name: []const u8, health: f32, max_health: f32) void {
        self.selected_unit = unit_id;
        if (unit_id != null) {
            self.unit_name = name;
            // We'll format this properly when rendering
            _ = health;
            _ = max_health;
            self.panel.visible = true;
        } else {
            self.unit_name = "No Unit Selected";
            self.health_text = "N/A";
            self.panel.visible = false;
        }
    }

    pub fn clear(self: *UnitInfoPanel) void {
        self.selected_unit = null;
        self.unit_name = "No Unit Selected";
        self.health_text = "N/A";
        self.panel.visible = false;
    }
};

/// Production queue display (bottom right)
pub const ProductionQueueDisplay = struct {
    panel: UIPanel,

    pub fn init(screen_width: f32) ProductionQueueDisplay {
        const panel_width: f32 = 300.0;
        const panel_height: f32 = 120.0;
        const panel_x: f32 = screen_width - panel_width - 10.0;
        return .{
            .panel = UIPanel.init(panel_x, 768.0 - panel_height - 10.0, panel_width, panel_height),
        };
    }

    pub fn update(self: *ProductionQueueDisplay, screen_width: f32) void {
        const panel_width: f32 = 300.0;
        self.panel.x = screen_width - panel_width - 10.0;
    }
};

/// Command buttons panel (bottom center)
pub const CommandPanel = struct {
    panel: UIPanel,
    buttons: [6]UIButton,
    button_count: usize,

    pub fn init(screen_width: f32) CommandPanel {
        const panel_width: f32 = 400.0;
        const panel_height: f32 = 80.0;
        const panel_x: f32 = (screen_width - panel_width) / 2.0;
        const panel_y: f32 = 768.0 - panel_height - 10.0;

        var buttons: [6]UIButton = undefined;
        const button_width: f32 = 60.0;
        const button_height: f32 = 60.0;
        const button_spacing: f32 = 5.0;
        const buttons_start_x: f32 = panel_x + 10.0;
        const buttons_y: f32 = panel_y + 10.0;

        buttons[0] = UIButton.init(buttons_start_x + 0.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Move");
        buttons[1] = UIButton.init(buttons_start_x + 1.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Stop");
        buttons[2] = UIButton.init(buttons_start_x + 2.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Attack");
        buttons[3] = UIButton.init(buttons_start_x + 3.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Build");
        buttons[4] = UIButton.init(buttons_start_x + 4.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Repair");
        buttons[5] = UIButton.init(buttons_start_x + 5.0 * (button_width + button_spacing), buttons_y, button_width, button_height, "Sell");

        return .{
            .panel = UIPanel.init(panel_x, panel_y, panel_width, panel_height),
            .buttons = buttons,
            .button_count = 6,
        };
    }

    pub fn update(self: *CommandPanel, screen_width: f32, mouse_x: f32, mouse_y: f32, mouse_clicked: bool) void {
        // Update panel position
        const panel_width: f32 = 400.0;
        self.panel.x = (screen_width - panel_width) / 2.0;

        // Update button positions and states
        const button_width: f32 = 60.0;
        const button_spacing: f32 = 5.0;
        const buttons_start_x: f32 = self.panel.x + 10.0;

        for (0..self.button_count) |i| {
            self.buttons[i].panel.x = buttons_start_x + @as(f32, @floatFromInt(i)) * (button_width + button_spacing);
            self.buttons[i].update(mouse_x, mouse_y, mouse_clicked);
        }
    }

    pub fn getClickedButton(self: *const CommandPanel) ?usize {
        for (0..self.button_count) |i| {
            if (self.buttons[i].wasClicked()) {
                return i;
            }
        }
        return null;
    }
};

/// Main UI Manager
pub const UIManager = struct {
    allocator: Allocator,
    screen_width: f32,
    screen_height: f32,

    // UI Elements
    resource_display: ResourceDisplay,
    unit_info_panel: UnitInfoPanel,
    production_display: ProductionQueueDisplay,
    command_panel: CommandPanel,

    // State
    show_ui: bool,

    pub fn init(allocator: Allocator, screen_width: f32, screen_height: f32) UIManager {
        return .{
            .allocator = allocator,
            .screen_width = screen_width,
            .screen_height = screen_height,
            .resource_display = ResourceDisplay.init(screen_width),
            .unit_info_panel = UnitInfoPanel.init(),
            .production_display = ProductionQueueDisplay.init(screen_width),
            .command_panel = CommandPanel.init(screen_width),
            .show_ui = true,
        };
    }

    pub fn deinit(self: *UIManager) void {
        _ = self;
        // Nothing to cleanup for now
    }

    pub fn update(self: *UIManager, mouse_x: f32, mouse_y: f32, mouse_clicked: bool) void {
        if (!self.show_ui) return;

        // Update all UI elements
        self.resource_display.update(self.screen_width);
        self.production_display.update(self.screen_width);
        self.command_panel.update(self.screen_width, mouse_x, mouse_y, mouse_clicked);
    }

    pub fn setSelectedUnit(self: *UIManager, unit_id: ?EntityId, name: []const u8, health: f32, max_health: f32) void {
        self.unit_info_panel.setSelectedUnit(unit_id, name, health, max_health);
    }

    pub fn clearSelection(self: *UIManager) void {
        self.unit_info_panel.clear();
    }

    pub fn toggleUI(self: *UIManager) void {
        self.show_ui = !self.show_ui;
    }

    pub fn handleResize(self: *UIManager, new_width: f32, new_height: f32) void {
        self.screen_width = new_width;
        self.screen_height = new_height;
        // UI elements will auto-update on next update() call
    }

    pub fn getCommandButtonClicked(self: *const UIManager) ?usize {
        if (!self.show_ui) return null;
        return self.command_panel.getClickedButton();
    }
};

// Tests
test "UIPanel: contains point" {
    const panel = UIPanel.init(100, 100, 200, 150);

    try std.testing.expect(panel.contains(150, 150));
    try std.testing.expect(panel.contains(100, 100)); // Top-left corner
    try std.testing.expect(panel.contains(300, 250)); // Bottom-right corner
    try std.testing.expect(!panel.contains(50, 150)); // Left of panel
    try std.testing.expect(!panel.contains(350, 150)); // Right of panel
}

test "UIButton: click detection" {
    var button = UIButton.init(100, 100, 80, 40, "Test");

    // Not clicked initially
    button.update(150, 120, false);
    try std.testing.expect(!button.wasClicked());

    // Mouse over but not clicked
    button.update(150, 120, false);
    try std.testing.expect(button.hovered);
    try std.testing.expect(!button.wasClicked());

    // Clicked
    button.update(150, 120, true);
    try std.testing.expect(button.wasClicked());
}

test "UIManager: initialization" {
    const allocator = std.testing.allocator;
    var ui = UIManager.init(allocator, 1024, 768);
    defer ui.deinit();

    try std.testing.expect(ui.show_ui);
    try std.testing.expectEqual(@as(f32, 1024), ui.screen_width);
    try std.testing.expectEqual(@as(f32, 768), ui.screen_height);
}
