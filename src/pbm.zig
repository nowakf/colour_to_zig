//mostly for testing purposes, not v. robust
const std = @import("std");
const File = std.fs.File;
const Allocator = std.mem.Allocator;

const PbmError = error {
    NO_TOK,
    UNEXPECTED_TOK,
};

fn expect(toks: *std.mem.TokenIterator(u8, .any), expected: []const u8) !void {
    const tok = toks.next() orelse return PbmError.NO_TOK;
    if (!std.mem.eql(u8, tok, expected) ) {
        return PbmError.UNEXPECTED_TOK;
    }
}

fn parse_header(buf: []const u8) !struct{w:u32, h:u32, h_len:u32} {
    var tokens = std.mem.tokenizeAny(u8, buf, "\n \t\r");
    try expect(&tokens, "P4");
    return .{
        .w = try std.fmt.parseInt(u32, tokens.next() orelse return PbmError.NO_TOK, 10),
        .h = try std.fmt.parseInt(u32, tokens.next() orelse return PbmError.NO_TOK, 10),
        .h_len = @intCast(tokens.index),
    };
}

pub fn from_file(alc: Allocator, f: File) ! struct {w:u32, h:u32, data:[]u8} {
    const buf = try f.readToEndAlloc(alc, 4096*4096);
    const dims = try parse_header(buf);
    std.mem.copyBackwards(u8, buf, buf[dims.h_len ..]);
    @memset(buf[buf.len - dims.h_len ..], 0);
    return .{
        .w = dims.w,
        .h = dims.h,
        .data = @alignCast(std.mem.alignInSlice(buf, @alignOf(usize))),
    };
}

test "x" {
    const alc = std.testing.allocator;
    const file = try std.fs.cwd().openFile("test.pbm", .{});
    defer file.close();
    const pbm = try from_file(alc, file);
    alc.free(pbm.data);
}
