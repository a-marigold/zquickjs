const std = @import("std");

const constants = @import("zig/constants.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const installStep = b.getInstallStep();

    const zqjsExe = b.addExecutable(.{
        .name = "zqjs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/zqjs.zig"),
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
            .unwind_tables = .none,
        }),
    });
    installStep.dependOn(
        &b.addInstallArtifact(zqjsExe, .{ .dest_dir = .{ .override = .prefix } }).step,
    );

    const zqjsCheck = b.addExecutable(.{
        .name = "zqjsCheck",
        .root_module = zqjsExe.root_module,
    });

    b.step("check", "Build on save").dependOn(&zqjsCheck.step);

    const translateQuickjs = b.addTranslateC(.{
        // 'quickjs.h' and 'quickjs-libc.h' are all needs for binding,
        // So take only 'quickjs-libc.h' 'cause it includes 'quickjs.h'
        .root_source_file = b.path("quickjs-libc.h"),
        .target = target,
        .optimize = optimize,

        .link_libc = true,
    });

    installStep.dependOn(&b.addInstallFile(
        translateQuickjs.getOutput(),

        "qjs.zig",
    ).step);

    const installQuickjsFiles = b.step("install-quickjs", "Install quickjs source C files to output");

    for (constants.QuickJsFileNames) |name| {
        installQuickjsFiles.dependOn(&b.addInstallFile(b.path(name), name).step);
    }

    installStep.dependOn(installQuickjsFiles);
}
