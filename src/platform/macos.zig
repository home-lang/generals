// macOS Platform Layer - Craft-style Objective-C FFI
// Type-safe Zig wrappers for macOS platform APIs
const std = @import("std");

// =============================================================================
// Objective-C Runtime Types and Functions (manual declarations)
// =============================================================================
pub const objc = struct {
    pub const id = ?*anyopaque;
    pub const Class = ?*anyopaque;
    pub const SEL = ?*anyopaque;
    pub const IMP = ?*anyopaque;
    pub const BOOL = bool;
    pub const Method = ?*anyopaque;
    pub const Ivar = ?*anyopaque;
    pub const Protocol = ?*anyopaque;

    // Objective-C runtime functions
    pub extern "objc" fn objc_getClass(name: [*:0]const u8) Class;
    pub extern "objc" fn objc_allocateClassPair(superclass: Class, name: [*:0]const u8, extraBytes: usize) Class;
    pub extern "objc" fn objc_registerClassPair(cls: Class) void;
    pub extern "objc" fn sel_registerName(name: [*:0]const u8) SEL;
    pub extern "objc" fn class_addMethod(cls: Class, name: SEL, imp: IMP, types: [*:0]const u8) BOOL;
    pub extern "objc" fn class_addIvar(cls: Class, name: [*:0]const u8, size: usize, alignment: u8, types: [*:0]const u8) BOOL;
    pub extern "objc" fn object_getIvar(obj: id, ivar: Ivar) id;
    pub extern "objc" fn object_setIvar(obj: id, ivar: Ivar, value: id) void;
    pub extern "objc" fn class_getInstanceVariable(cls: Class, name: [*:0]const u8) Ivar;
    pub extern "objc" fn objc_msgSend() void; // Actual signature varies, cast as needed
    pub extern "objc" fn objc_msgSend_stret() void;
    pub extern "objc" fn object_getClass(obj: id) Class;
    pub extern "objc" fn class_getSuperclass(cls: Class) Class;
    pub extern "objc" fn class_getName(cls: Class) [*:0]const u8;
    pub extern "objc" fn method_getImplementation(m: Method) IMP;
    pub extern "objc" fn class_getInstanceMethod(cls: Class, sel_arg: SEL) Method;
    pub extern "objc" fn class_getClassMethod(cls: Class, sel_arg: SEL) Method;
    pub extern "objc" fn class_getMethodImplementation(cls: Class, sel_arg: SEL) IMP;
    pub extern "objc" fn objc_setAssociatedObject(object: id, key: *const anyopaque, value: id, policy: usize) void;
    pub extern "objc" fn objc_getAssociatedObject(object: id, key: *const anyopaque) id;

    // Association policy constants
    pub const OBJC_ASSOCIATION_ASSIGN: usize = 0;
    pub const OBJC_ASSOCIATION_RETAIN_NONATOMIC: usize = 1;
    pub const OBJC_ASSOCIATION_COPY_NONATOMIC: usize = 3;
    pub const OBJC_ASSOCIATION_RETAIN: usize = 0x301;
    pub const OBJC_ASSOCIATION_COPY: usize = 0x303;
};

// =============================================================================
// Core Graphics Types
// =============================================================================
pub const NSRect = extern struct {
    origin: NSPoint,
    size: NSSize,
};

pub const NSPoint = extern struct {
    x: f64,
    y: f64,
};

pub const NSSize = extern struct {
    width: f64,
    height: f64,
};

pub const CGFloat = f64;

// =============================================================================
// Window Style Configuration (Craft-style)
// =============================================================================
pub const WindowStyle = struct {
    frameless: bool = false,
    transparent: bool = false,
    always_on_top: bool = false,
    resizable: bool = true,
    closable: bool = true,
    miniaturizable: bool = true,
    fullscreen: bool = false,
    x: ?i32 = null, // Window x position (null = center)
    y: ?i32 = null, // Window y position (null = center)
    dark_mode: ?bool = null, // null = system default, true = dark, false = light
    titlebar_hidden: bool = false, // Hide titlebar (content extends into titlebar area)
};

// NSWindowStyleMask constants
pub const NSWindowStyleMask = struct {
    pub const Borderless: c_ulong = 0;
    pub const Titled: c_ulong = 1;
    pub const Closable: c_ulong = 2;
    pub const Miniaturizable: c_ulong = 4;
    pub const Resizable: c_ulong = 8;
    pub const FullSizeContentView: c_ulong = 32768;
};

