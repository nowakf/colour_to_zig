const std = @import("std");
const ppm = @import("ppm.zig");
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

pub fn getPPM(alc: std.mem.Allocator, fname: []const u8) !Source {
    const file = try std.fs.cwd().openFile(fname, .{});
    defer file.close();
    const img = ppm.from_file(alc, file);
    return Source {
        .PPM = .{
            .w = img.w,
            .h = img.h,
            .img = img.to_owned_rgb_bytes(),
            .allocator = alc,
        }
    };
}

pub fn getCam(conf: Config) !Source {
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
            const name : [*:0]const u8 = c.Cap_getDeviceName(ctx, @intCast(id));
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
    var fmt_id : u32 = 0;
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
    return Source {
        .Cam = .{
            .ctx = ctx,
            .info = fmt,
            .stream_id = stream_id,
        }
    };
}

pub const Source = union(enum) {
    const Self = @This();
    Cam : struct {
        const Inner = @This();
        ctx: c.CapContext,
        info: c.CapFormatInfo,
        stream_id: i32,
        pub fn rawGetFrame(self: Inner, buf: []u8) !void {
            //TODO: remove this
            while(c.Cap_hasNewFrame(self.ctx, self.stream_id) == 0) {
            }
            _ = c.Cap_captureFrame(self.ctx, self.stream_id, @ptrCast(buf.ptr), @intCast(buf.len));
        }
        pub fn rawDimensions(self: Inner) [2]u32 {
            return .{self.info.width, self.info.height};
        }
        pub fn rawDeinit(self: Inner) void {
            //check errors here
            _ = c.Cap_closeStream(self.ctx, self.stream_id);
            _ = c.Cap_releaseContext(self.ctx);
        }
    },
    PPM : struct {
        const Inner = @This();
        allocator: std.mem.Allocator,
        img: []u8,
        w: u32,
        h: u32,
        pub fn rawDimensions(self: Inner) [2]u32 {
            return .{self.w, self.h};
        }
        pub fn rawGetFrame(self: Inner, buf: []u8) !void {
            @memcpy(buf, self.img);
        }
        pub fn rawDeinit(self: Inner) !void {
            self.allocator.free(self.img);
        }

    },
    pub fn getFrame(self: Self, buf: []u8) !void {
        switch (self) {
            inline else => |inner| try inner.rawGetFrame(buf),
        }
    }
    pub fn dimensions(self: Self) struct {width:u32, height:u32} {
        const dims = switch (self) {
            inline else => |inner| inner.rawDimensions(),
        };
        return .{.width=dims[0], .height=dims[1]};
    }
    pub fn deinit(self: Self) void {
        switch (self) {
            inline else => |inner| inner.rawDeinit(),
        }
    }
};



