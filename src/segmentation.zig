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
seg_shader: raylib.Shader,
err_shader: raylib.Shader,
buf_a: raylib.RenderTexture2D,
buf_b: raylib.RenderTexture2D,

pub fn new(alc: std.mem.Allocator, depth: u32) !Self {
    const camera = try cam.getCam(.{
        .props = &.{
            .{.EXPOSURE, 0.5},
            .{.CONTRAST, 0},
            .{.GAIN, 0},
            .{.SHARPNESS, 0},
            .{.BACKLIGHTCOMP, 0},
            .{.SATURATION, 0},
            .{.WHITEBALANCE, 0.5},
            .{.GAMMA, 0},
            .{.ZOOM, 1},
        },
    });
    const info = camera.dimensions();
    const buf = try alc.alloc(u8, info.width * info.height * 3);
    const seg_shader = raylib.LoadShader(
        "assets/shaders/vertex.glsl",
        "assets/shaders/segmentation.glsl",
    );
    const err_shader = raylib.LoadShader(
        "assets/shaders/vertex.glsl",
        "assets/shaders/errode.glsl",
    );
    const tex3d = Texture3D.new(.{
        .width = @intCast(info.width),
        .height = @intCast(info.height),
        .depth = @intCast(depth),
    });

    const buf_a = raylib.LoadRenderTexture(@intCast(info.width), @intCast(info.height));
    const buf_b = raylib.LoadRenderTexture(@intCast(info.width), @intCast(info.height));

    tex3d.send(seg_shader.id, "texture0");
    try camera.getFrame(buf); //to work around undefined behaviour in openpnp
    return .{
        .dummy = raylib.Texture2D {
            .id = raylib.rlGetTextureIdDefault(),
            .width = tex3d.width,
            .height = tex3d.height,
            .mipmaps = 1, 
            .format = tex3d.format
        }, //this feels kind of likely to cause bugs
        .cam = camera,
        .buf = buf,
        .texture = tex3d,
        .alc = alc,
        .seg_shader = seg_shader,
        .err_shader = err_shader,
        .buf_a = buf_a,
        .buf_b = buf_b,
    };
}

pub fn update(self: *Self) !void {
    if (!self.cam.isReady()) return;
    try self.cam.getFrame(self.buf);
    self.texture.set_frame(
        self.head,
        self.buf.ptr
    );
    raylib.SetShaderValue(
        self.seg_shader,
        raylib.GetShaderLocation(self.seg_shader, "head"),
        &self.head,
        raylib.ShaderUniformDataType.SHADER_UNIFORM_INT,
    );
    self.head = (self.head + 1) % @as(u32, @intCast(self.texture.depth));

}
fn ping_pong(self: Self) void {
    var a = self.buf_a;
    var b = self.buf_b;
    for (0..3) |i| {
        if (i%2==0) {
            a = self.buf_b;
            b = self.buf_a;
        } else {
            a = self.buf_a;
            b = self.buf_b;
        }
        raylib.BeginTextureMode(a);
        raylib.ClearBackground(raylib.BLACK);
        raylib.BeginShaderMode(self.err_shader);
            raylib.DrawTexture(b.texture, 0, 0, raylib.WHITE);
        raylib.EndTextureMode();
        raylib.EndShaderMode();
    }
}

fn segment(self: Self) void {
    raylib.BeginTextureMode(self.buf_a);
        //this creates a kind of nice fade away effect
        //if you delete it
        raylib.ClearBackground(raylib.BLACK);
        raylib.BeginShaderMode(self.seg_shader);
        raylib.DrawTexture(self.dummy, 0, 0, raylib.WHITE);
        raylib.EndShaderMode();
    raylib.EndTextureMode();
}

pub fn draw(self: Self) void {
    self.segment();
//    self.ping_pong();
    raylib.DrawTexture(self.buf_a.texture, 0, 0, raylib.WHITE);
}

pub fn deinit(self: *Self) void {
    self.cam.deinit() catch |err| {
        std.debug.print("error: {any}\n", .{err});
    };
    self.alc.free(self.buf);
    self.texture.deinit();
    //free textures
}

