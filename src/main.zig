const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;

const ArgParser = @import("argparse.zig").ArgParser;
const AudioProcessor = @import("audio.zig").AudioProcessor;
const cam = @import("camera.zig");
const img = @import("img.zig");
const moore = @import("moore.zig");
const segmentation = @import("segmentation.zig");

const raylib = @import("raylib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    raylib.InitWindow(800, 400, "window");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    var segger = try segmentation.new(allocator, 16);
    defer segger.deinit();

    var audio_processor = AudioProcessor.init();
    defer audio_processor.deinit();
    audio_processor.play();

    while (!raylib.WindowShouldClose()) {
        try audio_processor.update();

        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        try segger.update();

        segger.draw();

        raylib.DrawFPS(10, 10);
    }
}
