const std = @import("std");
const Vec2 = @import("math.zig").Vec2;
const Self = @This();

mouse_position: Vec2 = .{ .x = 0.0, .y = 0.0 },
player_position: Vec2 = .{ .x = 0.0, .y = 0.0 },
