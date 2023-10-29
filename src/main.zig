const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;
const raylib = @import("raylib");

const moore = @import("moore.zig");
const cam = @import("camera.zig");
const img = @import("img.zig");
const ArgParser = @import("argparse.zig").ArgParser;
const TextureStack = @import("texture_stack.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alc = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    const camera = try cam.getCam(.{});
    const info = camera.dimensions();

    var pixels = try alc.alloc(u8, info.width * info.height * 3);
    defer alc.free(pixels);

    raylib.InitWindow(@intCast(info.width), @intCast(info.height), "window");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    const shader = raylib.LoadShader(
        "assets/shaders/vertex.glsl",
        "assets/shaders/fragment.glsl",
    );
    defer raylib.UnloadShader(shader);

    var image = raylib.Image{
        .data = @ptrCast(@constCast(pixels.ptr)),
        .width = @intCast(info.width),
        .height = @intCast(info.height),
        .mipmaps = 1,
        .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
    };

    var stack = try TextureStack.new(shader, image);
    defer stack.deinit();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        try camera.getFrame(pixels);

        stack.push(pixels.ptr);

        raylib.BeginShaderMode(shader);
        stack.send(shader);

        raylib.DrawTexture(stack.getHead(), 0, 0, raylib.RED);
        raylib.EndShaderMode();

        raylib.DrawFPS(10, 10);
    }
}
