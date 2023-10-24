const std = @import("std");

const sod = @cImport({
    @cInclude("stddef.h");
    @cInclude("sod.h");
});

pub const SOD_VERSION = "1.1.9";


const SodError = error {
    UNSUPPORTED,
    OUTOFMEM,
    ABORT,
    IOERR,
    LIMIT,
    UNKNOWN,
};

fn sod_error(e_no: c_int) SodError!void {
    return switch (e_no) {
        0 => return,
        -1 => SodError.UNSUPPORTED,
        -2 => SodError.OUTOFMEM,
        -3 => SodError.ABORT,
        -4 => SodError.IOERR,
        -5 => SodError.LIMIT,
        else => |x| {
            std.debug.log("unknown error code: {}\n", x);
            return error.UNKNOWN;
        }
    };
}

fn infer_return(comptime fun: type) type {
    if (@typeInfo(fun) != .Fn) {
        @compileError("only functions return\n this is a: " ++ @typeName(fun) ++ "\n");
    } else {
        return @typeInfo(fun).Fn.return_type.?;
    }
}

fn check_empty(img: sod.sod_img) !sod.sod_img {
    return img;
    //return if (img.unnamed_0.data != null) img else
    //    error.NO_IMAGE_RETURNED;
}

pub fn wrap(fun: anytype, args: anytype) !infer_return(@TypeOf(fun)) {
    return switch (@typeInfo(infer_return(@TypeOf(fun)))) {
        .Void => return @call(.auto, fun, args),
        .Int => return sod_error(@call(.auto, fun, args)),
        .Struct => {
            const ret = @call(.auto, fun, args);
            if (@TypeOf(args[0]) == sod.sod_img) {
                sod.sod_free_image(args[0]);
            }
            return check_empty(ret);
        },
        else => |t| @compileError("unhandled type " ++ @typeName(@Type(t)) ++ "\n" ),
    };

}

