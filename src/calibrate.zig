const raylib = @import("raylib");
const cam = @import("camera.zig");
const std = @import("std");

const cos = std.math.cos;
const sin = std.math.sin;

const Self = @This();
const KERNEL : u32 = 3;

screen: raylib.Texture2D,
cam: cam.Source,
image: raylib.Image,
buf: []u8,
samples: std.ArrayList(u8),
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
        .samples = std.ArrayList(u8).init(alc),
        .buf = buf,
    };
}

const cross = [4]raylib.Vector2{
    .{.x=-5, .y=0}, .{.x=5,  .y=0},
    .{.x=0,  .y=-5}, .{.x=0,  .y=5},
};

pub fn update(self: *Self) !void {
    try self.cam.getFrame(self.buf);
    const mpos = raylib.GetMousePosition();
    const sw : f32 = @floatFromInt(raylib.GetScreenWidth());
    const sh : f32 = @floatFromInt(raylib.GetScreenHeight());
    const bw : f32 = @floatFromInt(self.image.width);
    const bh : f32 = @floatFromInt(self.image.height);
    var sum : struct{r: u32=0, g: u32=0, b: u32=0} = .{};
    const mx : u32 = @intFromFloat(mpos.x / sw * bw);
    const my : u32 = @intFromFloat(mpos.y / sh * bh);
    const raw_width : u32 = @intCast(self.image.width * 3);
    for (0..KERNEL) |y| {
        for (0..KERNEL) |x| {
            const i = (y+my) * raw_width + (x+mx) * 3;
            sum.r += self.buf[(i+0) % self.buf.len];
            sum.g += self.buf[(i+1) % self.buf.len];
            sum.b += self.buf[(i+2) % self.buf.len];
        }
    }
    const samples = KERNEL*KERNEL;
    if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
        const color = [3]u8{
            @intCast(sum.r/samples),
            @intCast(sum.g/samples),
            @intCast(sum.b/samples)
        };
        std.debug.print("collected {}, {}, {}, at mpoint {} {}\n", .{color[0], color[1], color[2], mx, my});
        try self.samples.appendSlice(&color);
    }
    if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_BACKSPACE)) {
        const colb = self.samples.popOrNull();
        const colg = self.samples.popOrNull();
        const colr = self.samples.popOrNull();
        std.debug.print("deleted last colour entry: {any} {any} {any}\n", .{colr, colg, colb});
    } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_ENTER)) {
        std.debug.print("we're done here\n", .{});
        self.is_done = true;
    }
}

pub fn draw(self: Self) !void {
    const mpos = raylib.GetMousePosition();
    raylib.UpdateTexture(self.screen, self.buf.ptr);
    raylib.DrawTexture(self.screen, 0, 0, raylib.WHITE);
    raylib.DrawLineV(cross[0].add(mpos), cross[1].add(mpos), raylib.RED);
    raylib.DrawLineV(cross[2].add(mpos), cross[3].add(mpos), raylib.RED);
}

pub fn isDone(self: Self) bool {
    return self.is_done;
}
