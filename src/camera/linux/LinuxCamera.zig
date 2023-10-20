const std = @import("std");

pub const LinuxCamera = struct {
    pub fn getFrame(self: LinuxCamera) [*:0]const u8 {
        _ = self;
        return @embedFile("../test.raw");
    }

    pub fn init(self: LinuxCamera) void {
        _ = self;
        std.debug.print("Init on on Linux\n", .{});
    }
};
