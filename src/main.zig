const std = @import("std");
const sod = @cImport({
    @cInclude("sod.h");
});

const Cam = @import("v4l2capture.zig").Capturer;

const USAGE: []const u8 = "USAGE: prog in.png out_path.png";

const Args = struct {
    v: []const u8 = "/dev/video0",
    o: []const u8 = "out.png",
};

fn parse_args() !Args {
    var args = std.process.args();
    var defaults = Args{};
    while (args.next()) |arg| {
        inline for (std.meta.fields(@TypeOf(defaults))) |f| {
            if (arg.len == 2 and arg[1] == f.name[0]) {
                @field(defaults, f.name) = args.next() orelse {
                    std.debug.print("flag -{s} requires a value\n ", .{f.name});
                    return error.ParseFailed;
                };
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
    const img = try check_output(sod.sod_img_load_from_file(arguments.o.ptr, 4));
    const bin = try check_output(sod.sod_otsu_binarize_image(img));
    sod_error(sod.sod_img_save_as_png(bin, "out.png")) catch |err| {
        std.debug.print("error: {s}", .{@errorName(err)});
    };

    return;
}
