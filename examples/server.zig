const std = @import("std");
const grapzig = @import("grapzig");

// Example context for resolvers
const Context = struct {
    users: std.ArrayList(User),

    const User = struct {
        id: i64,
        name: []const u8,
        email: []const u8,
        age: i64,
    };
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Grapzig Server Example ===\n\n", .{});

    // Initialize context with sample data
    var context = Context{
        .users = std.ArrayList(Context.User){},
    };
    defer context.users.deinit(allocator);

    try context.users.append(allocator, .{
        .id = 1,
        .name = "Alice",
        .email = "alice@example.com",
        .age = 25,
    });

    try context.users.append(allocator, .{
        .id = 2,
        .name = "Bob",
        .email = "bob@example.com",
        .age = 30,
    });

    std.debug.print("Initialized context with {d} users\n\n", .{context.users.items.len});

    // Create schema
    const user_type = try allocator.create(grapzig.ObjectType);
    user_type.* = grapzig.ObjectType.init(allocator, "User");
    // Note: user_type will be owned and cleaned up by the schema

    try user_type.addField("id", grapzig.FieldDefinition.init(allocator, "id", .{ .scalar = .id }));
    try user_type.addField("name", grapzig.FieldDefinition.init(allocator, "name", .{ .scalar = .string }));
    try user_type.addField("email", grapzig.FieldDefinition.init(allocator, "email", .{ .scalar = .string }));
    try user_type.addField("age", grapzig.FieldDefinition.init(allocator, "age", .{ .scalar = .int }));

    const query_type = try allocator.create(grapzig.ObjectType);
    query_type.* = grapzig.ObjectType.init(allocator, "Query");
    // Note: query_type will be owned and cleaned up by the schema

    try query_type.addField("user", grapzig.FieldDefinition.init(allocator, "user", .{ .object = user_type }));
    try query_type.addField("users", grapzig.FieldDefinition.init(allocator, "users", .{ .object = user_type }));

    var schema = grapzig.Schema.init(allocator, query_type);
    defer schema.deinit();

    std.debug.print("Schema created with types:\n", .{});
    std.debug.print("  - Query\n", .{});
    std.debug.print("  - User\n\n", .{});

    // Parse a query
    const query_string =
        \\query {
        \\  user(id: 1) {
        \\    name
        \\    email
        \\  }
        \\}
    ;

    std.debug.print("Parsing query:\n{s}\n\n", .{query_string});

    var parser = grapzig.Parser.init(allocator, query_string);
    var document = try parser.parse();
    defer document.deinit();

    std.debug.print("✅ Query parsed successfully!\n", .{});
    std.debug.print("Definitions: {d}\n\n", .{document.definitions.items.len});

    // Validate the query
    var validator = grapzig.Validator.init(allocator, &schema);
    defer validator.deinit();

    const is_valid = try validator.validate(&document);
    std.debug.print("Query validation: {s}\n", .{if (is_valid) "✅ Valid" else "❌ Invalid"});

    if (!is_valid) {
        std.debug.print("Validation errors:\n", .{});
        for (validator.getErrors()) |err| {
            std.debug.print("  - {s}\n", .{err.message});
        }
    }

    std.debug.print("\n=== Simulating Query Execution ===\n", .{});
    std.debug.print("Would execute query and return:\n", .{});
    std.debug.print("{{\n", .{});
    std.debug.print("  \"data\": {{\n", .{});
    std.debug.print("    \"user\": {{\n", .{});
    std.debug.print("      \"name\": \"{s}\",\n", .{context.users.items[0].name});
    std.debug.print("      \"email\": \"{s}\"\n", .{context.users.items[0].email});
    std.debug.print("    }}\n", .{});
    std.debug.print("  }}\n", .{});
    std.debug.print("}}\n", .{});

    std.debug.print("\n✅ Server example completed successfully!\n", .{});
}
