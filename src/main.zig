const t = @import("moore.zig");

const std = @import("std");
const argparse = @import("argparse.zig");
const sod = @import("sod.zig");
const File = std.fs.File;

const YUYV_BYTES : u32 = 2;

const StdinIter = struct {
    stdin : File,
    const Self = @This();

    fn next(self: Self, buf: []u8) ?[]const u8 {
        const read = self.stdin.read(buf) catch |err| {
            std.debug.print("err: .{s}\n", .{@errorName(err)});
            return null;
        };
        if (read != buf.len) {
            std.debug.print("read {}, should have read: {}\n",
                .{read, buf.len});
            return null;
        }
        return buf;
    }
    fn close(self: Self) void {
        self.stdin.close();
    }
};
const CamIter = struct {
    const Self = @This();

    fn next(self: Self, buf: []u8) ?[]const u8 {
        _ = buf;
        _ = self;
        return null;
    }

    fn close(self: Self) void {
        _ = self;
    }
};


//this is a unified interface over the various sources of image frames
const FrameIter = struct {
    buf: []u8,
    w: u32,
    h: u32,
    iter: union(enum) {
        stdin: StdinIter,
        cam: CamIter,
    },

    fn next(self: @This()) ?[]const u8 {
        return switch (self.iter) {
            .stdin => |stdi| stdi.next(self.buf),
            .cam => |cam| cam.next(self.buf),
        };
    }
    fn close(self: @This()) void {
        switch (self.iter) {
            .stdin => |stdi| stdi.close(),
            .cam => |cam| cam.close(),
        }
}
};


pub fn main() !void {
    const stdin = std.io.getStdIn();
    const args = try argparse.parse_args();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alc = gpa.allocator();
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            std.debug.print("leak detected! .{}", .{status});
        }
    }

        


    const frames = FrameIter {
        .w = args.w,
        .h = args.h,
        .buf = try alc.alloc(u8, args.w * args.h * YUYV_BYTES),
        .iter = if (stdin.isTty()) 
                    .{.cam = CamIter{}}
                 else 
                    .{.stdin = StdinIter{.stdin = stdin}},
    };
    defer alc.free(frames.buf);

    while (frames.next()) |frame| {
        std.debug.print("?", .{});
        _ = frame;
    }

    frames.close();

    return;
}
