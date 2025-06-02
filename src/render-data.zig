const std = @import("std");
const g = @import("global.zig");
const Sprite = @import("assets.zig").Sprite;
const SpriteID = @import("assets.zig").SpriteID;
const OrthographicCamera2d = @import("math.zig").OrthographicCamera2D;
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

const Self = @This();

game_camera: OrthographicCamera2d = OrthographicCamera2d{},
ui_camera: OrthographicCamera2d = OrthographicCamera2d{},
max_transforms: usize = 0,
transforms: std.ArrayList(Transform),

pub fn init(
    allocator: std.mem.Allocator,
    game_camera_dimensions: Vec2,
    max_transforms: usize,
) !*Self {
    const self = try allocator.create(Self);

    var transforms = std.ArrayList(Transform).init(allocator);
    try transforms.ensureTotalCapacity(max_transforms);

    self.* = Self{ .transforms = transforms };
    self.game_camera.dimensions = game_camera_dimensions;

    return self;
}

pub fn addTransform(self: *Self, transform: Transform) !void {
    if (self.transforms.items.len >= self.max_transforms) {
        return error.MaxTransformsExceeded;
    }
    try self.transforms.append(transform);
}

pub fn clearTransforms(self: *Self) void {
    self.transforms.clearRetainingCapacity();
}

pub fn addSprite(self: *Self, sprite_id: SpriteID, pos: Vec2) void {
    const sprite = Sprite.fromId(sprite_id);

    const transform = Transform{
        .atlas_offset = sprite.atlas_offset,
        .sprite_size = sprite.sprite_size,
        .pos = pos.sub(sprite.sprite_size.toVec2()).div(2),
        .size = sprite.sprite_size.toVec2(),
    };

    self.addTransform(transform) catch |err| {
        std.debug.print("Failed to add sprite transform: {}\n", .{err});
    };
}

pub fn addQuad(self: *Self, pos: Vec2, size: Vec2) !void {
    const transform = Transform{
        .pos = pos.sub(size).div(2),
        .size = size,
        .atlas_offset = IVec2.zero(),
        .sprite_size = IVec2.init(1, 1),
    };
    try self.addTransform(transform);
}

pub const Transform = struct {
    atlas_offset: IVec2 = IVec2.init(0, 0),
    sprite_size: IVec2 = IVec2.init(0, 0),
    pos: Vec2 = Vec2.init(0.0, 0.0),
    size: Vec2 = Vec2.init(0.0, 0.0),
};
