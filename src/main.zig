const builtin = @import("builtin");
const std = @import("std");

const moore = @import("moore.zig");
const cam = @import("cam.zig");
const sod = @import("sod.zig");
const File = std.fs.File;
const ArgParser = @import("argparse.zig").ArgParser;

const Camera = @import("camera/Camera.zig").Camera;
const LinuxCamera = @import("camera/linux/LinuxCamera.zig").LinuxCamera;
const MacOSCamera = @import("camera/macos/MacOSCamera.zig").MacOSCamera;

const raylib = @import("raylib");

const WIDTH = 640;
const HEIGHT = 480;

pub fn main() !void {
     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
     const alc = gpa.allocator();
     defer if (.leak == gpa.deinit()) {
         std.debug.print("leak detected!\n", .{});
     };

    const camera = try cam.getCam(.{});
    const info = camera.info;

    var pixels = try alc.alloc(u8, info.width*info.height*3);
    defer alc.free(pixels);

    raylib.InitWindow(WIDTH, HEIGHT, "window");
    raylib.SetTargetFPS(60);

    defer raylib.CloseWindow();

    var image = raylib.Image{
        .data = @ptrCast(@constCast(pixels.ptr)),
        .width = @intCast(info.width),
        .height = @intCast(info.height),
        .mipmaps = 1,
        .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
    };
    var texture = raylib.LoadTextureFromImage(image);
    defer raylib.UnloadTexture(texture);

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.BLACK);

        try camera.getFrame(pixels);

        raylib.UpdateTexture(texture, pixels.ptr);
        raylib.DrawTexture(texture, 0, 0, raylib.WHITE);

        raylib.DrawFPS(10, 10);
    }
}
