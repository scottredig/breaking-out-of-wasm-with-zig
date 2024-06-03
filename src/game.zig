const std = @import("std");

pub const total_size = [2]comptime_int{ 400, 300 };
const num_blocks = [2]comptime_int{ 10, 10 };

const paddle_size = [2]f32{ 60, 7 };
const ball_size = [2]f32{ 7, 7 };

const paddle_start = [2]f32{ (total_size[0] - paddle_size[0]) / 2, total_size[1] - paddle_size[1] - 10 };
const ball_start = [2]f32{ total_size[0] / 2, paddle_start[1] - ball_size[1] - 5 };

const max_rectangles = num_blocks[0] * num_blocks[1] // blocks
+ 1 // paddle
+ 1 //ball
;

pub const Button = enum {
    left,
    right,
    go,
};

pub const Game = struct {
    blocks: [num_blocks[0] * num_blocks[1]]bool = [_]bool{true} ** (num_blocks[0] * num_blocks[1]),
    ball: Bounds = .{
        .min = ball_start,
        .size = ball_size,
    },
    ball_velocity: [2]f32 = .{ 0, -200 },
    paddle: Bounds = .{
        .min = paddle_start,
        .size = paddle_size,
    },
    buttons: std.EnumSet(Button) = std.EnumSet(Button).initEmpty(),

    draw_rectangles: std.BoundedArray(Bounds, max_rectangles) = .{},

    pub fn create(allocator: std.mem.Allocator) !*Game {
        const g = try allocator.create(Game);
        g.* = .{};
        return g;
    }

    pub fn press(g: *Game, button: Button) void {
        g.buttons.insert(button);
    }

    pub fn release(g: *Game, button: Button) void {
        g.buttons.remove(button);
    }

    pub fn step(g: *Game, dt: f32) void {
        g.update(dt);
        try g.draw();
    }

    fn update(g: *Game, dt: f32) void {
        var can_respawn_blocks = false;
        inline for (0..2) |d| {
            if (g.ball_velocity[d] < 0 and g.ball.min[d] <= 0) {
                g.ball_velocity[d] *= -1;
                if (d == 1) {
                    can_respawn_blocks = true;
                }
            }
            if (g.ball_velocity[d] > 0 and g.ball.min[d] + g.ball.size[d] >= total_size[d]) {
                g.ball_velocity[d] *= -1;
            }
        }

        for (0..2) |d| {
            g.ball.min[d] += g.ball_velocity[d] * dt;
        }

        {
            const paddle_speed = 200;
            if (g.buttons.contains(.left)) {
                g.paddle.min[0] -= dt * paddle_speed;
            }
            if (g.buttons.contains(.right)) {
                g.paddle.min[0] += dt * paddle_speed;
            }

            // Also corrects mouse movement going out of bounds.
            if (g.paddle.min[0] < 0) {
                g.paddle.min[0] = 0;
            }
            const right_max = total_size[0] - g.paddle.size[0];
            if (g.paddle.min[0] > right_max) {
                g.paddle.min[0] = right_max;
            }
        }

        for (0..num_blocks[0]) |x| {
            for (0..num_blocks[1]) |y| {
                const i = x + y * num_blocks[0];
                if (g.blocks[i] and blockBounds(.{ x, y }).overlap(g.ball)) {
                    g.blocks[i] = false;
                    g.ball_velocity[1] *= -1;
                }
            }
        }

        if (g.paddle.overlap(g.ball) and g.ball_velocity[1] > 0) {
            g.ball_velocity[1] *= -1;
            const ball_center = g.ball.min[0] + (g.ball.size[0] / 2);
            const paddle_center = g.paddle.min[0] + (g.paddle.size[0] / 2);
            const horizontal_scale_factor = 5;
            g.ball_velocity[0] = (ball_center - paddle_center) * horizontal_scale_factor;
            can_respawn_blocks = true;
        }

        if (can_respawn_blocks) {
            for (0..num_blocks[0] * num_blocks[1]) |i| {
                if (g.blocks[i]) {
                    break;
                }
            } else {
                for (0..num_blocks[0] * num_blocks[1]) |i| {
                    g.blocks[i] = true;
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

        g.draw_rectangles.append(g.paddle) catch unreachable;
        g.draw_rectangles.append(g.ball) catch unreachable;
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
