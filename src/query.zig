const std = @import("std");
const Value = @import("value.zig").Value;

/// Query builder for constructing GraphQL queries
pub const Query = struct {
    allocator: std.mem.Allocator,
    operation_name: ?[]const u8 = null,
    selections: std.ArrayList(Selection),
    variables: std.StringHashMap(Variable),

    pub const Selection = struct {
        name: []const u8,
        alias: ?[]const u8 = null,
        arguments: std.StringHashMap(Value),
        selections: std.ArrayList(Selection),

        pub fn init(allocator: std.mem.Allocator, name: []const u8) Selection {
            return .{
                .name = name,
                .arguments = std.StringHashMap(Value).init(allocator),
                .selections = std.ArrayList(Selection){},
            };
        }

        pub fn deinit(self: *Selection, allocator: std.mem.Allocator) void {
            var iter = self.arguments.iterator();
            while (iter.next()) |entry| {
                var val = entry.value_ptr.*;
                val.deinit(allocator);
            }
            self.arguments.deinit();

            for (self.selections.items) |*sel| {
                sel.deinit(allocator);
            }
            self.selections.deinit(allocator);
        }
    };

    pub const Variable = struct {
        name: []const u8,
        type_name: []const u8,
        default_value: ?Value = null,
    };

    pub fn init(allocator: std.mem.Allocator) Query {
        return .{
            .allocator = allocator,
            .selections = std.ArrayList(Selection){},
            .variables = std.StringHashMap(Variable).init(allocator),
        };
    }

    pub fn deinit(self: *Query) void {
        for (self.selections.items) |*sel| {
            sel.deinit(self.allocator);
        }
        self.selections.deinit(self.allocator);
        self.variables.deinit();
    }

    pub fn setName(self: *Query, operation_name: []const u8) *Query {
        self.operation_name = operation_name;
        return self;
    }

    pub fn field(self: *Query, field_name: []const u8) !*SelectionBuilder {
        const selection = Selection.init(self.allocator, field_name);
        try self.selections.append(self.allocator, selection);
        return SelectionBuilder.init(self.allocator, &self.selections.items[self.selections.items.len - 1]);
    }

    pub fn variable(self: *Query, var_name: []const u8, type_name: []const u8) !*Query {
        try self.variables.put(var_name, .{
            .name = var_name,
            .type_name = type_name,
        });
        return self;
    }

    pub fn build(self: *Query) ![]const u8 {
        var buffer = std.ArrayList(u8){};
        errdefer buffer.deinit(self.allocator);

        try buffer.appendSlice(self.allocator, "query");

        if (self.operation_name) |op_name| {
            try buffer.append(self.allocator, ' ');
            try buffer.appendSlice(self.allocator, op_name);
        }

        if (self.variables.count() > 0) {
            try buffer.append(self.allocator, '(');
            var iter = self.variables.iterator();
            var first = true;
            while (iter.next()) |entry| {
                if (!first) try buffer.appendSlice(self.allocator, ", ");
                first = false;
                try buffer.append(self.allocator, '$');
                try buffer.appendSlice(self.allocator, entry.value_ptr.name);
                try buffer.appendSlice(self.allocator, ": ");
                try buffer.appendSlice(self.allocator, entry.value_ptr.type_name);
            }
            try buffer.append(self.allocator, ')');
        }

        try buffer.appendSlice(self.allocator, " {\n");
        for (self.selections.items) |selection| {
            try writeSelection(self.allocator, &buffer, selection, 1);
        }
        try buffer.appendSlice(self.allocator, "}\n");

        return buffer.toOwnedSlice(self.allocator);
    }

    fn writeSelection(allocator: std.mem.Allocator, buffer: *std.ArrayList(u8), selection: Selection, indent: usize) !void {
        try buffer.appendNTimes(allocator, ' ', indent * 2);

        if (selection.alias) |alias_name| {
            try buffer.appendSlice(allocator, alias_name);
            try buffer.appendSlice(allocator, ": ");
        }

        try buffer.appendSlice(allocator, selection.name);

        if (selection.arguments.count() > 0) {
            try buffer.append(allocator, '(');
            var iter = selection.arguments.iterator();
            var first = true;
            while (iter.next()) |entry| {
                if (!first) try buffer.appendSlice(allocator, ", ");
                first = false;
                try buffer.appendSlice(allocator, entry.key_ptr.*);
                try buffer.appendSlice(allocator, ": ");
                try entry.value_ptr.toJson(buffer.writer(allocator));
            }
            try buffer.append(allocator, ')');
        }

        if (selection.selections.items.len > 0) {
            try buffer.appendSlice(allocator, " {\n");
            for (selection.selections.items) |sub_selection| {
                try writeSelection(allocator, buffer, sub_selection, indent + 1);
            }
            try buffer.appendNTimes(allocator, ' ', indent * 2);
            try buffer.appendSlice(allocator, "}\n");
        } else {
            try buffer.append(allocator, '\n');
        }
    }
};

/// Builder for individual field selections
pub const SelectionBuilder = struct {
    allocator: std.mem.Allocator,
    selection: *Query.Selection,

    pub fn init(allocator: std.mem.Allocator, selection: *Query.Selection) *SelectionBuilder {
        const builder = allocator.create(SelectionBuilder) catch unreachable;
        builder.* = .{
            .allocator = allocator,
            .selection = selection,
        };
        return builder;
    }

    pub fn alias(self: *SelectionBuilder, alias_name: []const u8) *SelectionBuilder {
        self.selection.alias = alias_name;
        return self;
    }

    pub fn arg(self: *SelectionBuilder, name: []const u8, value: Value) !*SelectionBuilder {
        try self.selection.arguments.put(name, value);
        return self;
    }

    pub fn select(self: *SelectionBuilder, field_name: []const u8) !*SelectionBuilder {
        const sub_selection = Query.Selection.init(self.allocator, field_name);
        try self.selection.selections.append(self.allocator, sub_selection);
        return SelectionBuilder.init(
            self.allocator,
            &self.selection.selections.items[self.selection.selections.items.len - 1],
        );
    }

    pub fn done(self: *SelectionBuilder) void {
        self.allocator.destroy(self);
    }
};

test "Query builder basic" {
    const allocator = std.testing.allocator;

    var query = Query.init(allocator);
    defer query.deinit();

    var user_field = try query.field("user");
    _ = try user_field.arg("id", Value.fromInt(1));
    var name_field = try user_field.select("name");
    name_field.done();
    user_field.done();

    const result = try query.build();
    defer allocator.free(result);

    try std.testing.expect(std.mem.indexOf(u8, result, "user(id: 1)") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "name") != null);
}
