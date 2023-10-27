const std = @import("std");
const Allocator = std.mem.Allocator;

const PPM = struct {
    alc: Allocator,
    w: u32,
    h: u32,
    pix_bits: u32,
    data: []u8,
};

