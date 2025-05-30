const std = @import("std");
const c = @import("c");
const gl = @import("gl");
const builtin = @import("builtin");
const assets = @import("assets.zig");
const Transform = @import("gpu-data.zig").Transform;
const RenderData = @import("gpu-data.zig").RenderData;
const MAX_TRANSFORMS = @import("gpu-data.zig").MAX_TRANSFORMS;
const Sprite = @import("assets.zig").Sprite;
const SpriteID = @import("assets.zig").SpriteID;
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;
const Mat4 = @import("math.zig").Mat4;

const Self = @This();

allocator: std.mem.Allocator,
procs: gl.ProcTable = undefined,
context: c.SDL_GLContext = null,
program_id: c_uint = 0,
texture_id: c_uint = 0,
screen_size_id: c_int = 0,
projection_matrix_id: c_int = 0,
vao: c_uint = 0,
ubo: c_uint = 0,

// Renderer state
data: *RenderData,
window: *c.SDL_Window,

pub fn init(
    allocator: std.mem.Allocator,
    window: *c.SDL_Window,
    render_data: *RenderData,
) !*Self {
    var self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
        .data = render_data,
        .window = window,
    };

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

    self.context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print(
            "Failed to create OpenGL context: {s}\n",
            .{c.SDL_GetError()},
        );
        return error.ContextCreationFailed;
    };
    errdefer _ = c.SDL_GL_DestroyContext(self.context);

    if (!c.SDL_GL_MakeCurrent(window, self.context)) {
        std.debug.print(
            "Failed to make OpenGL context current: {s}\n",
            .{c.SDL_GetError()},
        );
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
        const vert_shader = @embedFile("shaders/quad.vert.glsl");
        const frag_shader = @embedFile("shaders/quad.frag.glsl");
        var success: c_int = 0;
        var info_log_buf: [1024:0]u8 = undefined;

        const vert_shader_id = gl.CreateShader(gl.VERTEX_SHADER);
        if (vert_shader_id == 0) {
            std.debug.print(
                "Failed to create vertex shader: {s}\n",
                .{c.SDL_GetError()},
            );
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
            gl.GetShaderInfoLog(
                vert_shader_id,
                info_log_buf.len,
                null,
                &info_log_buf,
            );
            std.debug.print(
                "Vertex shader compilation failed: {s}\n",
                .{std.mem.sliceTo(&info_log_buf, 0)},
            );
            return error.VertexShaderCompilationFailed;
        }

        const frag_shader_id = gl.CreateShader(gl.FRAGMENT_SHADER);
        if (frag_shader_id == 0) {
            std.debug.print(
                "Failed to create fragment shader: {s}\n",
                .{c.SDL_GetError()},
            );
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
            gl.GetShaderInfoLog(
                frag_shader_id,
                info_log_buf.len,
                null,
                &info_log_buf,
            );
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
    }

    gl.GenVertexArrays(1, (&self.vao)[0..1]);
    errdefer gl.DeleteVertexArrays(1, (&self.vao)[0..1]);

    gl.BindVertexArray(self.vao);

    gl.UseProgram(self.program_id);

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

    // Initialize transforms
    self.initTransforms(render_data.transforms[0..]);

    return self;
}

pub fn deinit(self: *Self) void {
    gl.makeProcTableCurrent(&self.procs);
    _ = c.SDL_GL_DestroyContext(self.context);
    gl.DeleteProgram(self.program_id);
}

pub fn render(self: *Self) void {
    gl.makeProcTableCurrent(&self.procs);

    const camera = self.data.game_camera;
    var projection_matrix = Mat4.orthographicProjection(
        camera.position.x - camera.dimensions.x / 2,
        camera.position.x + camera.dimensions.x / 2,
        -camera.position.y - camera.dimensions.y / 2,
        -camera.position.y + camera.dimensions.y / 2,
    );
    gl.UniformMatrix4fv(
        self.projection_matrix_id,
        1,
        gl.FALSE,
        projection_matrix.ax(),
    );

    if (self.data.transform_count > 0) {
        submitTransforms(self, self.data.transforms[0..self.data.transform_count]);
        // Reset transform count for the next frame
        self.data.transform_count = 0;
    }

    _ = c.SDL_GL_SwapWindow(self.window);
}

pub fn drawSprite(self: *Self, sprite_id: SpriteID, pos: Vec2) void {
    const sprite = Sprite.fromId(sprite_id);

    const transform = Transform{
        .atlas_offset = sprite.atlas_offset,
        .sprite_size = sprite.sprite_size,
        .pos = pos.sub(sprite.sprite_size.toVec2()).div(2),
        .size = sprite.sprite_size.toVec2(),
    };

    self.data.transforms[@intCast(self.data.transform_count)] = transform;
    self.data.transform_count += 1;
}

pub fn clearScreen(self: *Self, screen_dimensions: Vec2) void {
    gl.makeProcTableCurrent(&self.procs);
    gl.ClearColor(0.1, 0.1, 0.1, 1.0);
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

fn initTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.BufferSubData(
        gl.UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * MAX_TRANSFORMS,
        transforms.ptr,
    );
}

fn submitTransforms(self: *Self, transforms: []const Transform) void {
    _ = self;
    gl.BufferSubData(
        gl.UNIFORM_BUFFER,
        0,
        @sizeOf(Transform) * @as(isize, @intCast(transforms.len)),
        transforms.ptr,
    );
    gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, @intCast(transforms.len));
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

    if (severity == gl.DEBUG_SEVERITY_HIGH and
        severity == gl.DEBUG_SEVERITY_MEDIUM and
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
