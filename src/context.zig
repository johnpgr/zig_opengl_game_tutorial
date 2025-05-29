const std = @import("std");
const c = @import("c");
const GLRenderer = @import("renderer/gl-renderer.zig");

pub const Context = extern struct {
    window: *c.SDL_Window,
    renderer: *GLRenderer,
    running: bool,
    frame_count: u32,
    delta_time: f32,
    // Game state
    screen_w: f32,
    screen_h: f32,
    mouse_x: f32,
    mouse_y: f32,

    pub fn init(window: *c.SDL_Window, renderer: *GLRenderer, screen_w: f32, screen_h: f32) !Context {
        return .{
            .window = window,
            .renderer = renderer,
            .running = true,
            .frame_count = 0,
            .delta_time = 0.0,
            .screen_w = screen_w,
            .screen_h = screen_h,
            .mouse_x = 0.0,
            .mouse_y = 0.0,
        };
    }
};

