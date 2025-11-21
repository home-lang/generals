// macOS Sprite Renderer with Metal
// Extends the basic renderer with textured sprite support

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <stdint.h>
#include <stdbool.h>

typedef struct {
    void *metal_device;
    void *metal_command_queue;
    void *metal_layer;
    void *pipeline_state;
    void *sampler_state;
    void *vertex_buffer;
    void *color_pipeline_state;  // Pipeline for colored shapes
    void *color_vertex_buffer;   // Buffer for colored shapes
    float viewport_width;
    float viewport_height;
} SpriteRenderer;

// Vertex structure matching the Metal shader
typedef struct {
    float position[2];
    float texCoord[2];
} Vertex;

// Colored vertex structure for shapes
typedef struct {
    float position[2];
    float color[4];
} ColorVertex;

// Create sprite renderer
SpriteRenderer sprite_renderer_create(void *ns_window) {
    @autoreleasepool {
        NSWindow *window = (__bridge NSWindow *)ns_window;
        NSLog(@"Creating sprite renderer for window: %@", window);

        // Get Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            NSLog(@"ERROR: Metal is not supported on this device");
            SpriteRenderer result = {0};
            return result;
        }
        NSLog(@"Metal device: %@", device.name);

        // Create command queue
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!commandQueue) {
            NSLog(@"ERROR: Failed to create command queue");
            SpriteRenderer result = {0};
            return result;
        }

        // Create Metal layer
        CAMetalLayer *metalLayer = [CAMetalLayer layer];
        metalLayer.device = device;
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        metalLayer.framebufferOnly = YES; // Set to YES for better performance (we don't sample from it)

        // Setup window - IMPORTANT: setWantsLayer must be called before setLayer
        NSView *contentView = [window contentView];
        [contentView setWantsLayer:YES];
        [contentView setLayer:metalLayer];

        // Get screen scale factor
        CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
        NSLog(@"Screen scale factor: %f", scale);

        // Set up layer properties
        NSRect frame = [contentView frame];
        metalLayer.frame = contentView.bounds;
        metalLayer.contentsScale = scale;
        metalLayer.drawableSize = CGSizeMake(frame.size.width * scale, frame.size.height * scale);
        NSLog(@"Content view frame: %.0f x %.0f", frame.size.width, frame.size.height);
        NSLog(@"Drawable size: %.0f x %.0f", metalLayer.drawableSize.width, metalLayer.drawableSize.height);

        // Compile shaders from source string (inline shader code)
        NSString *shaderSource = @
            "#include <metal_stdlib>\n"
            "using namespace metal;\n"
            "struct Vertex { float2 position; float2 texCoord; };\n"
            "struct RasterizerData { float4 position [[position]]; float2 texCoord; };\n"
            "vertex RasterizerData vertex_main(uint vertexID [[vertex_id]], constant Vertex *vertices [[buffer(0)]], constant float2 *viewportSize [[buffer(1)]]) {\n"
            "    RasterizerData out;\n"
            "    float2 pos = vertices[vertexID].position;\n"
            "    out.texCoord = vertices[vertexID].texCoord;\n"
            "    float2 viewport = *viewportSize;\n"
            "    float2 ndc;\n"
            "    ndc.x = (pos.x / viewport.x) * 2.0 - 1.0;\n"
            "    ndc.y = 1.0 - (pos.y / viewport.y) * 2.0;\n"
            "    out.position = float4(ndc, 0.0, 1.0);\n"
            "    return out;\n"
            "}\n"
            "fragment float4 fragment_main(RasterizerData in [[stage_in]], texture2d<float> texture [[texture(0)]], sampler texSampler [[sampler(0)]]) {\n"
            "    return texture.sample(texSampler, in.texCoord);\n"
            "}\n";

        NSError *error = nil;
        id<MTLLibrary> library = [device newLibraryWithSource:shaderSource options:nil error:&error];
        if (!library) {
            NSLog(@"Failed to compile shaders: %@", error);
            SpriteRenderer result = {0};
            return result;
        }

        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];

        // Create pipeline state
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

        // Enable blending for transparency
        pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

        id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        if (!pipelineState) {
            NSLog(@"Failed to create pipeline state: %@", error);
            SpriteRenderer result = {0};
            return result;
        }

        // Create sampler state
        MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
        samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
        samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;

        id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor:samplerDescriptor];

        // Create vertex buffer for a quad (2 triangles)
        Vertex quadVertices[] = {
            {{0, 0}, {0, 0}},       // Top-left
            {{0, 0}, {1, 0}},       // Top-right
            {{0, 0}, {0, 1}},       // Bottom-left
            {{0, 0}, {1, 0}},       // Top-right
            {{0, 0}, {1, 1}},       // Bottom-right
            {{0, 0}, {0, 1}},       // Bottom-left
        };

        id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:quadVertices
                                                          length:sizeof(quadVertices)
                                                         options:MTLResourceStorageModeShared];

        // Create color shaders for selection indicators
        NSString *colorShaderSource = @
            "#include <metal_stdlib>\n"
            "using namespace metal;\n"
            "struct ColorVertex { float2 position; float4 color; };\n"
            "struct ColorRasterizerData { float4 position [[position]]; float4 color; };\n"
            "vertex ColorRasterizerData color_vertex_main(uint vertexID [[vertex_id]], constant ColorVertex *vertices [[buffer(0)]], constant float2 *viewportSize [[buffer(1)]]) {\n"
            "    ColorRasterizerData out;\n"
            "    float2 pos = vertices[vertexID].position;\n"
            "    out.color = vertices[vertexID].color;\n"
            "    float2 viewport = *viewportSize;\n"
            "    float2 ndc;\n"
            "    ndc.x = (pos.x / viewport.x) * 2.0 - 1.0;\n"
            "    ndc.y = 1.0 - (pos.y / viewport.y) * 2.0;\n"
            "    out.position = float4(ndc, 0.0, 1.0);\n"
            "    return out;\n"
            "}\n"
            "fragment float4 color_fragment_main(ColorRasterizerData in [[stage_in]]) {\n"
            "    return in.color;\n"
            "}\n";

        id<MTLLibrary> colorLibrary = [device newLibraryWithSource:colorShaderSource options:nil error:&error];
        if (!colorLibrary) {
            NSLog(@"Failed to compile color shaders: %@", error);
        }

        id<MTLFunction> colorVertexFunction = [colorLibrary newFunctionWithName:@"color_vertex_main"];
        id<MTLFunction> colorFragmentFunction = [colorLibrary newFunctionWithName:@"color_fragment_main"];

        // Create color pipeline state
        MTLRenderPipelineDescriptor *colorPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        colorPipelineDescriptor.vertexFunction = colorVertexFunction;
        colorPipelineDescriptor.fragmentFunction = colorFragmentFunction;
        colorPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

        // Enable blending for transparency
        colorPipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
        colorPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
        colorPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
        colorPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        colorPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
        colorPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        colorPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

        id<MTLRenderPipelineState> colorPipelineState = [device newRenderPipelineStateWithDescriptor:colorPipelineDescriptor error:&error];
        if (!colorPipelineState) {
            NSLog(@"Failed to create color pipeline state: %@", error);
        }

        // Create color vertex buffer (for circle/ring - 64 segments)
        const int circleSegments = 64;
        const int colorVertexCount = circleSegments * 6; // 2 triangles per segment
        id<MTLBuffer> colorVertexBuffer = [device newBufferWithLength:sizeof(ColorVertex) * colorVertexCount
                                                              options:MTLResourceStorageModeShared];

        SpriteRenderer result;
        result.metal_device = (__bridge_retained void *)device;
        result.metal_command_queue = (__bridge_retained void *)commandQueue;
        result.metal_layer = (__bridge_retained void *)metalLayer;
        result.pipeline_state = (__bridge_retained void *)pipelineState;
        result.sampler_state = (__bridge_retained void *)samplerState;
        result.vertex_buffer = (__bridge_retained void *)vertexBuffer;
        result.color_pipeline_state = (__bridge_retained void *)colorPipelineState;
        result.color_vertex_buffer = (__bridge_retained void *)colorVertexBuffer;
        result.viewport_width = frame.size.width;
        result.viewport_height = frame.size.height;

        return result;
    }
}

