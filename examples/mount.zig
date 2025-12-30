// SPDX-License-Identifier: AGPL-3.0-or-later
//! Example: VFS mount

const std = @import("std");
const rclone = @import("rclone");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize rclone runtime
    try rclone.init();
    defer rclone.deinit();

    // Mount with Dropbox-safe defaults
    var mount = try rclone.Vfs.mount(allocator, "dropbox:", "/mnt/dropbox", .{
        .cache_mode = .writes, // Dropbox-safe default
        .read_chunk_size = 32 * 1024 * 1024, // 32MB
        .cache_max_age = 72 * std.time.ns_per_hour,
    });
    defer mount.unmount();

    std.debug.print("Mounted dropbox: at /mnt/dropbox\n", .{});
    std.debug.print("Press Ctrl+C to unmount.\n", .{});

    // Keep running
    while (true) {
        std.time.sleep(std.time.ns_per_s);
    }
}
