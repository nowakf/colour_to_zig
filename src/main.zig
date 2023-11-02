const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;
const raylib = @import("raylib");
const segmentation = @import("segmentation.zig");

const ArgParser = @import("argparse.zig").ArgParser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alc = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };



    raylib.InitWindow(800, 400, "window");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    var segger = try segmentation.new(alc, 8);
    defer segger.deinit();

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);

        try segger.update();

        segger.draw();


        raylib.DrawFPS(10, 10);
    }
}
