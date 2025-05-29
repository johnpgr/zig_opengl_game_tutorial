const c = @import("c");
const std = @import("std");
const System = @import("system.zig");
const GameState = @import("game-state.zig");

export fn init(system: *const System) callconv(.C) void {
    // TODO Initialize game here
    _ = system;
    std.debug.print("Game initialized\n", .{});
}

export fn deinit(system: *const System) callconv(.C) void {
    // TODO Deinitialize game here
    _ = system;
    std.debug.print("Game deinitialized\n", .{});
}

export fn update(system: *const System, game_state: *GameState) callconv(.C) void {
    system.renderer.render_data.game_camera.position.x = 0;
    system.renderer.render_data.game_camera.position.y = 0;

    _ = game_state;
}

export fn draw(system: *const System, game_state: *GameState) callconv(.C) void {
    _ = game_state;
    const sprite_size: f32 = 64;

    system.renderer.drawSprite(
        .DICE,
        .{ .x = 0, .y = 0 },
        .{ .x = sprite_size, .y = sprite_size },
    );

    system.renderer.render(system.screen_dimensions.x, system.screen_dimensions.y);
    _ = c.SDL_GL_SwapWindow(system.window);
}
