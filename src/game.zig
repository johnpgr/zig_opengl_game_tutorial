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
    system.renderer.data.game_camera.position.x = 0;
    system.renderer.data.game_camera.position.y = 0;

    _ = game_state;
}

export fn draw(system: *const System, game_state: *GameState) callconv(.C) void {
    system.renderer.drawSprite(.DICE, game_state.player_pos);
    system.renderer.clearScreen(system.screen_dimensions);
    system.renderer.render();
}
