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

FROM scratch
COPY --from=zig /app/zig-out/bin/gravity-sim /gravity-sim

CMD ["/gravity-sim"]