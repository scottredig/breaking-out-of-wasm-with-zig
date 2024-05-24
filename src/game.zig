pub const total_size = [2]comptime_int{ 400, 300 };
pub const num_blocks = [2]comptime_int{ 10, 5 };

pub const paddle_size = [2]f32{ 60, 7 };
pub const ball_size = [2]f32{ 10, 10 };

pub const Game = struct {
    blocks: [num_blocks[0] * num_blocks[1]]bool = [_]bool{true} ** (num_blocks[0] * num_blocks[1]),
    paddle_pos: [2]f32 = [2]f32{ (total_size[0] - paddle_size[0]) / 2, total_size[1] - paddle_size[1] - 10 },
    ball_pos: [2]f32 = .{ 0, 0 },
    ball_dir: [2]f32 = .{ 60, 60 },

    pub fn step(g: *Game, dt: f32) void {
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
};

pub const Bounds = struct {
    min: [2]f32,
    max: [2]f32,
};

pub fn blockBounds(pos: [2]usize) Bounds {
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
        .max = .{
            block_size[0] * (fpos[0] + 1) - margin,
            block_size[1] * (fpos[1] + 1) - margin + block_h_start,
        },
    };
}