// Create texture from raw BGRA data
void *sprite_renderer_create_texture(SpriteRenderer *renderer, uint32_t width, uint32_t height, const uint8_t *data) {
    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)renderer->metal_device;

        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                     width:width
                                                                                                    height:height
                                                                                                 mipmapped:NO];
        textureDescriptor.usage = MTLTextureUsageShaderRead;

        id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];

        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        [texture replaceRegion:region mipmapLevel:0 withBytes:data bytesPerRow:width * 4];

        return (__bridge_retained void *)texture;
    }
}

// Render context that holds all objects for a frame
typedef struct {
    void *drawable;
    void *command_buffer;
    void *render_encoder;
} RenderContext;

// Static frame counter for debug logging
static int frameCount = 0;

// Begin a new frame
// NOTE: No autoreleasepool here - we manually retain objects and release them in end_frame
RenderContext sprite_renderer_begin_frame(SpriteRenderer *renderer) {
    RenderContext ctx = {0};

    CAMetalLayer *layer = (__bridge CAMetalLayer *)renderer->metal_layer;
    if (!layer) {
        NSLog(@"ERROR: Metal layer is NULL");
        return ctx;
    }

    // Log once on first frame
    if (frameCount == 0) {
        NSLog(@"First frame - Metal layer: %@", layer);
        NSLog(@"Layer device: %@", layer.device);
        NSLog(@"Layer pixel format: %lu", (unsigned long)layer.pixelFormat);
        NSLog(@"Layer drawable size: %.0f x %.0f", layer.drawableSize.width, layer.drawableSize.height);
        NSLog(@"Layer frame: %.0f x %.0f", layer.frame.size.width, layer.frame.size.height);
        NSLog(@"Layer contents scale: %f", layer.contentsScale);
    }

    // Get drawable size from layer
    CGSize drawableSize = layer.drawableSize;
    CGFloat scale = layer.contentsScale;
    if (scale <= 0) scale = [[NSScreen mainScreen] backingScaleFactor];

    if (drawableSize.width <= 0 || drawableSize.height <= 0) {
        // Try to get from frame
        CGSize frameSize = layer.frame.size;
        if (frameSize.width > 0 && frameSize.height > 0) {
            layer.drawableSize = CGSizeMake(frameSize.width * scale, frameSize.height * scale);
            drawableSize = layer.drawableSize;
            NSLog(@"Fixed drawable size from frame: %.0f x %.0f", drawableSize.width, drawableSize.height);
        } else {
            NSLog(@"ERROR: Cannot determine drawable size");
            return ctx;
        }
    }

    renderer->viewport_width = drawableSize.width / scale;
    renderer->viewport_height = drawableSize.height / scale;

    id<CAMetalDrawable> drawable = [layer nextDrawable];
    if (!drawable) {
        if (frameCount < 5) {
            NSLog(@"WARNING: Failed to get drawable on frame %d - layer may not be ready", frameCount);
        }
        frameCount++;
        return ctx;
    }

    id<MTLCommandQueue> commandQueue = (__bridge id<MTLCommandQueue>)renderer->metal_command_queue;
    if (!commandQueue) {
        NSLog(@"ERROR: Command queue is NULL");
        return ctx;
    }

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    if (!commandBuffer) {
        NSLog(@"ERROR: Failed to create command buffer");
        return ctx;
    }

    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    // Desert sand color for background (like original C&C Generals)
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.76, 0.66, 0.46, 1.0);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    if (!renderEncoder) {
        NSLog(@"ERROR: Failed to create render encoder");
        return ctx;
    }

    // Log first successful frame
    if (frameCount == 0) {
        NSLog(@"First frame rendering successfully - viewport: %.0f x %.0f", renderer->viewport_width, renderer->viewport_height);
    }

    // Retain all objects for the frame - these will be released in end_frame
    // Using __bridge_retained transfers ownership to the void* pointer
    ctx.drawable = (__bridge_retained void *)drawable;
    ctx.command_buffer = (__bridge_retained void *)commandBuffer;
    ctx.render_encoder = (__bridge_retained void *)renderEncoder;

    frameCount++;

    return ctx;
}

