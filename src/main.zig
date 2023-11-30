pub const std_options = struct {
    pub const log_level = .err;
};

const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;

const ArgParser = @import("argparse.zig").ArgParser;
const AudioProcessor = @import("audio.zig").AudioProcessor;
const cam = @import("camera.zig");
const img = @import("img.zig");
const moore = @import("moore.zig");
const segmentation = @import("segmentation.zig");
const calibrator = @import("calibrate.zig");

const raylib = @import("raylib");

pub fn calibrate(alc: std.mem.Allocator, camera: cam.Source) ![][3]f32 {
    var calib = try calibrator.new(alc, camera);
    defer calib.deinit();
    //callibration loop:
    while (!calib.isDone()) {
        if (raylib.WindowShouldClose()) {
            calib.samples.deinit();
            return error.CalibrationIncomplete;
        }
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        try calib.update();
        try calib.draw();
        raylib.ClearBackground(raylib.BLACK);
    }
    return calib.samples.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    raylib.SetTraceLogLevel(4);

    raylib.InitWindow(800, 400, "window");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);

    //doesn't work: annoying

    const camera = try cam.getCam(.{
        .name = "HD USB Camera: HD USB Camera",
        .fourcc = cam.fourcc("YUYV"),
        .dimensions = .{500, 500, 100},
        .props = &.{} 
    });

    const selected_colors = try calibrate(allocator, camera);

    var segger = try segmentation.new(allocator, camera, 8, .{
        .colours_of_interest = selected_colors,
    });
    allocator.free(selected_colors);
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
        raylib.DrawFPS(10,10);
    }
}
