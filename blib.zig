const std = @import("std");

pub fn Dyn(comptime T: type) type {
    return struct {
        data: []T,
        len: usize,
        cap: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Dyn(T) {
            var arr: Dyn(T) = undefined;
            arr.len = 0;
            arr.cap = 32;
            arr.allocator = allocator;
            arr.data = try allocator.alloc(T, arr.cap);
            return arr;
        }

        pub fn withCapacity(allocator: std.mem.Allocator, cap: usize) !Dyn(T) {
            var arr: Dyn(T) = undefined;
            arr.len = 0;
            arr.cap = cap;
            arr.allocator = allocator;
            arr.data = try allocator.alloc(T, arr.cap);
            return arr;
        }

        pub fn dupe(self: *Dyn(T)) !Dyn(T) {
            const new_buf = try self.allocator.dupe(T, self.data);
            return Dyn(T){
                .len = self.len,
                .cap = self.cap,
                .allocator = self.allocator,
                .data = new_buf,
            };
        }

        pub fn at(self: *Dyn(T), index: usize) ?T {
            if (index >= self.len) {
                return null;
            }

            return self.data[index];
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

        pub fn replace(self: *Dyn(T), index: usize, elem: T) !void {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }

            self.data[index] = elem;
        }

        pub fn clear(self: *Dyn(T)) void {
            self.len = 0;
            self.data[0] = 0;
        }

        pub fn remove(self: *Dyn(T), index: usize) !void {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }

            for (index + 1..self.len) |i| {
                self.data[i - 1] = self.data[i];
            }

            self.len -= 1;
        }

        pub fn deinit(self: *Dyn(T)) void {
            self.len = 0;
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
        var new_str = String{ .buf = self.buf.dupe() };

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

    pub fn pushChar(self: *String, ch: u8) !void {
        if (self.buf.len + 1 >= self.buf.cap) {
            try self.buf.resize();
        }

        self.buf.data[self.buf.len] = ch;
        self.buf.len += 1;
        self.buf.data[self.buf.len] = 0;
    }

    pub fn pushSlice(self: *String, content: []const u8) !void {
        if (self.buf.len + content.len >= self.buf.cap) {
            try self.buf.resizeWithSize(content.len);
        }

        for (content) |ch| {
            try self.pushChar(ch);
        }
    }

    pub fn pushString(self: *String, content: String) !void {
        try self.pushSlice(content.getSlice());
    }

    pub fn push(self: *String, elem: anytype) !void {
        switch (@TypeOf(elem)) {
            comptime_int => {
                // const char: u8 = @intCast(elem);
                // try self.pushChar(char);
                try self.pushChar(elem);
            },
            []const u8 => {
                try self.pushSlice(elem);
            },
            String => {
                try self.pushString(elem);
            },
            else => {
                const slice = if (@typeInfo(@TypeOf(elem)) == .Pointer) elem else &elem;
                try self.pushSlice(slice);
            },
        }
    }

    pub fn pop(self: *String) ?u8 {
        return self.buf.pop();
    }

    pub fn replace(self: *String, index: usize, ch: u8) !void {
        try self.buf.replace(index, ch);
    }

    pub fn containsChar(self: *String, pattern: u8) struct { bool, usize } {
        for (0..self.buf.len) |i| {
            if (self.buf.data[i] == pattern) {
                return .{ true, i };
            }
        }

        return .{ false, 0 };
    }

    pub fn containsSlice(self: *String, pattern: []const u8) struct { bool, usize } {
        var head: usize = 0;
        var index: usize = 0;

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
                if (i == 0) {
                    index = 1;
                } else {
                    index = i;
                }
            }
        }

        if (head == pattern.len) {
            return .{ true, index };
        }

        return .{ false, 0 };
    }

    pub fn containsString(self: *String, pattern: String) struct { bool, usize } {
        return self.containsSlice(pattern.getSlice());
    }

    pub fn contains(self: *String, pattern: anytype) !struct { bool, usize } {
        switch (@TypeOf(pattern)) {
            comptime_int => {
                return self.containsChar(pattern);
            },
            []const u8 => {
                return self.containsSlice(pattern);
            },
            String => {
                return self.containsString(pattern);
            },
            else => {
                const slice = if (@typeInfo(@TypeOf(pattern)) == .Pointer) pattern else &pattern;
                return self.containsSlice(slice);
            },
        }
    }

    pub fn compareSlice(self: *String, comparate: []const u8) bool {
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

    pub fn compareString(self: *String, comparate: String) bool {
        return self.compareSlice(comparate.getSlice());
    }

    pub fn compare(self: *String, comparate: anytype) !bool {
        switch (@TypeOf(comparate)) {
            []const u8 => {
                return self.compareSlice(comparate);
            },
            String => {
                return self.compareString(comparate);
            },
            else => {
                const slice = if (@typeInfo(@TypeOf(comparate)) == .Pointer) comparate else &comparate;
                return self.compareSlice(slice);
            },
        }
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

    pub fn getSlice(self: *String) []const u8 {
        return self.buf.data[0..self.buf.len];
    }

    pub fn getMutSlice(self: *String) []u8 {
        return self.buf.data[self.buf.head..self.buf.len];
    }

    pub fn clear(self: *String) void {
        self.buf.clear();
    }

    pub fn deinit(self: *String) void {
        self.buf.deinit();
    }
};

pub const print = std.debug.print;
pub fn println(comptime fmt: []const u8, args: anytype) void {
    print(fmt, args);
    print("\n", .{});
}
