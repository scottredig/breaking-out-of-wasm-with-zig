const std = @import("std");

const total_size = [2]comptime_int{ 400, 300 };
const num_blocks = [2]comptime_int{ 10, 5 };

const paddle_size = [2]f32{ 60, 7 };
const ball_size = [2]f32{ 10, 10 };

const max_rectangles = num_blocks[0] * num_blocks[1] // blocks
+ 1 // paddle
+ 1 //ball
;

pub const Game = struct {
    blocks: [num_blocks[0] * num_blocks[1]]bool = [_]bool{true} ** (num_blocks[0] * num_blocks[1]),
    paddle_pos: [2]f32 = [2]f32{ (total_size[0] - paddle_size[0]) / 2, total_size[1] - paddle_size[1] - 10 },
    ball_pos: [2]f32 = .{ 0, 0 },
    ball_dir: [2]f32 = .{ 60, 60 },

    draw_rectangles: std.BoundedArray(Bounds, max_rectangles) = .{},

    pub fn create(allocator: std.mem.Allocator) !*Game {
        const g = try allocator.create(Game);
        g.* = .{};
        return g;
    }

    pub fn step(g: *Game, dt: f32) void {
        g.update(dt);
        try g.draw();
    }

    fn update(g: *Game, dt: f32) void {
        inline for (0..2) |d| {
            if (g.ball_dir[d] < 0 and g.ball_pos[d] <= 0) {
                g.ball_dir[d] *= -1;
            }
            if (g.ball_dir[d] > 0 and g.ball_pos[d] + ball_size[d] >= total_size[d]) {
                g.ball_dir[d] *= -1;
            }
        }

        for (0..2) |d| {
            g.ball_pos[d] += g.ball_dir[d] * dt;
        }
    }

    fn draw(g: *Game) !void {
        g.draw_rectangles.resize(0) catch unreachable;

        for (0..num_blocks[0]) |x| {
            for (0..num_blocks[1]) |y| {
                if (g.blocks[x + y * num_blocks[0]]) {
                    g.draw_rectangles.append(blockBounds(.{ x, y })) catch unreachable;
                }
            }
        }

        g.draw_rectangles.append(.{
            .min = g.paddle_pos,
            .size = paddle_size,
        }) catch unreachable;
        g.draw_rectangles.append(.{
            .min = g.ball_pos,
            .size = ball_size,
        }) catch unreachable;
    }
};

pub const Bounds = struct {
    min: [2]f32,
    size: [2]f32,
};

fn blockBounds(pos: [2]usize) Bounds {
    const fpos = [2]f32{ @floatFromInt(pos[0]), @floatFromInt(pos[1]) };
    const margin: f32 = 1;
    const block_h_start = 25;
    const block_size = [2]f32{ // ignoring margin
        total_size[0] / num_blocks[0],
        10,
    };
    return .{
        .min = .{
            block_size[0] * fpos[0] + margin,
            block_size[1] * fpos[1] + margin + block_h_start,
        },
        .size = .{
            block_size[0] - 2 * margin,
            block_size[1] - 2 * margin,
        },
    };
}
