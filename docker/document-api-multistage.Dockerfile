FROM rust as builder
WORKDIR app
COPY LICENSE Cargo.toml ./
COPY core-lib core-lib
COPY keyring-api keyring-api
COPY document-api document-api
RUN cargo build --release

FROM debian:bullseye-slim

RUN apt-get update \
&& echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
&& apt-get --no-install-recommends install -y -q ca-certificates gnupg2 libssl1.1 libc6

# trust the DAPS certificate
COPY docker/daps_cachain.crt /usr/local/share/ca-certificates/daps_cachain.crt
RUN update-ca-certificates

RUN mkdir /server
WORKDIR /server

COPY --from=builder /app/target/release/document-api .
COPY docker/entrypoint.sh .

ENTRYPOINT ["/server/entrypoint.sh"]
CMD ["/server/document-api"]