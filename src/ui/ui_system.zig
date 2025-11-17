// C&C Generals - UI System
// Menus, HUD, command bar, and build palette

const std = @import("std");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn white() Color {
        return Color.init(255, 255, 255, 255);
    }

    pub fn black() Color {
        return Color.init(0, 0, 0, 255);
    }

    pub fn red() Color {
        return Color.init(255, 0, 0, 255);
    }

    pub fn green() Color {
        return Color.init(0, 255, 0, 255);
    }

    pub fn blue() Color {
        return Color.init(0, 0, 255, 255);
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
};

/// UI widget base
pub const UIWidget = struct {
    bounds: Rect,
    visible: bool,
    enabled: bool,
    id: u32,

    pub fn init(id: u32, bounds: Rect) UIWidget {
        return UIWidget{
            .bounds = bounds,
            .visible = true,
            .enabled = true,
            .id = id,
        };
    }

    pub fn isHovered(self: *UIWidget, mouse_pos: Vec2) bool {
        return self.visible and self.bounds.contains(mouse_pos);
    }
};

/// Button widget
pub const Button = struct {
    widget: UIWidget,
    text: []const u8,
    texture: []const u8,
    is_pressed: bool,
    is_hovered: bool,
    callback: ?*const fn () void,

    pub fn init(id: u32, bounds: Rect, text: []const u8) Button {
        return Button{
            .widget = UIWidget.init(id, bounds),
            .text = text,
            .texture = "",
            .is_pressed = false,
            .is_hovered = false,
            .callback = null,
        };
    }

    pub fn update(self: *Button, mouse_pos: Vec2, mouse_down: bool) void {
        self.is_hovered = self.widget.isHovered(mouse_pos);

        if (self.is_hovered and mouse_down) {
            self.is_pressed = true;
        } else if (self.is_pressed and !mouse_down) {
            // Button clicked
            self.is_pressed = false;
            if (self.callback) |cb| {
                cb();
            }
        }
    }
};

/// Text label
pub const Label = struct {
    widget: UIWidget,
    text: []const u8,
    color: Color,
    font_size: u32,

    pub fn init(id: u32, bounds: Rect, text: []const u8) Label {
        return Label{
            .widget = UIWidget.init(id, bounds),
            .text = text,
            .color = Color.white(),
            .font_size = 16,
        };
    }
};

/// Progress bar
pub const ProgressBar = struct {
    widget: UIWidget,
    value: f32, // 0.0 to 1.0
    color: Color,
    background_color: Color,

    pub fn init(id: u32, bounds: Rect) ProgressBar {
        return ProgressBar{
            .widget = UIWidget.init(id, bounds),
            .value = 0.0,
            .color = Color.green(),
            .background_color = Color.init(50, 50, 50, 255),
        };
    }

    pub fn setValue(self: *ProgressBar, value: f32) void {
        self.value = @max(0.0, @min(1.0, value));
    }
};

/// Minimap display
pub const Minimap = struct {
    widget: UIWidget,
    map_width: u32,
    map_height: u32,
    camera_pos: Vec2,
    camera_bounds: Rect,

    pub fn init(id: u32, bounds: Rect, map_width: u32, map_height: u32) Minimap {
        return Minimap{
            .widget = UIWidget.init(id, bounds),
            .map_width = map_width,
            .map_height = map_height,
            .camera_pos = Vec2.init(0, 0),
            .camera_bounds = Rect{ .x = 0, .y = 0, .width = 100, .height = 100 },
        };
    }

    pub fn worldToMinimap(self: *Minimap, world_pos: Vec2) Vec2 {
        const scale_x = self.widget.bounds.width / @as(f32, @floatFromInt(self.map_width));
        const scale_y = self.widget.bounds.height / @as(f32, @floatFromInt(self.map_height));

        return Vec2.init(
            self.widget.bounds.x + world_pos.x * scale_x,
            self.widget.bounds.y + world_pos.y * scale_y,
        );
    }

    pub fn minimapToWorld(self: *Minimap, minimap_pos: Vec2) Vec2 {
        const local_x = minimap_pos.x - self.widget.bounds.x;
        const local_y = minimap_pos.y - self.widget.bounds.y;

        const scale_x = @as(f32, @floatFromInt(self.map_width)) / self.widget.bounds.width;
        const scale_y = @as(f32, @floatFromInt(self.map_height)) / self.widget.bounds.height;

        return Vec2.init(local_x * scale_x, local_y * scale_y);
    }
};

