const std = @import("std");

const total_size = [2]comptime_int{ 400, 300 };
const num_blocks = [2]comptime_int{ 10, 10 };

const paddle_size = [2]f32{ 60, 7 };
const ball_size = [2]f32{ 7, 7 };

const paddle_start = [2]f32{ (total_size[0] - paddle_size[0]) / 2, total_size[1] - paddle_size[1] - 10 };
const ball_start = [2]f32{ total_size[0] / 2, paddle_start[1] - ball_size[1] - 5 };

const max_rectangles = num_blocks[0] * num_blocks[1] // blocks
+ 1 // paddle
+ 1 //ball
;

pub const Game = struct {
    blocks: [num_blocks[0] * num_blocks[1]]bool = [_]bool{true} ** (num_blocks[0] * num_blocks[1]),
    paddle_pos: [2]f32 = paddle_start,
    ball_pos: [2]f32 = ball_start,
    ball_dir: [2]f32 = .{ 0, -200 },

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

        const ball = Bounds{
            .min = g.ball_pos,
            .size = ball_size,
        };

        for (0..num_blocks[0]) |x| {
            for (0..num_blocks[1]) |y| {
                const i = x + y * num_blocks[0];
                if (g.blocks[i] and blockBounds(.{ x, y }).overlap(ball)) {
                    g.blocks[i] = false;
                    g.ball_dir[1] *= -1;
                }
            }
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

    fn overlap(a: Bounds, b: Bounds) bool {
        const left_of = a.min[0] + a.size[0] <= b.min[0];
        const right_of = a.min[0] >= b.min[0] + b.size[0];
        const above = a.min[1] + a.size[1] <= b.min[1];
        const below = a.min[1] >= b.min[1] + b.size[1];
        return !(left_of or right_of or above or below);
    }
};

fn blockBounds(pos: [2]usize) Bounds {
    const fpos = [2]f32{ @floatFromInt(pos[0]), @floatFromInt(pos[1]) };
    const margin: f32 = 1;
    const block_h_start = 25;
    const block_size = [2]f32{ // ignoring margin
        total_size[0] / num_blocks[0],
        7,
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
