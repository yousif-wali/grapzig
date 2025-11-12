# Contributing to Grapzig

Thank you for your interest in contributing to Grapzig! This document provides guidelines and instructions for contributing.

## 🎯 Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build something great together.

## 🚀 Getting Started

1. **Fetch the repository**
   ```bash
   zig fetch --save "git+https://github.com/yousif-wali/grapzig#master"
   ```

   Or clone it directly:
   ```bash
   git clone https://github.com/yousif-wali/grapzig.git
   cd grapzig
   ```

2. **Build the project**
   ```bash
   zig build
   ```

3. **Run tests**
   ```bash
   zig build test
   ```

4. **Run examples**
   ```bash
   zig build examples
   zig build run-basic
   ```

## 📝 Development Guidelines

### Code Style

- Follow Zig's standard formatting (use `zig fmt`)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Use Zig idioms and best practices

### Testing

- Write tests for new features
- Ensure all tests pass before submitting PR
- Add integration tests for complex features
- Test edge cases and error conditions

### Documentation

- Document all public APIs
- Include usage examples
- Update README.md for new features
- Add inline comments for complex code

## 🔧 Project Structure

```
grapzig/
├── src/
│   ├── grapzig.zig      # Main library entry point
│   ├── types.zig        # GraphQL type system
│   ├── value.zig        # Value representation
│   ├── schema.zig       # Schema definition
│   ├── query.zig        # Query builder
│   ├── mutation.zig     # Mutation builder
│   ├── parser.zig       # Query parser
│   ├── validator.zig    # Schema validator
│   └── executor.zig     # Query executor
├── examples/            # Example programs
├── build.zig           # Build configuration
└── README.md           # Documentation
```

## 🎨 Adding New Features

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Implement your feature**
   - Write the code
   - Add tests
   - Update documentation

3. **Test thoroughly**
   ```bash
   zig build test
   zig build examples
   ```

4. **Format code**
   ```bash
   zig fmt src/
   zig fmt examples/
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## 🐛 Reporting Bugs

When reporting bugs, please include:

- Zig version (`zig version`)
- Operating system
- Minimal reproduction code
- Expected vs actual behavior
- Error messages or stack traces

## 💡 Feature Requests

We welcome feature requests! Please:

- Check if the feature already exists
- Describe the use case
- Provide examples of how it would work
- Explain why it would be valuable

## 📋 Pull Request Process

1. **Update documentation** for any changed functionality
2. **Add tests** for new features
3. **Ensure all tests pass** (`zig build test`)
4. **Format code** (`zig fmt`)
5. **Update CHANGELOG.md** with your changes
6. **Request review** from maintainers

### PR Title Format

Use conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test additions or changes
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `chore:` Build process or tooling changes

Examples:
- `feat: add subscription support`
- `fix: correct parser error handling`
- `docs: update query builder examples`

## 🎯 Priority Areas

We're especially interested in contributions for:

- [ ] Query executor implementation
- [ ] Subscription support
- [ ] Introspection system
- [ ] Custom scalar types
- [ ] Directive support
- [ ] HTTP server integration
- [ ] Performance optimizations
- [ ] More examples and documentation

## 🧪 Testing Guidelines

### Unit Tests

```zig
test "feature description" {
    const allocator = std.testing.allocator;
    
    // Setup
    var query = grapzig.Query.init(allocator);
    defer query.deinit();
    
    // Test
    var field = try query.field("test");
    field.done();
    
    // Assert
    try std.testing.expect(query.selections.items.len == 1);
}
```

### Integration Tests

Add integration tests in `examples/` that demonstrate real-world usage.

## 📚 Documentation Standards

### Function Documentation

```zig
/// Creates a new GraphQL query builder.
/// 
/// The caller owns the returned Query and must call deinit() when done.
/// 
/// Example:
/// ```zig
/// var query = Query.init(allocator);
/// defer query.deinit();
/// ```
pub fn init(allocator: std.mem.Allocator) Query {
    // ...
}
```

### Type Documentation

```zig
/// Represents a GraphQL value.
/// 
/// Values can be scalars (int, float, string, boolean, null),
/// or complex types (list, object).
pub const Value = union(enum) {
    // ...
};
```

## 🔍 Code Review Process

All submissions require review. We look for:

- ✅ Code quality and style
- ✅ Test coverage
- ✅ Documentation completeness
- ✅ Performance considerations
- ✅ Error handling
- ✅ Memory safety

## 🎓 Learning Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [GraphQL Specification](https://spec.graphql.org/)
- [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)

## 💬 Getting Help

- Open an issue for questions
- Join discussions in GitHub Discussions
- Check existing issues and PRs

## 🙏 Thank You!

Your contributions make Grapzig better for everyone. We appreciate your time and effort!

---

Happy coding! ⚡
