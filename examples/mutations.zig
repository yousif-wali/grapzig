const std = @import("std");
const grapzig = @import("grapzig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Grapzig Mutations Example ===\n\n", .{});

    // Example 1: Create user mutation
    std.debug.print("Example 1: Create User\n", .{});
    var create_mutation = grapzig.Mutation.init(allocator);
    defer create_mutation.deinit();

    var create_user = try create_mutation.field("createUser");
    _ = try create_user.arg("name", grapzig.Value.fromString("Alice"));
    _ = try create_user.arg("email", grapzig.Value.fromString("alice@example.com"));
    _ = try create_user.arg("age", grapzig.Value.fromInt(25));
    var id_field = try create_user.select("id");
    id_field.done();
    var name_field = try create_user.select("name");
    name_field.done();
    create_user.done();

    const create_query = try create_mutation.build();
    defer allocator.free(create_query);
    std.debug.print("{s}\n", .{create_query});

    // Example 2: Update user mutation
    std.debug.print("\nExample 2: Update User\n", .{});
    var update_mutation = grapzig.Mutation.init(allocator);
    defer update_mutation.deinit();

    var update_user = try update_mutation.field("updateUser");
    _ = try update_user.arg("id", grapzig.Value.fromInt(1));
    _ = try update_user.arg("name", grapzig.Value.fromString("Alice Updated"));
    var updated_name = try update_user.select("name");
    updated_name.done();
    var updated_email = try update_user.select("email");
    updated_email.done();
    update_user.done();

    const update_query = try update_mutation.build();
    defer allocator.free(update_query);
    std.debug.print("{s}\n", .{update_query});

    // Example 3: Delete user mutation
    std.debug.print("\nExample 3: Delete User\n", .{});
    var delete_mutation = grapzig.Mutation.init(allocator);
    defer delete_mutation.deinit();

    var delete_user = try delete_mutation.field("deleteUser");
    _ = try delete_user.arg("id", grapzig.Value.fromInt(1));
    var success_field = try delete_user.select("success");
    success_field.done();
    delete_user.done();

    const delete_query = try delete_mutation.build();
    defer allocator.free(delete_query);
    std.debug.print("{s}\n", .{delete_query});

    // Example 4: Complex mutation with nested input
    std.debug.print("\nExample 4: Complex Mutation with Object Input\n", .{});
    var complex_mutation = grapzig.Mutation.init(allocator);
    defer complex_mutation.deinit();

    // Create an input object
    var input_obj = std.StringHashMap(grapzig.Value).init(allocator);
    // Note: input_obj will be owned by the Value and cleaned up when complex_mutation.deinit() is called
    // So we don't need a separate defer for it

    try input_obj.put("title", grapzig.Value.fromString("Mr"));
    try input_obj.put("firstName", grapzig.Value.fromString("Bob"));
    try input_obj.put("lastName", grapzig.Value.fromString("Smith"));

    var register_user = try complex_mutation.field("registerUser");
    _ = try register_user.arg("input", grapzig.Value{ .object = input_obj });
    var user_id = try register_user.select("id");
    user_id.done();
    var full_name = try register_user.select("fullName");
    full_name.done();
    register_user.done();

    const complex_query = try complex_mutation.build();
    defer allocator.free(complex_query);
    std.debug.print("{s}\n", .{complex_query});

    std.debug.print("\n✅ Mutations example completed successfully!\n", .{});
}
