// C&C Generals - Audio Engine
// Music playback and 3D sound positioning system

const std = @import("std");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn distance(self: Vec3, other: Vec3) f32 {
        const dx = self.x - other.x;
        const dy = self.y - other.y;
        const dz = self.z - other.z;
        return @sqrt(dx * dx + dy * dy + dz * dz);
    }
};

/// Audio format types
pub const AudioFormat = enum {
    WAV,
    MP3,
    OGG,
    FLAC,
};

/// Audio channel configuration
pub const AudioChannels = enum {
    Mono,
    Stereo,
    Surround_5_1,
    Surround_7_1,
};

/// Audio sample rate
pub const SampleRate = enum(u32) {
    Hz_22050 = 22050,
    Hz_44100 = 44100,
    Hz_48000 = 48000,
    Hz_96000 = 96000,
};

/// Audio buffer
pub const AudioBuffer = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    data: []u8,
    sample_rate: SampleRate,
    channels: AudioChannels,
    format: AudioFormat,
    duration: f32,

    pub fn init(
        allocator: std.mem.Allocator,
        name: []const u8,
        sample_rate: SampleRate,
        channels: AudioChannels,
    ) !AudioBuffer {
        const data = try allocator.alloc(u8, 1024); // Placeholder size

        return AudioBuffer{
            .allocator = allocator,
            .name = name,
            .data = data,
            .sample_rate = sample_rate,
            .channels = channels,
            .format = .WAV,
            .duration = 1.0,
        };
    }

    pub fn deinit(self: *AudioBuffer) void {
        self.allocator.free(self.data);
    }
};

/// Sound source in 3D space
pub const SoundSource = struct {
    id: u32,
    buffer: *AudioBuffer,
    position: Vec3,
    velocity: Vec3,
    volume: f32,
    pitch: f32,
    min_distance: f32,
    max_distance: f32,
    is_playing: bool,
    is_looping: bool,
    is_3d: bool,
    playback_time: f32,

    pub fn init(id: u32, buffer: *AudioBuffer, position: Vec3) SoundSource {
        return SoundSource{
            .id = id,
            .buffer = buffer,
            .position = position,
            .velocity = Vec3.init(0, 0, 0),
            .volume = 1.0,
            .pitch = 1.0,
            .min_distance = 10.0,
            .max_distance = 500.0,
            .is_playing = false,
            .is_looping = false,
            .is_3d = true,
            .playback_time = 0.0,
        };
    }

    pub fn play(self: *SoundSource) void {
        self.is_playing = true;
        self.playback_time = 0.0;
    }

    pub fn pause(self: *SoundSource) void {
        self.is_playing = false;
    }

    pub fn stop(self: *SoundSource) void {
        self.is_playing = false;
        self.playback_time = 0.0;
    }

    pub fn update(self: *SoundSource, delta_time: f32) void {
        if (!self.is_playing) return;

        self.playback_time += delta_time;

        if (self.playback_time >= self.buffer.duration) {
            if (self.is_looping) {
                self.playback_time = 0.0;
            } else {
                self.stop();
            }
        }
    }

    pub fn calculateVolume(self: *SoundSource, listener_pos: Vec3) f32 {
        if (!self.is_3d) return self.volume;

        const distance = self.position.distance(listener_pos);

        if (distance <= self.min_distance) {
            return self.volume;
        } else if (distance >= self.max_distance) {
            return 0.0;
        }

        // Linear falloff
        const falloff = 1.0 - (distance - self.min_distance) / (self.max_distance - self.min_distance);
        return self.volume * falloff;
    }
};

/// Music track
pub const MusicTrack = struct {
    buffer: *AudioBuffer,
    volume: f32,
    is_playing: bool,
    playback_time: f32,

    pub fn init(buffer: *AudioBuffer) MusicTrack {
        return MusicTrack{
            .buffer = buffer,
            .volume = 1.0,
            .is_playing = false,
            .playback_time = 0.0,
        };
    }

    pub fn play(self: *MusicTrack) void {
        self.is_playing = true;
        self.playback_time = 0.0;
    }

    pub fn pause(self: *MusicTrack) void {
        self.is_playing = false;
    }

    pub fn stop(self: *MusicTrack) void {
        self.is_playing = false;
        self.playback_time = 0.0;
    }

    pub fn update(self: *MusicTrack, delta_time: f32) void {
        if (!self.is_playing) return;

        self.playback_time += delta_time;

        if (self.playback_time >= self.buffer.duration) {
            self.playback_time = 0.0; // Loop music
        }
    }
};

