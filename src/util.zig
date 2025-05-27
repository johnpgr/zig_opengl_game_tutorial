const builtin = @import("builtin");
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

pub const BumpAllocator = struct {
    buffer: []u8,
    fba: std.heap.FixedBufferAllocator,

    pub fn init(size: usize) !BumpAllocator {
        const buffer = try std.heap.page_allocator.alloc(u8, size);
        return BumpAllocator{
            .buffer = buffer,
            .fba = std.heap.FixedBufferAllocator.init(buffer),
        };
    }

    pub fn deinit(self: *BumpAllocator) void {
        std.heap.page_allocator.free(self.buffer);
    }

    pub fn allocator(self: *BumpAllocator) std.mem.Allocator {
        return self.fba.allocator();
    }

    pub fn reset(self: *BumpAllocator) void {
        self.fba.reset();
    }

    pub fn alloc(self: *BumpAllocator, comptime T: type) !*T {
        return try self.fba.allocator().create(T);
    }

    pub fn allocSlice(self: *BumpAllocator, comptime T: type, size: usize) ![]T {
        return try self.fba.allocator().alloc(T, size);
    }
};

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

pub fn getSharedLibExt() []const u8 {
    if (comptime builtin.os.tag == .windows) {
        return ".dll";
    } else if (comptime builtin.os.tag == .macos) {
        return ".dylib";
    } else {
        return ".so";
    }
}
