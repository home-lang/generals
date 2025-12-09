// macOS Window Implementation in Objective-C
// Simple C-compatible wrapper for Cocoa windowing

#import <Cocoa/Cocoa.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    void *ns_app;
    void *ns_window;
    bool should_close;
    // Keyboard state
    bool key_up;
    bool key_down;
    bool key_left;
    bool key_right;
    bool key_w;
    bool key_a;
    bool key_s;
    bool key_d;
    // Number keys (for unit groups)
    bool key_1;
    bool key_2;
    bool key_3;
    bool key_4;
    bool key_5;
    bool key_6;
    bool key_7;
    bool key_8;
    bool key_9;
    bool key_0;
    // Modifier keys
    bool key_ctrl;
    bool key_shift;
    // Number key pressed this frame (for one-shot detection)
    int8_t number_key_pressed;  // -1 if none, 0-9 if pressed this frame
    // Mouse button state
    bool mouse_left_down;
    bool mouse_right_down;
    bool mouse_left_clicked;   // True for one frame when clicked
    bool mouse_right_clicked;  // True for one frame when clicked
} MacOSWindow;

// Custom view that accepts keyboard input and works with Metal layer
@interface GameView : NSView
@end

@implementation GameView

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    // Don't call super - this prevents the beep sound
    // The event is handled in poll_events
}

- (void)keyUp:(NSEvent *)event {
    // Don't call super
}

- (void)mouseDown:(NSEvent *)event {
    // Make this view the first responder when clicked
    [[self window] makeFirstResponder:self];
    [super mouseDown:event];
}

@end

// Custom window that accepts key events
@interface GameWindow : NSWindow
@end

@implementation GameWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (BOOL)canBecomeMainWindow {
    return YES;
}

@end

