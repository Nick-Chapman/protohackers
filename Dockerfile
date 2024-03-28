# syntax=docker/dockerfile:1
FROM ubuntu
WORKDIR /app
RUN apt update
RUN apt install -y gcc make opam
RUN opam init -y
RUN opam install dune
COPY dune-project .
COPY lib lib
COPY bin bin
RUN opam exec -- dune build
ENTRYPOINT _build/install/default/bin/echo 2>&1 > /tmp/echo.log
EXPOSE 6516
