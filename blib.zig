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

        pub fn with_capacity(allocator: std.mem.Allocator, cap: usize) !Dyn(T) {
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

        pub fn resize_with_size(self: *Dyn(T), size: usize) !void {
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

    pub fn with_capacity(allocator: std.mem.Allocator, cap: usize) !String {
        return String{ .buf = try Dyn(u8).with_capacity(allocator, cap) };
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

    pub fn push_char(self: *String, ch: u8) !void {
        if (self.buf.len + 1 >= self.buf.cap) {
            try self.buf.resize();
        }

        self.buf.data[self.buf.len] = ch;
        self.buf.len += 1;
        self.buf.data[self.buf.len] = 0;
    }

    pub fn push_cstr(self: *String, content: []const u8) !void {
        if (self.buf.len + content.len >= self.buf.cap) {
            try self.buf.resize_with_size(content.len);
        }

        for (content, 0..) |ch, i| {
            self.buf.data[self.buf.len + i] = ch;
            self.buf.len += 1;
        }
        // add \0
        std.debug.print("{}", .{self.buf.data[self.buf.len]});
    }

    pub fn push(self: *String, comptime T: type, content: T) !void {
        if (@TypeOf(T) == @TypeOf(u8)) {
            try self.push_char(content);
        } else if (@TypeOf(T) == @TypeOf([]const u8)) {
            try self.push_cstr(content);
        }
    }

    pub fn print(content: String) void {
        for (0..content.buf.len) |i| {
            std.debug.print("{c}", .{content.buf.data[i]});
        }
    }

    pub fn println(content: String) void {
        String.print(content);
        std.debug.print("\n", .{});
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
