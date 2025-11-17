// C&C Generals - Video Playback System
// Support for campaign cinematics and cutscenes

const std = @import("std");

/// Video format types
pub const VideoFormat = enum {
    BIK,  // Bink Video (used in original C&C Generals)
    MP4,  // H.264 MP4
    AVI,  // Audio Video Interleave
    WebM, // WebM format

    pub fn fromExtension(ext: []const u8) VideoFormat {
        if (std.mem.eql(u8, ext, ".bik")) return .BIK;
        if (std.mem.eql(u8, ext, ".mp4")) return .MP4;
        if (std.mem.eql(u8, ext, ".avi")) return .AVI;
        if (std.mem.eql(u8, ext, ".webm")) return .WebM;
        return .MP4; // Default
    }
};

/// Video playback state
pub const PlaybackState = enum {
    Stopped,
    Playing,
    Paused,
    Finished,
};

/// Video stream information
pub const VideoStream = struct {
    width: u32,
    height: u32,
    fps: f32,
    duration_seconds: f32,
    total_frames: u32,
    codec: []const u8,
};

/// Audio stream information
pub const AudioStream = struct {
    sample_rate: u32,
    channels: u8,
    codec: []const u8,
};

/// Video file
pub const VideoFile = struct {
    allocator: std.mem.Allocator,
    file_path: []const u8,
    format: VideoFormat,
    video_stream: VideoStream,
    audio_stream: ?AudioStream,
    current_frame: u32,
    current_time: f32,
    playback_state: PlaybackState,
    loop: bool,
    volume: f32,

    pub fn init(allocator: std.mem.Allocator, file_path: []const u8) !VideoFile {
        // Detect format from extension
        const ext_start = std.mem.lastIndexOf(u8, file_path, ".") orelse return error.InvalidFile;
        const ext = file_path[ext_start..];
        const format = VideoFormat.fromExtension(ext);

        // In full implementation: parse video file headers
        // For now, use placeholder values
        const video_stream = VideoStream{
            .width = 1920,
            .height = 1080,
            .fps = 30.0,
            .duration_seconds = 120.0,
            .total_frames = 3600,
            .codec = "H.264",
        };

        const audio_stream = AudioStream{
            .sample_rate = 44100,
            .channels = 2,
            .codec = "AAC",
        };

        return VideoFile{
            .allocator = allocator,
            .file_path = file_path,
            .format = format,
            .video_stream = video_stream,
            .audio_stream = audio_stream,
            .current_frame = 0,
            .current_time = 0.0,
            .playback_state = .Stopped,
            .loop = false,
            .volume = 1.0,
        };
    }

    pub fn deinit(self: *VideoFile) void {
        _ = self;
        // In full implementation: cleanup video decoder resources
    }

    /// Start playback
    pub fn play(self: *VideoFile) void {
        self.playback_state = .Playing;
    }

    /// Pause playback
    pub fn pause(self: *VideoFile) void {
        self.playback_state = .Paused;
    }

    /// Stop playback and reset
    pub fn stop(self: *VideoFile) void {
        self.playback_state = .Stopped;
        self.current_frame = 0;
        self.current_time = 0.0;
    }

    /// Seek to specific time
    pub fn seek(self: *VideoFile, time_seconds: f32) void {
        self.current_time = @min(time_seconds, self.video_stream.duration_seconds);
        self.current_frame = @as(u32, @intFromFloat(self.current_time * self.video_stream.fps));
    }

    /// Update video playback
    pub fn update(self: *VideoFile, delta_time: f32) void {
        if (self.playback_state != .Playing) return;

        self.current_time += delta_time;
        self.current_frame = @as(u32, @intFromFloat(self.current_time * self.video_stream.fps));

        // Check if finished
        if (self.current_time >= self.video_stream.duration_seconds) {
            if (self.loop) {
                self.current_time = 0.0;
                self.current_frame = 0;
            } else {
                self.playback_state = .Finished;
            }
        }
    }

    /// Get current frame texture (would return GPU texture in full implementation)
    pub fn getCurrentFrame(self: *VideoFile) ?u32 {
        if (self.playback_state != .Playing) return null;
        return self.current_frame;
    }

    /// Set playback volume
    pub fn setVolume(self: *VideoFile, volume: f32) void {
        self.volume = @max(0.0, @min(1.0, volume));
    }
};

