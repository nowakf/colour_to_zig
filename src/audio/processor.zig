const std = @import("std");
const math = std.math;

const raylib = @import("raylib");

const Delay = @import("delay.zig").Delay;
const Synth = @import("synth.zig").Synth;

const conf = @import("config.zig");

var synth: Synth = undefined;
var delay: Delay = undefined;

pub const AudioProcessor = struct {
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,

    pub fn init() AudioProcessor {
        synth = Synth.init();
        delay = Delay.init(2 * conf.SR, 0.0);

        var audio_processor: AudioProcessor = .{};

        raylib.InitAudioDevice();
        raylib.SetAudioStreamBufferSizeDefault(audio_processor.max_samples_per_update);

        audio_processor.audio_stream = raylib.LoadAudioStream(conf.SR, 16, 1);
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