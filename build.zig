const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // SDL Zig dependency not used when dynamically linking
    // const sdl_dep = b.dependency("sdl", .{
    //     .optimize = .ReleaseFast,
    //     .target = target,
    // });

    const obj = b.addObject(.{
        .name = "roc-sdl",
        .root_source_file = .{ .path = "platform/host.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    obj.force_pic = true;
    obj.disable_stack_probing = true;
    obj.linkSystemLibrary("SDL2");

    const install_obj = b.addInstallFile(obj.getEmittedBin(), "host.o");
    b.default_step.dependOn(&install_obj.step);
}
