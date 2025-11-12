const std = @import("std");
const Schema = @import("schema.zig").Schema;
const Value = @import("value.zig").Value;
const Parser = @import("parser.zig");

/// GraphQL query executor
pub const Executor = struct {
    allocator: std.mem.Allocator,
    schema: *Schema,
    context: ?*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, schema: *Schema) Executor {
        return .{
            .allocator = allocator,
            .schema = schema,
        };
    }

    pub fn setContext(self: *Executor, context: *anyopaque) void {
        self.context = context;
    }

    pub fn execute(self: *Executor, document: *Parser.Document) !Value {
        var result = std.StringHashMap(Value).init(self.allocator);
        errdefer result.deinit();

        for (document.definitions.items) |def| {
            switch (def) {
                .operation => |op| {
                    const op_result = try self.executeOperation(op);
                    const key = if (op.name) |n| n else "data";
                    try result.put(key, op_result);
                },
            }
        }

        return Value{ .object = result };
    }

    fn executeOperation(self: *Executor, operation: Parser.Operation) !Value {
        const root_type = switch (operation.operation_type) {
            .query => self.schema.query_type,
            .mutation => self.schema.mutation_type orelse return error.NoMutationType,
            .subscription => self.schema.subscription_type orelse return error.NoSubscriptionType,
        };

        var result = std.StringHashMap(Value).init(self.allocator);
        errdefer result.deinit();

        for (operation.selections.items) |selection| {
            const field_result = try self.executeSelection(selection, root_type, Value.fromNull());
            const key = selection.alias orelse selection.name;
            try result.put(key, field_result);
        }

        return Value{ .object = result };
    }

    fn executeSelection(self: *Executor, selection: Parser.Selection, parent_type: anytype, parent_value: Value) !Value {
        _ = parent_type;
        _ = parent_value;

        // Placeholder implementation
        // In a real implementation, this would:
        // 1. Look up the field in the parent type
        // 2. Call the field's resolver
        // 3. Execute sub-selections on the result

        if (selection.selections.items.len > 0) {
            var obj = std.StringHashMap(Value).init(self.allocator);
            for (selection.selections.items) |sub_sel| {
                try obj.put(sub_sel.name, Value.fromString("placeholder"));
            }
            return Value{ .object = obj };
        }

        return Value.fromString("placeholder");
    }
};
