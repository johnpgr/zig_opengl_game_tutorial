const std = @import("std");
const c = @import("c");
const util = @import("util.zig");
const Game = @import("game.zig");
const Input = @import("common/input.zig");
const RenderInterface = @import("renderer/interface.zig");
const GLRenderer = @import("renderer/gl-renderer.zig");

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

    // Create SDL window and OpenGL context here
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("Failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitError;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow(
        "Zig OpenGL Game",
        INITIAL_SCREEN_WIDTH,
        INITIAL_SCREEN_HEIGHT,
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_OPENGL,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };
    defer c.SDL_DestroyWindow(window);

    const input = try Input.init(
        transient_storage.allocator(),
        @floatFromInt(INITIAL_SCREEN_WIDTH),
        @floatFromInt(INITIAL_SCREEN_HEIGHT),
    );

    const render_data = try RenderData.init(transient_storage.allocator());

    var game_renderer = try GLRenderer.init(window, render_data);
    defer game_renderer.deinit();

    var game = Game{
        .window = window,
        .renderer = &game_renderer,
        .input = input,
        .running = true,
    };

    _ = c.SDL_ShowWindow(window);

    while (game.running) {
        var event: c.SDL_Event = undefined;
        game.handleEvent(&event);

        game.update();
        game.render();

        transient_storage.reset();
    }
}
