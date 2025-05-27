const std = @import("std");
const builtin = @import("builtin");
const gl = @import("gl.zig");
const c = @import("c.zig").c;
const assets = @import("assets.zig");
const math = @import("math.zig");
const RenderInterface = @import("render-interface.zig");

const Sprite = assets.Sprite;
const SpriteID = assets.SpriteID;
const RenderData = RenderInterface.RenderData;
const Transform = RenderInterface.Transform;
const MAX_TRANSFORMS = RenderInterface.MAX_TRANSFORMS;
const Vec2 = math.Vec2;

const Self = @This();

context: c.SDL_GLContext = null,
program_id: c.GLuint = 0,
texture_id: c.GLuint = 0,
transform_ubo_id: c.GLuint = 0,
screen_size_id: c.GLint = 0,
render_data: ?*RenderData = null,

pub fn init(window: *c.SDL_Window, render_data: *RenderData) !Self {
    var self = Self{};
    self.render_data = render_data;

    initGLAttributes();

    self.context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print("Failed to create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return error.ContextCreationFailed;
    };

    const gl_version = c.glGetString(c.GL_VERSION);
    std.debug.print("OpenGL Version: {s}\n", .{gl_version});

    try gl.loadOpenGLFunctions();

    gl.debugMessageCallback(glDebugCallback, null);
    c.glEnable(c.GL_DEBUG_OUTPUT_SYNCHRONOUS);
    c.glEnable(c.GL_DEBUG_OUTPUT);

    const vert_shader_id = gl.createShader(c.GL_VERTEX_SHADER);
    const frag_shader_id = gl.createShader(c.GL_FRAGMENT_SHADER);
    const vert_shader = @embedFile("shaders/quad.vert.glsl");
    const frag_shader = @embedFile("shaders/quad.frag.glsl");
    const vert_sources = [_][*:0]const u8{vert_shader};
    const frag_sources = [_][*:0]const u8{frag_shader};

    gl.shaderSource(vert_shader_id, 1, &vert_sources, null);
    gl.shaderSource(frag_shader_id, 1, &frag_sources, null);

    gl.compileShader(vert_shader_id);
    gl.compileShader(frag_shader_id);

    {
        var success: c_int = 0;
        var log_length: c.GLsizei = 0;
        var shader_log: [2048]u8 = undefined;

        gl.getShaderiv(vert_shader_id, c.GL_COMPILE_STATUS, &success);

        if (success == 0) {
            gl.getShaderInfoLog(vert_shader_id, 2048, &log_length, &shader_log);
            std.debug.print(
                "Vertex shader compilation failed: {s}\n",
                .{shader_log[0..@as(usize, @intCast(log_length))]},
            );
            return error.VertexShaderCompilationFailed;
        }
    }

    {
        var success: c_int = 0;
        var log_length: c.GLsizei = 0;
        var shader_log: [2048]u8 = undefined;

        gl.getShaderiv(frag_shader_id, c.GL_COMPILE_STATUS, &success);

        if (success == 0) {
            gl.getShaderInfoLog(frag_shader_id, 2048, &log_length, &shader_log);
            std.debug.print(
                "Fragment shader compilation failed: {s}\n",
                .{shader_log[0..@as(usize, @intCast(log_length))]},
            );
            return error.FragmentShaderCompilationFailed;
        }
    }

    self.program_id = gl.createProgram();

    gl.attachShader(self.program_id, vert_shader_id);
    gl.attachShader(self.program_id, frag_shader_id);
    gl.linkProgram(self.program_id);
    {
        var success: c_int = 0;
        var log_length: c.GLsizei = 0;
        var program_log: [2048]u8 = undefined;

        gl.getProgramiv(self.program_id, c.GL_LINK_STATUS, &success);

        if (success == 0) {
            gl.getProgramInfoLog(self.program_id, 2048, &log_length, &program_log);
            std.debug.print(
                "Shader program linking failed: {s}\n",
                .{program_log[0..@as(usize, @intCast(log_length))]},
            );
            return error.ProgramLinkingFailed;
        }
    }

    gl.detachShader(self.program_id, vert_shader_id);
    gl.detachShader(self.program_id, frag_shader_id);
    gl.deleteShader(vert_shader_id);
    gl.deleteShader(frag_shader_id);

    var VAO: c.GLuint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);

    gl.useProgram(self.program_id);

    // Texture atlas
    const texture = try assets.loadTexture("TEXTURE_ATLAS.png");
    const texture_location = gl.getUniformLocation(self.program_id, "textureAtlas");
    if (texture_location == -1) {
        std.debug.print("Failed to get uniform location for textureAtlas\n", .{});
        return error.TextureUniformLocationNotFound;
    }
    gl.uniform1i(texture_location, 0);
    gl.genTextures(1, &self.texture_id);
    gl.activeTexture(c.GL_TEXTURE0);
    gl.bindTexture(c.GL_TEXTURE_2D, self.texture_id);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_EDGE);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_SRGB8_ALPHA8,
        texture.w,
        texture.h,
        0,
        c.GL_RGBA,
        c.GL_UNSIGNED_BYTE,
        texture.pixels,
    );
    c.SDL_DestroySurface(texture);

    // Transform UBO
    const transform_ubo_idx = gl.getUniformBlockIndex(self.program_id, "TransformUBO");
    if (transform_ubo_idx == c.GL_INVALID_INDEX) {
        std.debug.print("Failed to get uniform block index for TransformUBO\n", .{});
        return error.TransformUBOIndexNotFound;
    }
    gl.uniformBlockBinding(self.program_id, transform_ubo_idx, 0);
    gl.genBuffers(1, &self.transform_ubo_id);
    gl.bindBufferBase(c.GL_UNIFORM_BUFFER, 0, self.transform_ubo_id);
    gl.bufferData(
        c.GL_UNIFORM_BUFFER,
        @sizeOf(Transform) * MAX_TRANSFORMS,
        &render_data.transforms,
        c.GL_DYNAMIC_DRAW,
    );

    // Screen size uniform
    self.screen_size_id = gl.getUniformLocation(self.program_id, "screenSize");

    // Vertex attributes
    c.glEnable(c.GL_FRAMEBUFFER_SRGB);
    c.glDisable(c.GL_MULTISAMPLE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_GREATER);

    return self;
}

