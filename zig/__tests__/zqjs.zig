const std = @import("std");
const testing = std.testing;

const allocator = testing.allocator;
const io = testing.io;

const ZQJS_EXE_PATH = "zig-out/zqjs.exe";
const SNAPSHOTS_PATH = "zig/__tests__/snapshots/";

/// Checks is the data of `snapshotPath` file equal to `actual`
///
/// If there is not file in `snapshotPath`, writes `actual` to there.
fn expectMatchSnapshot(
    snapshotPath: []const u8,
    actual: []const u8,
) !void {
    const cwd = std.Io.Dir.cwd();

    const expected = cwd.readFileAlloc(
        io,
        snapshotPath,
        allocator,
        .unlimited,
    ) catch |err| {
        switch (err) {
            error.FileNotFound => {
                try cwd.writeFile(io, .{
                    .sub_path = snapshotPath,

                    .data = actual,
                });

                return;
            },
            else => return err,
        }
    };
    defer allocator.free(expected);

    try testing.expectEqualStrings(expected, actual);
}

/// Checks `expected.stdoutSnapshotPath` and `expected.stderrSnapshotPath` via `expectMatchSnapshot`.
fn expectChildProcess(
    expected: struct { stdoutSnapshotPath: ?[]const u8 = null, stderrSnapshotPath: ?[]const u8 = null, exitCode: ?u8 = null },
    actual: std.process.RunResult,
) !void {
    if (expected.stdoutSnapshotPath) |snapshotPath| {
        try expectMatchSnapshot(snapshotPath, actual.stdout);
    }

    if (expected.stderrSnapshotPath) |snapshotPath| {
        try expectMatchSnapshot(snapshotPath, actual.stderr);
    }

    if (expected.exitCode) |exitCode| {
        try testing.expectEqual(exitCode, actual.term.exited);
    }
}

/// `argv` must omit path to `zqjs` binary 'cause it is included in the function.
fn runZqjs(comptime n: usize, argv: [n][]const u8) !std.process.RunResult {
    return std.process.run(
        allocator,
        io,
        .{
            .argv = &(.{@as([]const u8, ZQJS_EXE_PATH)} ++ argv),
        },
    );
}

test "Help printing to 'stderr' and exiting with code '1' when 'argv' length is 1" {
    const actual = try runZqjs(0, .{});
    defer {
        allocator.free(actual.stdout);
        allocator.free(actual.stderr);
    }

    try expectChildProcess(
        .{
            .stderrSnapshotPath = SNAPSHOTS_PATH ++ "help_text_err",

            .exitCode = 1,
        },

        actual,
    );

    try testing.expectEqualStrings("", actual.stdout);
}
