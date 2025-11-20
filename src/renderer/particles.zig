// Home Programming Language - Particle Effects System
// High-performance particle system for explosions, smoke, fire, etc.
//
// Features:
// - Object pooling for zero-allocation runtime
// - Billboard rendering with GPU instancing
// - Multiple emitter types (point, sphere, cone)
// - Particle physics (velocity, acceleration, drag)
// - Color/size animation over lifetime
// - Texture atlas support

const std = @import("std");
const gl = @import("opengl.zig");

// ============================================================================
// Particle Types
// ============================================================================

pub const ParticleType = enum {
    Smoke,
    Fire,
    Explosion,
    Spark,
    Debris,
    Dust,
    Blood,
    Water,
    Snow,
    Magic,
};

pub const EmitterShape = enum {
    Point,      // Emit from single point
    Sphere,     // Emit from sphere surface
    Cone,       // Emit in cone direction
    Box,        // Emit from box volume
    Circle,     // Emit from circle
};

pub const BlendMode = enum {
    Alpha,      // Standard alpha blending
    Additive,   // Additive blending (for fire/explosions)
    Multiply,   // Multiplicative blending (for smoke)
};

// ============================================================================
// Particle Structure
// ============================================================================

pub const Particle = struct {
    position: @Vector(3, f32),
    velocity: @Vector(3, f32),
    acceleration: @Vector(3, f32),
    color: @Vector(4, f32),
    start_color: @Vector(4, f32),
    end_color: @Vector(4, f32),
    size: f32,
    start_size: f32,
    end_size: f32,
    rotation: f32,
    angular_velocity: f32,
    lifetime: f32,
    age: f32,
    active: bool,
    texture_index: u32,

    pub fn init() Particle {
        return Particle{
            .position = @Vector(3, f32){ 0, 0, 0 },
            .velocity = @Vector(3, f32){ 0, 0, 0 },
            .acceleration = @Vector(3, f32){ 0, -9.8, 0 }, // Gravity
            .color = @Vector(4, f32){ 1, 1, 1, 1 },
            .start_color = @Vector(4, f32){ 1, 1, 1, 1 },
            .end_color = @Vector(4, f32){ 1, 1, 1, 0 },
            .size = 1.0,
            .start_size = 1.0,
            .end_size = 0.1,
            .rotation = 0,
            .angular_velocity = 0,
            .lifetime = 1.0,
            .age = 0,
            .active = false,
            .texture_index = 0,
        };
    }

    pub fn update(self: *Particle, dt: f32) void {
        if (!self.active) return;

        self.age += dt;

        // Kill particle if expired
        if (self.age >= self.lifetime) {
            self.active = false;
            return;
        }

        // Update physics
        self.velocity += self.acceleration * @as(@Vector(3, f32), @splat(dt));
        self.position += self.velocity * @as(@Vector(3, f32), @splat(dt));
        self.rotation += self.angular_velocity * dt;

        // Interpolate color and size over lifetime
        const t = self.age / self.lifetime;
        self.color = lerp4(self.start_color, self.end_color, t);
        self.size = std.math.lerp(self.start_size, self.end_size, t);
    }

    fn lerp4(a: @Vector(4, f32), b: @Vector(4, f32), t: f32) @Vector(4, f32) {
        const t_vec: @Vector(4, f32) = @splat(t);
        return a + (b - a) * t_vec;
    }
};

// ============================================================================
// Emitter Configuration
// ============================================================================