/// Audio listener (camera)
pub const AudioListener = struct {
    position: Vec3,
    velocity: Vec3,
    forward: Vec3,
    up: Vec3,

    pub fn init(position: Vec3) AudioListener {
        return AudioListener{
            .position = position,
            .velocity = Vec3.init(0, 0, 0),
            .forward = Vec3.init(0, 0, -1),
            .up = Vec3.init(0, 1, 0),
        };
    }

    pub fn setPosition(self: *AudioListener, position: Vec3) void {
        self.position = position;
    }

    pub fn setOrientation(self: *AudioListener, forward: Vec3, up: Vec3) void {
        self.forward = forward;
        self.up = up;
    }
};

/// Audio engine manager
pub const AudioEngine = struct {
    allocator: std.mem.Allocator,
    buffers: []AudioBuffer,
    buffer_count: usize,
    sound_sources: []SoundSource,
    source_count: usize,
    music_tracks: []MusicTrack,
    music_track_count: usize,
    current_music: ?*MusicTrack,
    listener: AudioListener,
    master_volume: f32,
    music_volume: f32,
    sfx_volume: f32,
    next_source_id: u32,

    pub fn init(allocator: std.mem.Allocator) !AudioEngine {
        const buffers = try allocator.alloc(AudioBuffer, 500);
        const sound_sources = try allocator.alloc(SoundSource, 128);
        const music_tracks = try allocator.alloc(MusicTrack, 32);

        return AudioEngine{
            .allocator = allocator,
            .buffers = buffers,
            .buffer_count = 0,
            .sound_sources = sound_sources,
            .source_count = 0,
            .music_tracks = music_tracks,
            .music_track_count = 0,
            .current_music = null,
            .listener = AudioListener.init(Vec3.init(0, 0, 0)),
            .master_volume = 1.0,
            .music_volume = 0.7,
            .sfx_volume = 1.0,
            .next_source_id = 1,
        };
    }

    pub fn deinit(self: *AudioEngine) void {
        for (self.buffers[0..self.buffer_count]) |*buffer| {
            buffer.deinit();
        }
        self.allocator.free(self.buffers);
        self.allocator.free(self.sound_sources);
        self.allocator.free(self.music_tracks);
    }

    /// Load audio buffer from file
    pub fn loadBuffer(self: *AudioEngine, file_path: []const u8) !*AudioBuffer {
        // Check if already loaded
        for (self.buffers[0..self.buffer_count]) |*buffer| {
            if (std.mem.eql(u8, buffer.name, file_path)) {
                return buffer;
            }
        }

        if (self.buffer_count >= self.buffers.len) return error.TooManyBuffers;

        // Stub: would load actual audio file
        var buffer = try AudioBuffer.init(self.allocator, file_path, .Hz_44100, .Stereo);
        buffer.duration = 2.0; // 2 seconds

        self.buffers[self.buffer_count] = buffer;
        const result = &self.buffers[self.buffer_count];
        self.buffer_count += 1;

        return result;
    }

    /// Play sound at 3D position
    pub fn playSound3D(self: *AudioEngine, buffer_name: []const u8, position: Vec3) !u32 {
        const buffer = try self.loadBuffer(buffer_name);

        if (self.source_count >= self.sound_sources.len) return error.TooManySources;

        const id = self.next_source_id;
        self.next_source_id += 1;

        var source = SoundSource.init(id, buffer, position);
        source.is_3d = true;
        source.play();

        self.sound_sources[self.source_count] = source;
        self.source_count += 1;

        return id;
    }

    /// Play 2D sound (UI, etc)
    pub fn playSound2D(self: *AudioEngine, buffer_name: []const u8) !u32 {
        const buffer = try self.loadBuffer(buffer_name);

        if (self.source_count >= self.sound_sources.len) return error.TooManySources;

        const id = self.next_source_id;
        self.next_source_id += 1;

        var source = SoundSource.init(id, buffer, Vec3.init(0, 0, 0));
        source.is_3d = false;
        source.play();

        self.sound_sources[self.source_count] = source;
        self.source_count += 1;

        return id;
    }

    /// Play music track
    pub fn playMusic(self: *AudioEngine, file_path: []const u8) !void {
        const buffer = try self.loadBuffer(file_path);

        // Stop current music if playing
        if (self.current_music) |music| {
            music.stop();
        }

        if (self.music_track_count >= self.music_tracks.len) return error.TooManyTracks;

        var track = MusicTrack.init(buffer);
        track.volume = self.music_volume;
        track.play();

        self.music_tracks[self.music_track_count] = track;
        self.current_music = &self.music_tracks[self.music_track_count];
        self.music_track_count += 1;
    }

    /// Stop music
    pub fn stopMusic(self: *AudioEngine) void {
        if (self.current_music) |music| {
            music.stop();
            self.current_music = null;
        }
    }

    /// Update audio engine
    pub fn update(self: *AudioEngine, delta_time: f32) void {
        // Update sound sources
        var i: usize = 0;
        while (i < self.source_count) {
            var source = &self.sound_sources[i];
            source.update(delta_time);

            // Remove completed sources
            if (!source.is_playing) {
                if (i < self.source_count - 1) {
                    self.sound_sources[i] = self.sound_sources[self.source_count - 1];
                }
                self.source_count -= 1;
                continue;
            }

            // Calculate 3D volume
            if (source.is_3d) {
                const volume = source.calculateVolume(self.listener.position);
                _ = volume; // Would apply to audio backend
            }

            i += 1;
        }

        // Update music
        if (self.current_music) |music| {
            music.update(delta_time);
        }
    }

    /// Set listener (camera) position
    pub fn setListenerPosition(self: *AudioEngine, position: Vec3) void {
        self.listener.setPosition(position);
    }

    /// Set listener orientation
    pub fn setListenerOrientation(self: *AudioEngine, forward: Vec3, up: Vec3) void {
        self.listener.setOrientation(forward, up);
    }

    /// Get audio statistics
    pub fn getStats(self: *AudioEngine) AudioStats {
        var active_sources: usize = 0;
        for (self.sound_sources[0..self.source_count]) |source| {
            if (source.is_playing) active_sources += 1;
        }

        return AudioStats{
            .loaded_buffers = self.buffer_count,
            .active_sources = active_sources,
            .total_sources = self.source_count,
            .music_playing = self.current_music != null,
        };
    }
};

