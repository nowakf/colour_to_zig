const std = @import("std");

const raylib = @import("raylib");

const Cam = @import("camera.zig");
const Shader = @import("shader.zig");
const CropBuf = @import("crop_buf.zig");

pub const Calibration = struct {
    const Calib = @This();
    alc: std.mem.Allocator,
    samples: [][3]f32,
    crop: CropBuf,
    pub fn deinit(self: Calib) void {
        self.alc.free(self.samples);
        self.crop.deinit();
    }
};

const Self = @This();

alc: std.mem.Allocator,
cam: Cam,
screen: raylib.Texture2D,
crop: CropBuf,
colour_cone_width: f32 = 0.1,
brightness_margin_width: f32 = 0.1,
samples: std.ArrayList([3]f32),
display_shader: Shader,
input_state: union(enum) {
    RectSelect: ?raylib.Vector2,
    RectDone: ?[2]raylib.Vector2,
    PointSelect: void,
    Done: void,
} = .{.RectSelect = null },

pub fn new(alc: std.mem.Allocator, camera: Cam) !Self {
    try camera.updateFrame(); //to work around undefined behaviour in openpnp
    const img = raylib.Image {
        .data = camera.buf.ptr,
        .width = @intCast(camera.info.width),
        .height = @intCast(camera.info.height),
        .mipmaps = 1,
        .format = @intFromEnum(raylib.PixelFormat.PIXELFORMAT_UNCOMPRESSED_R8G8B8),
    };
    const tex = raylib.LoadTextureFromImage(img);
    return .{
        .alc = alc,
        .cam = camera,
        .screen = tex,
        .display_shader = Shader.fromPaths(
            "assets/shaders/vertex.vert",
            "assets/shaders/calibrate.frag",
        ),
        .crop = try CropBuf.new(alc, camera.buf, .{.x=0, .y=0, .w=@intCast(img.width), .h=@intCast(img.height)}),
        .samples = std.ArrayList([3]f32).init(alc),
    };
}
fn colour_at_pt(self: Self, pt: raylib.Vector2, kernel: u32) raylib.Vector4 {
    const w : u32 = self.crop.dst_rect.w;
    const sw : f32 = @floatFromInt(raylib.GetScreenWidth());
    const sh : f32 = @floatFromInt(raylib.GetScreenHeight());
    const bw : f32 = @floatFromInt(self.crop.dst_rect.w);
    const bh : f32 = @floatFromInt(self.crop.dst_rect.h);
    var sum : struct{r: u32=0, g: u32=0, b: u32=0} = .{};
    const mx : u32 = @intFromFloat(pt.x / sw * bw);
    const my : u32 = @intFromFloat(pt.y / sh * bh);
    for (0..kernel) |y| {
        for (0..kernel) |x| {
            const i = ((y+my) * w + (x+mx)) * 3;
            sum.r += self.crop.buf[(i+0) % self.crop.buf.len];
            sum.g += self.crop.buf[(i+1) % self.crop.buf.len];
            sum.b += self.crop.buf[(i+2) % self.crop.buf.len];
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

const cross = [4]raylib.Vector2{
    .{.x=-5, .y=0}, .{.x=5,  .y=0},
    .{.x=0,  .y=-5}, .{.x=0,  .y=5},
};

//TODO: Make backup file in case you want to restore without recalibrating
//TODO: Change so you can select a range of colours? 
//TODO: Add more feedback while calibrating: show how the image will be segmented as colours are picked
pub fn update(self: *Self) !void {
    try self.cam.updateFrame();
    self.crop.update();
    raylib.UpdateTextureRec(self.screen, self.crop.dst_rect.to_rl_rect(), self.crop.buf.ptr);

    const mpos = raylib.GetMousePosition();
    const mcolour = self.colour_at_pt(mpos, 3);
    self.display_shader.begin();
        try self.samples.append(.{mcolour.x, mcolour.y, mcolour.z});
        try self.display_shader.send([][3]f32, self.samples.items, "colours");
        try self.display_shader.send(f32, self.brightness_margin_width, "brightness_margin_width");
        try self.display_shader.send(f32, self.colour_cone_width, "colour_cone_width");
        _ = self.samples.pop();
    self.display_shader.end();

    switch (self.input_state) {
        .RectSelect => |origin| {
            if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_SPACE)) {
                    self.input_state = .{.RectDone = null };
            }
            if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_ENTER)) {
                    self.input_state = .PointSelect;
            }
            if (origin) |pt| {
                if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
                    self.input_state = .{.RectDone = .{
                        pt,
                        mpos
                    }};
                }
            } else {
                if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
                    self.input_state = .{.RectSelect=mpos};
                }
            }
        },
        .RectDone => |sel| {
            if (sel) |pts| {
                const rect = self.crop.dst_rect.subset(
                    raylib.GetScreenWidth(),
                    raylib.GetScreenHeight(),
                    pts[0],
                    pts[1]
                );
                self.crop.setCrop(
                    rect
                ) catch |err| {
                    std.log.err("{any} invalid: {any}\n window is {any}", .{rect, err, self.crop.src_rect});
                };
            } else {
                try self.crop.setCrop(self.crop.src_rect);
            }
            self.input_state = .{.RectSelect = null};
        }, 
        .PointSelect => {
            if (raylib.IsMouseButtonReleased(raylib.MouseButton.MOUSE_BUTTON_LEFT)) {
                const colour = self.colour_at_pt(mpos, 3);
                std.debug.print("collected {}, {}, {}, at mpoint {} {}\n", .{colour.x, colour.y, colour.z, mpos.x, mpos.y});
                try self.samples.append(.{colour.x, colour.y, colour.z});
            } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_BACKSPACE)) {
                const col = self.samples.popOrNull();
                std.debug.print("deleted last colour entry: {any}\n", .{col});
            } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_UP)) {
                self.colour_cone_width += 0.01;
            } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_DOWN)) {
                self.colour_cone_width -= 0.01;
            } else if (raylib.IsKeyReleased(raylib.KeyboardKey.KEY_ENTER)) {
                std.debug.print("we're done here\n", .{});
                self.input_state = .Done;
            }
        },
        .Done => {
        },
    }

}

