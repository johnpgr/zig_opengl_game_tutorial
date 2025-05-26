const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig").c;

// OpenGL function pointers
var glCreateProgram_ptr: ?*const fn () callconv(.C) c_uint = null;
var glDeleteTextures_ptr: ?*const fn (c_int, [*]const c_uint) callconv(.C) void = null;
var glGenTextures_ptr: ?*const fn (c_int, [*]c_uint) callconv(.C) void = null;
var glBindTexture_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glDrawArrays_ptr: ?*const fn (c_uint, c_int, c_int) callconv(.C) void = null;
var glCreateShader_ptr: ?*const fn (c_uint) callconv(.C) c_uint = null;
var glGetUniformLocation_ptr: ?*const fn (c_uint, [*:0]const u8) callconv(.C) c_int = null;
var glUniform1f_ptr: ?*const fn (c_int, f32) callconv(.C) void = null;
var glUniform2fv_ptr: ?*const fn (c_int, c_int, [*]const f32) callconv(.C) void = null;
var glUniform3fv_ptr: ?*const fn (c_int, c_int, [*]const f32) callconv(.C) void = null;
var glUniform1i_ptr: ?*const fn (c_int, c_int) callconv(.C) void = null;
var glUniformMatrix4fv_ptr: ?*const fn (c_int, c_int, u8, [*]const f32) callconv(.C) void = null;
var glVertexAttribDivisor_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glActiveTexture_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glBufferSubData_ptr: ?*const fn (c_uint, isize, isize, ?*const anyopaque) callconv(.C) void = null;
var glDrawArraysInstanced_ptr: ?*const fn (c_uint, c_int, c_int, c_int) callconv(.C) void = null;
var glBindFramebuffer_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glCheckFramebufferStatus_ptr: ?*const fn (c_uint) callconv(.C) c_uint = null;
var glGenFramebuffers_ptr: ?*const fn (c_int, [*]c_uint) callconv(.C) void = null;
var glFramebufferTexture2D_ptr: ?*const fn (c_uint, c_uint, c_uint, c_uint, c_int) callconv(.C) void = null;
var glDrawBuffers_ptr: ?*const fn (c_int, [*]const c_uint) callconv(.C) void = null;
var glDeleteFramebuffers_ptr: ?*const fn (c_int, [*]const c_uint) callconv(.C) void = null;
var glBlendFunci_ptr: ?*const fn (c_uint, c_uint, c_uint) callconv(.C) void = null;
var glBlendEquation_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glClearBufferfv_ptr: ?*const fn (c_uint, c_int, [*]const f32) callconv(.C) void = null;
var glShaderSource_ptr: ?*const fn (c_uint, c_int, [*]const [*:0]const u8, ?[*]const c_int) callconv(.C) void = null;
var glCompileShader_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glGetShaderiv_ptr: ?*const fn (c_uint, c_uint, [*]c_int) callconv(.C) void = null;
var glGetShaderInfoLog_ptr: ?*const fn (c_uint, c_int, [*]c_int, [*]u8) callconv(.C) void = null;
var glAttachShader_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glLinkProgram_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glValidateProgram_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glGetProgramiv_ptr: ?*const fn (c_uint, c_uint, [*]c_int) callconv(.C) void = null;
var glGetProgramInfoLog_ptr: ?*const fn (c_uint, c_int, [*]c_int, [*]u8) callconv(.C) void = null;
var glGenBuffers_ptr: ?*const fn (c_int, [*]c_uint) callconv(.C) void = null;
var glGenVertexArrays_ptr: ?*const fn (c_int, [*]c_uint) callconv(.C) void = null;
var glGetAttribLocation_ptr: ?*const fn (c_uint, [*:0]const u8) callconv(.C) c_int = null;
var glBindVertexArray_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glEnableVertexAttribArray_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glVertexAttribPointer_ptr: ?*const fn (c_uint, c_int, c_uint, u8, c_int, ?*const anyopaque) callconv(.C) void = null;
var glBindBuffer_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glBindBufferBase_ptr: ?*const fn (c_uint, c_uint, c_uint) callconv(.C) void = null;
var glBufferData_ptr: ?*const fn (c_uint, isize, ?*const anyopaque, c_uint) callconv(.C) void = null;
var glGetVertexAttribPointerv_ptr: ?*const fn (c_uint, c_uint, [*]?*anyopaque) callconv(.C) void = null;
var glUseProgram_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glDeleteVertexArrays_ptr: ?*const fn (c_int, [*]const c_uint) callconv(.C) void = null;
var glDeleteBuffers_ptr: ?*const fn (c_int, [*]const c_uint) callconv(.C) void = null;
var glDeleteProgram_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glDetachShader_ptr: ?*const fn (c_uint, c_uint) callconv(.C) void = null;
var glDeleteShader_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glDrawElementsInstanced_ptr: ?*const fn (c_uint, c_int, c_uint, ?*const anyopaque, c_int) callconv(.C) void = null;
var glGenerateMipmap_ptr: ?*const fn (c_uint) callconv(.C) void = null;
var glDebugMessageCallback_ptr: ?*const fn (?*const fn (c_uint, c_uint, c_uint, c_uint, c_int, [*c]const u8, ?*const anyopaque) callconv(.c) void, ?*const anyopaque) callconv(.c) void = null;