// Static counter for end frame logging
static int endFrameCount = 0;

// End frame and present
void sprite_renderer_end_frame(SpriteRenderer *renderer, RenderContext *ctx) {
    (void)renderer; // Unused but kept for API consistency

    if (!ctx->render_encoder) {
        if (endFrameCount < 5) {
            NSLog(@"WARNING: end_frame called with no render encoder on frame %d", endFrameCount);
        }
        return;
    }

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge_transfer id<MTLRenderCommandEncoder>)ctx->render_encoder;
        id<MTLCommandBuffer> commandBuffer = (__bridge_transfer id<MTLCommandBuffer>)ctx->command_buffer;
        id<CAMetalDrawable> drawable = (__bridge_transfer id<CAMetalDrawable>)ctx->drawable;

        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];

        // Wait for first few frames to complete to ensure proper presentation
        if (endFrameCount < 3) {
            [commandBuffer waitUntilCompleted];
            NSLog(@"Frame %d completed and presented", endFrameCount);
        }

        ctx->drawable = NULL;
        ctx->command_buffer = NULL;
        ctx->render_encoder = NULL;

        endFrameCount++;
    }
}

// Draw a sprite within a render pass
void sprite_renderer_draw_sprite_batched(SpriteRenderer *renderer, RenderContext *ctx, void *texture_ptr, float x, float y, float width, float height) {
    if (!ctx->render_encoder) return;

    id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)ctx->render_encoder;
    id<MTLRenderPipelineState> pipelineState = (__bridge id<MTLRenderPipelineState>)renderer->pipeline_state;
    id<MTLSamplerState> samplerState = (__bridge id<MTLSamplerState>)renderer->sampler_state;
    id<MTLBuffer> vertexBuffer = (__bridge id<MTLBuffer>)renderer->vertex_buffer;
    id<MTLTexture> texture = (__bridge id<MTLTexture>)texture_ptr;

    // Update vertex positions
    Vertex *vertices = (Vertex *)[vertexBuffer contents];
    vertices[0] = (Vertex){{x, y}, {0, 0}};
    vertices[1] = (Vertex){{x + width, y}, {1, 0}};
    vertices[2] = (Vertex){{x, y + height}, {0, 1}};
    vertices[3] = (Vertex){{x + width, y}, {1, 0}};
    vertices[4] = (Vertex){{x + width, y + height}, {1, 1}};
    vertices[5] = (Vertex){{x, y + height}, {0, 1}};

    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

    float viewport[] = {renderer->viewport_width, renderer->viewport_height};
    [renderEncoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];

    [renderEncoder setFragmentTexture:texture atIndex:0];
    [renderEncoder setFragmentSamplerState:samplerState atIndex:0];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

