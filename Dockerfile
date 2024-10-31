FROM rust:1.82.0 AS builder

WORKDIR /csportal-player-finder
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN apt-get update && apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM node:22.9.0-alpine AS frontend

WORKDIR /csportal-player-finder

COPY ./frontend ./
RUN npm install
RUN npm run build

FROM alpine:3.20.3

COPY --from=builder /csportal-player-finder/target/x86_64-unknown-linux-musl/release/csportal-player-finder /csportal-player-finder/csportal-player-finder
COPY --from=frontend /csportal-player-finder/dist /www/public/

ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8000
ENV ROCKET_ENV=production

CMD ["/csportal-player-finder/csportal-player-finder"]
EXPOSE 8000
