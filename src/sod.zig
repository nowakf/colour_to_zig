const std = @import("std");

const sod = @cImport({
    @cInclude("stddef.h");
    @cInclude("sod.h");
});

pub const SOD_VERSION = "1.1.8";

pub const img = struct {
    const Self = sod.struct_sod_img;
    fn make_empty(w: c_int, h: c_int, c: c_int) Self {
        return sod.sod_make_empty_image(w, h, c);
    }
    fn make(w: c_int, h: c_int, c: c_int) Self {
        return sod.sod_make_image(w, h, c);
    }
    fn grow(pImg: [*c]Self, w: c_int, h: c_int, c: c_int) c_int {
        return sod.sod_grow_image(pImg, w, h, c);
    }
    fn make_random(w: c_int, h: c_int, c: c_int) Self {
        return sod.sod_make_random_image(w, h, c);
    }
    fn copy(m: Self) Self {
        return sod.sod_copy_image(m);
    }
    fn free(m: Self) void {
        return sod.sod_free_image(m);
    }
    fn load_from_file(zFile: [*c]const u8, nChannels: c_int) Self {
        return sod.sod_img_load_from_file(zFile, nChannels);
    }
    fn load_from_mem(zBuf: [*c]const u8, buf_len: c_int, nChannels: c_int) Self {
        return sod.sod_img_load_from_mem(zBuf, buf_len, nChannels);
    }
    fn set_load_from_directory(zPath: [*c]const u8, apLoaded: [*c][*c]Self, pnLoaded: [*c]c_int, max_entries: c_int) c_int {
        return sod.sod_img_set_load_from_directory(zPath, apLoaded, pnLoaded, max_entries);
    }
    fn set_release(aLoaded: [*c]Self, nEntries: c_int) void {
        return sod.sod_img_set_release(aLoaded, nEntries);
    }
    fn save_as_png(input: Self, zPath: [*c]const u8) c_int {
        return sod.sod_img_save_as_png(input, zPath);
    }
    fn save_as_jpeg(input: Self, zPath: [*c]const u8, Quality: c_int) c_int {
        return sod.sod_img_save_as_jpeg(input, zPath, Quality);
    }
    fn sod_blob_save_as_png(zPath: [*c]const u8, zBlob: [*c]const u8, width: c_int, height: c_int, nChannels: c_int) c_int {
        return sod.sod_blob_save_as_png(zPath, zBlob, width, height, nChannels);
    }
    fn sod_blob_save_as_jpeg(zPath: [*c]const u8, zBlob: [*c]const u8, width: c_int, height: c_int, nChannels: c_int, Quality: c_int) c_int {
        return sod.sod_blob_save_as_jpeg(zPath, zBlob, width, height, nChannels, Quality);
    }
    fn sod_blob_save_as_bmp(zPath: [*c]const u8, zBlob: [*c]const u8, width: c_int, height: c_int, nChannels: c_int) c_int {
        return sod.sod_blob_save_as_bmp(zPath, zBlob, width, height, nChannels);
    }
    fn get_pixel(m: Self, x: c_int, y: c_int, c: c_int) f32 {
        return sod.sod_img_get_pixel(m, x, y, c);
    }
    fn set_pixel(m: Self, x: c_int, y: c_int, c: c_int, val: f32) void {
        return sod.sod_img_set_pixel(m, x, y, c, val);
    }
    fn add_pixel(m: Self, x: c_int, y: c_int, c: c_int, val: f32) void {
        return sod.sod_img_add_pixel(m, x, y, c, val);
    }
    fn get_layer(m: Self, l: c_int) Self {
        return sod.sod_img_get_layer(m, l);
    }
    fn rgb_to_hsv(im: Self) void {
        return sod.sod_img_rgb_to_hsv(im);
    }
    fn hsv_to_rgb(im: Self) void {
        return sod.sod_img_hsv_to_rgb(im);
    }
    fn rgb_to_bgr(im: Self) void {
        return sod.sod_img_rgb_to_bgr(im);
    }
    fn bgr_to_rgb(im: Self) void {
        return sod.sod_img_bgr_to_rgb(im);
    }
    fn yuv_to_rgb(im: Self) void {
        return sod.sod_img_yuv_to_rgb(im);
    }
    fn rgb_to_yuv(im: Self) void {
        return sod.sod_img_rgb_to_yuv(im);
    }
    fn minutiae(bin: Self, pTotal: [*c]c_int, pEp: [*c]c_int, pBp: [*c]c_int) Self {
        return sod.sod_minutiae(bin, pTotal, pEp, pBp);
    }
    fn gaussian_noise_reduce(gray: Self) Self {
        return sod.sod_gaussian_noise_reduce(gray);
    }
    fn equalize_histogram(im: Self) Self {
        return sod.sod_equalize_histogram(im);
    }
    fn grayscale(im: Self) Self {
        return sod.sod_grayscale_image(im);
    }
    fn grayscale_3c(im: Self) void {
        return sod.sod_grayscale_image_3c(im);
    }
    fn threshold(im: Self, thresh: f32) Self {
        return sod.sod_threshold_image(im, thresh);
    }
    fn otsu_binarize(im: Self) Self {
        return sod.sod_otsu_binarize_image(im);
    }
    fn binarize(im: Self, reverse: c_int) Self {
        return sod.sod_binarize_image(im, reverse);
    }
    fn dilate(im: Self, times: c_int) Self {
        return sod.sod_dilate_image(im, times);
    }
    fn erode(im: Self, times: c_int) Self {
        return sod.sod_erode_image(im, times);
    }
    fn sharpen_filtering(im: Self) Self {
        return sod.sod_sharpen_filtering_image(im);
    }
    fn hilditch_thin(im: Self) Self {
        return sod.sod_hilditch_thin_image(im);
    }
    fn sobel(im: Self) Self {
        return sod.sod_sobel_image(im);
    }
    fn canny_edge(im: Self, reduce_noise: c_int) Self {
        return sod.sod_canny_edge_image(im, reduce_noise);
    }
    fn hough_lines_detect(im: Self, thresh: c_int, nPts: [*c]c_int) [*c]sod.sod_pts {
        return sod.sod_hough_lines_detect(im, thresh, nPts);
    }
    fn hough_lines_release(pLines: [*c]sod.sod_pts) void {
        return sod.sod_hough_lines_release(pLines);
    }
    fn find_blobs(im: Self, paBox: [*c][*c]sod.sod_box, pnBox: [*c]c_int, xFilter: ?*const fn (c_int, c_int) callconv(.C) c_int) c_int {
        return sod.sod_image_find_blobs(im, paBox, pnBox, xFilter, c_int);
    }
    fn blob_boxes_release(pBox: [*c]sod.sod_box) void {
        return sod.sod_blob_boxes_release(pBox);
    }
    fn composite(source: Self, dest: Self, dx: c_int, dy: c_int) void {
        return sod.sod_composite_image(source, dest, dx, dy);
    }
    fn flip(input: Self) void {
        return sod.sod_flip_image(input);
    }
    fn distance(a: Self, b: Self) Self {
        return sod.sod_image_distance(a, b);
    }
    fn embed(source: Self, dest: Self, dx: c_int, dy: c_int) void {
        return sod.sod_embed_image(source, dest, dx, dy);
    }
    fn blend(fore: Self, back: Self, alpha: f32) Self {
        return sod.sod_blend_image(fore, back, alpha);
    }
    fn scale_channel(im: Self, c: c_int, v: f32) void {
        return sod.sod_scale_image_channel(im, c, v);
    }
    fn translate_channel(im: Self, c: c_int, v: f32) void {
        return sod.sod_translate_image_channel(im, c, v);
    }
    fn resize(im: Self, w: c_int, h: c_int) Self {
        return sod.sod_resize_image(im, w, h);
    }
    fn resize_max(im: Self, max: c_int) Self {
        return sod.sod_resize_max(im, max);
    }
    fn resize_min(im: Self, min: c_int) Self {
        return sod.sod_resize_min(im, min);
    }
    fn rotate_crop(im: Self, rad: f32, s: f32, w: c_int, h: c_int, dx: f32, dy: f32, aspect: f32) Self {
        return sod.sod_rotate_crop_image(im, rad, s, w, h, dx, dy, aspect);
    }
    fn rotate(im: Self, rad: f32) Self {
        return sod.sod_rotate_image(im, rad);
    }
    fn translate(m: Self, s: f32) void {
        return sod.sod_translate_image(m, s);
    }
    fn scale(m: Self, s: f32) void {
        return sod.sod_scale_image(m, s);
    }
    fn normalize(p: Self) void {
        return sod.sod_normalize_image(p);
    }
    fn transpose(im: Self) void {
        return sod.sod_transpose_image(im);
    }
    fn crop(im: Self, dx: c_int, dy: c_int, w: c_int, h: c_int) Self {
        return sod.sod_crop_image(im, dx, dy, w, h);
    }
    fn random_crop(im: Self, w: c_int, h: c_int) Self {
        return sod.sod_random_crop_image(im, w, h);
    }
    fn random_augment(im: Self, angle: f32, aspect: f32, low: c_int, high: c_int, size: c_int) Self {
        return sod.sod_random_augment_image(im, angle, aspect, low, high, size);
    }
    fn draw_box(im: Self, x1: c_int, y1: c_int, x2: c_int, y2: c_int, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_box(im, x1, y1, x2, y2, r, g, b);
    }
    fn draw_box_grayscale(im: Self, x1: c_int, y1: c_int, x2: c_int, y2: c_int, g: f32) void {
        return sod.sod_image_draw_box_grayscale(im, x1, y1, x2, y2, g);
    }
    fn draw_circle(im: Self, x0: c_int, y0: c_int, radius: c_int, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_circle(im, x0, y0, radius, r, g, b);
    }
    fn draw_circle_thickness(im: Self, x0: c_int, y0: c_int, radius: c_int, width: c_int, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_circle_thickness(im, x0, y0, radius, width, r, g, b);
    }
    fn draw_bbox(im: Self, bbox: sod.sod_box, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_bbox(im, bbox, r, g, b);
    }
    fn draw_bbox_width(im: Self, bbox: sod.sod_box, width: c_int, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_bbox_width(im, bbox, width, r, g, b);
    }
    fn draw_line(im: Self, start: sod.sod_pts, end: sod.sod_pts, r: f32, g: f32, b: f32) void {
        return sod.sod_image_draw_line(im, start, end, r, g, b);
    }
    fn to_blob(im: Self) [*c]u8 {
        return sod.sod_image_to_blob(im);
    }
};

