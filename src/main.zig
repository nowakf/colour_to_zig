const builtin = @import("builtin");
const std = @import("std");
const File = std.fs.File;

const ArgParser = @import("argparse.zig").ArgParser;
const AudioProcessor = @import("audio/processor.zig").AudioProcessor;
const Cam = @import("camera.zig");
const img = @import("img.zig");
const moore = @import("moore.zig");
const segmentation = @import("segmentation.zig");
const calibrator = @import("calibrate.zig");
const Display = @import("display.zig");

const raylib = @import("raylib");

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn calibrate(alc: std.mem.Allocator, camera: Cam) !calibrator.Calibration {
    var calib = try calibrator.new(alc, camera);
    //callibration loop:
    while (!calib.isDone() and !raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        raylib.ClearBackground(raylib.BLACK);
        try calib.update();
        try calib.draw();
    }
    return calib.finish();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    var prng = std.rand.DefaultPrng.init(0);
    var rand = prng.random();
    //raylib.SetTraceLogLevel(4);
    raylib.SetConfigFlags(.{
        .FLAG_WINDOW_RESIZABLE = true,
    });
    raylib.InitWindow(800, 400, "window");
    defer raylib.CloseWindow();
    raylib.SetTargetFPS(60);
    const camera = try Cam.Camera(allocator, .{
        .name = "HD USB Camera: HD USB Camera",
        .fourcc = Cam.fourcc("MJPG"),
        .dimensions = .{ 1280, 720, 60 },
        .props = &.{},
    });
    defer camera.deinit();
    const calibration = try calibrate(allocator, camera);

    defer calibration.deinit();

    var segger = try segmentation.new(calibration.crop, 5, .{
        .colours_of_interest = calibration.samples,
    });
    defer segger.deinit();

    var audio_processor = try AudioProcessor.init(allocator, &rand, &camera);
    audio_processor.play();
    defer audio_processor.deinit(allocator);

    var display = Display.new();
    while (!raylib.WindowShouldClose()) {
        try camera.updateFrame();
        display.update();
        const segmented = try segger.process();
        raylib.BeginDrawing();
        raylib.ClearBackground(raylib.BLACK);
        audio_processor.update();
        display.draw(segmented);
        raylib.DrawFPS(10, 10);
        raylib.EndDrawing();
    }
}
