const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig").c;

pub var context: ?c.SDL_GLContext = null;

// OpenGL function pointers
var glCreateProgram: ?*const fn() callconv(.C) c_uint = null;
var glDeleteProgram: ?*const fn(c_uint) callconv(.C) void = null;
var glCreateShader: ?*const fn(c_uint) callconv(.C) c_uint = null;
var glDeleteShader: ?*const fn(c_uint) callconv(.C) void = null;

pub const RendererError = error{
    ContextCreationFailed,
    FunctionLoadingFailed,
};

fn loadGLFunction(comptime T: type, name: [*:0]const u8) ?T {
    const proc = c.SDL_GL_GetProcAddress(name);
    if (proc == null) {
        std.debug.print("Failed to load OpenGL function: {s}\n", .{name});
        return null;
    }
    return @as(T, @ptrCast(proc));
}

pub fn init(window: *c.SDL_Window) !void {
    // Set OpenGL attributes - use 4.1 for macOS compatibility
    if (comptime builtin.target.os.tag == .macos) {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 1);
    } else {
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 6);
    }
    _ = c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE);
    
    context = c.SDL_GL_CreateContext(window) orelse {
        std.debug.print("Failed to create OpenGL context: {s}\n", .{c.SDL_GetError()});
        return RendererError.ContextCreationFailed;
    };

    // Load OpenGL functions (needed on Windows and some other platforms)
    if (comptime builtin.target.os.tag  == .windows) {
        loadOpenGLFunctions() catch {
            deinit();
            return RendererError.FunctionLoadingFailed;
        };
    } else {
        // On Linux/macOS, functions are usually available directly
        glCreateProgram = c.glCreateProgram;
        glDeleteProgram = c.glDeleteProgram;
        glCreateShader = c.glCreateShader;
        glDeleteShader = c.glDeleteShader;
    }
}

pub fn deinit() void {
    _ = c.SDL_GL_DestroyContext(context orelse return);
}

fn loadOpenGLFunctions() !void {
    glCreateProgram = loadGLFunction(@TypeOf(glCreateProgram.?), "glCreateProgram") orelse return RendererError.FunctionLoadingFailed;
    glDeleteProgram = loadGLFunction(@TypeOf(glDeleteProgram.?), "glDeleteProgram") orelse return RendererError.FunctionLoadingFailed;
    glCreateShader = loadGLFunction(@TypeOf(glCreateShader.?), "glCreateShader") orelse return RendererError.FunctionLoadingFailed;
    glDeleteShader = loadGLFunction(@TypeOf(glDeleteShader.?), "glDeleteShader") orelse return RendererError.FunctionLoadingFailed;
    
    std.debug.print("OpenGL functions loaded successfully\n", .{});
}


pub fn createProgram() c_uint {
    if (glCreateProgram) |func| {
        return func();
    }
    return 0;
}

pub fn deleteProgram(program: c_uint) void {
    if (glDeleteProgram) |func| {
        func(program);
    }
}

pub fn createShader(shaderType: c_uint) c_uint {
    if (glCreateShader) |func| {
        return func(shaderType);
    }
    return 0;
}

pub fn deleteShader(shader: c_uint) void {
    if (glDeleteShader) |func| {
        func(shader);
    }
}
