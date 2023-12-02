const rl = @import("raylib");

const Self = @This();

bufs: [2]rl.RenderTexture2D,
on_flip: ?*const fn(*Self) void = null,
final: usize = 0,

pub fn setInitial(self: *Self, tex: rl.Texture2D) void {
    rl.BeginTextureMode(self.bufs[1]);
        rl.DrawTexture(tex, 0, 0, rl.WHITE);
    rl.EndTextureMode();
}

pub fn run(self: *Self, iterations: usize) void {
    for (0..iterations) |i| {
        if (self.on_flip) |cb| cb(self);
        rl.BeginTextureMode(self.bufs[i%2]);
        rl.ClearBackground(rl.BLACK);
        rl.DrawTexture(
            self.bufs[(i+1)%2].texture,
            0, 0, rl.WHITE
        );
    }
    rl.EndTextureMode();
    self.final = (iterations-1) % 2;
}
pub fn getLast(self: Self) rl.Texture2D {
    return self.bufs[self.final].texture;
}
