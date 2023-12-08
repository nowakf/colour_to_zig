const std = @import("std");

const rl = @import("raylib");

const SwapBuf = @import("swap_buf.zig");
const Shader = @import("shader.zig");

const Self = @This();

//swap_buf:  SwapBuf,
//seed_shader: Shader,
//flood_shader: Shader,
depths: rl.Texture2D,
surface: rl.Texture2D,
blue_noise: rl.Texture2D,
fbm_noise: rl.Texture2D,
sdf_shader: Shader,

pub fn new() Self {
    const this = .{
        .blue_noise = rl.LoadTexture("assets/textures/LDR_RGB1_0.png"),
        .fbm_noise = rl.LoadTexture("assets/textures/fbm_noise.png"),
        .depths = rl.LoadTexture("assets/textures/depths.png"),
        .surface = rl.LoadTexture("assets/textures/surface.png"),
        .sdf_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/sdf.frag")
    };
    rl.SetTextureFilter(this.depths, @intFromEnum(rl.TextureFilter.TEXTURE_FILTER_BILINEAR));
    rl.SetTextureFilter(this.surface, @intFromEnum(rl.TextureFilter.TEXTURE_FILTER_BILINEAR));
    return this;
}

pub fn update(self: *Self) void {
    if (rl.IsKeyReleased(rl.KeyboardKey.KEY_ENTER)) {
        rl.UnloadShader(self.sdf_shader.inner);
        self.sdf_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/sdf.frag");
        rl.UnloadTexture(self.depths);
        rl.UnloadTexture(self.surface);
        self.depths = rl.LoadTexture("assets/textures/depths.png");
        self.surface = rl.LoadTexture("assets/textures/surface.png");
    }
}

pub fn draw(self: Self, tex: rl.Texture2D, activity: f32) void {
    const w : f32 = @floatFromInt(rl.GetScreenWidth());
    const h : f32 = @floatFromInt(rl.GetScreenHeight());
    self.sdf_shader.send(f32, activity, "activity") catch |err| std.log.info("{any}\n", .{err});
    self.sdf_shader.send(f32, w/h, "aspect") catch |err| std.log.info("{any}\n", .{err});
    self.sdf_shader.send(f32, @floatCast(rl.GetTime()), "time")  catch |err| std.log.info("{any}\n", .{err});
    self.sdf_shader.begin();
        self.sdf_shader.sendTexture("noise0", self.blue_noise) catch |err| std.log.info("{any}\n", .{err});
        self.sdf_shader.sendTexture("noise1", self.fbm_noise) catch |err| std.log.info("{any}\n", .{err});
        self.sdf_shader.sendTexture("depths", self.depths) catch |err| std.log.info("{any}\n", .{err});
        self.sdf_shader.sendTexture("surface", self.surface) catch |err| std.log.info("{any}\n", .{err});
        rl.DrawTexturePro(
             tex,
            .{.x=0, .y=0, .width=@floatFromInt(tex.width), .height=@floatFromInt(tex.height)},
            .{.x=0, .y=0, .width=@floatFromInt(rl.GetScreenWidth()), .height=@floatFromInt(rl.GetScreenHeight())},
            .{}, 0, rl.WHITE
        );
    self.sdf_shader.end();
}
