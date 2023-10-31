const std = @import("std");
const Allocator = std.mem.Allocator;

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
        raylib.SetAudioStreamCallback(audio_processor.audio_stream, &audio_callback);

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

    pub fn process(self: *AudioProcessor) void {
        if (raylib.IsAudioStreamProcessed(self.audio_stream)) {
            var write_cursor: usize = 0;
            while (write_cursor < self.max_samples_per_update) : (write_cursor += 1) {}

            raylib.UpdateAudioStream(
                self.audio_stream,
                self.write_buffer.ptr,
                self.max_samples_per_update,
            );
            //     std.debug.print("Processed\n", .{});
        }
    }

    fn audio_callback(bufferData: ?*anyopaque, frames: u32) void {
        _ = frames;
        _ = bufferData;
        // std.debug.print("SetTargetFPS", .{});
    }
};
