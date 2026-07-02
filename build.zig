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

    const translateQjs = b.addTranslateC(.{
        // 'quickjs.h' and 'quickjs-libc.h' are all needs for binding
        // Take only 'quickjs-libc.h' 'cause it includes 'quickjs.h'
        .root_source_file = b.path("quickjs-libc.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    b.getInstallStep().dependOn(&b.addInstallFile(
        translateQjs.getOutput(),
        "qjs.zig",
    ).step);
}
