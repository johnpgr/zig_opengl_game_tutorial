const std = @import("std");


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
    max_transforms: usize,
    transforms: std.ArrayList(Transform),

    pub fn init(
        allocator: std.mem.Allocator,
        game_camera_dimensions: Vec2,
        max_transforms: usize,
    ) !*RenderData {
        const self = try allocator.create(RenderData);
        var transforms = std.ArrayList(Transform).init(allocator);
        try transforms.ensureTotalCapacity(max_transforms);

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
            .max_transforms = max_transforms,
            .transforms = transforms,
        };

        return self;
    }

    pub fn addTransform(self: *RenderData, transform: Transform) !void {
        if (self.transforms.items.len >= self.max_transforms) {
            return error.MaxTransformsExceeded;
        }
        try self.transforms.append(transform);
    }

    pub fn clearTransforms(self: *RenderData) void {
        self.transforms.clearRetainingCapacity();
    }
};
