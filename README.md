# protohackers

[Server programming challenge](https://protohackers.com)

Using Ocaml.


## Cloud Hosting instructions


### Install [opam](https://opam.ocaml.org/doc/Install.html)
```
sudo add-apt-repository ppa:avsm/ppa
sudo apt update
sudo apt install opam
```

### Initialize opam and install dune
```
opam init
eval $(opam env)
opam install dune
```

### Clone this repo and build the echo server (using opam/dune)
```
git clone https://github.com/Nick-Chapman/protohackers.git
cd protohackers
opam exec -- dune build
```

### Run echo server, serving my default port,  6516
```
opam exec -- dune exec -- echo
```
