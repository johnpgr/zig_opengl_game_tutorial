const std = @import("std");
const builtin = @import("builtin");
const gl = @import("gl");
const c = @import("c");
const assets = @import("../common/assets.zig");
const math = @import("../common/math.zig");
const renderer_interface = @import("interface.zig");
const glDebugCallback = @import("debug-callback.zig").glDebugCallback;

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
program_id: c_uint = 0,
texture_id: c_uint = 0,
screen_size_id: c_int = 0,
vao: c_uint = 0,
ubo: c_uint = 0,

pub fn init(window: *c.SDL_Window) !Self {
    var self = Self{};

    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, gl.info.version_major))
        return error.MajorVersionSettingFailed;
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, gl.info.version_minor))
        return error.MinorVersionSettingFailed;
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

    self.context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print("Failed to create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return error.ContextCreationFailed;
    };
    errdefer _ = c.SDL_GL_DestroyContext(self.context);

    if (!c.SDL_GL_MakeCurrent(window, self.context)) {
        std.debug.print("Failed to make OpenGL context current: {s}\n", .{c.SDL_GetError()});
        return error.ContextMakeCurrentFailed;
    }
    errdefer _ = c.SDL_GL_MakeCurrent(null, null);

    // Load OpenGL functions
    if (!self.procs.init(c.SDL_GL_GetProcAddress)) {
        std.debug.print("Failed to load OpenGL functions\n", .{});
        return error.FunctionLoadingFailed;
    }

    gl.makeProcTableCurrent(&self.procs);
    errdefer gl.makeProcTableCurrent(null);

    const gl_version = gl.GetString(gl.VERSION) orelse "Unknown OpenGL version";
    std.debug.print("OpenGL Version: {s}\n", .{gl_version});

    if (gl.info.version_major >= 4 and gl.info.version_minor >= 3) {
        gl.DebugMessageCallback(glDebugCallback, null);
        gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS);
        gl.Enable(gl.DEBUG_OUTPUT);
    }

    self.program_id = gl.CreateProgram();
    if (self.program_id == 0) {
        return error.ProgramCreationFailed;
    }
    errdefer gl.DeleteProgram(self.program_id);

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
                .{std.mem.sliceTo(&info_log_buf, 0)},
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
            gl.GetShaderInfoLog(frag_shader_id, info_log_buf.len, null, &info_log_buf);
            std.debug.print(
                "Fragment shader compilation failed: {s}\n",
                .{std.mem.sliceTo(&info_log_buf, 0)},
            );
            return error.FragmentShaderCompilationFailed;
        }

        gl.AttachShader(self.program_id, vert_shader_id);
        gl.AttachShader(self.program_id, frag_shader_id);

        gl.LinkProgram(self.program_id);
        gl.GetProgramiv(self.program_id, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(self.program_id, info_log_buf.len, null, &info_log_buf);
            std.debug.print(
                "Shader program linking failed: {s}\n",
                .{std.mem.sliceTo(&info_log_buf, 0)},
            );
            return error.LinkProgramFailed;
        }
    }

    gl.GenVertexArrays(1, (&self.vao)[0..1]);
    errdefer gl.DeleteVertexArrays(1, (&self.vao)[0..1]);

    gl.BindVertexArray(self.vao);

    gl.UseProgram(self.program_id);

    // Texture atlas
    const texture = try assets.loadTexture("TEXTURE_ATLAS.png");
    const texture_location = gl.GetUniformLocation(self.program_id, "textureAtlas");
    if (texture_location == -1) {
        std.debug.print("Failed to get uniform location for textureAtlas\n", .{});
        return error.TextureUniformLocationNotFound;
    }
    gl.Uniform1i(texture_location, 0);
    gl.GenTextures(1, (&self.texture_id)[0..1]);
    gl.ActiveTexture(gl.TEXTURE0);
    gl.BindTexture(gl.TEXTURE_2D, self.texture_id);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.SRGB8_ALPHA8,
        texture.w,
        texture.h,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        texture.pixels,
    );
    c.SDL_DestroySurface(texture);

    // Transform UBO
    const ubo_idx = gl.GetUniformBlockIndex(self.program_id, "TransformUBO");
    if (ubo_idx == gl.INVALID_INDEX) {
        std.debug.print("Failed to get uniform block index for TransformUBO\n", .{});
        return error.TransformUBOIndexNotFound;
    }
    gl.UniformBlockBinding(self.program_id, ubo_idx, 0);
    gl.GenBuffers(1, (&self.ubo)[0..1]);
    gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, self.ubo);
    gl.BufferData(
        gl.UNIFORM_BUFFER,
        @sizeOf(Transform) * MAX_TRANSFORMS,
        null, // Initial data is null, will be filled later
        gl.DYNAMIC_DRAW,
    );

    // Screen size uniform
    self.screen_size_id = gl.GetUniformLocation(self.program_id, "screenSize");

    // Vertex attributes
    gl.Enable(gl.FRAMEBUFFER_SRGB);
    gl.Disable(gl.MULTISAMPLE);
    gl.Enable(gl.DEPTH_TEST);
    gl.DepthFunc(gl.GREATER);

    return self;
}

pub fn deinit(self: *Self) void {
    _ = c.SDL_GL_DestroyContext(self.context);
    gl.DeleteProgram(self.program_id);
}

pub fn clear(self: *Self, window_w: f32, window_h: f32) void {
    gl.ClearColor(119.0 / 255.0, 33.0 / 255.0, 111.0 / 255.0, 1.0);
    gl.ClearDepth(0.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // Set the viewport to the current window size
    gl.Viewport(0, 0, @intFromFloat(window_w), @intFromFloat(window_h));
    // Send the screen size to the shader
    gl.Uniform2fv(self.screen_size_id, 1, &[2]f32{ window_w, window_h });
}

pub fn initTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.BufferSubData(
        gl.UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * MAX_TRANSFORMS,
        transforms.ptr,
    );
}

pub fn submitTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.BufferSubData(
        gl.UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * @as(isize, @intCast(transforms.len)),
        transforms.ptr,
    );
    gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, @intCast(transforms.len));
}
