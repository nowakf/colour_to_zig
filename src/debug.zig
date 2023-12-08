const std = @import("std");
const fmt = std.fmt;

const AudioProcessor = @import("audio/processor.zig").AudioProcessor;

const raylib = @import("raylib");

const conf = @import("config.zig");

pub const DebugInfo = struct {
    show: bool = false,
    audio_processor: *AudioProcessor,

    pub fn init(audio_processor: *AudioProcessor) DebugInfo {
        return .{
            .audio_processor = audio_processor,
        };
    }

    pub fn draw(self: *DebugInfo, allocator: std.mem.Allocator) !void {
        if (raylib.IsKeyPressed(raylib.KeyboardKey.KEY_F1)) {
            self.show = !self.show;
        }

        if (self.show) {
            try self.drawDebugInfo(allocator);
        }
    }

    fn drawDebugInfo(self: *DebugInfo, allocator: std.mem.Allocator) !void {
        const fps = try std.fmt.allocPrintZ(
            allocator,
            "FPS: {d}",
            .{raylib.GetFPS()},
        );
        defer allocator.free(fps);
        raylib.DrawText(
            fps,
            conf.DEBUG_GAP,
            conf.DEBUG_GAP,
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );

        const thresh = try std.fmt.allocPrintZ(
            allocator,
            "THRESH. (Q/W) {d}",
            .{self.audio_processor.trigger.threshold},
        );
        defer allocator.free(thresh);
        raylib.DrawText(
            thresh,
            conf.DEBUG_GAP,
            conf.DEBUG_GAP * 2,
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );

        const activity_att = try std.fmt.allocPrintZ(
            allocator,
            "ACT. INC. (A/S) {d:.3}",
            .{self.audio_processor.trigger.tracking_inc},
        );
        defer allocator.free(activity_att);
        raylib.DrawText(
            activity_att,
            conf.DEBUG_GAP,
            conf.DEBUG_GAP * 3,
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );

        const activity_dec = try std.fmt.allocPrintZ(
            allocator,
            "ACT. DEC. (D/F) {d:.3}",
            .{self.audio_processor.trigger.tracking_dec},
        );
        defer allocator.free(activity_dec);
        raylib.DrawText(
            activity_dec,
            conf.DEBUG_GAP,
            conf.DEBUG_GAP * 4,
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );

        raylib.DrawRectangleLines(
            conf.DEBUG_GAP,
            conf.DEBUG_GAP * 5,
            conf.DEBUG_GAP * 4,
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );
        raylib.DrawRectangle(
            conf.DEBUG_GAP,
            conf.DEBUG_GAP * 5,
            @intFromFloat(self.audio_processor.trigger.activity * 200.0),
            conf.DEBUG_FONT_SIZE,
            conf.DEBUG_COLOR,
        );
    }
};
