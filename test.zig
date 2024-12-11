const std = @import("std");
const azul = @import("azul.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var s = try azul.String.init(allocator);
    defer s.deinit();

    try s.push("hello");
    azul.println("{}", .{try s.contains('o')});
    azul.println("{}", .{try s.contains("ello")});

    azul.println("{s}", .{s.getSlice()});
}
