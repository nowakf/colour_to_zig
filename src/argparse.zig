const std = @import("std");
const ArgIterator = std.process.ArgIterator;

pub fn ArgParser(comptime T: type, comptime usage: []const u8) type {
    return struct {
        fn parse_opt(args: *ArgIterator, comptime out_type: type) !out_type {
            const inf = @typeInfo(out_type);
            if (inf == .Bool) {
                return true;
            } else {
                const val = args.next() orelse error.NO_ARGUMENT;
                return switch (inf) {
                    .Array, .Pointer => val,
                    .ComptimeInt => try std.fmt.parseInt(val),
                    .ComptimeFloat => try std.fmt.parseFloat(val),
                    else => std.debug.panic("unknown: {s}", .{@typeName(@TypeOf(inf))})
                };
            }
        }
        pub fn get_help() []const u8 {
            const default = T{};
            comptime var out_str : []const u8 = usage ++ "\n";
            inline for (std.meta.fields(T)) |field| {
                const longopt: []const u8 = "--" ++ field.name;
                const shortopt: []const u8 = &.{'-', field.name[0]};
                const defualt_value = switch (@typeInfo(field.type)) {
                    .Array, .Pointer => std.fmt.comptimePrint("{s}", .{@field(default, field.name)}),
                    else => std.fmt.comptimePrint("{any}", .{@field(default, field.name)}),
                };
                out_str = out_str
                    ++ longopt ++ ", "
                    ++ shortopt ++ ", "
                    ++ "default value is: "
                    ++ defualt_value ++ "\n";
            }
            return out_str;
        }

        pub fn parse(args: *ArgIterator) !T {
            const fields = std.meta.fields(T);
            var out = T{};
            while (args.next()) |arg| {
                inline for (fields) |field| {
                    const longopt: [:0]const u8 = "--" ++ field.name;
                    const shortopt: [:0]const u8 = &.{'-', field.name[0]};
                    if (std.mem.eql(u8, arg, longopt) or std.mem.eql(u8, arg, shortopt)) {
                        @field(out, field.name) = try ArgParser(T, usage).parse_opt(args, field.type);
                        break;
                    }
                }
            }
            return out;
        }
    };
}