/// Command bar for unit commands
pub const CommandBar = struct {
    widget: UIWidget,
    buttons: []Button,
    button_count: usize,
    selected_command: ?u32,

    pub fn init(allocator: std.mem.Allocator, id: u32, bounds: Rect) !CommandBar {
        const buttons = try allocator.alloc(Button, 12); // 12 command buttons

        return CommandBar{
            .widget = UIWidget.init(id, bounds),
            .buttons = buttons,
            .button_count = 0,
            .selected_command = null,
        };
    }

    pub fn deinit(self: *CommandBar, allocator: std.mem.Allocator) void {
        allocator.free(self.buttons);
    }

    pub fn addCommand(self: *CommandBar, command_id: u32, icon: []const u8, tooltip: []const u8) !void {
        if (self.button_count >= self.buttons.len) return error.TooManyCommands;

        // Layout buttons in a grid
        const button_size: f32 = 64;
        const padding: f32 = 4;
        const cols: usize = 6;

        const row = self.button_count / cols;
        const col = self.button_count % cols;

        const x = self.widget.bounds.x + @as(f32, @floatFromInt(col)) * (button_size + padding);
        const y = self.widget.bounds.y + @as(f32, @floatFromInt(row)) * (button_size + padding);

        const bounds = Rect{
            .x = x,
            .y = y,
            .width = button_size,
            .height = button_size,
        };

        var button = Button.init(command_id, bounds, tooltip);
        button.texture = icon;

        self.buttons[self.button_count] = button;
        self.button_count += 1;
    }

    pub fn update(self: *CommandBar, mouse_pos: Vec2, mouse_down: bool) void {
        for (self.buttons[0..self.button_count]) |*button| {
            button.update(mouse_pos, mouse_down);

            if (button.is_pressed) {
                self.selected_command = button.widget.id;
            }
        }
    }
};

/// Build palette for constructing buildings/units
pub const BuildPalette = struct {
    widget: UIWidget,
    tabs: []const []const u8,
    current_tab: usize,
    buttons: []Button,
    button_count: usize,

    pub fn init(allocator: std.mem.Allocator, id: u32, bounds: Rect) !BuildPalette {
        const buttons = try allocator.alloc(Button, 20);

        return BuildPalette{
            .widget = UIWidget.init(id, bounds),
            .tabs = &[_][]const u8{ "Units", "Buildings", "Defenses", "Generals" },
            .current_tab = 0,
            .buttons = buttons,
            .button_count = 0,
        };
    }

    pub fn deinit(self: *BuildPalette, allocator: std.mem.Allocator) void {
        allocator.free(self.buttons);
    }

    pub fn switchTab(self: *BuildPalette, tab_index: usize) void {
        if (tab_index < self.tabs.len) {
            self.current_tab = tab_index;
            // Would reload buttons for this tab
        }
    }

    pub fn addBuildOption(
        self: *BuildPalette,
        unit_id: u32,
        icon: []const u8,
        name: []const u8,
        cost: u32,
    ) !void {
        _ = cost;

        if (self.button_count >= self.buttons.len) return error.TooManyOptions;

        const button_size: f32 = 64;
        const padding: f32 = 4;
        const cols: usize = 4;

        const row = self.button_count / cols;
        const col = self.button_count % cols;

        const x = self.widget.bounds.x + @as(f32, @floatFromInt(col)) * (button_size + padding);
        const y = self.widget.bounds.y + 40 + @as(f32, @floatFromInt(row)) * (button_size + padding);

        const bounds = Rect{
            .x = x,
            .y = y,
            .width = button_size,
            .height = button_size,
        };

        var button = Button.init(unit_id, bounds, name);
        button.texture = icon;

        self.buttons[self.button_count] = button;
        self.button_count += 1;
    }
};

