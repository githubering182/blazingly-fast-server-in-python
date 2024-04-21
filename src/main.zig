const std = @import("std");
const net = std.net;
const Connection = net.StreamServer.Connection;
const json = std.json;
const print = std.debug.print;
const alloc = std.heap.page_allocator;

const Contact = struct { email: []const u8, phone: []const u8, name: []const u8, lastname: []const u8 };

fn handle_client(client: Connection) !void {
    var buf: [1024]u8 = undefined;
    _ = try client.stream.reader().read(&buf);

    print("received {s}", .{buf});

    var contacts = [1]Contact{Contact{ .email = "some@mail.com", .name = "somename", .lastname = "somelastname", .phone = "999-999-99-99" }};

    var res_buf: [200]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&res_buf);
    var string = std.ArrayList(u8).init(fba.allocator());

    try json.stringify(contacts, .{}, string.writer());

    try client.stream.writer().writeAll("HTTP/1.1 200 OK\r\nContent-Length: 100\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\n\r\n");
    try client.stream.writer().writeAll(string.items);

    client.stream.close();
}

pub fn main() !void {
    const bind = try net.Ip4Address.parse("127.0.0.1", 3000);
    const address = net.Address{ .in = bind };

    var server = net.StreamServer.init(.{ .reuse_port = true });
    try server.listen(address);
    defer server.deinit();

    print("Listening on port: {}", .{server.listen_address.getPort()});

    while (true) {
        var client = try server.accept();
        try handle_client(client);
    }
}
