pub inline fn bit(comptime x:u32) u32 {
    return 1 << x;
}

pub inline fn kb(comptime x:u32) u32 {
    return x * 1024;
}

pub inline fn mb(comptime x:u32) u32 {
    return kb(x) * 1024;
}

pub inline fn gb(comptime x:u32) u32 {
    return mb(x) * 1024;
}
