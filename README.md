# gravity-sim
A simulation of a bunch of particles and gravitational pull between them.

## Building from scratch
If you get any errors about libraries not found, you probably just need to install `libc, libwebp, and libgcc`. All of these assume you have done `git clone https://github.com/HyperCodec/gravity-sim && cd gravity-sim` (or something of the sort).

### Linux
On Linux, it's as simple as:

```sh
cd renderer
cargo build --release
cd ..
zig build
```

### Windows
Kind of broken, same thing as linux but move `renderer/target/release/renderer.dll` to `zig-out` after the `cargo build --release` step. If that doesn't work you can `docker build .`.

### Mac
Not sure (I don't own a mac). It's probably like Linux but if that doesn't work there's always `docker build .`.

## Configuration
I was too lazy to make a CLI, so constants in `main.zig` and `physics.zig` are the only config rn. Might use `zig-cli` or something later if I'm not too lazy.