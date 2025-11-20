// Metal Shaders for Generals 2D Rendering
#include <metal_stdlib>
using namespace metal;

// Vertex structure
struct Vertex {
    float2 position;  // Screen position
    float2 texCoord;  // Texture coordinates (0-1)
};

// Vertex shader output / Fragment shader input
struct RasterizerData {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex shader - transforms vertices for 2D rendering
vertex RasterizerData
vertex_main(uint vertexID [[vertex_id]],
            constant Vertex *vertices [[buffer(0)]],
            constant float2 *viewportSize [[buffer(1)]])
{
    RasterizerData out;

    // Get vertex position and tex coord
    float2 pos = vertices[vertexID].position;
    out.texCoord = vertices[vertexID].texCoord;

    // Convert from pixel coordinates to normalized device coordinates
    // Pixel coordinates: (0,0) top-left, (width, height) bottom-right
    // NDC: (-1,-1) bottom-left, (1,1) top-right
    float2 pixelPos = pos;
    float2 viewport = *viewportSize;

    float2 ndc;
    ndc.x = (pixelPos.x / viewport.x) * 2.0 - 1.0;
    ndc.y = 1.0 - (pixelPos.y / viewport.y) * 2.0;

    out.position = float4(ndc, 0.0, 1.0);

    return out;
}

// Fragment shader - samples texture and outputs color
fragment float4
fragment_main(RasterizerData in [[stage_in]],
             texture2d<float> texture [[texture(0)]],
             sampler texSampler [[sampler(0)]])
{
    // Sample the texture
    float4 color = texture.sample(texSampler, in.texCoord);

    return color;
}
