const std = @import("std");
const builtin = @import("builtin");
const c = @import("c");
const util = @import("util.zig");
const Game = @import("game.zig");
const System = @import("system.zig");
const GameState = @import("game-state.zig");
const RenderData = @import("gpu-data.zig").RenderData;
const GLRenderer = @import("gl-renderer.zig");
const GameLib = @import("lib.zig");

const mb = util.mb;

const WORLD_WIDTH = 320;
const WORLD_HEIGHT = 180;
const INITIAL_SCREEN_WIDTH = WORLD_WIDTH * 4;
const INITIAL_SCREEN_HEIGHT = WORLD_HEIGHT * 4;
const TILE_SIZE = 16;

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

    const render_data = try RenderData.init(transient_storage_allocator, .{
        .x = @floatFromInt(WORLD_WIDTH),
        .y = @floatFromInt(WORLD_HEIGHT),
    });

    var renderer = try GLRenderer.init(
        persistent_storage_allocator,
        window,
        render_data,
    );
    defer renderer.deinit();

    const system = try System.init(
        persistent_storage_allocator,
        window,
        renderer,
        @floatFromInt(INITIAL_SCREEN_WIDTH),
        @floatFromInt(INITIAL_SCREEN_HEIGHT),
    );

    const game_state = try GameState.init(persistent_storage_allocator);
    defer game_state.deinit();

    const lib_path = comptime if (builtin.os.tag == .windows)
        "game.dll"
    else if (builtin.os.tag == .macos)
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
                c.SDL_EVENT_WINDOW_RESIZED => {
                    system.screen_dimensions.x = @floatFromInt(event.window.data1);
                    system.screen_dimensions.y = @floatFromInt(event.window.data2);
                },
                c.SDL_EVENT_MOUSE_MOTION => {
                    const screen_x = event.motion.x;
                    const screen_y = event.motion.y;

                    game_state.updateMousePosition(
                        screen_x,
                        screen_y,
                        &render_data.game_camera,
                        system.screen_dimensions,
                    );
                },
                else => {},
            }
        }

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

        if (game_state.inputPressed(.RELOAD)) {
            should_reload = true;
            std.debug.print("Reloading library...\n", .{});

            // First rebuild the library
            util.rebuildLibrary(transient_storage.allocator()) catch |err| {
                std.debug.print("Failed to rebuild library: {}\n", .{err});
                continue; // Skip reload if build failed
            };

            // Small delay to ensure file is written
            std.time.sleep(100 * std.time.ns_per_ms);
        }

        if (game_lib) |lib| {
            lib.update_fn(system, game_state);
            lib.draw_fn(system, game_state);
        } else {
            system.renderer.clearScreen(system.screen_dimensions.x, system.screen_dimensions.y);
            //TODO: render a default screen or error message
        }

        game_state.update_key_state();
        transient_storage.reset();
    }
}