fn loadGLFunction(comptime T: type, name: [*:0]const u8) ?T {
    const proc = c.SDL_GL_GetProcAddress(name);
    if (proc == null) {
        std.debug.print("Failed to load OpenGL function: {s}\n", .{name});
        return null;
    }
    return @as(T, @ptrCast(proc));
}

pub fn loadOpenGLFunctions() !void {
    if (comptime builtin.target.os.tag == .windows) {
        glCreateProgram_ptr = loadGLFunction(@TypeOf(glCreateProgram_ptr.?), "glCreateProgram") orelse return error.FunctionLoadingFailed;
        glDeleteTextures_ptr = loadGLFunction(@TypeOf(glDeleteTextures_ptr.?), "glDeleteTextures") orelse return error.FunctionLoadingFailed;
        glGenTextures_ptr = loadGLFunction(@TypeOf(glGenTextures_ptr.?), "glGenTextures") orelse return error.FunctionLoadingFailed;
        glBindTexture_ptr = loadGLFunction(@TypeOf(glBindTexture_ptr.?), "glBindTexture") orelse return error.FunctionLoadingFailed;
        glDrawArrays_ptr = loadGLFunction(@TypeOf(glDrawArrays_ptr.?), "glDrawArrays") orelse return error.FunctionLoadingFailed;
        glCreateShader_ptr = loadGLFunction(@TypeOf(glCreateShader_ptr.?), "glCreateShader") orelse return error.FunctionLoadingFailed;
        glGetUniformLocation_ptr = loadGLFunction(@TypeOf(glGetUniformLocation_ptr.?), "glGetUniformLocation") orelse return error.FunctionLoadingFailed;
        glUniform1f_ptr = loadGLFunction(@TypeOf(glUniform1f_ptr.?), "glUniform1f") orelse return error.FunctionLoadingFailed;
        glUniform2fv_ptr = loadGLFunction(@TypeOf(glUniform2fv_ptr.?), "glUniform2fv") orelse return error.FunctionLoadingFailed;
        glUniform3fv_ptr = loadGLFunction(@TypeOf(glUniform3fv_ptr.?), "glUniform3fv") orelse return error.FunctionLoadingFailed;
        glUniform1i_ptr = loadGLFunction(@TypeOf(glUniform1i_ptr.?), "glUniform1i") orelse return error.FunctionLoadingFailed;
        glUniformMatrix4fv_ptr = loadGLFunction(@TypeOf(glUniformMatrix4fv_ptr.?), "glUniformMatrix4fv") orelse return error.FunctionLoadingFailed;
        glVertexAttribDivisor_ptr = loadGLFunction(@TypeOf(glVertexAttribDivisor_ptr.?), "glVertexAttribDivisor") orelse return error.FunctionLoadingFailed;
        glActiveTexture_ptr = loadGLFunction(@TypeOf(glActiveTexture_ptr.?), "glActiveTexture") orelse return error.FunctionLoadingFailed;
        glBufferSubData_ptr = loadGLFunction(@TypeOf(glBufferSubData_ptr.?), "glBufferSubData") orelse return error.FunctionLoadingFailed;
        glDrawArraysInstanced_ptr = loadGLFunction(@TypeOf(glDrawArraysInstanced_ptr.?), "glDrawArraysInstanced") orelse return error.FunctionLoadingFailed;
        glBindFramebuffer_ptr = loadGLFunction(@TypeOf(glBindFramebuffer_ptr.?), "glBindFramebuffer") orelse return error.FunctionLoadingFailed;
        glCheckFramebufferStatus_ptr = loadGLFunction(@TypeOf(glCheckFramebufferStatus_ptr.?), "glCheckFramebufferStatus") orelse return error.FunctionLoadingFailed;
        glGenFramebuffers_ptr = loadGLFunction(@TypeOf(glGenFramebuffers_ptr.?), "glGenFramebuffers") orelse return error.FunctionLoadingFailed;
        glFramebufferTexture2D_ptr = loadGLFunction(@TypeOf(glFramebufferTexture2D_ptr.?), "glFramebufferTexture2D") orelse return error.FunctionLoadingFailed;
        glDrawBuffers_ptr = loadGLFunction(@TypeOf(glDrawBuffers_ptr.?), "glDrawBuffers") orelse return error.FunctionLoadingFailed;
        glDeleteFramebuffers_ptr = loadGLFunction(@TypeOf(glDeleteFramebuffers_ptr.?), "glDeleteFramebuffers") orelse return error.FunctionLoadingFailed;
        glBlendFunci_ptr = loadGLFunction(@TypeOf(glBlendFunci_ptr.?), "glBlendFunci") orelse return error.FunctionLoadingFailed;
        glBlendEquation_ptr = loadGLFunction(@TypeOf(glBlendEquation_ptr.?), "glBlendEquation") orelse return error.FunctionLoadingFailed;
        glClearBufferfv_ptr = loadGLFunction(@TypeOf(glClearBufferfv_ptr.?), "glClearBufferfv") orelse return error.FunctionLoadingFailed;
        glShaderSource_ptr = loadGLFunction(@TypeOf(glShaderSource_ptr.?), "glShaderSource") orelse return error.FunctionLoadingFailed;
        glCompileShader_ptr = loadGLFunction(@TypeOf(glCompileShader_ptr.?), "glCompileShader") orelse return error.FunctionLoadingFailed;
        glGetShaderiv_ptr = loadGLFunction(@TypeOf(glGetShaderiv_ptr.?), "glGetShaderiv") orelse return error.FunctionLoadingFailed;
        glGetShaderInfoLog_ptr = loadGLFunction(@TypeOf(glGetShaderInfoLog_ptr.?), "glGetShaderInfoLog") orelse return error.FunctionLoadingFailed;
        glAttachShader_ptr = loadGLFunction(@TypeOf(glAttachShader_ptr.?), "glAttachShader") orelse return error.FunctionLoadingFailed;
        glLinkProgram_ptr = loadGLFunction(@TypeOf(glLinkProgram_ptr.?), "glLinkProgram") orelse return error.FunctionLoadingFailed;
        glValidateProgram_ptr = loadGLFunction(@TypeOf(glValidateProgram_ptr.?), "glValidateProgram") orelse return error.FunctionLoadingFailed;
        glGetProgramiv_ptr = loadGLFunction(@TypeOf(glGetProgramiv_ptr.?), "glGetProgramiv") orelse return error.FunctionLoadingFailed;
        glGetProgramInfoLog_ptr = loadGLFunction(@TypeOf(glGetProgramInfoLog_ptr.?), "glGetProgramInfoLog") orelse return error.FunctionLoadingFailed;
        glGenBuffers_ptr = loadGLFunction(@TypeOf(glGenBuffers_ptr.?), "glGenBuffers") orelse return error.FunctionLoadingFailed;
        glGenVertexArrays_ptr = loadGLFunction(@TypeOf(glGenVertexArrays_ptr.?), "glGenVertexArrays") orelse return error.FunctionLoadingFailed;
        glGetAttribLocation_ptr = loadGLFunction(@TypeOf(glGetAttribLocation_ptr.?), "glGetAttribLocation") orelse return error.FunctionLoadingFailed;
        glBindVertexArray_ptr = loadGLFunction(@TypeOf(glBindVertexArray_ptr.?), "glBindVertexArray") orelse return error.FunctionLoadingFailed;
        glEnableVertexAttribArray_ptr = loadGLFunction(@TypeOf(glEnableVertexAttribArray_ptr.?), "glEnableVertexAttribArray") orelse return error.FunctionLoadingFailed;
        glVertexAttribPointer_ptr = loadGLFunction(@TypeOf(glVertexAttribPointer_ptr.?), "glVertexAttribPointer") orelse return error.FunctionLoadingFailed;
        glBindBuffer_ptr = loadGLFunction(@TypeOf(glBindBuffer_ptr.?), "glBindBuffer") orelse return error.FunctionLoadingFailed;
        glBindBufferBase_ptr = loadGLFunction(@TypeOf(glBindBufferBase_ptr.?), "glBindBufferBase") orelse return error.FunctionLoadingFailed;
        glBufferData_ptr = loadGLFunction(@TypeOf(glBufferData_ptr.?), "glBufferData") orelse return error.FunctionLoadingFailed;
        glGetVertexAttribPointerv_ptr = loadGLFunction(@TypeOf(glGetVertexAttribPointerv_ptr.?), "glGetVertexAttribPointerv") orelse return error.FunctionLoadingFailed;
        glUseProgram_ptr = loadGLFunction(@TypeOf(glUseProgram_ptr.?), "glUseProgram") orelse return error.FunctionLoadingFailed;
        glDeleteVertexArrays_ptr = loadGLFunction(@TypeOf(glDeleteVertexArrays_ptr.?), "glDeleteVertexArrays") orelse return error.FunctionLoadingFailed;
        glDeleteBuffers_ptr = loadGLFunction(@TypeOf(glDeleteBuffers_ptr.?), "glDeleteBuffers") orelse return error.FunctionLoadingFailed;
        glDeleteProgram_ptr = loadGLFunction(@TypeOf(glDeleteProgram_ptr.?), "glDeleteProgram") orelse return error.FunctionLoadingFailed;
        glDetachShader_ptr = loadGLFunction(@TypeOf(glDetachShader_ptr.?), "glDetachShader") orelse return error.FunctionLoadingFailed;
        glDeleteShader_ptr = loadGLFunction(@TypeOf(glDeleteShader_ptr.?), "glDeleteShader") orelse return error.FunctionLoadingFailed;
        glDrawElementsInstanced_ptr = loadGLFunction(@TypeOf(glDrawElementsInstanced_ptr.?), "glDrawElementsInstanced") orelse return error.FunctionLoadingFailed;
        glGenerateMipmap_ptr = loadGLFunction(@TypeOf(glGenerateMipmap_ptr.?), "glGenerateMipmap") orelse return error.FunctionLoadingFailed;
        glDebugMessageCallback_ptr = loadGLFunction(@TypeOf(glDebugMessageCallback_ptr.?), "glDebugMessageCallback") orelse return error.FunctionLoadingFailed;
    } else {
        // On Linux/macOS, functions are usually available directly
        glCreateProgram_ptr = c.glCreateProgram;
        glDeleteTextures_ptr = c.glDeleteTextures;
        glGenTextures_ptr = c.glGenTextures;
        glBindTexture_ptr = c.glBindTexture;
        glDrawArrays_ptr = c.glDrawArrays;
        glCreateShader_ptr = c.glCreateShader;
        glGetUniformLocation_ptr = c.glGetUniformLocation;
        glUniform1f_ptr = c.glUniform1f;
        glUniform2fv_ptr = c.glUniform2fv;
        glUniform3fv_ptr = c.glUniform3fv;
        glUniform1i_ptr = c.glUniform1i;
        glUniformMatrix4fv_ptr = c.glUniformMatrix4fv;
        glVertexAttribDivisor_ptr = c.glVertexAttribDivisor;
        glActiveTexture_ptr = c.glActiveTexture;
        glBufferSubData_ptr = c.glBufferSubData;
        glDrawArraysInstanced_ptr = c.glDrawArraysInstanced;
        glBindFramebuffer_ptr = c.glBindFramebuffer;
        glCheckFramebufferStatus_ptr = c.glCheckFramebufferStatus;
        glGenFramebuffers_ptr = c.glGenFramebuffers;
        glFramebufferTexture2D_ptr = c.glFramebufferTexture2D;
        glDrawBuffers_ptr = c.glDrawBuffers;
        glDeleteFramebuffers_ptr = c.glDeleteFramebuffers;
        glBlendFunci_ptr = c.glBlendFunci;
        glBlendEquation_ptr = c.glBlendEquation;
        glClearBufferfv_ptr = c.glClearBufferfv;
        glShaderSource_ptr = c.glShaderSource;
        glCompileShader_ptr = c.glCompileShader;
        glGetShaderiv_ptr = c.glGetShaderiv;
        glGetShaderInfoLog_ptr = c.glGetShaderInfoLog;
        glAttachShader_ptr = c.glAttachShader;
        glLinkProgram_ptr = c.glLinkProgram;
        glValidateProgram_ptr = c.glValidateProgram;
        glGetProgramiv_ptr = c.glGetProgramiv;
        glGetProgramInfoLog_ptr = c.glGetProgramInfoLog;
        glGenBuffers_ptr = c.glGenBuffers;
        glGenVertexArrays_ptr = c.glGenVertexArrays;
        glGetAttribLocation_ptr = c.glGetAttribLocation;
        glBindVertexArray_ptr = c.glBindVertexArray;
        glEnableVertexAttribArray_ptr = c.glEnableVertexAttribArray;
        glVertexAttribPointer_ptr = c.glVertexAttribPointer;
        glBindBuffer_ptr = c.glBindBuffer;
        glBindBufferBase_ptr = c.glBindBufferBase;
        glBufferData_ptr = c.glBufferData;
        glGetVertexAttribPointerv_ptr = c.glGetVertexAttribPointerv;
        glUseProgram_ptr = c.glUseProgram;
        glDeleteVertexArrays_ptr = c.glDeleteVertexArrays;
        glDeleteBuffers_ptr = c.glDeleteBuffers;
        glDeleteProgram_ptr = c.glDeleteProgram;
        glDetachShader_ptr = c.glDetachShader;
        glDeleteShader_ptr = c.glDeleteShader;
        glDrawElementsInstanced_ptr = c.glDrawElementsInstanced;
        glGenerateMipmap_ptr = c.glGenerateMipmap;
        if (comptime builtin.target.os.tag != .macos) {
            glDebugMessageCallback_ptr = c.glDebugMessageCallback;
        }
    }

    std.debug.print("OpenGL functions loaded successfully\n", .{});
}

