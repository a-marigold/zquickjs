/// Paths to files (helpers) in the directory where 'zqjs' is located
pub const ExeDirPaths = struct {
    pub const buildFile = "bld.zig";
    pub const qjsBindings = "qjs.zig";
    pub const zqjsStd = "std.zig";
    pub const qjscExe = "qjs.exe";
};

/// Names of files used by 'zqjs' for compilation to static library
pub const QuickJsFileNames = [_][]const u8{
    "quickjs.c",
    "quickjs-libc.c",
    "cutils.c",
    "dtoa.c",

    "libregexp.c",
    "libunicode.c",
};
