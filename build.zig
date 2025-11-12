const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library module
    const grapzig_module = b.addModule("grapzig", .{
        .root_source_file = b.path("src/grapzig.zig"),
    });

    // Unit tests
    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/grapzig.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    // Examples
    const examples = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "basic", .path = "examples/basic.zig" },
        .{ .name = "schema", .path = "examples/schema.zig" },
        .{ .name = "mutations", .path = "examples/mutations.zig" },
        .{ .name = "server", .path = "examples/server.zig" },
        .{ .name = "graphql-server", .path = "examples/graphql_server.zig" },
        .{ .name = "real-world-blog", .path = "examples/real_world_blog.zig" },
    };

    const examples_step = b.step("examples", "Build all examples");

    inline for (examples) |example| {
        const exe_module = b.createModule(.{
            .root_source_file = b.path(example.path),
            .target = target,
            .optimize = optimize,
        });
        exe_module.addImport("grapzig", grapzig_module);

        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = exe_module,
        });

        b.installArtifact(exe);
        examples_step.dependOn(&b.addInstallArtifact(exe, .{}).step);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(
            b.fmt("run-{s}", .{example.name}),
            b.fmt("Run the {s} example", .{example.name}),
        );
        run_step.dependOn(&run_cmd.step);
    }
}