// Draw a filled rectangle
void sprite_renderer_draw_rect(SpriteRenderer *renderer, RenderContext *ctx, float x, float y, float width, float height, float r, float g, float b, float a) {
    if (!ctx->render_encoder) return;

    id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)ctx->render_encoder;
    id<MTLRenderPipelineState> colorPipelineState = (__bridge id<MTLRenderPipelineState>)renderer->color_pipeline_state;
    id<MTLBuffer> colorVertexBuffer = (__bridge id<MTLBuffer>)renderer->color_vertex_buffer;

    // Generate rectangle vertices (2 triangles)
    ColorVertex *vertices = (ColorVertex *)[colorVertexBuffer contents];

    // Triangle 1
    vertices[0] = (ColorVertex){{x, y}, {r, g, b, a}};                    // Top-left
    vertices[1] = (ColorVertex){{x + width, y}, {r, g, b, a}};           // Top-right
    vertices[2] = (ColorVertex){{x, y + height}, {r, g, b, a}};          // Bottom-left

    // Triangle 2
    vertices[3] = (ColorVertex){{x + width, y}, {r, g, b, a}};           // Top-right
    vertices[4] = (ColorVertex){{x + width, y + height}, {r, g, b, a}};  // Bottom-right
    vertices[5] = (ColorVertex){{x, y + height}, {r, g, b, a}};          // Bottom-left

    [renderEncoder setRenderPipelineState:colorPipelineState];
    [renderEncoder setVertexBuffer:colorVertexBuffer offset:0 atIndex:0];

    float viewport[] = {renderer->viewport_width, renderer->viewport_height};
    [renderEncoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

// Draw a selection circle
void sprite_renderer_draw_selection_circle(SpriteRenderer *renderer, RenderContext *ctx, float center_x, float center_y, float radius, float r, float g, float b, float a) {
    if (!ctx->render_encoder) return;

    id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)ctx->render_encoder;
    id<MTLRenderPipelineState> colorPipelineState = (__bridge id<MTLRenderPipelineState>)renderer->color_pipeline_state;
    id<MTLBuffer> colorVertexBuffer = (__bridge id<MTLBuffer>)renderer->color_vertex_buffer;

    // Generate circle vertices
    const int segments = 64;
    const float thickness = 3.0f; // Circle thickness in pixels
    ColorVertex *vertices = (ColorVertex *)[colorVertexBuffer contents];

    for (int i = 0; i < segments; i++) {
        float angle1 = (float)i / segments * 2.0f * M_PI;
        float angle2 = (float)(i + 1) / segments * 2.0f * M_PI;

        float x1_outer = center_x + cosf(angle1) * (radius + thickness/2);
        float y1_outer = center_y + sinf(angle1) * (radius + thickness/2);
        float x1_inner = center_x + cosf(angle1) * (radius - thickness/2);
        float y1_inner = center_y + sinf(angle1) * (radius - thickness/2);

        float x2_outer = center_x + cosf(angle2) * (radius + thickness/2);
        float y2_outer = center_y + sinf(angle2) * (radius + thickness/2);
        float x2_inner = center_x + cosf(angle2) * (radius - thickness/2);
        float y2_inner = center_y + sinf(angle2) * (radius - thickness/2);

        // First triangle
        vertices[i * 6 + 0] = (ColorVertex){{x1_outer, y1_outer}, {r, g, b, a}};
        vertices[i * 6 + 1] = (ColorVertex){{x2_outer, y2_outer}, {r, g, b, a}};
        vertices[i * 6 + 2] = (ColorVertex){{x1_inner, y1_inner}, {r, g, b, a}};

        // Second triangle
        vertices[i * 6 + 3] = (ColorVertex){{x2_outer, y2_outer}, {r, g, b, a}};
        vertices[i * 6 + 4] = (ColorVertex){{x2_inner, y2_inner}, {r, g, b, a}};
        vertices[i * 6 + 5] = (ColorVertex){{x1_inner, y1_inner}, {r, g, b, a}};
    }

    [renderEncoder setRenderPipelineState:colorPipelineState];
    [renderEncoder setVertexBuffer:colorVertexBuffer offset:0 atIndex:0];

    float viewport[] = {renderer->viewport_width, renderer->viewport_height};
    [renderEncoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:segments * 6];
}

