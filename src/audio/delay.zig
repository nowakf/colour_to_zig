const std = @import("std");

const LPF = @import("lpf.zig").LPF;

const conf = @import("config.zig");

pub const Delay = struct {
    min_dur: usize,
    max_dur: usize,
    fb: f32,

    del_dur: usize,
    del_idx: usize = 0,
    buf: [conf.MAX_DELAY_LENGTH]f32,

    var_dur: usize,
    var_idx: usize = 0,

    lpf: LPF,

    prng: std.rand.DefaultPrng,

    pub fn init(min_dur: usize, max_dur: usize, fb: f32) Delay {
        // TODO: Use shared PRNG
        var prng = std.rand.DefaultPrng.init(0);

        const max_d = if (max_dur <= conf.MAX_DELAY_LENGTH) max_dur else conf.MAX_DELAY_LENGTH;
        const dur = prng.random().intRangeAtMost(usize, min_dur, max_d);

        return .{
            .buf = [_]f32{0.0} ** conf.MAX_DELAY_LENGTH,
            .min_dur = min_dur,
            .max_dur = max_d,
            .del_dur = dur,
            .fb = fb,
            .prng = prng,
            .lpf = LPF.init(0.125),
            .var_dur = conf.SR * 4,
        };
    }

    pub fn sample(self: *Delay, in: f32) f32 {
        const s = self.buf[self.del_idx];
        self.advance();
        self.buf[self.del_idx] = self.lpf.sample((self.buf[self.del_idx] + in) * self.fb);
        return s;
    }

    fn advance(self: *Delay) void {
        if (self.del_idx < self.del_dur - 1) {
            self.del_idx += 1;
        } else {
            self.del_idx = 0;
        }

        if (self.var_idx < self.var_dur - 1) {
            self.var_idx += 1;
        } else {
            const rand = self.prng.random();
            self.del_dur = rand.intRangeAtMost(usize, self.min_dur, self.max_dur);
            self.var_dur = rand.intRangeAtMost(usize, self.min_dur, self.max_dur);
            self.lpf.cut = rand.float(f32);
            self.var_idx = 0;
        }
    }
};