pub const ColorSpace = enum(c_int) {
    COLOR = sod.SOD_IMG_COLOR,
    GRAY = sod.SOD_IMG_GRAYSCALE,
};

pub const SOD_LIB_INFO = "SOD Embedded - Release 1.1.8 under GPLv3. Copyright (C) 2018 - 2019 PixLab| Symisc Systems, https://sod.pixlab.io";

//const cnn_rnn_consts = enum(c_int) {
//    SOD_CNN_NETWORK_OUTPUT = 1,
//    SOD_CNN_DETECTION_THRESHOLD = 2,
//    SOD_CNN_NMS = 3,
//    SOD_CNN_DETECTION_CLASSES = 4,
//    SOD_CNN_RAND_SEED = 5,
//    SOD_CNN_HIER_THRESHOLD = 6,
//    SOD_CNN_TEMPERATURE = 7,
//    SOD_CNN_LOG_CALLBACK = 8,
//    SOD_RNN_CALLBACK = 9,
//    SOD_RNN_TEXT_LENGTH = 10,
//    SOD_RNN_DATA_LENGTH = 11,
//    SOD_RNN_SEED = 12,
//};
//
//const realnet_consts = enum(c_int) {
//    SOD_REALNET_MODEL_MINSIZE = 1,
//    SOD_REALNET_MODEL_MAXSIZE = 2,
//    SOD_REALNET_MODEL_SCALEFACTOR = 3,
//    SOD_REALNET_MODEL_STRIDEFACTOR = 4,
//    SOD_RELANET_MODEL_DETECTION_THRESHOLD = 5,
//    SOD_REALNET_MODEL_NMS = 6,
//    SOD_REALNET_MODEL_DISCARD_NULL_BOXES = 7,
//    SOD_REALNET_MODEL_NAME = 8,
//    SOD_REALNET_MODEL_ABOUT_INFO = 9,
//};

