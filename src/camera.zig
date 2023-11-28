const std = @import("std");
const ppm = @import("ppm.zig");
const c = @cImport({
    @cInclude("openpnp-capture.h");
});

//no checks whatsoever
pub fn fourcc(code: []const u8) u32 {
    return std.mem.bytesAsValue(u32, code[0..4]).*;
}

pub const Config = struct {
    name: ?[]const u8 = null,
    fourcc: ?u32 = null,
    props: []const struct{Property, f32} = &.{},
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

pub const Property = enum(u32) {
    EXPOSURE      = c.CAPPROPID_EXPOSURE,
    FOCUS         = c.CAPPROPID_FOCUS,
    ZOOM          = c.CAPPROPID_ZOOM,
    WHITEBALANCE  = c.CAPPROPID_WHITEBALANCE,
    GAIN          = c.CAPPROPID_GAIN,
    BRIGHTNESS    = c.CAPPROPID_BRIGHTNESS,
    CONTRAST      = c.CAPPROPID_CONTRAST,
    SATURATION    = c.CAPPROPID_SATURATION,
    GAMMA         = c.CAPPROPID_GAMMA,
    HUE           = c.CAPPROPID_HUE,
    SHARPNESS     = c.CAPPROPID_SHARPNESS,
    BACKLIGHTCOMP = c.CAPPROPID_BACKLIGHTCOMP,
    POWERLINEFREQ = c.CAPPROPID_POWERLINEFREQ,
};



fn cam_error(err: u32) !void {
    return switch (err) {
        c.CAPRESULT_OK,                   => return,
        c.CAPRESULT_ERR,                  => error.ERR,
        c.CAPRESULT_DEVICENOTFOUND,       => error.DEVICENOTFOUND,
        c.CAPRESULT_FORMATNOTSUPPORTED,   => error.FORMATNOTSUPPORTED,
        c.CAPRESULT_PROPERTYNOTSUPPORTED, => error.PROPERTYNOTSUPPORTED,
        else                              => std.debug.panic("unknown error value from camera: {}\n", .{err}),
    };
}

//value is in the range of 0-1, null returns the property to automatic
fn set_prop(ctx: c.CapContext, str: c.CapStream, prop: Property, value: ?f32) !void {
    if (value) |val| {
        if (val > 1.0) {
            std.debug.print("values for properties must be in the range of 0-1\n", .{});
            return error.INVALID_SETTING;
        }
        try cam_error(c.Cap_setAutoProperty(ctx, str, @intFromEnum(prop), 1));
        var min : i32 = undefined;
        var max : i32 = undefined;
        var default : i32 = undefined;
        try cam_error(c.Cap_getPropertyLimits(ctx, str, @intFromEnum(prop), &min, &max, &default));
        const ival : i32 = @intFromFloat(val * @as(f32, @floatFromInt(max - min)));
        try cam_error(c.Cap_setProperty(ctx, str, @intFromEnum(prop), ival));
        std.debug.print("set prop {any} with default of {} to {}\n", .{prop, default, ival});
    } else {
        return cam_error(c.Cap_setAutoProperty(ctx, str, @intFromEnum(prop), 0));
    }
}

fn max_fmt(a: c.CapFormatInfo, b: c.CapFormatInfo) c.CapFormatInfo {
    return if (a.width * a.height * a.fps > b.width * b.height * b.fps) a else b;
}

pub fn getCam(conf: Config) !Source {
    const ctx = c.Cap_createContext();
    const cam_cnt = c.Cap_getDeviceCount(ctx);
    if (cam_cnt == 0) {
        return error.NO_CAMERA;
    }
    const dev_id = id: {
        for (0..cam_cnt) |id| {
            const name : [*:0]const u8 = c.Cap_getDeviceName(ctx, @intCast(id));
            std.debug.print("camera '{s}' discovered\n", .{name});
            if (conf.name != null and std.mem.eql(u8, std.mem.span(name), conf.name.?)) {
                break :id @as(u32, @intCast(id));
            }
        }
        std.debug.print("camera '{s}' not discovered, falling back to '{s}'\n", .{conf.name orelse "", c.Cap_getDeviceName(ctx, 0)});
        break :id 0;
    };
    const fmt_cnt = c.Cap_getNumFormats(ctx, dev_id);
    if (fmt_cnt == -1) {
        return error.INVALID_FORMAT_CNT;
    }

    //fallback returns the largest fastest format available
    const Fmt = struct{fmt: c.CapFormatInfo, id: u32};
    var matching : ?Fmt = null;
    var fallback : Fmt = .{.fmt=c.CapFormatInfo{}, .id=0};
    std.debug.print("format requested: {s}\n", .{std.mem.asBytes(&conf.fourcc)});
    for (0..@intCast(fmt_cnt)) |id| {
        var cur = c.CapFormatInfo{};
        try cam_error(c.Cap_getFormatInfo(ctx, dev_id, @intCast(id), &cur));
        std.debug.print("format discovered: {any} {s}\n", .{cur, std.mem.asBytes(&cur.fourcc)});
        if (cur.fourcc == conf.fourcc) {
            std.debug.print("desired format found!\n", .{});
            const mx = max_fmt(cur, c.CapFormatInfo{});
            matching = .{
                .fmt = mx,
                .id=if (std.meta.eql(mx, cur)) @intCast(id) else matching.?.id,
            };
        } else {
            const mx = max_fmt(cur, fallback.fmt);
            fallback = .{
                .fmt=mx,
                .id=if (std.meta.eql(mx, cur)) @intCast(id) else fallback.id,
            };
        }
    }
    const fmt = if (matching) |m| m else fallback;

    const stream_id = c.Cap_openStream(ctx, dev_id, fmt.id);
    if (stream_id == -1) {
        return error.OPEN_STREAM_FAILED;
    }
    for (conf.props) |prop| {
        set_prop(ctx, stream_id, prop[0], prop[1]) catch |err| {
            if (err == error.PROPERTYNOTSUPPORTED) {
                std.debug.print("property: {any} not supported\n", .{prop[0]});
            } else {
                return err;
            }
        };
    }
    return Source {
        .Cam = .{
            .ctx = ctx,
            .info = fmt.fmt,
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
            try cam_error(c.Cap_captureFrame(self.ctx, self.stream_id, @ptrCast(buf.ptr), @intCast(buf.len)));
        }
        pub fn rawIsReady(self: Inner) bool {
            return c.Cap_hasNewFrame(self.ctx, self.stream_id) == 1;
        }
        pub fn rawDimensions(self: Inner) [2]u32 {
            return .{self.info.width, self.info.height};
        }
        pub fn rawDeinit(self: Inner) !void {
            //check errors here
            try cam_error(c.Cap_closeStream(self.ctx, self.stream_id));
            try cam_error(c.Cap_releaseContext(self.ctx));
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
    pub fn isReady(self: Self) bool {
        return switch (self) {
            .Cam => |inner| inner.rawIsReady(),
            else => true,
        };
    }
    pub fn dimensions(self: Self) struct {width:u32, height:u32} {
        const dims = switch (self) {
            inline else => |inner| inner.rawDimensions(),
        };
        return .{.width=dims[0], .height=dims[1]};
    }
    pub fn deinit(self: Self) !void {
        switch (self) {
            inline else => |inner| return inner.rawDeinit(),
        }
    }
};