// NSEventType constants
pub const NSEventType = struct {
    pub const KeyDown: c_ulong = 10;
    pub const KeyUp: c_ulong = 11;
    pub const LeftMouseDown: c_ulong = 1;
    pub const LeftMouseUp: c_ulong = 2;
    pub const RightMouseDown: c_ulong = 3;
    pub const RightMouseUp: c_ulong = 4;
    pub const MouseMoved: c_ulong = 5;
};

// NSEventMask constants
pub const NSEventMask = struct {
    pub const Any: c_ulonglong = 0xFFFFFFFFFFFFFFFF;
};

// NSEventModifierFlags constants
pub const NSEventModifierFlags = struct {
    pub const Command: c_ulong = 1 << 20;
    pub const Control: c_ulong = 1 << 18;
    pub const Shift: c_ulong = 1 << 17;
    pub const Option: c_ulong = 1 << 19;
};

// macOS Key Codes
pub const KeyCode = struct {
    pub const UpArrow: u16 = 126;
    pub const DownArrow: u16 = 125;
    pub const LeftArrow: u16 = 123;
    pub const RightArrow: u16 = 124;
    pub const W: u16 = 13;
    pub const A: u16 = 0;
    pub const S: u16 = 1;
    pub const D: u16 = 2;
    pub const Key1: u16 = 18;
    pub const Key2: u16 = 19;
    pub const Key3: u16 = 20;
    pub const Key4: u16 = 21;
    pub const Key5: u16 = 23;
    pub const Key6: u16 = 22;
    pub const Key7: u16 = 26;
    pub const Key8: u16 = 28;
    pub const Key9: u16 = 25;
    pub const Key0: u16 = 29;
};

// =============================================================================
// Helper Functions for Objective-C Runtime
// =============================================================================
pub fn getClass(name: [*:0]const u8) objc.Class {
    return objc.objc_getClass(name);
}

pub fn sel(name: [*:0]const u8) objc.SEL {
    return objc.sel_registerName(name);
}

// =============================================================================
// Message Send Wrappers (type-safe)
// =============================================================================

/// Message send with no arguments, returns id
pub fn msgSend0(target: anytype, selector: [*:0]const u8) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send with 1 argument, returns id
pub fn msgSend1(target: anytype, selector: [*:0]const u8, arg1: anytype) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, @TypeOf(arg1)) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector), arg1);
}

/// Message send with 2 arguments, returns id
pub fn msgSend2(target: anytype, selector: [*:0]const u8, arg1: anytype, arg2: anytype) objc.id {
    const Arg1Type = if (@TypeOf(arg1) == @TypeOf(null)) ?*anyopaque else @TypeOf(arg1);
    const Arg2Type = if (@TypeOf(arg2) == @TypeOf(null)) ?*anyopaque else @TypeOf(arg2);
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, Arg1Type, Arg2Type) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    const typed_arg1: Arg1Type = if (@TypeOf(arg1) == @TypeOf(null)) null else arg1;
    const typed_arg2: Arg2Type = if (@TypeOf(arg2) == @TypeOf(null)) null else arg2;
    return msg(target, sel(selector), typed_arg1, typed_arg2);
}

/// Message send with 3 arguments, returns id
pub fn msgSend3(target: anytype, selector: [*:0]const u8, arg1: anytype, arg2: anytype, arg3: anytype) objc.id {
    const Arg1Type = if (@TypeOf(arg1) == @TypeOf(null)) ?*anyopaque else @TypeOf(arg1);
    const Arg2Type = if (@TypeOf(arg2) == @TypeOf(null)) ?*anyopaque else @TypeOf(arg2);
    const Arg3Type = if (@TypeOf(arg3) == @TypeOf(null)) ?*anyopaque else @TypeOf(arg3);
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, Arg1Type, Arg2Type, Arg3Type) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    const typed_arg1: Arg1Type = if (@TypeOf(arg1) == @TypeOf(null)) null else arg1;
    const typed_arg2: Arg2Type = if (@TypeOf(arg2) == @TypeOf(null)) null else arg2;
    const typed_arg3: Arg3Type = if (@TypeOf(arg3) == @TypeOf(null)) null else arg3;
    return msg(target, sel(selector), typed_arg1, typed_arg2, typed_arg3);
}