pub const EmitterConfig = struct {
    particle_type: ParticleType,
    shape: EmitterShape,
    blend_mode: BlendMode,

    // Emission properties
    emission_rate: f32,          // Particles per second
    burst_count: u32,            // Particles per burst (0 = continuous)
    max_particles: u32,          // Maximum active particles

    // Particle lifetime
    lifetime_min: f32,
    lifetime_max: f32,

    // Initial velocity
    velocity_min: @Vector(3, f32),
    velocity_max: @Vector(3, f32),

    // Size
    start_size_min: f32,
    start_size_max: f32,
    end_size_min: f32,
    end_size_max: f32,

    // Color
    start_color: @Vector(4, f32),
    end_color: @Vector(4, f32),

    // Physics
    gravity: @Vector(3, f32),
    drag: f32,

    // Rotation
    angular_velocity_min: f32,
    angular_velocity_max: f32,

    // Emitter shape parameters
    radius: f32,                 // For sphere/circle
    cone_angle: f32,            // For cone (radians)
    box_extents: @Vector(3, f32), // For box

    // Texture
    texture_atlas_rows: u32,
    texture_atlas_cols: u32,
    animate_texture: bool,

    pub fn default() EmitterConfig {
        return EmitterConfig{
            .particle_type = .Smoke,
            .shape = .Point,
            .blend_mode = .Alpha,
            .emission_rate = 10.0,
            .burst_count = 0,
            .max_particles = 1000,
            .lifetime_min = 1.0,
            .lifetime_max = 2.0,
            .velocity_min = @Vector(3, f32){ -1, 0, -1 },
            .velocity_max = @Vector(3, f32){ 1, 2, 1 },
            .start_size_min = 0.5,
            .start_size_max = 1.0,
            .end_size_min = 0.1,
            .end_size_max = 0.2,
            .start_color = @Vector(4, f32){ 1, 1, 1, 1 },
            .end_color = @Vector(4, f32){ 0.5, 0.5, 0.5, 0 },
            .gravity = @Vector(3, f32){ 0, -9.8, 0 },
            .drag = 0.1,
            .angular_velocity_min = -1.0,
            .angular_velocity_max = 1.0,
            .radius = 1.0,
            .cone_angle = std.math.pi / 4.0,
            .box_extents = @Vector(3, f32){ 1, 1, 1 },
            .texture_atlas_rows = 1,
            .texture_atlas_cols = 1,
            .animate_texture = false,
        };
    }

    // Preset configurations
    pub fn explosion() EmitterConfig {
        var config = default();
        config.particle_type = .Explosion;
        config.blend_mode = .Additive;
        config.burst_count = 50;
        config.lifetime_min = 0.5;
        config.lifetime_max = 1.0;
        config.velocity_min = @Vector(3, f32){ -5, -5, -5 };
        config.velocity_max = @Vector(3, f32){ 5, 5, 5 };
        config.start_color = @Vector(4, f32){ 1, 0.8, 0.3, 1 };
        config.end_color = @Vector(4, f32){ 0.5, 0.1, 0.0, 0 };
        config.start_size_min = 1.0;
        config.start_size_max = 2.0;
        config.end_size_min = 3.0;
        config.end_size_max = 5.0;
        return config;
    }

    pub fn fire() EmitterConfig {
        var config = default();
        config.particle_type = .Fire;
        config.blend_mode = .Additive;
        config.emission_rate = 50.0;
        config.lifetime_min = 0.5;
        config.lifetime_max = 1.0;
        config.velocity_min = @Vector(3, f32){ -0.5, 2, -0.5 };
        config.velocity_max = @Vector(3, f32){ 0.5, 4, 0.5 };
        config.start_color = @Vector(4, f32){ 1, 0.5, 0.1, 1 };
        config.end_color = @Vector(4, f32){ 0.3, 0.1, 0.0, 0 };
        config.gravity = @Vector(3, f32){ 0, 1, 0 }; // Rises up
        return config;
    }

    pub fn smoke() EmitterConfig {
        var config = default();
        config.particle_type = .Smoke;
        config.blend_mode = .Alpha;
        config.emission_rate = 20.0;
        config.lifetime_min = 2.0;
        config.lifetime_max = 4.0;
        config.velocity_min = @Vector(3, f32){ -0.5, 1, -0.5 };
        config.velocity_max = @Vector(3, f32){ 0.5, 2, 0.5 };
        config.start_color = @Vector(4, f32){ 0.3, 0.3, 0.3, 0.8 };
        config.end_color = @Vector(4, f32){ 0.5, 0.5, 0.5, 0 };
        config.start_size_min = 1.0;
        config.start_size_max = 1.5;
        config.end_size_min = 3.0;
        config.end_size_max = 5.0;
        return config;
    }
};

// ============================================================================
// Particle Emitter
// ============================================================================