/// HUD (Heads-Up Display)
pub const HUD = struct {
    allocator: std.mem.Allocator,
    minimap: Minimap,
    command_bar: CommandBar,
    build_palette: BuildPalette,
    resource_labels: []Label,
    health_bar: ProgressBar,
    unit_info_label: Label,

    pub fn init(allocator: std.mem.Allocator, screen_width: u32, screen_height: u32) !HUD {
        const sw = @as(f32, @floatFromInt(screen_width));
        const sh = @as(f32, @floatFromInt(screen_height));

        // Minimap (bottom-left)
        const minimap = Minimap.init(
            1,
            Rect{ .x = 10, .y = sh - 210, .width = 200, .height = 200 },
            128,
            128,
        );

        // Command bar (bottom-center)
        const command_bar = try CommandBar.init(
            allocator,
            2,
            Rect{ .x = sw / 2 - 200, .y = sh - 150, .width = 400, .height = 140 },
        );

        // Build palette (right side)
        const build_palette = try BuildPalette.init(
            allocator,
            3,
            Rect{ .x = sw - 310, .y = sh / 2 - 200, .width = 300, .height = 400 },
        );

        // Resource labels (top-left)
        const resource_labels = try allocator.alloc(Label, 3);
        resource_labels[0] = Label.init(10, Rect{ .x = 10, .y = 10, .width = 150, .height = 30 }, "Money: $10000");
        resource_labels[1] = Label.init(11, Rect{ .x = 10, .y = 45, .width = 150, .height = 30 }, "Power: 100%");
        resource_labels[2] = Label.init(12, Rect{ .x = 10, .y = 80, .width = 150, .height = 30 }, "Supply: 50/100");

        // Health bar (top-center)
        const health_bar = ProgressBar.init(
            20,
            Rect{ .x = sw / 2 - 100, .y = 10, .width = 200, .height = 20 },
        );

        // Unit info label (top-right)
        const unit_info_label = Label.init(
            30,
            Rect{ .x = sw - 310, .y = 10, .width = 300, .height = 100 },
            "No unit selected",
        );

        return HUD{
            .allocator = allocator,
            .minimap = minimap,
            .command_bar = command_bar,
            .build_palette = build_palette,
            .resource_labels = resource_labels,
            .health_bar = health_bar,
            .unit_info_label = unit_info_label,
        };
    }

    pub fn deinit(self: *HUD) void {
        self.command_bar.deinit(self.allocator);
        self.build_palette.deinit(self.allocator);
        self.allocator.free(self.resource_labels);
    }

    pub fn update(self: *HUD, mouse_pos: Vec2, mouse_down: bool) void {
        self.command_bar.update(mouse_pos, mouse_down);
    }
};

/// Main menu
pub const MainMenu = struct {
    allocator: std.mem.Allocator,
    buttons: []Button,
    button_count: usize,
    title_label: Label,

    pub fn init(allocator: std.mem.Allocator, screen_width: u32, screen_height: u32) !MainMenu {
        const sw = @as(f32, @floatFromInt(screen_width));
        const sh = @as(f32, @floatFromInt(screen_height));

        const buttons = try allocator.alloc(Button, 6);

        const button_width: f32 = 300;
        const button_height: f32 = 60;
        const button_spacing: f32 = 20;
        const start_y = sh / 2 - 100;

        buttons[0] = Button.init(100, Rect{
            .x = sw / 2 - button_width / 2,
            .y = start_y,
            .width = button_width,
            .height = button_height,
        }, "Singleplayer");

        buttons[1] = Button.init(101, Rect{
            .x = sw / 2 - button_width / 2,
            .y = start_y + (button_height + button_spacing),
            .width = button_width,
            .height = button_height,
        }, "Multiplayer");

        buttons[2] = Button.init(102, Rect{
            .x = sw / 2 - button_width / 2,
            .y = start_y + (button_height + button_spacing) * 2,
            .width = button_width,
            .height = button_height,
        }, "Options");

        buttons[3] = Button.init(103, Rect{
            .x = sw / 2 - button_width / 2,
            .y = start_y + (button_height + button_spacing) * 3,
            .width = button_width,
            .height = button_height,
        }, "Exit");

        const title_label = Label.init(200, Rect{
            .x = sw / 2 - 400,
            .y = 100,
            .width = 800,
            .height = 80,
        }, "C&C Generals Zero Hour");

        return MainMenu{
            .allocator = allocator,
            .buttons = buttons,
            .button_count = 4,
            .title_label = title_label,
        };
    }

    pub fn deinit(self: *MainMenu) void {
        self.allocator.free(self.buttons);
    }

    pub fn update(self: *MainMenu, mouse_pos: Vec2, mouse_down: bool) ?u32 {
        for (self.buttons[0..self.button_count]) |*button| {
            button.update(mouse_pos, mouse_down);

            if (button.is_pressed) {
                return button.widget.id;
            }
        }
        return null;
    }
};

