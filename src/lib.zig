const std = @import("std");
const builtin = @import("builtin");
const Context = @import("context.zig").Context;

pub const InitFn = *const fn (ctx: *const Context) callconv(.C) void;
pub const DeinitFn = *const fn (ctx: *const Context) callconv(.C) void;
pub const UpdateFn = *const fn (ctx: *const Context) callconv(.C) void;
pub const DrawFn = *const fn (ctx: *const Context) callconv(.C) void;

pub const GameLib = struct {
    lib: std.DynLib,
    path: []const u8,
    last_modified: i128,
    init_fn: InitFn,
    deinit_fn: DeinitFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
};

pub fn loadLibrary(allocator: std.mem.Allocator, path: []const u8) !struct {
    lib: std.DynLib,
    init_fn: InitFn,
    deinit_fn: DeinitFn,
    update_fn: UpdateFn,
    draw_fn: DrawFn,
} {
    var lib: std.DynLib = undefined;

    if (comptime builtin.os.tag == .windows) {
        const lib_path = try std.fmt.allocPrint(allocator, "./tmp.{s}", .{std.fs.path.basename(path)});
        defer allocator.free(lib_path);

        // Create temp library files
        std.fs.cwd().deleteFile(lib_path) catch |e| {
            if (e != error.FileNotFound) return e;
        };
        try std.fs.cwd().copyFile(path, std.fs.cwd(), lib_path, .{});

        lib = try std.DynLib.open(lib_path);
    }

    lib = try std.DynLib.open(path);

    const init_fn = lib.lookup(InitFn, "init").?;
    const deinit_fn = lib.lookup(DeinitFn, "deinit").?;
    const update_fn = lib.lookup(UpdateFn, "update").?;
    const draw_fn = lib.lookup(DrawFn, "draw").?;

    return .{
        .lib = lib,
        .init_fn = init_fn,
        .deinit_fn = deinit_fn,
        .update_fn = update_fn,
        .draw_fn = draw_fn,
    };
}
