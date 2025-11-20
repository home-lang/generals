// Home Programming Language - Post-Processing Effects
// HDR rendering, bloom, shadows, SSAO, and other effects
//
// Features:
// - Bloom (HDR glow)
// - Shadow mapping (directional + point lights)
// - Screen-space ambient occlusion (SSAO)
// - Tone mapping
// - FXAA anti-aliasing
// - Depth of field

const std = @import("std");
const gl = @import("opengl.zig");

// ============================================================================
// Framebuffer Management
// ============================================================================

pub const Framebuffer = struct {
    fbo: gl.GLuint,
    color_texture: gl.GLuint,
    depth_texture: gl.GLuint,
    width: u32,
    height: u32,

    pub fn init(width: u32, height: u32, hdr: bool) !Framebuffer {
        const fbo = gl.genFramebuffer();
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);

        // Color texture
        const color_texture = gl.genTexture();
        gl.glBindTexture(gl.GL_TEXTURE_2D, color_texture);

        const format = if (hdr) gl.GL_RGBA16 else gl.GL_RGBA8;
        gl.glTexImage2D(
            gl.GL_TEXTURE_2D,
            0,
            @intCast(format),
            @intCast(width),
            @intCast(height),
            0,
            gl.GL_RGBA,
            gl.GL_FLOAT,
            null,
        );

        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, @intCast(gl.GL_LINEAR));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, @intCast(gl.GL_LINEAR));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, @intCast(gl.GL_CLAMP_TO_EDGE));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, @intCast(gl.GL_CLAMP_TO_EDGE));

        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, color_texture, 0);

        // Depth texture
        const depth_texture = gl.genTexture();
        gl.glBindTexture(gl.GL_TEXTURE_2D, depth_texture);
        gl.glTexImage2D(
            gl.GL_TEXTURE_2D,
            0,
            gl.GL_DEPTH_COMPONENT24,
            @intCast(width),
            @intCast(height),
            0,
            gl.GL_DEPTH_COMPONENT,
            gl.GL_FLOAT,
            null,
        );

        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_TEXTURE_2D, depth_texture, 0);

        // Check completeness
        if (gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER) != gl.GL_FRAMEBUFFER_COMPLETE) {
            return error.FramebufferIncomplete;
        }

        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

        return Framebuffer{
            .fbo = fbo,
            .color_texture = color_texture,
            .depth_texture = depth_texture,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Framebuffer) void {
        gl.deleteFramebuffer(self.fbo);
        gl.deleteTexture(self.color_texture);
        gl.deleteTexture(self.depth_texture);
    }

    pub fn bind(self: *const Framebuffer) void {
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.fbo);
        gl.glViewport(0, 0, @intCast(self.width), @intCast(self.height));
    }

    pub fn unbind() void {
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);
    }
};

// ============================================================================
// Bloom Effect
// ============================================================================

