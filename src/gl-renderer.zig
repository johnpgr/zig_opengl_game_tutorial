const std = @import("std");
const global = @import("global.zig");
const c = @import("c");
const gl = @import("gl");
const builtin = @import("builtin");
const assets = @import("assets.zig");
const RenderData = @import("render-data.zig");
const Transform = @import("render-data.zig").Transform;
const Sprite = @import("assets.zig").Sprite;
const SpriteID = @import("assets.zig").SpriteID;
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;
const Mat4 = @import("math.zig").Mat4;
const Context = global.Context;

const Self = @This();

procs: gl.ProcTable = undefined,
program_id: c_uint = 0,
texture_id: c_uint = 0,
vao: c_uint = 0,
vbo: c_uint = 0,
screen_size_id: c_int = 0,
projection_matrix_id: c_int = 0,

pub fn initGLSDL(window: *c.SDL_Window) !c.SDL_GLContext {
    // Initialize OpenGL context and resources (merged from GLProgram.init)
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

    const gl_sdl_context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print(
            "Failed to create OpenGL context: {s}\n",
            .{c.SDL_GetError()},
        );
        return error.ContextCreationFailed;
    };

    return gl_sdl_context;
}

pub fn init(allocator: std.mem.Allocator, render_data: *RenderData) !*Self {
    const self = try allocator.create(Self);

    // Load OpenGL functions
    if (!self.procs.init(c.SDL_GL_GetProcAddress)) {
        std.debug.print("Failed to load OpenGL functions\n", .{});
        return error.FunctionLoadingFailed;
    }

    gl.makeProcTableCurrent(&self.procs);

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

    const vert_shader_id = try createShader(gl.VERTEX_SHADER, "shaders/quad.vert.glsl");
    const frag_shader_id = try createShader(gl.FRAGMENT_SHADER, "shaders/quad.frag.glsl");

    gl.AttachShader(self.program_id, vert_shader_id);
    gl.AttachShader(self.program_id, frag_shader_id);
    gl.LinkProgram(self.program_id);

    var success: c_int = 0;
    var info_log_buf: [1024:0]u8 = undefined;

    gl.GetProgramiv(self.program_id, gl.LINK_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetProgramInfoLog(
            self.program_id,
            info_log_buf.len,
            null,
            &info_log_buf,
        );
        std.debug.print(
            "Shader program linking failed: {s}\n",
            .{std.mem.sliceTo(&info_log_buf, 0)},
        );
        return error.LinkProgramFailed;
    }

    gl.UseProgram(self.program_id);

    gl.DetachShader(self.program_id, vert_shader_id);
    gl.DetachShader(self.program_id, frag_shader_id);
    gl.DeleteShader(vert_shader_id);
    gl.DeleteShader(frag_shader_id);

    gl.GenVertexArrays(1, (&self.vao)[0..1]);
    errdefer gl.DeleteVertexArrays(1, (&self.vao)[0..1]);

    gl.BindVertexArray(self.vao);

    // Texture atlas
    const texture = try assets.loadTexture("TEXTURE_ATLAS.png");
    const texture_location = gl.GetUniformLocation(self.program_id, "texture_atlas");
    if (texture_location == -1) {
        std.debug.print("Failed to get uniform location for texture_atlas\n", .{});
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

    // Transform buffer setup
    const ubo_idx = gl.GetUniformBlockIndex(self.program_id, "TransformUBO");
    if (ubo_idx == gl.INVALID_INDEX) {
        std.debug.print("Failed to get uniform block index for TransformUBO\n", .{});
        return error.TransformUBOIndexNotFound;
    }
    gl.UniformBlockBinding(self.program_id, ubo_idx, 0);
    gl.GenBuffers(1, (&self.vbo)[0..1]);
    gl.BindBufferBase(gl.UNIFORM_BUFFER, 0, self.vbo);
    gl.BufferData(
        gl.UNIFORM_BUFFER,
        @sizeOf(Transform) * @as(isize, @intCast(render_data.max_transforms)),
        render_data.transforms.items.ptr,
        gl.DYNAMIC_DRAW,
    );

    // Uniform locations
    self.screen_size_id = gl.GetUniformLocation(self.program_id, "screen_size");
    self.projection_matrix_id = gl.GetUniformLocation(
        self.program_id,
        "projection_matrix",
    );

    // Vertex attributes
    gl.Enable(gl.FRAMEBUFFER_SRGB);
    gl.Disable(gl.MULTISAMPLE);
    gl.Enable(gl.DEPTH_TEST);
    gl.DepthFunc(gl.GREATER);
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    return self;
}

pub fn deinit(self: *Self) void {
    gl.DeleteProgram(self.program_id);
}

pub fn render(self: *Self, ctx: *Context) void {
    var projection_matrix = Mat4.orthographicProjection(
        ctx.render_data.game_camera.position.x - ctx.render_data.game_camera.dimensions.x / 2,
        ctx.render_data.game_camera.position.x + ctx.render_data.game_camera.dimensions.x / 2,
        -ctx.render_data.game_camera.position.y - ctx.render_data.game_camera.dimensions.y / 2,
        -ctx.render_data.game_camera.position.y + ctx.render_data.game_camera.dimensions.y / 2,
    );
    gl.UniformMatrix4fv(
        self.projection_matrix_id,
        1,
        gl.FALSE,
        projection_matrix.ax(),
    );

    gl.BufferSubData(
        gl.UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * @as(isize, @intCast(ctx.render_data.transforms.items.len)),
        ctx.render_data.transforms.items.ptr,
    );

    if (ctx.render_data.transforms.items.len > 0) {
        gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, @intCast(ctx.render_data.transforms.items.len));
        ctx.render_data.clearTransforms();
    }

    _ = c.SDL_GL_SwapWindow(ctx.window);
}

