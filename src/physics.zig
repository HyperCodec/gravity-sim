const std = @import("std");
const Vec2f = @import("vector.zig").Vec2f;

pub const G = 6.67e-11;

pub const PhysicsParticle = extern struct {
    const Self = @This();
    
    mass: f32,
    velocity: Vec2f,
    position: Vec2f,

    pub fn addForce(self: *Self, force: Vec2f) void {
        const accel = force.divOne(self.mass);
        self.velocity = self.velocity.add(accel);
    }

    pub fn updatePosition(self: *Self, dt: f32) void {
        const movement = self.velocity.multOne(dt);
        self.position = self.position.add(movement);
    }

    pub fn gravityStrength(self: Self, other: Self) f32 {
        const distSquared = self.position.sub(other.position).magSquared();
        return self.mass * other.mass * G / distSquared;
    }

    pub fn pullTowardOther(self: *Self, other: Self, dt: f32) void {
        const strength = self.gravityStrength(other) * dt;
        const direction = self.position.sub(other.position).norm();

        // std.debug.print("strength: {}\n", .{strength});

        self.addForce(direction.multOne(strength));
    }
};

pub const PhysicsEnvironment = struct {
    const Self = @This();

    bounds: EnvironmentBounds,
    particles: std.ArrayList(PhysicsParticle),
    threadCount: usize,
    allocator: std.mem.Allocator,

    pub fn init(
        alloc: std.mem.Allocator,
        bounds: EnvironmentBounds,
        particle_count: usize,
        particle_mass_min: f32,
        particle_mass_max: f32,
        threadCount: usize,
        rng: std.Random,
    ) !Self {
        var particles = std.ArrayList(PhysicsParticle).init(alloc);
        
        for(0..particle_count) |_| {
            const pos = (Vec2f { .x = rng.float(f32), .y = rng.float(f32) })
                .mult(bounds.size)
                .add(bounds.top_left);
            
            const mass = rng.float(f32) * (particle_mass_max - particle_mass_min) + particle_mass_min;

            try particles.append(PhysicsParticle {
                .mass = mass,
                .position = pos,
                .velocity = Vec2f.ZERO,
            });
        }

        return Self {
            .bounds = bounds,
            .allocator = alloc,
            .particles = particles,
            .threadCount = threadCount,
        };
    }

    pub fn deinit(self: *Self) void {
        self.particles.deinit();
        self.* = undefined;
    }

    pub fn applyGravity(self: *Self, dt: f32) !void {
        const tasksPerThread = @divFloor(self.particles.items.len, self.threadCount);
        
        var threads = std.ArrayList(std.Thread).init(self.allocator);
        defer threads.deinit();

        for(0..self.threadCount) |threadNum| {
            const t = try std.Thread.spawn(.{}, applyGravityForRange,
            .{self, threadNum * tasksPerThread, (threadNum + 1) * tasksPerThread, dt});
            try threads.append(t);
        }

        for(threads.items) |t| {
            t.join();
        }
    }

    fn applyGravityForRange(self: *Self, min: usize, max: usize, dt: f32) void {
        for(min..max) |i| {
            self.applyGravitySingular(i, dt);
        }
    }

    fn applyGravitySingular(self: *Self, i: usize, dt: f32) void {
        var p1 = &self.particles.items[i];

        for(0..self.particles.items.len) |j| {
            if(i == j) continue;

            const p2 = self.particles.items[j];

            p1.pullTowardOther(p2, dt);
        }
    }

    pub fn stepParticles(self: *Self, dt: f32) void {
        // TODO parallelize
        const bottomRight = self.bounds.bottomRight();
        for(self.particles.items) |*p| {
            p.updatePosition(dt);

            if(!self.bounds.isInHorizontalBounds(p.position)) {
                // wrap around screen
                p.position.x = bottomRight.x - p.position.x;

                // make sure wrapped version is still in bounds
                p.position.x = @min(@max(p.position.x, self.bounds.top_left.x), bottomRight.x);
            }

            if(!self.bounds.isInVerticalBounds(p.position)) {
                // same thing but vertical

                p.position.y = bottomRight.y - p.position.y;
                p.position.y = @min(@max(p.position.y, self.bounds.top_left.y), bottomRight.y);
            }
        }
    }

    pub fn performStep(self: *Self, dt: f32) !void {
        try self.applyGravity(dt);
        self.stepParticles(dt);
    }
};

pub const EnvironmentBounds = extern struct {
    const Self = @This();

    top_left: Vec2f,
    size: Vec2f,

    pub fn bottomRight(self: Self) Vec2f {
        return self.top_left.add(self.size);
    }

    pub fn isInBounds(self: Self, point: Vec2f) bool {
        return self.isInHorizontalBounds(point) and self.isInVerticalBounds(point);
    }

    pub fn isInHorizontalBounds(self: Self, point: Vec2f) bool {
        return point.x > self.top_left.x and point.x < self.bottomRight().x;
    }

    pub fn isInVerticalBounds(self: Self, point: Vec2f) bool {
        return point.y > self.top_left.y and point.y < self.bottomRight().y;
    }
};