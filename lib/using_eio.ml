
let sprintf = Printf.sprintf

let port = 6516

let worker : Eio.Net.listening_socket -> string -> unit =
  fun listening_socket name ->
  Eio.traceln "[%s] Worker Started" name;
  let rec loop i =
    let who = sprintf "%s.%d" name i in
    Eio.Switch.run @@ fun sw ->
    let (stream,addr) = Eio.Net.accept ~sw listening_socket in
    Eio.traceln "[%s] Accepted: %a" who Eio.Net.Sockaddr.pp addr;
    Eio.Flow.copy stream stream;
    Eio.traceln "[%s] Finished: %a" who Eio.Net.Sockaddr.pp addr;
    loop (i+1)
  in
  loop 0

let serve() =
  Eio_main.run @@ fun env ->
  let addr = `Tcp (Eio.Net.Ipaddr.V4.any,port) in
  Eio.traceln "(using Eio) Serving: %a" Eio.Net.Sockaddr.pp addr;
  Eio.Switch.run @@ fun sw ->
  let listening_socket = Eio.Net.listen ~backlog:0 ~reuse_port:true ~sw env#net addr in
  Eio.Fiber.List.iter (worker listening_socket) ["a";"b";"c";"d";"e"]
