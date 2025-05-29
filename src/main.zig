const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");
const util = @import("util.zig");
const Game = @import("game.zig");
const System = @import("system.zig");
const GameState = @import("game-state.zig");
const RenderData = @import("renderer/interface.zig").RenderData;
const GLRenderer = @import("renderer/gl-renderer.zig");

const GameLib = @import("lib.zig");
const BumpAllocator = util.BumpAllocator;
const mb = util.mb;

const INITIAL_SCREEN_WIDTH = 1280;
const INITIAL_SCREEN_HEIGHT = 720;
const WORLD_WIDTH = 320;
const WORLD_HEIGHT = 180;
const TILE_SIZE = 16;

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

    const render_data = try persistent_storage.alloc(RenderData);
    RenderData.init(render_data, .{
        .x = @floatFromInt(WORLD_WIDTH),
        .y = @floatFromInt(WORLD_HEIGHT),
    });

    var renderer = try GLRenderer.init(window, render_data);
    defer renderer.deinit();

    const system = try persistent_storage.alloc(System);
    System.init(
        system,
        window,
        &renderer,
        @floatFromInt(INITIAL_SCREEN_WIDTH),
        @floatFromInt(INITIAL_SCREEN_HEIGHT),
    );
    const game_state = try persistent_storage.alloc(GameState);

    const lib_path = if (comptime builtin.os.tag == .windows)
        "game.dll"
    else if (comptime builtin.os.tag == .macos)
        "zig-out/lib/libgame.dylib"
    else
        "zig-out/lib/libgame.so";

    var should_reload = true;
    var game_lib: ?GameLib = null;
    defer if (game_lib) |*lib| {
        lib.deinit_fn(system);
        lib.lib.close();
    };

    _ = c.SDL_ShowWindow(window);

    while (system.running) {
        if (should_reload) {
            if (game_lib) |*lib| {
                lib.deinit_fn(system);
                lib.lib.close();
            }

            game_lib = GameLib.load(transient_storage.allocator(), lib_path) catch |e| {
                std.debug.print("Failed to load game library: {}\n", .{e});
                continue;
            };

            std.debug.print("Game library loaded successfully: {s}\n", .{game_lib.?.path});
            game_lib.?.init_fn(system);
            should_reload = false;
        }

        // Poll events
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    system.running = false;
                },
                c.SDL_EVENT_KEY_UP => {
                    const key = event.key.key;
                    switch (key) {
                        c.SDLK_ESCAPE => {
                            system.running = false;
                        },
                        c.SDLK_R => {
                            should_reload = true;
                            std.debug.print("Reloading library...\n", .{});

                            // First rebuild the library
                            util.rebuildLibrary(transient_storage.allocator()) catch |err| {
                                std.debug.print("Failed to rebuild library: {}\n", .{err});
                                continue; // Skip reload if build failed
                            };

                            // Small delay to ensure file is written
                            std.time.sleep(100 * std.time.ns_per_ms);
                        },
                        else => {},
                    }
                },

                c.SDL_EVENT_WINDOW_RESIZED => {
                    system.screen_dimensions.x = @floatFromInt(event.window.data1);
                    system.screen_dimensions.y = @floatFromInt(event.window.data2);
                },
                else => {},
            }
        }

        if (game_lib) |lib| {
            lib.update_fn(system, game_state);
            lib.draw_fn(system, game_state);
        } else {
            system.renderer.gl_program.clear(system.screen_dimensions.x, system.screen_dimensions.y);
            //TODO: render a default screen or error message
        }

        transient_storage.reset();
    }
}
