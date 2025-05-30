const c = @import("c");
const global = @import("global.zig");
const std = @import("std");
const System = @import("system.zig");
const GameState = @import("game-state.zig");
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

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
    if (game_state.inputDown(.PRIMARY)) {
        const mouse_pos = game_state.mouse_pos_world;
        const tile = game_state.getTileAtWorldPos(mouse_pos);
        std.debug.print("Mouse position: ({}, {})\n", .{
            game_state.mouse_pos.x, game_state.mouse_pos.y,
        });
        std.debug.print("Mouse position World: ({}, {})\n", .{
            game_state.mouse_pos_world.x, game_state.mouse_pos_world.y,
        });
        std.debug.print("Tile at ({}, {})\n", .{
            mouse_pos.x, mouse_pos.y,
        });
        if (tile) |t| {
            t.is_visible = true;
        }
    }
    if (game_state.inputDown(.SECONDARY)) {
        const mouse_pos = game_state.mouse_pos;
        const tile = game_state.getTileAtWorldPos(mouse_pos);
        if (tile) |t| {
            t.is_visible = false;
        }
    }
    // std.debug.print("Mouse position: ({}, {})\n", .{
    //     game_state.mouse_pos.x, game_state.mouse_pos.y,
    // });
    // std.debug.print("Mouse position World: ({}, {})\n", .{
    //     game_state.mouse_pos_world.x, game_state.mouse_pos_world.y,
    // });
}

export fn draw(system: *System, game_state: *GameState) callconv(.C) void {
    system.renderer.clearScreen(system.screen_dimensions);

    // Draw the tileset
    var x: i32 = 0;
    while (x < global.WORLD_GRID.x) : (x += 1) {
        var y: i32 = 0;
        while (y < global.WORLD_GRID.y) : (y += 1) {
            const tile = game_state.getTileAtWorldPosI(
                IVec2.init(x, y),
            );
            if (tile) |t| {
                if (!t.is_visible) {
                    continue;
                }
                const tile_pos = Vec2{
                    .x = @floatFromInt(x * global.TILE_SIZE + global.TILE_SIZE / 2),
                    .y = @floatFromInt(y * global.TILE_SIZE + global.TILE_SIZE / 2),
                };
                system.renderer.drawQuad(
                    tile_pos,
                    Vec2.init(global.TILE_SIZE, global.TILE_SIZE),
                ) catch |e| {
                    std.debug.print("Failed to draw tile at ({}, {}): {}\n", .{
                        x, y, e,
                    });
                };
            }
        }
    }

    system.renderer.drawSprite(.DICE, game_state.player_pos);
    system.renderer.render();
}
