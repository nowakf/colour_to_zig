const builtin = @import("builtin");
const std = @import("std");

const moore = @import("moore.zig");
const cam = @import("cam.zig");
const img = @import("img.zig");
const File = std.fs.File;
const ArgParser = @import("argparse.zig").ArgParser;

const Camera = @import("camera/Camera.zig").Camera;

const raylib = @import("raylib");

const WIDTH = 640;
const HEIGHT = 480;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alc = gpa.allocator();
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    const camera_config = if (builtin.os.tag == .linux)
        .{ .fourcc = std.mem.bytesAsValue(u32, "MJPG").* }
    else
        .{};

    const camera = try cam.getCam(camera_config);
    const info = camera.info;

    var pixels = try alc.alloc(u8, info.width * info.height * 3);
    defer alc.free(pixels);

    var channels: [3][]u8 = .{
        try alc.alloc(u8, pixels.len / 3),
    } ** 3;
    defer {
        for (channels) |chan| {
            alc.free(chan);
        }
    }

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

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        // const h: f32 = @floatFromInt(raylib.GetScreenHeight());
        // const mouse: u8 = @intFromFloat(@max(@min(@as(f32, @floatFromInt(raylib.GetMouseY())) / h * 255, 255), 0));
        // const left: u8 = @intCast(mouse -% 10);
        // const right: u8 = @intCast(mouse +% 10);

        raylib.ClearBackground(raylib.BLACK);

        try camera.getFrame(pixels);

        img.pix_map(pixels, img.rgb2hsv);

        // try img.split_channels(3, channels, pixels);

        // var hist = img.histogram(256, channels[0]);
        // img.histogram_to_cumulative(&hist);

        // for (channels[0], 0..) |v1, i| {
        //     const v = img.histogram_equalization(16, 16, hist, v1);
        //     channels[0][i] = img.clamp(v, left, right);
        // }

        // try img.splat_channel(pixels, channels[0]);

        raylib.UpdateTexture(texture, pixels.ptr);

        // raylib.BeginShaderMode(shader);
        raylib.DrawTexture(texture, 0, 0, raylib.WHITE);
        // raylib.EndShaderMode();

        raylib.DrawFPS(10, 10);
    }
}
