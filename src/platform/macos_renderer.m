// macOS Metal Renderer Implementation
// Simple 2D rendering using Metal

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    void *metal_device;
    void *metal_command_queue;
    void *metal_layer;
} MacOSRenderer;

// Create Metal renderer for a window
MacOSRenderer macos_renderer_create(void *ns_window) {
    @autoreleasepool {
        NSWindow *window = (__bridge NSWindow *)ns_window;

        // Get Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"Metal is not supported on this device");
            MacOSRenderer result = {0};
            return result;
        }

        // Create command queue
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];

        // Create Metal layer
        CAMetalLayer *metalLayer = [CAMetalLayer layer];
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        metalLayer.framebufferOnly = YES;

        // Get window content view and set the Metal layer
        NSView *contentView = [window contentView];
        [contentView setLayer:metalLayer];
        [contentView setWantsLayer:YES];

        // Set layer size to match window size
        NSRect frame = [contentView frame];
        CGSize drawableSize = CGSizeMake(frame.size.width, frame.size.height);
        metalLayer.drawableSize = drawableSize;

        // Set content scale
        metalLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];

        MacOSRenderer result;
        result.metal_device = (__bridge_retained void *)device;
        result.metal_command_queue = (__bridge_retained void *)commandQueue;
        result.metal_layer = (__bridge_retained void *)metalLayer;

        return result;
    }
}

// Render a frame with a solid color
bool macos_renderer_render_frame(MacOSRenderer *renderer, float r, float g, float b, float a) {
    @autoreleasepool {
        CAMetalLayer *layer = (__bridge CAMetalLayer *)renderer->metal_layer;
        id<MTLCommandQueue> commandQueue = (__bridge id<MTLCommandQueue>)renderer->metal_command_queue;

        // Get next drawable
        id<CAMetalDrawable> drawable = [layer nextDrawable];
        if (!drawable) {
            return false;
        }

        // Create command buffer
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        if (!commandBuffer) {
            return false;
        }

        // Create render pass descriptor
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a);
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        // Create render command encoder
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder endEncoding];

        // Present drawable and commit
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];

        return true;
    }
}

// Destroy renderer
void macos_renderer_destroy(MacOSRenderer *renderer) {
    @autoreleasepool {
        if (renderer->metal_layer) {
            CAMetalLayer *layer = (__bridge_transfer CAMetalLayer *)renderer->metal_layer;
            (void)layer;
            renderer->metal_layer = NULL;
        }

        if (renderer->metal_command_queue) {
            id<MTLCommandQueue> queue = (__bridge_transfer id<MTLCommandQueue>)renderer->metal_command_queue;
            (void)queue;
            renderer->metal_command_queue = NULL;
        }

        if (renderer->metal_device) {
            id<MTLDevice> device = (__bridge_transfer id<MTLDevice>)renderer->metal_device;
            (void)device;
            renderer->metal_device = NULL;
        }
    }
}
