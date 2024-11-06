pub const std = @import("std");

pub const Vec2f = Vec2(f32);

pub fn Vec2(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const ZERO = Self { .x = 0, .y = 0 };

        x: T,
        y: T,

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn addSingle(self: Self, n: T) Self {
            return .{
                .x = self.x + n,
                .y = self.y + n,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn subSingle(self: Self, n: T) Self {
            return .{
                .x = self.x - n,
                .y = self.y - n,
            };
        }

        pub fn mult(self: Self, other: Self) Self {
            return .{
                .x = self.x * other.x,
                .y = self.y * other.y,
            };
        }

        pub fn multOne(self: Self, n: T) Self {
            return .{
                .x = self.x * n,
                .y = self.y * n,
            };
        }

        pub fn div(self: Self, other: Self) Self {
            return .{
                .x = @divExact(self.x, other.x),
                .y = @divExact(self.y, other.y),
            };
        }

        pub fn divOne(self: Self, n: T) Self {
            return .{
                .x = @divExact(self.x, n),
                .y = @divExact(self.y, n),
            };
        }

        pub fn magSquared(self: Self) T {
            return self.x * self.x + self.y * self.y;
        }

        pub fn mag(self: Self) T {
            return std.math.sqrt(self.magSquared());
        }

        pub fn norm(self: Self) Self {
            const m = self.mag();
            return self.divOne(m);
        }
    };
}