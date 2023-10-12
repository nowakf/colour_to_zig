const std = @import("std");

const sod = @cImport({
    @cInclude("<stddef.h>");
    @cInclude("sod.h");
});

fn wrap_declarations(comptime sd: type) type {
    const decls = std.meta.declarations(sd);
    for (decls) |decl| {
        _ = decl;
    }
}

fn tes() void {
    inline for (std.meta.fields(@TypeOf(sod))) |f| {
        _ = f;
    }
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
