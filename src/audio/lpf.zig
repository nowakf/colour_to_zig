const std = @import("std");
const math = std.math;

const conf = @import("../config.zig");

pub const LPF = struct {
    freq: f32,
    res: f32,
    s1: f32 = 0.0,
    s2: f32 = 0.0,

    pub fn init(freq: f32, res: f32) LPF {
        return .{
            .freq = freq,
            .res = res,
        };
    }

    pub fn sample(self: *LPF, in: f32) f32 {
        const g = @tan(math.pi * self.freq / conf.SR);
        const damping = 1.0 / self.res;
        const a1 = 1.0 / (1.0 + g * (g + damping));
        const a2 = g * a1;
        const a3 = g * a2;
        const m0 = 0.0;
        const m1 = 0.0;
        const m2 = 1.0;

        const y0 = (m0 * in + m1 * self.s1 + m2 * self.s2) * a1;
        const y1 = a2 * (in - y0) + self.s1;
        const y2 = a3 * (in - y0) + self.s2;

        self.s1 = 2.0 * y1 - self.s1;
        self.s2 = 2.0 * y2 - self.s2;

        return y0;
    }
};
