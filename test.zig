const std = @import("std");
const blib = @import("blib.zig");

test "string pushStr" {
    blib.println("string pushStr:", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var word = try blib.String.from("hello", allocator);
    defer word.deinit();

    try word.pushStr(" world!");

    blib.println("{s}", .{word.get()});
    blib.println("", .{});
}

test "string toUppercase" {
    blib.println("string toUppercase:", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var word = try blib.String.from("hello!", allocator);
    defer word.deinit();

    word.toUppercase();
    blib.println("{s}", .{word.get()});
    blib.println("", .{});
}

test "string compare" {
    blib.println("string compare:", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var word = try blib.String.from("hello!", allocator);
    defer word.deinit();

    blib.println("{}", .{word.compare("hello!")});
    blib.println("", .{});
}

pub fn main() !void {}