pub fn createProgram() c_uint {
    return glCreateProgram_ptr.?();
}

pub fn deleteProgram(program: c_uint) void {
    glDeleteProgram_ptr.?(program);
}

pub fn createShader(shaderType: c_uint) c_uint {
    return glCreateShader_ptr.?(shaderType);
}

pub fn deleteShader(shader: c_uint) void {
    glDeleteShader_ptr.?(shader);
}

pub fn deleteTextures(n: c_int, textures: [*]const c_uint) void {
    glDeleteTextures_ptr.?(n, textures);
}

pub fn genTextures(n: c_int, textures: [*]c_uint) void {
    glGenTextures_ptr.?(n, textures);
}

pub fn bindTexture(target: c_uint, texture: c_uint) void {
    glBindTexture_ptr.?(target, texture);
}

pub fn drawArrays(mode: c_uint, first: c_int, count: c_int) void {
    glDrawArrays_ptr.?(mode, first, count);
}

pub fn getUniformLocation(program: c_uint, name: [*:0]const u8) c_int {
    return glGetUniformLocation_ptr.?(program, name);
}

pub fn uniform1f(location: c_int, v0: f32) void {
    glUniform1f_ptr.?(location, v0);
}

pub fn uniform2fv(location: c_int, count: c_int, value: [*]const f32) void {
    glUniform2fv_ptr.?(location, count, value);
}

