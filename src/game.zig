const std = @import("std");
const c = @import("c.zig").c;
const GLRenderer = @import("gl_renderer.zig");

const Self = @This();

window: *c.SDL_Window,
renderer: GLRenderer,
running: bool,

pub fn init() !Self {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("Failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitError;
    }

    const window = c.SDL_CreateWindow(
        "Celeste Clone Zig",
        1280,
        720,
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_OPENGL,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };

    const renderer = try GLRenderer.init(window);

    return .{
        .window = window,
        .renderer = renderer,
        .running = true,
    };
}

pub fn deinit(self: *Self) void {
    self.renderer.deinit();
    c.SDL_DestroyWindow(self.window);
    c.SDL_Quit();
}

pub fn handleEvent(self: *Self, event: *c.SDL_Event) void {
    while (c.SDL_PollEvent(event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => {
                self.running = false;
            },
            c.SDL_EVENT_KEY_UP => {
                const key = event.key.key;
                switch (key) {
                    c.SDLK_ESCAPE => {
                        self.running = false;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn update(self: *Self) void {
    // TODO: Update game logic here
    // For now
    _ = self;
}

pub fn render(self: *Self) void {
    self.renderer.render();
    _ = c.SDL_GL_SwapWindow(self.window);
}
