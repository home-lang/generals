const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules
    const collections_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "../home/packages/collections/src/lib.zig" },
    });

    const io_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "../home/packages/io/src/lib.zig" },
    });
    io_mod.addImport("collections", collections_mod);

    const math_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "../home/packages/math/src/math.zig" },
    });

    // Main Generals game executable
    const generals = b.addExecutable(.{
        .name = "generals",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    generals.root_module.addImport("io", io_mod);
    generals.root_module.addImport("collections", collections_mod);
    generals.root_module.addImport("math", math_mod);

    // Add platform-specific sources for macOS
    generals.addCSourceFile(.{
        .file = b.path("src/platform/macos_window.m"),
        .flags = &[_][]const u8{},
    });
    generals.addCSourceFile(.{
        .file = b.path("src/platform/macos_renderer.m"),
        .flags = &[_][]const u8{},
    });
    generals.addCSourceFile(.{
        .file = b.path("src/platform/macos_sprite_renderer.m"),
        .flags = &[_][]const u8{},
    });

    // Link macOS frameworks
    generals.linkFramework("Foundation");
    generals.linkFramework("AppKit");
    generals.linkFramework("Metal");
    generals.linkFramework("QuartzCore");
    generals.linkLibC();

    b.installArtifact(generals);

    const run_generals = b.addRunArtifact(generals);
    run_generals.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run Generals");
    run_step.dependOn(&run_generals.step);

    // Test INI parser executable
    const test_ini = b.addExecutable(.{
        .name = "test_ini_parser",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test_ini_parser.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    test_ini.root_module.addImport("io", io_mod);
    test_ini.root_module.addImport("collections", collections_mod);

    b.installArtifact(test_ini);

    const test_step = b.step("test-ini", "Test INI parser");
    const run_test = b.addRunArtifact(test_ini);
    test_step.dependOn(&run_test.step);

    // Test Window executable (macOS only)
    const test_window = b.addExecutable(.{
        .name = "test_window",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test_window.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add Objective-C source files
    test_window.addCSourceFile(.{
        .file = b.path("src/platform/macos_window.m"),
        .flags = &[_][]const u8{},
    });
    test_window.addCSourceFile(.{
        .file = b.path("src/platform/macos_renderer.m"),
        .flags = &[_][]const u8{},
    });

    // Link Objective-C runtime and Metal for macOS
    test_window.linkFramework("Foundation");
    test_window.linkFramework("AppKit");
    test_window.linkFramework("Metal");
    test_window.linkFramework("QuartzCore");
    test_window.linkLibC();

    b.installArtifact(test_window);

    const test_window_step = b.step("test-window", "Test window creation");
    const run_test_window = b.addRunArtifact(test_window);
    test_window_step.dependOn(&run_test_window.step);

    // Test Texture loading executable
    const test_texture = b.addExecutable(.{
        .name = "test_texture",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test_texture.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(test_texture);

    const test_texture_step = b.step("test-texture", "Test TGA texture loading");
    const run_test_texture = b.addRunArtifact(test_texture);
    test_texture_step.dependOn(&run_test_texture.step);

    // Test Sprite rendering executable
    const test_sprite = b.addExecutable(.{
        .name = "test_sprite",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test_sprite.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add platform sources
    test_sprite.addCSourceFile(.{
        .file = b.path("src/platform/macos_window.m"),
        .flags = &[_][]const u8{},
    });
    test_sprite.addCSourceFile(.{
        .file = b.path("src/platform/macos_sprite_renderer.m"),
        .flags = &[_][]const u8{},
    });

    // Link frameworks
    test_sprite.linkFramework("Foundation");
    test_sprite.linkFramework("AppKit");
    test_sprite.linkFramework("Metal");
    test_sprite.linkFramework("QuartzCore");
    test_sprite.linkLibC();

    b.installArtifact(test_sprite);

    const test_sprite_step = b.step("test-sprite", "Test sprite rendering");
    const run_test_sprite = b.addRunArtifact(test_sprite);
    test_sprite_step.dependOn(&run_test_sprite.step);
}
