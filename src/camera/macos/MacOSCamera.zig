const std = @import("std");

const c = @cImport({
    @cInclude("openpnp-capture.h");
});

pub const MacOSCamera = struct {
    pub fn getFrame(self: MacOSCamera) [*:0]const u8 {
        _ = self;
        return @embedFile("../test.raw");
    }

    pub fn init(self: MacOSCamera) void {
        const context = c.Cap_createContext();
        _ = context;
        _ = self;
        std.debug.print("Init on on MacOS\n", .{});
    }
};
