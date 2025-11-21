// WND File Parser for C&C Generals Menu System
// Parses .wnd window definition files used by the original game
//
// Based on Thyme's gamewindowmanagerscript.cpp

const std = @import("std");
const Allocator = std.mem.Allocator;

/// RGBA Color
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn white() Color {
        return Color.init(255, 255, 255, 255);
    }

    pub fn black() Color {
        return Color.init(0, 0, 0, 255);
    }

    pub fn transparent() Color {
        return Color.init(0, 0, 0, 0);
    }
};

/// 2D Rectangle
pub const Rect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    pub fn init(x: i32, y: i32, w: i32, h: i32) Rect {
        return .{ .x = x, .y = y, .width = w, .height = h };
    }
};

/// Window status flags (from Thyme)
pub const WinStatus = packed struct {
    enabled: bool = false,
    image: bool = false,
    border: bool = false,
    hidden: bool = false,
    no_input: bool = false,
    no_focus: bool = false,
    dragable: bool = false,
    tab_stop: bool = false,
    right_click: bool = false,
    wrap_centered: bool = false,
    check_like: bool = false,
    hotkey_text: bool = false,
    always_color: bool = false,
    see_thru: bool = false,
    one_line: bool = false,
    on_mouse_down: bool = false,
};

/// Window type
pub const WindowType = enum {
    user,
    push_button,
    check_box,
    radio_button,
    list_box,
    combo_box,
    horz_slider,
    vert_slider,
    progress_bar,
    entry_field,
    static_text,
    tab_control,
};

/// Draw data for a window state
pub const DrawData = struct {
    image_name: []const u8,
    color: Color,
    border_color: Color,
};

/// Text draw data
pub const TextDrawData = struct {
    color: Color,
    border_color: Color,
};

/// Font definition
pub const FontDef = struct {
    name: []const u8,
    size: i32,
    bold: bool,
};

