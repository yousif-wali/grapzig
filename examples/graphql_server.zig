const std = @import("std");
const grapzig = @import("grapzig");

/// Complete GraphQL Server Example
/// This shows how Grapzig ACTUALLY handles GraphQL queries on the server side

// Domain models
const User = struct {
    id: u32,
    name: []const u8,
    email: []const u8,
};

const Post = struct {
    id: u32,
    title: []const u8,
    content: []const u8,
    author_id: u32,
};

// Database (in real app, this would be PostgreSQL/MongoDB)
const Database = struct {
    allocator: std.mem.Allocator,
    users: std.ArrayList(User),
    posts: std.ArrayList(Post),
    next_post_id: u32,

    pub fn init(allocator: std.mem.Allocator) Database {
        return .{
            .allocator = allocator,
            .users = std.ArrayList(User){},
            .posts = std.ArrayList(Post){},
            .next_post_id = 1,
        };
    }

    pub fn deinit(self: *Database) void {
        self.users.deinit(self.allocator);
        self.posts.deinit(self.allocator);
    }

    pub fn findUserById(self: *Database, id: u32) ?User {
        for (self.users.items) |user| {
            if (user.id == id) return user;
        }
        return null;
    }

    pub fn findPostById(self: *Database, id: u32) ?Post {
        for (self.posts.items) |post| {
            if (post.id == id) return post;
        }
        return null;
    }

    pub fn createPost(self: *Database, title: []const u8, content: []const u8, author_id: u32) !Post {
        const post = Post{
            .id = self.next_post_id,
            .title = title,
            .content = content,
            .author_id = author_id,
        };
        self.next_post_id += 1;
        try self.posts.append(self.allocator, post);
        return post;
    }
};

// Build the GraphQL Schema
fn buildSchema(allocator: std.mem.Allocator) !grapzig.Schema {
    // User Type
    const user_type = try allocator.create(grapzig.ObjectType);
    user_type.* = grapzig.ObjectType.init(allocator, "User");
    try user_type.addField("id", grapzig.FieldDefinition.init(allocator, "id", .{ .scalar = .id }));
    try user_type.addField("name", grapzig.FieldDefinition.init(allocator, "name", .{ .scalar = .string }));
    try user_type.addField("email", grapzig.FieldDefinition.init(allocator, "email", .{ .scalar = .string }));

    // Post Type
    const post_type = try allocator.create(grapzig.ObjectType);
    post_type.* = grapzig.ObjectType.init(allocator, "Post");
    try post_type.addField("id", grapzig.FieldDefinition.init(allocator, "id", .{ .scalar = .id }));
    try post_type.addField("title", grapzig.FieldDefinition.init(allocator, "title", .{ .scalar = .string }));
    try post_type.addField("content", grapzig.FieldDefinition.init(allocator, "content", .{ .scalar = .string }));
    try post_type.addField("authorId", grapzig.FieldDefinition.init(allocator, "authorId", .{ .scalar = .int }));

    // Query Type
    const query_type = try allocator.create(grapzig.ObjectType);
    query_type.* = grapzig.ObjectType.init(allocator, "Query");
    try query_type.addField("user", grapzig.FieldDefinition.init(allocator, "user", .{ .object = user_type }));
    try query_type.addField("post", grapzig.FieldDefinition.init(allocator, "post", .{ .object = post_type }));

    // Mutation Type
    const mutation_type = try allocator.create(grapzig.ObjectType);
    mutation_type.* = grapzig.ObjectType.init(allocator, "Mutation");
    try mutation_type.addField("createPost", grapzig.FieldDefinition.init(allocator, "createPost", .{ .object = post_type }));

    var schema = grapzig.Schema.init(allocator, query_type);
    schema.mutation_type = mutation_type;

    return schema;
}

