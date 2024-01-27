FROM ocaml/opam:alpine as builder

RUN sudo apk add openssl-dev gmp-dev

WORKDIR /src
ADD --chown=opam . .

RUN opam install -y --deps-only . --locked
RUN opam config exec -- dune build ./_build/install/default/bin/cddns

FROM alpine

RUN apk add openssl

WORKDIR /
COPY --from=builder /src/_build/install/default/bin/cddns /usr/local/bin

ENTRYPOINT ["/usr/local/bin/cddns", "--help"]
