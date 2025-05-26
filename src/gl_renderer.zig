const std = @import("std");
const builtin = @import("builtin");
const gl = @import("gl_functions.zig");
const c = @import("c.zig").c;

pub var context: ?c.SDL_GLContext = null;

pub fn init(window: *c.SDL_Window) !void {
    try gl.loadOpenGLFunctions();

    context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print("Failed to create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return error.ContextCreationFailed;
    };

    initGLAttributes();

    gl.debugMessageCallback(glDebugCallback, null);
}

pub fn deinit() void {
    _ = c.SDL_GL_DestroyContext(context.?);
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
}

pub fn glDebugCallback(
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
        std.debug.print("OpenGL Debug Message: {s}\n", .{message[0..length]});
        std.debug.assert(false);
    } else {
        std.debug.print("OpenGL Debug Message (ID: {}, Type: {}, Source: {}): {s}\n",
            .{id, type_, source, message[0..length]});
    }
}
