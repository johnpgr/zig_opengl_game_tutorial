const std = @import("std");
const gl = @import("gl_functions.zig");
const gl_renderer = @import("gl_renderer.zig");
const c = @import("c.zig").c;

var global_running = true;

fn handleAppEvent(event: *c.SDL_Event) !void {
    while (c.SDL_PollEvent(event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => {
                global_running = false;
            },
            c.SDL_EVENT_KEY_UP => {
                const key = event.key.key;
                switch (key) {
                    c.SDLK_ESCAPE => {
                        global_running = false;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("Failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitError;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow(
        "Celeste Clone Zig",
        1280,
        720,
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_OPENGL,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };
    defer c.SDL_DestroyWindow(window);

    try gl_renderer.init(window);
    defer gl_renderer.deinit();

    const prog_id = gl.createProgram();
    defer gl.deleteProgram(prog_id);
    std.debug.print("OpenGL Program ID: {}\n", .{prog_id});

    _ = c.SDL_ShowWindow(window);

    while (global_running) {
        var event: c.SDL_Event = undefined;
        try handleAppEvent(&event);
    }
}
