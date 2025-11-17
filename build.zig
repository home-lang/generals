// C&C Generals Zero Hour - Build System
// Zig 0.15.1 compatible build file

const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create Home stdlib modules
    const math3d_module = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "/Users/chrisbreuer/Code/home/packages/basics/src/math/math3d.zig" },
        .target = target,
        .optimize = optimize,
    });

    const pool_module = b.createModule(.{
        .root_source_file = .{ .cwd_relative = "/Users/chrisbreuer/Code/home/packages/basics/src/memory/pool.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Create root module
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add stdlib module imports
    root_module.addImport("math3d", math3d_module);
    root_module.addImport("pool", pool_module);

    // Create executable
    const exe = b.addExecutable(.{
        .name = "Generals",
        .root_module = root_module,
    });

    // Link libc
    exe.linkLibC();

    // Install executable
    b.installArtifact(exe);

    // Create run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
