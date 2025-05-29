const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");
const util = @import("util.zig");
const Game = @import("game.zig");
const Context = @import("context.zig").Context;
const RenderData = @import("renderer/interface.zig").RenderData;
const GLRenderer = @import("renderer/gl-renderer.zig");

const GameLib = @import("lib.zig").GameLib;
const loadLibrary = @import("lib.zig").loadLibrary;
const BumpAllocator = util.BumpAllocator;
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

    const render_data = try RenderData.init(persistent_storage.allocator());

    var renderer = try GLRenderer.init(window, render_data);
    defer renderer.deinit();

    var context = try Context.init(
        window,
        &renderer,
        @floatFromInt(INITIAL_SCREEN_WIDTH),
        @floatFromInt(INITIAL_SCREEN_HEIGHT),
    );

    const lib_path = if (comptime builtin.os.tag == .windows)
        "game.dll"
    else if (comptime builtin.os.tag == .macos)
        "zig-out/lib/libgame.dylib"
    else
        "zig-out/lib/libgame.so";

    var should_reload = true;
    var game_lib: ?GameLib = null;
    defer if (game_lib) |*lib| {
        lib.deinit_fn(&context);
        lib.lib.close();
    };

    _ = c.SDL_ShowWindow(window);

    while (context.running) {
        if (should_reload) {
            if (game_lib) |*lib| {
                lib.deinit_fn(&context);
                lib.lib.close();
            }

            if (loadLibrary(transient_storage.allocator(), lib_path)) |loaded| {
                const last_modified = util.getLastModified(lib_path) catch 0;
                game_lib = GameLib{
                    .lib = loaded.lib,
                    .path = lib_path,
                    .last_modified = last_modified,
                    .init_fn = loaded.init_fn,
                    .deinit_fn = loaded.deinit_fn,
                    .update_fn = loaded.update_fn,
                    .draw_fn = loaded.draw_fn,
                };
                game_lib.?.init_fn(&context);
                std.debug.print("Game Library loaded.\n", .{});
            } else |err| {
                std.debug.print("Failed to load game library: {}\n", .{err});
            }

            should_reload = false;
        }

        // Poll events
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    context.running = false;
                },
                c.SDL_EVENT_KEY_UP => {
                    const key = event.key.key;
                    switch (key) {
                        c.SDLK_ESCAPE => {
                            context.running = false;
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
                    context.screen_w = @floatFromInt(event.window.data1);
                    context.screen_h = @floatFromInt(event.window.data2);
                },
                else => {},
            }
        }

        if (game_lib) |lib| {
            lib.update_fn(&context);
            lib.draw_fn(&context);
        } else {
            std.debug.print("No game library loaded.\n", .{});
            context.renderer.gl_program.clear(context.screen_w, context.screen_h);
            //TODO: render a default screen or error message
        }

        transient_storage.reset();
    }
}
