const std = @import("std");
const Vec2 = @import("math.zig").Vec2;
const Self = @This();

mouse_position: Vec2,
player_position: Vec2,

pub fn init(
    allocator: std.mem.Allocator,
) !*Self {
    const self = try allocator.create(Self);

    self.* = .{
        .mouse_position = .{ .x = 0.0, .y = 0.0 },
        .player_position = .{ .x = 0.0, .y = 0.0 },
    };

    return self;
}
