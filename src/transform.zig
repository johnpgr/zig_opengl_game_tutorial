const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;

atlas_offset: IVec2 = IVec2.init(0, 0),
sprite_size: IVec2 = IVec2.init(0, 0),
pos: Vec2 = Vec2.init(0.0, 0.0),
size: Vec2 = Vec2.init(0.0, 0.0),
