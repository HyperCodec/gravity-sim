const std = @import("std");
const physics = @import("physics.zig");
const Vec2f = @import("vector.zig").Vec2f;
const renderer = @import("renderer.zig");

const STEP_COUNT = 900;
const FPS = 30;
const CACHE_DIR = "./replay_cache";
const OUTPUT_DIR = "./replay.gif";

const SIZE = Vec2f { .x = 800, .y = 800 };
const PARTICLE_COUNT = 1000;
const TIME_SCALE = 5;

const PARTICLE_SIZE = 5; // does not affect simulation, only rendering.
const PARTICLE_MASS_MIN = 1.0e3;
const PARTICLE_MASS_MAX = 5.0e11;

const DT = 1.0 / @as(f32, FPS);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    const cpuCores = try std.Thread.getCpuCount();

    var sim = try physics.PhysicsEnvironment.init(
        alloc,
        .{
            .size = SIZE,
            .top_left = Vec2f.ZERO,
        },
        PARTICLE_COUNT,
        PARTICLE_MASS_MIN,
        PARTICLE_MASS_MAX,
        cpuCores,
        std.crypto.random
    );
    defer sim.deinit();

    // std.debug.print("dt: {}\n", .{DT});
    _ = renderer.create_dir_all(CACHE_DIR);

    const opts = std.Progress.Options {
        .estimated_total_items = STEP_COUNT,
        .root_name = "gravity simulation",
    };
    var pb = std.Progress.start(opts);

    for(0..STEP_COUNT) |i| {
        // std.debug.print("{}\n", .{sim.particles.items[0]});
        try sim.performStep(DT * TIME_SCALE);

        const filename = try std.fmt.allocPrint(alloc, "frame{}.png", .{i});
        const path = try std.fs.path.joinZ(alloc, &[_][]const u8{CACHE_DIR, filename});

        renderer.cache_frame(PARTICLE_SIZE, path.ptr, .{ .base = sim.particles.items.ptr, .len = sim.particles.items.len}, sim.bounds);
        
        pb.completeOne();
    }

    renderer.build_gif(STEP_COUNT, FPS, CACHE_DIR, OUTPUT_DIR);

    pb.end();
}
