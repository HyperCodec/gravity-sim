<img src="doc/replay.gif" alt="cool replay" width="200"/>

# gravity-sim
A simulation of a bunch of particles and gravitational pull between them.

## Configuration
Configuration must be done via CLI:
```
gravity-sim

USAGE:
  gravity-sim [OPTIONS]

Performs a simple gravity simulation and renders the output to a GIF.

OPTIONS:
      --steps <VALUE>               The number of steps (frames) to simulate
      --fps <VALUE>                 The number of frames per second
      --cache <VALUE>               The folder to cache individual frames of the replay
      --output <VALUE>              The output GIF path
      --sim-width <VALUE>           The simulation/frame width
      --sim-height <VALUE>          The simulation/frame height
      --particle-count <VALUE>      The number of particles to spawn
      --particle-size <VALUE>       The particle size used in rendering
      --particle-mass-min <VALUE>   The minimum random bound for particle mass
      --particle-mass-max <VALUE>   The maximum random bound for particle mass
      --threads <VALUE>             The number of threads to use. If null, it uses the number of CPU cores
      --time-scale <VALUE>          How many times faster to make the simulation than real time (good option if you're impatient)
  -h, --help                        Show this help output.
      --color <VALUE>               When to use colors (*auto*, never, always).
```

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