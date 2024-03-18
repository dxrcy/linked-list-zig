const std = @import("std");
const print = std.debug.print;
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;

/// Singly linked list
pub fn LinkedList(
    T: type,
) type {
    return struct {
        const Self = @This();

        head: ?*Node,
        allocator: Allocator,

        /// Linked list node
        pub const Node = struct {
            value: T,
            next: ?*Node,
        };

        fn indexOutOfBounds() noreturn {
            panic("Index out of bounds.", .{});
        }

        /// Create a new linked list
        pub fn init(allocator: anytype) Allocator.Error!Self {
            return Self{
                .head = null,
                .allocator = allocator,
            };
        }

        /// Deallocate list items
        pub fn deinit(self: Self) void {
            var next = self.head;
            while (next) |node| {
                next = node.next;
                self.allocator.destroy(node);
            }
        }

        /// O(1)
        pub fn pushFront(self: *Self, value: T) !void {
            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = self.head;
            self.head = node;
        }

        /// O(n)
        pub fn pushBack(self: *Self, value: T) !void {
            // Held by last item
            var tail_ptr = &self.head;
            while (tail_ptr.*) |node| {
                tail_ptr = &node.next;
            }

            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = null;
            tail_ptr.* = node;
        }

        /// O(1)
        pub fn popFront(self: *Self) ?T {
            // No items
            const head = self.head orelse return null;
            // Remove first item and return
            const value = head.value;
            self.head = head.next;
            self.allocator.destroy(head);
            return value;
        }

        // O(n)
        pub fn popBack(self: *Self) ?T {
            // No items
            const head = self.head orelse return null;
            // Held by second-last item, or head if length=1
            var tail_ptr = &self.head;
            var tail = head;

            // If length=1, ie. head is not tail
            if (head.next) |head_next| {
                tail = head_next;
                tail_ptr = &head.next;
                // Find last item
                while (tail.next) |tail_next| {
                    tail_ptr = &tail.next;
                    tail = tail_next;
                }
            }

            // Remove last item and return
            const value = tail.value;
            tail_ptr.* = null;
            self.allocator.destroy(tail);
            return value;
        }

        /// O(n)
        pub fn len(self: *const Self) usize {
            var length: usize = 0;
            var next = self.head;
            while (next) |node| {
                length += 1;
                next = node.next;
            }
            return length;
        }

        /// O(n)
        pub fn get(self: *const Self, index: usize) ?*const T {
            var next = self.head;
            var i: usize = 0;
            while (next) |node| {
                if (i == index) {
                    return &node.value;
                }
                next = node.next;
                i += 1;
            }
            return null;
        }

        /// O(1)
        pub fn front(self: *const Self) ?*const T {
            const head = self.head orelse return null;
            return &head.value;
        }

        /// O(1)
        pub fn frontMut(self: *Self) ?*T {
            const head = self.head orelse return null;
            return &head.value;
        }

        /// O(n)
        pub fn back(self: *const Self) ?*const T {
            var next = self.head;
            while (next) |node| {
                if (node.next == null) {
                    return &node.value;
                }
                next = node.next;
            }
            return null;
        }

        /// O(n)
        pub fn backMut(self: *Self) ?*T {
            var next = self.head;
            while (next) |node| {
                if (node.next == null) {
                    return &node.value;
                }
                next = node.next;
            }
            return null;
        }

        /// O(n)
        pub fn isEmpty(self: *const Self) bool {
            return self.len() == 0;
        }

        /// O(n)
        /// Panics if index out of bounds
        pub fn insert(self: *Self, index: usize, value: T) !void {
            var next = self.head;
            var i: usize = 1;
            while (next) |prev| {
                if (i == index) {
                    var node = try self.allocator.create(Node);
                    node.value = value;
                    node.next = prev.next;
                    prev.next = node;
                    return;
                }
                next = prev.next;
                i += 1;
            }
            Self.indexOutOfBounds();
        }

        /// O(n)
        /// Panics if index out of bounds
        pub fn remove(self: *Self, index: usize) ?T {
            var next = self.head;
            var prev_ptr = &self.head;
            var i: usize = 0;
            while (next) |node| {
                next = node.next;
                if (i == index) {
                    prev_ptr.* = next;
                    const value = node.value;
                    self.allocator.destroy(node);
                    return value;
                }
                prev_ptr = &node.next;
                i += 1;
            }
            Self.indexOutOfBounds();
        }

        // pub fn replace(self: *Self, index: usize, value: T) T

        // pub fn clear(self: *Self) void

        // pub fn append(self: *Self, other: *Self) !void

        // pub fn contains(self: *const Self, needle: &T) bool
    };
}

