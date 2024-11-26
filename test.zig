const std = @import("std");
const blib = @import("blib.zig");

test "strings" {
    blib.println("strings:", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var word = try blib.String.from("hello", allocator);
    defer word.deinit();

    try word.push(u8, '!');

    var duplicate = try word.dupe();
    defer duplicate.deinit();

    duplicate.println();

    blib.println("", .{});
}

test "dynamic arrays" {
    blib.println("dynamic arrays:", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var nums = try blib.Dyn(i32).init(allocator);
    defer nums.deinit();

    try nums.push(10);
    try nums.push(20);

    if (nums.dequeue()) |num| {
        blib.println("{}", .{num});
    }

    if (nums.pop()) |num| {
        blib.println("{}", .{num});
    }
    blib.println("", .{});
}

pub fn main() !void {}
