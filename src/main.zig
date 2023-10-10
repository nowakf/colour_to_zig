const std = @import("std");
const sod = @cImport({
    @cInclude("sod.h");
});
const os = std.os;

const Cam = @import("v4l2capture.zig").Capturer;

const USAGE: []const u8 = "USAGE: prog in.png out_path.png";

const Args = struct {
    v: []const u8 = "/dev/video0",
    o: []const u8 = "out.png",
    w: u32 = 640,
    h: u32 = 480,
};

fn finnicky_linux_stuff(cap: *Cam, alc: std.mem.Allocator) ![]u8 {
    const epoll_fd = try os.epoll_create1(os.linux.EPOLL.CLOEXEC);
    defer os.close(epoll_fd);

    var cap_event = os.linux.epoll_event{
        .events = os.linux.EPOLL.IN,
        .data = os.linux.epoll_data{ .fd = cap.getFd() },
    };

    try os.epoll_ctl(epoll_fd, os.linux.EPOLL.CTL_ADD, cap_event.data.fd, &cap_event);

    //signalfd?
    const timeout = 5000;
    var event: [5]os.linux.epoll_event = .{};
    const ev_cnt = os.epoll_wait(epoll_fd, &event, timeout);
    if (ev_cnt == 0) {
        return error.Hmm;
    }
    if (event[0].data.fd == cap_event.data.fd) {
        return try cap.capture(alc);
    } else {
        return error.Hmmmm;
    }
}

fn parse_args() !Args {
    var args = std.process.args();
    var defaults = Args{};
    while (args.next()) |arg| {
        inline for (std.meta.fields(@TypeOf(defaults))) |f| {
            if (arg.len == 2 and arg[1] == f.name[0]) {
                const val = args.next() orelse {
                    std.debug.print("flag -{s} requires a value\n ", .{f.name});
                    return error.ParseFailed;
                };

                const parsed = switch (f.type) {
                    u32 => try std.fmt.parseInt(u32, val, 10),
                    []const u8 => arg,
                    else => std.debug.panic("unknown type"),
                };

                @field(defaults, f.name) = parsed;
            }
        }
    }
    return defaults;
}

fn sod_error(code: c_int) error{ UNSUPPORTED, OUTOFMEM, ABORT, LIMIT, IO }!void {
    return switch (code) {
        sod.SOD_OK => return,
        sod.SOD_UNSUPPORTED => error.UNSUPPORTED,
        sod.SOD_OUTOFMEM => error.OUTOFMEM,
        sod.SOD_ABORT => error.ABORT,
        sod.SOD_IOERR => error.IO,
        sod.SOD_LIMIT => error.LIMIT,
        else => std.debug.panic("unknown error code from sod: {}\n", .{code}),
    };
}

fn check_output(img: sod.struct_sod_img) !sod.struct_sod_img {
    if (sod.SOD_IS_EMPTY_IMG(img)) {
        std.debug.print("failed to load image \n", .{});
        return error.UNKNOWN_SOD_ERROR;
    }
    return img;
}

pub fn main() !void {
    const arguments = try parse_args();
    const alc = std.heap.page_allocator;

    var cam = try Cam.init(alc, arguments.v, arguments.w, arguments.h, 15, "YUYV");
    defer cam.deinit();

    try cam.start();
    defer cam.stop();

    const buf = try finnicky_linux_stuff(&cam, alc);
    defer alc.free(buf);

    var img = try check_output(sod.sod_make_image(@intCast(arguments.w), @intCast(arguments.h), 1));

    for (0..(buf.len / 2)) |i| {
        img.data[i] = @as(f32, @floatFromInt(buf[i * 2])) / 255;
    }

    const canny = try check_output(sod.sod_canny_edge_image(img, 0));
    defer sod.sod_free_image(canny);

    try sod_error(sod.sod_img_save_as_png(canny, "out.png"));

    return;
}
