# Audio System

**Status**: ✅ Core implementation complete
**Source**: Ported from [Thyme Engine](https://github.com/TheAssemblyArmada/Thyme) (GPL licensed)
**Backend**: OpenAL (cross-platform 3D audio)

## Overview

Complete 3D positional audio system for C&C Generals Zero Hour using OpenAL. Supports sound effects, background music, 3D positioning, and doppler effects.

## Components

### Audio System (`audio_system.home` - 541 lines)

**Core Features:**
- OpenAL device and context management
- 3D positional audio
- Audio buffer management with caching
- Source pooling (32 concurrent sounds)
- WAV file loading and parsing
- Background music streaming
- Volume controls (master, music, SFX)

**Audio Pipeline:**
```
WAV File → AudioBuffer → AudioSource → OpenAL → Speakers
```

## Features

### Sound Effects

**3D Positional Audio:**
- Sounds positioned in 3D space
- Distance attenuation
- Doppler effect for moving objects
- Velocity-based pitch shifting

**2D UI Sounds:**
- Non-positional sounds
- Menu clicks, notifications
- UI feedback

### Music System

**Background Music:**
- Looping music tracks
- Smooth volume control
- Music/SFX separation
- Fade in/out (TODO)

### Resource Management

**Audio Buffer Caching:**
- Load once, play many times
- Automatic deduplication
- WAV file parsing

**Source Pooling:**
- Pre-allocated sources (32)
- Automatic recycling
- No allocation during gameplay

## Usage Examples

### Initialize Audio

```home
import audio.audio_system.AudioSystem

fn main() {
    // Create audio system
    let mut audio = AudioSystem.new()?

    // Load sounds
    audio.load_sound("assets/sounds/tank_fire.wav")?
    audio.load_sound("assets/sounds/explosion.wav")?
    audio.load_sound("assets/sounds/unit_select.wav")?

    // Play background music
    audio.play_music("assets/music/theme.wav")?

    // Set volumes
    audio.set_master_volume(0.8)
    audio.set_music_volume(0.6)
    audio.set_sfx_volume(1.0)
}
```

### Play Sound Effects

```home
// Play 3D sound at position
let tank_pos = Vec3.new(10.0, 0.0, 5.0)
audio.play_sound("tank_fire.wav", tank_pos, 1.0)?

// Play 2D UI sound
audio.play_sound_2d("unit_select.wav", 0.8)?

// Explosion with variation
let explosion_pos = Vec3.new(0.0, 0.0, -15.0)
audio.play_sound("explosion.wav", explosion_pos, 1.2)?
```

### Update Listener (Camera)

```home
// Each frame, update listener from camera
fn update_audio(audio: &mut AudioSystem, camera: &Camera) {
    let position = camera.position()
    let forward = camera.forward()
    let up = camera.up()
    let velocity = camera_velocity

    audio.update_listener(*position, *forward, *up, velocity)

    // Update audio system (recycle finished sources)
    audio.update()
}
```

### Music Control

```home
// Play music
audio.play_music("assets/music/battle_theme.wav")?

// Stop music
audio.stop_music()

// Change music volume
audio.set_music_volume(0.4)
```

## WAV File Format Support

**Supported Formats:**
- Mono 8-bit
- Mono 16-bit
- Stereo 8-bit
- Stereo 16-bit

**Sample Rates:**
- 11025 Hz
- 22050 Hz
- 44100 Hz (recommended)
- 48000 Hz

**File Structure:**
```
RIFF Header (12 bytes)
  - "RIFF" magic
  - File size
  - "WAVE" format

fmt Chunk (24+ bytes)
  - Audio format (PCM)
  - Channels (1 or 2)
  - Sample rate
  - Bits per sample

data Chunk (8 + N bytes)
  - "data" magic
  - Data size
  - Audio samples
```

## Design Principles

### Performance

**Source Pooling:**
- Pre-allocate 32 sources at startup
- Recycle finished sources automatically
- No runtime allocation

**Buffer Caching:**
- Load sound once, reference many times
- HashMap lookup for fast access
- Deduplication prevents duplicate loads

**3D Audio:**
- OpenAL handles spatial calculations
- Hardware-accelerated when available
- Efficient distance attenuation

### Safety

**Resource Management:**
- RAII cleanup of buffers and sources
- Automatic shutdown on drop
- No leaked OpenAL resources

**Error Handling:**
- Result types for all operations
- Graceful degradation (silently fail if no sources)
- Descriptive error messages

## Integration with Game

### Entity Events

```home
// Tank fires weapon
fn on_tank_fire(audio: &mut AudioSystem, tank: &Entity) {
    let pos = tank.transform.position
    audio.play_sound("tank_fire.wav", pos, 1.0)
}

// Explosion damage
fn on_explosion(audio: &mut AudioSystem, position: Vec3) {
    audio.play_sound("explosion.wav", position, 1.5)
}

// Unit death
fn on_unit_death(audio: &mut AudioSystem, unit: &Entity) {
    let pos = unit.transform.position
    audio.play_sound("unit_death.wav", pos, 0.8)
}
```

### Game Loop Integration

```home
struct Game {
    renderer: Renderer,
    audio: AudioSystem,
    entities: EntityManager,
}

impl Game {
    fn update(self: &mut Game, dt: f32) {
        // Update entities
        self.entities.update(dt)

        // Update audio listener from camera
        let camera = self.renderer.camera().camera()
        self.audio.update_listener(
            *camera.position(),
            *camera.forward(),
            *camera.up(),
            Vec3.new(0.0, 0.0, 0.0)  // TODO: camera velocity
        )

        // Update audio system (recycle sources)
        self.audio.update()
    }
}
```

## OpenAL API Reference

### Device & Context

```c
// Open device
ALCdevice* alcOpenDevice(const char* deviceName)

// Create context
ALCcontext* alcCreateContext(ALCdevice* device, const ALCint* attrlist)

// Make context current
ALCboolean alcMakeContextCurrent(ALCcontext* context)
```

### Buffers

```c
// Generate buffers
void alGenBuffers(ALsizei n, ALuint* buffers)

// Upload data
void alBufferData(ALuint buffer, ALenum format, const void* data, ALsizei size, ALsizei freq)

// Delete buffers
void alDeleteBuffers(ALsizei n, const ALuint* buffers)
```

### Sources

```c
// Generate sources
void alGenSources(ALsizei n, ALuint* sources)

// Set source parameters
void alSourcef(ALuint source, ALenum param, ALfloat value)
void alSource3f(ALuint source, ALenum param, ALfloat v1, ALfloat v2, ALfloat v3)
void alSourcei(ALuint source, ALenum param, ALint value)

// Playback control
void alSourcePlay(ALuint source)
void alSourcePause(ALuint source)
void alSourceStop(ALuint source)

// Delete sources
void alDeleteSources(ALsizei n, const ALuint* sources)
```

### Listener

```c
// Set listener position
void alListener3f(ALenum param, ALfloat v1, ALfloat v2, ALfloat v3)

// Set listener orientation
void alListenerfv(ALenum param, const ALfloat* values)

// Set listener gain
void alListenerf(ALenum param, ALfloat value)
```

## Sound Design Guidelines

### Volume Levels

| Sound Type | Volume Range | Example |
|------------|--------------|---------|
| Music | 0.5 - 0.7 | Background themes |
| Ambience | 0.3 - 0.5 | Wind, birds, environment |
| Unit Sounds | 0.6 - 0.8 | Tank movement, engine |
| Weapons | 0.8 - 1.0 | Gun fire, explosions |
| UI | 0.5 - 0.7 | Button clicks, notifications |
| Voice | 0.7 - 0.9 | Unit acknowledgements |

### Distance Attenuation

OpenAL automatically handles distance falloff:
- Close (0-10 units): Full volume
- Medium (10-50 units): Gradual falloff
- Far (50+ units): Minimal volume

### Performance Targets

- **Concurrent Sounds**: 32 max (pooled)
- **Music Streaming**: 1 track
- **CPU Usage**: <1% (OpenAL handles most processing)
- **Memory**: ~50MB for all game sounds

## File Structure

```
src/audio/
├── README.md              # This file
└── audio_system.home      # Complete audio system (541 lines)
```

## Future Enhancements

### Streaming Audio
- [ ] Large music files (>10MB)
- [ ] Buffer streaming for long tracks
- [ ] Compression support (OGG Vorbis)

### Effects
- [ ] Reverb/echo
- [ ] Environmental audio zones
- [ ] Underwater effects
- [ ] Distance-based filtering (muffle distant sounds)

### Advanced Features
- [ ] Audio occlusion (walls block sound)
- [ ] Dynamic music system (combat/exploration)
- [ ] Voice radio filter
- [ ] Positional voice chat (multiplayer)

## Testing

### Audio Test

```home
fn test_audio() {
    let mut audio = AudioSystem.new()?

    // Load test sound
    audio.load_sound("test.wav")?

    // Play at origin
    audio.play_sound("test.wav", Vec3.new(0.0, 0.0, 0.0), 1.0)?

    // Wait for playback
    Time.sleep_seconds(2.0)

    // Cleanup
    audio.shutdown()
}
```

### 3D Audio Test

```home
fn test_3d_audio() {
    let mut audio = AudioSystem.new()?
    audio.load_sound("beep.wav")?

    // Play sounds in a circle around listener
    for i in 0..8 {
        let angle = (i as f32) * (3.14159 * 2.0 / 8.0)
        let pos = Vec3.new(
            10.0 * math.cos(angle),
            0.0,
            10.0 * math.sin(angle)
        )

        audio.play_sound("beep.wav", pos, 1.0)?
        Time.sleep_millis(500)
    }
}
```

## License

This implementation maintains the GPL license philosophy from Thyme Engine.
Written for Home language: November 2024
