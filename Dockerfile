FROM rust:latest AS rust
WORKDIR /app

ADD ./renderer .

RUN cargo build --release

FROM ziglings/ziglang:latest AS zig
WORKDIR /app

COPY --from=rust /app/target/release/librenderer.so ./renderer/target/release/librenderer.so
COPY build.zig build.zig.zon ./
ADD ./src ./src

RUN zig build

FROM alpine:latest
WORKDIR /app

COPY --from=zig /app/zig-out/bin/gravity-sim ./gravity-sim
COPY --from=rust /app/target/release/librenderer.so ./renderer/target/release/librenderer.so
RUN apk add --no-cache libc6-compat libwebp libgcc
CMD ["/app/gravity-sim"]