const FrameIter = @import("iter.zig").FrameIter;

pub const Camera = struct {
};


pub fn iter(self: @This()) FrameIter {
    _ = self;
    @panic("");
}