/// Message send with 4 arguments, returns id
pub fn msgSend4(target: anytype, selector: [*:0]const u8, arg1: anytype, arg2: anytype, arg3: anytype, arg4: anytype) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, @TypeOf(arg1), @TypeOf(arg2), @TypeOf(arg3), @TypeOf(arg4)) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector), arg1, arg2, arg3, arg4);
}

/// Message send with no arguments, returns void
pub fn msgSendVoid0(target: anytype, selector: [*:0]const u8) void {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) void, @ptrCast(&objc.objc_msgSend));
    msg(target, sel(selector));
}

/// Message send with 1 argument, returns void
pub fn msgSendVoid1(target: anytype, selector: [*:0]const u8, arg1: anytype) void {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, @TypeOf(arg1)) callconv(.c) void, @ptrCast(&objc.objc_msgSend));
    msg(target, sel(selector), arg1);
}

/// Message send with 2 arguments, returns void
pub fn msgSendVoid2(target: anytype, selector: [*:0]const u8, arg1: anytype, arg2: anytype) void {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, @TypeOf(arg1), @TypeOf(arg2)) callconv(.c) void, @ptrCast(&objc.objc_msgSend));
    msg(target, sel(selector), arg1, arg2);
}

/// Message send that returns NSRect (for methods like -frame)
pub fn msgSendRect(target: anytype, selector: [*:0]const u8) NSRect {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) NSRect, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send that returns CGFloat (f64)
pub fn msgSendFloat(target: anytype, selector: [*:0]const u8) f64 {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) f64, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send that returns bool
pub fn msgSendBool(target: anytype, selector: [*:0]const u8) bool {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) bool, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send that returns u16 (for keyCode)
pub fn msgSendU16(target: anytype, selector: [*:0]const u8) u16 {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) u16, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send that returns c_ulong (for type, modifierFlags)
pub fn msgSendULong(target: anytype, selector: [*:0]const u8) c_ulong {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL) callconv(.c) c_ulong, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector));
}

/// Message send with 1 bool argument, returns id
pub fn msgSend1Bool(target: anytype, selector: [*:0]const u8, arg1: bool) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, bool) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector), arg1);
}

/// Message send with 1 f64 argument, returns id
pub fn msgSend1Double(target: anytype, selector: [*:0]const u8, arg1: f64) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, f64) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector), arg1);
}

/// Message send with 1 c_ulong argument, returns id
pub fn msgSend1ULong(target: anytype, selector: [*:0]const u8, arg1: c_ulong) objc.id {
    const msg = @as(*const fn (@TypeOf(target), objc.SEL, c_ulong) callconv(.c) objc.id, @ptrCast(&objc.objc_msgSend));
    return msg(target, sel(selector), arg1);
}

// =============================================================================
// NSString Helper
// =============================================================================
pub fn createNSString(str: []const u8, allocator: std.mem.Allocator) !objc.id {
    const cstr = try allocator.dupeZ(u8, str);
    defer allocator.free(cstr);
    const NSString = getClass("NSString");
    const str_alloc = msgSend0(NSString, "alloc");
    return msgSend1(str_alloc, "initWithUTF8String:", cstr.ptr);
}

pub fn createNSStringFromCStr(cstr: [*:0]const u8) objc.id {
    const NSString = getClass("NSString");
    const str_alloc = msgSend0(NSString, "alloc");
    return msgSend1(str_alloc, "initWithUTF8String:", cstr);
}

// =============================================================================
// Menu Item Helper (Craft-style)
// =============================================================================
pub const MenuItem = struct {
    title: [*:0]const u8,
    action: ?objc.SEL = null,
    target: objc.id = null,
    key_equivalent: [*:0]const u8 = "",
    modifier_mask: c_ulong = NSEventModifierFlags.Command,
    submenu: ?[]const MenuItem = null,
};

