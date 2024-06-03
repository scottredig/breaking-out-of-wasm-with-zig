const std = @import("std");
const zjb = @import("zjb");
const game = @import("game.zig");

var allocator = std.heap.wasm_allocator;
var g: *game.Game = undefined;

var canvas: zjb.Handle = undefined;
var ctx: zjb.Handle = undefined;
var window_size: [2]i32 = undefined;
var last_timestamp: f64 = undefined;

pub const panic = zjb.panic;
export fn main() void {
    g = game.Game.create(allocator) catch |e| zjb.throwError(e);

    canvas = zjb.global("document").call("createElement", .{zjb.constString("canvas")}, zjb.Handle);
    ctx = canvas.call("getContext", .{zjb.constString("2d")}, zjb.Handle);

    {
        const body = zjb.global("document").get("body", zjb.Handle);
        defer body.release();

        body.call("appendChild", .{canvas}, void);
    }

    zjb.global("document").call("addEventListener", .{ zjb.constString("keydown"), zjb.fnHandle("keyDown", keyDown) }, void);
    zjb.global("document").call("addEventListener", .{ zjb.constString("keyup"), zjb.fnHandle("keyUp", keyUp) }, void);

    {
        const timeline = zjb.global("document").get("timeline", zjb.Handle);
        defer timeline.release();

        last_timestamp = timeline.get("currentTime", f64);
        animationFrame(last_timestamp);
    }
}

fn animationFrame(timestamp: f64) callconv(.C) void {
    const delta_time = timestamp - last_timestamp;
    last_timestamp = timestamp;
    window_size[0] = zjb.ConstHandle.global.get("innerWidth", i32);
    window_size[1] = zjb.ConstHandle.global.get("innerHeight", i32);
    canvas.set("width", window_size[0]);
    canvas.set("height", window_size[1]);

    g.step(@floatCast(@min(delta_time / 1000, 0.1)));

    // Background
    ctx.set("fillStyle", zjb.constString("#000"));
    ctx.call("fillRect", .{ 0, 0, window_size[0], window_size[1] }, void);

    // Draw rectangles from game
    ctx.set("fillStyle", zjb.constString("#fff"));
    for (g.draw_rectangles.constSlice()) |bounds| {
        ctx.call("fillRect", .{ bounds.min[0], bounds.min[1], bounds.size[0], bounds.size[1] }, void);
    }

    zjb.ConstHandle.global.call("requestAnimationFrame", .{zjb.fnHandle("animationFrame", animationFrame)}, void);
}

fn eventButton(event: zjb.Handle) ?game.Button {
    const key = event.get("key", zjb.Handle);
    defer key.release();
    if (key.eql(zjb.constString("ArrowLeft"))) {
        return .left;
    }
    if (key.eql(zjb.constString("ArrowRight"))) {
        return .right;
    }
    return null;
}

fn keyDown(event: zjb.Handle) callconv(.C) void {
    defer event.release();

    if (eventButton(event)) |button| {
        g.press(button);
    }
}

fn keyUp(event: zjb.Handle) callconv(.C) void {
    defer event.release();

    if (eventButton(event)) |button| {
        g.release(button);
    }
}
