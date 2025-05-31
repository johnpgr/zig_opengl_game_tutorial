const IVec2 = @import("math.zig").IVec2;
const c = @import("c");
const GLContext = @import("gl-renderer.zig");
const RenderData = @import("render-data.zig");
const GameState = @import("game-state.zig");

pub const WORLD_WIDTH = 320;
pub const WORLD_HEIGHT = 180;
pub const INITIAL_SCREEN_WIDTH = WORLD_WIDTH * 4;
pub const INITIAL_SCREEN_HEIGHT = WORLD_HEIGHT * 4;
pub const TILE_SIZE = 8;
pub const WORLD_GRID: IVec2 = .{
    .x = WORLD_WIDTH / TILE_SIZE,
    .y = WORLD_HEIGHT / TILE_SIZE,
};
pub const NUM_KEYS = c.SDL_SCANCODE_COUNT;

pub var window: *c.SDL_Window = undefined;
pub var sdl_gl_context: c.SDL_GLContext = undefined;
pub var gl_context: *GLContext = undefined;
pub var render_data: *RenderData = undefined;
pub var game_state: *GameState = undefined;
