const std = @import("std");

pub const Schema = @import("schema.zig").Schema;
pub const Query = @import("query.zig").Query;
pub const Mutation = @import("mutation.zig").Mutation;
pub const Field = @import("field.zig").Field;
pub const Type = @import("types.zig").Type;
pub const ObjectType = @import("types.zig").ObjectType;
pub const FieldDefinition = @import("types.zig").FieldDefinition;
pub const Value = @import("value.zig").Value;
pub const Executor = @import("executor.zig").Executor;
pub const Parser = @import("parser.zig").Parser;
pub const Validator = @import("validator.zig").Validator;
pub const Operation = @import("parser.zig").Operation;
pub const Selection = @import("parser.zig").Selection;

/// GraphQL library version
pub const version = std.SemanticVersion{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

test {
    std.testing.refAllDecls(@This());
}
