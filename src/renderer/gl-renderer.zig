const std = @import("std");
const c = @import("c");
const gl = @import("gl");
const assets = @import("../assets.zig");
const math = @import("../math.zig");
const renderer_interface = @import("interface.zig");
const GLProgram = @import("gl-program.zig");

const Transform = renderer_interface.Transform;
const RenderData = renderer_interface.RenderData;
const MAX_TRANSFORMS = renderer_interface.MAX_TRANSFORMS;
const Sprite = assets.Sprite;
const SpriteID = assets.SpriteID;
const Vec2 = math.Vec2;
const IVec2 = math.IVec2;
const Mat4 = math.Mat4;

const Self = @This();

gl_program: GLProgram,
render_data: *RenderData,
window: *c.SDL_Window,

pub fn init(window: *c.SDL_Window, render_data: *RenderData) !Self {
    var self = Self{
        .gl_program = try GLProgram.init(window),
        .render_data = render_data,
        .window = window,
    };

    self.gl_program.initTransforms(render_data.transforms[0..]);

    return self;
}

pub fn deinit(self: *Self) void {
    self.gl_program.deinit();
}

pub fn render(self: *Self, w: f32, h: f32) void {
    if (!c.SDL_GL_MakeCurrent(self.window, self.gl_program.context)) {
        std.debug.print("Failed to make OpenGL context current in clear: {s}\n", .{c.SDL_GetError()});
        return;
    }
    gl.makeProcTableCurrent(&self.gl_program.procs);

    self.gl_program.clear(w, h);

    const camera = self.render_data.game_camera;
    var projection_matrix = Mat4.orthographicProjection(
        camera.position.x - camera.dimensions.x / 2,
        camera.position.x + camera.dimensions.x / 2,
        -camera.position.y - camera.dimensions.y / 2,
        -camera.position.y + camera.dimensions.y / 2,
    );
    gl.UniformMatrix4fv(
        self.gl_program.projection_matrix_id,
        1,
        gl.FALSE,
        projection_matrix.ax(),
    );

    if (self.render_data.transform_count > 0) {
        self.gl_program.submitTransforms(self.render_data.transforms[0..self.render_data.transform_count]);
        // Reset transform count for the next frame
        self.render_data.transform_count = 0;
    }
}

pub fn drawSprite(self: *Self, sprite_id: SpriteID, pos: Vec2) void {
    const sprite = Sprite.fromId(sprite_id);

    const transform = Transform{
        .atlas_offset = sprite.atlas_offset,
        .sprite_size = sprite.sprite_size,
        .pos = pos.sub(sprite.sprite_size.toVec2()).div(2),
        .size = sprite.sprite_size.toVec2(),
    };

    self.render_data.transforms[@intCast(self.render_data.transform_count)] = transform;
    self.render_data.transform_count += 1;
}