pub fn uniform3fv(location: c_int, count: c_int, value: [*]const f32) void {
    glUniform3fv_ptr.?(location, count, value);
}

pub fn uniform1i(location: c_int, v0: c_int) void {
    glUniform1i_ptr.?(location, v0);
}

pub fn uniformMatrix4fv(
    location: c_int,
    count: c_int,
    transpose: u8,
    value: [*]const f32,
) void {
    glUniformMatrix4fv_ptr.?(location, count, transpose, value);
}

pub fn vertexAttribDivisor(index: c_uint, divisor: c_uint) void {
    glVertexAttribDivisor_ptr.?(index, divisor);
}

pub fn activeTexture(texture: c_uint) void {
    glActiveTexture_ptr.?(texture);
}

pub fn bufferSubData(
    target: c_uint,
    offset: isize,
    size: isize,
    data: ?*const anyopaque,
) void {
    glBufferSubData_ptr.?(target, offset, size, data);
}

pub fn drawArraysInstanced(
    mode: c_uint,
    first: c_int,
    count: c_int,
    instanceCount: c_int,
) void {
    glDrawArraysInstanced_ptr.?(mode, first, count, instanceCount);
}

pub fn bindFramebuffer(target: c_uint, framebuffer: c_uint) void {
    glBindFramebuffer_ptr.?(target, framebuffer);
}

