const c = @import("c");
const std = @import("std");
const OrthographicCamera2d = @import("gpu-data.zig").OrthographicCamera2d;
const Vec2 = @import("math.zig").Vec2;
const GameInputType = @import("input.zig").GameInputType;
const KeyMapping = @import("input.zig").KeyMapping;

const Self = @This();

const NUM_KEYS = c.SDL_SCANCODE_COUNT;

allocator: std.mem.Allocator,
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
key_mapping: KeyMapping,

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
        .player_pos = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos_prev = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos_rel = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos_world = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos_world_prev = .{ .x = 0.0, .y = 0.0 },
        .mouse_pos_world_rel = .{ .x = 0.0, .y = 0.0 },
        .key_state_prev = [_]bool{false} ** NUM_KEYS,
        .key_mapping = try KeyMapping.init(allocator),
    };

    return self;
}

pub fn deinit(self:*Self) void {
    self.key_mapping.deinit();
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
    const keys = self.key_mapping.getKeys(input_type);
    for (keys) |key| {
        if (self.keyDown(key)) {
            return true;
        }
    }
    return false;
}

pub fn updateMousePosition(
    self: *Self,
    screen_x: f32,
    screen_y: f32,
    camera: *const OrthographicCamera2d,
    screen_dimensions: Vec2,
) void {
    // Store the previous positions
    self.mouse_pos_prev = self.mouse_pos;
    self.mouse_pos_world_prev = self.mouse_pos_world;

    // Update current screen position
    self.mouse_pos = .{ .x = screen_x, .y = screen_y };

    // Convert screen coordinates to normalized device coordinates (0 to 1)
    const ndc_x = screen_x / screen_dimensions.x;
    const ndc_y = screen_y / screen_dimensions.y;

    // Convert NDC to world coordinates accounting for camera position and zoom
    const world_x = camera.position.x + (ndc_x * camera.dimensions.x) / camera.zoom;
    const world_y = camera.position.y + (ndc_y * camera.dimensions.y) / camera.zoom;

    self.mouse_pos_world = .{ .x = world_x, .y = world_y };

    // Calculate relative movement
    self.mouse_pos_rel = .{
        .x = self.mouse_pos.x - self.mouse_pos_prev.x,
        .y = self.mouse_pos.y - self.mouse_pos_prev.y,
    };
    self.mouse_pos_world_rel = .{
        .x = self.mouse_pos_world.x - self.mouse_pos_world_prev.x,
        .y = self.mouse_pos_world.y - self.mouse_pos_world_prev.y,
    };
}
