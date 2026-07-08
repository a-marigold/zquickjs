const std = @import("std");

const constants = @import("zig/constants.zig");

const INSTALL_ARTIFACT_OPTIONS: std.Build.Step.InstallArtifact.Options = .{
    .dest_dir = .{ .override = .prefix },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const optimizeC = b.option(
        bool,
        "optimizeC",
        "Whether to apply '-O3' and '-flto' for quickjs C files",
    );

    const installStep = b.getInstallStep();

    const check = b.step("check", "Build on save");
    check.dependOn(
        &(b.addExecutable(.{
            .name = "check-modules",
            .root_module = b.createModule(.{
                .root_source_file = b.path("check.zig"),
                .target = target,
            }),
        }).step),
    );

    const qjscExe = b.addExecutable(.{
        .name = "qjsc",
        .root_module = b.createModule(.{
            .target = target,
            .link_libc = true,
        }),
    });

    const qjscFlags: []const []const u8 =
        if (target.result.os.tag == .linux and target.result.abi == .gnu)
            if (optimizeC == true) &.{
                "-O3",
                "-flto",
                constants.QuickJsCFlags.LINUX_GNU_SOURCE,
                constants.QuickJsCFlags.CONFIG_VERSION,
            } else &.{
                constants.QuickJsCFlags.LINUX_GNU_SOURCE,
                constants.QuickJsCFlags.CONFIG_VERSION,
            }
        else if (optimizeC == true) &.{
            "-O3",
            "-flto",
            constants.QuickJsCFlags.CONFIG_VERSION,
        } else &.{
            constants.QuickJsCFlags.CONFIG_VERSION,
        };

    qjscExe.root_module.addCSourceFiles(.{
        .files = &.{
            "qjsc.c",
            "quickjs.c",
            "cutils.c",
            "quickjs-libc.c",
            "libunicode.c",
            "libregexp.c",
            "dtoa.c",
        },
        .flags = qjscFlags,
        .language = .c,
    });

    installStep.dependOn(
        &b.addInstallArtifact(qjscExe, INSTALL_ARTIFACT_OPTIONS).step,
    );

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
        &b.addInstallArtifact(zqjsExe, INSTALL_ARTIFACT_OPTIONS).step,
    );

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

    installStep.dependOn(&b.addInstallFile(
        b.path("zig/bld.zig"),
        constants.ExeDirPaths.buildFile,
    ).step);

    const installQuickjsFilesStep = b.step("install-quickjs", "Install quickjs source C files to output");

    for (constants.QuickJsFileNames) |name| {
        installQuickjsFilesStep.dependOn(&b.addInstallFile(b.path(name), name).step);
    }
    installStep.dependOn(installQuickjsFilesStep);

    const testStep = b.step("test", "Run 'zqjs' tests");

    const zqjsTest = b.addTest(.{
        .name = "test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/__tests__/zqjs.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const runZqjsTest = b.addRunArtifact(zqjsTest);
    runZqjsTest.step.dependOn(&zqjsTest.step);
    testStep.dependOn(&runZqjsTest.step);
}
