const std = @import("std");
const Schema = @import("schema.zig").Schema;
const Parser = @import("parser.zig");

/// GraphQL query validator
pub const Validator = struct {
    allocator: std.mem.Allocator,
    schema: *Schema,
    errors: std.ArrayList(ValidationError),

    pub const ValidationError = struct {
        message: []const u8,
        line: ?usize = null,
        column: ?usize = null,
    };

    pub fn init(allocator: std.mem.Allocator, schema: *Schema) Validator {
        return .{
            .allocator = allocator,
            .schema = schema,
            .errors = std.ArrayList(ValidationError){},
        };
    }

    pub fn deinit(self: *Validator) void {
        self.errors.deinit(self.allocator);
    }

    pub fn validate(self: *Validator, document: *Parser.Document) !bool {
        self.errors.clearRetainingCapacity();

        for (document.definitions.items) |def| {
            switch (def) {
                .operation => |op| try self.validateOperation(op),
            }
        }

        return self.errors.items.len == 0;
    }

    fn validateOperation(self: *Validator, operation: Parser.Operation) !void {
        const root_type = switch (operation.operation_type) {
            .query => self.schema.query_type,
            .mutation => self.schema.mutation_type orelse {
                try self.addError("Schema does not support mutations");
                return;
            },
            .subscription => self.schema.subscription_type orelse {
                try self.addError("Schema does not support subscriptions");
                return;
            },
        };

        for (operation.selections.items) |selection| {
            try self.validateSelection(selection, root_type);
        }
    }

    fn validateSelection(self: *Validator, selection: Parser.Selection, parent_type: anytype) !void {
        _ = self;
        _ = selection;
        _ = parent_type;
        // Validation logic would go here
        // This is a placeholder for the full implementation
    }

    fn addError(self: *Validator, message: []const u8) !void {
        try self.errors.append(self.allocator, .{ .message = message });
    }

    pub fn getErrors(self: *Validator) []const ValidationError {
        return self.errors.items;
    }
};
