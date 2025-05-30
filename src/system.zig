const c = @import("c");
const std = @import("std");
const GLRenderer = @import("gl-renderer.zig");
const Vec2 = @import("math.zig").Vec2;

const Self = @This();

allocator: std.mem.Allocator,
window: *c.SDL_Window,
renderer: *GLRenderer,
screen_dimensions: Vec2,
running: bool,
frame_count: u32,
delta_time: f32,

pub fn init(
    allocator: std.mem.Allocator,
    window: *c.SDL_Window,
    renderer: *GLRenderer,
    screen_w: f32,
    screen_h: f32,
) !*Self {
    const self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
        .window = window,
        .renderer = renderer,
        .running = true,
        .screen_dimensions = .{ .x = screen_w, .y = screen_h },
        .frame_count = 0,
        .delta_time = 0.0,
    };

    return self;
}
