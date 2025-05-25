const std = @import("std");
const testing = std.testing;
const io = @import("io.zig");

test "File open, write, read, and close" {
    const test_path = "test.txt";
    const test_content = "Hello, World!";

    // Create a test file
    {
        var file = try io.File.create(test_path, .{});
        defer file.close();

        try file.write(test_content);
    }

    // Read and verify content
    {
        var file = try io.File.open(test_path, .{});
        defer file.close();

        const content = try file.read(testing.allocator);
        defer testing.allocator.free(content);

        try testing.expectEqualStrings(test_content, content);
    }

    // Cleanup
    try std.fs.cwd().deleteFile(test_path);
}

test "File error handling" {
    // Try to open non-existent file
    const result = io.File.open("nonexistent.txt", .{});
    try testing.expectError(error.FileNotFound, result);

    // Try to write to read-only file
    const test_path = "readonly.txt";
    {
        // First create the file
        var file = try io.File.create(test_path, .{});
        file.close();

        // Reopen in read-only mode
        file = try io.File.open(test_path, .{ .mode = .read_only });
        defer file.close();

        try testing.expectError(error.AccessDenied, file.write("test"));
    }

    // Cleanup
    try std.fs.cwd().deleteFile(test_path);
}

test "File createAndOpen" {
    const test_path = "createandopen.txt";
    const test_content = "Hello, World!";
    
    // First use - should create the file
    {
        var file = try io.File.createAndOpen(test_path, .{ .mode = .read_write });
        defer file.close();
        try file.write(test_content);
    }

    // Second use - should open existing file
    {
        var file = try io.File.createAndOpen(test_path, .{ .mode = .read_only });
        defer file.close();
        
        const content = try file.read(testing.allocator);
        defer testing.allocator.free(content);
        
        try testing.expectEqualStrings(test_content, content);
    }

    // Test with read-only mode on existing file
    {
        var file = try io.File.createAndOpen(test_path, .{ .mode = .read_only });
        defer file.close();
        
        try testing.expectError(error.AccessDenied, file.write("test"));
    }

    // Cleanup
    try std.fs.cwd().deleteFile(test_path);
}

test "File copy" {
    const source_path = "source.txt";
    const dest_path = "dest.txt";
    const test_content = "Hello, World!";

    // Create and write to source file
    {
        var file = try io.File.create(source_path, .{});
        defer file.close();
        try file.write(test_content);
    }

    // Copy file
    try io.File.copyFile(testing.allocator, source_path, dest_path);

    // Verify destination content
    {
        var file = try io.File.open(dest_path, .{});
        defer file.close();

        const content = try file.read(testing.allocator);
        defer testing.allocator.free(content);

        try testing.expectEqualStrings(test_content, content);
    }

    // Cleanup both files
    try std.fs.cwd().deleteFile(source_path);
    try std.fs.cwd().deleteFile(dest_path);
}