pub fn clearScreen(self: *Self, screen_dimensions: Vec2) void {
    gl.ClearColor(0.4, 0.3, 0.6, 1.0);
    gl.ClearDepth(0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // Set the viewport to the current window size
    gl.Viewport(
        0,
        0,
        @intFromFloat(screen_dimensions.x),
        @intFromFloat(screen_dimensions.y),
    );
    // Send the screen size to the shader
    gl.Uniform2fv(
        self.screen_size_id,
        1,
        &[2]f32{ screen_dimensions.x, screen_dimensions.y },
    );
}

fn glDebugCallback(
    source: c_uint,
    type_: c_uint,
    id: c_uint,
    severity: c_uint,
    length: c_int,
    message: [*c]const u8,
    user: ?*const anyopaque,
) callconv(.C) void {
    _ = user; // Unused parameter, can be used for custom data if needed

    // macOS does not support OpenGL debug callbacks, so we can skip this
    if (comptime builtin.target.os.tag == .macos) {
        return;
    }

    if (severity == gl.DEBUG_SEVERITY_HIGH or
        severity == gl.DEBUG_SEVERITY_MEDIUM or
        severity == gl.DEBUG_SEVERITY_LOW)
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

fn createShader(shader_type: c_uint, comptime shader_path: []const u8) !c_uint {
    var success: c_int = 0;
    var info_log_buf: [1024:0]u8 = undefined;

    const shader_source = @embedFile(shader_path);
    const shader_id = gl.CreateShader(shader_type);
    if (shader_id == 0) {
        std.debug.print(
            "Failed to create shader: {s}\n",
            .{c.SDL_GetError()},
        );
        return error.ShaderCreationFailed;
    }
    errdefer gl.DeleteShader(shader_id);

    gl.ShaderSource(shader_id, 1, &.{shader_source}, null);
    gl.CompileShader(shader_id);
    gl.GetShaderiv(shader_id, gl.COMPILE_STATUS, &success);

    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(
            shader_id,
            info_log_buf.len,
            null,
            &info_log_buf,
        );
        std.debug.print(
            "Shader compilation failed: {s}\n",
            .{std.mem.sliceTo(&info_log_buf, 0)},
        );
        return error.ShaderCompilationFailed;
    }

    return shader_id;
}
