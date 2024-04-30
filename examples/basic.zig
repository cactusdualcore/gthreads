const std = @import("std");
const gthr = @import("gthr");

fn count_to_ten() void {
    const tid: u8 = @intCast(gthr.tid());
    const which_thread: u8 = 'A' + tid - 2;

    for (1..10) |i| {
        std.debug.print("{c} {d}\n", .{ which_thread, i });
        _ = gthr.gtyield();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try gthr.init();
    defer gthr.ret(0);

    try gthr.gtgo(count_to_ten, allocator);
    try gthr.gtgo(count_to_ten, allocator);
}
