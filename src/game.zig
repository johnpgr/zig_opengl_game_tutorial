const c = @import("c");
const std = @import("std");
const Context = @import("context.zig").Context;

export fn init(ctx: *Context) callconv(.C) void {
    // TODO Initialize game here
    _ = ctx;
    std.debug.print("Game initialized\n", .{});
}

export fn deinit(ctx: *Context) callconv(.C) void {
    // TODO Deinitialize game here
    _ = ctx;
    std.debug.print("Game deinitialized\n", .{});
}

export fn update(ctx: *Context) callconv(.C) void {
    // TODO: Update the game here
    _ = ctx;
}

export fn draw(ctx: *Context) callconv(.C) void {
    const cols: u32 = 16;
    const gap: f32 = 10.0;
    const sprite_size: f32 = 64.0;

    for (0..128) |i| {
        const row = @divFloor(@as(u32, @intCast(i)), cols);
        const col = @mod(@as(u32, @intCast(i)), cols);

        ctx.renderer.drawSprite(
            .DICE,
            .{
                .x = gap + @as(f32, @floatFromInt(col)) * (sprite_size + gap),
                .y = gap + @as(f32, @floatFromInt(row)) * (sprite_size + gap),
            },
            .{ .x = sprite_size, .y = sprite_size },
        );
    }

    ctx.renderer.render(ctx.screen_w, ctx.screen_h);
    _ = c.SDL_GL_SwapWindow(ctx.window);
}
