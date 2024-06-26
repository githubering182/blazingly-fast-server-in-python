const std = @import("std");
const net = std.net;
const Connection = net.StreamServer.Connection;
const json = std.json;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const split = std.mem.split;

const Status = enum(u16) {
    Ok,
    NotFound,
    Created,
    pub fn to_val(self: Status) []const u8 {
        return switch (self) {
            Status.Ok => "200",
            Status.Created => "201",
            Status.NotFound => "404",
        };
    }
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Contact = struct {
    id: []const u8,
    phone: []const u8,
    name: []const u8,
    lastname: []const u8,
    patronymic: []const u8,
    username: []const u8,
    address: []const u8,
    birthdate: []const u8,
};

const Contacts = ArrayList(Contact).init(allocator);

const buf_len: u16 = 1024;

fn handle_client(client: Connection) !void {
    var request = std.ArrayList(u8).init(allocator);
    defer request.deinit();

    var buf: [buf_len]u8 = undefined;
    while (true) {
        var read = try client.stream.reader().read(&buf);
        print("rl: {d}", .{read});

        print("read: {s}\n", .{buf[0..read]});

        _ = try request.appendSlice(buf[0..read]);
        if (read < buf_len) break;
    }

    print("ln: {d}\n", .{request.items.len});

    try client.stream.writer().writeAll("HTTP/1.1 200 OK\r\n\r\n");

    client.stream.close();
}

pub fn main() !void {
    const bind = try net.Ip4Address.parse("127.0.0.1", 3000);
    const address = net.Address{ .in = bind };

    var server = net.StreamServer.init(.{ .reuse_port = true });

    try server.listen(address);

    defer {
        server.deinit();
        Contacts.deinit();
        _ = gpa.deinit();
    }

    print("Listening on port: {}\n", .{server.listen_address.getPort()});

    while (true) {
        var client = try server.accept();
        try handle_client(client);
    }
}
