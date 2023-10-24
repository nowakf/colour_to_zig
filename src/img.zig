const std = @import("std");

fn hsv(rgb: [3]u8) [3]u8 {
    var out : [3]u8 = .{0} ** 3;
    const r = @as(f32, @floatFromInt(rgb[0])) / 255;
    const g = @as(f32, @floatFromInt(rgb[1])) / 255;
    const b = @as(f32, @floatFromInt(rgb[2])) / 255;
    const max = @max(@max(r, g), b);
    const min = @min(@min(r, g), b);
    const delta = max - min;
    if (max == 0) return .{0} ** 3;
    if (delta == 0) return .{255} ** 3;
    const h_tmp = tmp: {
        if (max == r) break :tmp (g-b) / delta;
        if (max == g) break :tmp 2+(b-r) / delta;
        if (max == b) break :tmp 4+(r-g) / delta;
        unreachable;
    };
    const h = (if (h_tmp < 0) h_tmp + 6 else h_tmp) / 6;
    out[0] = @intFromFloat(h * 255);
    out[1] = @intFromFloat(delta / max * 255);
    out[2] = @intFromFloat(max * 255);
    return out;
}

test "hsv" {
    const tests = [_][2][3]u8 {
        //input             expectation
        .{.{0, 255, 255},   .{127, 255, 255}},
        .{.{255, 0, 255},   .{212, 255, 255}},
        .{.{0, 0, 0},       .{0, 0, 0}},
        .{.{255, 0, 0},     .{0, 255, 255}},
    };
    for (tests, 0..) |tst, i| {
        const result = hsv(tst[0]);
        const expected = tst[1];
        std.testing.expect(std.mem.eql(u8, &expected, &result)) catch |err| {
            std.debug.print("failed on: {}, expected: {any}, got: {any}\n", .{i, expected, result});
            return err;
        };
    }
}

fn histogram(comptime buckets: comptime_int,  vals: []const u8) [buckets]u8 {
    var out : [buckets]u8 = .{0} ** buckets;
    for (vals) |v| {
        out[@as(u32, v) * buckets / 256] +|= 1;
    }
    return out;
}

test "histogram" {
    const testing = std.testing;
    const tests = [_] struct {[]const u8, []const u8} {
        .{
            &.{0,  0,  1},  
            &.{3,  0}
        }, 
        .{
            &.{0,  0,  1,  255,  255,  255},  
            &.{3,  3}
        }, 
        .{
            &.{255,  255,  255,  255,  255,  255,  255,  255,  255,  255,  255},  
            &.{0,  0,  0,  0,  11}
        }, 
        .{
            &.{12, 24, 36, 48, 60, 72, 84, 97, 109, 121, 133, 145, 157, 169, 182, 194, 206, 218, 230, 242, 254}, 
            &.{7,  7, 7}
        }, 
        .{
            &.{254, 242, 230, 218, 206, 194, 182, 169, 157, 145, 133, 121, 109, 97, 84, 72, 60, 48, 36, 24, 12}, 
            &.{7,  7, 7}
        }, 
    };
    inline for (tests) |tst| {
        testing.expect(std.mem.eql(u8,  &histogram(tst[1].len,  tst[0]),  tst[1])) catch |err| {
            std.debug.print("expected: {any}\n returned: {any}\n",  .{tst[1], histogram(tst[1].len,  tst[0])});
            return err;
        };
    }
}
