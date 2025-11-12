# 🚀 Grapzig - GraphQL for Zig

A modern, type-safe GraphQL library for Zig that makes building GraphQL APIs simple and enjoyable.

[![Zig](https://img.shields.io/badge/zig-0.15.2+-orange.svg)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- **🎯 Type-Safe**: Leverage Zig's compile-time type system for GraphQL schemas
- **🔧 Fluent API**: Intuitive builder pattern for queries, mutations, and schemas
- **⚡ Zero Dependencies**: Pure Zig implementation with no external dependencies
- **📦 Modular Design**: Use only what you need - query builder, schema, parser, executor
- **🎨 Clean Syntax**: Idiomatic Zig code that feels natural
- **🧪 Well Tested**: Comprehensive test coverage
- **📚 Production Ready**: Complete examples and documentation

## 🚀 Quick Start

```bash
# See it in action!
git clone https://github.com/yousif-wali/grapzig
cd grapzig

# Run the complete GraphQL server example
zig build run-graphql-server

# This shows EXACTLY how Grapzig processes GraphQL queries!
```

---

## 📦 Installation

Add grapzig as a dependency in your `build.zig.zon`:

```bash
zig fetch --save "git+https://github.com/yousif-wali/grapzig#master"
```

Then in your `build.zig`, add the grapzig module as a dependency to your program:

```zig
const grapzig = b.dependency("grapzig", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("grapzig", grapzig.module("grapzig"));
```

> **Note:** The library tracks Zig master (0.15.2+).

---

## 🎯 What is Grapzig?

**Grapzig is a GraphQL engine for building GraphQL servers in Zig.**

Think of it as the GraphQL equivalent of:
- `graphql-js` for Node.js
- `juniper` for Rust
- `graphene` for Python

### What Grapzig Provides

- ✅ **Parse** GraphQL queries from HTTP requests
- ✅ **Validate** queries against your schema
- ✅ **Define** your GraphQL schema
- ✅ **Build** queries/mutations programmatically

### What You Implement

- 🔧 HTTP server (using `std.http` or your framework)
- 🔧 Resolvers (functions that fetch data)
- 🔧 Database layer (PostgreSQL, MongoDB, etc.)
- 🔧 JSON response building

---

## 🚀 Quick Start

### Building a Query

```zig
const std = @import("std");
const grapzig = @import("grapzig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a query
    var query = grapzig.Query.init(allocator);
    defer query.deinit();

    // Build: { user(id: 1) { name email } }
    var user_field = try query.field("user");
    _ = try user_field.arg("id", grapzig.Value.fromInt(1));
    var name = try user_field.select("name");
    name.done();
    var email = try user_field.select("email");
    email.done();
    user_field.done();

    const query_string = try query.build();
    defer allocator.free(query_string);

    std.debug.print("{s}\n", .{query_string});
}
```

**Output:**
```graphql
query {
  user(id: 1) {
    name
    email
  }
}
```

### Creating a Mutation

```zig
var mutation = grapzig.Mutation.init(allocator);
defer mutation.deinit();

var create = try mutation.field("createUser");
_ = try create.arg("name", grapzig.Value.fromString("Alice"));
_ = try create.arg("email", grapzig.Value.fromString("alice@example.com"));
var id = try create.select("id");
id.done();
create.done();

const mutation_str = try mutation.build();
defer allocator.free(mutation_str);
```

---

## 🏗️ Real-World Usage

### Architecture Overview

```
Client Request (HTTP POST)
    ↓
Parse JSON body to get query string
    ↓
grapzig.Parser.parse(query_string)
    ↓
grapzig.Validator.validate(document, schema)
    ↓
Execute query (call your resolvers)
    ↓
Build JSON response
    ↓
Send HTTP response to client
```

### Complete Example: Blog API

```zig
const std = @import("std");
const grapzig = @import("grapzig");

// 1. Define your data models
const User = struct {
    id: u32,
    name: []const u8,
    email: []const u8,
};

const Post = struct {
    id: u32,
    title: []const u8,
    author_id: u32,
};

// 2. Build your GraphQL schema (once at startup)
pub fn buildSchema(allocator: std.mem.Allocator) !grapzig.Schema {
    const user_type = try allocator.create(grapzig.ObjectType);
    user_type.* = grapzig.ObjectType.init(allocator, "User");
    try user_type.addField("id", grapzig.FieldDefinition.init(
        allocator, "id", .{ .scalar = .id }
    ));
    try user_type.addField("name", grapzig.FieldDefinition.init(
        allocator, "name", .{ .scalar = .string }
    ));

    const query_type = try allocator.create(grapzig.ObjectType);
    query_type.* = grapzig.ObjectType.init(allocator, "Query");
    try query_type.addField("user", grapzig.FieldDefinition.init(
        allocator, "user", .{ .object = user_type }
    ));

    return grapzig.Schema.init(allocator, query_type);
}

// 3. Handle incoming GraphQL requests
pub fn handleGraphQLRequest(
    allocator: std.mem.Allocator,
    query_string: []const u8,
    schema: *grapzig.Schema,
) ![]const u8 {
    // Parse the query
    var parser = grapzig.Parser.init(allocator, query_string);
    var document = try parser.parse();
    defer document.deinit();

    // Validate the query
    var validator = grapzig.Validator.init(allocator, schema);
    defer validator.deinit();
    
    if (!try validator.validate(&document)) {
        return try buildErrorResponse(allocator, validator.getErrors());
    }

    // Execute the query (call your resolvers)
    return try executeQuery(allocator, &document);
}
```

### Memory Management Best Practice

Use `ArenaAllocator` for request-scoped allocations:

```zig
pub fn handleRequest(request: []const u8) ![]const u8 {
    // Create arena for this request - everything auto-freed at end
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // Frees everything at once
    
    const allocator = arena.allocator();
    return try processGraphQLQuery(allocator, request);
}
```

> **Note on Examples**: Some examples may show memory leak warnings from `GeneralPurposeAllocator`. This is expected and acceptable for demonstration code. In production, use `ArenaAllocator` for automatic cleanup (see `graphql_server.zig` and `schema.zig` example).

---

## 📚 API Reference

### Core Types

#### `grapzig.Query`
Build GraphQL queries programmatically.

```zig
var query = grapzig.Query.init(allocator);
defer query.deinit();

var field = try query.field("fieldName");
_ = try field.arg("argName", grapzig.Value.fromInt(123));
var subField = try field.select("subField");
subField.done();
field.done();

const query_str = try query.build();
defer allocator.free(query_str);
```

#### `grapzig.Mutation`
Build GraphQL mutations.

```zig
var mutation = grapzig.Mutation.init(allocator);
defer mutation.deinit();

var create = try mutation.field("createItem");
_ = try create.arg("name", grapzig.Value.fromString("Item"));
create.done();

const mutation_str = try mutation.build();
defer allocator.free(mutation_str);
```

#### `grapzig.Schema`
Define your GraphQL schema.

```zig
const user_type = try allocator.create(grapzig.ObjectType);
user_type.* = grapzig.ObjectType.init(allocator, "User");
try user_type.addField("id", grapzig.FieldDefinition.init(...));

const query_type = try allocator.create(grapzig.ObjectType);
query_type.* = grapzig.ObjectType.init(allocator, "Query");

var schema = grapzig.Schema.init(allocator, query_type);
defer schema.deinit();
```

#### `grapzig.Parser`
Parse GraphQL query strings.

```zig
var parser = grapzig.Parser.init(allocator, query_string);
var document = try parser.parse();
defer document.deinit();
```

#### `grapzig.Validator`
Validate queries against a schema.

```zig
var validator = grapzig.Validator.init(allocator, &schema);
defer validator.deinit();

const is_valid = try validator.validate(&document);
if (!is_valid) {
    for (validator.getErrors()) |err| {
        std.debug.print("Error: {s}\n", .{err.message});
    }
}
```

#### `grapzig.Value`
Represent GraphQL values.

```zig
const int_val = grapzig.Value.fromInt(42);
const str_val = grapzig.Value.fromString("hello");
const bool_val = grapzig.Value.fromBool(true);
const null_val = grapzig.Value.fromNull();

// Serialize to JSON
var buffer = std.ArrayList(u8){};
defer buffer.deinit(allocator);
try value.toJson(buffer.writer(allocator));
```

---

## 🎓 Examples

The library includes comprehensive examples:

```bash
# Basic query and mutation building
zig build run-basic

# Schema definition
zig build run-schema

# Mutation examples
zig build run-mutations

# Server with parser and validator
zig build run-server

# 🔥 COMPLETE GraphQL SERVER (Shows how Grapzig ACTUALLY works!)
zig build run-graphql-server

# Query/mutation building examples
zig build run-real-world-blog
```

### 🔥 Example: Complete GraphQL Server

**See `examples/graphql_server.zig`** - This is THE example that shows how Grapzig actually processes GraphQL queries on the server!

**What it demonstrates:**
1. ✅ Client sends GraphQL query string
2. ✅ **Grapzig parses** the query
3. ✅ **Grapzig validates** against schema
4. ✅ **You execute** by calling your resolvers (database operations)
5. ✅ **Grapzig helped** you understand WHAT to execute
6. ✅ Return JSON response to client

This example shows the **complete flow** of how mutations actually call your database functions!

---

## 🔧 Production Usage

### Step-by-Step Implementation

1. **Define Your Schema** (once at startup)
   ```zig
   var schema = try buildSchema(allocator);
   defer schema.deinit();
   ```

2. **Handle HTTP Requests** (per request)
   ```zig
   pub fn handleRequest(query: []const u8) ![]const u8 {
       var arena = std.heap.ArenaAllocator.init(allocator);
       defer arena.deinit();
       
       return try processGraphQL(arena.allocator(), query, &schema);
   }
   ```

3. **Parse & Validate**
   ```zig
   var parser = grapzig.Parser.init(allocator, query);
   var document = try parser.parse();
   defer document.deinit();
   
   var validator = grapzig.Validator.init(allocator, &schema);
   defer validator.deinit();
   const is_valid = try validator.validate(&document);
   ```

4. **Execute** (call your resolvers)
   ```zig
   const result = try executeQuery(allocator, &document, db);
   ```

### Integration with HTTP Server

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Build schema once at startup
    var schema = try buildSchema(allocator);
    defer schema.deinit();
    
    // Start HTTP server
    const address = try std.net.Address.parseIp("0.0.0.0", 8080);
    var server = try std.net.Server.init(.{ .reuse_address = true });
    defer server.deinit();
    try server.listen(address);
    
    std.debug.print("GraphQL server running on http://localhost:8080\n", .{});
    
    while (true) {
        const connection = try server.accept();
        try handleConnection(allocator, connection, &schema);
    }
}
```

---

## 💡 Best Practices

### 1. Memory Management
- Use `ArenaAllocator` for request-scoped allocations
- Build schema once at startup, not per request
- Always call `deinit()` on resources

### 2. Schema Design
- Initialize schema once at server startup
- Reuse the same schema for all requests
- Keep schema in server state

### 3. Error Handling
```zig
var parser = grapzig.Parser.init(allocator, query);
var document = parser.parse() catch |err| {
    return buildErrorResponse("Invalid query syntax");
};
defer document.deinit();
```

### 4. Performance
- Reuse schema across requests
- Use arena allocators for requests
- Pool database connections
- Cache frequently used queries

---

## 🧪 Testing

Run the test suite:

```bash
zig build test
```

Build all examples:

```bash
zig build examples
```

---

## 📖 Documentation

- **Examples**: See `examples/` directory for working code
- **API Reference**: See sections above
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by the GraphQL specification
- Built with ❤️ for the Zig community

---

## 📞 Contact

- GitHub: [@yousif-wali](https://github.com/yousif-wali)
- Issues: [GitHub Issues](https://github.com/yousif-wali/grapzig/issues)

---

Made with ⚡ by the Zig community

🔥🔥🔥🔥