// THIS IS THE KEY PART: Execute GraphQL queries using Grapzig
fn executeGraphQLQuery(
    allocator: std.mem.Allocator,
    query_string: []const u8,
    schema: *grapzig.Schema,
    db: *Database,
) ![]const u8 {
    std.debug.print("\n🔥 Processing GraphQL Query with Grapzig 🔥\n", .{});
    std.debug.print("Query: {s}\n\n", .{query_string});

    // Step 1: Parse the query using Grapzig
    var parser = grapzig.Parser.init(allocator, query_string);
    var document = try parser.parse();
    defer document.deinit();

    std.debug.print("✅ Step 1: Query parsed successfully\n", .{});

    // Step 2: Validate the query using Grapzig
    var validator = grapzig.Validator.init(allocator, schema);
    defer validator.deinit();

    const is_valid = try validator.validate(&document);
    if (!is_valid) {
        std.debug.print("❌ Validation failed!\n", .{});
        return error.ValidationFailed;
    }

    std.debug.print("✅ Step 2: Query validated successfully\n", .{});

    // Step 3: Execute the query (THIS IS WHERE YOU CALL YOUR RESOLVERS)
    std.debug.print("✅ Step 3: Executing query...\n\n", .{});

    const operation = document.definitions.items[0].operation;
    const operation_type = operation.operation_type;

    if (operation_type == .query) {
        return try executeQuery(allocator, &operation, db);
    } else if (operation_type == .mutation) {
        return try executeMutation(allocator, &operation, db);
    }

    return error.UnsupportedOperation;
}

// Execute Query Operations
fn executeQuery(
    allocator: std.mem.Allocator,
    operation: *const grapzig.Operation,
    db: *Database,
) ![]const u8 {
    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    try result.appendSlice(allocator, "{\n  \"data\": {\n");

    for (operation.selections.items, 0..) |selection, i| {
        if (std.mem.eql(u8, selection.name, "user")) {
            // Get the 'id' argument
            const id_value = selection.arguments.get("id") orelse return error.MissingArgument;
            const user_id = @as(u32, @intCast(id_value.int));

            // Resolve user from database
            if (db.findUserById(user_id)) |user| {
                try result.appendSlice(allocator, "    \"user\": {\n");
                try result.appendSlice(allocator, "      \"id\": ");
                try std.fmt.format(result.writer(allocator), "{d}", .{user.id});
                try result.appendSlice(allocator, ",\n      \"name\": \"");
                try result.appendSlice(allocator, user.name);
                try result.appendSlice(allocator, "\",\n      \"email\": \"");
                try result.appendSlice(allocator, user.email);
                try result.appendSlice(allocator, "\"\n    }");
            } else {
                try result.appendSlice(allocator, "    \"user\": null");
            }
        } else if (std.mem.eql(u8, selection.name, "post")) {
            const id_value = selection.arguments.get("id") orelse return error.MissingArgument;
            const post_id = @as(u32, @intCast(id_value.int));

            if (db.findPostById(post_id)) |post| {
                try result.appendSlice(allocator, "    \"post\": {\n");
                try result.appendSlice(allocator, "      \"id\": ");
                try std.fmt.format(result.writer(allocator), "{d}", .{post.id});
                try result.appendSlice(allocator, ",\n      \"title\": \"");
                try result.appendSlice(allocator, post.title);
                try result.appendSlice(allocator, "\",\n      \"content\": \"");
                try result.appendSlice(allocator, post.content);
                try result.appendSlice(allocator, "\"\n    }");
            }
        }

        if (i < operation.selections.items.len - 1) {
            try result.appendSlice(allocator, ",\n");
        }
    }

    try result.appendSlice(allocator, "\n  }\n}");
    return result.toOwnedSlice(allocator);
}

