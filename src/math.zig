const c = @import("c");

pub const Vec2 = c.SDL_FPoint;
pub const IVec2 = c.SDL_Point;

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

    pub fn orthographicProjection(
        left: f32,
        right: f32,
        top: f32,
        bottom: f32,
    ) Mat4 {
        var result = Mat4{};

        result.aw().* = -(right + left) / (right - left);
        result.bw().* = (top + bottom) / (top - bottom);
        result.cw().* = 0.0; // Near Plane
        result.data[0][0] = 2.0 / (right - left);
        result.data[1][1] = 2.0 / (top - bottom);
        result.data[2][2] = 1.0 / (1.0 - 0.0); // Far and Near
        result.data[3][3] = 1.0;

        return result;
    }
};
