const c = @import("c");
const std = @import("std");
const System = @import("system.zig");
const GameState = @import("game-state.zig");

export fn init(system: *System) callconv(.C) void {
    // TODO Initialize game here
    _ = system;
    std.debug.print("Game initialized\n", .{});
}

export fn deinit(system: *System) callconv(.C) void {
    // TODO Deinitialize game here
    _ = system;
    std.debug.print("Game deinitialized\n", .{});
}

export fn update(system: *System, game_state: *GameState) callconv(.C) void {
    system.renderer.data.game_camera.position.x = 160;
    system.renderer.data.game_camera.position.y = -90;

    if (game_state.inputDown(.MOVE_LEFT)) {
        game_state.player_pos.x -= 1;
    }
    if (game_state.inputDown(.MOVE_RIGHT)) {
        game_state.player_pos.x += 1;
    }
    if (game_state.inputDown(.MOVE_UP)) {
        game_state.player_pos.y -= 1;
    }
    if (game_state.inputDown(.MOVE_DOWN)) {
        game_state.player_pos.y += 1;
    }
    if (game_state.inputDown(.QUIT)) {
        system.running = false;
    }
    if(game_state.inputDown(.PRIMARY)) {
        const mouse_pos = game_state.mouse_pos_world;
        const tile = game_state.getTileAtWorldPos(mouse_pos);
        if(tile) |t| {
            t.is_visible = true;
        }
    }
}

export fn draw(system: *System, game_state: *GameState) callconv(.C) void {
    system.renderer.drawSprite(.DICE, game_state.player_pos);
    system.renderer.clearScreen(system.screen_dimensions);
    system.renderer.render();
}
