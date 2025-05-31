const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

zoom: f32 = 1.0,
position: Vec2 = Vec2.init(0.0, 0.0),
dimensions: Vec2 = Vec2.init(0.0, 0.0),
