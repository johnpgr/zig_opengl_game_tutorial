const c = @import("c.zig").c;
const std = @import("std");
const util = @import("util.zig");
const gl = @import("gl.zig");
const Game = @import("game.zig");
const Input = @import("input.zig");
const RenderInterface = @import("render-interface.zig");

const BumpAllocator = util.BumpAllocator;
const RenderData = RenderInterface.RenderData;
const mb = util.mb;

const INITIAL_SCREEN_WIDTH = 1280;
const INITIAL_SCREEN_HEIGHT = 720;

pub fn main() !void {
    var transient_storage = try BumpAllocator.init(mb(50));
    defer transient_storage.deinit();

    var persistent_storage = try BumpAllocator.init(mb(50));
    defer persistent_storage.deinit();

    const input = try Input.init(
        transient_storage.allocator(),
        @floatFromInt(INITIAL_SCREEN_WIDTH),
        @floatFromInt(INITIAL_SCREEN_HEIGHT),
    );

    const render_data = try RenderData.init(transient_storage.allocator());

    //TODO(HIGH_PRIORITY): Move window & renderer creation out of Game.init
    var game = try Game.init(input, render_data);

    _ = c.SDL_ShowWindow(game.window);

    while (game.running) {
        var event: c.SDL_Event = undefined;
        game.handleEvent(&event);

        game.update();
        game.render();
        transient_storage.reset();
    }
}