pub fn checkFramebufferStatus(target: c_uint) c_uint {
    return glCheckFramebufferStatus_ptr.?(target);
}

pub fn genFramebuffers(n: c_int, framebuffers: [*]c_uint) void {
    glGenFramebuffers_ptr.?(n, framebuffers);
}

pub fn framebufferTexture2D(
    target: c_uint,
    attachment: c_uint,
    textarget: c_uint,
    texture: c_uint,
    level: c_int,
) void {
    glFramebufferTexture2D_ptr.?(target, attachment, textarget, texture, level);
}

pub fn drawBuffers(n: c_int, bufs: [*]const c_uint) void {
    glDrawBuffers_ptr.?(n, bufs);
}

pub fn deleteFramebuffers(n: c_int, framebuffers: [*]const c_uint) void {
    glDeleteFramebuffers_ptr.?(n, framebuffers);
}

pub fn blendFunci(buf: c_uint, src: c_uint, dst: c_uint) void {
    glBlendFunci_ptr.?(buf, src, dst);
}

pub fn blendEquation(mode: c_uint) void {
    glBlendEquation_ptr.?(mode);
}

pub fn clearBufferfv(
    buffer: c_uint,
    drawbuffer: c_int,
    value: [*]const f32,
) void {
    glClearBufferfv_ptr.?(buffer, drawbuffer, value);
}

