//! Used with zig compiler by zqjs CLI in runtime

const std = @import("std");

const constants = @import("constants.zig");

pub fn build(b: *std.Build) void {
    const initFnName = b.option(
        []const u8,
        "init-fn-name",
        "Name of modules init function",
    );

    const zigRoot = b.option(
        []const u8,
        "zig-root",

        "Path to root zig file",
    );

    if (initFnName == null and zigRoot) {
        @panic("'-Dinit-fn-name' cannot be omitted whem '-Dzig-root' is provided.");
    } else if (zigRoot == null and initFnName) {
        @panic("'-Dzig-root' cannot be omitted when '-Dinit-fn-name' is provided.");
    }

    const jsRoot = b.option(
        []const u8,
        "js-root",
        "Path to root js file",
    ) orelse {
        @panic("'-Djs-root' is required.");
    };
    const exeDir = b.option(
        []const u8,
        "exe-dir",
        "Path to the directory where 'zqjs' CLI and the 'build.zig' file are located",
    ) orelse {
        @panic("'-Dexe-dir' is required");
    };

    const zigRootLib = b.addLibrary(.{
        .name = "zig-root-lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path(zigRoot),
        }),
        .linkage = .static,
    });

    zigRootLib.root_module.addCSourceFiles();
}
