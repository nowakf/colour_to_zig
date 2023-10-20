const std = @import("std");

const c = @cImport({
    @cInclude("openpnp-capture.h");
});

pub const MacOSCamera = struct {
    context: *anyopaque = undefined,

    pub fn getFrame(self: *MacOSCamera) [*:0]const u8 {
        const count = c.Cap_getDeviceCount(self.context);
        std.debug.print("{}", .{count});

        return @embedFile("../test.raw");
    }

    pub fn init(self: *MacOSCamera) void {
        // Why is this optional?
        self.context = c.Cap_createContext().?;
    }
};