pub fn draw(self: *Self) !void {
    const mpos = raylib.GetMousePosition();
    const w = raylib.GetScreenWidth();
    const h = raylib.GetScreenHeight();
    const mcolour = self.colour_at_pt(mpos, 3);
    self.display_shader.begin();
        raylib.DrawTexturePro(
            self.screen,
            self.crop.dst_rect.to_rl_rect(),
            .{.x=0, .y=0, .width=@floatFromInt(w), .height=@floatFromInt(h)},
            .{.x=0, .y=0},
            0,
            raylib.WHITE
        );
    self.display_shader.end();
    switch (self.input_state) {
        .RectSelect => |origin| {
            raylib.DrawText("in rect select mode: space to restart, enter to accept", 0, 0, 12, raylib.WHITE);
            if (origin) |pt| {
                const rct = CropBuf.RectI.from_rl_pts(pt, mpos);
                raylib.DrawRectangleLines(
                    @intCast(rct.x),
                    @intCast(rct.y),
                    @intCast(rct.w),
                    @intCast(rct.h),
                    raylib.WHITE,
                );
            }
        },
        .PointSelect => {
            raylib.DrawText("in point select mode: backspace to undo, enter to accept", 0, 0, 12, raylib.WHITE);
            raylib.DrawRectangle(0, 0, 30, 30, raylib.ColorFromNormalized(mcolour));
        },
        else => {
        }
    }

}

pub fn isDone(self: Self) bool {
    return self.input_state == .Done;
}

pub fn finish(self: *Self) !Calibration {
    raylib.UnloadTexture(self.screen);
    raylib.UnloadShader(self.display_shader.inner);
    return .{
        .alc = self.alc,
        .samples = try self.samples.toOwnedSlice(),
        .crop = self.crop,
    };
}

