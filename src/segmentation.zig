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
params: SegmentationParams,

pub fn new(alc: std.mem.Allocator, camera: cam.Source, depth: u32, opts: SegmentationParams) !Self {
    const info = camera.dimensions();
    const buf = try alc.alloc(u8, info.width * info.height * 3);
    const seg_shader = raylib.LoadShader(
        "assets/shaders/vertex.vert",
        "assets/shaders/segmentation.frag",
    );
    const err_shader = raylib.LoadShader(
        "assets/shaders/vertex.vert",
        "assets/shaders/errode.frag",
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
    try send_settings(seg_shader, opts);
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
        .params = opts,
    };
}

//this should be kept in sync with the uniforms in 
//assets/shaders/segmentation.glsl
const SegmentationParams = struct {
    colour_cone_width: f32 = 0.5,
    brightness_margin_width: f32 = 0.1,
    //this should be a vector
    //and the shader should have a 'vec_len' uniform.
    colours_of_interest: []const [3]f32 = &.{
        .{1,   0,   0},
        .{0,   1,   0},
        .{0,   0,   1},
        .{1,   1,   0},
        .{0,   1,   1},
        .{1,   0,   1},
        .{0.5, 0,   1},
        .{0,   0.5, 1},
        .{1,   0.5, 0},
        .{1,   0,   0.5},
        .{0,   1,   0.5},
        .{0.5, 1,   0.5},
    },
    fn to_gl_type(comptime T: type) raylib.ShaderUniformDataType {
        return switch (T) {
            f32, f64 => raylib.ShaderUniformDataType.SHADER_UNIFORM_FLOAT,
            [2]f32, [2]f64 => raylib.ShaderUniformDataType.SHADER_UNIFORM_VEC2,
            [3]f32, [3]f64 => raylib.ShaderUniformDataType.SHADER_UNIFORM_VEC3,
            [4]f32, [4]f64 => raylib.ShaderUniformDataType.SHADER_UNIFORM_VEC4,
            i8, u8, i16, u16, i32, u32, usize => raylib.ShaderUniformDataType.SHADER_UNIFORM_INT,
            inline else => @panic("unknown type\n" ++ @typeName(T)),
        };
    }
};

pub fn update_settings(self: *Self, params: SegmentationParams) !void {
    self.params = params;
    try send_settings(self.seg_shader, self.params);
}

fn send_settings(shader: raylib.Shader, params: SegmentationParams) !void {
    raylib.BeginShaderMode(shader);
    defer raylib.EndShaderMode();
    inline for (std.meta.fields(@TypeOf(params))) |f| {
        var buf : [100]u8 = undefined;
        const name = try std.fmt.bufPrintZ(&buf, f.name, .{});
        const ty = @typeInfo(f.type);
        if (ty == .Array or ty == .Pointer) {
            raylib.SetShaderValueV(
                shader,
                raylib.GetShaderLocation(shader, name),
                if (ty == .Array) &@field(params, f.name) else @field(params, f.name).ptr,
                @intFromEnum(SegmentationParams.to_gl_type(@TypeOf(@field(params, f.name)[0]))),
                @intCast(@field(params, f.name).len)
            );
            raylib.SetShaderValue(
                shader,
                raylib.GetShaderLocation(shader, try std.fmt.bufPrintZ(&buf, "{s}_cnt", .{f.name})),
                &@field(params, f.name).len,
                SegmentationParams.to_gl_type(usize),
            );
        } else {
            raylib.SetShaderValue(
                shader,
                raylib.GetShaderLocation(shader, name),
                &@field(params, f.name),
                SegmentationParams.to_gl_type(f.type),
            );
        }
    }
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
        //if you comment it out
        //raylib.ClearBackground(raylib.BLACK);
        raylib.BeginShaderMode(self.seg_shader);
        raylib.DrawTexture(self.dummy, 0, 0, raylib.WHITE);
        raylib.EndShaderMode();
    raylib.EndTextureMode();
}

pub fn draw(self: Self) void {
    self.segment();
    self.ping_pong();
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

