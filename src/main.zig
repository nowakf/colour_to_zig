const builtin = @import("builtin");
const std = @import("std");

const moore = @import("moore.zig");
const cam = @import("camera.zig");
const img = @import("img.zig");
const File = std.fs.File;
const ArgParser = @import("argparse.zig").ArgParser;

const raylib = @import("raylib");

//raylib has no arraytextures :(
const TextureStack = struct {
    const Self = @This();
    const texture_prefix = "tex";
    const stack_depth = 16; //max textures allowed is 16
    textures: [stack_depth]raylib.Texture2D,
    uniforms: [stack_depth]i32,
    head: u32,

    fn new(shader: raylib.Shader, initial_image: raylib.Image) !Self {
        var textures : [stack_depth]raylib.Texture2D = undefined;
        var buf : [texture_prefix.len + 4:0]u8 = .{0} ** (texture_prefix.len + 4); 
        var uniforms : [stack_depth]i32 = undefined;
        for (0..stack_depth) |i| {
            const uni_name : [:0]const u8 = try std.fmt.bufPrintZ(&buf, "{s}{}", .{texture_prefix, i});
            const unf = raylib.GetShaderLocation(shader, uni_name.ptr);
            if (unf < 0) {
                std.debug.print("{s} uniform either undefined or unused in shader\n", .{uni_name});
            }
            uniforms[i] = unf;
            textures[i] = raylib.LoadTextureFromImage(initial_image);
        }
        return .{
            .textures = textures, 
            .uniforms = uniforms,
            .head = 0,
        };
    }
    fn deinit(self: *Self) void {
        for (self.textures) |tex| {
            raylib.UnloadTexture(tex);
        }
    }
    fn push(self: *Self, new_data: *const anyopaque) void {
        raylib.UpdateTexture(self.textures[self.head], new_data);
        self.head = (self.head + 1) % stack_depth;
    }
    fn getHead(self: Self) raylib.Texture2D {
        return self.textures[self.head];
    }
    fn send(self: Self, shader: raylib.Shader) void{
        for (self.uniforms, 0..) |loc, i| {
            raylib.SetShaderValueTexture(
                    shader,
                    loc,
                    self.textures[(self.head + i) % stack_depth],
            );
        }
    }
};

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

        stack.send(shader);

        raylib.BeginShaderMode(shader);
        std.debug.print("{any}\n", .{stack.getHead()});
        raylib.DrawTexture(stack.getHead(), 0, 0, raylib.WHITE);
        raylib.EndShaderMode();

        raylib.DrawFPS(10, 10);
    }
}
