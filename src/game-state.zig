const c = @import("c");
const std = @import("std");
const Vec2 = @import("math.zig").Vec2;

const Self = @This();

const NUM_KEYS = c.SDL_SCANCODE_COUNT;

player_pos: Vec2,
// Screen
mouse_pos: Vec2,
mouse_pos_prev: Vec2,
mouse_pos_rel: Vec2,
// World
mouse_pos_world: Vec2,
mouse_pos_world_prev: Vec2,
mouse_pos_world_rel: Vec2,

key_state_prev: [NUM_KEYS]bool,

pub fn init(self: *Self) void {
    self.player_pos = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos_prev = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos_rel = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos_world = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos_world_prev = .{ .x = 0.0, .y = 0.0 };
    self.mouse_pos_world_rel = .{ .x = 0.0, .y = 0.0 };
    self.key_state_prev = [_]bool{false} ** NUM_KEYS;
}

pub fn update_key_state(self: *Self) void {
    const current_key_state = c.SDL_GetKeyboardState(null);

    if (current_key_state != null) {
        for (0..NUM_KEYS) |i| {
            self.key_state_prev[i] = current_key_state.?[i];
        }
    } else {
        std.debug.print("Failed to get keyboard state\n", .{});
    }
}

pub fn keyPressed(self: *Self, key: c.SDL_Keycode) bool {
    const key_state_curr = c.SDL_GetKeyboardState(null);
    if (key_state_curr == null) return false;

    const scancode = c.SDL_GetScancodeFromKey(key, null);
    if (scancode == c.SDL_SCANCODE_UNKNOWN) return false;

    if (scancode < 0 or scancode >= NUM_KEYS) return false;

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

    if (scancode < 0 or scancode >= NUM_KEYS) return false;

    const idx: usize = @intCast(scancode);
    // Key is down if it's currently pressed
    return key_state_curr[idx];
}
