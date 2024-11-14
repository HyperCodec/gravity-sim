const std = @import("std");
const physics = @import("physics.zig");
const Vec2f = @import("vector.zig").Vec2f;
const renderer = @import("renderer.zig");
const cli = @import("zig-cli");

var config = struct {
    step_count: usize = 300,
    fps: u32 = 30,
    cache_dir: []const u8 = "./replay_cache",
    output_dir: []const u8 = "./replay.gif",
    sim_size_x: f32 = 800,
    sim_size_y: f32 = 800,
    particle_count: usize = 1000,
    particle_size: u32 = 5,
    particle_mass_min: f32 = 1.0e3,
    particle_mass_max: f32 = 5.0e11,
    thread_count: ?usize = null,
    time_scale: f32 = 5,
}{};

var alloc: std.mem.Allocator = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    alloc = arena.allocator();

    var r = try cli.AppRunner.init(alloc);

    const app = cli.App {
        .command = .{
            .name = "gravity-sim",
            .description = .{
                .one_line = "Performs a simple gravity simulation and renders the output to a GIF.",
            },
            .options = &.{
                .{
                    .long_name = "steps",
                    .help = "The number of steps (frames) to simulate",
                    .value_ref = r.mkRef(&config.step_count),
                },
                .{
                    .long_name = "fps",
                    .help = "The number of frames per second",
                    .value_ref = r.mkRef(&config.fps),
                },
                .{
                    .long_name = "cache",
                    .help = "The folder to cache individual frames of the replay",
                    .value_ref = r.mkRef(&config.cache_dir),
                },
                .{
                    .long_name = "output",
                    .help = "The output GIF path",
                    .value_ref = r.mkRef(&config.output_dir),
                },
                .{
                    .long_name = "sim-width",
                    .help = "The simulation/frame width",
                    .value_ref = r.mkRef(&config.sim_size_x),
                },
                .{
                    .long_name = "sim-height",
                    .help = "The simulation/frame height",
                    .value_ref = r.mkRef(&config.sim_size_y),
                },
                .{
                    .long_name = "particle-count",
                    .help = "The number of particles to spawn",
                    .value_ref = r.mkRef(&config.particle_count),
                },
                .{
                    .long_name = "particle-size",
                    .help = "The particle size used in rendering",
                    .value_ref = r.mkRef(&config.particle_size),
                },
                .{
                    .long_name = "particle-mass-min",
                    .help = "The minimum random bound for particle mass",
                    .value_ref = r.mkRef(&config.particle_mass_min),
                },
                .{
                    .long_name = "particle-mass-max",
                    .help = "The maximum random bound for particle mass",
                    .value_ref = r.mkRef(&config.particle_mass_max),
                },
                .{
                    .long_name = "threads",
                    .help = "The number of threads to use. If null, it uses the number of CPU cores",
                    .value_ref = r.mkRef(&config.thread_count),
                },
                .{
                    .long_name = "time-scale",
                    .help = "How many times faster to make the simulation than real time (good option if you're impatient)",
                    .value_ref = r.mkRef(&config.time_scale),
                },
            },
            .target = .{
                .action = .{ .exec = run_simulation },
            }
        }
    };

    return r.run(&app);
}

fn run_simulation() !void {
    const DT = 1.0 / @as(f32, @floatFromInt(config.fps));

    if(config.thread_count == null) {
        config.thread_count = try std.Thread.getCpuCount();
    }

    var sim = try physics.PhysicsEnvironment.init(
        alloc,
        .{
            .size = .{ .x = config.sim_size_x, .y = config.sim_size_y },
            .top_left = Vec2f.ZERO,
        },
        config.particle_count,
        config.particle_mass_min,
        config.particle_mass_max,
        config.thread_count.?,
        std.crypto.random
    );
    defer sim.deinit();

    // std.debug.print("dt: {}\n", .{DT});
    _ = renderer.create_dir_all(config.cache_dir.ptr);

    const opts = std.Progress.Options {
        .estimated_total_items = config.step_count,
        .root_name = "gravity simulation",
    };
    var pb = std.Progress.start(opts);

    for(0..config.step_count) |i| {
        // std.debug.print("{}\n", .{sim.particles.items[0]});
        try sim.performStep(DT * config.time_scale);

        const filename = try std.fmt.allocPrint(alloc, "frame{}.png", .{i});
        const path = try std.fs.path.joinZ(alloc, &[_][]const u8{config.cache_dir, filename});

        renderer.cache_frame(config.particle_size, path.ptr, .{ .base = sim.particles.items.ptr, .len = sim.particles.items.len}, sim.bounds);
        
        pb.completeOne();
    }

    renderer.build_gif(config.step_count, config.fps, config.cache_dir.ptr, config.output_dir.ptr);

    pb.end();
}
