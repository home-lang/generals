// Generals Game Engine - Particle System
// Metal-compatible particle effects for explosions, smoke, fire, etc.

const std = @import("std");
const Allocator = std.mem.Allocator;

// Vector math helper
pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn scale(v: Vec2, s: f32) Vec2 {
        return .{ .x = v.x * s, .y = v.y * s };
    }

    pub fn length(v: Vec2) f32 {
        return @sqrt(v.x * v.x + v.y * v.y);
    }
};

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn scale(v: Vec3, s: f32) Vec3 {
        return .{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
    }
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn lerp(start: Color, end: Color, t: f32) Color {
        return .{
            .r = start.r + (end.r - start.r) * t,
            .g = start.g + (end.g - start.g) * t,
            .b = start.b + (end.b - start.b) * t,
            .a = start.a + (end.a - start.a) * t,
        };
    }
};

/// Particle type for visual categorization
pub const ParticleType = enum {
    Smoke,
    Fire,
    Explosion,
    Spark,
    Debris,
    Dust,
    Blood,
};

/// Individual particle
pub const Particle = struct {
    position: Vec2,
    velocity: Vec2,
    acceleration: Vec2,
    color: Color,
    start_color: Color,
    end_color: Color,
    size: f32,
    start_size: f32,
    end_size: f32,
    rotation: f32,
    angular_velocity: f32,
    lifetime: f32,
    age: f32,
    active: bool,
    particle_type: ParticleType,

    pub fn init() Particle {
        return .{
            .position = Vec2.init(0, 0),
            .velocity = Vec2.init(0, 0),
            .acceleration = Vec2.init(0, 100.0), // Gravity (downward in screen space)
            .color = Color.init(1, 1, 1, 1),
            .start_color = Color.init(1, 1, 1, 1),
            .end_color = Color.init(1, 1, 1, 0),
            .size = 10.0,
            .start_size = 10.0,
            .end_size = 2.0,
            .rotation = 0,
            .angular_velocity = 0,
            .lifetime = 1.0,
            .age = 0,
            .active = false,
            .particle_type = .Smoke,
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
        self.velocity = Vec2.add(self.velocity, Vec2.scale(self.acceleration, dt));
        self.position = Vec2.add(self.position, Vec2.scale(self.velocity, dt));
        self.rotation += self.angular_velocity * dt;

        // Interpolate color and size over lifetime
        const t = self.age / self.lifetime;
        self.color = Color.lerp(self.start_color, self.end_color, t);
        self.size = self.start_size + (self.end_size - self.start_size) * t;
    }
};

/// Particle emitter configuration
pub const EmitterConfig = struct {
    position: Vec2,
    particle_type: ParticleType,
    spawn_rate: f32, // Particles per second
    initial_velocity_min: Vec2,
    initial_velocity_max: Vec2,
    lifetime_min: f32,
    lifetime_max: f32,
    start_size_min: f32,
    start_size_max: f32,
    end_size_min: f32,
    end_size_max: f32,
    start_color: Color,
    end_color: Color,
    angular_velocity_min: f32,
    angular_velocity_max: f32,
    gravity: f32,
    duration: f32, // How long emitter lasts (0 = infinite)
    burst_count: u32, // Spawn this many particles immediately

    // Preset configurations
    pub fn explosion(pos: Vec2) EmitterConfig {
        return .{
            .position = pos,
            .particle_type = .Explosion,
            .spawn_rate = 0, // Burst only
            .initial_velocity_min = Vec2.init(-200, -200),
            .initial_velocity_max = Vec2.init(200, -100),
            .lifetime_min = 0.5,
            .lifetime_max = 1.2,
            .start_size_min = 20,
            .start_size_max = 35,
            .end_size_min = 5,
            .end_size_max = 10,
            .start_color = Color.init(1.0, 0.8, 0.2, 1.0), // Bright yellow-orange
            .end_color = Color.init(0.3, 0.1, 0.0, 0.0), // Dark red, fades out
            .angular_velocity_min = -3.0,
            .angular_velocity_max = 3.0,
            .gravity = 50.0,
            .duration = 0.1,
            .burst_count = 30,
        };
    }

    pub fn smoke(pos: Vec2) EmitterConfig {
        return .{
            .position = pos,
            .particle_type = .Smoke,
            .spawn_rate = 20.0,
            .initial_velocity_min = Vec2.init(-20, -50),
            .initial_velocity_max = Vec2.init(20, -30),
            .lifetime_min = 1.5,
            .lifetime_max = 2.5,
            .start_size_min = 10,
            .start_size_max = 15,
            .end_size_min = 25,
            .end_size_max = 35,
            .start_color = Color.init(0.5, 0.5, 0.5, 0.8), // Gray
            .end_color = Color.init(0.3, 0.3, 0.3, 0.0), // Darker gray, fades out
            .angular_velocity_min = -1.0,
            .angular_velocity_max = 1.0,
            .gravity = -10.0, // Slight upward drift
            .duration = 2.0,
            .burst_count = 0,
        };
    }

    pub fn fire(pos: Vec2) EmitterConfig {
        return .{
            .position = pos,
            .particle_type = .Fire,
            .spawn_rate = 50.0,
            .initial_velocity_min = Vec2.init(-30, -80),
            .initial_velocity_max = Vec2.init(30, -50),
            .lifetime_min = 0.3,
            .lifetime_max = 0.8,
            .start_size_min = 8,
            .start_size_max = 12,
            .end_size_min = 2,
            .end_size_max = 4,
            .start_color = Color.init(1.0, 0.6, 0.1, 1.0), // Bright orange
            .end_color = Color.init(0.8, 0.0, 0.0, 0.0), // Red, fades out
            .angular_velocity_min = -2.0,
            .angular_velocity_max = 2.0,
            .gravity = -20.0, // Upward
            .duration = 0.0, // Infinite until stopped
            .burst_count = 5,
        };
    }

    pub fn sparks(pos: Vec2) EmitterConfig {
        return .{
            .position = pos,
            .particle_type = .Spark,
            .spawn_rate = 0,
            .initial_velocity_min = Vec2.init(-150, -200),
            .initial_velocity_max = Vec2.init(150, -50),
            .lifetime_min = 0.3,
            .lifetime_max = 0.7,
            .start_size_min = 2,
            .start_size_max = 4,
            .end_size_min = 1,
            .end_size_max = 2,
            .start_color = Color.init(1.0, 1.0, 0.5, 1.0), // Bright yellow
            .end_color = Color.init(1.0, 0.3, 0.0, 0.0), // Orange, fades out
            .angular_velocity_min = 0,
            .angular_velocity_max = 0,
            .gravity = 200.0,
            .duration = 0.1,
            .burst_count = 20,
        };
    }
};

/// Particle emitter
pub const Emitter = struct {
    config: EmitterConfig,
    active: bool,
    age: f32,
    spawn_accumulator: f32,

    pub fn init(config: EmitterConfig) Emitter {
        return .{
            .config = config,
            .active = true,
            .age = 0,
            .spawn_accumulator = 0,
        };
    }

    pub fn update(self: *Emitter, dt: f32) void {
        if (!self.active) return;

        self.age += dt;

        // Check if emitter should die
        if (self.config.duration > 0 and self.age >= self.config.duration) {
            self.active = false;
            return;
        }

        // Accumulate spawn time
        if (self.config.spawn_rate > 0) {
            self.spawn_accumulator += dt;
        }
    }

    pub fn shouldSpawn(self: *Emitter) bool {
        if (!self.active) return false;
        if (self.config.spawn_rate == 0) return false;

        const spawn_interval = 1.0 / self.config.spawn_rate;
        return self.spawn_accumulator >= spawn_interval;
    }

    pub fn consumeSpawn(self: *Emitter) void {
        const spawn_interval = 1.0 / self.config.spawn_rate;
        self.spawn_accumulator -= spawn_interval;
    }
};

const EmitterList = std.ArrayList(Emitter);

/// Particle system with object pooling
pub const ParticleSystem = struct {
    allocator: Allocator,
    particles: []Particle,
    emitters: EmitterList,
    max_particles: usize,
    random: std.Random,

    pub fn init(allocator: Allocator, max_particles: usize) !ParticleSystem {
        const particles = try allocator.alloc(Particle, max_particles);
        @memset(particles, Particle.init());

        // Use address of particles array as seed (unique per instance)
        var prng = std.Random.DefaultPrng.init(@intFromPtr(particles.ptr));

        return .{
            .allocator = allocator,
            .particles = particles,
            .emitters = EmitterList.empty,
            .max_particles = max_particles,
            .random = prng.random(),
        };
    }

    pub fn deinit(self: *ParticleSystem) void {
        self.allocator.free(self.particles);
        self.emitters.deinit(self.allocator);
    }

    /// Add emitter and spawn burst particles
    pub fn addEmitter(self: *ParticleSystem, config: EmitterConfig) !void {
        const emitter = Emitter.init(config);
        try self.emitters.append(self.allocator, emitter);

        // Spawn burst particles immediately
        for (0..config.burst_count) |_| {
            self.spawnParticle(&config);
        }
    }

    /// Spawn a particle from a config
    fn spawnParticle(self: *ParticleSystem, config: *const EmitterConfig) void {
        // Find inactive particle
        for (self.particles) |*particle| {
            if (!particle.active) {
                particle.active = true;
                particle.position = config.position;
                particle.age = 0;
                particle.particle_type = config.particle_type;

                // Random velocity
                particle.velocity = Vec2.init(
                    self.randomRange(config.initial_velocity_min.x, config.initial_velocity_max.x),
                    self.randomRange(config.initial_velocity_min.y, config.initial_velocity_max.y),
                );

                // Random lifetime
                particle.lifetime = self.randomRange(config.lifetime_min, config.lifetime_max);

                // Random size
                particle.start_size = self.randomRange(config.start_size_min, config.start_size_max);
                particle.end_size = self.randomRange(config.end_size_min, config.end_size_max);
                particle.size = particle.start_size;

                // Colors
                particle.start_color = config.start_color;
                particle.end_color = config.end_color;
                particle.color = config.start_color;

                // Random angular velocity
                particle.angular_velocity = self.randomRange(config.angular_velocity_min, config.angular_velocity_max);

                // Gravity
                particle.acceleration = Vec2.init(0, config.gravity);

                return;
            }
        }
        // All particles are active - drop this one
    }

    fn randomRange(self: *ParticleSystem, min: f32, max: f32) f32 {
        return min + self.random.float(f32) * (max - min);
    }

    /// Update all particles and emitters
    pub fn update(self: *ParticleSystem, dt: f32) void {
        // Update all particles
        for (self.particles) |*particle| {
            particle.update(dt);
        }

        // Update emitters and spawn particles
        var i: usize = 0;
        while (i < self.emitters.items.len) {
            var emitter = &self.emitters.items[i];
            emitter.update(dt);

            // Spawn particles from continuous emitters
            while (emitter.shouldSpawn()) {
                self.spawnParticle(&emitter.config);
                emitter.consumeSpawn();
            }

            // Remove dead emitters
            if (!emitter.active) {
                _ = self.emitters.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    /// Get all active particles for rendering
    pub fn getActiveParticles(self: *ParticleSystem) []const Particle {
        return self.particles;
    }

    /// Get count of active particles (for debugging)
    pub fn getActiveCount(self: *ParticleSystem) usize {
        var count: usize = 0;
        for (self.particles) |particle| {
            if (particle.active) count += 1;
        }
        return count;
    }

    /// Clear all particles and emitters
    pub fn clear(self: *ParticleSystem) void {
        for (self.particles) |*particle| {
            particle.active = false;
        }
        self.emitters.clearRetainingCapacity(self.allocator);
    }
};

// ============================================================================
// Convenience Functions
// ============================================================================

/// Spawn explosion effect at position
pub fn spawnExplosion(system: *ParticleSystem, x: f32, y: f32) !void {
    try system.addEmitter(EmitterConfig.explosion(Vec2.init(x, y)));
    // Add sparks too
    try system.addEmitter(EmitterConfig.sparks(Vec2.init(x, y)));
}

/// Spawn smoke effect at position
pub fn spawnSmoke(system: *ParticleSystem, x: f32, y: f32) !void {
    try system.addEmitter(EmitterConfig.smoke(Vec2.init(x, y)));
}

/// Spawn fire effect at position
pub fn spawnFire(system: *ParticleSystem, x: f32, y: f32) !void {
    try system.addEmitter(EmitterConfig.fire(Vec2.init(x, y)));
}
