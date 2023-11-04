const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;

const AudioProcessor = @import("audio.zig").AudioProcessor;
const moore = @import("moore.zig");
const cam = @import("camera.zig");
const img = @import("img.zig");
const ArgParser = @import("argparse.zig").ArgParser;

const raylib = @import("raylib");

const WIDTH = 640;
const HEIGHT = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    const camera = try cam.getCam(.{});
    const info = camera.dimensions();

    var pixels = try allocator.alloc(u8, info.width * info.height * 3);
    defer allocator.free(pixels);

    raylib.InitWindow(WIDTH, HEIGHT, "window");
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
    var texture = raylib.LoadTextureFromImage(image);
    defer raylib.UnloadTexture(texture);

    var audio_processor = try AudioProcessor.new();
    defer audio_processor.free();
    audio_processor.play();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        try camera.getFrame(pixels);
        raylib.UpdateTexture(texture, pixels.ptr);

        raylib.BeginShaderMode(shader);
        raylib.DrawTexture(texture, 0, 0, raylib.WHITE);
        raylib.EndShaderMode();

        raylib.DrawFPS(10, 10);
    }
}
