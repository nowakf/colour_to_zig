const std = @import("std");

const USAGE: []const u8 = "USAGE: prog in.png out_path.png";

pub const Args = struct {
    v: []const u8 = "/dev/video0",
    o: []const u8 = "out.png",
    w: u32 = 640,
    h: u32 = 480,
};

pub fn parse_args() !Args {
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
