const raylib = @import("raylib");
const c = @cImport (
    @cInclude("raylib/src/external/glad.h")
        //so this file is generated by 'glad' so hopefuly should work on all platforms, 
        //but honestly, who knows?
);

const Texture3DOptions = struct {
    width: i32,
    height: i32,
    depth: i32,
    mipmaps: i32 = 1, 
    format: i32 = c.GL_RGB,
    clamp: u32 = c.GL_REPEAT,
    filter: u32 = c.GL_NEAREST,
    data: ?[]const u8 = null,
};

const Self = @This();
/// OpenGL texture id
id: u32,
/// Texture base width
width: i32,
/// Texture base height
height: i32,
/// Texture base depth
depth: i32,
/// Mipmap levels, 1 by default
mipmaps: i32,
/// Data format (PixelFormat type)
format: i32,

pub fn new(opts: Texture3DOptions) Self {
    var texture : c.GLuint = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_3D, texture);
    c.glTexParameteri(c.GL_TEXTURE_3D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_3D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_3D, c.GL_TEXTURE_WRAP_R, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_3D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR_MIPMAP_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_3D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glTexImage3D(
        c.GL_TEXTURE_3D,
        0,
        c.GL_RGB8,
        opts.width,
        opts.height,
        opts.depth,
        0,
        @intCast(opts.format),
        c.GL_UNSIGNED_BYTE,
        if (opts.data) |dt| dt.ptr else null,
    );
    c.glGenerateMipmap(c.GL_TEXTURE_3D);  
    raylib.rlCheckErrors();
    return .{
        .id = texture,
        .width = opts.width,
        .height = opts.height,
        .depth = opts.depth,
        .mipmaps = opts.mipmaps,
        .format = opts.format,
    };
}

pub fn send(self: Self, shader: u32, uniform: []const u8) void {
    const unf = c.glGetUniformLocation(shader, uniform.ptr);
    c.glUseProgram(shader);
    defer c.glUseProgram(0);
    c.glUniform1i(unf, @intCast(self.id));
    raylib.rlCheckErrors();
}

pub fn set_frame(self: Self, frame: u32, data: [*]const u8) void {
    c.glActiveTexture(c.GL_TEXTURE0);
    c.glBindTexture(c.GL_TEXTURE_3D, self.id);
    c.glGenerateMipmap(c.GL_TEXTURE_3D);
    c.glTexSubImage3D(
        c.GL_TEXTURE_3D, 
        0,
        0,
        0,
        @intCast(frame),
        self.width,
        self.height,
        1,              //a frame has a z-depth of 1
        @intCast(self.format),
        c.GL_UNSIGNED_BYTE,
        data 
    );
    raylib.rlCheckErrors();
}

pub fn deinit(self: Self) void {
    c.glDeleteTextures(1, &self.id);
    raylib.rlCheckErrors();
}
