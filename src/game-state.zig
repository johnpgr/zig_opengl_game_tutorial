const c = @import("c");
const std = @import("std");
const g = @import("global.zig");
const util = @import("util.zig");
const OrthographicCamera2d = @import("math.zig").OrthographicCamera2d;
const Vec2 = @import("math.zig").Vec2;
const IVec2 = @import("math.zig").IVec2;
const GameInputType = @import("input.zig").GameInputType;
const KeyMapping = @import("input.zig").KeyMapping;
const RenderData = @import("render-data.zig");
const Tile = @import("tile.zig");

const Self = @This();

screen_dimensions: Vec2 = Vec2.init(0.0, 0.0),
running: bool = true,
frame_count: u32 = 0,
delta_time: f32 = 0.0,
player_pos: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos_prev: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos_rel: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos_world: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos_world_prev: Vec2 = Vec2.init(0.0, 0.0),
mouse_pos_world_rel: Vec2 = Vec2.init(0.0, 0.0),
world_grid: [g.WORLD_GRID.x][g.WORLD_GRID.y]Tile =
    [_][g.WORLD_GRID.y]Tile{
        [_]Tile{.{}} ** g.WORLD_GRID.y,
    } ** g.WORLD_GRID.x,
key_state_prev: [g.NUM_KEYS]bool = [_]bool{false} ** g.NUM_KEYS,
key_mapping: KeyMapping,

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);

    self.* = Self{
        .key_mapping = try KeyMapping.init(allocator),
    };

    return self;
}

pub fn updateKeyState(self: *Self) void {
    const current_key_state = c.SDL_GetKeyboardState(null);

    if (current_key_state != null) {
        for (0..g.NUM_KEYS) |i| {
            self.key_state_prev[i] = current_key_state.?[i];
        }
    } else {
        std.debug.print("Failed to get keyboard state\n", .{});
    }
}

pub fn updateMousePosition(
    self: *Self,
    render_data: *RenderData,
    screen_dimensions: Vec2,
) void {
    _ = render_data;
    _ = screen_dimensions;
    // Store previous positions
    self.mouse_pos_prev = self.mouse_pos;
    self.mouse_pos_world_prev = self.mouse_pos_world;

    // Update screen position
    self.mouse_pos = util.getMousePosition();

    // Calculate relative movement
    self.mouse_pos_rel = .{
        .x = self.mouse_pos.x - self.mouse_pos_prev.x,
        .y = self.mouse_pos.y - self.mouse_pos_prev.y,
    };

    //TODO
    // self.mouse_pos_world =

    // Calculate world relative movement
    self.mouse_pos_world_rel = .{
        .x = self.mouse_pos_world.x - self.mouse_pos_world_prev.x,
        .y = self.mouse_pos_world.y - self.mouse_pos_world_prev.y,
    };
}

pub fn keyPressed(self: *Self, key: c.SDL_Keycode) bool {
    const key_state_curr = c.SDL_GetKeyboardState(null);
    if (key_state_curr == null) return false;

    const scancode = c.SDL_GetScancodeFromKey(key, null);
    if (scancode == c.SDL_SCANCODE_UNKNOWN) return false;

    if (scancode < 0 or scancode >= g.NUM_KEYS) return false;

    const idx: usize = @intCast(scancode);
    // Key is pressed if it's currently down (1) and was previously up (0).
    return key_state_curr[idx] and !self.key_state_prev[idx];
}

pub fn keyReleased(self: *Self, key: c.SDL_Keycode) bool {
    const key_state_curr = c.SDL_GetKeyboardState(null);
    if (key_state_curr == null) return false;

    const scancode = c.SDL_GetScancodeFromKey(key);
    if (scancode == c.SDL_SCANCODE_UNKNOWN) return false;

    const scancode_val: c_int = @intFromEnum(scancode);
    if (scancode_val < 0 or scancode_val >= c.SDL_NUM_SCANCODES) return false;

    const idx: usize = @intCast(scancode_val);
    // Key is released if it's currently up (0) and was previously down (1).
    return !key_state_curr[idx] and self.key_state_prev[idx];
}

pub fn keyDown(self: *Self, key: c.SDL_Keycode) bool {
    _ = self;
    const key_state_curr = c.SDL_GetKeyboardState(null);
    if (key_state_curr == null) return false;

    const scancode = c.SDL_GetScancodeFromKey(key, null);
    if (scancode == c.SDL_SCANCODE_UNKNOWN) return false;

    if (scancode < 0 or scancode >= g.NUM_KEYS) return false;

    const idx: usize = @intCast(scancode);
    // Key is down if it's currently pressed
    return key_state_curr[idx];
}

pub fn inputPressed(self: *Self, input_type: GameInputType) bool {
    const keys = self.key_mapping.getKeys(input_type);
    for (keys) |key| {
        if (self.keyPressed(key)) {
            return true;
        }
    }
    return false;
}

pub fn inputReleased(self: *Self, input_type: GameInputType) bool {
    const keys = self.key_mapping.getKeys(input_type);
    for (keys) |key| {
        if (self.keyReleased(key)) {
            return true;
        }
    }
    return false;
}

pub fn inputDown(self: *Self, input_type: GameInputType) bool {
    const inputs = self.key_mapping.getInputs(input_type);
    for (inputs) |input| {
        switch (input) {
            .key => |keycode| {
                if (self.keyDown(keycode)) return true;
            },
            .mouse => |button| {
                if (self.mouseButtonDown(button)) return true;
            },
        }
    }
    return false;
}

pub fn mouseButtonDown(self: *Self, button: u8) bool {
    _ = self;
    const mouse_state: c_uint = c.SDL_GetMouseState(null, null);
    const mask: c_uint = @as(c_uint, 1) << @as(u5, @intCast(@as(c_uint, button) - 1));
    return (mouse_state & mask) != 0;
}

pub fn getTile(self: *Self, x: f32, y: f32) ?*Tile {
    if (x >= 0 and x < g.WORLD_GRID.x and y >= 0 and y < g.WORLD_GRID.y) {
        return &self.world_grid[@intFromFloat(x)][@intFromFloat(y)];
    }

    return null;
}

pub fn getTileI(self: *Self, x: i32, y: i32) ?*Tile {
    if (x >= 0 and x < g.WORLD_GRID.x and y >= 0 and y < g.WORLD_GRID.y) {
        return &self.world_grid[@intCast(x)][@intCast(y)];
    }

    return null;
}

pub fn getTileAtWorldPos(self: *Self, pos: Vec2) ?*Tile {
    return self.getTile(pos.x, pos.y);
}

pub fn getTileAtWorldPosI(self: *Self, pos: IVec2) ?*Tile {
    return self.getTileI(pos.x, pos.y);
}
