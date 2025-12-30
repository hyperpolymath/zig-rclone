// SPDX-License-Identifier: AGPL-3.0-or-later
//! Example: Sync between remotes

const std = @import("std");
const rclone = @import("rclone");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize rclone runtime
    try rclone.init();
    defer rclone.deinit();

    // Stream transfer between clouds without temp files
    var reader = try rclone.Remote.openRead(allocator, "dropbox:documents/report.pdf");
    defer reader.close();

    var writer = try rclone.Remote.openWrite(allocator, "gdrive:backup/report.pdf");
    defer writer.close();

    // Stream with backpressure
    try rclone.stream(reader, writer, .{
        .buffer_size = 64 * 1024 * 1024, // 64MB
        .parallel_streams = 32,
    });

    std.debug.print("Sync complete!\n", .{});
}
