const std = @import("std");
const c = @cImport({
    @cInclude("openpnp-capture.h");
});

//no checks whatsoever
pub fn fourcc(code: [4]u8) u32 {
    return std.mem.bytesAsValue(u32, code).*;
}

pub const Config = struct {
    name: ?[]const u8 = null,
    fourcc: ?u32 = null,
};

pub fn getCam(conf: Config) !Cam {
    const ctx = c.Cap_createContext();
    const cam_cnt = c.Cap_getDeviceCount(ctx);
    if (cam_cnt == 0) {
        return error.NO_CAMERA;
    }
    const dev_id = id: {
        if (conf.name == null) {
            break :id 0;
        }
        for (0..cam_cnt) |id| {
            const name: [*:0]const u8 = c.Cap_getDeviceName(ctx, @intCast(id));
            if (std.mem.eql(u8, std.mem.span(name), conf.name.?)) {
                break :id @as(u32, @intCast(id));
            }
        }
        break :id 0;
    };
    const fmt_cnt = c.Cap_getNumFormats(ctx, dev_id);
    if (fmt_cnt == -1) {
        return error.INVALID_FORMAT_CNT;
    }

    //just return the largest format available
    var fmt = c.CapFormatInfo{};
    var fmt_id: u32 = 0;
    for (0..@intCast(fmt_cnt)) |id| {
        var cur = c.CapFormatInfo{};
        const res = c.Cap_getFormatInfo(ctx, dev_id, @intCast(id), &cur);
        _ = res;
        if ((conf.fourcc == null or cur.fourcc == conf.fourcc) and cur.width * cur.height > fmt.width * fmt.height) {
            fmt = cur;
            fmt_id = @intCast(id);
        }
    }

    const stream_id = c.Cap_openStream(ctx, dev_id, fmt_id);
    if (stream_id == -1) {
        return error.OPEN_STREAM_FAILED;
    }
    return Cam{
        .ctx = ctx,
        .info = fmt,
        .stream_id = stream_id,
    };
}

const Cam = struct {
    const Self = @This();
    ctx: c.CapContext,
    info: c.CapFormatInfo,
    stream_id: i32,
    pub fn getFrame(self: Self, buf: []u8) !void {
        _ = c.Cap_captureFrame(self.ctx, self.stream_id, @ptrCast(buf.ptr), @intCast(buf.len));
    }
    pub fn deinit(self: Self) void {
        //check errors here
        _ = c.Cap_closeStream(self.ctx, self.stream_id);
        _ = c.Cap_releaseContext(self.ctx);
    }
};
