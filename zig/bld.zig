//! Used with zig compiler by zqjs CLI in runtime

const std = @import("std");

const constants = @import("constants.zig");

const OptLvl = enum {
    O0,
    O1,
    O2,
    O3,
    Os,
    Oz,
};

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
    const zqjsDir = b.option(
        []const u8,
        "zqjs-dir",
        "Path to the directory where 'zqjs' CLI, 'bld.zig' and quickjs soruce code files are located",
    ) orelse {
        @panic("'-zqjs-dir' is required");
    };

    const qjscOutputPath = std.mem.join(
        b.allocator,
        "/",
        &.{ b.tmpPath().src_path.sub_path, "b_c" },
    );

    b.addSystemCommand(&.{std.mem.join(
        b.allocator,
        "/",

        &.{
            zqjsDir,
            constants.ExeDirPaths.qjscExe,
        },
        // Generate only bytecode
        "-c",

        // Strip debug bytecodes
        "-s",

        // Set the bytecode C identifier name
        "-N",
        "b_c",

        // Set the output file
        "-o",
        qjscOutputPath,

        // Input file
        jsRoot,
    )});

    const zigRootLib = b.addLibrary(.{
        .name = "zig-root-lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path(zigRoot),
        }),
        .linkage = .static,
    });

    const flto: []const u8 = if (b.option(
        []const u8,
        "flto",
        "Whether to enable '-flto' for quickjs C source files compilation",
    )) "-flto" else "";

    const optLvl: []const u8 = switch (b.option(
        OptLvl,
        "opt-lvl",
        "Optimization level for quickjs C source files compilation",
    )) {
        .O0, null => "-O0",
        .O1 => "-O1",
        .O2 => "-O2",
        .O3 => "-O3",
        .Os => "-Os",
        .Oz => "-Oz",
    };

    zigRootLib.root_module.addCSourceFiles(.{
        .files = constants.QuickJsFileNames,
        .flags = &.{
            flto, optLvl,
        },
        .language = .c,
    });
}
