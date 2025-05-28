const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const target_os = target.result.os.tag;

    // c_pkg is a zig module that centralizes the C imports and library linking.
    const c_pkg = b.addModule("c", .{
        .root_source_file = b.path("src/c.zig"),
        .target = target,
        .optimize = optimize,
    });
    c_pkg.linkSystemLibrary("SDL3", .{});
    c_pkg.linkSystemLibrary("SDL3_image", .{});
    c_pkg.linkSystemLibrary("SDL3_ttf", .{});

    if (target_os == .windows) {
        c_pkg.addLibraryPath(.{ .cwd_relative = "thirdparty/SDL3_3.2.14-win32-x64/" });
        c_pkg.addLibraryPath(.{ .cwd_relative = "thirdparty/SDL3_ttf-3.2.2-win32-x64/" });
        c_pkg.addLibraryPath(.{ .cwd_relative = "thirdparty/SDL3_image-3.2.4-win32-x64/" });
    }

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zig_opengl_game",
        .root_module = exe_mod,
    });

    // Choose the OpenGL API, version, profile and extensions you want to generate bindings for.
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    exe.linkLibC();
    exe.root_module.addImport("c", c_pkg);
    exe.root_module.addImport("gl", gl_bindings);

    if (target_os == .windows) {
        exe.linkSystemLibrary("opengl32");
        exe.subsystem = if (optimize != .Debug) .Windows else .Console;

        const sdl_dll_dep = b.addInstallBinFile(b.path("thirdparty/SDL3_3.2.14-win32-x64/SDL3.dll"), "SDL3.dll");
        const sdl_ttf_dll_dep = b.addInstallBinFile(b.path("./thirdparty/SDL3_ttf-3.2.2-win32-x64/SDL3_ttf.dll"), "SDL3_ttf.dll");
        const sdl_image_dll_dep = b.addInstallBinFile(b.path("./thirdparty/SDL3_image-3.2.4-win32-x64/SDL3_image.dll"), "SDL3_image.dll");

        exe.step.dependOn(&sdl_dll_dep.step);
        exe.step.dependOn(&sdl_ttf_dll_dep.step);
        exe.step.dependOn(&sdl_image_dll_dep.step);

        const copy_assets = b.addInstallDirectory(.{
            .source_dir = b.path("assets"),
            .install_dir = .bin,
            .install_subdir = "assets",
        });
        exe.step.dependOn(&copy_assets.step);
    } else if (target_os == .macos) {
        exe.linkFramework("OpenGL");
    } else {
        exe.linkSystemLibrary("GL");
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
