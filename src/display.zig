const rl = @import("raylib");

const Self = @This();

pub fn new() Self {
    return .{};
}

pub fn draw(self: Self, tex: rl.Texture2D) void {
    _ = tex;
    _ = self;
}
