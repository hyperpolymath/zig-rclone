// SPDX-License-Identifier: AGPL-3.0-or-later
//! Example: List files from a remote

const std = @import("std");
const rclone = @import("rclone");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize rclone runtime
    try rclone.init();
    defer rclone.deinit();

    // Open remote with Dropbox-safe rate limiting
    var limiter = rclone.RateLimiter.init(.{
        .tps = 4,
        .burst = 1,
    });

    var remote = try rclone.Remote.openWithRateLimit(allocator, "dropbox:", &limiter);
    defer remote.close();

    // List root directory
    var iter = try remote.list("/", .{
        .tps_limit = 4,
        .tps_burst = 1,
    });
    defer iter.deinit();

    std.debug.print("Files in dropbox:/\n", .{});
    std.debug.print("-------------------\n", .{});

    while (iter.next()) |entry| {
        const type_char: u8 = if (entry.is_dir) 'd' else '-';
        std.debug.print("{c} {d:>12} {s}\n", .{ type_char, entry.size, entry.name });
    }
}
