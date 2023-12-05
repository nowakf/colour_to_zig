const std = @import("std");

const raylib = @import("raylib");

const Cam = @import("camera.zig");
const Texture3D = @import("texture3d.zig");
const SwapBuf = @import("swap_buf.zig");
const CropBuf = @import("crop_buf.zig");
const Shader = @import("shader.zig");

const Self = @This();

head: u32 = 0,
texture: Texture3D,
dummy: raylib.Texture2D,
seg_shader: Shader,
err_shader: Shader,
crop_buf: CropBuf,
swap_buf: SwapBuf,
params: SegmentationParams,

pub fn new(image: CropBuf, depth: u32, opts: SegmentationParams) !Self {
    const seg_shader = Shader.fromPaths(
        "assets/shaders/vertex.vert",
        "assets/shaders/segmentation.frag",
    );
    const err_shader = Shader.fromPaths(
        "assets/shaders/vertex.vert",
        "assets/shaders/errode.frag",
    );
    const tex3d = Texture3D.new(.{
        .width =  @intCast(image.dst_rect.w),
        .height = @intCast(image.dst_rect.h),
        .depth = @intCast(depth),
    });

    const swap_buf = .{
        .bufs = .{
            raylib.LoadRenderTexture(@intCast(image.dst_rect.w), @intCast(image.dst_rect.h)),
            raylib.LoadRenderTexture(@intCast(image.dst_rect.w), @intCast(image.dst_rect.h)),
        },
    };

    tex3d.send(seg_shader.inner.id, "texture0");
    try seg_shader.send(SegmentationParams, opts, null);
    return .{
        .texture = tex3d,
        .dummy = raylib.LoadTextureFromImage(.{
            .data = image.buf.ptr,
            .width = @intCast(image.dst_rect.w),
            .height = @intCast(image.dst_rect.h),
            .mipmaps = 1,
            .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
            }),
        .seg_shader = seg_shader,
        .err_shader = err_shader,
        .params = opts,
        .crop_buf = image,
        .swap_buf = swap_buf,
    };
}

//this should be kept in sync with the uniforms in 
//assets/shaders/segmentation.glsl
const SegmentationParams = struct {
    colour_cone_width: f32 = 0.10,
    brightness_margin_width: f32 = 0.1,
    //this should be a vector
    //and the shader should have a 'vec_len' uniform.
    colours_of_interest: []const [3]f32 = &.{
        .{1, 0, 0},
    }
};

pub fn update_settings(self: *Self, params: SegmentationParams) !void {
    self.params = params;
    try self.seg_shader.send(self.params);
}

pub fn process(self: *Self) !raylib.Texture2D {
    self.crop_buf.update();

    self.texture.set_frame(
        self.head,
        self.crop_buf.buf.ptr
    );

    //try self.seg_shader.send(u32, self.head, "head");

    self.segment();

    self.errode();

    self.head = (self.head + 1) % @as(u32, @intCast(self.texture.depth));

    return self.swap_buf.getLast();

}

fn segment(self: *Self) void {
    self.seg_shader.begin();
        self.swap_buf.setInitial(self.dummy);
    self.seg_shader.end();
}

fn errode(self: *Self) void {
    self.err_shader.begin();
        self.swap_buf.run(8);
    self.err_shader.end();
}

pub fn debugDraw(self: *Self) !void {
    const e = try self.process();
    raylib.DrawTexturePro(
        e,
        .{
            .x=0,
            .y=0,
            .width=@floatFromInt(self.crop_buf.dst_rect.w),
            .height=@floatFromInt(self.crop_buf.dst_rect.h),
        },
        .{
            .x=0,
            .y=0,
            .width=@floatFromInt(raylib.GetScreenWidth()),
            .height=@floatFromInt(raylib.GetScreenHeight()),
        },
        .{.x=0,.y=0},
        0,
        raylib.WHITE,
    );
}

pub fn deinit(self: *Self) void {
    self.texture.deinit();
    //free textures
}

