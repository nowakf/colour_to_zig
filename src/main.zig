const moore = @import("moore.zig");

const std = @import("std");
const iter = @import("iter.zig");
const Stdin = iter.Stdin;
const Cam = iter.Cam;
const sod = @import("sod.zig");
const File = std.fs.File;
const ArgParser = @import("argparse.zig").ArgParser;

pub fn main() !void {
    const fields = struct {
        video : []const u8 = "/dev/video0",
        out : []const u8 = "out.png",
        width : u32 = 640,
        height : f32 = 48.0,
    };


    var args = std.process.args();
    const parser = ArgParser(
        fields,
        "USAGE: if you provide an image or stream of images on stdin, that's fine. If you don't, it will try and access the camera.",
    );
    const out = try parser.parse(&args);
    std.debug.print("{s}", .{parser.get_help()});

    std.debug.print("{s}, {s}, {} {}\n", out);

    const stdin = std.io.getStdIn();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alc = gpa.allocator();
    _ = alc;
    defer {
        const status = gpa.deinit();
        if (status == .leak) {
            std.debug.print("leak detected! .{}", .{status});
        }
    }


    var cam = Cam(.{}){};
    var stn = Stdin(.{}){};

    const frames = if (stdin.isTty()) 
        cam.iter()
     else 
         stn.iter();

    var buf = [_]u8{'t', 'e'};

    while (frames.next(&buf) != null) {
        std.debug.print("?", .{});
    }

    return;
}
