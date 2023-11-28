const raylib = @import("raylib");
const cam = @import("camera.zig");
const std = @import("std");

const cos = std.math.cos;
const sin = std.math.sin;

const Self = @This();

screen: raylib.Texture2D,
cam: cam.Source,
image: raylib.Image,
buf: []u8,
samples: std.ArrayList([3]f32),
alc: std.mem.Allocator,
is_done: bool = false,

pub fn new(alc: std.mem.Allocator, camera: cam.Source) !Self {
    const info = camera.dimensions();
    const buf = try alc.alloc(u8, info.width * info.height * 4);

    const img = raylib.Image {
            .data = buf.ptr,
            .width = @intCast(info.width),
            .height = @intCast(info.height),
            .mipmaps = 1,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
    };
    const tex = raylib.LoadTextureFromImage(img);
    try camera.getFrame(buf); //to work around undefined behaviour in openpnp
    return .{
        .alc = alc,
        .screen = tex,
        .cam = camera,
        .image = img,
        .samples = std.ArrayList([3]f32).init(alc),
        .buf = buf,
    };
}

const cross = [4]raylib.Vector2{
    .{.x=-5, .y=0}, .{.x=5,  .y=0},
    .{.x=0,  .y=-5}, .{.x=0,  .y=5},
};

fn color_at_pt(self: Self, pt: raylib.Vector2, kernel: u32) raylib.Vector4 {
    const w : u32 = @intCast(self.image.width);
    const sw : f32 = @floatFromInt(raylib.GetScreenWidth());
    const sh : f32 = @floatFromInt(raylib.GetScreenHeight());
    const bw : f32 = @floatFromInt(self.image.width);
    const bh : f32 = @floatFromInt(self.image.height);
    var sum : struct{r: u32=0, g: u32=0, b: u32=0} = .{};
    const mx : u32 = @intFromFloat(pt.x / sw * bw);
    const my : u32 = @intFromFloat(pt.y / sh * bh);
    for (0..kernel) |y| {
        for (0..kernel) |x| {
            const i = ((y+my) * w + (x+mx)) * 3;
            sum.r += self.buf[(i+0) % self.buf.len];
            sum.g += self.buf[(i+1) % self.buf.len];
            sum.b += self.buf[(i+2) % self.buf.len];
        }
    }
    const samples = kernel*kernel;
    return .{
        .x = @as(f32, @floatFromInt(sum.r/samples))/255,
        .y = @as(f32, @floatFromInt(sum.g/samples))/255,
        .z = @as(f32, @floatFromInt(sum.b/samples))/255,
        .w = 1.0,
    };
}

pub fn update(self: *Self) !void {
    try self.cam.getFrame(self.buf);
    const mpos = raylib.GetMousePosition();
    if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
        const color = self.color_at_pt(mpos, 4);
        std.debug.print("collected {}, {}, {}, at mpoint {} {}\n", .{color.x, color.y, color.z, mpos.x, mpos.y});
        try self.samples.append(.{color.x, color.y, color.z});
    }
    if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_BACKSPACE)) {
        const col = self.samples.popOrNull();
        std.debug.print("deleted last colour entry: {any}\n", .{col});
    } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_ENTER)) {
        std.debug.print("we're done here\n", .{});
        self.is_done = true;
    }
}

pub fn draw(self: Self) !void {
    const mpos = raylib.GetMousePosition();
    raylib.UpdateTexture(self.screen, self.buf.ptr);
    raylib.DrawTexture(self.screen, 0, 0, raylib.WHITE);
    const mcolor = self.color_at_pt(mpos, 4);
    raylib.DrawRectangle(0, 0, 30, 30, raylib.ColorFromNormalized(mcolor));
    raylib.DrawLineV(cross[0].add(mpos), cross[1].add(mpos), raylib.RED);
    raylib.DrawLineV(cross[2].add(mpos), cross[3].add(mpos), raylib.RED);
}

pub fn isDone(self: Self) bool {
    return self.is_done;
}

pub fn deinit(self: *Self) void {
    self.alc.free(self.buf);
    raylib.UnloadTexture(self.screen);
}
