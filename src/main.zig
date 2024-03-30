const std = @import("std");
const net = std.net;
const print = std.debug.print;

pub fn main() !void {
    const bind = try net.Ip4Address.parse("127.0.0.1", 3000);
    const address = net.Address{ .in = bind };

    var server = net.StreamServer.init(.{ .reuse_port = true });
    try server.listen(address);
    defer server.deinit();

    print("Listening on port: {}", .{server.listen_address.getPort()});

    while (true) {
        var client = try server.accept();

        var buf: [1024]u8 = undefined;
        _ = try client.stream.reader().read(&buf);

        print("received {s}", .{buf});

        try client.stream.writer().writeAll("HTTP/1.1 200\r\n\r\nsome");

        client.stream.close();
    }
}
