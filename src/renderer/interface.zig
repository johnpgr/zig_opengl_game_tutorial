const std = @import("std");

pub const MAX_TRANSFORMS = 1024;

const math = @import("../common/math.zig");

const Vec2 = math.Vec2;
const IVec2 = math.IVec2;

pub const Transform = struct {
    atlas_offset: IVec2,
    sprite_size: IVec2,
    pos: Vec2,
    size: Vec2,
};

pub const RenderData = struct {
    transform_count: usize,
    transforms: [MAX_TRANSFORMS]Transform,

    pub fn init(allocator: std.mem.Allocator) !*RenderData {
        const data = try allocator.create(RenderData);

        data.* = .{
            .transform_count = 0,
            .transforms = .{
                Transform{
                    .atlas_offset = .{ .x = 0, .y = 0 },
                    .sprite_size = .{ .x = 0, .y = 0 },
                    .pos = .{ .x = 0, .y = 0 },
                    .size = .{ .x = 0, .y = 0 },
                },
            } ** MAX_TRANSFORMS,
        };

        return data;
    }
};
