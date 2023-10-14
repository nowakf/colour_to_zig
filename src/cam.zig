const std = @import("std");

const InvalidIter = struct {
    const Self = @This();
    fn new() Self {
        @panic("");
    }
    fn next(_: Self, _: []u8) ?[]const u8 {
        std.debug.print("", .{});
        return null;
    }
    fn close(_: Self) void { }
};

const CamIter = struct {
    //cam : @import("v4l2.zig").Camera = undefined,
    const Self = @This();

    fn new() Self {
        return .{
     //       .cam = null,
        };
    }
    fn next(self: Self, buf: []u8) ?[]const u8 {
        _ = buf;
        _ = self;
        return null;
    }

    fn close(self: Self) void {
        _ = self;
    }
};
