const zjb = @import("zjb");

const game = @import("game.zig");
var g = game.Game{};

var canvas: zjb.Handle = undefined;
var ctx: zjb.Handle = undefined;
var window_size: [2]i32 = undefined;
var last_timestamp: f64 = undefined;

export fn main() void {
    canvas = zjb.global("document").call("createElement", .{zjb.constString("canvas")}, zjb.Handle);
    ctx = canvas.call("getContext", .{zjb.constString("2d")}, zjb.Handle);

    {
        const body = zjb.global("document").get("body", zjb.Handle);
        defer body.release();

        body.call("appendChild", .{canvas}, void);
    }

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

    // Draw blocks
    ctx.set("fillStyle", zjb.constString("#fff"));
    for (0..game.num_blocks[0]) |x| {
        for (0..game.num_blocks[1]) |y| {
            if (g.blocks[x + y * game.num_blocks[0]]) {
                const b = game.blockBounds(.{ x, y });
                ctx.call("fillRect", .{ b.min[0], b.min[1], b.max[0] - b.min[0], b.max[1] - b.min[1] }, void);
            }
        }
    }

    ctx.call("fillRect", .{ g.paddle_pos[0], g.paddle_pos[1], game.paddle_size[0], game.paddle_size[1] }, void);

    zjb.ConstHandle.global.call("requestAnimationFrame", .{zjb.fnHandle("animationFrame", animationFrame)}, void);
}
