const c = @import("c");
const std = @import("std");

pub const GameInputType = enum {
    MOVE_UP,
    MOVE_DOWN,
    MOVE_LEFT,
    MOVE_RIGHT,
    JUMP,
    ATTACK,
    INTERACT,
    PAUSE,
    QUIT,
    PRIMARY,
    SECONDARY,
};

pub const InputCode = union(enum) {
    key: c.SDL_Keycode,
    mouse: u8,  // SDL_BUTTON_LEFT = 1, SDL_BUTTON_RIGHT = 3, etc.
    // gamepad: u8,  // Can be added later
};

pub const KeyMapping = struct {
    allocator: std.mem.Allocator,
    mappings: std.EnumArray(GameInputType, std.ArrayList(InputCode)),

    pub fn init(allocator: std.mem.Allocator) !KeyMapping {
        var self = KeyMapping{
            .allocator = allocator,
            .mappings = std.EnumArray(
                GameInputType,
                std.ArrayList(InputCode),
            ).init(.{
                .MOVE_UP = undefined,
                .MOVE_DOWN = undefined,
                .MOVE_LEFT = undefined,
                .MOVE_RIGHT = undefined,
                .JUMP = undefined,
                .ATTACK = undefined,
                .INTERACT = undefined,
                .PAUSE = undefined,
                .QUIT = undefined,
                .PRIMARY = undefined,
                .SECONDARY = undefined,
            }),
        };

        // Initialize ArrayLists for each GameInputType
        inline for (std.meta.fields(GameInputType)) |field| {
            const input_type = @field(GameInputType, field.name);
            self.mappings.set(
                input_type,
                std.ArrayList(InputCode).init(allocator),
            );
        }

        try self.addMapping(.MOVE_UP, .{ .key = c.SDLK_W });
        try self.addMapping(.MOVE_UP, .{ .key = c.SDLK_UP });

        try self.addMapping(.MOVE_DOWN, .{ .key = c.SDLK_S });
        try self.addMapping(.MOVE_DOWN, .{ .key = c.SDLK_DOWN });

        try self.addMapping(.MOVE_LEFT, .{ .key = c.SDLK_A });
        try self.addMapping(.MOVE_LEFT, .{ .key = c.SDLK_LEFT });

        try self.addMapping(.MOVE_RIGHT, .{ .key = c.SDLK_D });
        try self.addMapping(.MOVE_RIGHT, .{ .key = c.SDLK_RIGHT });

        try self.addMapping(.JUMP, .{ .key = c.SDLK_SPACE });

        try self.addMapping(.ATTACK, .{ .key = c.SDLK_X });
        try self.addMapping(.ATTACK, .{ .mouse = c.SDL_BUTTON_LEFT });

        try self.addMapping(.INTERACT, .{ .key = c.SDLK_E });

        try self.addMapping(.PAUSE, .{ .key = c.SDLK_ESCAPE });
        try self.addMapping(.QUIT, .{ .key = c.SDLK_ESCAPE });

        try self.addMapping(.PRIMARY, .{ .mouse = c.SDL_BUTTON_LEFT });
        try self.addMapping(.SECONDARY, .{ .mouse = c.SDL_BUTTON_RIGHT });

        return self;
    }

    pub fn deinit(self: *KeyMapping) void {
        inline for (std.meta.fields(GameInputType)) |field| {
            const input_type = @field(GameInputType, field.name);
            self.mappings.getPtr(input_type).deinit();
        }
    }

    pub fn addMapping(
        self: *KeyMapping,
        input_type: GameInputType,
        code: InputCode,
    ) !void {
        const input_list = self.mappings.getPtr(input_type);

        for (input_list.items) |existing_input| {
            if (std.meta.eql(existing_input, code)) return;
        }

        try input_list.append(code);
    }

    pub fn removeMapping(
        self: *KeyMapping,
        input_type: GameInputType,
        code: InputCode,
    ) void {
        var input_list = self.mappings.getPtr(input_type);
        for (input_list.items, 0..) |existing_input, i| {
            if (std.meta.eql(existing_input, code)) {
                _ = input_list.swapRemove(i);
                break;
            }
        }
    }

    pub fn getInputs(self: *const KeyMapping, input_type: GameInputType) []const InputCode {
        return self.mappings.get(input_type).items;
    }
};
