
open UnixLabels
open Printf

exception Panic of string
let panic s = raise (Panic s)

let port = 9000

let suck : int -> file_descr -> unit =
  fun who fd ->
  let size = 100 in
  let buf = Bytes.create size in
  let rec loop() =
    let n = read fd ~buf ~pos:0 ~len:size in
    if n == 0 then () else
    printf "[%d]%s%!" who (Bytes.sub_string buf 0 n);
    let nn = write fd ~buf ~pos:0 ~len:n in
    if (n!=nn) then panic (sprintf "write: %d != %d" n nn);
    loop()
  in
  loop()

let serve() =
  let () = printf "Serve: %d\n%!" port in
  let cloexec = true in
  let domain = PF_INET in
  let kind = SOCK_STREAM in
  let fd = socket ~cloexec ~domain ~kind ~protocol:0 in
  let addr = ADDR_INET (inet_addr_loopback,port) in
  let () = bind fd ~addr in
  let () = listen fd ~max:5 in
  let rec loop tag =
    (*printf "accept...\n%!";*)
    let (fd1,_addr1) = accept fd in
    (*printf "accept... %s\n%!" (string_of_sockaddr _addr1);*)
    let _t = Thread.create (fun () -> suck tag fd1) () in
    (*printf "accept: FINISHED\n%!";*)
    loop (tag+1)
  in
  let () = loop 1 in
  ()
