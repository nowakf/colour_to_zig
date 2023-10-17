const std = @import("std");
pub const Orientation = enum(u2) {
        N, E, S, W,
        const Self = @This();
        fn left(self: *Self) void {
            self.* = @enumFromInt(@intFromEnum(self.*) -% 1);
        }
        fn right(self: *Self) void {
            self.* = @enumFromInt(@intFromEnum(self.*) +% 1);
        }
        pub fn three_facing(self: Self) [3][2]i2 {
            //this is a clockwise tour around the moore neighborhood
            //(0, 0) is at the top left.
            const ring : [9][2]i2 = .{.{-1, -1}, .{0, -1}, .{1, -1}, .{1, 0},
                .{1, 1}, .{0, 1}, .{-1, 1}, .{-1, 0}, .{-1, -1}};
            comptime var windows = std.mem.window([2]i2, &ring, 3, 2);
            comptime var i = 0;
            comptime var facings = @as([4][3][2]i2, @bitCast([1]i2{-1} ** (4 * 3 * 2)));
            comptime while (windows.next()) |window| : (i += 1) {
                facings[i] = window[0..3].*;
            };
            return facings[@intFromEnum(self)];
        }
};

pub const Bitmap = struct {
    w: u32, 
    h: u32,
    bits: std.bit_set.DynamicBitSetUnmanaged,
    const Self = @This();
    fn at(self: Self, x: u32, y: u32) bool {
        return x < self.w and y < self.h and self.bits.isSet(y*self.w+x);
    }

    fn from_img(alc: std.mem.Allocator, w: u32, h: u32, bytes: []u8) !Bitmap {
            _ = bytes;
            _ = h;
            _ = w;
            _ = alc;

        const pbm = struct {
            w: u32,
            h: u32,
            data: []align(@alignOf(usize)) u8,
        };
        const x = pbm{
            .w=0, 
            .h=0, 
            .data=&.{}
        };
        //const pbm = try @import("pbm.zig").parse(file);

        return Self {
            .w    = x.w,
            .h    = x.h,
            .bits = std.bit_set.DynamicBitSetUnmanaged {
                .bit_length = x.w * x.h,
                .masks = @ptrCast(@alignCast(x.data)),
            },
        };
    }
};

fn u32_i2_wrapping_sum(a: u32, b: i2) u32 {
    const res_signed = @as(i64, @intCast(a)) +% b;
    return @as(u32, @bitCast(@as(i32, @truncate(res_signed))));
}

test "u32_i2_wrapping_sum" {
    const expect = std.testing.expect;
    try expect(u32_i2_wrapping_sum(0, -1) == 0xffffffff);
    try expect(u32_i2_wrapping_sum(0, 1) == 1);
    try expect(u32_i2_wrapping_sum(0xffffffff, 1) == 0);
    try expect(u32_i2_wrapping_sum(0xffffffff, 0) == 0xffffffff);
}


pub const Tracer = struct {
    orientation: Orientation = Orientation.N,
    pos: [2]u32,
    const Self = @This();
    fn step(self: *Self, map: *const Bitmap) [2]u32 {
        const three_facing = self.orientation.three_facing();
        var bits = std.bit_set.IntegerBitSet(3).initEmpty();
        for (three_facing, 0..) |delta, i| {
            const x = u32_i2_wrapping_sum(self.pos[0], delta[0]);
            const y = u32_i2_wrapping_sum(self.pos[1], delta[1]);
            if (map.at(x, y)) {
                bits.set(i);
            }
        }
        const three : u3 = bits.mask;
        switch (three) {
            0b100...0b111 => {
                self.orientation.left();
                self.pos = .{
                    u32_i2_wrapping_sum(self.pos[0], three_facing[0][0]),
                    u32_i2_wrapping_sum(self.pos[1], three_facing[0][1]),
                };
            },
            0b010...0b011 => {
                self.pos = .{
                    u32_i2_wrapping_sum(self.pos[0], three_facing[1][0]),
                    u32_i2_wrapping_sum(self.pos[1], three_facing[1][1]),
                };
            },
            0b001         => {
                self.pos = .{
                    u32_i2_wrapping_sum(self.pos[0], three_facing[2][0]),
                    u32_i2_wrapping_sum(self.pos[1], three_facing[2][1]),
                };
            },
            0b000         => {
                self.orientation.right();
            },
        }
        return self.pos;
    }
    pub fn trace(map: *const Bitmap, start: [2]u32, alc: std.mem.Allocator) [][2]u32 {
        var contour = std.ArrayList([2]u32).init(alc);
        var tracer = Tracer{
            .pos = start,
        };

        var right_turns : u32 = 0;
        var last_loc = start;
        var last_pushed = start;

        while (true) {
            const loc = tracer.step(map);
            if (std.mem.eql(u32, &loc, &last_loc)) {
                right_turns += 1;
            } else {
                right_turns = 0;
                last_loc = loc;
                if (true) { //work out some chain-approx style simplification here
                    last_pushed = loc;
                    contour.append(loc) catch |err| std.debug.panic("{any}", .{err});
                }
            }
            const pts = contour.items;
            if (right_turns == 3 or std.mem.eql(u32, &pts[0], &pts[pts.len-1])) {
                return pts;
            }
        }
    }
};
test "tracer_trace" {
    const expect = std.testing.expect;
    _ = expect;

}