// Create a window
MacOSWindow macos_window_create(const char *title, uint32_t width, uint32_t height, bool resizable) {
    @autoreleasepool {
        NSLog(@"macos_window_create: Creating window '%s' (%ux%u)", title, width, height);

        // CRITICAL: For command-line apps to show GUI on macOS
        // Must transform to regular app BEFORE creating window
        NSApplication *app = [NSApplication sharedApplication];

        // Transform process to foreground app (required for CLI apps)
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);

        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        // Finish launching immediately
        if (![app isRunning]) {
            [app finishLaunching];
        }

        // Create window style mask
        NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
        if (resizable) {
            styleMask |= NSWindowStyleMaskResizable;
        }

        // Create window using custom GameWindow class
        NSRect frame = NSMakeRect(100, 100, width, height);
        GameWindow *window = [[GameWindow alloc] initWithContentRect:frame
                                                           styleMask:styleMask
                                                             backing:NSBackingStoreBuffered
                                                               defer:NO];

        // Prevent the window from being released when closed
        [window setReleasedWhenClosed:NO];

        // Set title
        [window setTitle:[NSString stringWithUTF8String:title]];

        // Set window to accept mouse moved events
        [window setAcceptsMouseMovedEvents:YES];

        // Make the window opaque and have a shadow
        [window setOpaque:YES];
        [window setHasShadow:YES];
        [window setBackgroundColor:[NSColor blackColor]];

        // Create and set custom content view that accepts keyboard input
        GameView *gameView = [[GameView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
        [window setContentView:gameView];

        // Center window
        [window center];

        NSLog(@"macos_window_create: Window created at frame: %@", NSStringFromRect([window frame]));

        MacOSWindow result;
        result.ns_app = (__bridge_retained void *)app;
        result.ns_window = (__bridge_retained void *)window;
        result.should_close = false;
        result.key_up = false;
        result.key_down = false;
        result.key_left = false;
        result.key_right = false;
        result.key_w = false;
        result.key_a = false;
        result.key_s = false;
        result.key_d = false;
        result.key_1 = false;
        result.key_2 = false;
        result.key_3 = false;
        result.key_4 = false;
        result.key_5 = false;
        result.key_6 = false;
        result.key_7 = false;
        result.key_8 = false;
        result.key_9 = false;
        result.key_0 = false;
        result.key_ctrl = false;
        result.key_shift = false;
        result.number_key_pressed = -1;
        result.mouse_left_down = false;
        result.mouse_right_down = false;
        result.mouse_left_clicked = false;
        result.mouse_right_clicked = false;

        return result;
    }
}

// Show window
void macos_window_show(MacOSWindow *window) {
    @autoreleasepool {
        NSWindow *ns_window = (__bridge NSWindow *)window->ns_window;
        NSApplication *app = (__bridge NSApplication *)window->ns_app;

        NSLog(@"macos_window_show: Showing window %@", ns_window);

        // Reset window to normal level (not floating)
        [ns_window setLevel:NSNormalWindowLevel];

        // Make the window key and bring to front
        [ns_window makeKeyAndOrderFront:nil];

        // Make the content view first responder for keyboard input
        [[ns_window contentView] becomeFirstResponder];
        [ns_window makeFirstResponder:[ns_window contentView]];

        // Activate the application to bring it to foreground
        [app activateIgnoringOtherApps:YES];

        // Process any pending events immediately
        NSEvent *event;
        while ((event = [app nextEventMatchingMask:NSEventMaskAny
                                         untilDate:[NSDate distantPast]
                                            inMode:NSDefaultRunLoopMode
                                           dequeue:YES])) {
            [app sendEvent:event];
        }

        // Log window state
        NSLog(@"macos_window_show: Window visible: %d, key: %d, frame: %@",
              [ns_window isVisible], [ns_window isKeyWindow], NSStringFromRect([ns_window frame]));
    }
}

// Hide window
void macos_window_hide(MacOSWindow *window) {
    @autoreleasepool {
        NSWindow *ns_window = (__bridge NSWindow *)window->ns_window;
        [ns_window orderOut:nil];
    }
}

// Poll events - returns false if should quit
bool macos_window_poll_events(MacOSWindow *window) {
    @autoreleasepool {
        NSApplication *app = (__bridge NSApplication *)window->ns_app;

        // Reset click flags at the start of each frame
        window->mouse_left_clicked = false;
        window->mouse_right_clicked = false;
        window->number_key_pressed = -1;

        // Update modifier key state from current flags
        NSUInteger modFlags = [NSEvent modifierFlags];
        window->key_ctrl = (modFlags & NSEventModifierFlagControl) != 0;
        window->key_shift = (modFlags & NSEventModifierFlagShift) != 0;

        while (true) {
            NSEvent *event = [app nextEventMatchingMask:NSEventMaskAny
                                              untilDate:nil
                                                 inMode:NSDefaultRunLoopMode
                                                dequeue:YES];

            if (event == nil) {
                break;
            }

            // Handle keyboard events
            if (event.type == NSEventTypeKeyDown) {
                // Check for quit command
                if ([event modifierFlags] & NSEventModifierFlagCommand) {
                    if ([[event characters] isEqualToString:@"q"]) {
                        window->should_close = true;
                        return false;
                    }
                }

                // Track arrow keys and WASD
                unsigned short keyCode = [event keyCode];
                if (keyCode == 126) window->key_up = true;      // Up arrow
                if (keyCode == 125) window->key_down = true;    // Down arrow
                if (keyCode == 123) window->key_left = true;    // Left arrow
                if (keyCode == 124) window->key_right = true;   // Right arrow
                if (keyCode == 13) window->key_w = true;        // W
                if (keyCode == 0) window->key_a = true;         // A
                if (keyCode == 1) window->key_s = true;         // S
                if (keyCode == 2) window->key_d = true;         // D

                // Number keys (top row: 18=1, 19=2, 20=3, 21=4, 23=5, 22=6, 26=7, 28=8, 25=9, 29=0)
                if (keyCode == 18) { window->key_1 = true; window->number_key_pressed = 1; }
                if (keyCode == 19) { window->key_2 = true; window->number_key_pressed = 2; }
                if (keyCode == 20) { window->key_3 = true; window->number_key_pressed = 3; }
                if (keyCode == 21) { window->key_4 = true; window->number_key_pressed = 4; }
                if (keyCode == 23) { window->key_5 = true; window->number_key_pressed = 5; }
                if (keyCode == 22) { window->key_6 = true; window->number_key_pressed = 6; }
                if (keyCode == 26) { window->key_7 = true; window->number_key_pressed = 7; }
                if (keyCode == 28) { window->key_8 = true; window->number_key_pressed = 8; }
                if (keyCode == 25) { window->key_9 = true; window->number_key_pressed = 9; }
                if (keyCode == 29) { window->key_0 = true; window->number_key_pressed = 0; }
            } else if (event.type == NSEventTypeKeyUp) {
                // Release keys
                unsigned short keyCode = [event keyCode];
                if (keyCode == 126) window->key_up = false;
                if (keyCode == 125) window->key_down = false;
                if (keyCode == 123) window->key_left = false;
                if (keyCode == 124) window->key_right = false;
                if (keyCode == 13) window->key_w = false;
                if (keyCode == 0) window->key_a = false;
                if (keyCode == 1) window->key_s = false;
                if (keyCode == 2) window->key_d = false;

                // Number keys release
                if (keyCode == 18) window->key_1 = false;
                if (keyCode == 19) window->key_2 = false;
                if (keyCode == 20) window->key_3 = false;
                if (keyCode == 21) window->key_4 = false;
                if (keyCode == 23) window->key_5 = false;
                if (keyCode == 22) window->key_6 = false;
                if (keyCode == 26) window->key_7 = false;
                if (keyCode == 28) window->key_8 = false;
                if (keyCode == 25) window->key_9 = false;
                if (keyCode == 29) window->key_0 = false;
            } else if (event.type == NSEventTypeLeftMouseDown) {
                window->mouse_left_down = true;
                window->mouse_left_clicked = true;
            } else if (event.type == NSEventTypeLeftMouseUp) {
                window->mouse_left_down = false;
            } else if (event.type == NSEventTypeRightMouseDown) {
                window->mouse_right_down = true;
                window->mouse_right_clicked = true;
            } else if (event.type == NSEventTypeRightMouseUp) {
                window->mouse_right_down = false;
            }

            [app sendEvent:event];
        }

        return !window->should_close;
    }
}

// Get native window handle
void *macos_window_get_native_handle(MacOSWindow *window) {
    return window->ns_window;
}

// Get mouse position in window coordinates
void macos_window_get_mouse_position(MacOSWindow *window, float *x, float *y) {
    @autoreleasepool {
        if (!window || !window->ns_window) {
            *x = 0;
            *y = 0;
            return;
        }
        NSWindow *ns_window = (__bridge NSWindow *)window->ns_window;
        if (!ns_window) {
            *x = 0;
            *y = 0;
            return;
        }
        NSPoint mouseLocation = [NSEvent mouseLocation];
        NSRect windowFrame = [ns_window frame];

        // Convert from screen coordinates to window coordinates
        NSPoint windowPoint;
        windowPoint.x = mouseLocation.x - windowFrame.origin.x;
        windowPoint.y = mouseLocation.y - windowFrame.origin.y;

        // Flip Y coordinate (macOS uses bottom-left origin, we want top-left)
        NSRect contentRect = [[ns_window contentView] frame];
        windowPoint.y = contentRect.size.height - windowPoint.y;

        *x = (float)windowPoint.x;
        *y = (float)windowPoint.y;
    }
}

// Get keyboard state
void macos_window_get_keyboard_state(MacOSWindow *window,
                                      bool *up, bool *down, bool *left, bool *right,
                                      bool *w, bool *a, bool *s, bool *d) {
    *up = window->key_up;
    *down = window->key_down;
    *left = window->key_left;
    *right = window->key_right;
    *w = window->key_w;
    *a = window->key_a;
    *s = window->key_s;
    *d = window->key_d;
}

// Get mouse button state
void macos_window_get_mouse_button_state(MacOSWindow *window,
                                          bool *left_down, bool *right_down,
                                          bool *left_clicked, bool *right_clicked) {
    *left_down = window->mouse_left_down;
    *right_down = window->mouse_right_down;
    *left_clicked = window->mouse_left_clicked;
    *right_clicked = window->mouse_right_clicked;
}

// Get modifier keys and number key pressed this frame
void macos_window_get_modifier_state(MacOSWindow *window,
                                      bool *ctrl, bool *shift,
                                      int8_t *number_pressed) {
    *ctrl = window->key_ctrl;
    *shift = window->key_shift;
    *number_pressed = window->number_key_pressed;
}

// Destroy window
void macos_window_destroy(MacOSWindow *window) {
    @autoreleasepool {
        if (window->ns_window) {
            NSWindow *ns_window = (__bridge_transfer NSWindow *)window->ns_window;
            [ns_window close];
            window->ns_window = NULL;
        }

        if (window->ns_app) {
            // Don't release the shared NSApplication
            window->ns_app = NULL;
        }
    }
}
