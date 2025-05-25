const std = @import("std");

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

    pub fn copyFile(allocator: std.mem.Allocator, source_path: []const u8, dest_path: []const u8) !void {
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