/// Video player manager
pub const VideoPlayer = struct {
    allocator: std.mem.Allocator,
    videos: []VideoFile,
    video_count: usize,
    current_video: ?*VideoFile,
    subtitle_enabled: bool,
    fullscreen: bool,

    pub fn init(allocator: std.mem.Allocator) !VideoPlayer {
        const videos = try allocator.alloc(VideoFile, 100);

        return VideoPlayer{
            .allocator = allocator,
            .videos = videos,
            .video_count = 0,
            .current_video = null,
            .subtitle_enabled = true,
            .fullscreen = true,
        };
    }

    pub fn deinit(self: *VideoPlayer) void {
        for (self.videos[0..self.video_count]) |*video| {
            video.deinit();
        }
        self.allocator.free(self.videos);
    }

    /// Load video file
    pub fn loadVideo(self: *VideoPlayer, file_path: []const u8) !*VideoFile {
        if (self.video_count >= self.videos.len) return error.TooManyVideos;

        self.videos[self.video_count] = try VideoFile.init(self.allocator, file_path);
        const video = &self.videos[self.video_count];
        self.video_count += 1;

        std.debug.print("Video loaded: {s} ({}x{} @ {}fps)\n", .{
            file_path,
            video.video_stream.width,
            video.video_stream.height,
            video.video_stream.fps,
        });

        return video;
    }

    /// Play video file
    pub fn playVideo(self: *VideoPlayer, file_path: []const u8, loop: bool) !void {
        const video = try self.loadVideo(file_path);
        video.loop = loop;
        video.play();
        self.current_video = video;

        std.debug.print("Playing video: {s}\n", .{file_path});
    }

    /// Stop current video
    pub fn stopVideo(self: *VideoPlayer) void {
        if (self.current_video) |video| {
            video.stop();
            self.current_video = null;
        }
    }

    /// Update current video
    pub fn update(self: *VideoPlayer, delta_time: f32) void {
        if (self.current_video) |video| {
            video.update(delta_time);

            // Auto-stop when finished
            if (video.playback_state == .Finished and !video.loop) {
                self.current_video = null;
            }
        }
    }

    /// Skip current video
    pub fn skipVideo(self: *VideoPlayer) void {
        self.stopVideo();
    }

    /// Get playback statistics
    pub fn getStats(self: *VideoPlayer) VideoStats {
        const is_playing = self.current_video != null and self.current_video.?.playback_state == .Playing;
        const current_time = if (self.current_video) |v| v.current_time else 0.0;
        const duration = if (self.current_video) |v| v.video_stream.duration_seconds else 0.0;

        return VideoStats{
            .loaded_videos = self.video_count,
            .is_playing = is_playing,
            .current_time = current_time,
            .duration = duration,
            .subtitle_enabled = self.subtitle_enabled,
        };
    }
};

pub const VideoStats = struct {
    loaded_videos: usize,
    is_playing: bool,
    current_time: f32,
    duration: f32,
    subtitle_enabled: bool,
};

/// Campaign cinematic manager
pub const CinematicManager = struct {
    allocator: std.mem.Allocator,
    video_player: VideoPlayer,
    cinematics_path: []const u8,

    pub fn init(allocator: std.mem.Allocator, cinematics_path: []const u8) !CinematicManager {
        return CinematicManager{
            .allocator = allocator,
            .video_player = try VideoPlayer.init(allocator),
            .cinematics_path = cinematics_path,
        };
    }

    pub fn deinit(self: *CinematicManager) void {
        self.video_player.deinit();
    }

    /// Play campaign intro
    pub fn playCampaignIntro(self: *CinematicManager, faction: []const u8) !void {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/{s}_intro.bik",
            .{ self.cinematics_path, faction },
        );
        defer self.allocator.free(filename);

        try self.video_player.playVideo(filename, false);
    }

    /// Play mission briefing
    pub fn playMissionBriefing(self: *CinematicManager, faction: []const u8, mission: u32) !void {
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/{s}_mission{}_briefing.bik",
            .{ self.cinematics_path, faction, mission },
        );
        defer self.allocator.free(filename);

        try self.video_player.playVideo(filename, false);
    }

    /// Play mission ending
    pub fn playMissionEnding(self: *CinematicManager, faction: []const u8, mission: u32, victory: bool) !void {
        const result = if (victory) "victory" else "defeat";
        const filename = try std.fmt.allocPrint(
            self.allocator,
            "{s}/{s}_mission{}_{s}.bik",
            .{ self.cinematics_path, faction, mission, result },
        );
        defer self.allocator.free(filename);

        try self.video_player.playVideo(filename, false);
    }

    /// Update video player
    pub fn update(self: *CinematicManager, delta_time: f32) void {
        self.video_player.update(delta_time);
    }

    /// Skip current cinematic
    pub fn skip(self: *CinematicManager) void {
        self.video_player.skipVideo();
    }
};

// Tests
test "Video file loading" {
    const allocator = std.testing.allocator;

    var video = try VideoFile.init(allocator, "videos/intro.mp4");
    defer video.deinit();

    try std.testing.expect(video.format == .MP4);
    try std.testing.expect(video.video_stream.width == 1920);
    try std.testing.expect(video.playback_state == .Stopped);
}

test "Video playback" {
    const allocator = std.testing.allocator;

    var video = try VideoFile.init(allocator, "videos/intro.mp4");
    defer video.deinit();

    video.play();
    try std.testing.expect(video.playback_state == .Playing);

    video.update(1.0);
    try std.testing.expect(video.current_time > 0.0);
    try std.testing.expect(video.current_frame > 0);
}

test "Video player manager" {
    const allocator = std.testing.allocator;

    var player = try VideoPlayer.init(allocator);
    defer player.deinit();

    try player.playVideo("videos/usa_intro.bik", false);

    const stats = player.getStats();
    try std.testing.expect(stats.is_playing == true);
    try std.testing.expect(stats.loaded_videos == 1);
}

test "Cinematic manager" {
    const allocator = std.testing.allocator;

    var manager = try CinematicManager.init(allocator, "data/videos");
    defer manager.deinit();

    try manager.playCampaignIntro("USA");
    manager.update(0.1);

    const stats = manager.video_player.getStats();
    try std.testing.expect(stats.is_playing == true);
}
