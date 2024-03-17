const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const Allocator = mem.Allocator;

test "list works" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var list = try LinkedList(u8).init(allocator);
    defer list.deinit();
    print_list(list);

    try list.push_front('a');
    try list.push_front('b');
    try list.push_front('c');
    print_list(list);

    const value = try list.pop_front();
    try expect(value == 'c');
    print_list(list);
}

fn print_list(list: LinkedList(u8)) void {
    print("\n---------- Inspect\n", .{});
    print("- Length: {d}\n", .{list.len});
    var next = list.head;
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

pub fn LinkedList(
    T: type,
) type {
    return struct {
        const Self = @This();

        head: ?*Node,
        len: usize,
        allocator: Allocator,

        const Node = struct {
            value: T,
            next: ?*Node,
        };

        fn init(allocator: anytype) Allocator.Error!Self {
            return Self{
                .head = null,
                .len = 0,
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
            self.len += 1;
        }

        fn pop_front(self: *Self) !?T {
            if (self.head) |head| {
                const value = head.value;
                self.head = head.next;
                self.allocator.destroy(head);
                self.len -= 1;
                return value;
            } else {
                return null;
            }
        }
    };
}
