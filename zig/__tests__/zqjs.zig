const std = @import("std");
const testing = std.testing;

const allocator = testing.allocator;
const io = testing.io;

const ZQJS_EXE_PATH = "../../zig-out/zqjs.exe";

/// Checks is the data of `snapshotPath` file equal to `actual`
///
/// If there is not file in `snapshotPath`, writes `actual` to there.
fn expectMatchSnapshot(
    snapshotPath: []const u8,
    actual: []const u8,
) !void {
    const cwd = std.Io.Dir.cwd();

    const expected = try (cwd.readFileAlloc(
        io,
        snapshotPath,
        allocator,
        .unlimited,
    ) catch |err| {
        switch (err) {
            .FileNotFound => {
                cwd.writeFile(io, .{
                    .sub_path = snapshotPath,

                    .data = actual,
                });

                return;
            },
            else => return err,
        }
    });

    try testing.expectEqualStrings(expected, actual);
}

/// Checks do `expected.stdoutSnapshotPath` and `expected.stderrSnapshotPath` equal to
/// `actual.stdout` and `actual.stderr` via `expectMatchSnapshot`.
fn expectChildProcess(
    expected: struct { stdoutSnapshotPath: ?[]const u8, stderrSnapshotPath: ?[]const u8, exitCode: ?u8 },
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
