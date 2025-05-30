pub const IVec2 = @import("math.zig").IVec2;

pub const WORLD_WIDTH = 320;
pub const WORLD_HEIGHT = 180;
pub const INITIAL_SCREEN_WIDTH = WORLD_WIDTH * 4;
pub const INITIAL_SCREEN_HEIGHT = WORLD_HEIGHT * 4;
pub const TILE_SIZE = 8;
pub const WORLD_GRID: IVec2 = .{
    .x = WORLD_WIDTH / TILE_SIZE,
    .y = WORLD_HEIGHT / TILE_SIZE,
};
