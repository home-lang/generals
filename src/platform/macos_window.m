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
    // Mouse button state
    bool mouse_left_down;
    bool mouse_right_down;
    bool mouse_left_clicked;   // True for one frame when clicked
    bool mouse_right_clicked;  // True for one frame when clicked
} MacOSWindow;

// Create a window
MacOSWindow macos_window_create(const char *title, uint32_t width, uint32_t height, bool resizable) {
    @autoreleasepool {
        // Get shared application
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        // Create window style mask
        NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
        if (resizable) {
            styleMask |= NSWindowStyleMaskResizable;
        }

        // Create window
        NSRect frame = NSMakeRect(100, 100, width, height);
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                      styleMask:styleMask
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];

        // Set title
        [window setTitle:[NSString stringWithUTF8String:title]];

        // Center window
        [window center];

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

        [ns_window makeKeyAndOrderFront:nil];
        [app activateIgnoringOtherApps:YES];
        [app finishLaunching];
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
        NSWindow *ns_window = (__bridge NSWindow *)window->ns_window;
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