test "list works" {
    const expect = std.testing.expect;
    const allocator = std.testing.allocator;

    var list = try LinkedList(u8).init(allocator);
    defer list.deinit();
    inspect_list(list);
    try expect(list.len() == 0);
    try expect(list.isEmpty());
    try expect(list.get(0) == null);

    try list.pushFront('a');
    try list.pushFront('b');
    try list.pushFront('c');
    try list.pushFront('d');
    inspect_list(list);
    try expect(list.len() == 4);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'd');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2).?.* == 'b');
    try expect(list.get(3).?.* == 'a');
    try expect(list.get(4) == null);

    try expect(list.popFront() == 'd');
    inspect_list(list);
    try expect(list.len() == 3);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1).?.* == 'b');
    try expect(list.get(2).?.* == 'a');
    try expect(list.get(3) == null);

    try list.pushBack('x');
    inspect_list(list);
    try expect(list.len() == 4);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1).?.* == 'b');
    try expect(list.get(2).?.* == 'a');
    try expect(list.get(3).?.* == 'x');
    try expect(list.get(4) == null);

    var item = list.popBack();
    inspect_list(list);
    try expect(item == 'x');
    try expect(list.len() == 3);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1).?.* == 'b');
    try expect(list.get(2).?.* == 'a');
    try expect(list.get(3) == null);

    item = list.popBack();
    inspect_list(list);
    try expect(item == 'a');
    try expect(list.len() == 2);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1).?.* == 'b');
    try expect(list.get(2) == null);

    item = list.popBack();
    inspect_list(list);
    try expect(item == 'b');
    try expect(list.len() == 1);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1) == null);

    item = list.popBack();
    inspect_list(list);
    try expect(item == 'c');
    try expect(list.len() == 0);
    try expect(list.isEmpty());
    try expect(list.get(0) == null);

    item = list.popBack();
    inspect_list(list);
    try expect(item == null);
    try expect(list.len() == 0);
    try expect(list.isEmpty());
    try expect(list.get(0) == null);

    try list.pushFront('a');
    try list.pushFront('c');
    try list.pushFront('d');
    inspect_list(list);
    try expect(list.len() == 3);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'd');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2).?.* == 'a');
    try expect(list.get(3) == null);

    try list.insert(2, 'b');
    inspect_list(list);
    try expect(list.len() == 4);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'd');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2).?.* == 'b');
    try expect(list.get(3).?.* == 'a');
    try expect(list.get(4) == null);

    try expect(list.front().?.* == 'd');
    const front = list.frontMut();
    front.?.* = 'e';
    try expect(list.front().?.* == 'e');
    try expect(list.get(0).?.* == 'e');
    inspect_list(list);

    try expect(list.back().?.* == 'a');
    const back = list.backMut();
    back.?.* = 'x';
    try expect(list.back().?.* == 'x');
    try expect(list.get(list.len() - 1).?.* == 'x');
    inspect_list(list);
    try expect(list.len() == 4);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'e');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2).?.* == 'b');
    try expect(list.get(3).?.* == 'x');
    try expect(list.get(4) == null);

    item = list.remove(2);
    inspect_list(list);
    try expect(item == 'b');
    try expect(list.len() == 3);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'e');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2).?.* == 'x');
    try expect(list.get(3) == null);

    item = list.remove(2);
    inspect_list(list);
    try expect(item == 'x');
    try expect(list.len() == 2);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'e');
    try expect(list.get(1).?.* == 'c');
    try expect(list.get(2) == null);

    item = list.remove(0);
    inspect_list(list);
    try expect(item == 'e');
    try expect(list.len() == 1);
    try expect(!list.isEmpty());
    try expect(list.get(0).?.* == 'c');
    try expect(list.get(1) == null);

    item = list.remove(0);
    inspect_list(list);
    try expect(item == 'c');
    try expect(list.len() == 0);
    try expect(list.isEmpty());
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