/// UI Manager
pub const UIManager = struct {
    allocator: std.mem.Allocator,
    hud: ?HUD,
    main_menu: ?MainMenu,
    screen_width: u32,
    screen_height: u32,
    mouse_position: Vec2,
    mouse_down: bool,

    pub fn init(allocator: std.mem.Allocator, screen_width: u32, screen_height: u32) UIManager {
        return UIManager{
            .allocator = allocator,
            .hud = null,
            .main_menu = null,
            .screen_width = screen_width,
            .screen_height = screen_height,
            .mouse_position = Vec2.init(0, 0),
            .mouse_down = false,
        };
    }

    pub fn deinit(self: *UIManager) void {
        if (self.hud) |*hud| {
            hud.deinit();
        }
        if (self.main_menu) |*menu| {
            menu.deinit();
        }
    }

    pub fn showMainMenu(self: *UIManager) !void {
        if (self.hud) |*hud| {
            hud.deinit();
            self.hud = null;
        }

        self.main_menu = try MainMenu.init(self.allocator, self.screen_width, self.screen_height);
    }

    pub fn showHUD(self: *UIManager) !void {
        if (self.main_menu) |*menu| {
            menu.deinit();
            self.main_menu = null;
        }

        self.hud = try HUD.init(self.allocator, self.screen_width, self.screen_height);
    }

    pub fn update(self: *UIManager) void {
        if (self.main_menu) |*menu| {
            _ = menu.update(self.mouse_position, self.mouse_down);
        }

        if (self.hud) |*hud| {
            hud.update(self.mouse_position, self.mouse_down);
        }
    }

    pub fn getStats(self: *UIManager) UIStats {
        var widget_count: usize = 0;
        var button_count: usize = 0;

        if (self.hud) |hud| {
            widget_count += 6; // minimap, command_bar, build_palette, 3 labels
            button_count += hud.command_bar.button_count;
            button_count += hud.build_palette.button_count;
        }

        if (self.main_menu) |menu| {
            widget_count += menu.button_count + 1; // buttons + title
            button_count += menu.button_count;
        }

        return UIStats{
            .widget_count = widget_count,
            .button_count = button_count,
            .has_hud = self.hud != null,
            .has_menu = self.main_menu != null,
        };
    }
};

pub const UIStats = struct {
    widget_count: usize,
    button_count: usize,
    has_hud: bool,
    has_menu: bool,
};

// Tests
test "Button creation" {
    const button = Button.init(1, Rect{ .x = 0, .y = 0, .width = 100, .height = 50 }, "Test");
    try std.testing.expect(std.mem.eql(u8, button.text, "Test"));
}

test "Minimap conversion" {
    var minimap = Minimap.init(1, Rect{ .x = 0, .y = 0, .width = 200, .height = 200 }, 1000, 1000);

    const world_pos = Vec2.init(500, 500);
    const minimap_pos = minimap.worldToMinimap(world_pos);

    try std.testing.expect(minimap_pos.x == 100);
    try std.testing.expect(minimap_pos.y == 100);
}

test "UI manager" {
    const allocator = std.testing.allocator;

    var manager = UIManager.init(allocator, 1920, 1080);
    defer manager.deinit();

    try manager.showHUD();

    const stats = manager.getStats();
    try std.testing.expect(stats.has_hud == true);
}
