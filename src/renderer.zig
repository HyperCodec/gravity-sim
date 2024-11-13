const physics = @import("physics.zig");

pub fn CSlice(comptime T: type) type {
    return extern struct {
        base: [*]T,
        len: usize
    };
}

pub extern fn cache_frame(particle_size: u32, dir: [*:0]const u8, particles: CSlice(physics.PhysicsParticle), bounds: physics.EnvironmentBounds)  callconv(.C) void;
pub extern fn build_gif(frame_count: usize, framerate: u32, frames_dir: [*:0]const u8, output_dir: [*:0]const u8) callconv(.C) void;
pub extern fn create_dir_all(path: [*:0]const u8) callconv(.C) bool;