const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");
const global = @import("global.zig");
const util = @import("util.zig");
const Game = @import("game.zig");
const GameState = @import("game-state.zig");
const RenderData = @import("render-data.zig");
const GLRenderer = @import("gl-renderer.zig");
const GameLib = @import("lib.zig");
const IVec2 = @import("math.zig").IVec2;
const Context = global.Context;
const mb = util.mb;

pub fn main() !void {
    var persistent_storage = std.heap.FixedBufferAllocator.init(
        try std.heap.page_allocator.alloc(u8, mb(50)),
    );
    const persistent_storage_allocator = persistent_storage.allocator();
    defer std.heap.page_allocator.free(persistent_storage.buffer);

    var transient_storage = std.heap.FixedBufferAllocator.init(
        try std.heap.page_allocator.alloc(u8, mb(50)),
    );
    const transient_storage_allocator = transient_storage.allocator();
    defer std.heap.page_allocator.free(transient_storage.buffer);

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("Failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitError;
    }
    defer c.SDL_Quit();

    var ctx: Context = undefined;

    ctx.window = c.SDL_CreateWindow(
        "Zig OpenGL Game",
        global.INITIAL_SCREEN_WIDTH,
        global.INITIAL_SCREEN_HEIGHT,
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_OPENGL,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };
    defer c.SDL_DestroyWindow(ctx.window);

    ctx.render_data = try RenderData.init(
        persistent_storage_allocator,
        .{
            .x = @floatFromInt(global.WORLD_WIDTH),
            .y = @floatFromInt(global.WORLD_HEIGHT),
        },
        1000,
    );

    ctx.sdl_gl_context = try GLRenderer.initGLSDL(ctx.window);
    defer _ = c.SDL_GL_DestroyContext(ctx.sdl_gl_context);

    if (!c.SDL_GL_MakeCurrent(ctx.window, ctx.sdl_gl_context)) {
        std.debug.print(
            "Failed to make OpenGL context current: {s}\n",
            .{c.SDL_GetError()},
        );
        return error.ContextMakeCurrentFailed;
    }

    ctx.gl_context = try GLRenderer.init(persistent_storage_allocator, ctx.render_data);
    defer ctx.gl_context.deinit();

    ctx.game_state = try GameState.init(persistent_storage_allocator);

    const lib_path = comptime if (builtin.os.tag == .windows)
        "game.dll"
    else if (builtin.os.tag == .macos)
        "zig-out/lib/libgame.dylib"
    else
        "zig-out/lib/libgame.so";

    var should_reload = true;
    var game_lib: ?GameLib = null;
    defer if (game_lib) |*lib| {
        lib.deinit_fn();
        lib.lib.close();
    };

    _ = c.SDL_ShowWindow(ctx.window);

    while (ctx.game_state.running) {
        if (should_reload) {
            if (game_lib) |*lib| {
                lib.deinit_fn();
                lib.lib.close();
            }

            game_lib = GameLib.load(transient_storage_allocator, lib_path) catch |e| {
                std.debug.print("Failed to load game library: {}\n", .{e});
                continue;
            };

            std.debug.print("Game library loaded successfully: {s}\n", .{game_lib.?.path});
            game_lib.?.init_fn();
            should_reload = false;
        }

        // Poll events
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => {
                    ctx.game_state.running = false;
                },
                c.SDL_EVENT_WINDOW_RESIZED => {
                    ctx.game_state.screen_dimensions.x = @floatFromInt(event.window.data1);
                    ctx.game_state.screen_dimensions.y = @floatFromInt(event.window.data2);
                },
                else => {},
            }
        }

        if (ctx.game_state.keyPressed(c.SDLK_R)) {
            should_reload = true;
            std.debug.print("Reloading library...\n", .{});

            // First rebuild the library
            util.rebuildLibrary(transient_storage_allocator) catch |err| {
                std.debug.print("Failed to rebuild library: {}\n", .{err});
                continue; // Skip reload if build failed
            };

            // Small delay to ensure file is written
            std.time.sleep(100 * std.time.ns_per_ms);
        }

        if (game_lib) |lib| {
            lib.update_fn(&ctx);
        } else {
            //TODO: Handle case where game library is not loaded
            @panic("Game library not loaded");
        }

        ctx.game_state.updateMousePosition(ctx.render_data, ctx.game_state.screen_dimensions);
        ctx.game_state.updateKeyState();
        transient_storage.reset();
    }
}