// Render a sprite (old single-call interface - deprecated but kept for compatibility)
bool sprite_renderer_draw_sprite(SpriteRenderer *renderer, void *texture_ptr, float x, float y, float width, float height) {
    @autoreleasepool {
        CAMetalLayer *layer = (__bridge CAMetalLayer *)renderer->metal_layer;
        id<MTLCommandQueue> commandQueue = (__bridge id<MTLCommandQueue>)renderer->metal_command_queue;
        id<MTLRenderPipelineState> pipelineState = (__bridge id<MTLRenderPipelineState>)renderer->pipeline_state;
        id<MTLSamplerState> samplerState = (__bridge id<MTLSamplerState>)renderer->sampler_state;
        id<MTLBuffer> vertexBuffer = (__bridge id<MTLBuffer>)renderer->vertex_buffer;
        id<MTLTexture> texture = (__bridge id<MTLTexture>)texture_ptr;

        id<CAMetalDrawable> drawable = [layer nextDrawable];
        if (!drawable) return false;

        // Update vertex positions
        Vertex *vertices = (Vertex *)[vertexBuffer contents];
        vertices[0] = (Vertex){{x, y}, {0, 0}};
        vertices[1] = (Vertex){{x + width, y}, {1, 0}};
        vertices[2] = (Vertex){{x, y + height}, {0, 1}};
        vertices[3] = (Vertex){{x + width, y}, {1, 0}};
        vertices[4] = (Vertex){{x + width, y + height}, {1, 1}};
        vertices[5] = (Vertex){{x, y + height}, {0, 1}};

        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderEncoder setRenderPipelineState:pipelineState];
        [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

        float viewport[] = {renderer->viewport_width, renderer->viewport_height};
        [renderEncoder setVertexBytes:viewport length:sizeof(viewport) atIndex:1];

        [renderEncoder setFragmentTexture:texture atIndex:0];
        [renderEncoder setFragmentSamplerState:samplerState atIndex:0];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];

        return true;
    }
}