pub const ParticleEmitter = struct {
    config: EmitterConfig,
    particles: []Particle,
    position: @Vector(3, f32),
    direction: @Vector(3, f32),
    active: bool,
    emission_accumulator: f32,
    rng: std.Random.DefaultPrng,

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, config: EmitterConfig) !ParticleEmitter {
        const particles = try allocator.alloc(Particle, config.max_particles);
        for (particles) |*p| {
            p.* = Particle.init();
        }

        return ParticleEmitter{
            .config = config,
            .particles = particles,
            .position = @Vector(3, f32){ 0, 0, 0 },
            .direction = @Vector(3, f32){ 0, 1, 0 },
            .active = true,
            .emission_accumulator = 0,
            .rng = std.Random.DefaultPrng.init(0),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ParticleEmitter) void {
        self.allocator.free(self.particles);
    }

    pub fn setPosition(self: *ParticleEmitter, pos: @Vector(3, f32)) void {
        self.position = pos;
    }

    pub fn setDirection(self: *ParticleEmitter, dir: @Vector(3, f32)) void {
        self.direction = normalize(dir);
    }

    pub fn emit(self: *ParticleEmitter, count: u32) void {
        var emitted: u32 = 0;
        for (self.particles) |*particle| {
            if (emitted >= count) break;
            if (particle.active) continue;

            self.spawnParticle(particle);
            emitted += 1;
        }
    }

    pub fn burst(self: *ParticleEmitter) void {
        if (self.config.burst_count > 0) {
            self.emit(self.config.burst_count);
        }
    }

    pub fn update(self: *ParticleEmitter, dt: f32) void {
        if (!self.active) return;

        // Continuous emission
        if (self.config.burst_count == 0) {
            self.emission_accumulator += self.config.emission_rate * dt;
            const to_emit = @as(u32, @intFromFloat(self.emission_accumulator));
            if (to_emit > 0) {
                self.emit(to_emit);
                self.emission_accumulator -= @as(f32, @floatFromInt(to_emit));
            }
        }

        // Update all active particles
        for (self.particles) |*particle| {
            particle.update(dt);
        }
    }

    fn spawnParticle(self: *ParticleEmitter, particle: *Particle) void {
        const random = self.rng.random();

        // Initialize particle
        particle.active = true;
        particle.age = 0;

        // Position based on emitter shape
        particle.position = self.position + self.getShapeOffset(random);

        // Velocity
        particle.velocity = self.getRandomVelocity(random);

        // Lifetime
        particle.lifetime = random.float(f32) * (self.config.lifetime_max - self.config.lifetime_min) + self.config.lifetime_min;

        // Size
        particle.start_size = random.float(f32) * (self.config.start_size_max - self.config.start_size_min) + self.config.start_size_min;
        particle.end_size = random.float(f32) * (self.config.end_size_max - self.config.end_size_min) + self.config.end_size_min;
        particle.size = particle.start_size;

        // Color
        particle.start_color = self.config.start_color;
        particle.end_color = self.config.end_color;
        particle.color = particle.start_color;

        // Rotation
        particle.angular_velocity = random.float(f32) * (self.config.angular_velocity_max - self.config.angular_velocity_min) + self.config.angular_velocity_min;
        particle.rotation = random.float(f32) * std.math.tau;

        // Physics
        particle.acceleration = self.config.gravity;

        // Texture
        if (self.config.animate_texture) {
            particle.texture_index = random.intRangeAtMost(u32, 0, self.config.texture_atlas_rows * self.config.texture_atlas_cols - 1);
        } else {
            particle.texture_index = 0;
        }
    }

    fn getShapeOffset(self: *ParticleEmitter, random: std.Random) @Vector(3, f32) {
        return switch (self.config.shape) {
            .Point => @Vector(3, f32){ 0, 0, 0 },
            .Sphere => randomPointOnSphere(random, self.config.radius),
            .Circle => randomPointOnCircle(random, self.config.radius),
            .Cone => randomPointInCone(random, self.direction, self.config.cone_angle, self.config.radius),
            .Box => randomPointInBox(random, self.config.box_extents),
        };
    }

    fn getRandomVelocity(self: *ParticleEmitter, random: std.Random) @Vector(3, f32) {
        const t = @Vector(3, f32){
            random.float(f32),
            random.float(f32),
            random.float(f32),
        };
        return self.config.velocity_min + (self.config.velocity_max - self.config.velocity_min) * t;
    }

    pub fn getActiveCount(self: *const ParticleEmitter) u32 {
        var count: u32 = 0;
        for (self.particles) |particle| {
            if (particle.active) count += 1;
        }
        return count;
    }
};

// ============================================================================
// Particle System Manager
// ============================================================================

