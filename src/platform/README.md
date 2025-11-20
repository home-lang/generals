# Platform Layer

**Status**: ✅ Core implementation complete
**Source**: Inspired by [Thyme Engine](https://github.com/TheAssemblyArmada/Thyme) (GPL licensed)
**Language**: Home programming language

## Overview

The platform layer provides OS-agnostic abstractions for file I/O, timing, and system operations. This allows the game engine to run on macOS (and potentially other platforms) without platform-specific code in the game logic.

## Components

### File I/O (`file.home`)

Cross-platform file operations abstraction:

- **File Operations**
  - Open, close, read, write
  - Seek and tell (positioning)
  - EOF detection
  - Size queries

- **Convenience Functions**
  - `read_all_bytes()` - Load entire file
  - `read_all_text()` - Load file as string
  - `write_all_bytes()` - Write entire file
  - `write_all_text()` - Write string to file

- **Directory Operations**
  - Check file/directory existence
  - Create directories (recursive)
  - List directory contents
  - Delete files
  - File metadata (size, modified time)

- **File Modes**
  - `Read` - Read-only access
  - `Write` - Write access
  - `Append` - Append to end
  - `Create` - Create if doesn't exist
  - `Truncate` - Clear file on open
  - `Text` - Text mode (line endings)
  - `Binary` - Binary mode

### Timing (`time.home`)

High-resolution timing for game loops:

- **GameTimer**
  - Frame delta time calculation
  - FPS tracking
  - Pause/resume support
  - Accumulated time tracking

- **Time Utilities**
  - Monotonic clock (nanosecond precision)
  - Sleep functions
  - Time unit conversions

- **FrameLimiter**
  - Fixed timestep game loops
  - Target FPS control
  - Prevents spiral of death
  - Smooth frame pacing

- **Stopwatch**
  - Duration measurement
  - Start/stop/reset
  - Running time queries
  - Pause support

## Usage Examples

### File Operations

```home
import platform.file.File

// Read entire file
let data = File.read_all_bytes("assets/texture.tga")?

// Write to file
File.write_all_text("config.ini", "setting=value\n")?

// Buffered file operations
let mut file = File.open("data.bin", FileMode.Read | FileMode.Binary)?
let mut buffer = [0u8; 1024]
let bytes_read = file.read(&mut buffer)?
file.close()

// Directory operations
if File.exists("assets/") {
    let files = File.list_directory("assets/")?
    for filename in files {
        println!("Found: {}", filename)
    }
}

// File metadata
let info = File.metadata("game.exe")?
println!("Size: {} bytes", info.size)
println!("Modified: {}", info.modified_time)
```

### Game Loop Timing

```home
import platform.time.GameTimer
import platform.time.FrameLimiter

// Create timer and limiter
let mut timer = GameTimer.new()
let mut limiter = FrameLimiter.new(60.0)  // 60 FPS target

// Main game loop
loop {
    // Get frame delta
    let dt = timer.delta()  // e.g., 0.016 seconds (60 FPS)

    // Update game logic
    update_game(dt)

    // Render
    render_frame()

    // Limit frame rate
    limiter.wait_for_next_frame()

    // Show FPS
    if timer.frame_count % 60 == 0 {
        println!("FPS: {}", timer.fps())
    }
}
```

### Measuring Performance

```home
import platform.time.Stopwatch

// Create stopwatch
let mut sw = Stopwatch.new()

// Measure operation
sw.start()
expensive_operation()
sw.stop()

println!("Operation took {} ms", sw.elapsed_millis())
println!("Operation took {:.3} seconds", sw.elapsed_seconds())

// Restart for another measurement
sw.restart()
another_operation()
sw.stop()
```

## Design Principles

### Portability

- All OS-specific code isolated to platform layer
- Uses Home's standard library abstractions
- Easy to add new platform implementations

### Performance

- Zero-cost abstractions where possible
- Buffered file I/O support
- High-resolution monotonic clock
- Efficient time conversions

### Safety

- Result types for error handling
- No panics on file not found
- Resource cleanup (RAII pattern)
- Bounds checking on all operations

## Integration with Thyme

While Thyme uses C++ and platform-specific APIs, this platform layer provides equivalent functionality:

| Thyme (C++) | Home Platform Layer |
|-------------|---------------------|
| `File::Open()` | `File.open()` |
| `File::Read()` | `File.read()` |
| `GetPerformanceCounter()` | `Time.now_nanos()` |
| `Sleep()` | `Time.sleep_millis()` |
| Custom timers | `GameTimer` |

## Next Steps

This platform layer enables:
1. **.BIG Archive Reader** - Load game assets from archives
2. **.INI Parser** - Read game configuration files
3. **Resource Loading** - Textures, models, audio
4. **Game Loop** - Fixed timestep updates and rendering

## Implementation Notes

### File I/O

- Uses Home's `std.fs` for cross-platform file operations
- Supports both streaming and bulk read/write
- Handles platform-specific path separators
- UTF-8 string support

### Timing

- Uses monotonic clock (not affected by system time changes)
- Nanosecond precision (microsecond in practice)
- Frame limiter prevents CPU spinning
- Accumulator pattern for fixed timesteps

### Error Handling

- Returns `Result<T, String>` for operations that can fail
- Provides descriptive error messages
- No unwrap/panic in library code
- Graceful fallbacks where possible

## Future Enhancements

Potential additions:
- Memory-mapped file I/O (for large .BIG archives)
- Asynchronous file operations
- File watching (hot reload)
- Threading primitives (if needed)
- CPU core detection
- Memory usage tracking

## License

This implementation maintains the GPL license philosophy from Thyme Engine.
Written for Home language: November 2024
