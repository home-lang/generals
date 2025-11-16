# C&C Generals Zero Hour - Home Language Port

A complete reimplementation of Command & Conquer: Generals Zero Hour in the [Home programming language](https://github.com/stacksjs/home).

## About

This project ports the EA/Westwood RTS game engine from C++ to Home, leveraging modern language features for safety, performance, and maintainability.

**Original Source:** TheSuperHackers/GeneralsGameCode (4,385 C++ source files)
**Target:** Home language with modern architecture

## Features

- **Memory Safe:** Leverages Home's ownership system
- **Cross-Platform:** Windows, macOS, Linux support
- **Modern Graphics:** DirectX 12, Vulkan, Metal backends
- **Deterministic Netcode:** Lockstep multiplayer
- **Modding Support:** Full INI and asset modding

## Project Status

🚧 **In Active Development** - Phase 1: Foundation & Core Systems

See [TODO.md](./TODO.md) for the complete roadmap.

## Building

```bash
# Clone the repository
git clone https://github.com/yourusername/generals.git
cd generals

# Build with Home
home build

# Run
./zig-out/bin/generals
```

## License

GPL-3.0 License - Same as original Generals source code

EA has not endorsed and does not support this product. All trademarks are the property of their respective owners.

## Contributing

Contributions welcome! See [TODO.md](./TODO.md) for current tasks.

---

*Powered by the Home Programming Language*
