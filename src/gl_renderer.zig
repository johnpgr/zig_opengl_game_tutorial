const std = @import("std");
const builtin = @import("builtin");
const gl = @import("gl_functions.zig");
const c = @import("c.zig").c;

const Self = @This();

context: c.SDL_GLContext,
program_id: c.GLuint,

pub fn init(window: *c.SDL_Window) !Self {
    initGLAttributes();

    const context = c.SDL_GL_CreateContext(window) orelse {
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

    const program_id = gl.createProgram();

    gl.attachShader(program_id, vert_shader_id);
    gl.attachShader(program_id, frag_shader_id);
    gl.linkProgram(program_id);

    gl.detachShader(program_id, vert_shader_id);
    gl.detachShader(program_id, frag_shader_id);
    gl.deleteShader(vert_shader_id);
    gl.deleteShader(frag_shader_id);

    var VAO: c.GLuint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);

    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_GREATER);

    gl.useProgram(program_id);

    return .{
        .context = context,
        .program_id = program_id,
    };
}

pub fn deinit(self: *Self) void {
    _ = c.SDL_GL_DestroyContext(self.context);
    gl.deleteProgram(self.program_id);
}

pub fn render(self: *Self) void {
    _ = self;
    c.glClearColor(119.0 / 255.0, 33.0 / 255.0, 111.0 / 255.0, 1.0);
    c.glClearDepth(0.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glViewport(0, 0, 1280, 720);
    gl.drawArrays(c.GL_TRIANGLES, 0, 6);
}

fn initGLAttributes() void {
    // Set OpenGL attributes - use 4.1 for macOS compatibility
    if (comptime builtin.target.os.tag == .macos) {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 1);
    } else {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 6);
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
