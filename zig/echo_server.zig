const std = @import("std");
const net = std.net;
const print = std.debug.print;

const buffer_size = 1024;

pub fn main() !void {
    print("My zig echo server; buffer_size={d}\n",.{buffer_size});
    const portnum = 6516;
    const loopback : net.Ip4Address = try net.Ip4Address.parse("0.0.0.0",portnum);
    const me : net.Address = net.Address{.in = loopback};
    var server : net.Server = try me.listen(.{.reuse_address = true});
    print("listening on: {any}\n",.{server.listen_address});
    while (true) {
        print("waiting to accept connection...\n",.{});
        const conn : net.Server.Connection = try server.accept();
        _ = try std.Thread.spawn(.{}, handle, .{conn});
    }
}

fn handle(conn: net.Server.Connection) void {
    const addr = conn.address;
    print("{any}: connection accepted\n",.{addr});
    const stream = conn.stream;
    const writer = stream.writer();
    while(true) {
        var buf : [buffer_size]u8 = undefined;
        const n : usize = stream.read(&buf) catch 0;
        if (n == 0) break;
        print("{any}: received {d} bytes\n",.{addr,n});
        writer.writeAll(buf[0..n]) catch {};
    }
    stream.close();
    print("{any}: connection closed\n",.{addr});
}