// Destroy texture
void sprite_renderer_destroy_texture(void *texture_ptr) {
    @autoreleasepool {
        if (texture_ptr) {
            id<MTLTexture> texture = (__bridge_transfer id<MTLTexture>)texture_ptr;
            (void)texture;
        }
    }
}

// Destroy renderer
void sprite_renderer_destroy(SpriteRenderer *renderer) {
    @autoreleasepool {
        if (renderer->color_vertex_buffer) {
            id<MTLBuffer> buffer = (__bridge_transfer id<MTLBuffer>)renderer->color_vertex_buffer;
            (void)buffer;
        }
        if (renderer->color_pipeline_state) {
            id<MTLRenderPipelineState> pipeline = (__bridge_transfer id<MTLRenderPipelineState>)renderer->color_pipeline_state;
            (void)pipeline;
        }
        if (renderer->vertex_buffer) {
            id<MTLBuffer> buffer = (__bridge_transfer id<MTLBuffer>)renderer->vertex_buffer;
            (void)buffer;
        }
        if (renderer->sampler_state) {
            id<MTLSamplerState> sampler = (__bridge_transfer id<MTLSamplerState>)renderer->sampler_state;
            (void)sampler;
        }
        if (renderer->pipeline_state) {
            id<MTLRenderPipelineState> pipeline = (__bridge_transfer id<MTLRenderPipelineState>)renderer->pipeline_state;
            (void)pipeline;
        }
        if (renderer->metal_layer) {
            CAMetalLayer *layer = (__bridge_transfer CAMetalLayer *)renderer->metal_layer;
            (void)layer;
        }
        if (renderer->metal_command_queue) {
            id<MTLCommandQueue> queue = (__bridge_transfer id<MTLCommandQueue>)renderer->metal_command_queue;
            (void)queue;
        }
        if (renderer->metal_device) {
            id<MTLDevice> device = (__bridge_transfer id<MTLDevice>)renderer->metal_device;
            (void)device;
        }
    }
}
