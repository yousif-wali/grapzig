const std = @import("std");

/// GraphQL type system
pub const Type = union(enum) {
    scalar: ScalarType,
    object: *ObjectType,
    interface: *InterfaceType,
    union_type: *UnionType,
    enum_type: *EnumType,
    input_object: *InputObjectType,
    list: *Type,
    non_null: *Type,

    pub const ScalarType = enum {
        int,
        float,
        string,
        boolean,
        id,
        custom,
    };

    pub fn isNullable(self: Type) bool {
        return switch (self) {
            .non_null => false,
            else => true,
        };
    }

    pub fn unwrap(self: Type) Type {
        return switch (self) {
            .non_null => |inner| inner.*,
            .list => |inner| inner.*,
            else => self,
        };
    }
};

/// Object type definition
pub const ObjectType = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    fields: std.StringHashMap(FieldDefinition),
    interfaces: std.ArrayList(*InterfaceType),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) ObjectType {
        return .{
            .name = name,
            .fields = std.StringHashMap(FieldDefinition).init(allocator),
            .interfaces = std.ArrayList(*InterfaceType){},
        };
    }

    pub fn deinit(self: *ObjectType, allocator: std.mem.Allocator) void {
        self.fields.deinit();
        self.interfaces.deinit(allocator);
    }

    pub fn addField(self: *ObjectType, name: []const u8, field: FieldDefinition) !void {
        try self.fields.put(name, field);
    }
};

/// Field definition
pub const FieldDefinition = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    type: Type,
    args: std.StringHashMap(InputValue),
    resolver: ?*const fn (parent: *anyopaque, args: *anyopaque, context: *anyopaque) anyerror!*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, name: []const u8, field_type: Type) FieldDefinition {
        return .{
            .name = name,
            .type = field_type,
            .args = std.StringHashMap(InputValue).init(allocator),
        };
    }

    pub fn deinit(self: *FieldDefinition) void {
        self.args.deinit();
    }
};

/// Input value (for arguments and input fields)
pub const InputValue = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    type: Type,
    default_value: ?Value = null,
};

/// Interface type
pub const InterfaceType = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    fields: std.StringHashMap(FieldDefinition),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) InterfaceType {
        return .{
            .name = name,
            .fields = std.StringHashMap(FieldDefinition).init(allocator),
        };
    }

    pub fn deinit(self: *InterfaceType, _: std.mem.Allocator) void {
        self.fields.deinit();
    }
};

/// Union type
pub const UnionType = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    types: std.ArrayList(*ObjectType),

    pub fn init(_: std.mem.Allocator, name: []const u8) UnionType {
        return .{
            .name = name,
            .types = std.ArrayList(*ObjectType){},
        };
    }

    pub fn deinit(self: *UnionType, allocator: std.mem.Allocator) void {
        self.types.deinit(allocator);
    }
};

/// Enum type
pub const EnumType = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    values: std.StringHashMap(EnumValue),

    pub const EnumValue = struct {
        name: []const u8,
        description: ?[]const u8 = null,
        value: i32,
    };

    pub fn init(allocator: std.mem.Allocator, name: []const u8) EnumType {
        return .{
            .name = name,
            .values = std.StringHashMap(EnumValue).init(allocator),
        };
    }

    pub fn deinit(self: *EnumType, _: std.mem.Allocator) void {
        self.values.deinit();
    }
};

/// Input object type
pub const InputObjectType = struct {
    name: []const u8,
    description: ?[]const u8 = null,
    fields: std.StringHashMap(InputValue),

    pub fn init(allocator: std.mem.Allocator, name: []const u8) InputObjectType {
        return .{
            .name = name,
            .fields = std.StringHashMap(InputValue).init(allocator),
        };
    }

    pub fn deinit(self: *InputObjectType, _: std.mem.Allocator) void {
        self.fields.deinit();
    }
};

const Value = @import("value.zig").Value;

test "Type system basics" {
    const allocator = std.testing.allocator;

    var user_type = ObjectType.init(allocator, "User");
    defer user_type.deinit(allocator);

    const name_field = FieldDefinition.init(allocator, "name", .{ .scalar = .string });
    try user_type.addField("name", name_field);

    try std.testing.expectEqualStrings("User", user_type.name);
    try std.testing.expect(user_type.fields.contains("name"));
}
