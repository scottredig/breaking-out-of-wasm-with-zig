const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const dir = std.Build.InstallDir.bin;

    const zjb = b.dependency("zjb", .{});

    const breakout = b.addExecutable(.{
        .name = "breakout",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
        .optimize = optimize,
    });
    breakout.root_module.addImport("zjb", zjb.module("zjb"));
    breakout.entry = .disabled;
    breakout.rdynamic = true;

    const extract_breakout = b.addRunArtifact(zjb.artifact("generate_js"));
    const extract_breakout_out = extract_breakout.addOutputFileArg("zjb_extract.js");
    extract_breakout.addArg("Zjb"); // Name of js class.
    extract_breakout.addArtifactArg(breakout);

    const breakout_step = b.step("breakout", "Build the end to end breakout");

    breakout_step.dependOn(&b.addInstallArtifact(breakout, .{
        .dest_dir = .{ .override = dir },
    }).step);
    breakout_step.dependOn(&b.addInstallFileWithDir(extract_breakout_out, dir, "zjb_extract.js").step);

    breakout_step.dependOn(&b.addInstallDirectory(.{
        .source_dir = .{ .path = "static" },
        .install_dir = dir,
        .install_subdir = "",
    }).step);
}
