const std = @import("std");

const rl = @import("raylib");

const Self = @This();

inner: rl.Shader,

pub fn fromPaths(vs: [:0]const u8, fs: [:0]const u8) Self {
    return .{.inner=rl.LoadShader(vs, fs)};
}

pub fn begin(self: Self) void {
    rl.BeginShaderMode(self.inner);
}

pub fn end(self: Self) void {
    _ = self;
    rl.EndShaderMode();
}

fn toGlType(comptime T: type) rl.ShaderUniformDataType {
    return switch (T) {
        f32, f64 => rl.ShaderUniformDataType.SHADER_UNIFORM_FLOAT,
        [2]f32, [2]f64 => rl.ShaderUniformDataType.SHADER_UNIFORM_VEC2,
        [3]f32, [3]f64 => rl.ShaderUniformDataType.SHADER_UNIFORM_VEC3,
        [4]f32, [4]f64 => rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4,
        i8, u8, i16, u16, i32, u32, usize => rl.ShaderUniformDataType.SHADER_UNIFORM_INT,
        inline else => @panic("unknown type\n" ++ @typeName(T)),
    };
}

fn send_struct(self: Self, comptime T: type, val: T) !void {
    inline for (std.meta.fields(T)) |f| {
        try self.send(f.type, @field(val, f.name), f.name);
    }
}

fn location(self: Self, uniform: []const u8, comptime fmt: ?[]const u8) !i32 {
    var buf : [100]u8 = undefined;
    const name = try std.fmt.bufPrintZ(&buf, fmt orelse "{s}", .{uniform});
    //hope this constant is correct
    const loc = rl.GetShaderLocation(self.inner, name);
    if (loc != -1) {
        return loc;
    } else {
        std.debug.print("shader with id: {} did not have uniform: {} with name: {s}\n", .{self.inner.id, loc, name});
        return error.NoSuchUniform;
    }
}

fn sendArray(self: Self, uniform: []const u8, comptime T: type, array: T) !void {
    rl.SetShaderValue(
        self.inner,
        try self.location(uniform, "{s}_cnt"),
        &array.len,
        toGlType(i32),
    );

    if (array.len == 0) return;

    const ch_ty = switch (@typeInfo(T)) {
        inline else => |t| t.child
    };

    rl.SetShaderValueV(
        self.inner,
        try self.location(uniform, null),
        array.ptr,
        @intFromEnum(toGlType(ch_ty)),
        @intCast(array.len)
    );
}

fn sendValue(self: Self, uniform: []const u8, comptime T: type, val: T) !void {
    rl.SetShaderValue(
        self.inner,
        try self.location(uniform, null),
        &val,
        toGlType(T),
    );
}

pub fn send(self: Self, comptime T: type, v: T, name: ?[]const u8) !void {
    rl.BeginShaderMode(self.inner);
    defer rl.EndShaderMode();
    //std.builtin.Type
    switch (@typeInfo(T)) {
        .Struct => try self.send_struct(T, v),
        .Int, .ComptimeInt => try self.sendValue(name.?, T, v),
        .Float, .ComptimeFloat => try self.sendValue(name.?, T, v),
        .Pointer, .Array => switch(T) {
            [2]f32, [3]f32, [4]f32, [2]f64, [3]f64, [4]f64 => self.sendValue(name.?, T, v),
            inline else => try self.sendArray(name.?, T, v)
        },
        else => @compileError("cannot send" ++ @typeName(T) ++ "\n"),
    }
}
