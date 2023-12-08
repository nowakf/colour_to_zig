const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Schroeder = struct {
    c_a: Comb,
    c_b: Comb,
    c_c: Comb,
    c_d: Comb,
    ap_a: Allpass,
    ap_b: Allpass,
    ap_c: Allpass,

    pub fn init(allocator: Allocator) !Schroeder {
        return .{
            .c_a = try Comb.init(allocator, 4799, 0.805),
            .c_b = try Comb.init(allocator, 4999, 0.827),
            .c_c = try Comb.init(allocator, 5399, 0.883),
            .c_d = try Comb.init(allocator, 5801, 0.864),
            .ap_a = try Allpass.init(allocator, 1051, 0.7, 0.7),
            .ap_b = try Allpass.init(allocator, 337, 0.7, 0.7),
            .ap_c = try Allpass.init(allocator, 113, 0.7, 0.7),
        };
    }

    pub fn deinit(self: *Schroeder, allocator: Allocator) void {
        self.c_a.deinit(allocator);
        self.c_b.deinit(allocator);
        self.c_c.deinit(allocator);
        self.c_d.deinit(allocator);
        self.ap_a.deinit(allocator);
        self.ap_b.deinit(allocator);
        self.ap_c.deinit(allocator);
    }

    pub fn sample(self: *Schroeder, in: f32) f32 {
        const c_a = self.c_a.sample(in);
        const c_b = self.c_b.sample(in);
        const c_c = self.c_c.sample(in);
        const c_d = self.c_d.sample(in);

        var s = c_a * 0.25 + c_b * 0.25 + c_c * 0.25 + c_d * 0.25;

        s = self.ap_a.sample(in);
        s = self.ap_b.sample(s);
        s = self.ap_c.sample(s);

        return s;
    }
};

pub const Comb = struct {
    fb: f32,
    idx: usize = 0,
    buf: []f32,

    pub fn init(allocator: Allocator, len: usize, fb: f32) !Comb {
        const buf = try allocator.alloc(f32, len);

        for (0..buf.len) |i| {
            buf[i] = 0.0;
        }

        return .{
            .fb = fb,

            .buf = buf,
        };
    }

    pub fn deinit(self: *Comb, allocator: Allocator) void {
        allocator.free(self.buf);
    }

    pub fn sample(self: *Comb, in: f32) f32 {
        const del = self.buf[self.idx];
        const out = in + self.fb * del;
        self.buf[self.idx] = out;
        self.idx = (self.idx + 1) % self.buf.len;
        return out;
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

    pub fn deinit(self: *Allpass, allocator: Allocator) void {
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
