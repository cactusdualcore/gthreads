const std = @import("std");

const native_endian = @import("builtin").target.cpu.arch.endian();

const default_size = 0x1000;

pub const StackOptions = struct {
    size: usize = default_size,
};

pub const Stack = struct {
    end: *const u8,
    bot: *const u8,
    ptr: [*]u8,

    pub fn init(allocator: std.mem.Allocator, options: StackOptions) !@This() {
        const end = try allocator.alloc(u8, options.size);
        const mem_ptr: [*]u8 = @ptrCast(end);
        return init_unmanaged(mem_ptr, options);
    }

    pub fn init_unmanaged(mem_ptr: [*]u8, options: StackOptions) !@This() {
        // x64 stacks grow down
        const bottom = mem_ptr + options.size;

        return @This(){
            .end = @ptrCast(mem_ptr),
            .bot = @ptrCast(bottom),
            .ptr = bottom,
        };
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.end);
    }

    pub fn bump(self: *@This(), size: comptime_int) void {
        self.ptr -= size;
    }

    pub fn push_fn(self: *@This(), func: *const fn () void) void {
        self.bump(@sizeOf(usize));
        std.mem.writeInt(usize, @ptrCast(self.ptr), @intFromPtr(func), native_endian);
    }

    pub fn push_int(self: *@This(), num: u32) void {
        self.bump(@sizeOf(u32));
        std.mem.writeInt(u32, @ptrCast(self.ptr), num, native_endian);
    }
};
