const std = @import("std");

const rl = @import("raylib");

pub const RectI = struct {
    const Rect = @This();
    x:u32,
    y:u32,
    w:u32,
    h:u32,
    pub fn is_within(self: Rect, other: Rect) bool {
        return  self.x >= other.x
            and self.y >= other.y
            and self.x+self.w <= other.x+other.w
            and self.y+self.h <= other.y+other.h;
    }
    pub fn to_rl_rect(self: Rect) rl.Rectangle {
        return .{
            .x = @floatFromInt(self.x),
            .y = @floatFromInt(self.y),
            .width = @floatFromInt(self.w),
            .height = @floatFromInt(self.h),
        };
    }
    pub fn from_rl_rect(r: rl.Rectangle) Rect {
        return .{
            .x = @intFromFloat(r.x),
            .y = @intFromFloat(r.y),
            .w = @intFromFloat(r.width),
            .h = @intFromFloat(r.height),
        };
    }
    pub fn from_rl_pts(a: rl.Vector2, b: rl.Vector2) Rect {
        const lf = @min(a.x, b.x);
        const tp = @min(a.y, b.y);
        const rg = @max(a.x, b.x);
        const bt = @max(a.y, b.y);
        return .{
            .x = @intFromFloat(lf),
            .y = @intFromFloat(tp),
            .w = @intFromFloat(rg-lf),
            .h = @intFromFloat(bt-tp),
        };
    }
    //this is bugged:
    pub fn subset(self: Rect, w: i32, h: i32, a: rl.Vector2, b: rl.Vector2) Rect {
        const f_src_w : f32 = @floatFromInt(w);
        const f_src_h : f32 = @floatFromInt(h);
        const f_dst_w : f32 = @floatFromInt(self.w);
        const f_dst_h : f32 = @floatFromInt(self.h);
        return Rect.from_rl_pts(
            .{
                .x=a.x / f_src_w * f_dst_w,
                .y=a.y / f_src_h * f_dst_h, 
            },
            .{
                .x=b.x / f_src_w * f_dst_w,
                .y=b.y / f_src_h * f_dst_h, 
            }
        );
    }
};


const Self = @This();

alc: std.mem.Allocator,
src_rect: RectI,
src_buf: []const u8,
dst_rect: RectI,
bytes_per_px: u32 = 3,
buf: []u8,

pub fn new(alc: std.mem.Allocator, src_buf: []const u8, src_rect: RectI) !Self {
    return .{
        .alc = alc,
        .src_rect = src_rect,
        .src_buf = src_buf,
        .dst_rect = src_rect,
        .buf = try alc.dupe(u8, src_buf),
    };
}

pub fn update(self: *Self) void {
    const src = self.src_rect;
    const dst = self.dst_rect;
    const bytes = self.bytes_per_px;
    for (0..dst.h) |i| {
        const dst_l = i*dst.w*bytes;
        const dst_r = dst_l + dst.w*bytes;
        const src_l = (i+dst.y)*src.w*bytes + dst.x*bytes;
        const src_r = src_l + dst.w*bytes;
        @memcpy(
            self.buf[dst_l..dst_r],
            self.src_buf[src_l..src_r]
        );
    }
}

pub fn setCrop(self: *Self, crop: RectI) !void {
    if (!crop.is_within(self.src_rect)) {
        return error.CropTooBig;
    }
    self.dst_rect = crop;
    self.buf = try self.alc.realloc(self.buf, crop.w*crop.h*self.bytes_per_px);
}

pub fn deinit(self: Self) void {
    self.alc.free(self.buf);
}
