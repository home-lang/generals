// C&C Generals - Main Menu System
// Complete main menu with all game modes

const std = @import("std");
const ui_system = @import("ui_system.zig");

/// Menu screens
pub const MenuScreen = enum {
    Main,
    Singleplayer,
    Multiplayer,
    Options,
    Credits,
    Campaign,
    Skirmish,
    ChallengeMode,
    NetworkLobby,
    MapSelection,
    Graphics,
    Audio,
    Controls,
    Gameplay,
};

/// Menu button action
pub const MenuAction = enum {
    None,
    Singleplayer,
    Multiplayer,
    Options,
    Credits,
    Exit,
    Campaign,
    Skirmish,
    Challenge,
    USACampaign,
    ChinaCampaign,
    GLACampaign,
    CreateLobby,
    JoinLobby,
    Back,
    StartGame,
    QuickMatch,
    CustomGame,
    Graphics,
    Audio,
    Controls,
    Gameplay,
    Apply,
    Cancel,
};

/// Menu button
pub const MenuButton = struct {
    id: u32,
    label: []const u8,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    is_hovered: bool,
    is_pressed: bool,
    action: MenuAction,
    enabled: bool,

    pub fn init(id: u32, label: []const u8, x: f32, y: f32, width: f32, height: f32, action: MenuAction) MenuButton {
        return MenuButton{
            .id = id,
            .label = label,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .is_hovered = false,
            .is_pressed = false,
            .action = action,
            .enabled = true,
        };
    }

    pub fn contains(self: *MenuButton, mouse_x: f32, mouse_y: f32) bool {
        return mouse_x >= self.x and mouse_x <= self.x + self.width and
            mouse_y >= self.y and mouse_y <= self.y + self.height;
    }

    pub fn update(self: *MenuButton, mouse_x: f32, mouse_y: f32, mouse_down: bool) MenuAction {
        self.is_hovered = self.contains(mouse_x, mouse_y);

        if (self.is_hovered and mouse_down and self.enabled) {
            self.is_pressed = true;
            return self.action;
        }

        self.is_pressed = false;
        return .None;
    }
};

