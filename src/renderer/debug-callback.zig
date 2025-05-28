const c = @import("c");
const builtin = @import("builtin");
const std = @import("std");

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
