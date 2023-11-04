const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;

const raylib = @import("raylib");

const SR = 44100;

var sin_osc = SinOsc.init(440);

pub const AudioProcessor = struct {
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,

    pub fn new() !AudioProcessor {
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

    pub fn free(
        self: *AudioProcessor,
    ) void {
        raylib.UnloadAudioStream(self.audio_stream);
        raylib.CloseAudioDevice();
    }

    pub fn play(self: *AudioProcessor) void {
        raylib.PlayAudioStream(self.audio_stream);
    }

    fn audio_stream_callback(buffer_data: ?*anyopaque, frames: u32) void {
        if (buffer_data != null) {
            var i: usize = 0;
            while (i < frames) : (i += 1) {
                const data: [*]i16 = @alignCast(@ptrCast(buffer_data));
                const sample = sin_osc.sample() * math.maxInt(i16);
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
        self.phase += self.inc;
        if (self.phase >= math.tau) self.phase -= math.tau;
        return @sin(self.phase);
    }
};
