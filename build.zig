const std = @import("std");
const LazyPath = std.build.LazyPath;

const raylib = @import("vendor/raylib/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-video",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });


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

    b.installArtifact(opnpc);

    exe.linkLibrary(opnpc);
    exe.addIncludePath(.{ .path = "vendor/openpnp-capture/include" });
    raylib.addTo(b, exe, target, optimize);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());


    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

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
