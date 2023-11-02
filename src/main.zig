const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;
const raylib = @import("raylib");

const moore = @import("moore.zig");
const cam = @import("camera.zig");
const img = @import("img.zig");
const ArgParser = @import("argparse.zig").ArgParser;

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

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        try camera.getFrame(pixels);

        raylib.BeginShaderMode(shader);

        raylib.EndShaderMode();

        raylib.DrawFPS(10, 10);
    }
}
