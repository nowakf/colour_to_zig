const std = @import("std");

pub const MacOSCamera = struct {
    pub fn getFrame(self: MacOSCamera) [*:0]const u8 {
        _ = self;
        return @embedFile("../test.raw");
    }

    pub fn init(self: MacOSCamera) void {
        _ = self;
        std.debug.print("Init on on MacOS\n", .{});
    }
};
