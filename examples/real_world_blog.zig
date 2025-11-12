const std = @import("std");
const grapzig = @import("grapzig");

/// Real-world example: Blog API with GraphQL
/// This demonstrates how to use Grapzig in a production scenario

// Domain models
const Post = struct {
    id: u32,
    title: []const u8,
    content: []const u8,
    author_id: u32,
    published: bool,
};

const User = struct {
    id: u32,
    name: []const u8,
    email: []const u8,
};

const Comment = struct {
    id: u32,
    post_id: u32,
    author_id: u32,
    content: []const u8,
};

// Database context (in real app, this would be your database connection)
const Database = struct {
    allocator: std.mem.Allocator,
    posts: std.ArrayList(Post),
    users: std.ArrayList(User),
    comments: std.ArrayList(Comment),
    next_post_id: u32,
    next_user_id: u32,
    next_comment_id: u32,

    pub fn init(allocator: std.mem.Allocator) Database {
        return .{
            .allocator = allocator,
            .posts = std.ArrayList(Post){},
            .users = std.ArrayList(User){},
            .comments = std.ArrayList(Comment){},
            .next_post_id = 1,
            .next_user_id = 1,
            .next_comment_id = 1,
        };
    }

    pub fn deinit(self: *Database) void {
        self.posts.deinit(self.allocator);
        self.users.deinit(self.allocator);
        self.comments.deinit(self.allocator);
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

    pub fn getPostsByAuthor(self: *Database, author_id: u32) !std.ArrayList(Post) {
        var result = std.ArrayList(Post){};
        for (self.posts.items) |post| {
            if (post.author_id == author_id) {
                try result.append(self.allocator, post);
            }
        }
        return result;
    }

    pub fn createPost(self: *Database, title: []const u8, content: []const u8, author_id: u32) !Post {
        const post = Post{
            .id = self.next_post_id,
            .title = title,
            .content = content,
            .author_id = author_id,
            .published = false,
        };
        self.next_post_id += 1;
        try self.posts.append(self.allocator, post);
        return post;
    }

    pub fn createUser(self: *Database, name: []const u8, email: []const u8) !User {
        const user = User{
            .id = self.next_user_id,
            .name = name,
            .email = email,
        };
        self.next_user_id += 1;
        try self.users.append(self.allocator, user);
        return user;
    }
};

pub fn main() !void {
    // Use ArenaAllocator for automatic cleanup (recommended for request-scoped operations)
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== 🔥 Real-World Blog API Example 🔥 ===\n\n", .{});

    // Initialize database with sample data
    var db = Database.init(allocator);
    defer db.deinit();

    const alice = try db.createUser("Alice Johnson", "alice@example.com");
    const bob = try db.createUser("Bob Smith", "bob@example.com");

    _ = try db.createPost("Getting Started with Zig", "Zig is a great language...", alice.id);
    _ = try db.createPost("GraphQL in Zig", "Building GraphQL APIs in Zig...", alice.id);
    _ = try db.createPost("Memory Management", "Understanding allocators...", bob.id);

    std.debug.print("Database initialized with {d} users and {d} posts\n\n", .{ db.users.items.len, db.posts.items.len });

    // ============================================
    // Example 1: Query a single post with author
    // ============================================
    std.debug.print("=== Example 1: Query Post with Author ===\n", .{});

    var query1 = grapzig.Query.init(allocator);
    defer query1.deinit();

    var post_field = try query1.field("post");
    _ = try post_field.arg("id", grapzig.Value.fromInt(1));
    var title = try post_field.select("title");
    title.done();
    var content = try post_field.select("content");
    content.done();
    var author = try post_field.select("author");
    var author_name = try author.select("name");
    author_name.done();
    var author_email = try author.select("email");
    author_email.done();
    author.done();
    post_field.done();

    const query1_str = try query1.build();
    defer allocator.free(query1_str);

    std.debug.print("GraphQL Query:\n{s}\n", .{query1_str});

    // Simulate execution
    if (db.findPostById(1)) |post| {
        if (db.findUserById(post.author_id)) |author_user| {
            std.debug.print("\nResult:\n", .{});
            std.debug.print("{{\n", .{});
            std.debug.print("  \"post\": {{\n", .{});
            std.debug.print("    \"title\": \"{s}\",\n", .{post.title});
            std.debug.print("    \"content\": \"{s}\",\n", .{post.content});
            std.debug.print("    \"author\": {{\n", .{});
            std.debug.print("      \"name\": \"{s}\",\n", .{author_user.name});
            std.debug.print("      \"email\": \"{s}\"\n", .{author_user.email});
            std.debug.print("    }}\n", .{});
            std.debug.print("  }}\n", .{});
            std.debug.print("}}\n\n", .{});
        }
    }

    // ============================================
    // Example 2: Query all posts by an author
    // ============================================
    std.debug.print("=== Example 2: Query Posts by Author ===\n", .{});

    var query2 = grapzig.Query.init(allocator);
    defer query2.deinit();

    var user_field = try query2.field("user");
    _ = try user_field.arg("id", grapzig.Value.fromInt(1));
    var user_name = try user_field.select("name");
    user_name.done();
    var posts_field = try user_field.select("posts");
    var post_title = try posts_field.select("title");
    post_title.done();
    var post_published = try posts_field.select("published");
    post_published.done();
    posts_field.done();
    user_field.done();

    const query2_str = try query2.build();
    defer allocator.free(query2_str);

    std.debug.print("GraphQL Query:\n{s}\n", .{query2_str});

    // Simulate execution
    if (db.findUserById(1)) |user| {
        var user_posts = try db.getPostsByAuthor(user.id);
        defer user_posts.deinit(allocator);

        std.debug.print("\nResult:\n", .{});
        std.debug.print("{{\n", .{});
        std.debug.print("  \"user\": {{\n", .{});
        std.debug.print("    \"name\": \"{s}\",\n", .{user.name});
        std.debug.print("    \"posts\": [\n", .{});
        for (user_posts.items, 0..) |post, i| {
            std.debug.print("      {{\n", .{});
            std.debug.print("        \"title\": \"{s}\",\n", .{post.title});
            std.debug.print("        \"published\": {s}\n", .{if (post.published) "true" else "false"});
            std.debug.print("      }}{s}\n", .{if (i < user_posts.items.len - 1) "," else ""});
        }
        std.debug.print("    ]\n", .{});
        std.debug.print("  }}\n", .{});
        std.debug.print("}}\n\n", .{});
    }

    // ============================================
    // Example 3: Create a new post (Mutation)
    // ============================================
    std.debug.print("=== Example 3: Create New Post (Mutation) ===\n", .{});

    var mutation = grapzig.Mutation.init(allocator);
    defer mutation.deinit();

    var create_post = try mutation.field("createPost");
    _ = try create_post.arg("title", grapzig.Value.fromString("Advanced Zig Patterns"));
    _ = try create_post.arg("content", grapzig.Value.fromString("Deep dive into Zig patterns..."));
    _ = try create_post.arg("authorId", grapzig.Value.fromInt(2));
    var new_post_id = try create_post.select("id");
    new_post_id.done();
    var new_post_title = try create_post.select("title");
    new_post_title.done();
    create_post.done();

    const mutation_str = try mutation.build();
    defer allocator.free(mutation_str);

    std.debug.print("GraphQL Mutation:\n{s}\n", .{mutation_str});

    // Execute mutation
    const new_post = try db.createPost("Advanced Zig Patterns", "Deep dive into Zig patterns...", 2);

    std.debug.print("\nResult:\n", .{});
    std.debug.print("{{\n", .{});
    std.debug.print("  \"createPost\": {{\n", .{});
    std.debug.print("    \"id\": {d},\n", .{new_post.id});
    std.debug.print("    \"title\": \"{s}\"\n", .{new_post.title});
    std.debug.print("  }}\n", .{});
    std.debug.print("}}\n\n", .{});

    // ============================================
    // Example 4: Using the Parser for incoming requests
    // ============================================
    std.debug.print("=== Example 4: Parsing Client Query ===\n", .{});

    // Simulate receiving this query from a client (e.g., HTTP request)
    const client_query =
        \\query {
        \\  post(id: 2) {
        \\    title
        \\    author {
        \\      name
        \\    }
        \\  }
        \\}
    ;

    std.debug.print("Received query from client:\n{s}\n", .{client_query});

    var parser = grapzig.Parser.init(allocator, client_query);
    const document = try parser.parse();
    // Note: In production, you'd properly clean up the document
    // For this example with ArenaAllocator, it's automatically cleaned

    std.debug.print("\n✅ Query parsed successfully!\n", .{});
    std.debug.print("Operation type: {s}\n", .{@tagName(document.definitions.items[0].operation.operation_type)});

    // In a real application, you would:
    // 1. Parse the query
    // 2. Validate it against your schema
    // 3. Execute it by calling your resolvers
    // 4. Return the result as JSON

    std.debug.print("\n=== Production Usage Pattern ===\n", .{});
    std.debug.print("1. Receive GraphQL query from HTTP request\n", .{});
    std.debug.print("2. Parse query using grapzig.Parser\n", .{});
    std.debug.print("3. Validate query using grapzig.Validator\n", .{});
    std.debug.print("4. Execute query by calling your resolvers\n", .{});
    std.debug.print("5. Build response and return as JSON\n", .{});

    std.debug.print("\n✅ Real-world example completed successfully!\n", .{});
}
