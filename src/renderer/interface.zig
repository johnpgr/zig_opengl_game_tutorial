const std = @import("std");

pub const MAX_TRANSFORMS = 1024;

const math = @import("../math.zig");

const Vec2 = math.Vec2;
const IVec2 = math.IVec2;

pub const OrthographicCamera2d = struct {
    zoom: f32,
    position: Vec2,
    dimensions: Vec2,
};

pub const Transform = struct {
    atlas_offset: IVec2,
    sprite_size: IVec2,
    pos: Vec2,
    size: Vec2,
};

pub const RenderData = struct {
    game_camera: OrthographicCamera2d,
    ui_camera: OrthographicCamera2d,
    transform_count: usize,
    transforms: [MAX_TRANSFORMS]Transform,

    pub fn init(allocator: std.mem.Allocator, game_camera_dimensions: Vec2) !*RenderData {
        const self = try allocator.create(RenderData);

        self.* = .{
            .game_camera = .{
                .zoom = 1.0,
                .position = .{ .x = 0.0, .y = 0.0 },
                .dimensions = game_camera_dimensions,
            },
            .ui_camera = .{
                .zoom = 1.0,
                .position = .{ .x = 0.0, .y = 0.0 },
                .dimensions = .{ .x = 0.0, .y = 0.0 },
            },
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

        return self;
    }
};
