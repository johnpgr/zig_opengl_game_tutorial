const std = @import("std");
const util = @import("util.zig");
const builtin = @import("builtin");
const GameState = @import("game-state.zig");
const RenderData = @import("render-data.zig");

const Self = @This();

pub const InitFn = *const fn () callconv(.C) void;
pub const DeinitFn = *const fn () callconv(.C) void;
pub const UpdateFn = *const fn (game_state_in: *GameState, render_data_in: *RenderData) callconv(.C) void;

lib: std.DynLib,
path: []const u8,
last_modified: i128,
init_fn: InitFn,
deinit_fn: DeinitFn,
update_fn: UpdateFn,

pub fn load(allocator: std.mem.Allocator, path: []const u8) !Self {
    var lib: std.DynLib = undefined;

    if (comptime builtin.os.tag == .windows) {
        const lib_path = try std.fmt.allocPrint(
            allocator,
            "./tmp.{s}",
            .{std.fs.path.basename(path)},
        );
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

    return .{
        .path = path,
        .last_modified = util.getLastModified(path) catch 0,
        .lib = lib,
        .init_fn = init_fn,
        .deinit_fn = deinit_fn,
        .update_fn = update_fn,
    };
}
