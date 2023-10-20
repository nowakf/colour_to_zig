const std = @import("std");

pub const MacOSCamera = struct {
    pub fn getFrame(self: MacOSCamera) void {
        _ = self;
        std.debug.print("Get frame on MacOS\n", .{});
    }

    pub fn init(self: MacOSCamera) void {
        _ = self;
        std.debug.print("Init on on MacOS\n", .{});
    }
};
