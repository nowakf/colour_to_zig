const conf = @import("config.zig");

pub const Delay = struct {
    buf: [conf.MAX_DELAY_LENGTH]f32,
    idx: usize = 0,
    dur: usize,
    fb: f32,

    pub fn init(dur: usize, fb: f32) Delay {
        return .{
            .buf = [_]f32{0.0} ** conf.MAX_DELAY_LENGTH,
            .dur = if (dur <= conf.MAX_DELAY_LENGTH) dur else conf.MAX_DELAY_LENGTH,
            .fb = fb,
        };
    }

    pub fn sample(self: *Delay, in: f32) f32 {
        self.buf[self.idx] = (self.buf[self.idx] * self.fb) + in;
        self.advance();
        return self.buf[self.idx];
    }

    fn advance(self: *Delay) void {
        if (self.idx < self.dur - 1) {
            self.idx += 1;
        } else {
            self.idx = 0;
        }
    }
};
