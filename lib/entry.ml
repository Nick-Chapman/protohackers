open Printf

let run () =
  printf "*echo_server*\n%!";
  Using_eio.serve()
