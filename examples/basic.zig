const std = @import("std");
const grapzig = @import("grapzig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Grapzig Basic Example ===\n\n", .{});

    // Create a simple query
    var query = grapzig.Query.init(allocator);
    defer query.deinit();

    // Build query: { user(id: 1) { name email } }
    var user_field = try query.field("user");
    _ = try user_field.arg("id", grapzig.Value.fromInt(1));
    var name_field = try user_field.select("name");
    name_field.done();
    var email_field = try user_field.select("email");
    email_field.done();
    user_field.done();

    const query_string = try query.build();
    defer allocator.free(query_string);

    std.debug.print("Generated Query:\n{s}\n", .{query_string});

    // Create a mutation
    var mutation = grapzig.Mutation.init(allocator);
    defer mutation.deinit();

    // Build mutation: mutation { createUser(name: "John", email: "john@example.com") { id name } }
    var create_user = try mutation.field("createUser");
    _ = try create_user.arg("name", grapzig.Value.fromString("John"));
    _ = try create_user.arg("email", grapzig.Value.fromString("john@example.com"));
    var id_field = try create_user.select("id");
    id_field.done();
    var user_name = try create_user.select("name");
    user_name.done();
    create_user.done();

    const mutation_string = try mutation.build();
    defer allocator.free(mutation_string);

    std.debug.print("\nGenerated Mutation:\n{s}\n", .{mutation_string});

    // Working with values
    std.debug.print("\n=== Value Examples ===\n", .{});

    const int_val = grapzig.Value.fromInt(42);
    const str_val = grapzig.Value.fromString("Hello, GraphQL!");
    const bool_val = grapzig.Value.fromBool(true);

    var buffer = std.ArrayList(u8){};
    defer buffer.deinit(allocator);

    try int_val.toJson(buffer.writer(allocator));
    std.debug.print("Int value: {s}\n", .{buffer.items});

    buffer.clearRetainingCapacity();
    try str_val.toJson(buffer.writer(allocator));
    std.debug.print("String value: {s}\n", .{buffer.items});

    buffer.clearRetainingCapacity();
    try bool_val.toJson(buffer.writer(allocator));
    std.debug.print("Boolean value: {s}\n", .{buffer.items});

    std.debug.print("\n✅ Basic example completed successfully!\n", .{});
}
