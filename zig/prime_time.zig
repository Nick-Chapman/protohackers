
const std = @import("std");
const net = std.net;
const print = std.debug.print;
const json = std.json;

var gpa = std.heap.DebugAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    print("Zig prime_time\n",.{});
    const portnum = 6516;
    const loopback : net.Ip4Address = try net.Ip4Address.parse("0.0.0.0",portnum);
    const me : net.Address = net.Address{.in = loopback};
    var server : net.Server = try me.listen(.{.reuse_address = true});
    print("listening on: {any}\n",.{server.listen_address});
    while (true) {
        //print("waiting to accept connection...\n",.{});
        const conn : net.Server.Connection = try server.accept();
        _ = try std.Thread.spawn(.{}, handle, .{conn});
        //try handle(conn);
    }
}

fn handle(conn: net.Server.Connection) !void {
    //const addr = conn.address;
    //print("{any}: connection accepted\n",.{addr});
    const stream = conn.stream;
    const writer = stream.writer();
    while(true) {
        const buffer_size = 1024;
        var buf : [buffer_size]u8 = undefined;
        const mes = stream.reader().readUntilDelimiter(&buf,'\n') catch break;
        if (std.mem.eql(u8, mes, "")) {
            print("EMP: '{s}' -- not responding\n",.{mes});
            continue;
        }
        if (parse_and_test(mes)) |b| {
            try writer.writeAll("{\"method\":\"isPrime\",\"prime\":");
            try writer.writeAll(if (b) "true" else "false");
            try writer.writeAll("}\n");
        } else {
            //print("message:{s} -- FAILED PARSE\n",.{mes});
            try writer.writeAll("BAD\n");
            break;
        }
    }
    stream.close();
    //print("{any}: connection closed\n",.{addr});
}

fn parse_and_test(query: []const u8) ?bool {
    const request = parseI(query) orelse {
        if (matchF(query)) {
            print("FLO: '{s}'\n",.{query});
            return false;
        }
        print("MAL: '{s}' -- {any}\n",.{query,query});
        return null;
    };
    const num = request.number;
    if (!std.mem.eql(u8, request.method, "isPrime")) {
        print("WRO: '{s}'\n",.{query});
        return null;
    }
    if (matchS(query)) {
        print("STR: '{s}'\n",.{query});
        return null;
    }
    const b = is_prime(num);
    //print("--> HAPPY NUMBER. TEST ITS PRIMENESS {d} --> {any}\n",.{num,b});
    return b;
}

const RequestI = struct {
    method: []u8,
    number: i400,
};
fn parseI(query: []const u8) ?RequestI {
    const parsed = json.parseFromSlice(RequestI,allocator,query,.{
        .allocate = .alloc_always,
        .ignore_unknown_fields = true,
    }) catch {
        return null;
    };
    return parsed.value;
}

const RequestS = struct {
    method: []u8,
    number: []u8,
};
fn matchS(query: []const u8) bool {
    _ = json.parseFromSlice(RequestS,allocator,query,.{
        .allocate = .alloc_always,
        .ignore_unknown_fields = true,
    }) catch {
        return false;
    };
    return true;
}

const RequestF = struct {
    method: []u8,
    number: f128,
};
fn matchF(query: []const u8) bool {
    _ = json.parseFromSlice(RequestF,allocator,query,.{
        .allocate = .alloc_always,
        .ignore_unknown_fields = true,
    }) catch {
        return false;
    };
    return true;
}

fn is_prime(i: i400) bool {
    if (i < 2) return false;
    const big : u400 = @intCast(i);
    if (i == 2) return true;
    if (big % 2 == 0) return false;
    const n : u32 = @intCast(big);
    const root_of_n = std.math.sqrt(n) + 1;
    for (2..root_of_n) |d| {
        if (n % d == 0) return false;
    }
    return true;
}
