const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

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

        // O(1)
        fn push_front(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = self.head;
            self.head = node;
            self.len += 1;
        }

        // O(n)
        fn push_back(self: *Self, value: T) !void {
            // Held by last item
            var tail_ptr = &self.head;
            while (tail_ptr.*) |node| {
                tail_ptr = &node.next;
            }

            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = null;
            tail_ptr.* = node;
            self.len += 1;
        }

        // O(1)
        fn pop_front(self: *Self) ?T {
            // No items
            const head = self.head orelse return null;
            // Remove first item and return
            const value = head.value;
            self.head = head.next;
            self.allocator.destroy(head);
            self.len -= 1;
            return value;
        }

        // O(n)
        fn pop_back(self: *Self) ?T {
            // No items
            const head = self.head orelse return null;
            // Held by second-last item, or head if len=1
            var tail_ptr = &self.head;
            var tail = head;

            // If len=1, ie. head is not tail
            if (head.next) |head_next| {
                tail = head_next;
                tail_ptr = &head.next;
                // Find last iteem
                while (tail.next) |tail_next| {
                    tail_ptr = &tail.next;
                    tail = tail_next;
                }
            }

            // Remove last item and return
            const value = tail.value;
            tail_ptr.* = null;
            self.allocator.destroy(tail);
            self.len -= 1;
            return value;
        }

        // O(n)
        fn get(self: *const Self, index: usize) ?T {
            var next = self.head;
            var i: usize = 0;
            while (next) |node| {
                if (i >= index) {
                    return node.value;
                }
                next = node.next;
                i += 1;
            }
            return null;
        }

        // O(1)
        fn is_empty(self: *const Self) bool {
            return self.len == 0;
        }
    };
}

test "list works" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var list = try LinkedList(u8).init(allocator);
    defer list.deinit();
    inspect_list(list);
    try expect(list.len == 0);
    try expect(list.is_empty());
    try expect(list.get(0) == null);

    try list.push_front('a');
    try list.push_front('b');
    try list.push_front('c');
    try list.push_front('d');
    inspect_list(list);
    try expect(list.len == 4);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'd');
    try expect(list.get(1) == 'c');
    try expect(list.get(2) == 'b');
    try expect(list.get(3) == 'a');
    try expect(list.get(4) == null);

    try expect(list.pop_front() == 'd');
    inspect_list(list);
    try expect(list.len == 3);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'c');
    try expect(list.get(1) == 'b');
    try expect(list.get(2) == 'a');
    try expect(list.get(3) == null);

    try list.push_back('x');
    inspect_list(list);
    try expect(list.len == 4);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'c');
    try expect(list.get(1) == 'b');
    try expect(list.get(2) == 'a');
    try expect(list.get(3) == 'x');
    try expect(list.get(4) == null);

    var val = list.pop_back();
    inspect_list(list);
    try expect(val == 'x');
    try expect(list.len == 3);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'c');
    try expect(list.get(1) == 'b');
    try expect(list.get(2) == 'a');
    try expect(list.get(3) == null);

    val = list.pop_back();
    inspect_list(list);
    try expect(val == 'a');
    try expect(list.len == 2);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'c');
    try expect(list.get(1) == 'b');
    try expect(list.get(2) == null);

    val = list.pop_back();
    inspect_list(list);
    try expect(val == 'b');
    try expect(list.len == 1);
    try expect(!list.is_empty());
    try expect(list.get(0) == 'c');
    try expect(list.get(1) == null);

    val = list.pop_back();
    inspect_list(list);
    try expect(val == 'c');
    try expect(list.len == 0);
    try expect(list.is_empty());
    try expect(list.get(0) == null);

    val = list.pop_back();
    inspect_list(list);
    try expect(val == null);
    try expect(list.len == 0);
    try expect(list.is_empty());
    try expect(list.get(0) == null);
}

fn inspect_list(list: LinkedList(u8)) void {
    var next = list.head;
    var i: usize = 0;
    print("[", .{});
    while (next) |node| {
        if (i > 0) {
            print(", ", .{});
        }
        print("{c}", .{node.value});
        next = node.next;
        i += 1;
    }
    print("]\n", .{});
}
