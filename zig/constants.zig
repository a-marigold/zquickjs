/// Paths to files (helpers) in the directory where 'zqjs' is located.
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

/// `-DCONFIG_VERSION` flag from quickjs Makefile.
///
///
///
///
///
/// Can be given via running 'cat ./VERSION' in the root of repo.
pub const QUICKJS_DCONFIG_VERSION_FLAG = "-DCONFIG_VERSION=\"2026-06-04\"";