pub fn shaderSource(
    shader: c_uint,
    count: c_int,
    strings: [*]const [*:0]const u8,
    lengths: ?[*]const c_int,
) void {
    glShaderSource_ptr.?(shader, count, strings, lengths);
}

pub fn compileShader(shader: c_uint) void {
    glCompileShader_ptr.?(shader);
}

pub fn getShaderiv(shader: c_uint, pname: c_uint, params: [*c]c_int) void {
    glGetShaderiv_ptr.?(shader, pname, params);
}

pub fn getShaderInfoLog(
    shader: c.GLuint,
    bufSize: c.GLsizei,
    length: [*c]c.GLsizei,
    infoLog: [*c]c.GLchar,
) void {
    glGetShaderInfoLog_ptr.?(shader, bufSize, length, infoLog);
}

pub fn attachShader(program: c_uint, shader: c_uint) void {
    glAttachShader_ptr.?(program, shader);
}

pub fn linkProgram(program: c_uint) void {
    glLinkProgram_ptr.?(program);
}

pub fn validateProgram(program: c_uint) void {
    glValidateProgram_ptr.?(program);
}

pub fn getProgramiv(program: c_uint, pname: c_uint, params: [*]c_int) void {
    glGetProgramiv_ptr.?(program, pname, params);
}

