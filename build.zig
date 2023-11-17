const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-video",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const opnpc = openpc(b, target, optimize);
    b.installArtifact(opnpc);
    exe.linkLibrary(opnpc);
    exe.addIncludePath(.{ .path = "vendor/openpnp-capture/include" });

    raylib_build_bindings(b, exe, target, optimize);
    link_raylib_object(b, exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());


    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}


fn openpc(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) *std.build.LibExeObjStep {
    const opnpc_common_cpp_src_files = [_][]const u8{
        "vendor/openpnp-capture/common/context.cpp",
        "vendor/openpnp-capture/common/libmain.cpp",
        "vendor/openpnp-capture/common/logging.cpp",
        "vendor/openpnp-capture/common/stream.cpp",
    };

    const opnpc_linux_cpp_src_files = [_][]const u8{
        "vendor/openpnp-capture/linux/mjpeghelper.cpp",
        "vendor/openpnp-capture/linux/platformcontext.cpp",
        "vendor/openpnp-capture/linux/platformstream.cpp",
        "vendor/openpnp-capture/linux/yuvconverters.cpp",
    };

    const opnpc_objective_c_src_files = [_][]const u8{
        "vendor/openpnp-capture/mac/platformcontext.mm",
        "vendor/openpnp-capture/mac/platformstream.mm",
        "vendor/openpnp-capture/mac/uvcctrl.mm",
    };
    // OPENPNP CAPTURE
    const opnpc = b.addStaticLibrary(.{
        .name = "zig-openpnp-capture",
        .target = target,
        .optimize = optimize,
    });

    const t = opnpc.target_info.target;

    opnpc.linkLibC();
    opnpc.linkLibCpp();

    opnpc.addIncludePath(.{ .path = "vendor/openpnp-capture/include" });
    opnpc.addCSourceFiles(.{ .files = &opnpc_common_cpp_src_files });

    const opnpc__config_header = b.addConfigHeader(.{
        .style = .{
            .cmake = .{
                .path = "vendor/openpnp-capture/cmake/version.h.in",
            },
        },
    }, .{
        .GITVERSION = null,
    });
    opnpc.addConfigHeader(opnpc__config_header);
    opnpc.installConfigHeader(opnpc__config_header, .{});

    switch (t.os.tag) {
        .linux => {
            opnpc.linkSystemLibrary("turbojpeg");
            opnpc.addCSourceFiles(.{
                .files = &opnpc_linux_cpp_src_files,
            });
        },
        .macos => {
            opnpc.addCSourceFiles(.{
                .files = &opnpc_objective_c_src_files,
                // .flags = &.{"-fobjc-arc"},
                .flags = &.{"-fno-objc-arc"},
            });
            opnpc.linkFramework("AVFoundation");
            opnpc.linkFramework("Foundation");
            opnpc.linkFramework("CoreMedia");
            opnpc.linkFramework("CoreVideo");
            opnpc.linkFramework("Accelerate");
            opnpc.linkFramework("IOKit");
        },
        else => {},
    }
    return opnpc;
}

//this is all horrible copy paste because I don't understand zig build system:
const raylib_root = "vendor/raylib";
const dir_raylib = raylib_root ++ "/raylib/src";
const raylib = @import("vendor/raylib/raylib/src/build.zig");

fn link_raylib_object(b: *std.Build, exe: *std.build.LibExeObjStep) void {
    const raylib_cmd = b.addSystemCommand(&[_][]const u8{
        "make",
        "--directory=" ++ dir_raylib
    });
    const make_directives = b.option([]const u8, "make_cmd", "passthrough quoted options to make") orelse "";
    var args = std.mem.splitAny(u8, make_directives, " ");
    while (args.next()) |arg| {
        raylib_cmd.addArg(arg);
    }
    exe.step.dependOn(&raylib_cmd.step);
    exe.addObjectFile(.{.path = dir_raylib ++ "/libraylib.a"});
}


fn raylib_wrapper(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.Mode) *std.build.LibExeObjStep {
    const lib = b.addStaticLibrary(.{ .name = "raylib-zig", .target = target, .optimize = optimize });
    lib.addIncludePath(.{ .path = dir_raylib });
    lib.addIncludePath(.{ .path = raylib_root });
    lib.linkLibC();
    lib.addCSourceFile(.{ .file = .{ .path = raylib_root ++ "/marshal.c" }, .flags = &.{} });
    return lib;
}

fn raylib_build_bindings(b: *std.Build, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, optimize: std.builtin.Mode) void {
    exe.addAnonymousModule("raylib", .{ .source_file = .{ .path = raylib_root ++ "/raylib.zig" } });
    exe.addIncludePath(.{ .path = dir_raylib });
    exe.addIncludePath(.{ .path = raylib_root });
    const lib = raylib_wrapper(b, target, optimize);
    exe.linkLibrary(lib);
}
