const std = @import("std");

const Camera = @import("../camera.zig");

pub const CameraTrigger = struct {
    img: []u8,
    threshold: f32,
    w: usize,
    h: usize,
    last_diff: f32 = 0.0,

    pub fn init(img: []u8, w: usize, h: usize, threshold: f32) CameraTrigger {
        return .{
            .img = img,
            .w = w,
            .h = h,
            .threshold = threshold,
        };
    }

    pub fn poll(self: *CameraTrigger) bool {
        if (self.getDiff() > self.threshold) {
            return true;
        } else {
            return false;
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
