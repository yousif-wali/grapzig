const std = @import("std");
const Value = @import("value.zig").Value;

/// GraphQL query parser
pub const Parser = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    pos: usize = 0,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Parser {
        return .{
            .allocator = allocator,
            .source = source,
        };
    }

    pub fn parse(self: *Parser) !Document {
        var definitions = std.ArrayList(Definition){};
        errdefer definitions.deinit(self.allocator);

        while (self.pos < self.source.len) {
            self.skipWhitespace();
            if (self.pos >= self.source.len) break;

            const def = try self.parseDefinition();
            try definitions.append(self.allocator, def);
        }

        return Document{ .definitions = definitions, .allocator = self.allocator };
    }

    fn parseDefinition(self: *Parser) !Definition {
        const keyword = try self.parseKeyword();

        if (std.mem.eql(u8, keyword, "query")) {
            return Definition{ .operation = try self.parseOperation(.query) };
        } else if (std.mem.eql(u8, keyword, "mutation")) {
            return Definition{ .operation = try self.parseOperation(.mutation) };
        } else if (std.mem.eql(u8, keyword, "subscription")) {
            return Definition{ .operation = try self.parseOperation(.subscription) };
        }

        return error.UnknownDefinition;
    }

    fn parseOperation(self: *Parser, op_type: OperationType) !Operation {
        self.skipWhitespace();

        var op_name: ?[]const u8 = null;
        if (self.peek() != '{') {
            op_name = try self.parseName();
        }

        self.skipWhitespace();
        const selections = try self.parseSelectionSet();

        return Operation{
            .operation_type = op_type,
            .name = op_name,
            .selections = selections,
        };
    }

    fn parseSelectionSet(self: *Parser) anyerror!std.ArrayList(Selection) {
        try self.expect('{');
        self.skipWhitespace();

        var selections = std.ArrayList(Selection){};
        errdefer selections.deinit(self.allocator);

        while (self.peek() != '}') {
            const selection = try self.parseSelection();
            try selections.append(self.allocator, selection);
            self.skipWhitespace();
        }

        try self.expect('}');
        return selections;
    }

    fn parseSelection(self: *Parser) !Selection {
        const field_name = try self.parseName();
        self.skipWhitespace();

        var alias: ?[]const u8 = null;
        var actual_name = field_name;

        if (self.peek() == ':') {
            _ = try self.next();
            self.skipWhitespace();
            alias = field_name;
            actual_name = try self.parseName();
            self.skipWhitespace();
        }

        var arguments = std.StringHashMap(Value).init(self.allocator);
        if (self.peek() == '(') {
            arguments = try self.parseArguments();
            self.skipWhitespace();
        }

        var sub_selections = std.ArrayList(Selection){};
        if (self.peek() == '{') {
            sub_selections = try self.parseSelectionSet();
        }

        return Selection{
            .name = actual_name,
            .alias = alias,
            .arguments = arguments,
            .selections = sub_selections,
        };
    }

    fn parseArguments(self: *Parser) !std.StringHashMap(Value) {
        try self.expect('(');
        self.skipWhitespace();

        var args = std.StringHashMap(Value).init(self.allocator);
        errdefer args.deinit();

        while (self.peek() != ')') {
            const arg_name = try self.parseName();
            self.skipWhitespace();
            try self.expect(':');
            self.skipWhitespace();
            const value = try self.parseValue();
            try args.put(arg_name, value);

            self.skipWhitespace();
            if (self.peek() == ',') {
                _ = try self.next();
                self.skipWhitespace();
            }
        }

        try self.expect(')');
        return args;
    }

    fn parseValue(self: *Parser) anyerror!Value {
        self.skipWhitespace();
        const ch = self.peek();

        if (ch == '"') {
            return Value.fromString(try self.parseString());
        } else if (ch == '[') {
            return try self.parseList();
        } else if (ch == '{') {
            return try self.parseObject();
        } else if (std.ascii.isDigit(ch) or ch == '-') {
            return try self.parseNumber();
        } else if (ch == 't' or ch == 'f') {
            return Value.fromBool(try self.parseBoolean());
        } else if (ch == 'n') {
            try self.expectWord("null");
            return Value.fromNull();
        }

        return error.InvalidValue;
    }

    fn parseString(self: *Parser) ![]const u8 {
        try self.expect('"');
        const start = self.pos;
        while (self.peek() != '"') {
            _ = try self.next();
        }
        const end = self.pos;
        try self.expect('"');
        return self.source[start..end];
    }

    fn parseNumber(self: *Parser) !Value {
        const start = self.pos;
        if (self.peek() == '-') _ = try self.next();

        while (std.ascii.isDigit(self.peek())) {
            _ = try self.next();
        }

        if (self.peek() == '.') {
            _ = try self.next();
            while (std.ascii.isDigit(self.peek())) {
                _ = try self.next();
            }
            const num_str = self.source[start..self.pos];
            const value = try std.fmt.parseFloat(f64, num_str);
            return Value.fromFloat(value);
        }

        const num_str = self.source[start..self.pos];
        const value = try std.fmt.parseInt(i64, num_str, 10);
        return Value.fromInt(value);
    }

    fn parseBoolean(self: *Parser) !bool {
        if (self.peek() == 't') {
            try self.expectWord("true");
            return true;
        } else {
            try self.expectWord("false");
            return false;
        }
    }

    fn parseList(self: *Parser) !Value {
        try self.expect('[');
        self.skipWhitespace();

        var list = std.ArrayList(Value){};
        errdefer list.deinit(self.allocator);

        while (self.peek() != ']') {
            const value = try self.parseValue();
            try list.append(self.allocator, value);
            self.skipWhitespace();
            if (self.peek() == ',') {
                _ = try self.next();
                self.skipWhitespace();
            }
        }

        try self.expect(']');
        return Value{ .list = list };
    }

    fn parseObject(self: *Parser) !Value {
        try self.expect('{');
        self.skipWhitespace();

        var obj = std.StringHashMap(Value).init(self.allocator);
        errdefer obj.deinit();

        while (self.peek() != '}') {
            const key = try self.parseName();
            self.skipWhitespace();
            try self.expect(':');
            self.skipWhitespace();
            const value = try self.parseValue();
            try obj.put(key, value);

            self.skipWhitespace();
            if (self.peek() == ',') {
                _ = try self.next();
                self.skipWhitespace();
            }
        }

        try self.expect('}');
        return Value{ .object = obj };
    }

    fn parseName(self: *Parser) ![]const u8 {
        const start = self.pos;
        while (std.ascii.isAlphanumeric(self.peek()) or self.peek() == '_') {
            _ = try self.next();
        }
        if (start == self.pos) return error.ExpectedName;
        return self.source[start..self.pos];
    }

    fn parseKeyword(self: *Parser) ![]const u8 {
        return self.parseName();
    }

    fn skipWhitespace(self: *Parser) void {
        while (self.pos < self.source.len and std.ascii.isWhitespace(self.source[self.pos])) {
            self.pos += 1;
        }
    }

    fn peek(self: *Parser) u8 {
        if (self.pos >= self.source.len) return 0;
        return self.source[self.pos];
    }

    fn next(self: *Parser) !u8 {
        if (self.pos >= self.source.len) return error.UnexpectedEOF;
        const ch = self.source[self.pos];
        self.pos += 1;
        return ch;
    }

    fn expect(self: *Parser, expected: u8) !void {
        const ch = try self.next();
        if (ch != expected) return error.UnexpectedCharacter;
    }

    fn expectWord(self: *Parser, word: []const u8) !void {
        for (word) |ch| {
            const actual = try self.next();
            if (actual != ch) return error.UnexpectedWord;
        }
    }
};

pub const Document = struct {
    definitions: std.ArrayList(Definition),
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Document) void {
        self.definitions.deinit(self.allocator);
    }
};

pub const Definition = union(enum) {
    operation: Operation,
};

pub const Operation = struct {
    operation_type: OperationType,
    name: ?[]const u8,
    selections: std.ArrayList(Selection),
};

pub const OperationType = enum {
    query,
    mutation,
    subscription,
};

pub const Selection = struct {
    name: []const u8,
    alias: ?[]const u8,
    arguments: std.StringHashMap(Value),
    selections: std.ArrayList(Selection),
};
