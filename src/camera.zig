const std = @import("std");
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
    dimensions: ?[3]u32 = null,
    props: []const struct{Property, f32} = &.{},
};


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



fn camError(err: u32) !void {
    return switch (err) {
        c.CAPRESULT_OK,                   => return,
        c.CAPRESULT_ERR,                  => error.Err,
        c.CAPRESULT_DEVICENOTFOUND,       => error.DeviceNotFound,
        c.CAPRESULT_FORMATNOTSUPPORTED,   => error.FormatNotSupported,
        c.CAPRESULT_PROPERTYNOTSUPPORTED, => error.PropNotSupported,
        else                              => std.debug.panic("unknown error value from camera: {}\n", .{err}),
    };
}

//value is in the range of 0-1, null returns the property to automatic
//this must be reworked: openpnp is fucking up somehow so we should do this through the shell
fn setProp(ctx: c.CapContext, str: c.CapStream, prop: Property, value: ?f32) !void {
    if (value) |val| {
        if (val > 1.0) {
            std.log.err("values for properties must be in the range of 0-1\n", .{});
            return error.InvalidSetting;
        }
        try camError(c.Cap_setAutoProperty(ctx, str, @intFromEnum(prop), 1));
        var min : i32 = undefined;
        var max : i32 = undefined;
        var default : i32 = undefined;
        try camError(c.Cap_getPropertyLimits(ctx, str, @intFromEnum(prop), &min, &max, &default));
        const ival : i32 = @intFromFloat(val * @as(f32, @floatFromInt(max - min)));
        try camError(c.Cap_setProperty(ctx, str, @intFromEnum(prop), ival));
        std.log.info("set prop {any} with default of {} to {}\n", .{prop, default, ival});
    } else {
        return camError(c.Cap_setAutoProperty(ctx, str, @intFromEnum(prop), 0));
    }
}


const Fmt = struct{fmt: c.CapFormatInfo, id: u32};

fn unsigned_abs(a: u32, b: u32) u32 {
    return @intCast(@abs(@as(i32, @intCast(a)) - @as(i32, @intCast(b))));
}

fn closer_dims(a: c.CapFormatInfo, b: c.CapFormatInfo, desired: ?[3]u32) bool {
    const des  = desired orelse .{2000,2000,100};
        return 
          unsigned_abs(a.width, des[0]) * unsigned_abs(a.height, des[1]) * unsigned_abs(a.fps, des[2]) <
          unsigned_abs(b.width, des[0]) * unsigned_abs(b.height, des[1]) * unsigned_abs(b.fps, des[2]);
}


fn getCapFormat(ctx: *anyopaque, dev_id: u32, conf: Config) !Fmt {
    const fmt_cnt = c.Cap_getNumFormats(ctx, dev_id);
    if (fmt_cnt == -1) {
        return error.InvalidFmtCnt;
    }
    //fallback returns the largest fastest format available
    var matching : ?Fmt = null;
    var fallback : Fmt = .{.fmt=c.CapFormatInfo{}, .id=0};
    std.log.info("format requested: {s}\n", .{std.mem.asBytes(&conf.fourcc)});
    for (0..@intCast(fmt_cnt)) |id| {
        var cur = c.CapFormatInfo{};
        try camError(c.Cap_getFormatInfo(ctx, dev_id, @intCast(id), &cur));
        std.log.info("format discovered: {any} {s}\n", .{cur, std.mem.asBytes(&cur.fourcc)});
        if (cur.fourcc == conf.fourcc and (matching == null or closer_dims(cur, matching.?.fmt, conf.dimensions))) {
            matching = .{
                .fmt = cur,
                .id=@intCast(id),
            };
        } else if (closer_dims(cur, fallback.fmt, conf.dimensions)){
            fallback = .{
                .fmt=cur,
                .id=@intCast(id),
            };
        }
    }
    return if (matching) |m| m else fallback;
}

fn getDeviceId(ctx: *anyopaque, cam_name: ?[]const u8) !u32 {
    const cam_cnt = c.Cap_getDeviceCount(ctx);
    if (cam_cnt == 0) {
        return error.NoCameras;
    }
    const dev_id = id: {
        for (0..cam_cnt) |id| {
            const this_name : [*:0]const u8 = c.Cap_getDeviceName(ctx, @intCast(id));
            std.log.info("camera '{s}' discovered\n", .{this_name});
            if (cam_name != null and std.mem.eql(u8, std.mem.span(this_name), cam_name.?)) {
                break :id @as(u32, @intCast(id));
            }
        }
        std.log.err("camera '{s}' not discovered, falling back to '{s}'\n", .{cam_name orelse "none specified", c.Cap_getDeviceName(ctx, 0)});
        break :id 0;
    };
    return dev_id;
}

pub fn configureCam(ctx: *anyopaque, conf: Config) !struct{info: c.CapFormatInfo, id: i32} {
    const dev_id = try getDeviceId(ctx, conf.name);
    const fmt = try getCapFormat(ctx, dev_id, conf);

    std.log.info("{any} : {s} chosen\n", .{fmt, std.mem.asBytes(&fmt.fmt.fourcc)});

    const stream_id = c.Cap_openStream(ctx, dev_id, fmt.id);
    if (stream_id == -1) {
        return error.OpenStreamFailed;
    }

    for (conf.props) |prop| {
        setProp(ctx, stream_id, prop[0], prop[1]) catch |err| {
            if (err == error.PropNotSupported) {
                std.log.err("property: {any} not supported\n", .{prop[0]});
            } else {
                return err;
            }
        };
    }
    return .{.info=fmt.fmt, .id=stream_id};
}

const raylib = @import("raylib");

const Self = @This();

ctx: c.CapContext,
info: c.CapFormatInfo,
stream_id: i32,
alc: std.mem.Allocator,
buf: []u8,

pub fn Camera(alc: std.mem.Allocator, conf: Config) !Self {
    const ctx = c.Cap_createContext() orelse return error.ContextNotCreated;
    const stream = try configureCam(ctx, conf);
    const buf = try alc.alloc(u8,  stream.info.width * stream.info.height * 3);
    const info = stream.info;
    return .{
        .alc = alc,
        .ctx = ctx,
        .info = info,
        .stream_id = stream.id,
        .buf = buf,
    };
}

pub fn updateFrame(self: Self) !void {
    try camError(c.Cap_captureFrame(self.ctx, self.stream_id, @ptrCast(self.buf.ptr), @intCast(self.buf.len)));
}
pub fn isReady(self: Self) bool {
    return c.Cap_hasNewFrame(self.ctx, self.stream_id) == 1;
}
pub fn dimensions(self: Self) [2]u32 {
    return .{self.info.width, self.info.height};
}

pub fn changeFormat(self: *Self, new_conf: Config) !void {
    try camError(c.Cap_closeStream(self.ctx, self.stream_id));
    const new_stream = try configureCam(self.ctx, new_conf);
    self.info = new_stream.info;
    self.id = new_stream.id;
}
pub fn deinit(self: Self) void {
    //check errors here
    camError(c.Cap_closeStream(self.ctx, self.stream_id)) catch |err| {
        std.log.err("{} while closing stream\n", .{err});
    };
    camError(c.Cap_releaseContext(self.ctx)) catch |err| {
        std.log.err("{} while releasing context\n", .{err});
    };
    self.alc.free(self.buf);
}



