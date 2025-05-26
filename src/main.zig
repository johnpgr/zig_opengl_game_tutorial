const std = @import("std");
const c = @import("c.zig").c;
const gl = @import("gl_functions.zig");
const Game = @import("game.zig");

pub fn main() !void {
    var game = try Game.init();

    _ = c.SDL_ShowWindow(game.window);

    while (game.running) {
        var event: c.SDL_Event = undefined;
        game.handleEvent(&event);

        game.update();
        game.render();
    }
}
