const std = @import("std");

const raylib = @import("raylib");

const Camera = @import("../camera.zig");

const conf = @import("../config.zig");

pub const CameraTrigger = struct {
    img: []u8,
    threshold: f32,
    w: usize,
    h: usize,
    last_diff: f32 = 0.0,
    tracking_inc: f32 = conf.TRIG_TRACKING_INC,
    tracking_dec: f32 = conf.TRIG_TRACKING_DEC,
    activity: f32 = 0.0,

    pub fn init(img: []u8, w: usize, h: usize, threshold: f32) CameraTrigger {
        return .{
            .img = img,
            .w = w,
            .h = h,
            .threshold = threshold,
        };
    }

    pub fn poll(self: *CameraTrigger) bool {
        self.processKeys();

        self.activity = @max(self.activity - self.tracking_dec, 0.0);

        if (self.getDiff() > self.threshold) {
            self.activity = @min(self.activity + self.tracking_inc, 1.0);
            return true;
        } else {
            return false;
        }
    }

    fn processKeys(self: *CameraTrigger) void {
        if (raylib.IsKeyPressed(conf.KEY_AUDIO_TRIG_THRESH_DEC) and self.threshold > 10) {
            self.threshold -= 10;
        }

        if (raylib.IsKeyPressed(conf.KEY_AUDIO_TRIG_THRESH_INC)) {
            self.threshold += 10;
        }

        if (raylib.IsKeyPressed(conf.KEY_TRACKING_INC_DEC) and self.tracking_inc > 0.005) {
            self.tracking_inc -= 0.005;
        }

        if (raylib.IsKeyPressed(conf.KEY_TRACKING_INC_INC)) {
            self.tracking_inc += 0.005;
        }

        if (raylib.IsKeyPressed(conf.KEY_TRACKING_DEC_DEC) and self.tracking_dec > 0.001) {
            self.tracking_dec -= 0.001;
        }

        if (raylib.IsKeyPressed(conf.KEY_TRACKING_INC)) {
            self.tracking_dec += 0.001;
        }
    }

    fn getDiff(self: *CameraTrigger) f32 {
        const sum = self.getSum();
        const diff = @abs(sum - self.last_diff);
        self.last_diff = sum;
        return diff;
    }

    fn getSum(self: *CameraTrigger) f32 {
        const a = self.getValueAt(self.w / 4, self.h / 4);
        const b = self.getValueAt(self.w / 4, self.h - self.h / 4);
        const c = self.getValueAt(self.w - self.w / 4, self.h / 4);
        const d = self.getValueAt(self.w - self.w / 4, self.h - self.h / 4);
        return a + b + c + d;
    }

    fn getValueAt(self: *CameraTrigger, x: usize, y: usize) f32 {
        const i = (y * self.w + x) * 3;
        return @floatFromInt(
            @as(i32, self.img[i]) + @as(i32, self.img[i]) + @as(i32, self.img[i + 2]),
        );
    }
};
