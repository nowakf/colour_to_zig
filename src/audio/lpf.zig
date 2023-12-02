const conf = @import("config.zig");

pub const LPF = struct {
    cut: f32,
    last: f32 = 0.0,

    pub fn init(cut: f32) LPF {
        return .{
            .cut = cut,
        };
    }

    pub fn sample(self: *LPF, in: f32) f32 {
        const diff = in - self.last;
        self.last += diff * self.cut;
        return self.last;
    }
};
