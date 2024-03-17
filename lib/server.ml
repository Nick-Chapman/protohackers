
open UnixLabels
open Printf

exception Panic of string
let panic s = raise (Panic s)

let port = 6516
let addr = inet_addr_any (* NOT: loopback *)

let suck : int -> file_descr -> unit =
  fun who fd ->
  let size = 10000 in
  let buf = Bytes.create size in
  let rec loop() =
    let n = read fd ~buf ~pos:0 ~len:size in
    if n == 0 then () else (
      let nn = write fd ~buf ~pos:0 ~len:n in
      (*printf "[%d] Echoed #%d bytes\n%!" who nn;*)
      if (n!=nn) then panic (sprintf "write: %d != %d" n nn);
      loop()
    )
  in
  loop();
  close fd;
  printf "[%d] Closed\n%!" who;
  ()

let string_of_sockaddr = function
  | ADDR_UNIX _ -> "ADDR_UNIX"
  | ADDR_INET (ia,p) -> sprintf "%s:%d" (string_of_inet_addr ia) p

let serve() =
  let () = printf "Serve: %s:%d\n%!" (string_of_inet_addr addr) port in
  let cloexec = true in
  let domain = PF_INET in
  let kind = SOCK_STREAM in
  let fd = socket ~cloexec ~domain ~kind ~protocol:0 in
  let addr = ADDR_INET (addr,port) in
  let () = bind fd ~addr in
  let () = listen fd ~max:0 in
  let rec loop who =
    let (fd1,addr1) = accept fd in
    printf "[%d] Accepted: %s\n%!" who (string_of_sockaddr addr1);
    let _t = Thread.create (fun () -> suck who fd1) () in
    loop (who+1)
  in
  loop 1