// Execute Mutation Operations
fn executeMutation(
    allocator: std.mem.Allocator,
    operation: *const grapzig.Operation,
    db: *Database,
) ![]const u8 {
    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    try result.appendSlice(allocator, "{\n  \"data\": {\n");

    for (operation.selections.items) |selection| {
        if (std.mem.eql(u8, selection.name, "createPost")) {
            // Get arguments
            const title_value = selection.arguments.get("title") orelse return error.MissingArgument;
            const content_value = selection.arguments.get("content") orelse return error.MissingArgument;
            const author_id_value = selection.arguments.get("authorId") orelse return error.MissingArgument;

            const title = title_value.string;
            const content = content_value.string;
            const author_id = @as(u32, @intCast(author_id_value.int));

            // THIS IS WHERE GRAPZIG CALLS YOUR RESOLVER (createPost)
            const new_post = try db.createPost(title, content, author_id);

            try result.appendSlice(allocator, "    \"createPost\": {\n");
            try result.appendSlice(allocator, "      \"id\": ");
            try std.fmt.format(result.writer(allocator), "{d}", .{new_post.id});
            try result.appendSlice(allocator, ",\n      \"title\": \"");
            try result.appendSlice(allocator, new_post.title);
            try result.appendSlice(allocator, "\",\n      \"content\": \"");
            try result.appendSlice(allocator, new_post.content);
            try result.appendSlice(allocator, "\"\n    }");
        }
    }

    try result.appendSlice(allocator, "\n  }\n}");
    return result.toOwnedSlice(allocator);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== 🔥 GraphQL Server Example 🔥 ===\n", .{});
    std.debug.print("This shows how Grapzig ACTUALLY processes GraphQL queries\n\n", .{});

    // Initialize database
    var db = Database.init(allocator);
    defer db.deinit();

    try db.users.append(allocator, .{ .id = 1, .name = "Alice", .email = "alice@example.com" });
    try db.users.append(allocator, .{ .id = 2, .name = "Bob", .email = "bob@example.com" });
    try db.posts.append(allocator, .{ .id = 1, .title = "Hello World", .content = "First post", .author_id = 1 });

    std.debug.print("Database initialized with {d} users and {d} posts\n", .{ db.users.items.len, db.posts.items.len });

    // Build schema once
    var schema = try buildSchema(allocator);
    defer schema.deinit();

    std.debug.print("Schema created successfully\n", .{});

    // ============================================
    // Example 1: Client sends a Query
    // ============================================
    std.debug.print("\n============================================================\n", .{});
    std.debug.print("Example 1: Query a User\n", .{});
    std.debug.print("============================================================\n", .{});

    const query1 =
        \\query {
        \\  user(id: 1) {
        \\    name
        \\    email
        \\  }
        \\}
    ;

    const result1 = try executeGraphQLQuery(allocator, query1, &schema, &db);
    defer allocator.free(result1);

    std.debug.print("Response:\n{s}\n", .{result1});

    // ============================================
    // Example 2: Client sends a Mutation
    // ============================================
    std.debug.print("\n============================================================\n", .{});
    std.debug.print("Example 2: Create a Post (Mutation)\n", .{});
    std.debug.print("============================================================\n", .{});

    const mutation1 =
        \\mutation {
        \\  createPost(title: "New Post", content: "This is new content", authorId: 2) {
        \\    id
        \\    title
        \\  }
        \\}
    ;

    const result2 = try executeGraphQLQuery(allocator, mutation1, &schema, &db);
    defer allocator.free(result2);

    std.debug.print("Response:\n{s}\n", .{result2});

    // Verify the post was created
    std.debug.print("\n✅ Database now has {d} posts (was 1, created 1 new)\n", .{db.posts.items.len});

    // ============================================
    // Example 3: Query the newly created post
    // ============================================
    std.debug.print("\n============================================================\n", .{});
    std.debug.print("Example 3: Query the New Post\n", .{});
    std.debug.print("============================================================\n", .{});

    const query2 =
        \\query {
        \\  post(id: 2) {
        \\    title
        \\    content
        \\  }
        \\}
    ;

    const result3 = try executeGraphQLQuery(allocator, query2, &schema, &db);
    defer allocator.free(result3);

    std.debug.print("Response:\n{s}\n", .{result3});

    std.debug.print("\n============================================================\n", .{});
    std.debug.print("🎉 This is how Grapzig works on the server!\n", .{});
    std.debug.print("============================================================\n", .{});
    std.debug.print("\nKey Points:\n", .{});
    std.debug.print("1. Client sends GraphQL query string\n", .{});
    std.debug.print("2. Grapzig parses the query\n", .{});
    std.debug.print("3. Grapzig validates against schema\n", .{});
    std.debug.print("4. You execute by calling your resolvers\n", .{});
    std.debug.print("5. Grapzig helped you understand WHAT to execute\n", .{});
    std.debug.print("6. You return JSON response to client\n", .{});
    std.debug.print("\n✅ Complete, Happy Hacking!\n", .{});
}