pub const Img = struct {
    const Self = @This();
    inner: sod.sod_img,


    pub fn make(w: c_int, h: c_int, c: c_int) !Self {
        return .{
            .inner = wrap(sod.sod_make_image, .{w, h, c})
        };
    }
    pub fn grow(pImg: *Self, w: c_int, h: c_int, c: c_int) !void {
        return wrap(sod.sod_grow_image, .{pImg.inner, w, h, c});
    }
    pub fn make_random(w: c_int, h: c_int, c: c_int) !Self {
        return .{
            .inner = wrap(sod.sod_make_random_image, .{w, h, c})
        };
    }
    pub fn copy(m: Self) !Self {
        const img = sod.sod_copy_image(m.inner);
        return .{.inner = try check_empty(img)};
    }
    pub fn free(m: Self) void {
        return sod.sod_free_image(m.inner);
    }
    pub fn load_from_file(zFile: [*c]const u8, nChannels: c_int) !Self {
        const img = sod.sod_img_load_from_file(zFile, nChannels);
        return .{.inner = try check_empty(img)};
    }
    pub fn load_from_mem(zBuf: [*c]const u8, buf_len: c_int, nChannels: c_int) !Self {
        const img = sod.sod_img_load_from_mem(zBuf, buf_len, nChannels);
        return .{.inner = try check_empty(img)};
    }
    pub fn set_load_from_directory(zPath: [*c]const u8, apLoaded: [*c][*c]Self, pnLoaded: [*c]c_int, max_entries: c_int) !void {
        return wrap(sod.sod_img_set_load_from_directory, .{zPath, apLoaded, pnLoaded, max_entries});
    }
    pub fn set_release(aLoaded: [*c]Self, nEntries: c_int) void {
        sod.sod_img_set_release(aLoaded, nEntries);
    }
    pub fn get_pixel(m: Self, x: c_int, y: c_int, c: c_int) f32 {
        sod.sod_img_get_pixel(m.inner, x, y, c);
    }
    pub fn set_pixel(m: *Self, x: c_int, y: c_int, c: c_int, val: f32) void {
        sod.sod_img_set_pixel(m.inner, x, y, c, val);
    }
    pub fn add_pixel(m: *Self, x: c_int, y: c_int, c: c_int, val: f32) void {
        sod.sod_img_add_pixel(m.inner, x, y, c, val);
    }
    pub fn get_layer(m: Self, l: c_int) !Self {
        const in = try check_empty(sod.sod_img_get_layer(m.inner, l));
        return .{.inner = in};
    }
    pub fn rgb_to_hsv(im: *Self) void {
        sod.sod_img_rgb_to_hsv(im.inner);
    }
    pub fn hsv_to_rgb(im: *Self) void {
        sod.sod_img_hsv_to_rgb(im.inner);
    }
    pub fn rgb_to_bgr(im: *Self) void {
        sod.sod_img_rgb_to_bgr(im.inner);
    }
    pub fn bgr_to_rgb(im: *Self) void {
        sod.sod_img_bgr_to_rgb(im.inner);
    }
    pub fn yuv_to_rgb(im: *Self) void {
        sod.sod_img_yuv_to_rgb(im.inner);
    }
    pub fn rgb_to_yuv(im: *Self) void {
        sod.sod_img_rgb_to_yuv(im.inner);
    }
    pub fn minutiae(bin: *Self, pTotal: [*c]c_int, pEp: [*c]c_int, pBp: [*c]c_int) !void {
        bin.inner = try wrap(sod.sod_minutiae, .{bin.inner, pTotal, pEp, pBp});
    }
    pub fn gaussian_noise_reduce(gray: *Self) !void {
        gray.inner = try wrap(sod.sod_gaussian_noise_reduce, .{gray.inner});
    }
    pub fn equalize_histogram(im: *Self) !void {
        im.inner = try wrap(sod.sod_equalize_histogram, .{im.inner});
    }
    pub fn grayscale(im: *Self) !void {
        im.inner = try wrap(sod.sod_grayscale_image, .{im.inner});
    }
    pub fn grayscale_3c(im: *Self) void {
        sod.sod_grayscale_image_3c(im.inner);
    }
    pub fn threshold(im: *Self, thresh: f32) !void {
        im.inner = try wrap(sod.sod_threshold_image, .{im.inner, thresh});
    }
    pub fn otsu_binarize(im: *Self) !void {
        im.inner = try wrap(sod.sod_otsu_binarize_image, .{im.inner});
    }
    pub fn binarize(im: *Self, reverse: c_int) !void {
        im.inner = try wrap(sod.sod_binarize_image, .{im.inner, reverse});
    }
    pub fn dilate(im: *Self, times: c_int) !void {
        im.inner = try wrap(sod.sod_dilate_image, .{im.inner, times});
    }
    pub fn erode(im: *Self, times: c_int) !void {
        im.inner = try wrap(sod.sod_erode_image, .{im.inner, times});
    }
    pub fn sharpen_filtering(im: *Self) !void {
         im.inner = try wrap(sod.sod_sharpen_filtering_image, .{im.inner});
    }
    pub fn hilditch_thin(im: *Self) !void {
        im.inner = try wrap(sod.sod_hilditch_thin_image, .{im});
    }
    pub fn sobel(im: *Self) !void {
        im.inner = try wrap(sod.sod_sobel_image, .{im.inner});
    }
    pub fn canny_edge(im: *Self, reduce_noise: c_int) !void.sod_img {
        im.inner = wrap(sod.sod_canny_edge_image, .{im.inner, reduce_noise});
    }
    pub fn hough_lines_detect(im: *Self, thresh: c_int, nPts: [*c]c_int) [*c]sod.sod_pts {
        return sod.sod_hough_lines_detect(im.inner, thresh, nPts);
    }
    pub fn hough_lines_release(pLines: [*c]sod.sod_pts) void {
        sod.sod_hough_lines_release(pLines);
    }
    pub fn find_blobs(im: Self, paBox: [*c][*c]sod.sod_box, pnBox: [*c]c_int, xFilter: ?*const fn (c_int, c_int) callconv(.C) c_int) !void {
        return wrap(sod.sod_image_find_blobs(im.inner, paBox, pnBox, xFilter, c_int));
    }
    pub fn blob_boxes_release(pBox: [*c]sod.sod_box) void {
        return sod.sod_blob_boxes_release(pBox);
    }
    pub fn composite(source: Self, dest: *Self, dx: c_int, dy: c_int) void {
        sod.sod_composite_image(source.inner, dest.inner, dx, dy);
    }
    pub fn flip(input: *Self) !void {
        input.inner = try wrap(sod.sod_flip_image, .{input.inner});
    }
    pub fn distance(a: *Self, b: Self) !void {
        a.inner = try wrap(sod.sod_image_distance, .{a.inner, b.inner});
    }
    pub fn embed(source: *Self, dest: Self, dx: c_int, dy: c_int) !void {
        source.inner = try wrap(sod.sod_embed_image, .{source.inner, dest.inner, dx, dy});
    }
    pub fn blend(fore: *Self, back: Self, alpha: f32) !void {
        fore.inner = try wrap(sod.sod_blend_image, .{fore.inner, back.inner, alpha});
    }
    pub fn scale_channel(im: *Self, c: c_int, v: f32) !void {
        im.inner = try wrap(sod.sod_scale_image_channel, .{im.inner, c, v});
    }
    pub fn translate_channel(im: Self, c: c_int, v: f32) void {
        sod.sod_translate_image_channel(im.inner, c, v);
    }
    pub fn resize(im: *Self, w: c_int, h: c_int) !void {
        im.inner = try wrap(sod.sod_resize_image, .{im.inner, w, h});
    }
    pub fn resize_max(im: *Self, max: c_int) !void {
        im.inner = try wrap(sod.sod_resize_max, .{im.inner, max});
    }
    pub fn resize_min(im: *Self, min: c_int) !void {
        im.inner = try wrap(sod.sod_resize_min, .{im.inner, min});
    }
    pub fn rotate_crop(im: *Self, rad: f32, s: f32, w: c_int, h: c_int, dx: f32, dy: f32, aspect: f32) !void {
        im.inner = try wrap(sod.sod_rotate_crop_image, .{im.inner, rad, s, w, h, dx, dy, aspect});
    }
    pub fn rotate(im: *Self, rad: f32) !void {
        im.inner = try wrap(sod.sod_rotate_image, .{im.inner, rad});
    }
    pub fn translate(m: *Self, s: f32) void {
        sod.sod_translate_image(m.inner, s);
    }
    pub fn scale(m: *Self, s: f32) void {
        sod.sod_scale_image(m.inner, s);
    }
    pub fn normalize(p: *Self) void {
        sod.sod_normalize_image(p.inner);
    }
    pub fn transpose(im: *Self) void {
        sod.sod_transpose_image(im.inner);
    }
    pub fn crop(im: *Self, dx: c_int, dy: c_int, w: c_int, h: c_int) !void {
        im.inner = try wrap(sod.sod_crop_image, .{im, dx, dy, w, h});
    }
    pub fn random_crop(im: *Self, w: c_int, h: c_int) !void {
        im.inner = try wrap(sod.sod_random_crop_image, .{im, w, h});
    }
    pub fn random_augment(im: *Self, angle: f32, aspect: f32, low: c_int, high: c_int, size: c_int) !void {
        im.inner = try wrap(sod.sod_random_augment_image, .{im, angle, aspect, low, high, size});
    }
    pub fn draw_box(im: *Self, x1: c_int, y1: c_int, x2: c_int, y2: c_int, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_box(im, x1, y1, x2, y2, r, g, b);
    }
    pub fn draw_box_grayscale(im: *Self, x1: c_int, y1: c_int, x2: c_int, y2: c_int, g: f32) void {
        sod.sod_image_draw_box_grayscale(im, x1, y1, x2, y2, g);
    }
    pub fn draw_circle(im: *Self, x0: c_int, y0: c_int, radius: c_int, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_circle(im, x0, y0, radius, r, g, b);
    }
    pub fn draw_circle_thickness(im: *Self, x0: c_int, y0: c_int, radius: c_int, width: c_int, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_circle_thickness(im, x0, y0, radius, width, r, g, b);
    }
    pub fn draw_bbox(im: *Self, bbox: sod.sod_box, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_bbox(im, bbox, r, g, b);
    }
    pub fn draw_bbox_width(im: *Self, bbox: sod.sod_box, width: c_int, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_bbox_width(im, bbox, width, r, g, b);
    }
    pub fn draw_line(im: *Self, start: sod.sod_pts, end: sod.sod_pts, r: f32, g: f32, b: f32) void {
        sod.sod_image_draw_line(im, start, end, r, g, b);
    }
    pub fn to_blob(im: Self) [*c]u8 {
        return sod.sod_image_to_blob(im.inner);
    }
};

test "x" {
    const f = try wrap(sod.sod_sobel_image, .{sod.sod_make_image(0,0,0)});
    _ = f;
}

pub const ColorSpace = enum(c_int) {
    COLOR = sod.SOD_IMG_COLOR,
    GRAY = sod.SOD_IMG_GRAYSCALE,
};

pub const SOD_LIB_INFO = "SOD Embedded - Release 1.1.8 under GPLv3. Copyright (C) 2018 - 2019 PixLab| Symisc Systems, https://sod.pixlab.io";


