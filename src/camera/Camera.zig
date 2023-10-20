const LinuxCamera = @import("linux/LinuxCamera.zig").LinuxCamera;
const MacOSCamera = @import("macos/MacOSCamera.zig").MacOSCamera;

pub const Camera = union(enum) {
    linux: LinuxCamera,
    macos: MacOSCamera,

    pub fn getFrame(self: Camera) void {
        switch (self) {
            inline else => |camera| camera.getFrame(),
        }
    }

    pub fn init(self: Camera) void {
        switch (self) {
            inline else => |camera| camera.init(),
        }
    }
};
