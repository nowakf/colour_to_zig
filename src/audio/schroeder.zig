const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Schroeder = struct {
    ap_a: Allpass,
    ap_b: Allpass,
    ap_c: Allpass,

    pub fn init(allocator: Allocator) !Schroeder {
        return .{
            .ap_a = try Allpass.init(allocator, 1051, 0.7, 0.7),
            .ap_b = try Allpass.init(allocator, 337, 0.7, 0.7),
            .ap_c = try Allpass.init(allocator, 113, 0.7, 0.7),
        };
    }

    pub fn deinit(self: *Schroeder, allocator: Allocator) !void {
        allocator.free(self.ap);
    }

    pub fn sample(self: *Schroeder, in: f32) f32 {
        var s = self.ap_a.sample(in);
        s = self.ap_b.sample(s);
        s = self.ap_c.sample(s);
        return s;
    }
};

pub const Allpass = struct {
    fb: f32,
    ff: f32,
    idx: usize = 0,
    buf: []f32,

    pub fn init(allocator: Allocator, len: usize, fb: f32, ff: f32) !Allpass {
        const buf = try allocator.alloc(f32, len);

        for (0..buf.len) |i| {
            buf[i] = 0.0;
        }

        return .{
            .fb = fb,
            .ff = ff,
            .buf = buf,
        };
    }

    pub fn deinit(self: *Allpass, allocator: Allocator) !void {
        allocator.free(self.buf);
    }

    pub fn sample(self: *Allpass, in: f32) f32 {
        const del = self.buf[self.idx];
        const out = self.ff * in - del;
        self.buf[self.idx] = in + out * self.fb;
        self.idx = (self.idx + 1) % self.buf.len;
        return out;
    }
};
