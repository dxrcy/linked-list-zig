const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const Allocator = mem.Allocator;

test "list works" {
    var list = try List(u32).init(std.testing.allocator);
    defer list.deinit();
    print_list(list);

    try list.push_front(21);
    try list.push_front(32);
    try list.push_front(43);
    print_list(list);
}

fn print_list(list: List(u32)) void {
    print("------- Inspect\n", .{});
    var next = list.head;
    var i: usize = 0;
    while (next) |node| {
        if (i > 5) {
            std.debug.panic("Too many items!", .{});
        }
        print("Node <{d}>\n    value = {d},\n    next = {*}\n", .{ i, node.value, node.next });
        next = node.next;
        i += 1;
    }
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
            print("------- FREE\n", .{});
            var next = self.head;
            var i: usize = 0;
            while (next) |node| {
                if (i > 10) {
                    std.debug.panic("Too many items!", .{});
                }
                print("<FREE>\n", .{});
                print(":: {d:2} :: {d}\n", .{ i, node.value });
                next = node.next;
                self.allocator.destroy(node);
                i += 1;
            }
        }

        fn push_front(self: *Self, value: T) !void {
            print("<PUSH> {d}\n", .{value});

            var node = try self.allocator.create(Node);
            node.value = value;
            node.next = self.head;
            self.head = node;
        }
    };
}
