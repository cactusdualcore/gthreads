const std = @import("std");

const default_example_name = "basic";

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gthr = b.addModule("gthr", .{
        .root_source_file = .{ .path = "src/runtime.zig" },
        .target = target,
        .optimize = optimize,
    });
    gthr.addAssemblyFile(.{ .path = "src/asm/x64/gtswtch.s" });

    const example = try example_entrypoint(b);

    const exe = b.addExecutable(.{
        .name = example.name,
        .root_source_file = .{ .path = example.file_name },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("gthr", gthr);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addAssemblyFile(.{ .path = "src/gtswtch.s" });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

const Entrypoint = struct {
    name: []const u8,
    file_name: []const u8,
};
const Examples = std.ArrayList(Entrypoint);

fn example_entrypoint(b: *std.Build) !Entrypoint {
    const example_list = try examples(b);

    const raw_example_name = b.option([]const u8, "example", "the name of an example to run");
    const example_name = raw_example_name orelse default_example_name;

    var root_source_file: ?[]const u8 = null;
    for (example_list.items) |*entry| {
        if (std.mem.eql(u8, entry.name, example_name)) {
            root_source_file = entry.file_name;
        }
    }

    const path = try std.fs.path.join(
        b.allocator,
        &.{ "examples", root_source_file.? },
    );

    return .{
        .name = example_name,
        .file_name = path,
    };
}

fn examples(b: *std.Build) !Examples {
    var source_files = Examples.init(b.allocator);
    var files = try std.fs.cwd().openDir("examples", .{ .iterate = true });

    var iter = files.iterate();
    while (try iter.next()) |file| {
        var entrypoint: ?Entrypoint = null;
        switch (file.kind) {
            .file => if (std.mem.endsWith(u8, file.name, ".zig")) {
                const raw_name = file.name[0 .. file.name.len - 4];
                const name = try b.allocator.dupe(u8, raw_name);
                const file_name = try b.allocator.dupe(u8, file.name);

                entrypoint = .{
                    .name = name,
                    .file_name = file_name,
                };
            },
            .directory => {
                const name = try b.allocator.dupeZ(u8, file.name);
                entrypoint = .{
                    .name = name,
                    .file_name = try std.fs.path.joinZ(b.allocator, &.{ name, "main.zig" }),
                };
            },
            else => @panic("unhandled file kind"),
        }
        if (entrypoint) |entry| {
            try source_files.append(entry);
        }
    }

    return source_files;
}
