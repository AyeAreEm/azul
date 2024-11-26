const std = @import("std");

pub fn Dyn(comptime T: type) type {
    return struct {
        data: []T,
        head: usize,
        len: usize,
        cap: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Dyn(T) {
            var arr: Dyn(T) = undefined;
            arr.len = 0;
            arr.head = 0;
            arr.cap = 32;
            arr.allocator = allocator;
            arr.data = try allocator.alloc(T, arr.cap);
            return arr;
        }

        pub fn withCapacity(allocator: std.mem.Allocator, cap: usize) !Dyn(T) {
            var arr: Dyn(T) = undefined;
            arr.len = 0;
            arr.head = 0;
            arr.cap = cap;
            arr.allocator = allocator;
            arr.data = try allocator.alloc(T, arr.cap);
            return arr;
        }

        pub fn dupe(self: *Dyn(T)) !Dyn(T) {
            const new_buf = try self.allocator.dupe(T, self.data);
            return Dyn(T){
                .len = self.len,
                .head = self.head,
                .cap = self.cap,
                .allocator = self.allocator,
                .data = new_buf,
            };
        }

        pub fn at(self: *Dyn(T), index: usize) ?T {
            if (index >= self.len) {
                return null;
            }

            return self.data[self.head + index];
        }

        pub fn resize(self: *Dyn(T)) !void {
            self.cap *= 2;
            self.data = try self.allocator.realloc(self.data, self.cap * @sizeOf(T));
        }

        pub fn resizeWithSize(self: *Dyn(T), size: usize) !void {
            self.cap = (self.cap * 2) + size;
            self.data = try self.allocator.realloc(self.data, self.cap * @sizeOf(T));
        }

        pub fn push(self: *Dyn(T), elem: T) !void {
            if (self.len + 1 >= self.cap) {
                try self.resize();
            }

            self.data[self.len] = elem;
            self.len += 1;
        }

        pub fn pop(self: *Dyn(T)) ?T {
            if (self.len == 0) {
                return null;
            }

            const elem = self.at(self.len - 1);
            if (elem) |_| {
                self.len -= 1;
            }

            return elem;
        }

        pub fn dequeue(self: *Dyn(T)) ?T {
            if (self.len == 0) {
                return null;
            }

            const elem = self.at(0);
            self.len -= 1;
            self.head += 1;

            return elem;
        }

        pub fn clear(self: *Dyn(T)) void {
            self.len = 0;
            self.head = 0;
            self.data[0] = 0;
        }

        // pub fn remove() !void {
        //     std.mem.trim(comptime T: type, slice: []const T, values_to_strip: []const T)
        // }

        pub fn deinit(self: *Dyn(T)) void {
            self.len = 0;
            self.head = 0;
            self.cap = 0;
            self.allocator.free(self.data);
        }
    };
}

pub const String = struct {
    buf: Dyn(u8),

    pub fn init(allocator: std.mem.Allocator) !String {
        return String{ .buf = try Dyn(u8).init(allocator) };
    }

    pub fn withCapacity(allocator: std.mem.Allocator, cap: usize) !String {
        return String{ .buf = try Dyn(u8).withCapacity(allocator, cap) };
    }

    pub fn dupe(self: *String) !String {
        const new_buf = try self.buf.allocator.dupe(u8, self.buf.data);
        var new_str = String{ .buf = .{
            .len = self.buf.len,
            .head = self.buf.head,
            .cap = self.buf.cap,
            .allocator = self.buf.allocator,
            .data = new_buf,
        } };

        if (new_str.buf.len + 1 >= new_str.buf.cap) {
            try new_str.buf.resize();
        }

        new_str.buf.data[new_str.buf.len] = 0;
        return new_str;
    }

    pub fn from(content: []const u8, allocator: std.mem.Allocator) !String {
        var str: String = try String.init(allocator);
        for (content) |ch| {
            try str.buf.push(ch);
        }

        if (str.buf.len + 1 >= str.buf.cap) {
            try str.buf.resize();
        }

        str.buf.data[str.buf.len] = 0;
        return str;
    }

    pub fn at(self: *String, index: usize) ?u8 {
        return self.buf.at(index);
    }

    pub fn replace(self: *String, index: usize, ch: u8) !void {
        if (self.buf.head + index >= self.buf.cap) {
            return error.IndexOutOfCapacityBounds;
        }

        self.buf.data[self.buf.head + index] = ch;
    }

    pub fn pushChar(self: *String, ch: u8) !void {
        if (self.buf.len + 1 >= self.buf.cap) {
            try self.buf.resize();
        }

        try self.replace(self.buf.len, ch);
        self.buf.len += 1;
        try self.replace(self.buf.len, ch);
    }

    pub fn pushStr(self: *String, content: []const u8) !void {
        if (self.buf.len + content.len >= self.buf.cap) {
            try self.buf.resizeWithSize(content.len);
        }

        for (content) |ch| {
            try self.pushChar(ch);
        }
    }

    pub fn containsChar(self: *String, pattern: u8) struct { bool, usize } {
        for (0..self.buf.len) |i| {
            if (self.buf.data[i] == pattern) {
                return .{ true, i };
            }
        }

        return .{ false, 0 };
    }

    pub fn constainsStr(self: *String, pattern: []const u8) .{ bool, usize } {
        var head = 0;
        var index = 0;

        if (self.buf.len < pattern.len) {
            return .{ false, 0 };
        }

        for (0..self.buf.len) |i| {
            if (head == pattern.len) {
                return .{ true, index };
            }

            if (self.buf.data[i] == pattern[head]) {
                head += 1;
            } else {
                head = 0;
                index = i;
            }
        }

        if (head == pattern.len) {
            return .{ true, index };
        }
    }

    pub fn containsString(self: *String, pattern: String) struct { bool, usize } {
        var head = 0;
        var index = 0;

        if (self.buf.len < pattern.buf.len) {
            return .{ false, 0 };
        }

        for (0..self.buf.len) |i| {
            if (head == pattern.buf.len) {
                return .{ true, index };
            }

            if (self.buf.data[i] == pattern.buf.data[head]) {
                head += 1;
            } else {
                head = 0;
                index = i;
            }
        }

        if (head == pattern.buf.len) {
            return .{ true, index };
        }
    }

    pub fn compare(self: *String, comparate: []const u8) bool {
        if (self.buf.len != comparate.len) {
            return false;
        }

        for (comparate, 0..) |ch, i| {
            if (self.buf.data[i] != ch) {
                return false;
            }
        }

        return true;
    }

    pub fn startsWith(self: *String, pattern: u8) bool {
        if (self.at(0)) |ch| {
            return ch == pattern;
        }

        return false;
    }

    pub fn endsWith(self: *String, pattern: u8) bool {
        if (self.at(self.buf.len - 1)) |ch| {
            return ch == pattern;
        }

        return false;
    }

    pub fn toUppercase(self: *String) void {
        self.buf.data = std.ascii.upperString(self.buf.data, self.buf.data);
    }

    pub fn toLowercase(self: *String) void {
        self.buf.data = std.ascii.lowerString(self.buf.data, self.buf.data);
    }

    pub fn get(self: *String) []const u8 {
        return self.buf.data[self.buf.head..self.buf.len];
    }

    pub fn getMut(self: *String) []u8 {
        return self.buf.data[self.buf.head..self.buf.len];
    }

    pub fn clear(self: *String) void {
        self.buf.clear();
    }

    pub fn deinit(self: *String) void {
        self.buf.deinit();
    }
};

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt, args);
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt, args);
    print("\n", .{});
}
