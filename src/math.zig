const c = @import("c");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn toIVec2(self: Vec2) IVec2 {
        return IVec2{ .x = @intCast(self.x), .y = @intCast(self.y) };
    }

    pub fn sub(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn add(self: Vec2, other: Vec2) Vec2 {
        return Vec2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn div(self: Vec2, divisor: f32) Vec2 {
        return Vec2{ .x = self.x / divisor, .y = self.y / divisor };
    }
};

pub const IVec2 = struct {
    x: i32,
    y: i32,

    pub fn toVec2(self: IVec2) Vec2 {
        return Vec2{ .x = @floatFromInt(self.x), .y = @floatFromInt(self.y) };
    }

    pub fn sub(self: IVec2, other: IVec2) IVec2 {
        return IVec2{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn add(self: IVec2, other: IVec2) IVec2 {
        return IVec2{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn div(self: IVec2, divisor: f32) IVec2 {
        return IVec2{
            .x = @intCast(@as(f32, @floatFromInt(self.x)) / divisor),
            .y = @intCast(@as(f32, @floatFromInt(self.y)) / divisor),
        };
    }
};

pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

/// Represents a 4x4 matrix in column-major order.
/// [ax, ay, az, aw]
/// [bx, by, bz, bw]
/// [cx, cy, cz, cw]
/// [dx, dy, dz, dw]
pub const Mat4 = struct {
    data: [4][4]f32 = [_][4]f32{
        [_]f32{ 0.0, 0.0, 0.0, 0.0 },
        [_]f32{ 0.0, 0.0, 0.0, 0.0 },
        [_]f32{ 0.0, 0.0, 0.0, 0.0 },
        [_]f32{ 0.0, 0.0, 0.0, 0.0 },
    },

    pub fn ax(self: *Mat4) *f32 {
        return &self.data[0][0];
    }
    pub fn bx(self: *Mat4) *f32 {
        return &self.data[1][0];
    }
    pub fn cx(self: *Mat4) *f32 {
        return &self.data[2][0];
    }
    pub fn dx(self: *Mat4) *f32 {
        return &self.data[3][0];
    }
    pub fn ay(self: *Mat4) *f32 {
        return &self.data[0][1];
    }
    pub fn by(self: *Mat4) *f32 {
        return &self.data[1][1];
    }
    pub fn cy(self: *Mat4) *f32 {
        return &self.data[2][1];
    }
    pub fn dy(self: *Mat4) *f32 {
        return &self.data[3][1];
    }
    pub fn az(self: *Mat4) *f32 {
        return &self.data[0][2];
    }
    pub fn bz(self: *Mat4) *f32 {
        return &self.data[1][2];
    }
    pub fn cz(self: *Mat4) *f32 {
        return &self.data[2][2];
    }
    pub fn dz(self: *Mat4) *f32 {
        return &self.data[3][2];
    }
    pub fn aw(self: *Mat4) *f32 {
        return &self.data[0][3];
    }
    pub fn bw(self: *Mat4) *f32 {
        return &self.data[1][3];
    }
    pub fn cw(self: *Mat4) *f32 {
        return &self.data[2][3];
    }
    pub fn dw(self: *Mat4) *f32 {
        return &self.data[3][3];
    }

    pub fn translate(self: *Mat4, x: f32, y: f32, z: f32) Mat4 {
        var result = self.*;
        result.aw().* += x;
        result.bw().* += y;
        result.cw().* += z;
        return result;
    }

    pub fn orthographicProjection(
        left: f32,
        right: f32,
        top: f32,
        bottom: f32,
    ) Mat4 {
        var result = Mat4{};

        // Set scale components
        result.data[0][0] = 2.0 / (right - left);
        result.data[1][1] = 2.0 / (top - bottom);
        result.data[2][2] = 1.0; // Far/(far-near) with near=0, far=1
        result.data[3][3] = 1.0;

        // Set translation in last column (column-major layout)
        result.dx().* = -(right + left) / (right - left);
        result.dy().* = -(top + bottom) / (top - bottom);
        result.dz().* = -0.0; // No depth translation for 2D

        return result;
    }
};
