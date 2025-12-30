// SPDX-License-Identifier: AGPL-3.0-or-later
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "zig-rclone",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link librclone (Go->C shared library)
    lib.linkSystemLibrary("rclone");
    lib.linkLibC();

    b.installArtifact(lib);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Example: list files
    const list_example = b.addExecutable(.{
        .name = "list-example",
        .root_source_file = b.path("examples/list.zig"),
        .target = target,
        .optimize = optimize,
    });
    list_example.root_module.addImport("rclone", &lib.root_module);

    const run_list = b.addRunArtifact(list_example);
    const list_step = b.step("example-list", "Run list example");
    list_step.dependOn(&run_list.step);
}
