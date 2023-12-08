const std = @import("std");

const rl = @import("raylib");

const Cam = @import("camera.zig");
const Texture3D = @import("texture3d.zig");
const SwapBuf = @import("swap_buf.zig");
const CropBuf = @import("crop_buf.zig");
const Shader = @import("shader.zig");

const Self = @This();

head: u32 = 0,
seg_shader: Shader,
crop_buf: CropBuf,
frame: rl.Texture2D,
state: SwapBuf,
params: SegmentationParams,


pub fn new(image: CropBuf, depth: u32, opts: SegmentationParams) !Self {
    _ = depth;
    const seg_shader = Shader.fromPaths(
        "assets/shaders/vertex.vert",
        "assets/shaders/segmentation.frag",
    );

    seg_shader.send(SegmentationParams, opts, null) catch |err| {
        std.log.err("{any}\n", .{err});
    };

    std.debug.print("{any}", .{opts});

    const swap_buf = .{
        .bufs = .{
            rl.LoadRenderTexture(@intCast(image.dst_rect.w), @intCast(image.dst_rect.h)),
            rl.LoadRenderTexture(@intCast(image.dst_rect.w), @intCast(image.dst_rect.h)),
        },
    };

    const frame = rl.LoadTextureFromImage(.{
            .data = image.buf.ptr,
            .width = @intCast(image.dst_rect.w),
            .height = @intCast(image.dst_rect.h),
            .mipmaps = 1,
            .format = @intFromEnum(rl.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
    });

    rl.SetTextureFilter(frame, @intFromEnum(rl.TextureFilter.TEXTURE_FILTER_BILINEAR));

    return .{
        .seg_shader = seg_shader,
        .state = swap_buf,
        .frame = frame,
        .params = opts,
        .crop_buf = image,
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
    //try self.seg_shader.send(self.params);
}

pub fn update(self: *Self) void {
    if (rl.IsKeyReleased(rl.KeyboardKey.KEY_ENTER)) {
        rl.UnloadShader(self.seg_shader.inner);
        self.seg_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/segmentation.frag");
    }
}

pub fn process(self: *Self) !rl.Texture2D {
    self.crop_buf.update();

    rl.UpdateTexture(self.frame, self.crop_buf.buf.ptr);
   
    self.seg_shader.begin();
    rl.BeginTextureMode(self.state.bufs[self.state.last_written]);
    self.state.last_written = (self.state.last_written + 1) % 2;

    self.seg_shader.sendTexture("camera_frame", self.frame) catch |err| {
        std.log.info("{any}\n", .{err});
    };

    self.seg_shader.sendTexture("state", self.state.bufs[self.state.last_written].texture) catch |err| {
        std.log.info("{any}\n", .{err});
    };

    rl.DrawTexturePro(self.frame,
        .{.x=0, .y=0, .width=@floatFromInt(self.frame.width), .height=@floatFromInt(self.frame.height)},
        .{.x=0, .y=0, .width=@floatFromInt(self.frame.width), .height=@floatFromInt(self.frame.height)},
        .{},
        0,
        rl.WHITE
        );


    rl.EndTextureMode();

    self.seg_shader.end();

    return self.state.getLast();

}


pub fn debugDraw(self: *Self) !void {
    const e = try self.process();
    rl.DrawTexturePro(
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
            .width=@floatFromInt(rl.GetScreenWidth()),
            .height=@floatFromInt(rl.GetScreenHeight()),
        },
        .{.x=0,.y=0},
        0,
        rl.WHITE,
    );
}

pub fn deinit(self: *Self) void {
    _ = self;
    //free textures
}

