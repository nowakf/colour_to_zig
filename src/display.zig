const std = @import("std");

const rl = @import("raylib");

const SwapBuf = @import("swap_buf.zig");
const Shader = @import("shader.zig");

const Self = @This();

//swap_buf:  SwapBuf,
//seed_shader: Shader,
//flood_shader: Shader,
sdf_shader: Shader,

pub fn new() Self {
    return .{
        .sdf_shader = Shader.fromPaths("assets/shaders/vertex.vert", "assets/shaders/sdf.frag")
    };
}

pub fn draw(self: Self, tex: rl.Texture2D) void {
    const mpos = rl.GetMousePosition().scale(1.0/@as(f32, @floatFromInt(rl.GetScreenWidth())));
    self.sdf_shader.send([2]f32, .{mpos.x, mpos.y}, "mouse") catch |err| {
        std.log.err("{any}\n", .{err});
    };
    self.sdf_shader.begin();
        rl.DrawTexturePro(
            tex, 
            .{.x=0, .y=0, .width=@floatFromInt(tex.width), .height=@floatFromInt(tex.height)},
            .{.x=0, .y=0, .width=@floatFromInt(rl.GetScreenWidth()), .height=@floatFromInt(rl.GetScreenHeight())},
            .{}, 0, rl.WHITE
        );
    self.sdf_shader.end();
}
