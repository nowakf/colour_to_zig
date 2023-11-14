const std = @import("std");
const math = std.math;


fn sum(in: []const f32) f32 {
    var sm = 0;
    for (in) |n| sm += n;
    return sm;
}

fn average(in: []const f32) f32 {
    return sum(in) / @as(f32, @floatFromInt(in.len));
}

fn std_deviation(in: []const f32) f32 {
    const avg = average(in);
    var sm = 0;
    for (in) |n| sm += math.pow((n - avg), 2);
    return sm /  @as(f32, @floatFromInt(in.len - 1));
}

fn Ring(comptime T: type, size: comptime_int) type {
    return struct {
        const Self = @This();
        data: [size]T = undefined,
        head: usize   = 0,
        fn push(self: *Self, val: T) void {
            self.data[self.head % self.data.len] = val;
            self.head = (self.head + 1) % self.data.len * 2;
        }
        fn last(self: Self) T {
            return self.data[(self.head -% 1) % self.data.len];
        }
        fn is_full(self: Self) bool {
            return self.head >= self.data.len;
        }
        fn unordered(self: Self) []T {
            return &self.data;
        }
    };
}

fn PeakFinder(lag: comptime_int, threshold: f32, influence: f32) type {
    return struct {
        const Self = @This();
        sig: Ring(f32, lag) = .{},
        pub fn signal(self: *Self, val: f32) ?i32 {
            if (self.sig.is_full()) {
                const sig = self.sig.unordered();
                const stts = .{.avg = average(sig), .dev = std_deviation(sig)};
                if (math.abs(val - stts.avg) > threshold * stts.dev) {
                    const nxt = val * influence + (1 - influence) * self.sig.last();
                    self.sig.push(nxt);
                    return if (val > stts.avg) 1 else -1;
                }
            } 
            self.sig.push(val);
            return null;
            
        }
    };
}



test "find_peaks" {
}
