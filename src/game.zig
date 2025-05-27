const c = @import("c.zig").c;
const std = @import("std");
const Input = @import("input.zig");
const RenderInterface = @import("render-interface.zig");
const GLRenderer = @import("gl-renderer.zig");

const RenderData = RenderInterface.RenderData;
const Self = @This();

window: *c.SDL_Window,
renderer: GLRenderer,
input: ?*Input,
running: bool,

pub fn init(input: *Input, render_data: *RenderData) !Self {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("Failed to initialize SDL: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitError;
    }

    const window = c.SDL_CreateWindow(
        "Zig OpenGL Game",
        @intFromFloat(input.screen_size.x),
        @intFromFloat(input.screen_size.y),
        c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_OPENGL,
    ) orelse {
        std.debug.print("Failed to create window: {s}\n", .{c.SDL_GetError()});
        return error.WindowCreationError;
    };

    const renderer = try GLRenderer.init(window, render_data);

    return .{
        .window = window,
        .renderer = renderer,
        .running = true,
        .input = input,
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
            c.SDL_EVENT_WINDOW_RESIZED => {
                self.input.?.screen_size.x = @floatFromInt(event.window.data1);
                self.input.?.screen_size.y = @floatFromInt(event.window.data2);
            },
            else => {},
        }
    }
}

pub fn update(self: *Self) void {
    const cols: u32 = 8;
    const gap: f32 = 10.0;
    const sprite_size: f32 = 64.0;
    
    for (0..100) |i| {
        const row = @divFloor(@as(u32, @intCast(i)), cols);
        const col = @mod(@as(u32, @intCast(i)), cols);
        
        self.renderer.drawSprite(
            .DICE,
            .{
                .x = gap + @as(f32, @floatFromInt(col)) * (sprite_size + gap),
                .y = gap + @as(f32, @floatFromInt(row)) * (sprite_size + gap),
            },
            .{ .x = sprite_size, .y = sprite_size },
        );
    }
}

pub fn render(self: *Self) void {
    if(self.input) |input| {
        self.renderer.render(input.screen_size.x, input.screen_size.y);
        _ = c.SDL_GL_SwapWindow(self.window);
    }
}