const bloom_extract_shader =
    \\#version 410 core
    \\in vec2 TexCoords;
    \\out vec4 FragColor;
    \\uniform sampler2D hdrTexture;
    \\uniform float threshold;
    \\void main() {
    \\    vec3 color = texture(hdrTexture, TexCoords).rgb;
    \\    float brightness = dot(color, vec3(0.2126, 0.7152, 0.0722));
    \\    FragColor = brightness > threshold ? vec4(color, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
    \\}
;

const bloom_blur_shader =
    \\#version 410 core
    \\in vec2 TexCoords;
    \\out vec4 FragColor;
    \\uniform sampler2D image;
    \\uniform bool horizontal;
    \\uniform float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
    \\void main() {
    \\    vec2 tex_offset = 1.0 / textureSize(image, 0);
    \\    vec3 result = texture(image, TexCoords).rgb * weight[0];
    \\    if (horizontal) {
    \\        for (int i = 1; i < 5; ++i) {
    \\            result += texture(image, TexCoords + vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
    \\            result += texture(image, TexCoords - vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
    \\        }
    \\    } else {
    \\        for (int i = 1; i < 5; ++i) {
    \\            result += texture(image, TexCoords + vec2(0.0, tex_offset.y * i)).rgb * weight[i];
    \\            result += texture(image, TexCoords - vec2(0.0, tex_offset.y * i)).rgb * weight[i];
    \\        }
    \\    }
    \\    FragColor = vec4(result, 1.0);
    \\}
;

pub const BloomEffect = struct {
    extract_fbo: Framebuffer,
    blur_fbos: [2]Framebuffer,
    extract_shader: gl.GLuint,
    blur_shader: gl.GLuint,
    threshold: f32,
    blur_iterations: u32,

    pub fn init(width: u32, height: u32) !BloomEffect {
        // Downsample for blur efficiency
        const blur_width = width / 2;
        const blur_height = height / 2;

        return BloomEffect{
            .extract_fbo = try Framebuffer.init(width, height, true),
            .blur_fbos = .{
                try Framebuffer.init(blur_width, blur_height, true),
                try Framebuffer.init(blur_width, blur_height, true),
            },
            .extract_shader = 0, // TODO: Compile shader
            .blur_shader = 0,
            .threshold = 1.0,
            .blur_iterations = 5,
        };
    }

    pub fn deinit(self: *BloomEffect) void {
        self.extract_fbo.deinit();
        self.blur_fbos[0].deinit();
        self.blur_fbos[1].deinit();
    }

    pub fn apply(self: *BloomEffect, input_texture: gl.GLuint) gl.GLuint {
        // Extract bright pixels
        self.extract_fbo.bind();
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        // TODO: Render quad with extract shader
        _ = input_texture;

        // Blur ping-pong
        var horizontal = true;
        var first_iteration = true;
        var i: u32 = 0;
        while (i < self.blur_iterations * 2) : (i += 1) {
            const current_fbo = &self.blur_fbos[if (horizontal) @as(usize, 0) else 1];
            current_fbo.bind();

            // TODO: Render quad with blur shader
            _ = first_iteration;

            horizontal = !horizontal;
            first_iteration = false;
        }

        Framebuffer.unbind();
        return self.blur_fbos[1].color_texture;
    }
};

// ============================================================================
// Shadow Mapping
// ============================================================================

pub const ShadowMap = struct {
    fbo: gl.GLuint,
    depth_texture: gl.GLuint,
    resolution: u32,

    pub fn init(resolution: u32) !ShadowMap {
        const fbo = gl.genFramebuffer();
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);

        const depth_texture = gl.genTexture();
        gl.glBindTexture(gl.GL_TEXTURE_2D, depth_texture);
        gl.glTexImage2D(
            gl.GL_TEXTURE_2D,
            0,
            gl.GL_DEPTH_COMPONENT24,
            @intCast(resolution),
            @intCast(resolution),
            0,
            gl.GL_DEPTH_COMPONENT,
            gl.GL_FLOAT,
            null,
        );

        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, @intCast(gl.GL_NEAREST));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, @intCast(gl.GL_NEAREST));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, @intCast(gl.GL_CLAMP_TO_BORDER));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, @intCast(gl.GL_CLAMP_TO_BORDER));

        const border_color = [_]f32{ 1, 1, 1, 1 };
        gl.glTexParameterfv(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_BORDER_COLOR, &border_color);

        gl.glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_DEPTH_ATTACHMENT, gl.GL_TEXTURE_2D, depth_texture, 0);
        gl.glDrawBuffer(gl.GL_NONE);
        gl.glReadBuffer(gl.GL_NONE);

        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, 0);

        return ShadowMap{
            .fbo = fbo,
            .depth_texture = depth_texture,
            .resolution = resolution,
        };
    }

    pub fn deinit(self: *ShadowMap) void {
        gl.deleteFramebuffer(self.fbo);
        gl.deleteTexture(self.depth_texture);
    }

    pub fn bind(self: *const ShadowMap) void {
        gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, self.fbo);
        gl.glViewport(0, 0, @intCast(self.resolution), @intCast(self.resolution));
        gl.glClear(gl.GL_DEPTH_BUFFER_BIT);
    }
};

// ============================================================================
// SSAO (Screen-Space Ambient Occlusion)
// ============================================================================

const ssao_shader =
    \\#version 410 core
    \\in vec2 TexCoords;
    \\out float FragColor;
    \\uniform sampler2D gPosition;
    \\uniform sampler2D gNormal;
    \\uniform sampler2D texNoise;
    \\uniform vec3 samples[64];
    \\uniform mat4 projection;
    \\uniform float radius;
    \\uniform float bias;
    \\const vec2 noiseScale = vec2(1024.0/4.0, 768.0/4.0);
    \\void main() {
    \\    vec3 fragPos = texture(gPosition, TexCoords).xyz;
    \\    vec3 normal = normalize(texture(gNormal, TexCoords).rgb);
    \\    vec3 randomVec = normalize(texture(texNoise, TexCoords * noiseScale).xyz);
    \\    vec3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    \\    vec3 bitangent = cross(normal, tangent);
    \\    mat3 TBN = mat3(tangent, bitangent, normal);
    \\    float occlusion = 0.0;
    \\    for (int i = 0; i < 64; ++i) {
    \\        vec3 samplePos = TBN * samples[i];
    \\        samplePos = fragPos + samplePos * radius;
    \\        vec4 offset = vec4(samplePos, 1.0);
    \\        offset = projection * offset;
    \\        offset.xyz /= offset.w;
    \\        offset.xyz = offset.xyz * 0.5 + 0.5;
    \\        float sampleDepth = texture(gPosition, offset.xy).z;
    \\        float rangeCheck = smoothstep(0.0, 1.0, radius / abs(fragPos.z - sampleDepth));
    \\        occlusion += (sampleDepth >= samplePos.z + bias ? 1.0 : 0.0) * rangeCheck;
    \\    }
    \\    occlusion = 1.0 - (occlusion / 64.0);
    \\    FragColor = occlusion;
    \\}
;

