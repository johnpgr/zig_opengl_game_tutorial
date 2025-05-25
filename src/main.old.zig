const std = @import("std");
const c = @cImport({
    @cDefine("SDL_DISABLE_OLD_NAMES", {});
    @cInclude("SDL3/SDL.h");

    @cDefine("GL_GLEXT_PROTOTYPES", {});
    @cInclude("SDL3/SDL_opengl.h");
    @cInclude("SDL3/SDL_opengl_glext.h");
});

pub inline fn BIT(comptime x: u32) u32 {
    return 1 << x;
}
pub inline fn KB(comptime x: u32) u32 {
    return x * 1024;
}
pub inline fn MB(comptime x: u32) u32 {
    return KB(x) * 1024;
}
pub inline fn GB(comptime x: u32) u32 {
    return MB(x) * 1024;
}

pub const GLContext = struct {
    program_id: c.GLuint = 0,
};

var global_gl_context: GLContext = GLContext{};
var global_running = true;

pub fn handleEvents(window: *c.SDL_Window) void {
    _ = window;
    var event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&event)) {
        switch (event.type) {
            c.SDL_EVENT_QUIT => {
                global_running = false;
            },
            c.SDL_EVENT_KEY_DOWN, c.SDL_EVENT_KEY_UP => {
                const key_event = event.key;
                const key_code = key_event.key;
                const is_down = key_event.down;
                _ = is_down;
                const is_repeat = key_event.repeat;

                if (is_repeat) continue;

                switch (key_code) {
                    c.SDLK_ESCAPE => {
                        global_running = false;
                    },
                    else => {},
                }
            },
            else => {},
        }
    }
}

pub fn readFile(allocator: std.mem.Allocator, filepath: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    const stat = try file.stat();
    const content = try allocator.alloc(u8, @intCast(stat.size));

    const bytes_read = try file.readAll(content);
    if (bytes_read != content.len) return error.IncompleteRead;

    return content;
}

pub fn writeFile(filepath: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(filepath, .{
        .read = true,
        .truncate = true,
    });
    defer file.close();

    try file.writeAll(content);
}

pub fn copyFile(allocator: std.mem.Allocator, src: []const u8, dst: []const u8) !void {
    const content = try readFile(allocator, src);
    defer allocator.free(content);
    try writeFile(dst, content);
}

pub fn initOpenGLAttributes() !void {
    // Context version
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MAJOR_VERSION, 4)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(MAJOR_VERSION) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_MINOR_VERSION, 3)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(MINOR_VERSION) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    // Context flags
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_PROFILE_MASK, c.SDL_GL_CONTEXT_PROFILE_CORE)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(PROFILE_MASK) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_CONTEXT_FLAGS, c.SDL_GL_CONTEXT_DEBUG_FLAG)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(CONTEXT_FLAGS) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    // Pixel format attributes
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_DOUBLEBUFFER, 1)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(DOUBLEBUFFER) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_RED_SIZE, 8)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(RED_SIZE) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_GREEN_SIZE, 8)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(GREEN_SIZE) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_BLUE_SIZE, 8)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(BLUE_SIZE) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_ALPHA_SIZE, 8)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(ALPHA_SIZE) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_DEPTH_SIZE, 24)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(DEPTH_SIZE) Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_SetAttributeError;
    }
    // Optional: Request hardware acceleration
    if (!c.SDL_GL_SetAttribute(c.SDL_GL_ACCELERATED_VISUAL, 1)) {
        c.SDL_LogWarn(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetAttribute(ACCELERATED_VISUAL) Warning: %s. May fall back.\n",
            c.SDL_GetError(),
        );
    }
}

pub fn initSDLGLContext(window: *c.SDL_Window) !c.SDL_GLContext {
    const gl_context = c.SDL_GL_CreateContext(window) orelse {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_CreateContext Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_CreateContextError;
    };

    if (!c.SDL_GL_MakeCurrent(window, gl_context)) {
        c.SDL_LogError(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_MakeCurrent Error: %s\n",
            c.SDL_GetError(),
        );
        return error.SDL_GL_MakeCurrentError;
    }
    if (!c.SDL_GL_SetSwapInterval(1)) {
        c.SDL_LogWarn(
            c.SDL_LOG_CATEGORY_APPLICATION,
            "SDL_GL_SetSwapInterval Error: %s. Continuing without VSync.\n",
            c.SDL_GetError(),
        );
    }

    return gl_context;
}