/// Main menu state
pub const MainMenu = struct {
    allocator: std.mem.Allocator,
    current_screen: MenuScreen,
    buttons: []MenuButton,
    button_count: usize,
    background_video: ?[]const u8,
    music_track: ?[]const u8,
    screen_width: u32,
    screen_height: u32,

    pub fn init(allocator: std.mem.Allocator, screen_width: u32, screen_height: u32) !MainMenu {
        const buttons = try allocator.alloc(MenuButton, 50);

        var menu = MainMenu{
            .allocator = allocator,
            .current_screen = .Main,
            .buttons = buttons,
            .button_count = 0,
            .background_video = null,
            .music_track = "sounds/music/main_menu.mp3",
            .screen_width = screen_width,
            .screen_height = screen_height,
        };

        // Build main menu buttons
        try menu.buildMainMenu();

        return menu;
    }

    pub fn deinit(self: *MainMenu) void {
        self.allocator.free(self.buttons);
    }

    /// Build main menu screen
    fn buildMainMenu(self: *MainMenu) !void {
        self.button_count = 0;

        const center_x = @as(f32, @floatFromInt(self.screen_width)) / 2.0;
        const start_y: f32 = 300.0;
        const button_width: f32 = 300.0;
        const button_height: f32 = 60.0;
        const spacing: f32 = 80.0;

        // Singleplayer button
        self.buttons[0] = MenuButton.init(
            0,
            "SINGLEPLAYER",
            center_x - button_width / 2.0,
            start_y,
            button_width,
            button_height,
            .Singleplayer,
        );

        // Multiplayer button
        self.buttons[1] = MenuButton.init(
            1,
            "MULTIPLAYER",
            center_x - button_width / 2.0,
            start_y + spacing,
            button_width,
            button_height,
            .Multiplayer,
        );

        // Options button
        self.buttons[2] = MenuButton.init(
            2,
            "OPTIONS",
            center_x - button_width / 2.0,
            start_y + spacing * 2.0,
            button_width,
            button_height,
            .Options,
        );

        // Credits button
        self.buttons[3] = MenuButton.init(
            3,
            "CREDITS",
            center_x - button_width / 2.0,
            start_y + spacing * 3.0,
            button_width,
            button_height,
            .Credits,
        );

        // Exit button
        self.buttons[4] = MenuButton.init(
            4,
            "EXIT",
            center_x - button_width / 2.0,
            start_y + spacing * 4.0,
            button_width,
            button_height,
            .Exit,
        );

        self.button_count = 5;
    }

    /// Build singleplayer menu
    fn buildSingleplayerMenu(self: *MainMenu) !void {
        self.button_count = 0;

        const center_x = @as(f32, @floatFromInt(self.screen_width)) / 2.0;
        const start_y: f32 = 300.0;
        const button_width: f32 = 300.0;
        const button_height: f32 = 60.0;
        const spacing: f32 = 80.0;

        // Campaign button
        self.buttons[0] = MenuButton.init(0, "CAMPAIGN", center_x - button_width / 2.0, start_y, button_width, button_height, .Campaign);

        // Skirmish button
        self.buttons[1] = MenuButton.init(1, "SKIRMISH", center_x - button_width / 2.0, start_y + spacing, button_width, button_height, .Skirmish);

        // Challenge mode button
        self.buttons[2] = MenuButton.init(2, "CHALLENGE", center_x - button_width / 2.0, start_y + spacing * 2.0, button_width, button_height, .Challenge);

        // Back button
        self.buttons[3] = MenuButton.init(3, "BACK", center_x - button_width / 2.0, start_y + spacing * 3.0, button_width, button_height, .Back);

        self.button_count = 4;
    }

    /// Build campaign selection menu
    fn buildCampaignMenu(self: *MainMenu) !void {
        self.button_count = 0;

        const center_x = @as(f32, @floatFromInt(self.screen_width)) / 2.0;
        const start_y: f32 = 300.0;
        const button_width: f32 = 300.0;
        const button_height: f32 = 60.0;
        const spacing: f32 = 80.0;

        // USA Campaign
        self.buttons[0] = MenuButton.init(0, "USA CAMPAIGN", center_x - button_width / 2.0, start_y, button_width, button_height, .USACampaign);

        // China Campaign
        self.buttons[1] = MenuButton.init(1, "CHINA CAMPAIGN", center_x - button_width / 2.0, start_y + spacing, button_width, button_height, .ChinaCampaign);

        // GLA Campaign
        self.buttons[2] = MenuButton.init(2, "GLA CAMPAIGN", center_x - button_width / 2.0, start_y + spacing * 2.0, button_width, button_height, .GLACampaign);

        // Back button
        self.buttons[3] = MenuButton.init(3, "BACK", center_x - button_width / 2.0, start_y + spacing * 3.0, button_width, button_height, .Back);

        self.button_count = 4;
    }

    /// Build multiplayer menu
    fn buildMultiplayerMenu(self: *MainMenu) !void {
        self.button_count = 0;

        const center_x = @as(f32, @floatFromInt(self.screen_width)) / 2.0;
        const start_y: f32 = 300.0;
        const button_width: f32 = 300.0;
        const button_height: f32 = 60.0;
        const spacing: f32 = 80.0;

        // Quick Match
        self.buttons[0] = MenuButton.init(0, "QUICK MATCH", center_x - button_width / 2.0, start_y, button_width, button_height, .QuickMatch);

        // Create Game
        self.buttons[1] = MenuButton.init(1, "CREATE GAME", center_x - button_width / 2.0, start_y + spacing, button_width, button_height, .CreateLobby);

        // Join Game
        self.buttons[2] = MenuButton.init(2, "JOIN GAME", center_x - button_width / 2.0, start_y + spacing * 2.0, button_width, button_height, .JoinLobby);

        // Back button
        self.buttons[3] = MenuButton.init(3, "BACK", center_x - button_width / 2.0, start_y + spacing * 3.0, button_width, button_height, .Back);

        self.button_count = 4;
    }

    /// Build options menu
    fn buildOptionsMenu(self: *MainMenu) !void {
        self.button_count = 0;

        const center_x = @as(f32, @floatFromInt(self.screen_width)) / 2.0;
        const start_y: f32 = 300.0;
        const button_width: f32 = 300.0;
        const button_height: f32 = 60.0;
        const spacing: f32 = 80.0;

        // Graphics
        self.buttons[0] = MenuButton.init(0, "GRAPHICS", center_x - button_width / 2.0, start_y, button_width, button_height, .Graphics);

        // Audio
        self.buttons[1] = MenuButton.init(1, "AUDIO", center_x - button_width / 2.0, start_y + spacing, button_width, button_height, .Audio);

        // Controls
        self.buttons[2] = MenuButton.init(2, "CONTROLS", center_x - button_width / 2.0, start_y + spacing * 2.0, button_width, button_height, .Controls);

        // Gameplay
        self.buttons[3] = MenuButton.init(3, "GAMEPLAY", center_x - button_width / 2.0, start_y + spacing * 3.0, button_width, button_height, .Gameplay);

        // Back button
        self.buttons[4] = MenuButton.init(4, "BACK", center_x - button_width / 2.0, start_y + spacing * 4.0, button_width, button_height, .Back);

        self.button_count = 5;
    }

    /// Change to a different menu screen
    pub fn changeScreen(self: *MainMenu, screen: MenuScreen) !void {
        self.current_screen = screen;

        switch (screen) {
            .Main => try self.buildMainMenu(),
            .Singleplayer => try self.buildSingleplayerMenu(),
            .Multiplayer => try self.buildMultiplayerMenu(),
            .Options => try self.buildOptionsMenu(),
            .Campaign => try self.buildCampaignMenu(),
            else => {},
        }
    }

    /// Update menu (process input)
    pub fn update(self: *MainMenu, mouse_x: f32, mouse_y: f32, mouse_down: bool) !?MenuAction {
        for (self.buttons[0..self.button_count]) |*button| {
            const action = button.update(mouse_x, mouse_y, mouse_down);
            if (action != .None) {
                // Handle navigation actions
                switch (action) {
                    .Singleplayer => {
                        try self.changeScreen(.Singleplayer);
                        return null;
                    },
                    .Multiplayer => {
                        try self.changeScreen(.Multiplayer);
                        return null;
                    },
                    .Options => {
                        try self.changeScreen(.Options);
                        return null;
                    },
                    .Campaign => {
                        try self.changeScreen(.Campaign);
                        return null;
                    },
                    .Back => {
                        // Navigate back to main menu
                        try self.changeScreen(.Main);
                        return null;
                    },
                    else => return action,
                }
            }
        }
        return null;
    }

    /// Get menu statistics
    pub fn getStats(self: *MainMenu) MenuStats {
        return MenuStats{
            .current_screen = self.current_screen,
            .button_count = self.button_count,
            .has_background_video = self.background_video != null,
            .has_music = self.music_track != null,
        };
    }
};

pub const MenuStats = struct {
    current_screen: MenuScreen,
    button_count: usize,
    has_background_video: bool,
    has_music: bool,
};

// Tests
test "Main menu creation" {
    const allocator = std.testing.allocator;

    var menu = try MainMenu.init(allocator, 1920, 1080);
    defer menu.deinit();

    const stats = menu.getStats();
    try std.testing.expect(stats.current_screen == .Main);
    try std.testing.expect(stats.button_count == 5);
}

test "Menu navigation" {
    const allocator = std.testing.allocator;

    var menu = try MainMenu.init(allocator, 1920, 1080);
    defer menu.deinit();

    try menu.changeScreen(.Singleplayer);
    const stats = menu.getStats();
    try std.testing.expect(stats.current_screen == .Singleplayer);
    try std.testing.expect(stats.button_count == 4);
}

test "Button interaction" {
    const allocator = std.testing.allocator;

    var menu = try MainMenu.init(allocator, 1920, 1080);
    defer menu.deinit();

    // Click on first button (Singleplayer)
    const action = try menu.update(960.0, 330.0, true);
    const stats = menu.getStats();

    // Should navigate to singleplayer menu
    try std.testing.expect(stats.current_screen == .Singleplayer);
    try std.testing.expect(action == null);
}
