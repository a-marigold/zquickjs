//! `zqjs` CLI

const std = @import("std");

const HELP_TEXT =
    \\usage: 
    \\  -h              Print help
    \\  -Dzig-root      Path to zig root file. If omitted,
    \\                  the default files are used (which have 'zqjs:std')
    \\  -Dinit-fn-name  Name of function in zit root that initializes modules.
    \\                  Cannot be skiped if '-Dzig-root' is provided
    \\  -Djs-root       Path to '.js' root file (it must not import other '.js' files!)
;

pub fn main(init: std.process.Init) !void {
    const arenaAllocator = init.arena.allocator();

    const stdoutBuffer: []u8 = undefined;
    var stdoutWriter = std.Io.File.stdout().writer(init.io, stdoutBuffer);

    const stdout = &stdoutWriter.interface;

    var args = try init.minimal.args.iterateAllocator(arenaAllocator);
    defer args.deinit();

    while (args.next()) {}

    try stdout.writeAll(HELP_TEXT);
    try stdout.flush();
    std.process.exit(1);

    try stdoutWriter.flush();
}
