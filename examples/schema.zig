const std = @import("std");
const grapzig = @import("grapzig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Grapzig Schema Example ===\n\n", .{});

    // Create User type
    const user_type = try allocator.create(grapzig.ObjectType);
    user_type.* = grapzig.ObjectType.init(allocator, "User");
    // Note: user_type will be owned and cleaned up by the schema

    // Add fields to User type
    const id_field = grapzig.FieldDefinition.init(allocator, "id", .{ .scalar = .id });
    try user_type.addField("id", id_field);

    const name_field = grapzig.FieldDefinition.init(allocator, "name", .{ .scalar = .string });
    try user_type.addField("name", name_field);

    const email_field = grapzig.FieldDefinition.init(allocator, "email", .{ .scalar = .string });
    try user_type.addField("email", email_field);

    const age_field = grapzig.FieldDefinition.init(allocator, "age", .{ .scalar = .int });
    try user_type.addField("age", age_field);

    std.debug.print("Created User type with fields:\n", .{});
    var field_iter = user_type.fields.iterator();
    while (field_iter.next()) |entry| {
        std.debug.print("  - {s}\n", .{entry.key_ptr.*});
    }

    // Create Query type
    const query_type = try allocator.create(grapzig.ObjectType);
    query_type.* = grapzig.ObjectType.init(allocator, "Query");
    // Note: query_type will be owned and cleaned up by the schema

    // Add user query field
    const user_query_field = grapzig.FieldDefinition.init(allocator, "user", .{ .object = user_type });
    try query_type.addField("user", user_query_field);

    std.debug.print("\nCreated Query type with fields:\n", .{});
    var query_field_iter = query_type.fields.iterator();
    while (query_field_iter.next()) |entry| {
        std.debug.print("  - {s}\n", .{entry.key_ptr.*});
    }

    // Create schema
    var schema = grapzig.Schema.init(allocator, query_type);
    defer schema.deinit();

    try schema.addType(user_type);

    std.debug.print("\nSchema created successfully!\n", .{});
    std.debug.print("Query type: {s}\n", .{schema.query_type.name});
    std.debug.print("Registered types: {d}\n", .{schema.types.count()});

    // Using Schema Builder
    std.debug.print("\n=== Using Schema Builder ===\n", .{});

    var builder = grapzig.Schema.Builder.init(allocator);
    defer builder.deinit();

    const builder_query = try allocator.create(grapzig.ObjectType);
    builder_query.* = grapzig.ObjectType.init(allocator, "Query");
    // Note: builder_query will be owned and cleaned up by built_schema

    var built_schema = try builder.query(builder_query).build();
    defer built_schema.deinit();

    std.debug.print("Built schema with query type: {s}\n", .{built_schema.query_type.name});

    std.debug.print("\n✅ Schema example completed successfully!\n", .{});
}
