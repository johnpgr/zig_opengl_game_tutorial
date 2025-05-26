const std = @import("std");
const c = @import("c.zig").c;

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