pub const SSAOEffect = struct {
    ssao_fbo: Framebuffer,
    blur_fbo: Framebuffer,
    noise_texture: gl.GLuint,
    shader: gl.GLuint,
    blur_shader: gl.GLuint,
    samples: [64]@Vector(3, f32),
    radius: f32,
    bias: f32,

    pub fn init(width: u32, height: u32) !SSAOEffect {
        var effect = SSAOEffect{
            .ssao_fbo = try Framebuffer.init(width, height, false),
            .blur_fbo = try Framebuffer.init(width, height, false),
            .noise_texture = 0,
            .shader = 0,
            .blur_shader = 0,
            .samples = undefined,
            .radius = 0.5,
            .bias = 0.025,
        };

        // Generate sample kernel
        var rng = std.Random.DefaultPrng.init(0);
        const random = rng.random();

        for (&effect.samples) |*sample| {
            var s = @Vector(3, f32){
                random.float(f32) * 2.0 - 1.0,
                random.float(f32) * 2.0 - 1.0,
                random.float(f32),
            };

            // Normalize
            const len = @sqrt(@reduce(.Add, s * s));
            s = s / @as(@Vector(3, f32), @splat(len));

            // Scale
            var scale = @as(f32, @floatFromInt(std.mem.indexOfScalar(@Vector(3, f32), &effect.samples, s) orelse 0)) / 64.0;
            scale = std.math.lerp(0.1, 1.0, scale * scale);
            s = s * @as(@Vector(3, f32), @splat(scale));

            sample.* = s;
        }

        // Generate noise texture
        effect.noise_texture = try generateNoiseTexture();

        return effect;
    }

    pub fn deinit(self: *SSAOEffect) void {
        self.ssao_fbo.deinit();
        self.blur_fbo.deinit();
        gl.deleteTexture(self.noise_texture);
    }

    pub fn apply(self: *SSAOEffect, position_texture: gl.GLuint, normal_texture: gl.GLuint) gl.GLuint {
        // Generate SSAO texture
        self.ssao_fbo.bind();
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        // TODO: Render quad with SSAO shader
        _ = position_texture;
        _ = normal_texture;

        // Blur SSAO
        self.blur_fbo.bind();
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        // TODO: Render quad with blur shader

        Framebuffer.unbind();
        return self.blur_fbo.color_texture;
    }

    fn generateNoiseTexture() !gl.GLuint {
        var ssaoNoise: [16]@Vector(3, f32) = undefined;
        var rng = std.Random.DefaultPrng.init(0);
        const random = rng.random();

        for (&ssaoNoise) |*noise| {
            noise.* = @Vector(3, f32){
                random.float(f32) * 2.0 - 1.0,
                random.float(f32) * 2.0 - 1.0,
                0.0,
            };
        }

        const texture = gl.genTexture();
        gl.glBindTexture(gl.GL_TEXTURE_2D, texture);
        gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGB8, 4, 4, 0, gl.GL_RGB, gl.GL_FLOAT, @ptrCast(&ssaoNoise));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, @intCast(gl.GL_NEAREST));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, @intCast(gl.GL_NEAREST));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, @intCast(gl.GL_REPEAT));
        gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, @intCast(gl.GL_REPEAT));

        return texture;
    }
};

// ============================================================================
// Post-Processing Pipeline
// ============================================================================

pub const PostProcessPipeline = struct {
    bloom: BloomEffect,
    ssao: SSAOEffect,
    shadow_map: ShadowMap,
    scene_fbo: Framebuffer,
    final_fbo: Framebuffer,

    bloom_enabled: bool,
    ssao_enabled: bool,
    shadows_enabled: bool,

    pub fn init(width: u32, height: u32) !PostProcessPipeline {
        return PostProcessPipeline{
            .bloom = try BloomEffect.init(width, height),
            .ssao = try SSAOEffect.init(width, height),
            .shadow_map = try ShadowMap.init(2048),
            .scene_fbo = try Framebuffer.init(width, height, true),
            .final_fbo = try Framebuffer.init(width, height, false),
            .bloom_enabled = true,
            .ssao_enabled = true,
            .shadows_enabled = true,
        };
    }

    pub fn deinit(self: *PostProcessPipeline) void {
        self.bloom.deinit();
        self.ssao.deinit();
        self.shadow_map.deinit();
        self.scene_fbo.deinit();
        self.final_fbo.deinit();
    }

    pub fn beginScene(self: *PostProcessPipeline) void {
        self.scene_fbo.bind();
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
    }

    pub fn endScene(self: *PostProcessPipeline) gl.GLuint {
        Framebuffer.unbind();

        var current_texture = self.scene_fbo.color_texture;

        // Apply bloom
        if (self.bloom_enabled) {
            const bloom_texture = self.bloom.apply(current_texture);
            // TODO: Combine with current_texture
            _ = bloom_texture;
        }

        // Apply SSAO (would need G-buffer)
        if (self.ssao_enabled) {
            // const ssao_texture = self.ssao.apply(position_tex, normal_tex);
        }

        return current_texture;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Framebuffer creation" {
    // TODO: Requires OpenGL context
}
