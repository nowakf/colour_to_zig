const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const raylib = @import("raylib");

const Camera = @import("../camera.zig");
const CameraTrigger = @import("trigger.zig").CameraTrigger;
const Delay = @import("delay.zig").Delay;
const Schroeder = @import("schroeder.zig").Schroeder;
const Synth = @import("synth.zig").Synth;

const conf = @import("../config.zig");

var synth: Synth = undefined;
var delay_a: Delay = undefined;
var delay_b: Delay = undefined;
var delay_c: Delay = undefined;
var schroeder: Schroeder = undefined;

pub const AudioProcessor = struct {
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,
    trigger: CameraTrigger,

    pub fn init(allocator: Allocator, rand: *std.rand.Random, cam: *const Camera) !AudioProcessor {
        synth = Synth.init(rand);

        delay_a = Delay.init(
            rand,
            conf.DEL_A_MIN_DEL_TIME,
            conf.DEL_A_MAX_DEL_TIME,
            conf.DEL_A_FB,
            conf.DEL_A_MIN_VAR_TIME,
            conf.DEL_A_MAX_VAR_TIME,
        );
        delay_b = Delay.init(
            rand,
            conf.DEL_B_MIN_DEL_TIME,
            conf.DEL_B_MAX_DEL_TIME,
            conf.DEL_B_FB,
            conf.DEL_B_MIN_VAR_TIME,
            conf.DEL_B_MAX_VAR_TIME,
        );
        delay_c = Delay.init(
            rand,
            conf.DEL_C_MIN_DEL_TIME,
            conf.DEL_C_MAX_DEL_TIME,
            conf.DEL_C_FB,
            conf.DEL_C_MIN_VAR_TIME,
            conf.DEL_C_MAX_VAR_TIME,
        );

        schroeder = try Schroeder.init(allocator);

        var audio_processor: AudioProcessor = .{
            .trigger = CameraTrigger.init(
                cam.buf,
                @as(usize, @as(u32, cam.info.width)),
                @as(usize, @as(u32, cam.info.height)),
                conf.TRIG_THRESHOLD,
            ),
        };

        raylib.InitAudioDevice();
        raylib.SetAudioStreamBufferSizeDefault(audio_processor.max_samples_per_update);

        audio_processor.audio_stream = raylib.LoadAudioStream(conf.SR, 16, 1);
        raylib.SetAudioStreamCallback(
            audio_processor.audio_stream,
            &audio_stream_callback,
        );

        return audio_processor;
    }

    pub fn deinit(self: *AudioProcessor, allocator: Allocator) void {
        schroeder.deinit(allocator);

        raylib.UnloadAudioStream(self.audio_stream);
        raylib.CloseAudioDevice();
    }

    pub fn play(self: *AudioProcessor) void {
        raylib.PlayAudioStream(self.audio_stream);
    }

    pub fn update(self: *AudioProcessor) void {
        if (raylib.IsKeyPressed(conf.KEY_AUDIO_TRIG_THRESH_DEC)) {
            self.trigger.threshold -= 10;
            std.debug.print("Trigger threshold: {d}\n", .{self.trigger.threshold});
        }

        if (raylib.IsKeyPressed(conf.KEY_AUDIO_TRIG_THRESH_INC)) {
            self.trigger.threshold += 10;
            std.debug.print("Trigger threshold: {d}\n", .{self.trigger.threshold});
        }

        if (self.trigger.poll()) {
            synth.trig();
        }
    }

    fn audio_stream_callback(buffer_data: ?*anyopaque, frames: u32) void {
        if (buffer_data != null) {
            for (0..frames) |i| {
                const data: [*]i16 = @alignCast(@ptrCast(buffer_data));

                const sample = synth.sample();

                const delayed_a = delay_a.sample(sample);
                const delayed_b = delay_b.sample(delayed_a);

                var mix = sample * 0.3 + delayed_b * 0.3 + delayed_a * 0.3;

                const rev = schroeder.sample(mix);
                mix = mix * 0.5 + rev * 0.5;

                mix = mix * 0.5 + delay_c.sample(mix) * 0.5;

                mix = mix * math.maxInt(i16);
                mix = @max(mix, math.minInt(i16));
                mix = @min(mix, math.maxInt(i16));

                data[i] = @intFromFloat(mix);
            }
        }
    }
};
