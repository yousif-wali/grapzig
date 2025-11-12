const std = @import("std");
const Value = @import("value.zig").Value;
const Query = @import("query.zig").Query;

/// Mutation builder for GraphQL mutations
pub const Mutation = struct {
    allocator: std.mem.Allocator,
    operation_name: ?[]const u8 = null,
    selections: std.ArrayList(Query.Selection),
    variables: std.StringHashMap(Query.Variable),

    pub fn init(allocator: std.mem.Allocator) Mutation {
        return .{
            .allocator = allocator,
            .selections = std.ArrayList(Query.Selection){},
            .variables = std.StringHashMap(Query.Variable).init(allocator),
        };
    }

    pub fn deinit(self: *Mutation) void {
        for (self.selections.items) |*sel| {
            sel.deinit(self.allocator);
        }
        self.selections.deinit(self.allocator);
        self.variables.deinit();
    }

    pub fn name(self: *Mutation, operation_name: []const u8) *Mutation {
        self.operation_name = operation_name;
        return self;
    }

    pub fn field(self: *Mutation, field_name: []const u8) !*MutationBuilder {
        const selection = Query.Selection.init(self.allocator, field_name);
        try self.selections.append(self.allocator, selection);
        return MutationBuilder.init(self.allocator, &self.selections.items[self.selections.items.len - 1]);
    }

    pub fn build(self: *Mutation) ![]const u8 {
        var buffer = std.ArrayList(u8){};
        errdefer buffer.deinit(self.allocator);

        try buffer.appendSlice(self.allocator, "mutation");

        if (self.operation_name) |op_name| {
            try buffer.append(self.allocator, ' ');
            try buffer.appendSlice(self.allocator, op_name);
        }

        try buffer.appendSlice(self.allocator, " {\n");
        for (self.selections.items) |selection| {
            try writeSelection(self.allocator, &buffer, selection, 1);
        }
        try buffer.appendSlice(self.allocator, "}\n");

        return buffer.toOwnedSlice(self.allocator);
    }

    fn writeSelection(allocator: std.mem.Allocator, buffer: *std.ArrayList(u8), selection: Query.Selection, indent: usize) !void {
        try buffer.appendNTimes(allocator, ' ', indent * 2);
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

pub const MutationBuilder = struct {
    allocator: std.mem.Allocator,
    selection: *Query.Selection,

    pub fn init(allocator: std.mem.Allocator, selection: *Query.Selection) *MutationBuilder {
        const builder = allocator.create(MutationBuilder) catch unreachable;
        builder.* = .{
            .allocator = allocator,
            .selection = selection,
        };
        return builder;
    }

    pub fn arg(self: *MutationBuilder, name: []const u8, value: Value) !*MutationBuilder {
        try self.selection.arguments.put(name, value);
        return self;
    }

    pub fn select(self: *MutationBuilder, field_name: []const u8) !*MutationBuilder {
        const sub_selection = Query.Selection.init(self.allocator, field_name);
        try self.selection.selections.append(self.allocator, sub_selection);
        return MutationBuilder.init(
            self.allocator,
            &self.selection.selections.items[self.selection.selections.items.len - 1],
        );
    }

    pub fn done(self: *MutationBuilder) void {
        self.allocator.destroy(self);
    }
};
