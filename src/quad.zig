const gl = @import("zopengl");

const Texture = @import("texture.zig");

const Self = @This();
buffers: Buffers,

const verts = [6][4]gl.Float {
    //  x       y    s      t
     .{ -1.0, -1.0, 0.0, 1.0}, //BL
     .{ -1.0, 1.0,  0.0, 0.0}, //TL
     .{ 1.0,  1.0,  1.0, 0.0}, //TR
     .{ 1.0,  -1.0, 1.0, 1.0}, //BR
};

const idxs = [6]gl.Int {
    0, 1, 2, 3, 2, 4
};

const Buffers = struct {
    vao: gl.Uint,
    vbo: gl.Uint,
    ebo: gl.Uint,
};


fn gen_buffers() !Buffers {
    var vao : gl.Uint = undefined;
    var vbo : gl.Uint = undefined;
    var ebo : gl.Uint = undefined;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    gl.genBuffers(1, &ebo);
    try check_gl_error();
    return .{.vao=vao, .vbo=vbo, .ebo=ebo};
}

//make this more sane?
fn bind_attrs(self: Self) !void {
    const pos_attr_loc = gl.getAttribLocation(self.shader, "position");
    gl.vertexAttribPointer(pos_attr_loc, 2, gl.FLOAT, gl.FALSE, 4*@sizeOf(gl.Float), &0);
    gl.enableVertexAttribArray(pos_attr_loc);

    const tex_attr_loc = gl.getAttribLocation(self.shader, "texcoord");
    gl.vertexAttribPointer(tex_attr_loc, 2, gl.FLOAT, gl.FALSE, 4*@sizeOf(gl.Float), &(2*@sizeOf(gl.Float)));
    gl.enableVertexAttribArray(tex_attr_loc);
    try check_gl_error();
}

pub fn new() !Self {
    return .{
        .buffers = try gen_buffers(),
    };
}

pub fn bind(self: Self) !void {
    gl.bindVertexArray(self.buffers.vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, self.buffers.vbo);
    gl.bufferData(gl.ARRAY_BUFFER, verts.len, verts.ptr, gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, self.buffers.ebo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, idxs.len, idxs.ptr, gl.STATIC_DRAW);
    try check_gl_error();
}

pub fn destroy(self: *Self) void {
    gl.deleteBuffers(1,      &self.buffers.vbo);
    gl.deleteBuffers(1,      &self.buffers.ebo);
    gl.deleteVertexArrays(1, &self.buffers.vao);
}

//this should go in another file:
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

