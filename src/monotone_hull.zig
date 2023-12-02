///Image -> monotone hull
const raylib = @import("raylib");
const moore = @import("moore.zig");
const std = @import("std");

const ColorMap = struct {
};

fn imageAt(image: *const anyopaque, x: u32, y: u32) bool {
    _ = image;
    _ = y;
    _ = x;
    return false;
}
fn imageStarts(image: *const anyopaque) [][2]u32 {
    _ = image; 
    return &.{};
}

fn ImageMap(img: raylib.Image) moore.Map {
    return .{
        .ctx = &img,
        ._at = imageAt,
        ._starts = imageStarts,
    };
}

pub fn trace(alc: std.mem.Allocator, img: raylib.Image) ![]const []const [2]u32 {
    var ctrs = std.ArrayList([]const [2]u32).init(alc);
    const map = ImageMap(img);
    for (map.starts()) |start| {
        var ctr = try moore.Tracer.trace(alc, map, start);
        try ctrs.append(try ctr.toOwnedSlice());
    }
    return ctrs.toOwnedSlice();
}