pub const AudioStats = struct {
    loaded_buffers: usize,
    active_sources: usize,
    total_sources: usize,
    music_playing: bool,
};

// Tests
test "Audio buffer creation" {
    const allocator = std.testing.allocator;

    var buffer = try AudioBuffer.init(allocator, "test.wav", .Hz_44100, .Stereo);
    defer buffer.deinit();

    try std.testing.expect(buffer.sample_rate == .Hz_44100);
    try std.testing.expect(buffer.channels == .Stereo);
}

test "Sound source" {
    const allocator = std.testing.allocator;

    var buffer = try AudioBuffer.init(allocator, "test.wav", .Hz_44100, .Stereo);
    defer buffer.deinit();

    var source = SoundSource.init(1, &buffer, Vec3.init(0, 0, 0));
    source.play();

    try std.testing.expect(source.is_playing == true);

    source.update(0.1);
    try std.testing.expect(source.playback_time > 0);
}

test "Audio engine" {
    const allocator = std.testing.allocator;

    var engine = try AudioEngine.init(allocator);
    defer engine.deinit();

    const sound_id = try engine.playSound3D("sounds/explosion.wav", Vec3.init(100, 0, 100));
    try std.testing.expect(sound_id > 0);

    engine.update(0.1);

    const stats = engine.getStats();
    try std.testing.expect(stats.active_sources > 0);
}
