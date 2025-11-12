const std = @import("std");
const Type = @import("types.zig").Type;
const ObjectType = @import("types.zig").ObjectType;
const FieldDefinition = @import("types.zig").FieldDefinition;

/// GraphQL Schema
pub const Schema = struct {
    allocator: std.mem.Allocator,
    query_type: *ObjectType,
    mutation_type: ?*ObjectType = null,
    subscription_type: ?*ObjectType = null,
    types: std.StringHashMap(*ObjectType),

    pub fn init(allocator: std.mem.Allocator, query_type: *ObjectType) Schema {
        return .{
            .allocator = allocator,
            .query_type = query_type,
            .types = std.StringHashMap(*ObjectType).init(allocator),
        };
    }

    pub fn deinit(self: *Schema) void {
        var iter = self.types.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.*.deinit(self.allocator);
            self.allocator.destroy(entry.value_ptr.*);
        }
        self.types.deinit();
    }

    pub fn addType(self: *Schema, type_obj: *ObjectType) !void {
        try self.types.put(type_obj.name, type_obj);
    }

    pub fn getType(self: *Schema, name: []const u8) ?*ObjectType {
        return self.types.get(name);
    }

    pub fn setMutationType(self: *Schema, mutation_type: *ObjectType) void {
        self.mutation_type = mutation_type;
    }

    pub fn setSubscriptionType(self: *Schema, subscription_type: *ObjectType) void {
        self.subscription_type = subscription_type;
    }

    /// Builder pattern for creating schemas
    pub const Builder = struct {
        allocator: std.mem.Allocator,
        query_type: ?*ObjectType = null,
        mutation_type: ?*ObjectType = null,
        subscription_type: ?*ObjectType = null,
        types: std.ArrayList(*ObjectType),

        pub fn init(allocator: std.mem.Allocator) Builder {
            return .{
                .allocator = allocator,
                .types = std.ArrayList(*ObjectType){},
            };
        }

        pub fn deinit(self: *Builder) void {
            self.types.deinit(self.allocator);
        }

        pub fn query(self: *Builder, query_type: *ObjectType) *Builder {
            self.query_type = query_type;
            return self;
        }

        pub fn mutation(self: *Builder, mutation_type: *ObjectType) *Builder {
            self.mutation_type = mutation_type;
            return self;
        }

        pub fn subscription(self: *Builder, subscription_type: *ObjectType) *Builder {
            self.subscription_type = subscription_type;
            return self;
        }

        pub fn addType(self: *Builder, type_obj: *ObjectType) !*Builder {
            try self.types.append(self.allocator, type_obj);
            return self;
        }

        pub fn build(self: *Builder) !Schema {
            if (self.query_type == null) {
                return error.QueryTypeRequired;
            }

            var schema = Schema.init(self.allocator, self.query_type.?);
            schema.mutation_type = self.mutation_type;
            schema.subscription_type = self.subscription_type;

            for (self.types.items) |type_obj| {
                try schema.addType(type_obj);
            }

            return schema;
        }
    };
};

test "Schema creation" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const query_type = try allocator.create(ObjectType);
    query_type.* = ObjectType.init(allocator, "Query");

    var schema = Schema.init(allocator, query_type);
    defer schema.deinit();

    try std.testing.expectEqualStrings("Query", schema.query_type.name);
}

test "Schema builder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const query_type = try allocator.create(ObjectType);
    query_type.* = ObjectType.init(allocator, "Query");

    var builder = Schema.Builder.init(allocator);
    defer builder.deinit();

    var schema = try builder.query(query_type).build();
    defer schema.deinit();

    try std.testing.expectEqualStrings("Query", schema.query_type.name);
}
