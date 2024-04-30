const std = @import("std");
const stack = @import("stack.zig");

pub const Regs = extern struct {
    rsp: u64,
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    rbx: u64,
    rbp: u64,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print(
            "[ %rsp {x}, %r15 {x}, %r14 {x}, %r13 {x}, %r12 {x}, %rbx {x}, %rbp {x} ]",
            .{ self.rsp, self.r15, self.r14, self.r13, self.r12, self.rbx, self.rbp },
        );
    }
};

pub const Thread = struct {
    sp: stack.Stack,
    tid: u16 = 0,
    regs: Regs,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{{ {d} ", .{self.tid});
        try self.regs.format(fmt, options, writer);
        try writer.writeAll(" }");
    }
};
