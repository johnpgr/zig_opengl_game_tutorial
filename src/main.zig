const std = @import("std");

const c = @cImport({
    @cDefine("SDL_DISABLE_OLDNAMES", {});
    @cDefine("GL_GLEXT_PROTOTYPES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
    @cInclude("SDL3/SDL_opengl.h");
});

var global_running = true;

pub fn handleAppEvent(event: *c.SDL_Event) !void {
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
            else => {}
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
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };
    defer c.SDL_DestroyWindow(window);

    _ = c.SDL_ShowWindow(window);

    while (global_running) {
        var event: c.SDL_Event = undefined;
        try handleAppEvent(&event);
    }
}
