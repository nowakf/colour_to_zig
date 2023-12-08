const rl = @import("raylib");
const std = @import("std");

const Shader = @import("shader.zig");

const Self = @This();

bufs: [2]rl.RenderTexture2D,
last_written: usize = 0,


pub fn draw(self: *Self, tex: rl.Texture2D) void {
    _ = tex;
    self.last_written = (self.last_written + 1) % 2;
    rl.BeginTextureMode(self.bufs[self.last_written]);
    //rl.DrawTexture(
    //    tex,
    //    0, 0,
    //    rl.WHITE
    //); //flips it, annoying!
    rl.EndTextureMode();
}

pub fn getLast(self: Self) rl.Texture2D {
    return self.bufs[self.last_written].texture;
}
