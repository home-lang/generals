// Generals Resource Manager
// Loads and manages all game assets and INI data

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Resource Manager - handles loading of INI files, textures, models, audio
pub const ResourceManager = struct {
    allocator: Allocator,
    assets_path: []const u8,

    // Loaded INI data
    faction_units: ?IniFile,
    faction_buildings: ?IniFile,
    weapons: ?IniFile,
    command_buttons: ?IniFile,

    // TODO: Add texture cache, model cache, audio cache

    const IniFile = @import("io").IniFile;

    pub fn init(allocator: Allocator, assets_path: []const u8) !ResourceManager {
        return ResourceManager{
            .allocator = allocator,
            .assets_path = try allocator.dupe(u8, assets_path),
            .faction_units = null,
            .faction_buildings = null,
            .weapons = null,
            .command_buttons = null,
        };
    }

    pub fn deinit(self: *ResourceManager) void {
        self.allocator.free(self.assets_path);

        if (self.faction_units) |*ini| ini.deinit();
        if (self.faction_buildings) |*ini| ini.deinit();
        if (self.weapons) |*ini| ini.deinit();
        if (self.command_buttons) |*ini| ini.deinit();
    }

    /// Load all core game data
    pub fn loadGameData(self: *ResourceManager) !void {
        std.debug.print("ResourceManager: Loading game data from {s}\n", .{self.assets_path});

        // Load INI files
        try self.loadIniFiles();

        std.debug.print("ResourceManager: Game data loaded successfully!\n", .{});
    }

    fn loadIniFiles(self: *ResourceManager) !void {
        const String = @import("io").String;

        // Build paths to INI files
        const ini_path = try String.format(self.allocator, "{s}/ini", .{self.assets_path});
        defer self.allocator.free(ini_path);

        // Load FactionUnit.ini
        const faction_unit_path = try String.format(self.allocator, "{s}/FactionUnit.ini", .{ini_path});
        defer self.allocator.free(faction_unit_path);

        std.debug.print("  Loading: {s}\n", .{faction_unit_path});
        self.faction_units = try IniFile.parseFile(self.allocator, faction_unit_path);

        if (self.faction_units) |units| {
            std.debug.print("    Loaded {} unit definitions\n", .{units.sections.size()});
        }

        // Load FactionBuilding.ini
        const faction_building_path = try String.format(self.allocator, "{s}/FactionBuilding.ini", .{ini_path});
        defer self.allocator.free(faction_building_path);

        std.debug.print("  Loading: {s}\n", .{faction_building_path});
        self.faction_buildings = try IniFile.parseFile(self.allocator, faction_building_path);

        if (self.faction_buildings) |buildings| {
            std.debug.print("    Loaded {} building definitions\n", .{buildings.sections.size()});
        }

        // Load Weapon.ini
        const weapon_path = try String.format(self.allocator, "{s}/Weapon.ini", .{ini_path});
        defer self.allocator.free(weapon_path);

        // Check if file exists
        std.fs.cwd().access(weapon_path, .{}) catch |err| {
            if (err != error.FileNotFound) return err;
            std.debug.print("  Weapon.ini not found, skipping\n", .{});
        };

        std.debug.print("  Loading: {s}\n", .{weapon_path});
        self.weapons = IniFile.parseFile(self.allocator, weapon_path) catch null;

        if (self.weapons) |weapons| {
            std.debug.print("    Loaded {} weapon definitions\n", .{weapons.sections.count});
        }

        // Load CommandButton.ini
        const command_button_path = try String.format(self.allocator, "{s}/CommandButton.ini", .{ini_path});
        defer self.allocator.free(command_button_path);

        std.fs.cwd().access(command_button_path, .{}) catch |err| {
            if (err != error.FileNotFound) return err;
            std.debug.print("  CommandButton.ini not found, skipping\n", .{});
        };

        if (true) {
            std.debug.print("  Loading: {s}\n", .{command_button_path});
            self.command_buttons = try IniFile.parseFile(self.allocator, command_button_path);

            if (self.command_buttons) |buttons| {
                std.debug.print("    Loaded {} command button definitions\n", .{buttons.sections.size()});
            }
        }
    }

    /// Get unit definition by name
    pub fn getUnitDef(self: *const ResourceManager, name: []const u8) ?IniFile.Section {
        if (self.faction_units) |units| {
            return units.getSection(name);
        }
        return null;
    }

    /// Get building definition by name
    pub fn getBuildingDef(self: *const ResourceManager, name: []const u8) ?IniFile.Section {
        if (self.faction_buildings) |buildings| {
            return buildings.getSection(name);
        }
        return null;
    }
};
