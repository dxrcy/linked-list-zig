const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const Allocator = mem.Allocator;

test "list works" {
    var list = try List(u8).init(std.testing.allocator);
    defer list.deinit();
    print_list(list);

    try list.push_front('a');
    try list.push_front('b');
    try list.push_front('c');
    print_list(list);
}

fn print_list(list: List(u8)) void {
    print("\n---------- Inspect\n", .{});
    var next = list.head;
    if (next == null) {
        print("(empty)\n", .{});
    }
    var i: usize = 0;
    while (next) |node| {
        if (i > 5) {
            std.debug.panic("Too many items!", .{});
        }
        print("Node <{d}>\n    value = {c},\n    next = {*}\n", .{ i, node.value, node.next });
        next = node.next;
        i += 1;
    }
    print("---------- /Inspect\n\n", .{});
}

pub fn List(
    T: type,
) type {
    return struct {
        const Self = @This();

        head: ?*Node,
        allocator: Allocator,

        const Node = struct {
            value: T,
            next: ?*Node,
        };

        fn init(allocator: anytype) Allocator.Error!Self {
            return Self{
                .head = null,
                .allocator = allocator,
            };
        }

        fn deinit(self: Self) void {
            var next = self.head;
            while (next) |node| {
                next = node.next;
                self.allocator.destroy(node);
            }
        }

        fn push_front(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = self.head;
            self.head = node;
        }
    };
}