pub fn initGLSLShaders(allocator: std.mem.Allocator) !void {
    const vert_shader_id = c.glCreateShader(c.GL_VERTEX_SHADER);
    const frag_shader_id = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    const vert_shader = try readFile(allocator, "assets/shaders/quad.vert");
    const frag_shader = try readFile(allocator, "assets/shaders/quad.frag");

    var vert_len: c_int = @intCast(vert_shader.len);
    var frag_len: c_int = @intCast(frag_shader.len);
    c.glShaderSource(vert_shader_id, 1, &vert_shader.ptr, &vert_len);
    c.glShaderSource(frag_shader_id, 1, &frag_shader.ptr, &frag_len);
    c.glCompileShader(vert_shader_id);
    c.glCompileShader(frag_shader_id);
    {
        var success: i32 = 0;
        var log: [2048]u8 = undefined;
        c.glGetShaderiv(vert_shader_id, c.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            c.glGetShaderInfoLog(vert_shader_id, 2048, null, &log);
            c.SDL_LogError(
                c.SDL_LOG_CATEGORY_APPLICATION,
                "Vertex shader compilation error: %s\n",
                &log,
            );
            return error.ShaderCompilationError;
        }
    }
    {
        var success: i32 = 0;
        var log: [2048]u8 = undefined;
        c.glGetShaderiv(frag_shader_id, c.GL_COMPILE_STATUS, &success);
        if (success == 0) {
            c.glGetShaderInfoLog(frag_shader_id, 2048, null, &log);
            c.SDL_LogError(
                c.SDL_LOG_CATEGORY_APPLICATION,
                "Fragment shader compilation error: %s\n",
                &log,
            );
            return error.ShaderCompilationError;
        }
    }
    global_gl_context.program_id = c.glCreateProgram();
    c.glAttachShader(global_gl_context.program_id, vert_shader_id);
    c.glAttachShader(global_gl_context.program_id, frag_shader_id);
    c.glLinkProgram(global_gl_context.program_id);

    c.glDetachShader(global_gl_context.program_id, vert_shader_id);
    c.glDetachShader(global_gl_context.program_id, frag_shader_id);
    c.glDeleteShader(vert_shader_id);
    c.glDeleteShader(frag_shader_id);

    var VAO: c.GLuint = 0;
    c.glGenVertexArrays(1, &VAO);
    c.glBindVertexArray(VAO);

    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_GREATER);

    c.glUseProgram(global_gl_context.program_id);
}

pub const BumpAllocator = struct {
    buffer: []u8,
    fba: std.heap.FixedBufferAllocator,

    pub fn init(size: u32) !BumpAllocator {
        const buffer = try std.heap.page_allocator.alloc(u8, size);
        return BumpAllocator{
            .buffer = buffer,
            .fba = std.heap.FixedBufferAllocator.init(buffer),
        };
    }

    pub fn allocator(self: *BumpAllocator) std.mem.Allocator {
        return self.fba.allocator();
    }

    pub fn deinit(self: *BumpAllocator) void {
        std.heap.page_allocator.free(self.buffer);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    _ = allocator;

    var bpa = try BumpAllocator.init(MB(50));
    defer bpa.deinit();
    const transient_storage = bpa.allocator();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "SDL_Init Error: %s\n", c.SDL_GetError());
        return error.SDL_InitError;
    }
    defer c.SDL_Quit();

    try initOpenGLAttributes();

    const window_flags = c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIGH_PIXEL_DENSITY;
    const window = c.SDL_CreateWindow("Unnamed game", 1280, 720, window_flags) orelse {
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "SDL_CreateWindow Error: %s\n", c.SDL_GetError());
        return error.SDL_CreateWindowError;
    };
    defer c.SDL_DestroyWindow(window);

    const context = try initSDLGLContext(window);
    defer _ = c.SDL_GL_DestroyContext(context);
    try initGLSLShaders(transient_storage);

    while (global_running) {
        handleEvents(window);
        c.glClearColor(119.0 / 255.0, 33.0 / 255.0, 110.0 / 255.0, 1.0);
        c.glClearDepth(0.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glViewport(0, 0, 1280, 720);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);
        _ = c.SDL_GL_SwapWindow(window);
    }
}
