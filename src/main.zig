const t = @import("moore.zig");

const std = @import("std");
const argparse = @import("argparse.zig");
const sod = @import("sod.zig");
const File = std.fs.File;

const StdinIter = struct {
    stdin : File,

    const Self = @This();
    fn from_args(stdin: File, args: argparse.Args) !@This() {
        _ = args;
        return .{.stdin = stdin};
    }

    fn next(self: Self) ?[]const u8 {
        _ = self;
        return &.{};
    }
    fn close() void {
    }
};
const CamIter = if (@import("builtin").os.tag == .linux) struct {
    inner : u8 = undefined,
    const Self = @This();
    fn from_args(args: argparse.Args) !@This() {
        _ = args;
        return .{.inner = 0 };
    }
    fn next(self: Self) ?[]const u8 {
        _ = self;
        return &.{};
    }
    fn close() void {
    }
} else struct {
    fn new() !void {
        std.debug.print("camera only supported on linux: non-linux users must pipe images into stdin\n", .{});
        return error.NotImplimented; 
    }
};



const FrameIter = union(enum) {
    stdin: StdinIter,
    cam: CamIter,
    fn next(self: @This()) ?[]const u8 {
        return self.next();
    }
    fn close(self: @This()) void {
        self.close();
    }
};


pub fn main() !void {
    const stdin = std.io.getStdIn();
    const args = try argparse.parse_args();
    const frames = if (stdin.isTty()) 
        FrameIter{.stdin = try StdinIter.from_args(stdin, args) }
    else 
        FrameIter{.cam = try CamIter.from_args(args) };

    while (frames.next()) |frame| {
        _ = frame;
    }
    frames.close();
    return;
}
