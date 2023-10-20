//unified interface to frame-grabbers:
//my guess is this is very unsafe
pub const FrameIter = struct {
    ptr: *anyopaque,
    vtable: struct {
        next: *const fn (ctx: *anyopaque, buf: []u8) ?usize,
    },
    pub fn next(self: @This(), buf: []u8) ?usize {
        return self.vtable.next(self.ptr, buf);
    }
};

pub const Config = struct {
};

pub fn Stdin(comptime cfg: Config) type {
    _ = cfg;
    return struct {
        w : u32 = 100,
        h : u32 = 100,
        const Self = @This(); 
        pub fn next(self: *anyopaque, buf: []u8) ?usize {
            _ = buf;
            _ = self;
            return null;
        }
        pub fn iter(self: *Self) FrameIter {
            return .{
                .ptr = self,
                .vtable = .{
                    .next = next,
                },
            };
        }
    };
}

pub fn Cam(comptime args: Config) type {
    _ = args;
    if (@import("builtin").os.tag == .linux) {
        return @import("v4l2.zig");
    } else {
        return struct {
            const Self = @This();
            pub fn iter(self: Self) FrameIter {
                _ = self;
                @panic("no camera available for this machine\n");
            }
        };
    }
}


