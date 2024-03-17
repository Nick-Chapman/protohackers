
open UnixLabels
open Printf

exception Panic of string
let panic s = raise (Panic s)

let port = 6516
let addr = inet_addr_any (* NOT: loopback *)

let suck : string -> file_descr -> unit =
  fun who fd ->
  let size = 10000 in
  let buf = Bytes.create size in
  let rec loop() =
    let n = read fd ~buf ~pos:0 ~len:size in
    (*printf "[%s] Read: %s%!" who (Bytes.sub_string buf 0 n);*)
    if n == 0 then () else (
      let nn = write fd ~buf ~pos:0 ~len:n in
      (*printf "[%s] Echoed #%d bytes\n%!" who nn;*)
      if (n!=nn) then panic (sprintf "write: %d != %d" n nn);
      loop()
    )
  in
  loop();
  close fd;
  printf "[%s] Closed\n%!" who;
  ()

let string_of_sockaddr = function
  | ADDR_UNIX _ -> "ADDR_UNIX"
  | ADDR_INET (ia,p) -> sprintf "%s:%d" (string_of_inet_addr ia) p

let worker fd name =
  printf "[%s] Worker Started\n%!" name;
  let rec loop i =
    let who = sprintf "%s.%d" name i in
    let (fd1,addr1) = accept fd in
    printf "[%s] Accepted: %s\n%!" who (string_of_sockaddr addr1);
    suck who fd1;
    loop (i+1)
  in
  loop 0

let rec spawn_workers f = function
  | [] -> ()
  | [last] -> f last
  | w::more ->
     let _t = Thread.create f w in
     spawn_workers f more

let serve() =
  let () = printf "Serve: %s:%d\n%!" (string_of_inet_addr addr) port in
  let cloexec = true in
  let domain = PF_INET in
  let kind = SOCK_STREAM in
  let fd = socket ~cloexec ~domain ~kind ~protocol:0 in
  let addr = ADDR_INET (addr,port) in
  let () = bind fd ~addr in
  let () = listen fd ~max:0 in
  spawn_workers (worker fd) ["a";"b";"c";"d";"e"];
  ()
