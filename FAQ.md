# Frequently Asked Questions

## Memory Management

### Q: Why do some examples show memory leaks?

**A:** This is expected and acceptable for demonstration code. The memory leaks occur because:

1. **Examples are for learning** - They demonstrate API usage, not production patterns
2. **Schema ownership** - The Schema owns ObjectType pointers but only calls `deinit()`, not `destroy()`
3. **Parser Document** - Some examples don't clean up the parsed document

**In production**, you should use `ArenaAllocator` for automatic cleanup:

```zig
pub fn handleRequest(request: []const u8) ![]const u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // Everything freed automatically!
    
    return try processGraphQL(arena.allocator(), request);
}
```

See `examples/graphql_server.zig` for the correct production pattern.

### Q: Should I worry about the memory leaks in examples?

**A:** No! The examples:
- Exit immediately after running
- Are meant for demonstration only
- Show API usage, not production code
- The OS reclaims all memory on exit

The `graphql_server.zig` example shows the **correct** production approach using ArenaAllocator.

## Usage

### Q: How do I use Grapzig in my server?

**A:** Follow these steps:

1. **Build schema once** at server startup
2. **Use ArenaAllocator** for each request
3. **Parse** incoming GraphQL query
4. **Validate** against schema
5. **Execute** by calling your resolvers
6. **Return** JSON response

See `examples/graphql_server.zig` for a complete working example.

### Q: Does Grapzig execute queries automatically?

**A:** No. Grapzig:
- ✅ Parses GraphQL queries
- ✅ Validates them against your schema
- ✅ Tells you WHAT to execute

**You** implement the execution by:
- Reading the parsed operation
- Calling your database/resolvers
- Building the JSON response

This gives you full control over how data is fetched.

### Q: Can I use Grapzig for client-side GraphQL?

**A:** Yes! Use the Query and Mutation builders:

```zig
var query = grapzig.Query.init(allocator);
defer query.deinit();

var user = try query.field("user");
_ = try user.arg("id", grapzig.Value.fromInt(1));
// ... build your query

const query_string = try query.build();
// Send query_string to your GraphQL server
```

## Compatibility

### Q: What Zig version is required?

**A:** Zig 0.15.2 or later. The library uses the new ArrayList API introduced in Zig 0.15.x.

### Q: Does Grapzig have dependencies?

**A:** No! Grapzig is a pure Zig implementation with zero external dependencies.

## Features

### Q: Does Grapzig support subscriptions?

**A:** Not yet. Current version (0.1.0) supports:
- ✅ Queries
- ✅ Mutations
- ❌ Subscriptions (planned for future release)

### Q: Does Grapzig support introspection?

**A:** Not yet. This is planned for a future release.

### Q: Can I use Grapzig with HTTP servers?

**A:** Yes! Grapzig is designed to work with any HTTP server. You:
1. Receive GraphQL query from HTTP POST
2. Parse it with Grapzig
3. Validate it
4. Execute it
5. Return JSON response

See the README for integration examples.

## Performance

### Q: Is Grapzig fast?

**A:** Yes! Grapzig:
- Uses Zig's compile-time optimizations
- Has zero runtime dependencies
- Efficient memory management with ArenaAllocator
- Minimal allocations

### Q: Should I cache parsed queries?

**A:** For production, yes! You can cache frequently-used queries to avoid re-parsing.

## Contributing

### Q: How can I contribute?

**A:** See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. We welcome:
- Bug reports
- Feature requests
- Pull requests
- Documentation improvements
- Examples

### Q: Where do I report bugs?

**A:** Open an issue on GitHub: https://github.com/yousif-wali/grapzig/issues

## Getting Help

### Q: Where can I ask questions?

**A:** 
- GitHub Issues: https://github.com/yousif-wali/grapzig/issues
- Zig Discord: #help or #libraries channels

### Q: Is there a community?

**A:** Join the Zig Discord and look for discussions about Grapzig in the #libraries channel.

---

**Have more questions?** Open an issue on GitHub!
