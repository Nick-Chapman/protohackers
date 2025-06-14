
let sprintf = Printf.sprintf
module U = Unix
open Lwt_unix

exception Panic of string
let panic s = raise (Panic s)

let port = 6516
let addr = U.inet_addr_any (* NOT: loopback *)

let suck : string -> file_descr -> unit Lwt.t =
  fun who fd ->
  let size = 10000 in
  let buf = Bytes.create size in
  let rec loop() =
    let%lwt n = read fd buf 0 size in
    let%lwt () = Lwt_io.printf "[%s] Read: %s%!" who (Bytes.sub_string buf 0 n) in
    if n == 0 then Lwt.return_unit else (
      let%lwt nn = write fd buf 0 n in
      let%lwt () = Lwt_io.printf "[%s] Echoed #%d bytes\n%!" who nn in
      if (n!=nn) then panic (sprintf "write: %d != %d" n nn);
      loop()
    )
  in
  let%lwt () = loop() in
  let%lwt () = close fd in
  Lwt_io.printf "[%s] Closed\n%!" who

let string_of_sockaddr = function
  | ADDR_UNIX _ -> "ADDR_UNIX"
  | ADDR_INET (ia,p) -> sprintf "%s:%d" (U.string_of_inet_addr ia) p

let worker : file_descr -> string -> unit  Lwt.t =
  fun fd name ->
  let%lwt () = Lwt_io.printf "[%s] Worker Started\n%!" name in
  let rec loop i =
    let who = sprintf "%s.%d" name i in
    let%lwt (fd1,addr1) = accept fd in
    let%lwt () = Lwt_io.printf "[%s] Accepted: %s\n%!" who (string_of_sockaddr addr1) in
    let%lwt () = suck who fd1 in
    loop (i+1)
  in
  loop 0

let spawn_workers : (string -> unit Lwt.t) -> string list -> unit Lwt.t =
  fun f names ->
  Lwt.join (List.map f names)

let serve() =
  Lwt_main.run @@
  let%lwt () = Lwt_io.printf "(using Lwt) Serve: %s:%d\n%!" (U.string_of_inet_addr addr) port in
  let cloexec = true in
  let domain = PF_INET in
  let kind = SOCK_STREAM in
  let fd = socket ~cloexec domain kind 0 in
  let addr = ADDR_INET (addr,port) in
  let%lwt () = bind fd addr in
  let () = listen fd 0 in
  spawn_workers (worker fd) ["a";"b";"c";"d";"e"]

