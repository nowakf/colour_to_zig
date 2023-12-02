const std = @import("std");

const conf = @import("config.zig");

pub const VarDelay = struct {
    min_dur: usize,
    max_dur: usize,
    fb: f32,

    del_dur: usize,
    del_idx: usize = 0,
    buf: [conf.MAX_DELAY_LENGTH]f32,

    var_dur: usize,
    var_idx: usize = 0,

    prng: std.rand.DefaultPrng,

    pub fn init(min_dur: usize, max_dur: usize, fb: f32) VarDelay {
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
            .var_dur = conf.SR * 4,
        };
    }

    pub fn sample(self: *VarDelay, in: f32) f32 {
        self.buf[self.del_idx] = (self.buf[self.del_idx] * self.fb) + in;
        self.advance();
        return self.buf[self.del_idx];
    }

    fn advance(self: *VarDelay) void {
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
            self.var_idx = 0;
        }
    }
};