pub fn getProgramInfoLog(
    program: c_uint,
    bufSize: c_int,
    length: [*]c_int,
    infoLog: [*]u8,
) void {
    glGetProgramInfoLog_ptr.?(program, bufSize, length, infoLog);
}

pub fn genBuffers(n: c_int, buffers: [*]c_uint) void {
    glGenBuffers_ptr.?(n, buffers);
}

pub fn genVertexArrays(n: c_int, arrays: [*c]c_uint) void {
    glGenVertexArrays_ptr.?(n, arrays);
}

pub fn getAttribLocation(program: c_uint, name: [*:0]const u8) c_int {
    return glGetAttribLocation_ptr.?(program, name);
}

pub fn bindVertexArray(array: c_uint) void {
    glBindVertexArray_ptr.?(array);
}

pub fn enableVertexAttribArray(index: c_uint) void {
    glEnableVertexAttribArray_ptr.?(index);
}

pub fn vertexAttribPointer(
    index: c_uint,
    size: c_int,
    type_: c_uint,
    normalized: u8,
    stride: c_int,
    pointer: ?*const anyopaque,
) void {
    glVertexAttribPointer_ptr.?(index, size, type_, normalized, stride, pointer);
}

pub fn bindBuffer(target: c_uint, buffer: c_uint) void {
    glBindBuffer_ptr.?(target, buffer);
}

pub fn bindBufferBase(
    target: c_uint,
    index: c_uint,
    buffer: c_uint,
) void {
    glBindBufferBase_ptr.?(target, index, buffer);
}

pub fn bufferData(
    target: c_uint,
    size: isize,
    data: ?*const anyopaque,
    usage: c_uint,
) void {
    glBufferData_ptr.?(target, size, data, usage);
}

pub fn getVertexAttribPointerv(
    index: c_uint,
    pname: c_uint,
    pointer: [*]?*anyopaque,
) void {
    glGetVertexAttribPointerv_ptr.?(index, pname, pointer);
}

pub fn useProgram(program: c_uint) void {
    glUseProgram_ptr.?(program);
}

pub fn deleteVertexArrays(n: c_int, arrays: [*]const c_uint) void {
    glDeleteVertexArrays_ptr.?(n, arrays);
}

pub fn deleteBuffers(n: c_int, buffers: [*]const c_uint) void {
    glDeleteBuffers_ptr.?(n, buffers);
}

pub fn detachShader(program: c_uint, shader: c_uint) void {
    glDetachShader_ptr.?(program, shader);
}

pub fn drawElementsInstanced(
    mode: c_uint,
    count: c_int,
    type_: c_uint,
    indices: ?*const anyopaque,
    instancecount: c_int,
) void {
    glDrawElementsInstanced_ptr.?(mode, count, type_, indices, instancecount);
}

pub fn generateMipmap(target: c_uint) void {
    glGenerateMipmap_ptr.?(target);
}

pub fn debugMessageCallback(
    callback: *const fn (
        c_uint,
        c_uint,
        c_uint,
        c_uint,
        c_int,
        [*c]const u8,
        ?*const anyopaque,
    ) callconv(.c) void,
    userParam: ?*const anyopaque,
) void {
    if (comptime builtin.target.os.tag != .macos) {
        glDebugMessageCallback_ptr.?(callback, userParam);
    } else {
        std.debug.print("glDebugMessageCallback is a function from OpenGL 4.3+ (macOS max. OpenGL version: 4.1)\n", .{});
    }
}
