const std = @import("std");
const Type = @import("types.zig").Type;
const Value = @import("value.zig").Value;

/// Field builder for creating GraphQL fields with fluent API
pub const Field = struct {
    allocator: std.mem.Allocator,
    name: []const u8,
    field_type: Type,
    description: ?[]const u8 = null,
    args: std.StringHashMap(Argument),
    resolver: ?ResolverFn = null,

    pub const ResolverFn = *const fn (
        parent: Value,
        args: std.StringHashMap(Value),
        context: *anyopaque,
    ) anyerror!Value;

    pub const Argument = struct {
        name: []const u8,
        arg_type: Type,
        description: ?[]const u8 = null,
        default_value: ?Value = null,
    };

    pub fn init(allocator: std.mem.Allocator, name: []const u8, field_type: Type) Field {
        return .{
            .allocator = allocator,
            .name = name,
            .field_type = field_type,
            .args = std.StringHashMap(Argument).init(allocator),
        };
    }

    pub fn deinit(self: *Field) void {
        self.args.deinit();
    }

    pub fn describe(self: *Field, description: []const u8) *Field {
        self.description = description;
        return self;
    }

    pub fn arg(self: *Field, name: []const u8, arg_type: Type) !*Field {
        try self.args.put(name, .{
            .name = name,
            .arg_type = arg_type,
        });
        return self;
    }

    pub fn argWithDefault(self: *Field, name: []const u8, arg_type: Type, default: Value) !*Field {
        try self.args.put(name, .{
            .name = name,
            .arg_type = arg_type,
            .default_value = default,
        });
        return self;
    }

    pub fn resolve(self: *Field, resolver_fn: ResolverFn) *Field {
        self.resolver = resolver_fn;
        return self;
    }
};

test "Field builder" {
    const allocator = std.testing.allocator;

    var field = Field.init(allocator, "user", .{ .scalar = .string });
    defer field.deinit();

    _ = field.describe("Get user by ID");
    _ = try field.arg("id", .{ .scalar = .id });

    try std.testing.expectEqualStrings("user", field.name);
    try std.testing.expect(field.description != null);
    try std.testing.expect(field.args.contains("id"));
}