pub fn deinit(self: *Self) void {
    _ = c.SDL_GL_DestroyContext(self.context);
    gl.deleteProgram(self.program_id);
}

pub fn render(self: *Self, w: f32, h: f32) void {
    if (self.render_data) |data| {
        c.glClearColor(119.0 / 255.0, 33.0 / 255.0, 111.0 / 255.0, 1.0);
        c.glClearDepth(0.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        // Set the viewport to the current window size
        c.glViewport(0, 0, @intFromFloat(w), @intFromFloat(h));
        // Send the screen size to the shader
        gl.uniform2fv(self.screen_size_id, 1, &[2]f32{ w, h });

        // Copy the transforms to the GPU
        gl.bufferSubData(
            c.GL_UNIFORM_BUFFER,
            0,
            @sizeOf(Transform) * @as(isize,@intCast(data.transform_count)),
            &data.transforms,
        );
        gl.drawArraysInstanced(c.GL_TRIANGLES, 0, 6, @intCast(data.transform_count));
        // Reset transform count for the next frame
        data.transform_count = 0;
    }
}

pub fn drawSprite(self: *Self, sprite_id: SpriteID, pos: Vec2, size: Vec2) void {
    if (self.render_data) |data| {
        const sprite = Sprite.fromId(sprite_id);

        const transform = Transform{
            .atlas_offset = sprite.atlas_offset,
            .sprite_size = sprite.sprite_size,
            .pos = pos,
            .size = size,
        };

        data.transforms[@intCast(data.transform_count)] = transform;
        data.transform_count += 1;
    }
}

fn initGLAttributes() void {
    // Set OpenGL attributes - use 4.1 for macOS compatibility
    if (comptime builtin.target.os.tag == .macos) {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 1);
    } else {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3);
    }
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
}

fn glDebugCallback(
    source: c.GLenum,
    type_: c.GLenum,
    id: c.GLuint,
    severity: c.GLenum,
    length: c.GLsizei,
    message: [*c]const u8,
    user: ?*const anyopaque,
) callconv(.C) void {
    _ = user; // Unused parameter, can be used for custom data if needed

    // macOS does not support OpenGL debug callbacks, so we can skip this
    if (comptime builtin.target.os.tag == .macos) {
        return;
    }

    if (severity == c.GL_DEBUG_SEVERITY_HIGH and
        severity == c.GL_DEBUG_SEVERITY_MEDIUM and
        severity == c.GL_DEBUG_SEVERITY_LOW)
    {
        std.debug.print(
            "OpenGL Debug Message: {s}\n",
            .{message[0..@as(usize, @intCast(length))]},
        );
        std.debug.assert(false);
    } else {
        std.debug.print(
            "OpenGL Debug Message (ID: {}, Type: {}, Source: {}): {s}\n",
            .{ id, type_, source, message[0..@as(usize, @intCast(length))] },
        );
    }
}