pub const ParticleSystem = struct {
    emitters: std.ArrayList(ParticleEmitter),
    allocator: std.mem.Allocator,

    // Rendering
    vao: gl.GLuint,
    vbo: gl.GLuint,
    shader_program: gl.GLuint,
    texture: gl.GLuint,

    pub fn init(allocator: std.mem.Allocator) ParticleSystem {
        return ParticleSystem{
            .emitters = std.ArrayList(ParticleEmitter).init(allocator),
            .allocator = allocator,
            .vao = 0,
            .vbo = 0,
            .shader_program = 0,
            .texture = 0,
        };
    }

    pub fn deinit(self: *ParticleSystem) void {
        for (self.emitters.items) |*emitter| {
            emitter.deinit();
        }
        self.emitters.deinit();

        if (self.vao != 0) gl.deleteVertexArray(self.vao);
        if (self.vbo != 0) gl.deleteBuffer(self.vbo);
        if (self.shader_program != 0) gl.glDeleteProgram(self.shader_program);
        if (self.texture != 0) gl.deleteTexture(self.texture);
    }

    pub fn addEmitter(self: *ParticleSystem, config: EmitterConfig) !*ParticleEmitter {
        const emitter = try ParticleEmitter.init(self.allocator, config);
        try self.emitters.append(emitter);
        return &self.emitters.items[self.emitters.items.len - 1];
    }

    pub fn update(self: *ParticleSystem, dt: f32) void {
        for (self.emitters.items) |*emitter| {
            emitter.update(dt);
        }
    }

    pub fn render(self: *ParticleSystem, view_matrix: [16]f32, projection_matrix: [16]f32) void {
        _ = view_matrix;
        _ = projection_matrix;

        // TODO: Implement instanced billboard rendering
        // For each active particle, render a camera-facing quad
        // Use GPU instancing for performance
    }
};

// ============================================================================
// Helper Functions
// ============================================================================

fn normalize(v: @Vector(3, f32)) @Vector(3, f32) {
    const len = @sqrt(@reduce(.Add, v * v));
    return if (len > 0) v / @as(@Vector(3, f32), @splat(len)) else v;
}

fn randomPointOnSphere(random: std.Random, radius: f32) @Vector(3, f32) {
    const theta = random.float(f32) * std.math.tau;
    const phi = std.math.acos(2.0 * random.float(f32) - 1.0);

    const sin_phi = @sin(phi);
    return @Vector(3, f32){
        radius * sin_phi * @cos(theta),
        radius * sin_phi * @sin(theta),
        radius * @cos(phi),
    };
}

fn randomPointOnCircle(random: std.Random, radius: f32) @Vector(3, f32) {
    const theta = random.float(f32) * std.math.tau;
    return @Vector(3, f32){
        radius * @cos(theta),
        0,
        radius * @sin(theta),
    };
}

fn randomPointInBox(random: std.Random, extents: @Vector(3, f32)) @Vector(3, f32) {
    return @Vector(3, f32){
        (random.float(f32) * 2.0 - 1.0) * extents[0],
        (random.float(f32) * 2.0 - 1.0) * extents[1],
        (random.float(f32) * 2.0 - 1.0) * extents[2],
    };
}

fn randomPointInCone(random: std.Random, direction: @Vector(3, f32), angle: f32, length: f32) @Vector(3, f32) {
    const theta = random.float(f32) * std.math.tau;
    const phi = random.float(f32) * angle;

    const sin_phi = @sin(phi);
    const offset = @Vector(3, f32){
        length * sin_phi * @cos(theta),
        length * @cos(phi),
        length * sin_phi * @sin(theta),
    };

    // Rotate offset to align with direction
    // Simplified: assumes direction is normalized
    return offset + direction * @as(@Vector(3, f32), @splat(length));
}

// ============================================================================
// Tests
// ============================================================================

test "Particle initialization" {
    const testing = std.testing;
    const particle = Particle.init();
    try testing.expect(!particle.active);
    try testing.expectEqual(@as(f32, 1.0), particle.lifetime);
}

test "Particle update" {
    const testing = std.testing;
    var particle = Particle.init();
    particle.active = true;
    particle.lifetime = 1.0;
    particle.velocity = @Vector(3, f32){ 1, 0, 0 };

    particle.update(0.5);
    try testing.expect(particle.active);
    try testing.expectEqual(@as(f32, 0.5), particle.age);
}

test "EmitterConfig presets" {
    const testing = std.testing;
    const explosion = EmitterConfig.explosion();
    try testing.expectEqual(ParticleType.Explosion, explosion.particle_type);
    try testing.expectEqual(@as(u32, 50), explosion.burst_count);
}
