const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    run(allocator) catch |err| {
        std.debug.print("{}", .{err});
    };
}

fn run(allocator: std.mem.Allocator) !void {
    // const path = "/home/n/test";
    const path = "/home/n/code/zig-rando-project";
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();
    std.debug.print("{s}\n", .{path});
    var tree_states = [_]bool{false} ** 128;
    try pprint_dir(allocator, dir, 0, &tree_states);
}

fn pprint_dir(allocator: std.mem.Allocator, dir: std.fs.Dir, depth: usize, last_item_printed: *[128]bool) !void {
    var it = dir.iterateAssumeFirstIteration();
    var list = std.ArrayList(std.fs.Dir.Entry).init(allocator);

    while (try it.next()) |file| {
        // std.debug.print("{d} {s}\n", .{ depth, file.name });
        try list.append(file);
        // if (file.kind == .directory) {
        // }
    }
    std.sort.heap(std.fs.Dir.Entry, list.items, {}, cmpFile);

    for (list.items, 1..) |file, i| {
        for (0..depth) |current_depth| {
            const ch = if (last_item_printed[current_depth]) " " else "│";
            std.debug.print("{s}   ", .{ch});
        }

        const ch = if (list.items.len == i) blk: {
            last_item_printed[depth] = true;
            break :blk "╰";
        } else "├";
        std.debug.print("{s}── {s}\n", .{ ch, file.name });

        if (file.kind == std.fs.Dir.Entry.Kind.directory) {
            var sub_dir = try dir.openDir(file.name, .{ .iterate = true });
            defer sub_dir.close();
            try pprint_dir(allocator, sub_dir, depth + 1, last_item_printed);
        }

        last_item_printed[depth] = false;
    }
}

fn cmpFile(_: void, a: std.fs.Dir.Entry, b: std.fs.Dir.Entry) bool {
    // _ = context;                //
    if (a.kind != b.kind) {
        if (a.kind == std.fs.Dir.Entry.Kind.file) return true;
        if (b.kind == std.fs.Dir.Entry.Kind.file) return false;
    }
    if (std.ascii.lessThanIgnoreCase(a.name, b.name)) {
        return true;
    }
    return false;
}
