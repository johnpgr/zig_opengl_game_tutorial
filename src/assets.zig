const std = @import("std");
const c = @import("c");
const math = @import("math.zig");

const Vec2 = math.Vec2;
const IVec2 = math.IVec2;

const TEXTURES_PATH = "assets/textures";
const FONTS_PATH = "assets/fonts";
const AUDIO_PATH = "assets/audio";
const IMAGES_PATH = "assets/images";

pub fn loadTexture(texture_name: []const u8) !*c.SDL_Surface {
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const full_path = std.fmt.bufPrintZ(&path_buf, "{s}/{s}", .{ TEXTURES_PATH, texture_name }) catch |err| {
        std.debug.print("Path too long for texture: {s}\n", .{texture_name});
        return err;
    };

    const surface = c.IMG_Load(full_path.ptr) orelse {
        std.debug.print("Failed to load texture: {s}\n", .{c.SDL_GetError()});
        return error.TextureLoadError;
    };

    return surface;
}

pub const SpriteID = enum {
    WHITE,
    DICE,
};

pub const Sprite = struct {
    atlas_offset: IVec2,
    sprite_size: IVec2,

    pub fn fromId(sprite_id: SpriteID) Sprite {
        var sprite: Sprite = undefined;

        switch (sprite_id) {
            .WHITE => {
                sprite.atlas_offset = .{ .x = 0, .y = 0 };
                sprite.sprite_size = .{ .x = 1, .y = 1 };
            },
            .DICE => {
                sprite.atlas_offset = .{ .x = 16, .y = 0 };
                sprite.sprite_size = .{ .x = 16, .y = 16 };
            },
        }

        return sprite;
    }
};
