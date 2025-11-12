const std = @import("std");

/// GraphQL value representation
pub const Value = union(enum) {
    null_value,
    int: i64,
    float: f64,
    string: []const u8,
    boolean: bool,
    enum_value: []const u8,
    list: std.ArrayList(Value),
    object: std.StringHashMap(Value),

    pub fn deinit(self: *Value, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .list => |*list| {
                for (list.items) |*item| {
                    item.deinit(allocator);
                }
                list.deinit(allocator);
            },
            .object => |*obj| {
                var iter = obj.iterator();
                while (iter.next()) |entry| {
                    var val = entry.value_ptr.*;
                    val.deinit(allocator);
                }
                obj.deinit();
            },
            else => {},
        }
    }

    pub fn fromInt(value: i64) Value {
        return .{ .int = value };
    }

    pub fn fromFloat(value: f64) Value {
        return .{ .float = value };
    }

    pub fn fromString(value: []const u8) Value {
        return .{ .string = value };
    }

    pub fn fromBool(value: bool) Value {
        return .{ .boolean = value };
    }

    pub fn fromNull() Value {
        return .null_value;
    }

    pub fn toJson(self: Value, writer: anytype) !void {
        switch (self) {
            .null_value => try writer.writeAll("null"),
            .int => |v| try writer.print("{d}", .{v}),
            .float => |v| try writer.print("{d}", .{v}),
            .string => |v| {
                try writer.writeByte('"');
                try writer.writeAll(v);
                try writer.writeByte('"');
            },
            .boolean => |v| try writer.writeAll(if (v) "true" else "false"),
            .enum_value => |v| {
                try writer.writeByte('"');
                try writer.writeAll(v);
                try writer.writeByte('"');
            },
            .list => |list| {
                try writer.writeByte('[');
                for (list.items, 0..) |item, i| {
                    if (i > 0) try writer.writeByte(',');
                    try item.toJson(writer);
                }
                try writer.writeByte(']');
            },
            .object => |obj| {
                try writer.writeByte('{');
                var iter = obj.iterator();
                var first = true;
                while (iter.next()) |entry| {
                    if (!first) try writer.writeByte(',');
                    first = false;
                    try writer.writeByte('"');
                    try writer.writeAll(entry.key_ptr.*);
                    try writer.writeByte('"');
                    try writer.writeByte(':');
                    try entry.value_ptr.toJson(writer);
                }
                try writer.writeByte('}');
            },
        }
    }
};

test "Value creation and JSON serialization" {
    const allocator = std.testing.allocator;

    // Test scalar values
    const int_val = Value.fromInt(42);
    const str_val = Value.fromString("hello");
    const bool_val = Value.fromBool(true);
    const null_val = Value.fromNull();

    var buffer = std.ArrayList(u8){};
    defer buffer.deinit(allocator);

    try int_val.toJson(buffer.writer(allocator));
    try std.testing.expectEqualStrings("42", buffer.items);

    buffer.clearRetainingCapacity();
    try str_val.toJson(buffer.writer(allocator));
    try std.testing.expectEqualStrings("\"hello\"", buffer.items);

    buffer.clearRetainingCapacity();
    try bool_val.toJson(buffer.writer(allocator));
    try std.testing.expectEqualStrings("true", buffer.items);

    buffer.clearRetainingCapacity();
    try null_val.toJson(buffer.writer(allocator));
    try std.testing.expectEqualStrings("null", buffer.items);
}
