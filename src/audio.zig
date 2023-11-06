const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const raylib = @import("raylib");

const SR = 44100;
const N_OSCS = 8;

var bell: Bell = undefined;

pub const AudioProcessor = struct {
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,

    pub fn init(alllocator: Allocator) !AudioProcessor {
        bell = try Bell.init(alllocator, 0.01, 1.2);

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

    pub fn free(self: *AudioProcessor, allocator: Allocator) void {
        bell.free(allocator);

        raylib.UnloadAudioStream(self.audio_stream);
        raylib.CloseAudioDevice();
    }

    pub fn play(self: *AudioProcessor) void {
        raylib.PlayAudioStream(self.audio_stream);
    }

    fn audio_stream_callback(buffer_data: ?*anyopaque, frames: u32) void {
        if (buffer_data != null) {
            for (0..frames) |i| {
                const data: [*]i16 = @alignCast(@ptrCast(buffer_data));
                const sample = bell.sample() * math.maxInt(i16);
                data[i] = @intFromFloat(sample);
            }
        }
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

const OscBank = struct {
    oscs: []SinOsc,

    pub fn init(allocator: Allocator, n_oscs: usize) !OscBank {
        var prng = std.rand.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.os.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });

        var oscs = try allocator.alloc(SinOsc, n_oscs);

        for (0..n_oscs) |i| {
            const rand = prng.random();
            const freq = rand.float(f32) * 18_000 + 2000;
            const osc = SinOsc.init(freq);
            oscs[i] = osc;
        }

        return .{ .oscs = oscs };
    }

    pub fn free(self: *OscBank, allocator: Allocator) void {
        allocator.free(self.oscs);
    }

    pub fn sample(self: *OscBank) f32 {
        var s: f32 = 0.0;

        for (0..self.oscs.len) |i| {
            s += self.oscs[i].sample() / 12.0;
        }

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
};

const Bell = struct {
    osc_bank: OscBank,
    env: Env,

    pub fn init(allocator: Allocator, a: f32, d: f32) !Bell {
        return .{
            .osc_bank = try OscBank.init(allocator, N_OSCS),
            .env = Env.init(a, d),
        };
    }

    pub fn free(self: *Bell, allocator: Allocator) void {
        self.osc_bank.free(allocator);
    }

    pub fn sample(self: *Bell) f32 {
        return self.osc_bank.sample() * self.env.sample();
    }
};
