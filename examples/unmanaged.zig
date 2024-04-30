const std = @import("std");
const gthr = @import("gthr");

fn count_to_ten() void {
    const stderr = std.io.getStdErr();
    const writer = stderr.writer();

    const tid: u8 = @intCast(gthr.tid());

    const which_thread: u8 = 'A' + tid - 2;
    var buffer: [4]u8 = .{ which_thread, ' ', 0, '\n' };

    for (1..10) |i| {
        // 'std.fmt.format' causes a memory access violation
        // when called in the context of a green thread
        // initialized with 'gthr.gtgo_unmanaged'
        // if run **unoptimized**.
        // Weirdly enough, 'std.io.Writer.write' doesn't
        // seem to be the problem.
        // I don't know what's going on there.
        buffer[2] = '0' + @as(u8, @intCast(i));
        _ = writer.write(&buffer) catch @panic("Oh, no!");
        _ = gthr.gtyield();
    }

    // This, for example, would crash if compiled with -Doptimize=Debug
    //   writer.print("{d}\n", .{10}) catch unreachable;
}

const stack_size = 0x1000;

var st1: [stack_size]u8 align(8) = undefined;
var st2: [stack_size]u8 align(8) = undefined;

pub fn main() !void {
    try gthr.init();
    defer gthr.ret(0);

    try gthr.gtgo_unmanaged(count_to_ten, @ptrCast(&st1), stack_size);
    try gthr.gtgo_unmanaged(count_to_ten, @ptrCast(&st2), stack_size);
}
