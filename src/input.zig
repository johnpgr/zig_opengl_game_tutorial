const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;

const Self = @This();

screen_size: Vec2,

pub fn init(allocator: std.mem.Allocator, screen_x: f32, screen_y: f32) !*Self {
    const self = try allocator.create(Self);

    self.screen_size.x = screen_x;
    self.screen_size.y = screen_y;

    return self;
}
