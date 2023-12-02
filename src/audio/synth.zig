const std = @import("std");
const math = std.math;

const conf = @import("config.zig");

pub const Synth = struct {
    voices: [conf.N_VOICES]?Voice,

    pub fn init() Synth {
        return .{
            .voices = [_]?Voice{null} ** conf.N_VOICES,
        };
    }

    pub fn trig(self: *Synth) !void {
        // TODO: Use shared PRNG
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.os.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        const decay = conf.MIN_DECAY + rand.float(f32) * (conf.MAX_DECAY - conf.MIN_DECAY);

        for (0..self.voices.len) |i| {
            if (self.voices[i] == null) {
                self.voices[i] = try Voice.init(conf.ATTACK, decay);
                break;
            } else if (self.voices[i].?.finished()) {
                self.voices[i] = try Voice.init(conf.ATTACK, decay);
                break;
            }
        }
    }

    pub fn sample(self: *Synth) f32 {
        var s: f32 = 0.0;
        for (0..self.voices.len) |i| {
            if (self.voices[i] != null) {
                s += self.voices[i].?.sample() / @as(f32, @floatFromInt(conf.N_VOICES));
            }
        }
        return s;
    }
};

const Voice = struct {
    osc_bank: OscBank,
    env: Env,

    pub fn init(a: f32, d: f32) !Voice {
        return .{
            .osc_bank = try OscBank.init(),
            .env = Env.init(a, d),
        };
    }

    pub fn sample(self: *Voice) f32 {
        if (!self.finished()) {
            return self.osc_bank.sample() * self.env.sample();
        } else {
            return 0.0;
        }
    }

    pub fn finished(self: *Voice) bool {
        return self.env.finished();
    }
};

const OscBank = struct {
    oscs: [conf.N_PARTIALS]SinOsc,

    pub fn init() !OscBank {
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.os.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        const oscs = init: {
            var initial_value: [conf.N_PARTIALS]SinOsc = undefined;
            for (
                &initial_value,
            ) |*osc| {
                osc.* = SinOsc.init(rand.float(f32) * conf.MAX_FREQ);
            }

            break :init initial_value;
        };

        return .{ .oscs = oscs };
    }

    pub fn sample(self: *OscBank) f32 {
        var s: f32 = 0.0;
        for (0..self.oscs.len) |i| {
            s += self.oscs[i].sample() / @as(f32, @floatFromInt(self.oscs.len));
        }
        return s;
    }
};

const SinOsc = struct {
    freq: f32,
    inc: f32,
    phase: f32 = 0.0,

    pub fn init(freq: f32) SinOsc {
        return .{
            .freq = freq,
            .inc = math.tau * freq / conf.SR,
        };
    }

    pub fn sample(self: *SinOsc) f32 {
        const s = @sin(self.phase);
        self.phase += self.inc;
        if (self.phase >= math.tau) self.phase -= math.tau;
        return s;
    }
};

const Env = struct {
    a: u32,
    d: u32,
    i: u32 = 0,

    pub fn init(a: f32, d: f32) Env {
        return .{
            .a = @intFromFloat(a * conf.SR),
            .d = @intFromFloat(d * conf.SR),
        };
    }

    pub fn sample(self: *Env) f32 {
        var s: f32 = 0.0;
        if (self.i < self.a) {
            s = 1.0 - @exp(-5.0 * @as(f32, @floatFromInt(self.i)) / @as(f32, @floatFromInt(self.a)));
        } else if (self.i < self.a + self.d) {
            s = @exp(-5.0 * @as(f32, @floatFromInt(self.i - self.a)) / @as(f32, @floatFromInt(self.d)));
        }
        self.i += 1;
        return s;
    }

    pub fn finished(self: *Env) bool {
        return self.i == self.a + self.d;
    }
};
