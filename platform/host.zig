const std = @import("std");
const builtin = @import("builtin");
const list = @import("list.zig");
const str = @import("str.zig");
const tvg = @import("tinyvg");
const zigimg = @import("zigimg");
const RocList = list.RocList;
const RocStr = str.RocStr;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const Align = 2 * @alignOf(usize);
const DEBUG: bool = false;

extern fn malloc(size: usize) callconv(.C) ?*align(Align) anyopaque;
extern fn realloc(c_ptr: [*]align(Align) u8, size: usize) callconv(.C) ?*anyopaque;
extern fn free(c_ptr: [*]align(Align) u8) callconv(.C) void;
extern fn memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void;
extern fn memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        var ptr = malloc(size);
        const stdout = std.io.getStdOut().writer();
        stdout.print("alloc:   {d} (alignment {d}, size {d})\n", .{ ptr, alignment, size }) catch unreachable;
        return ptr;
    } else {
        return malloc(size);
    }
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("realloc: {d} (alignment {d}, old_size {d})\n", .{ c_ptr, alignment, old_size }) catch unreachable;
    }

    return realloc(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))), new_size);
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("dealloc: {d} (alignment {d})\n", .{ c_ptr, alignment }) catch unreachable;
    }

    free(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))));
}

export fn roc_panic(msg: *RocStr, tag_id: u32) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    // const msg = @as([*:0]const u8, @ptrCast(c_ptr));
    stderr.print("\n\nRoc crashed with the following error;\nMSG:{s}\nTAG:{d}\n\nShutting down\n", .{ msg.asSlice(), tag_id }) catch unreachable;
    std.process.exit(0);
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    return memset(dst, value, size);
}

extern fn kill(pid: c_int, sig: c_int) c_int;
extern fn shm_open(name: *const i8, oflag: c_int, mode: c_uint) c_int;
extern fn mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) *anyopaque;
extern fn getppid() c_int;

fn roc_getppid() callconv(.C) c_int {
    return getppid();
}

fn roc_getppid_windows_stub() callconv(.C) c_int {
    return 0;
}

fn roc_shm_open(name: *const i8, oflag: c_int, mode: c_uint) callconv(.C) c_int {
    return shm_open(name, oflag, mode);
}
fn roc_mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) callconv(.C) *anyopaque {
    return mmap(addr, length, prot, flags, fd, offset);
}

comptime {
    if (builtin.os.tag == .macos or builtin.os.tag == .linux) {
        @export(roc_getppid, .{ .name = "roc_getppid", .linkage = .Strong });
        @export(roc_mmap, .{ .name = "roc_mmap", .linkage = .Strong });
        @export(roc_shm_open, .{ .name = "roc_shm_open", .linkage = .Strong });
    }

    if (builtin.os.tag == .windows) {
        @export(roc_getppid_windows_stub, .{ .name = "roc_getppid", .linkage = .Strong });
    }
}

const mem = std.mem;
const Allocator = mem.Allocator;

extern fn roc__mainForHost_1_exposed_generic(*RocStr, *RocStr) void;

fn callRoc(arg: RocStr) RocStr {
    var callresult = RocStr.empty();
    roc__mainForHost_1_exposed_generic(&callresult, @constCast(&arg));
    arg.decref();

    return callresult;
}

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const assert = @import("std").debug.assert;

var SCREEN_WIDTH: c_int = undefined;
var SCREEN_HEIGHT: c_int = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // CALL ROC
    // const arg = RocStr.fromSlice("Luke");
    // const callresult = callRoc(arg);

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    // SETUP WINDOW
    try setupScreen();
    const screen = c.SDL_CreateWindow("My Game Window", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_OPENGL) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // const zig_bmp = @embedFile("zig.bmp");
    // const rw = c.SDL_RWFromConstMem(zig_bmp, zig_bmp.len) orelse {
    //     c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
    //     return error.SDLInitializationFailed;
    // };
    // defer assert(c.SDL_RWclose(rw) == 0);

    // const zig_surface = c.SDL_LoadBMP_RW(rw, 0) orelse {
    //     c.SDL_Log("Unable to load bmp: %s", c.SDL_GetError());
    //     return error.SDLInitializationFailed;
    // };
    // defer c.SDL_FreeSurface(zig_surface);

    // const zig_texture = c.SDL_CreateTextureFromSurface(renderer, zig_surface) orelse {
    //     c.SDL_Log("Unable to create texture from surface: %s", c.SDL_GetError());
    //     return error.SDLInitializationFailed;
    // };
    // defer c.SDL_DestroyTexture(zig_texture);

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        // Clear Screen
        _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF);
        _ = c.SDL_RenderClear(renderer);

        // Get rects from Roc
        var rects = try getRects(allocator);
        defer rects.deinit();

        // Draw each rectangle
        _ = c.SDL_SetRenderDrawColor(renderer, 0xFF, 0x00, 0x00, 0xFF);
        for (rects.items) |rect| {
            _ = c.SDL_RenderFillRect(renderer, &rect);
        }

        // TODO Draw texture
        // _ = c.SDL_RenderCopy(renderer, zig_texture, null, null);

        // Update Screen
        c.SDL_RenderPresent(renderer);

        c.SDL_Delay(17);
    }
}

const InitDimensions = struct {
    w: c_int,
    h: c_int,
};

fn setupScreen() !void {
    const arg = RocStr.fromSlice("INIT");
    defer arg.decref();
    const callresult = callRoc(arg);
    defer callresult.decref();

    var values = std.mem.splitScalar(u8, callresult.asSlice(), ' ');

    const width = values.next() orelse return error.ParseError;
    const height = values.next() orelse return error.ParseError;

    SCREEN_WIDTH = try std.fmt.parseInt(c_int, width, 10);
    SCREEN_HEIGHT = try std.fmt.parseInt(c_int, height, 10);
}

fn getRects(allocator: std.mem.Allocator) !std.ArrayList(c.SDL_Rect) {
    const arg = RocStr.fromSlice("RENDER");
    defer arg.decref();
    const callresult = callRoc(arg);
    defer callresult.decref();

    var rects = std.ArrayList(c.SDL_Rect).init(allocator);

    var rectStrs = std.mem.splitScalar(u8, callresult.asSlice(), '|');
    while (rectStrs.next()) |rectStr| {
        if (rectStr.len == 0) {
            continue;
        }

        var values = std.mem.splitScalar(u8, rectStr, ' ');

        const x = values.next() orelse return error.ParseError;
        const y = values.next() orelse return error.ParseError;
        const w = values.next() orelse return error.ParseError;
        const h = values.next() orelse return error.ParseError;

        try rects.append(.{
            .x = try std.fmt.parseInt(c_int, x, 10),
            .y = try std.fmt.parseInt(c_int, y, 10),
            .w = try std.fmt.parseInt(c_int, w, 10),
            .h = try std.fmt.parseInt(c_int, h, 10),
        });
    }

    return rects;
}
