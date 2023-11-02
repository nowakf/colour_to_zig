const Texture3D = @import("texture3d.zig");
const raylib = @import("raylib");
const cam = @import("camera.zig");
const std = @import("std");

const Self = @This();

//maybe should be switched for a valid texture of some kind
dummy: raylib.Texture2D,
cam: cam.Source,
buf: []u8,
head: u32 = 0,
texture: Texture3D,
alc: std.mem.Allocator,
shader: raylib.Shader,

pub fn new(alc: std.mem.Allocator, depth: u32) !Self {
    const camera = try cam.getCam(.{});
    const info = camera.dimensions();
    const buf = try alc.alloc(u8, info.width * info.height * 3);
    const segmentation_shader = raylib.LoadShader(
        "assets/shaders/vertex.glsl",
        "assets/shaders/segmentation.glsl",
    );
    const tex3d = Texture3D.new(.{
        .width = @intCast(info.width),
        .height = @intCast(info.height),
        .depth = @intCast(depth),
    });
    tex3d.send(segmentation_shader.id, "texture0");
    try camera.getFrame(buf); //to work around undefined behaviour in openpnp
    return .{
        .dummy = raylib.Texture2D {
            .id = raylib.rlGetTextureIdDefault(),
            .width = tex3d.width,
            .height = tex3d.height,
            .mipmaps = 1, //?
            .format = tex3d.format
        }, //this feels kind of likely to cause bugs
        .cam = camera,
        .buf = buf,
        .texture = tex3d,
        .alc = alc,
        .shader = segmentation_shader,
    };
}

pub fn update(self: *Self) !void {
    if (!self.cam.isReady()) return;
    try self.cam.getFrame(self.buf);
    self.texture.set_frame(
        self.head,
        self.buf.ptr
    );
    self.head = (self.head + 1) % @as(u32, @intCast(self.texture.depth));

}

pub fn draw(self: Self) void {
    raylib.BeginShaderMode(self.shader);
    raylib.DrawTexture(self.dummy, 0, 0, raylib.WHITE);
    raylib.EndShaderMode();
}

pub fn deinit(self: *Self) void {
    self.cam.deinit();
    self.alc.free(self.buf);
    self.texture.deinit();
}

