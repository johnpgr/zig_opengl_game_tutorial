const c = @import("c");
const std = @import("std");
const Input = @import("common/input.zig");
const GLRenderer = @import("renderer/gl-renderer.zig");

const Self = @This();

window: *c.SDL_Window,
renderer: *GLRenderer,
input: *Input,
running: bool,

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
                self.input.screen_size.x = @floatFromInt(event.window.data1);
                self.input.screen_size.y = @floatFromInt(event.window.data2);
            },
            else => {},
        }
    }
}

pub fn update(self: *Self) void {
    const cols: u32 = 16;
    const gap: f32 = 10.0;
    const sprite_size: f32 = 64.0;

    for (0..128) |i| {
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
    self.renderer.render(self.input.screen_size.x, self.input.screen_size.y);
    _ = c.SDL_GL_SwapWindow(self.window);
}
