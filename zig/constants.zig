/// Paths to files (`zqjs` helpers) in the directory where `zqjs.exe` is located.
pub const ExeDirPaths = struct {
    pub const buildFile = "bld.zig";
    pub const qjsBindings = "qjs.zig";
    pub const zqjsStd = "std.zig";
    pub const qjscExe = "qjs.exe";
};

/// Names of files used by 'zqjs' to be compiled to static library.
pub const QuickJsFileNames = [_][]const u8{
    "quickjs.c",
    "quickjs-libc.c",
    "cutils.c",
    "dtoa.c",

    "libregexp.c",
    "libunicode.c",
};

/// Flags to be provided to C compiler for quickjs compilation.
/// They contains both name and value and can be passed to argv without transforming.
pub const QuickJsCFlags = struct {
    /// Only for GNU linux.
    pub const LINUX_GNU_SOURCE = "-D_GNU_SOURCE";

    /// Received from running `cat ./VERSION` in the root of the repo.
    pub const CONFIG_VERSION = "-DCONFIG_VERSION=\"2026-06-04\"";
};
