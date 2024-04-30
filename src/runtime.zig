const std = @import("std");
const stack = @import("stack.zig");
const Thread = @import("threads.zig").Thread;
const Regs = @import("threads.zig").Regs;

pub const Stack = stack.Stack;

const max_threads = 4;

const ThreadTable = std.BoundedArray(Thread, max_threads);

pub var table: ThreadTable = undefined;
export var running_thread_index: usize = undefined;

pub fn init() !void {
    table = try ThreadTable.init(1);

    table.buffer[0] = Thread{
        .regs = undefined,
        .tid = 1,
        .sp = undefined,
    };

    running_thread_index = 0;
}

pub fn tid() u16 {
    return table.buffer[running_thread_index].tid;
}

extern fn gtswtch(old: *Regs, new: *const Regs) callconv(.C) void;

pub fn gtyield() callconv(.C) u16 {
    var threads: []Thread = table.slice();

    if (threads.len == 1) {
        return 0;
    }

    const next_thread_index = @mod(running_thread_index + 1, threads.len);
    const next_thread = threads[next_thread_index];

    const old = &threads[running_thread_index].regs;
    const new = &next_thread.regs;

    running_thread_index = next_thread_index;
    gtswtch(old, new);
    return next_thread.tid;
}

pub fn ret(code: u8) noreturn {
    if (running_thread_index != 0) {
        _ = table.orderedRemove(running_thread_index);
        running_thread_index -= 1;
        _ = gtyield();
    }
    while (gtyield() > 1) {
        // wait for other threads to finish
    }
    std.process.exit(code);
}

pub fn gtstop() noreturn {
    ret(0);
}

var global_thread_counter: u16 = 1;

fn prepare_thread_environment(st: stack.Stack, exit: *const fn () noreturn, entrypoint: *const fn () void) !void {
    var thread = try table.addOne();
    thread.sp = st;
    var sp = &thread.sp;

    sp.push_fn(exit);
    sp.push_fn(entrypoint);

    thread.regs.rsp = @intCast(@intFromPtr(sp.ptr));

    global_thread_counter += 1;
    thread.tid = global_thread_counter;
}

pub fn gtgo(entrypoint: *const fn () void, allocator: std.mem.Allocator) !void {
    const st = try stack.Stack.init(allocator, .{});
    try prepare_thread_environment(st, @ptrCast(&gtstop), entrypoint);
}

pub fn gtgo_unmanaged(entrypoint: *const fn () void, sp: [*]u8, len: usize) !void {
    const st = try stack.Stack.init_unmanaged(sp, .{ .size = len });
    try prepare_thread_environment(st, @ptrCast(&gtstop), entrypoint);
}
