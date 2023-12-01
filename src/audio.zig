const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const raylib = @import("raylib");

const SR = 44100;

const N_VOICES = 16;
const N_PARTIALS = 8;

const ATTACK = 0.01;
const DECAY = 2;
const MAX_FREQ = 10_000;

const MAX_DELAY_LENGTH = SR * 10;

var synth: Synth = undefined;
var delay: Delay = undefined;

pub const AudioProcessor = struct {
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,

    pub fn init() AudioProcessor {
        synth = Synth.init();
        delay = Delay.init(0.2 * SR, 0.75);

        var audio_processor: AudioProcessor = .{};

        raylib.InitAudioDevice();
        raylib.SetAudioStreamBufferSizeDefault(audio_processor.max_samples_per_update);

        audio_processor.audio_stream = raylib.LoadAudioStream(SR, 16, 1);
        raylib.SetAudioStreamCallback(
            audio_processor.audio_stream,
            &audio_stream_callback,
        );

        return audio_processor;
    }

    pub fn deinit(self: *AudioProcessor) void {
        raylib.UnloadAudioStream(self.audio_stream);
        raylib.CloseAudioDevice();
    }

    pub fn play(self: *AudioProcessor) void {
        raylib.PlayAudioStream(self.audio_stream);
    }

    pub fn update(self: *AudioProcessor) !void {
        // TODO: Remove unused self reference
        _ = self;
        if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_SPACE)) {
            try synth.trig();
        }
    }

    fn audio_stream_callback(buffer_data: ?*anyopaque, frames: u32) void {
        if (buffer_data != null) {
            for (0..frames) |i| {
                const data: [*]i16 = @alignCast(@ptrCast(buffer_data));

                const sample = synth.sample() * math.maxInt(i16);
                const delayed = delay.sample(sample);

                const mix = sample + delayed;

                data[i] = @intFromFloat(mix);
            }
        }
    }
};

const Delay = struct {
    buf: [MAX_DELAY_LENGTH]f32,
    idx: usize = 0,
    dur: usize,
    fb: f32,

    pub fn init(dur: usize, fb: f32) Delay {
        return .{
            .buf = [_]f32{0.0} ** MAX_DELAY_LENGTH,
            .dur = dur,
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

const Synth = struct {
    voices: [N_VOICES]?Voice,

    pub fn init() Synth {
        return .{
            .voices = [_]?Voice{null} ** N_VOICES,
        };
    }

    pub fn trig(self: *Synth) !void {
        for (0..self.voices.len) |i| {
            if (self.voices[i] == null) {
                self.voices[i] = try Voice.init(ATTACK, DECAY);
                break;
            } else if (self.voices[i].?.finished()) {
                self.voices[i] = try Voice.init(ATTACK, DECAY);
                break;
            }
        }
    }

    pub fn sample(self: *Synth) f32 {
        var s: f32 = 0.0;
        for (0..self.voices.len) |i| {
            if (self.voices[i] != null) {
                s += self.voices[i].?.sample() / @as(f32, @floatFromInt(N_VOICES));
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
    oscs: [N_PARTIALS]SinOsc,

    pub fn init() !OscBank {
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.os.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        const rand = prng.random();

        const oscs = init: {
            var initial_value: [N_PARTIALS]SinOsc = undefined;
            for (
                &initial_value,
            ) |*osc| {
                osc.* = SinOsc.init(rand.float(f32) * MAX_FREQ);
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
            .inc = math.tau * freq / SR,
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
            .a = @intFromFloat(a * SR),
            .d = @intFromFloat(d * SR),
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
