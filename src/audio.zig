const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;

const raylib = @import("raylib");

pub const AudioProcessor = struct {
    max_samples: i32 = 512,
    max_samples_per_update: i32 = 4096,
    audio_stream: raylib.AudioStream = undefined,
    audio_callback: *const fn (bufferData: ?*anyopaque, frames: u32) void = undefined,
    write_buffer: []f16 = undefined,

    pub fn new(allocator: Allocator) !AudioProcessor {
        var audio_processor: AudioProcessor = .{};

        audio_processor.write_buffer = try allocator.alloc(f16, @intCast(audio_processor.max_samples_per_update));

        raylib.InitAudioDevice();
        raylib.SetAudioStreamBufferSizeDefault(audio_processor.max_samples_per_update);

        audio_processor.audio_stream = raylib.LoadAudioStream(44100, 16, 1);
        raylib.SetAudioStreamCallback(
            audio_processor.audio_stream,
            &audio_stream_callback,
        );

        return audio_processor;
    }

    pub fn free(self: *AudioProcessor, allocator: Allocator) void {
        allocator.free(self.write_buffer);
        raylib.UnloadAudioStream(self.audio_stream);
        raylib.CloseAudioDevice();
    }

    pub fn play(self: *AudioProcessor) void {
        raylib.PlayAudioStream(self.audio_stream);
    }

    fn audio_stream_callback(buffer_data: ?*anyopaque, frames: u32) void {
        _ = frames;
        _ = buffer_data;
        // if (buffer_data != null) {
        //     var i: usize = 0;
        //     while (i < frames) : (i += 1) {
        //         const value = @sin(@as(f16, @floatFromInt(i * 10)));
        //         const data: [*]f16 = @alignCast(@ptrCast(buffer_data));
        //         data[i] = value;
        //         std.debug.print("{} {}\n", .{ i, value });
        //     }
        // }
    }
};
