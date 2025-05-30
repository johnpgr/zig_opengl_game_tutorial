const builtin = @import("builtin");
const IVec2 = @import("math.zig").IVec2;
const Vec2 = @import("math.zig").Vec2;
const OrthographicCamera2d = @import("gpu-data.zig").OrthographicCamera2d;
const std = @import("std");

pub inline fn bit(comptime x: usize) usize {
    return 1 << x;
}

pub inline fn kb(comptime x: usize) usize {
    return x * 1024;
}

pub inline fn mb(comptime x: usize) usize {
    return kb(x) * 1024;
}

pub inline fn gb(comptime x: usize) usize {
    return mb(x) * 1024;
}

pub const File = struct {
    data: std.fs.File,
    path: []const u8,
    stats: std.fs.File.Stat,

    pub fn open(path: []const u8, mode: std.fs.File.OpenFlags) !File {
        const file = try std.fs.cwd().openFile(path, mode);
        return File{ .data = file, .path = path, .stats = try file.stat() };
    }

    pub fn close(self: File) void {
        self.data.close();
    }

    pub fn read(self: File, allocator: std.mem.Allocator) ![]u8 {
        const size = self.stats.size;
        const buffer = try allocator.alloc(u8, size);
        const bytes_read = try self.data.readAll(buffer);
        if (bytes_read != size) {
            return error.ReadError;
        }
        return buffer;
    }

    pub fn write(self: File, data: []const u8) !void {
        self.data.writeAll(data) catch |err| {
            return switch (err) {
                error.NotOpenForWriting => error.AccessDenied,
                else => err,
            };
        };
    }

    pub fn create(path: []const u8, mode: std.fs.File.CreateFlags) !File {
        const file = try std.fs.cwd().createFile(path, mode);
        return File{ .data = file, .path = path, .stats = try file.stat() };
    }

    pub fn createAndOpen(path: []const u8, mode: std.fs.File.OpenFlags) !File {
        // Try to open the file first
        return File.open(path, mode) catch |err| {
            // If file doesn't exist, create and then reopen with desired mode
            if (err == error.FileNotFound) {
                var file = try File.create(path, .{});
                file.close();
                // Reopen with requested mode
                return File.open(path, mode);
            }
            return err;
        };
    }

    pub fn copyFile(
        allocator: std.mem.Allocator,
        source_path: []const u8,
        dest_path: []const u8,
    ) !void {
        // Open source file for reading
        var source = try File.open(source_path, .{ .mode = .read_only });
        defer source.close();

        // Create destination file
        var dest = try File.create(dest_path, .{});
        defer dest.close();

        // Read source content
        const content = try source.read(allocator);
        defer allocator.free(content);

        // Write to destination
        try dest.write(content);
    }

    pub fn delete(self: File) !void {
        try std.fs.cwd().deleteFile(self.path);
    }
};

pub fn getSharedLibExt() []const u8 {
    if (comptime builtin.os.tag == .windows) {
        return ".dll";
    } else if (comptime builtin.os.tag == .macos) {
        return ".dylib";
    } else {
        return ".so";
    }
}

pub fn getLastModified(path: []const u8) !i128 {
    const file = std.fs.cwd().openFile(path, .{}) catch return 0;
    defer file.close();
    const stat = try file.stat();
    return stat.mtime;
}

pub fn rebuildLibrary(allocator: std.mem.Allocator) !void {
    const build_args = &[_][]const u8{
        "zig",
        "build",
        "-Dlib-only",
    };

    var child = std.process.Child.init(build_args, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(
        allocator,
        1024 * 1024,
    );
    defer allocator.free(stdout);

    const stderr = try child.stderr.?.readToEndAlloc(
        allocator,
        1024 * 1024,
    );
    defer allocator.free(stderr);

    const term = try child.wait();

    switch (term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Build successful!\n", .{});
                if (stdout.len > 0) {
                    std.debug.print("Build output: {s}\n", .{stdout});
                }
            } else {
                std.debug.print("Build failed with exit code: {}\n", .{code});
                if (stderr.len > 0) {
                    std.debug.print("Build error: {s}\n", .{stderr});
                }
            }
        },
        else => {
            std.debug.print("Build process terminated abnormally\n", .{});
        },
    }
}

pub fn screenToWorld(
    game_camera: OrthographicCamera2d,
    screen_dimensions: Vec2,
    screen_pos: Vec2,
) Vec2 {
    var x_pos: f32 = screen_pos.x / screen_dimensions.x *
        game_camera.dimensions.x;
    // Offset using dimensions and position
    x_pos += -game_camera.dimensions.x / 2 +
        game_camera.position.x;

    var y_pos: f32 = screen_pos.y / screen_dimensions.y *
        game_camera.dimensions.y;
    // Offset using dimensions and position
    y_pos += game_camera.dimensions.y / 2 +
        game_camera.position.y;

    return Vec2.init(x_pos, y_pos);
}
