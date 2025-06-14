const std = @import("std");
const net = std.net;
const print = std.debug.print;

pub fn main() !void {
    print("My zig echo server.\n",.{});
    const portnum = 6516;
    // TODO: why two steps here?
    const loopback : net.Ip4Address = try net.Ip4Address.parse("127.0.0.1",portnum);
    const me : net.Address = net.Address{.in = loopback};
    var server : net.Server = try me.listen(.{.reuse_address = true});
    // TODO: support concurrent connections!
    // TODO: am I handling binary?
    print("listening on: {any}\n",.{server.listen_address});
    while (true) {
        print("waiting to accept connection...\n",.{});
        const conn : net.Server.Connection = try server.accept();
        const addr = conn.address;
        print("{any}: connection accepted\n",.{addr});
        const stream = conn.stream;
        const writer = stream.writer();
        while(true) {
            // code using use low level read interface, and a silly small buffer
            var buf : [16]u8 = undefined;
            const n : usize = try stream.read(&buf);
            if (n == 0) break;
            print("{any}: received {d} bytes\n",.{addr,n});
            //for (0..n) |i| writer.writeByte(buf[i]) catch {};
            writer.writeAll(buf[0..n]) catch {};
        }
        stream.close();
        print("{any}: connection closed\n",.{addr});
    }
}
