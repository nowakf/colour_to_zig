const std = @import("std");

pub const LinuxCamera = struct {
    pub fn getFrame(self: LinuxCamera) void {
        _ = self;
        std.debug.print("Get frame on Linux\n", .{});
    }

    pub fn init(self: LinuxCamera) void {
        _ = self;
        std.debug.print("Init on on Linux\n", .{});
    }
};
