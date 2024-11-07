const physics = @import("physics.zig");

pub fn CSlice(comptime T: type) type {
    return extern struct {
        base: [*]T,
        len: usize
    };
}

pub const std = @import("std");

pub extern fn cache_frame(dir: [*:0]const u8, particles: CSlice(physics.PhysicsParticle), bounds: physics.EnvironmentBounds)  callconv(.C) void;
pub extern fn build_gif(framerate: u32, frames_dir: [*:0]const u8, output_dir: [*:0]const u8) callconv(.C) void;