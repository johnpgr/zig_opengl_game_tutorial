const c = @import("c");
const gl = @import("gl");
const g = @import("global.zig");
const global = @import("global.zig");
const std = @import("std");
const GameState = @import("game-state.zig");
const RenderData = @import("render-data.zig");
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

export fn init() callconv(.C) void {
    // TODO Initialize game here
    std.debug.print("Game initialized\n", .{});
}

export fn deinit() callconv(.C) void {
    // TODO Deinitialize game here
    std.debug.print("Game deinitialized\n", .{});
}

export fn update(game_state_in: *GameState, render_data_in: *RenderData) callconv(.C) void {
    gl.makeProcTableCurrent(&g.gl_context.procs);
    if(game_state_in != g.game_state) {
        g.game_state = game_state_in;
    }
    if(render_data_in != g.render_data) {
        g.render_data = render_data_in;
    }

    g.render_data.game_camera.position.x = 160;
    g.render_data.game_camera.position.y = -90;

    if (g.game_state.inputDown(.MOVE_LEFT)) {
        g.game_state.player_pos.x -= 1;
    }
    if (g.game_state.inputDown(.MOVE_RIGHT)) {
        g.game_state.player_pos.x += 1;
    }
    if (g.game_state.inputDown(.MOVE_UP)) {
        g.game_state.player_pos.y -= 1;
    }
    if (g.game_state.inputDown(.MOVE_DOWN)) {
        g.game_state.player_pos.y += 1;
    }
    if (g.game_state.inputDown(.QUIT)) {
        g.game_state.running = false;
    }
    if (g.game_state.inputDown(.PRIMARY)) {
        const mouse_pos = g.game_state.mouse_pos_world;
        const tile = g.game_state.getTileAtWorldPos(mouse_pos);
        std.debug.print("Mouse position: ({}, {})\n", .{
            g.game_state.mouse_pos.x, g.game_state.mouse_pos.y,
        });
        std.debug.print("Mouse position World: ({}, {})\n", .{
            g.game_state.mouse_pos_world.x, g.game_state.mouse_pos_world.y,
        });
        std.debug.print("Tile at ({}, {})\n", .{
            mouse_pos.x, mouse_pos.y,
        });
        if (tile) |t| {
            t.is_visible = true;
        }
    }
    if (g.game_state.inputDown(.SECONDARY)) {
        const mouse_pos = g.game_state.mouse_pos;
        const tile = g.game_state.getTileAtWorldPos(mouse_pos);
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

    g.gl_context.clearScreen(g.game_state.screen_dimensions);

    // Draw the tileset
    var x: i32 = 0;
    while (x < global.WORLD_GRID.x) : (x += 1) {
        var y: i32 = 0;
        while (y < global.WORLD_GRID.y) : (y += 1) {
            const tile = g.game_state.getTileAtWorldPosI(
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
                g.render_data.addQuad(
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

    g.render_data.addSprite(.DICE, g.game_state.player_pos);
    g.gl_context.render();
}
