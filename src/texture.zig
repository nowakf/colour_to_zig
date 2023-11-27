const gl = @import("zopengl");

const Self = @This();
id: gl.Uint,
w: u32,
h: u32,
typ: gl.Uint,

fn load() void {
}

fn bind(self: Self) void {
    _ = self;
}

fn destroy(self: *Self) void {
    gl.DeleteTextures(1, &self.id);
}
