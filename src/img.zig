const std = @import("std");
const maxInt = std.math.maxInt;
const swap = std.mem.swap;

pub fn split_channels(comptime N: comptime_int, channels: [N][]u8, img: []const u8) !void {
    const chan_len = img.len / 3;
    for (channels, 0..) |chan, i| {
        if (chan.len != chan_len) return error.WrongSize;
        for (0..chan_len) |j| {
            chan[j] = img[j*channels.len+i];
        }
    }
}

//needs ptrs not to alias
pub fn splat_channel(channels: []u8, channel: []const u8) !void {
    if (channels.len != 3*channel.len) return error.DIFF_SIZE;
    for (0..channel.len) |i| {
        channels[i*3] = channel[i];
        channels[i*3+1] = channel[i];
        channels[i*3+2] = channel[i];
    }
}

//converts to range [0..1] f32
fn int_to_float(comptime int : type, px: [3]int) [3]f32 {
    return .{
        @as(f32, @floatFromInt(px[0])) / maxInt(int),
        @as(f32, @floatFromInt(px[1])) / maxInt(int),
        @as(f32, @floatFromInt(px[2])) / maxInt(int),
    };
}
fn float_to_int(comptime int : type, px: [3]f32) [3]int {
    return .{
        @intFromFloat(@round(px[0] * maxInt(int))),
        @intFromFloat(@round(px[1] * maxInt(int))),
        @intFromFloat(@round(px[2] * maxInt(int))),
    };
}

pub fn pix_map(buf: []u8, comptime fun: fn([3]u8) [3]u8) void {
    for (0..buf.len/3) |i| {
        const tmp = fun(.{
            buf[i*3], 
            buf[i*3+1],
            buf[i*3+2]
        });
        buf[i*3]   = tmp[0];
        buf[i*3+1] = tmp[1];
        buf[i*3+2] = tmp[2];
    }
}

pub fn clamp(v: u8, b: u8, t: u8) u8 {
    return if (v > b and v < t) 255 else 0;
}

pub fn hsv2rgb(hsv: [3]u8) [3]u8 {
    const flt = int_to_float(u8, hsv);
    const region = flt[0] * 6;
    const c = flt[2] * flt[1];
    const x = c * (1 - @abs(@mod(region, 2) - 1));
    const m = flt[2] - c;
    const rgbflt = switch (@as(u32, @intFromFloat(region))) {
        0 => .{c+m, x+m, 0+m},
        1 => .{x+m, c+m, 0+m},
        2 => .{0+m, c+m, x+m},
        3 => .{0+m, x+m, c+m},
        4 => .{x+m, 0+m, c+m},
        5, 6 => .{c+m, 0+m, x+m},
        else => unreachable,
    };
    return float_to_int(u8, rgbflt);
}

//this is lossy: can it be made lossless?
pub fn rgb2hsv(rgb: [3]u8) [3]u8 {
    const flt = int_to_float(u8, rgb);
    const r = flt[0];
    const g = flt[1];
    const b = flt[2];
    const max = @max(@max(r, g), b);
    const min = @min(@min(r, g), b);
    const delta = max - min;
    if (max == 0) return .{0} ** 3;
    if (delta == 0) return .{0} ** 3;
    const h_tmp = tmp: {
        if (max == r) break :tmp (g-b) / delta; 
        if (max == g) break :tmp 2+(b-r) / delta;
        if (max == b) break :tmp 4+(r-g) / delta;
        unreachable;
    };
    const h = (if (h_tmp < 0) h_tmp + 6 else h_tmp) / 6;
    return float_to_int(u8, .{h, delta/max, max});
}


pub fn histogram(comptime buckets: comptime_int,  vals: []const u8) [buckets]u8 {
    var out : [buckets]u8 = .{0} ** buckets;
    for (vals) |v| {
        out[@as(u32, v) * buckets / 256] +|= 1;
    }
    return out;
}

pub fn histogram_to_cumulative(hist: *[256]u8) void {
    var sum : u32 = 0;
    var tmp : [256]u32 = .{0} ** 256;
    for (hist, 0..) |v, i| {
        sum += v;
        tmp[i] = sum;
    }
    //scale to fit range
    const max = tmp[255];
    for (tmp, 0..) |t, i| {
        hist[i] = @intFromFloat(@round(@as(f32, @floatFromInt(t)) / @as(f32, @floatFromInt(max)) * 255));
    }
}

//this is nonsense: need to rethink
pub fn histogram_equalization(w: u32, h: u32, cdf: [256]u8, v: u8) u8 {
    const fsz : f64 = @floatFromInt(w*h);
    const cdv : f64 = @floatFromInt(cdf[v]);
    return @intFromFloat((cdv / fsz) * 255);
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

test "hsv-rgb" {
    const tests = [_][2][3]u8 {
        //rgb                hsv
        .{.{0, 255, 255},   .{128, 255, 255}},
        .{.{255, 0, 255},   .{213, 255, 255}},
        .{.{0, 0, 0},       .{0, 0, 0}},
        .{.{255, 0, 0},     .{0, 255, 255}},
    };
    for (tests, 0..) |tst, i| {
        const result = rgb2hsv(tst[0]);
        const expected = tst[1];
        std.testing.expect(std.mem.eql(u8, &expected, &result)) catch |err| {
            std.debug.print("failed on hsv: {}, expected: {any}, got: {any}\n", .{i, expected, result});
            return err;
        };
    }
    //because rgb->hsv is lossy I've no idea how to make these two tests mirror
    for (tests, 0..) |tst, i| {
        _ = i;
        const result = hsv2rgb(tst[1]);
        _ = result;
        const expected = tst[0];
        _ = expected;
        //std.testing.expect(std.mem.eql(u8, &expected, &result)) catch |err| {
        //    std.debug.print("failed on rgb: {}, expected: {any}, got: {any}\n", .{i, expected, result});
        //    return err;
        //};
    }
}
