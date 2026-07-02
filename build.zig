const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zqjsExe = b.addExecutable(.{
        .name = "zqjs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/zqjs.zig"),
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
        }),
    });
    b.installArtifact(zqjsExe);

    const zqjsCheck = b.addExecutable(.{
        .name = "zqjsCheck",
        .root_module = zqjsExe.root_module,
    });
    b.step("check", "Build on save").dependOn(&zqjsCheck.step);
}
