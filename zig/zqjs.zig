//! 'zqjs' CLI

const std = @import("std");

const constants = @import("constants.zig");

const HELP_TEXT =
    \\usage:
    \\ zqjs -flag-example=value
    \\
    \\ -h              Print help.
    \\ -o              Path to dir where to output executables.
    \\ -Dzig-root      Path to zig root file.
    \\                 If omitted, the default root is used (which has 'zqjs:std').
    \\                 Cannot be omitted if '-Dinit-fn-name' is provided.
    \\ -Dinit-fn-name  Name of function in zig root that initializes custom JS modules.
    \\                 Cannot be omitted if '-Dzig-root' is provided.
    \\ -Djs-root       Path to '.js' root file (it must not import other '.js' files).
    \\ -Dtarget        Zig compiler target.
    \\ -Doptimize      Zig compiler optimization (Debug, ReleaseSafe, ReleaseSmall, ReleaseFast).
    \\ -Dflto          Whether to enable '-flto' flag for quickjs C files compilation.
    \\ -Dopt-lvl       Optimization level for quickjs C files compilation.
    \\                 Default to 'O0'.
    \\                 Example: '-Dopt-lvl=O3' or '-Dopt-lvl=Oz'.
;
pub fn main(init: std.process.Init.Minimal) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var threaded = std.Io.Threaded.init(arenaAllocator, .{});
    defer threaded.deinit();

    const io = threaded.io();

    const stdoutBuffer: []u8 = undefined;

    var stdoutWriter = std.Io.File.stdout().writer(io, stdoutBuffer);

    const stdout = &stdoutWriter.interface;

    var args = try init.args.iterateAllocator(arenaAllocator);
    defer args.deinit();

    const exeDirPath = try std.process.executableDirPathAlloc(io, arenaAllocator);

    var zigBuildCmd = std.ArrayList([]const u8).empty;

    _ = args.skip();

    if (args.next()) |firstArg| {
        if (std.mem.eql(u8, @as([]const u8, "-h"), firstArg)) {
            try stdout.writeAll(HELP_TEXT);
            try stdout.flush();

            std.process.exit(0);
        } else {
            try zigBuildCmd.append(arenaAllocator, firstArg);
        }
    } else {
        try stdout.writeAll(HELP_TEXT);
        try stdout.flush();

        std.process.exit(1);
    }

    while (args.next()) |arg| {
        try zigBuildCmd.append(arenaAllocator, arg);
    }

    try zigBuildCmd.appendSlice(
        arenaAllocator,
        &.{
            "zig",        "build",    "--build-file",
            try std.mem.join(
                arenaAllocator,
                "/",
                &.{ exeDirPath, constants.ExeDirPaths.buildFile },
            ),

            "-Dzqjs-dir", exeDirPath,
        },
    );

    var zigBuildProcess = try std.process.spawn(io, .{
        .argv = zigBuildCmd.items,
        .stdout = .inherit,
        .stderr = .inherit,
    });

    defer _ = zigBuildProcess.wait(io) catch {};
}

pub const panic = std.debug.no_panic;
