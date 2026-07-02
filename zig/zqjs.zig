//! 'zqjs' CLI

const std = @import("std");

const constants = @import("constants.zig");

const HELP_TEXT =
    \\usage: 
    \\ -h              Print help.
    \\ -Dzig-root      Path to zig root file. 
    \\                 If omitted, the default root is used (which has 'zqjs:std').
    \\                 Cannot be omitted if '-Dinit-fn-name' is provided.
    \\ -Dinit-fn-name  Name of function in zig root that initializes modules.
    \\                 Cannot be omitted if '-Dzig-root' is provided.
    \\ -Djs-root       Path to '.js' root file (it must not import other '.js' files).
    \\ -Dtarget        Zig compiler target.
    \\ -Doptimize      Zig compiler optimization (Debug, ReleaseSafe, ReleaseSmall, ReleaseFast).
    \\ -p              Prefix of path where to store 'bin' folder with executables.
    \\                 (e.g for '-p ./dist' executables are stored to './dist/bin').
;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const arenaAllocator = init.arena.allocator();

    const stdoutBuffer: []u8 = undefined;

    var stdoutWriter = std.Io.File.stdout().writer(io, stdoutBuffer);

    const stdout = &stdoutWriter.interface;

    var args = try init.minimal.args.iterateAllocator(arenaAllocator);
    defer args.deinit();

    const exeDirPath = try std.process.executableDirPathAlloc(io, arenaAllocator);

    var zigBuildCmd = std.ArrayList([]const u8).empty;
    while (args.next()) |arg| {
        try zigBuildCmd.append(arenaAllocator, arg);
    }

    if (zigBuildCmd.items.len == 1) {
        try stdout.writeAll(HELP_TEXT);
        try stdout.flush();
        std.process.exit(1);
    }

    try zigBuildCmd.appendSlice(
        arenaAllocator,
        &.{
            "zig",       "build",    "--build-file",
            try std.mem.join(
                arenaAllocator,
                "/",
                &.{ exeDirPath, constants.exeDirPaths.buildFile },
            ),

            "-Dexe-dir", exeDirPath,
        },
    );

    var zigBuildProcess = try std.process.spawn(io, .{
        .argv = zigBuildCmd.items,
        .stdout = .inherit,
        .stderr = .inherit,
    });

    defer _ = zigBuildProcess.wait(io) catch {};
}
