FROM rust:1.82.0 AS builder

WORKDIR /profile-peek
COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN apt-get update && apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM node:22.9.0-alpine AS frontend

WORKDIR /profile-peek

COPY ./frontend ./frontend
COPY ./shared ./shared

RUN npm install --prefix frontend
RUN npm run build --prefix frontend

FROM alpine:3.20.3

COPY --from=builder /profile-peek/target/x86_64-unknown-linux-musl/release/profile-peek /profile-peek/profile-peek
COPY --from=frontend /profile-peek/frontend/dist /www/public/

ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8000
ENV ROCKET_ENV=production

CMD ["/profile-peek/profile-peek"]
EXPOSE 8000
