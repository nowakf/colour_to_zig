const builtin = @import("builtin");
const std = @import("std");

const moore = @import("moore.zig");
const iter = @import("iter.zig");
const Stdin = iter.Stdin;
const Cam = iter.Cam;
const sod = @import("sod.zig");
const File = std.fs.File;
const ArgParser = @import("argparse.zig").ArgParser;

const Camera = @import("camera/Camera.zig").Camera;
const LinuxCamera = @import("camera/linux/LinuxCamera.zig").LinuxCamera;
const MacOSCamera = @import("camera/macos/MacOSCamera.zig").MacOSCamera;

const raylib = @import("raylib");

const WIDTH = 640;
const HEIGHT = 480;
fn tes(comptime s: anytype) s {
    return s;
}

pub fn main() !void {
    var camera = switch (builtin.target.os.tag) {
        .linux => LinuxCamera{},
        .macos => MacOSCamera{},
        else => @compileError("Platform not supported"),
    };

    camera.init();

    raylib.InitWindow(WIDTH, HEIGHT, "window");
    raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    var pixels = camera.getFrame();
    var image = raylib.Image{
        .data = @ptrCast(@constCast(pixels)),
        .width = WIDTH,
        .height = HEIGHT,
        .mipmaps = 1,
        .format = 4,
    };
    var texture = raylib.LoadTextureFromImage(image);
    defer raylib.UnloadTexture(texture);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.BLACK);

        pixels = camera.getFrame();
        raylib.UpdateTexture(texture, pixels);
        raylib.DrawTexture(texture, 0, 0, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }
    // const fields = struct {
    //     video : []const u8 = "/dev/video0",
    //     out : []const u8 = "out.png",
    //     width : u32 = 640,
    //     height : f32 = 48.0,
    // };

    // var args = std.process.args();
    // const parser = ArgParser(
    //     fields,
    //     "USAGE: if you provide an image or stream of images on stdin, that's fine. If you don't, it will try and access the camera.",
    // );
    // const out = try parser.parse(&args);
    // std.debug.print("{s}", .{parser.get_help()});

    // std.debug.print("{s}, {s}, {} {}\n", out);

    // const stdin = std.io.getStdIn();
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const alc = gpa.allocator();
    // _ = alc;
    // defer {
    //     const status = gpa.deinit();
    //     if (status == .leak) {
    //         std.debug.print("leak detected! .{}", .{status});
    //     }
    // }

    // var cam = Cam(.{}){};
    // var stn = Stdin(.{}){};

    // const frames = if (stdin.isTty())
    //     cam.iter()
    //  else
    //      stn.iter();

    // var buf = [_]u8{'t', 'e'};

    // while (frames.next(&buf) != null) {
    //     std.debug.print("?", .{});
    // }

    // return;
}
