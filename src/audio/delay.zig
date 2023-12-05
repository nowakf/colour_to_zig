const std = @import("std");
const Random = std.rand.Random;

const LPF = @import("lpf.zig").LPF;

const conf = @import("config.zig");

pub const Delay = struct {
    min_del_time: usize,
    max_del_time: usize,
    fb: f32,

    min_var_time: usize,
    max_var_time: usize,

    del_time: usize,
    del_idx: usize = 0,
    buf: [conf.MAX_DEL_LENGTH]f32,

    var_time: usize,
    var_idx: usize = 0,

    lpf: LPF,

    rand: *Random,

    pub fn init(
        rand: *Random,
        min_del_time: usize,
        max_del_time: usize,
        fb: f32,
        min_var_time: usize,
        max_var_time: usize,
    ) Delay {
        const max_del_time_limited = if (max_del_time <= conf.MAX_DEL_LENGTH) max_del_time else conf.MAX_DEL_LENGTH;
        const del_time = rand.intRangeAtMost(usize, min_del_time, max_del_time_limited);

        const var_time = rand.intRangeAtMost(usize, min_var_time, max_var_time);

        const lpf_freq = rand.float(f32) * 10000 + 2000;

        return .{
            .min_del_time = min_del_time,
            .max_del_time = max_del_time_limited,
            .min_var_time = min_var_time,
            .max_var_time = max_var_time,
            .fb = fb,
            .del_time = del_time,
            .buf = [_]f32{0.0} ** conf.MAX_DEL_LENGTH,
            .var_time = var_time,
            .lpf = LPF.init(lpf_freq, conf.DEL_LPF_RES),
            .rand = rand,
        };
    }

    pub fn sample(self: *Delay, in: f32) f32 {
        const s = self.buf[self.del_idx];
        self.advance();
        self.buf[self.del_idx] = self.lpf.sample((self.buf[self.del_idx] + in) * self.fb);
        return s;
    }

    fn advance(self: *Delay) void {
        if (self.del_idx < self.del_time - 1) {
            self.del_idx += 1;
        } else {
            self.del_idx = 0;
        }

        if (self.var_idx < self.var_time - 1) {
            self.var_idx += 1;
        } else {
            self.del_time = self.rand.intRangeAtMost(usize, self.min_del_time, self.max_del_time);
            self.var_time = self.rand.intRangeAtMost(usize, self.min_del_time, self.max_del_time);
            self.lpf.freq = conf.MIN_DEL_LPF_FREQ + self.rand.float(f32) * (conf.MAX_DEL_LPF_FREQ - conf.MIN_DEL_LPF_FREQ);
            self.var_idx = 0;
        }
    }
};
