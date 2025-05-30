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
    RELOAD,
};

pub const KeyMapping = struct {
    allocator: std.mem.Allocator,
    mappings: std.EnumArray(GameInputType, std.ArrayList(c.SDL_Keycode)),

    pub fn init(allocator: std.mem.Allocator) !KeyMapping {
        var self = KeyMapping{
            .allocator = allocator,
            .mappings = std.EnumArray(GameInputType, std.ArrayList(c.SDL_Keycode)).init(.{
                .MOVE_UP = undefined,
                .MOVE_DOWN = undefined,
                .MOVE_LEFT = undefined,
                .MOVE_RIGHT = undefined,
                .JUMP = undefined,
                .ATTACK = undefined,
                .INTERACT = undefined,
                .PAUSE = undefined,
                .QUIT = undefined,
                .RELOAD = undefined,
            }),
        };

        // Initialize ArrayLists for each GameInputType
        inline for (std.meta.fields(GameInputType)) |field| {
            const input_type = @field(GameInputType, field.name);
            self.mappings.set(input_type, std.ArrayList(c.SDL_Keycode).init(allocator));
        }

        // Set up default key mappings
        self.addMapping(.MOVE_UP, c.SDLK_W) catch {};
        self.addMapping(.MOVE_UP, c.SDLK_UP) catch {};
        
        self.addMapping(.MOVE_DOWN, c.SDLK_S) catch {};
        self.addMapping(.MOVE_DOWN, c.SDLK_DOWN) catch {};
        
        self.addMapping(.MOVE_LEFT, c.SDLK_A) catch {};
        self.addMapping(.MOVE_LEFT, c.SDLK_LEFT) catch {};
        
        self.addMapping(.MOVE_RIGHT, c.SDLK_D) catch {};
        self.addMapping(.MOVE_RIGHT, c.SDLK_RIGHT) catch {};
        
        self.addMapping(.JUMP, c.SDLK_SPACE) catch {};
        
        self.addMapping(.ATTACK, c.SDLK_X) catch {};
        self.addMapping(.ATTACK, c.SDLK_Z) catch {};
        
        self.addMapping(.INTERACT, c.SDLK_E) catch {};
        
        self.addMapping(.PAUSE, c.SDLK_ESCAPE) catch {};
        
        self.addMapping(.QUIT, c.SDLK_ESCAPE) catch {};
        
        self.addMapping(.RELOAD, c.SDLK_R) catch {};

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
        key: c.SDL_Keycode,
    ) !void {
        const key_list = self.mappings.getPtr(input_type);

        for (key_list.items) |existing_key| {
            if (existing_key == key) return;
        }

        try key_list.append(key);
    }

    pub fn removeMapping(
        self: *KeyMapping,
        input_type: GameInputType,
        keycode: c.SDL_Keycode,
    ) void {
        var key_list = self.mappings.getPtr(input_type);
        for (key_list.items, 0..) |existing_key, i| {
            if (existing_key == keycode) {
                _ = key_list.swapRemove(i);
                break;
            }
        }
    }

    pub fn getKeys(self: *const KeyMapping, input_type: GameInputType) []const c.SDL_Keycode {
        return self.mappings.get(input_type).items;
    }
};
