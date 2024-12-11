const std = @import("std");
const blib = @import("blib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var s = try blib.String.init(allocator);
    defer s.deinit();

    try s.push("hello");
    blib.println("{}", .{try s.contains('o')});
    blib.println("{}", .{try s.contains("ello")});

    blib.println("{s}", .{s.getSlice()});
}