/// Window definition parsed from WND file
pub const WindowDef = struct {
    name: []const u8,
    window_type: WindowType,
    screen_rect: Rect,
    creation_res: struct { width: i32, height: i32 },
    status: WinStatus,

    // Callbacks
    system_callback: []const u8,
    input_callback: []const u8,
    tooltip_callback: []const u8,
    draw_callback: []const u8,

    // Font
    font: FontDef,

    // Text colors
    text_enabled: TextDrawData,
    text_disabled: TextDrawData,
    text_hilite: TextDrawData,

    // Draw data (9 states each)
    enabled_draw: [9]DrawData,
    disabled_draw: [9]DrawData,
    hilite_draw: [9]DrawData,

    // Text content
    text: []const u8,
    tooltip_text: []const u8,

    // Child windows (fixed-size array to avoid Zig 0.16 ArrayList issues)
    children: [64]?*WindowDef,
    child_count: usize,

    allocator: Allocator,

    pub fn init(allocator: Allocator) WindowDef {
        return WindowDef{
            .name = "",
            .window_type = .user,
            .screen_rect = Rect.init(0, 0, 100, 100),
            .creation_res = .{ .width = 800, .height = 600 },
            .status = .{ .enabled = true },
            .system_callback = "[None]",
            .input_callback = "[None]",
            .tooltip_callback = "[None]",
            .draw_callback = "[None]",
            .font = .{ .name = "Arial", .size = 12, .bold = false },
            .text_enabled = .{ .color = Color.white(), .border_color = Color.white() },
            .text_disabled = .{ .color = Color.init(128, 128, 128, 255), .border_color = Color.white() },
            .text_hilite = .{ .color = Color.white(), .border_color = Color.white() },
            .enabled_draw = [_]DrawData{.{ .image_name = "NoImage", .color = Color.white(), .border_color = Color.white() }} ** 9,
            .disabled_draw = [_]DrawData{.{ .image_name = "NoImage", .color = Color.init(64, 64, 64, 255), .border_color = Color.white() }} ** 9,
            .hilite_draw = [_]DrawData{.{ .image_name = "NoImage", .color = Color.init(128, 128, 255, 255), .border_color = Color.white() }} ** 9,
            .text = "",
            .tooltip_text = "",
            .children = [_]?*WindowDef{null} ** 64,
            .child_count = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *WindowDef) void {
        for (0..self.child_count) |i| {
            if (self.children[i]) |child| {
                child.deinit();
                self.allocator.destroy(child);
            }
        }
    }

    pub fn addChild(self: *WindowDef, child: *WindowDef) void {
        if (self.child_count < 64) {
            self.children[self.child_count] = child;
            self.child_count += 1;
        }
    }
};

/// Layout block info
pub const LayoutBlock = struct {
    init_callback: []const u8,
    update_callback: []const u8,
    shutdown_callback: []const u8,
};

/// Parsed WND file
pub const WndFile = struct {
    version: i32,
    layout: LayoutBlock,
    root_window: ?*WindowDef,
    allocator: Allocator,

    pub fn init(allocator: Allocator) WndFile {
        return WndFile{
            .version = 2,
            .layout = .{
                .init_callback = "[None]",
                .update_callback = "[None]",
                .shutdown_callback = "[None]",
            },
            .root_window = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *WndFile) void {
        if (self.root_window) |root| {
            root.deinit();
            self.allocator.destroy(root);
        }
    }
};

/// WND File Parser
pub const WndParser = struct {
    allocator: Allocator,
    source: []const u8,
    pos: usize,
    line: usize,

    pub fn init(allocator: Allocator, source: []const u8) WndParser {
        return WndParser{
            .allocator = allocator,
            .source = source,
            .pos = 0,
            .line = 1,
        };
    }

    pub fn parse(self: *WndParser) !WndFile {
        var wnd = WndFile.init(self.allocator);

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            if (self.pos >= self.source.len) break;

            const token = self.readToken();
            if (token.len == 0) continue;

            if (std.mem.eql(u8, token, "FILE_VERSION")) {
                _ = self.expect("=");
                wnd.version = self.readInt();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "STARTLAYOUTBLOCK")) {
                try self.parseLayoutBlock(&wnd.layout);
            } else if (std.mem.eql(u8, token, "WINDOW")) {
                wnd.root_window = try self.parseWindow();
            }
        }

        return wnd;
    }

    fn parseLayoutBlock(self: *WndParser, layout: *LayoutBlock) !void {
        while (self.pos < self.source.len) {
            self.skipWhitespace();
            const token = self.readToken();

            if (std.mem.eql(u8, token, "ENDLAYOUTBLOCK")) {
                return;
            } else if (std.mem.eql(u8, token, "LAYOUTINIT")) {
                _ = self.expect("=");
                layout.init_callback = self.readToken();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "LAYOUTUPDATE")) {
                _ = self.expect("=");
                layout.update_callback = self.readToken();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "LAYOUTSHUTDOWN")) {
                _ = self.expect("=");
                layout.shutdown_callback = self.readToken();
                _ = self.expect(";");
            }
        }
    }

    fn parseWindow(self: *WndParser) !*WindowDef {
        const window = try self.allocator.create(WindowDef);
        window.* = WindowDef.init(self.allocator);

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            const token = self.readToken();

            if (std.mem.eql(u8, token, "END")) {
                return window;
            } else if (std.mem.eql(u8, token, "WINDOWTYPE")) {
                _ = self.expect("=");
                const type_str = self.readToken();
                window.window_type = self.parseWindowType(type_str);
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "SCREENRECT")) {
                _ = self.expect("=");
                window.screen_rect = try self.parseRect();
            } else if (std.mem.eql(u8, token, "NAME")) {
                _ = self.expect("=");
                window.name = self.readQuotedString();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "STATUS")) {
                _ = self.expect("=");
                window.status = try self.parseStatus();
            } else if (std.mem.eql(u8, token, "SYSTEMCALLBACK")) {
                _ = self.expect("=");
                window.system_callback = self.readQuotedString();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "INPUTCALLBACK")) {
                _ = self.expect("=");
                window.input_callback = self.readQuotedString();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "DRAWCALLBACK")) {
                _ = self.expect("=");
                window.draw_callback = self.readQuotedString();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "FONT")) {
                _ = self.expect("=");
                window.font = try self.parseFont();
            } else if (std.mem.eql(u8, token, "CHILD")) {
                // Parse nested child window
            } else if (std.mem.eql(u8, token, "WINDOW")) {
                const child = try self.parseWindow();
                window.addChild(child);
            } else if (std.mem.eql(u8, token, "TEXT")) {
                _ = self.expect("=");
                window.text = self.readQuotedString();
                _ = self.expect(";");
            } else if (std.mem.eql(u8, token, "ENABLEDDRAWDATA") or
                std.mem.eql(u8, token, "DISABLEDDRAWDATA") or
                std.mem.eql(u8, token, "HILITEDRAWDATA") or
                std.mem.eql(u8, token, "TEXTCOLOR") or
                std.mem.eql(u8, token, "TOOLTIPCALLBACK") or
                std.mem.eql(u8, token, "HEADERTEMPLATE") or
                std.mem.eql(u8, token, "TOOLTIPDELAY") or
                std.mem.eql(u8, token, "STYLE"))
            {
                // Skip to next semicolon for now
                self.skipToSemicolon();
            }
        }

        return window;
    }

    fn parseWindowType(self: *WndParser, type_str: []const u8) WindowType {
        _ = self;
        if (std.mem.eql(u8, type_str, "USER")) return .user;
        if (std.mem.eql(u8, type_str, "PUSHBUTTON")) return .push_button;
        if (std.mem.eql(u8, type_str, "CHECKBOX")) return .check_box;
        if (std.mem.eql(u8, type_str, "RADIOBUTTON")) return .radio_button;
        if (std.mem.eql(u8, type_str, "LISTBOX")) return .list_box;
        if (std.mem.eql(u8, type_str, "COMBOBOX")) return .combo_box;
        if (std.mem.eql(u8, type_str, "HORZSLIDER")) return .horz_slider;
        if (std.mem.eql(u8, type_str, "VERTSLIDER")) return .vert_slider;
        if (std.mem.eql(u8, type_str, "PROGRESSBAR")) return .progress_bar;
        if (std.mem.eql(u8, type_str, "ENTRYFIELD")) return .entry_field;
        if (std.mem.eql(u8, type_str, "STATICTEXT")) return .static_text;
        if (std.mem.eql(u8, type_str, "TABCONTROL")) return .tab_control;
        return .user;
    }

    fn parseRect(self: *WndParser) !Rect {
        // Parse: UPPERLEFT: x y, BOTTOMRIGHT: x2 y2, CREATIONRESOLUTION: w h;
        var rect = Rect.init(0, 0, 100, 100);

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            const token = self.readToken();

            if (std.mem.eql(u8, token, "UPPERLEFT:")) {
                rect.x = self.readInt();
                rect.y = self.readInt();
            } else if (std.mem.eql(u8, token, "BOTTOMRIGHT:")) {
                const x2 = self.readInt();
                const y2 = self.readInt();
                rect.width = x2 - rect.x;
                rect.height = y2 - rect.y;
            } else if (std.mem.eql(u8, token, "CREATIONRESOLUTION:")) {
                _ = self.readInt(); // width
                _ = self.readInt(); // height
                _ = self.expect(";");
                break;
            }

            // Skip comma if present
            self.skipWhitespace();
            if (self.pos < self.source.len and self.source[self.pos] == ',') {
                self.pos += 1;
            }
        }

        return rect;
    }

    fn parseStatus(self: *WndParser) !WinStatus {
        var status = WinStatus{};

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            if (self.source[self.pos] == ';') {
                self.pos += 1;
                break;
            }
            if (self.source[self.pos] == '+') {
                self.pos += 1;
                continue;
            }

            const token = self.readToken();
            if (std.mem.eql(u8, token, "ENABLED")) status.enabled = true;
            if (std.mem.eql(u8, token, "IMAGE")) status.image = true;
            if (std.mem.eql(u8, token, "BORDER")) status.border = true;
            if (std.mem.eql(u8, token, "HIDDEN")) status.hidden = true;
            if (std.mem.eql(u8, token, "DRAGABLE")) status.dragable = true;
        }

        return status;
    }

    fn parseFont(self: *WndParser) !FontDef {
        var font = FontDef{ .name = "Arial", .size = 12, .bold = false };

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            if (self.source[self.pos] == ';') {
                self.pos += 1;
                break;
            }

            const token = self.readToken();
            if (std.mem.eql(u8, token, "NAME:")) {
                font.name = self.readQuotedString();
            } else if (std.mem.eql(u8, token, "SIZE:")) {
                font.size = self.readInt();
            } else if (std.mem.eql(u8, token, "BOLD:")) {
                font.bold = self.readInt() != 0;
            }

            // Skip comma if present
            self.skipWhitespace();
            if (self.pos < self.source.len and self.source[self.pos] == ',') {
                self.pos += 1;
            }
        }

        return font;
    }

    fn skipWhitespace(self: *WndParser) void {
        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (c == ' ' or c == '\t' or c == '\r') {
                self.pos += 1;
            } else if (c == '\n') {
                self.pos += 1;
                self.line += 1;
            } else if (c == '/' and self.pos + 1 < self.source.len and self.source[self.pos + 1] == '/') {
                // Skip line comment
                while (self.pos < self.source.len and self.source[self.pos] != '\n') {
                    self.pos += 1;
                }
            } else {
                break;
            }
        }
    }

    fn skipToSemicolon(self: *WndParser) void {
        while (self.pos < self.source.len and self.source[self.pos] != ';') {
            if (self.source[self.pos] == '\n') self.line += 1;
            self.pos += 1;
        }
        if (self.pos < self.source.len) self.pos += 1; // Skip semicolon
    }

    fn readToken(self: *WndParser) []const u8 {
        self.skipWhitespace();
        const start = self.pos;

        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (c == ' ' or c == '\t' or c == '\n' or c == '\r' or
                c == '=' or c == ';' or c == ',' or c == ':')
            {
                break;
            }
            self.pos += 1;
        }

        return self.source[start..self.pos];
    }

    fn readQuotedString(self: *WndParser) []const u8 {
        self.skipWhitespace();
        if (self.pos >= self.source.len or self.source[self.pos] != '"') {
            return self.readToken();
        }

        self.pos += 1; // Skip opening quote
        const start = self.pos;

        while (self.pos < self.source.len and self.source[self.pos] != '"') {
            self.pos += 1;
        }

        const result = self.source[start..self.pos];
        if (self.pos < self.source.len) self.pos += 1; // Skip closing quote

        return result;
    }

    fn readInt(self: *WndParser) i32 {
        self.skipWhitespace();
        var negative = false;
        if (self.pos < self.source.len and self.source[self.pos] == '-') {
            negative = true;
            self.pos += 1;
        }

        var value: i32 = 0;
        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (c >= '0' and c <= '9') {
                value = value * 10 + @as(i32, c - '0');
                self.pos += 1;
            } else {
                break;
            }
        }

        return if (negative) -value else value;
    }

    fn expect(self: *WndParser, expected: []const u8) []const u8 {
        self.skipWhitespace();
        if (self.pos + expected.len <= self.source.len and
            std.mem.eql(u8, self.source[self.pos .. self.pos + expected.len], expected))
        {
            self.pos += expected.len;
            return expected;
        }
        return "";
    }
};

/// Load and parse a WND file
pub fn loadWndFile(allocator: Allocator, path: []const u8) !WndFile {
    // Read entire file using std.fs.cwd().readFileAlloc
    const source = try std.fs.cwd().readFileAlloc(path, allocator, .unlimited);
    defer allocator.free(source);

    var parser = WndParser.init(allocator, source);
    return try parser.parse();
}

// Tests
test "parse simple WND" {
    const source =
        \\FILE_VERSION = 2;
        \\STARTLAYOUTBLOCK
        \\  LAYOUTINIT = TestInit;
        \\ENDLAYOUTBLOCK
        \\WINDOW
        \\  WINDOWTYPE = USER;
        \\  NAME = "Test.wnd:TestWindow";
        \\  STATUS = ENABLED+IMAGE;
        \\END
    ;

    var parser = WndParser.init(std.testing.allocator, source);
    var wnd = try parser.parse();
    defer wnd.deinit();

    try std.testing.expectEqual(@as(i32, 2), wnd.version);
    try std.testing.expect(wnd.root_window != null);
    try std.testing.expectEqualStrings("Test.wnd:TestWindow", wnd.root_window.?.name);
}
