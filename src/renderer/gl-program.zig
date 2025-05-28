const std = @import("std");
const builtin = @import("builtin");
const gl = @import("gl");
const c = @import("../c.zig");
const assets = @import("../common/assets.zig");
const math = @import("../common/math.zig");
const renderer_interface = @import("interface.zig");

const Transform = renderer_interface.Transform;
const RenderData = renderer_interface.Transform;
const MAX_TRANSFORMS = renderer_interface.MAX_TRANSFORMS;
const Sprite = assets.Sprite;
const SpriteID = assets.SpriteID;
const Vec2 = math.Vec2;
const IVec2 = math.IVec2;

const Self = @This();

procs: gl.ProcTable = undefined,
context: c.SDL_GLContext = null,
vao: c.GLuint = 0,
program_id: c.GLuint = 0,
texture_id: c.GLuint = 0,
transform_ubo_id: c.GLuint = 0,
screen_size_id: c.GLint = 0,

pub fn init(window: *c.SDL_Window) !Self {
    var self = Self{};

    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, gl.info.version_major))
        return error.MajorVersionSettingFailed;
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, gl.info.version_minor))
        return error.MajorVersionSettingFailed;
    if (!c.SDL_GL_SetAttribute(
        c.SDL_GL_CONTEXT_PROFILE_MASK,
        switch (gl.info.api) {
            .gl => if (gl.info.profile) |profile| switch (profile) {
                .core => c.SDL_GL_CONTEXT_PROFILE_CORE,
                .compatibility => c.SDL_GL_CONTEXT_PROFILE_COMPATIBILITY,
                else => comptime unreachable,
            } else 0,
            .gles, .glsc => c.SDL_GL_CONTEXT_PROFILE_ES,
        },
    )) return error.ProfileMaskSettingFailed;
    if (!c.SDL_GL_SetAttribute(
        c.SDL_GL_CONTEXT_FLAGS,
        if (gl.info.api == .gl and gl.info.version_major >= 3)
            c.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG
        else
            0,
    )) return error.ContextFlagsSettingFailed;

    const gl_version = gl.GetString(c.GL_VERSION) orelse "Unknown OpenGL version";
    std.debug.print("OpenGL Version: {s}\n", .{gl_version});

    self.context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print("Failed to create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return error.ContextCreationFailed;
    };
    errdefer _ = c.SDL_GL_DestroyContext(self.context);

    if (!c.SDL_GL_MakeCurrent(window, self.context)) {
        std.debug.print("Failed to make OpenGL context current: {s}\n", .{c.SDL_GetError()});
        return error.ContextMakeCurrentFailed;
    }
    errdefer _ = c.SDL_GL_MakeCurrent(window, null);

    // Load OpenGL functions
    if (!self.procs.init(c.SDL_GL_GetProcAddress)) {
        std.debug.print("Failed to load OpenGL functions\n", .{});
        return error.FunctionLoadingFailed;
    }

    gl.makeProcTableCurrent(&self.procs);
    errdefer gl.makeProcTableCurrent(null);

    self.program_id = gl.createProgram();
    if (self.program_id == 0) {
        return error.ProgramCreationFailed;
    }
    errdefer gl.deleteProgram(self.program_id);

    {
        const vert_shader = @embedFile("../shaders/quad.vert.glsl");
        const frag_shader = @embedFile("../shaders/quad.frag.glsl");
        var success: c_int = 0;
        var info_log_buf: [1024:0]u8 = undefined;

        const vert_shader_id = gl.CreateShader(gl.VERTEX_SHADER);
        if (vert_shader_id == 0) {
            std.debug.print("Failed to create vertex shader: {s}\n", .{c.SDL_GetError()});
            return error.VertexShaderCreationFailed;
        }
        defer {
            gl.DetachShader(self.program_id, vert_shader_id);
            gl.DeleteShader(vert_shader_id);
        }

        gl.ShaderSource(vert_shader_id, 1, &.{vert_shader}, null);
        gl.CompileShader(vert_shader_id);
        gl.GetShaderiv(vert_shader_id, gl.COMPILE_STATUS, &success);

        if (success == gl.FALSE) {
            gl.GetShaderInfoLog(vert_shader_id, info_log_buf.len, null, &info_log_buf);
            std.debug.print(
                "Vertex shader compilation failed: {s}\n",
                .{info_log_buf},
            );
            return error.VertexShaderCompilationFailed;
        }

        const frag_shader_id = gl.CreateShader(gl.FRAGMENT_SHADER);
        if (frag_shader_id == 0) {
            std.debug.print("Failed to create fragment shader: {s}\n", .{c.SDL_GetError()});
            return error.FragmentShaderCreationFailed;
        }
        defer {
            gl.DetachShader(self.program_id, frag_shader_id);
            gl.DeleteShader(frag_shader_id);
        }

        gl.ShaderSource(frag_shader_id, 1, &.{frag_shader}, null);
        gl.CompileShader(frag_shader_id);
        gl.GetShaderiv(frag_shader_id, gl.COMPILE_STATUS, &success);

        if (success == gl.FALSE) {
            gl.getShaderInfoLog(frag_shader_id, info_log_buf.len, null, &info_log_buf);
            std.debug.print(
                "Fragment shader compilation failed: {s}\n",
                .{info_log_buf},
            );
            return error.FragmentShaderCompilationFailed;
        }

        gl.attachShader(self.program_id, vert_shader_id);
        gl.attachShader(self.program_id, frag_shader_id);

        gl.linkProgram(self.program_id);
        gl.GetProgramiv(self.program_id, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(self.program_id, info_log_buf.len, null, &info_log_buf);
            std.debug.print(
                "Shader program linking failed: {s}\n",
                .{info_log_buf},
            );
            return error.LinkProgramFailed;
        }
    }

    gl.GenVertexArrays(1, &self.vao);
    gl.BindVertexArray(self.vao);

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
        null, // Initial data is null, will be filled later
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

pub fn clear(self: *Self, window_w: f32, window_h: f32) void {
    c.glClearColor(119.0 / 255.0, 33.0 / 255.0, 111.0 / 255.0, 1.0);
    c.glClearDepth(0.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    // Set the viewport to the current window size
    c.glViewport(0, 0, @intFromFloat(window_w), @intFromFloat(window_h));
    // Send the screen size to the shader
    gl.uniform2fv(self.screen_size_id, 1, &[2]f32{ window_w, window_h });
}

pub fn initTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.bufferSubData(
        c.GL_UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * MAX_TRANSFORMS,
        transforms.ptr,
    );
}

pub fn submitTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.bufferSubData(
        c.GL_UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * @as(isize, @intCast(transforms.len)),
        transforms.ptr,
    );
    gl.drawArraysInstanced(c.GL_TRIANGLES, 0, 6, @intCast(transforms.len));
}