pub fn createMenu(title: [*:0]const u8, items: []const MenuItem) objc.id {
    const NSMenu = getClass("NSMenu");
    const NSMenuItem = getClass("NSMenuItem");

    const title_str = createNSStringFromCStr(title);
    const menu_alloc = msgSend0(NSMenu, "alloc");
    const menu = msgSend1(menu_alloc, "initWithTitle:", title_str);

    for (items) |item| {
        if (std.mem.eql(u8, std.mem.span(item.title), "-")) {
            // Separator item
            const separator = msgSend0(NSMenuItem, "separatorItem");
            _ = msgSend1(menu, "addItem:", separator);
        } else {
            const item_title = createNSStringFromCStr(item.title);
            const key_equiv = createNSStringFromCStr(item.key_equivalent);

            const menu_item_alloc = msgSend0(NSMenuItem, "alloc");
            const menu_item = msgSend3(menu_item_alloc, "initWithTitle:action:keyEquivalent:", item_title, item.action, key_equiv);

            if (item.target != null) {
                _ = msgSend1(menu_item, "setTarget:", item.target);
            }

            if (item.modifier_mask != NSEventModifierFlags.Command) {
                _ = msgSend1ULong(menu_item, "setKeyEquivalentModifierMask:", item.modifier_mask);
            }

            if (item.submenu) |sub_items| {
                const submenu = createMenu(item.title, sub_items);
                _ = msgSend1(menu_item, "setSubmenu:", submenu);
            }

            _ = msgSend1(menu, "addItem:", menu_item);
        }
    }

    return menu;
}

// =============================================================================
// Window State
// =============================================================================
pub const WindowState = struct {
    ns_app: objc.id,
    ns_window: objc.id,
    should_close: bool,

    // Keyboard state
    key_up: bool,
    key_down: bool,
    key_left: bool,
    key_right: bool,
    key_w: bool,
    key_a: bool,
    key_s: bool,
    key_d: bool,

    // Number keys (for unit groups)
    key_1: bool,
    key_2: bool,
    key_3: bool,
    key_4: bool,
    key_5: bool,
    key_6: bool,
    key_7: bool,
    key_8: bool,
    key_9: bool,
    key_0: bool,

    // Modifier keys
    key_ctrl: bool,
    key_shift: bool,

    // Number key pressed this frame (-1 if none, 0-9 if pressed)
    number_key_pressed: i8,

    // Mouse button state
    mouse_left_down: bool,
    mouse_right_down: bool,
    mouse_left_clicked: bool, // True for one frame when clicked
    mouse_right_clicked: bool, // True for one frame when clicked

    pub fn init() WindowState {
        return WindowState{
            .ns_app = null,
            .ns_window = null,
            .should_close = false,
            .key_up = false,
            .key_down = false,
            .key_left = false,
            .key_right = false,
            .key_w = false,
            .key_a = false,
            .key_s = false,
            .key_d = false,
            .key_1 = false,
            .key_2 = false,
            .key_3 = false,
            .key_4 = false,
            .key_5 = false,
            .key_6 = false,
            .key_7 = false,
            .key_8 = false,
            .key_9 = false,
            .key_0 = false,
            .key_ctrl = false,
            .key_shift = false,
            .number_key_pressed = -1,
            .mouse_left_down = false,
            .mouse_right_down = false,
            .mouse_left_clicked = false,
            .mouse_right_clicked = false,
        };
    }
};

// =============================================================================
// Utility Functions
// =============================================================================

/// Build style mask from WindowStyle
pub fn buildStyleMask(style: WindowStyle) c_ulong {
    if (style.frameless) {
        return NSWindowStyleMask.Borderless;
    }

    var mask: c_ulong = NSWindowStyleMask.Titled;
    if (style.closable) mask |= NSWindowStyleMask.Closable;
    if (style.miniaturizable) mask |= NSWindowStyleMask.Miniaturizable;
    if (style.resizable) mask |= NSWindowStyleMask.Resizable;
    if (style.titlebar_hidden) mask |= NSWindowStyleMask.FullSizeContentView;

    return mask;
}

/// Get window frame
pub fn getWindowFrame(window: objc.id) NSRect {
    return msgSendRect(window, "frame");
}

/// Get content view frame
pub fn getContentViewFrame(window: objc.id) NSRect {
    const content_view = msgSend0(window, "contentView");
    return msgSendRect(content_view, "frame");
}

/// Check if window is key (focused)
pub fn isKeyWindow(window: objc.id) bool {
    return msgSendBool(window, "isKeyWindow");
}

/// Check if window is visible
pub fn isWindowVisible(window: objc.id) bool {
    return msgSendBool(window, "isVisible");
}
