const std = @import("std");

pub const MAX_TRANSFORMS = 1024;

const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

pub const OrthographicCamera2d = struct {
    zoom: f32 = 1.0,
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
    allocator: std.mem.Allocator,
    game_camera: OrthographicCamera2d,
    ui_camera: OrthographicCamera2d,
    transform_count: usize,
    transforms: [MAX_TRANSFORMS]Transform,

    pub fn init(
        allocator: std.mem.Allocator,
        game_camera_dimensions: Vec2,
    ) !*RenderData {
        const self = try allocator.create(RenderData);

        self.* = .{
            .allocator = allocator,
            .game_camera = .{
                .position = .{ .x = 0.0, .y = 0.0 },
                .dimensions = game_camera_dimensions,
            },
            .ui_camera = .{
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
