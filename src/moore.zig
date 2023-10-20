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
            const ring : [9][2]i2 = .{
                .{-1, -1}, .{0, -1}, .{1, -1},
                .{1, 0}, .{1, 1}, .{0, 1}, 
                .{-1, 1}, .{-1, 0}, .{-1, -1}};
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
    bits: std.bit_set.DynamicBitSet,
    const Self = @This();

    fn at(self: Self, x: u32, y: u32) bool {
        return x < self.w and y < self.h and self.bits.isSet(y*self.w+x);
    }
    fn empty(alc: std.mem.Allocator, w: u32, h: u32) !Self {
        return .{
            .w=w, .h=h, .bits=try std.bit_set.DynamicBitSet.initEmpty(alc, w*h),
        };
    }
    fn deinit(self: *Self) void {
        self.bits.deinit();
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
    fn step(self: *Self, map: *const Bitmap) ?[2]i2 {
        const three_facing = self.orientation.three_facing();
        var bits = std.bit_set.IntegerBitSet(3).initEmpty();
        for (three_facing, 0..) |delta, i| {
            const x = u32_i2_wrapping_sum(self.pos[0], delta[0]);
            const y = u32_i2_wrapping_sum(self.pos[1], delta[1]);
            bits.setValue(2-i, map.at(x, y));
        }
        const three : u3 = bits.mask;
        const new_heading = switch (three) {
            0b100...0b111 => left: {
                self.orientation.left();
                break :left three_facing[0];
            },
            0b010...0b011 => three_facing[1],
            0b001         => three_facing[2],
            0b000         => {
                self.orientation.right();
                return null;
            },
        };

        self.pos = .{
                u32_i2_wrapping_sum(self.pos[0], new_heading[0]),
                u32_i2_wrapping_sum(self.pos[1], new_heading[1]),
        };

        return new_heading;
    }
    pub fn find_next_start(map: *const Bitmap, start: [2]u32) ?[2]u32 {
        var it = map.bits.iterator(.{});
        it.bit_offset = start[1] / map.w + start[0];
        const next : u32 = @intCast(it.next().?);
        return .{next % map.w, next / map.w};
    }
    pub fn trace(alc: std.mem.Allocator, map: *const Bitmap, start: [2]u32) !std.ArrayList([2]u32) {
        var contour = std.ArrayList([2]u32).init(alc);
        var tracer = Tracer{
            .pos = start,
        };

        var right_turns : u32 = 0;
        var heading : [2]i2 = .{0, 0};

        while (true) {
            const prev = tracer.pos;
            const next = tracer.step(map);
            if (next == null) {
                right_turns += 1;
            } else {
                right_turns = 0;
                const n_heading = next.?;
                if (n_heading[0] != heading[0] or n_heading[1] != heading[1]) {
                    heading = n_heading;
                    try contour.append(prev);
                }
            }
            if (right_turns == 3 or (right_turns == 0 and std.mem.eql(u32, &tracer.pos, &start))) {
                return contour;
            }
        }
    }
};

test "tracer_trace" {
    const ContourSpec = struct {
        const Self = @This();
        map: Bitmap,
        coords: std.ArrayList([2]u32),
        fn from_str(alc: std.mem.Allocator, spec: []const u8) !Self {
            var tokens = std.mem.tokenizeAny(u8, spec, " \n\r\t");
            var vertexes : [64][2]u32 = .{.{0,0}} ** 64;
            var bmap = try Bitmap.empty(alc, 8, 8);
            var i : u32 = 0;
            var cnt : u32 = 0;
            while (tokens.peek() != null) : (i += 1) {
                const tok = tokens.next().?;
                if (tok[0] == '.') continue;
                bmap.bits.set(i);
                if (tok[0] == 'o') continue;
                const val = try std.fmt.parseInt(u8, tok, 16);
                vertexes[val] = .{i % 8, i / 8};
                cnt += 1;
            }
            var managed = std.ArrayList([2]u32).init(alc);
            try managed.appendSlice(vertexes[0..cnt]);
            return Self {
                .map=bmap,
                .coords=managed,
            };
        }
        fn eql(comptime N: comptime_int, comptime T: type, a: []const [N]T, b: []const [N]T) bool {
            if (a.len != b.len) return false;
            if (a.ptr == b.ptr) return true;
            for (a, b) |a_elem, b_elem| {
                if (!std.mem.eql(T, &a_elem, &b_elem)) return false;
            }
            return true;

        }
        fn check(self: Self, alc: std.mem.Allocator) !void {
            const start = Tracer.find_next_start(&self.map, .{0, 0}) orelse
                return error.NO_START;
            if (!std.mem.eql(u32, &start, &self.coords.items[0])) {
                std.debug.print("st: {any} actual: {any}\n", .{start, self.coords.items[0]});
                return error.WRONG_START;
            }
            const traced = try Tracer.trace(alc, &self.map, start);
            defer traced.deinit();
            if (!Self.eql(2, u32, traced.items, self.coords.items)) {
                std.debug.print("traced: {any} actual: {any}\n", .{traced.items, self.coords.items});
                return error.NO_MATCH;
            }
        }
        fn deinit(self: *Self) void {
            self.coords.deinit();
            self.map.deinit();
        }
    };

    const expect = std.testing.expect;
    _ = expect;

    const alc = std.testing.allocator;

    var square = try ContourSpec.from_str(alc,
        //0  1  2  3  4  5  6  7
        \\.  .  .  .  .  .  .  . 
        \\.  .  .  .  .  .  .  . 
        \\.  .  0  o  o  1  .  . 
        \\.  .  o  .  .  o  .  . 
        \\.  .  o  .  .  o  .  . 
        \\.  .  3  o  o  2  .  . 
        \\.  .  .  .  .  .  .  . 
        \\.  .  .  .  .  .  .  .
    );
    defer square.deinit();
    try square.check(alc);
    var bounds = try ContourSpec.from_str(alc,
        //0  1  2  3  4  5  6  7
        \\0  o  o  o  o  o  o  1 
        \\o  .  .  .  .  .  .  o 
        \\o  .  .  .  .  .  .  o 
        \\o  .  .  .  .  .  .  o 
        \\o  .  .  .  .  .  .  o 
        \\o  .  .  .  .  .  .  o 
        \\o  .  .  .  .  .  .  o 
        \\3  o  o  o  o  o  o  2
    );
    defer bounds.deinit();
    try bounds.check(alc);
    var spiky = try ContourSpec.from_str(alc,
        //0  1  2  3  4  5  6  7
        \\.  .  .  .  .  .  .  . 
        \\.  0  1  .  3  4  .  . 
        \\.  .  8  2  o  .  .  . 
        \\.  .  o  5  .  .  .  . 
        \\.  .  o  o  .  .  .  . 
        \\.  .  7  6  .  .  .  . 
        \\.  .  .  .  .  .  .  . 
        \\.  .  .  .  .  .  .  .
    );
    defer spiky.deinit();
    try spiky.check(alc);
}


