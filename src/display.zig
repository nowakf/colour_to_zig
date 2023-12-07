const std = @import("std");

const rl = @import("raylib");

const SwapBuf = @import("swap_buf.zig");
const Shader = @import("shader.zig");

const Self = @This();

//swap_buf:  SwapBuf,
//seed_shader: Shader,
//flood_shader: Shader,
swatch: rl.Texture2D,
blue_noise: rl.Texture2D,
fbm_noise: rl.Texture2D,
sdf_shader: Shader,

pub fn new() Self {
    const this = .{
        .blue_noise = rl.LoadTexture("assets/textures/LDR_RGB1_0.png"),
        .fbm_noise = rl.LoadTexture("assets/textures/fbm_noise.png"),
        .swatch = rl.LoadTexture("assets/textures/hambach.png"),
        .sdf_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/sdf.frag")
    };
    return this;
}

pub fn update(self: *Self) void {
    if (rl.IsKeyReleased(rl.KeyboardKey.KEY_ENTER)) {
        rl.UnloadShader(self.sdf_shader.inner);
        self.sdf_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/sdf.frag");
        rl.UnloadTexture(self.swatch);
        self.swatch = rl.LoadTexture("assets/textures/hambach.png");
    }
}

pub fn draw(self: Self, tex: rl.Texture2D) void {
    const w : f32 = @floatFromInt(rl.GetScreenWidth());
    const h : f32 = @floatFromInt(rl.GetScreenHeight());
    self.sdf_shader.send(f32, w/h, "aspect") catch |err| std.log.info("{any}\n", .{err});
    self.sdf_shader.begin();
        self.sdf_shader.sendTexture("noise0", self.blue_noise) catch |err| std.log.info("{any}\n", .{err});
        self.sdf_shader.sendTexture("noise1", self.fbm_noise) catch |err| std.log.info("{any}\n", .{err});
        self.sdf_shader.sendTexture("swatch0", self.swatch) catch |err| std.log.info("{any}\n", .{err});
        rl.DrawTexturePro(
             tex,
            .{.x=0, .y=0, .width=@floatFromInt(tex.width), .height=@floatFromInt(tex.height)},
            .{.x=0, .y=0, .width=@floatFromInt(rl.GetScreenWidth()), .height=@floatFromInt(rl.GetScreenHeight())},
            .{}, 0, rl.WHITE
        );
    self.sdf_shader.end();
}
