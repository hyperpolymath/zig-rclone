// SPDX-License-Identifier: AGPL-3.0-or-later
//! VFS mount operations for cloud storage

const std = @import("std");
const c = @import("c.zig");
const CacheMode = @import("main.zig").CacheMode;

/// VFS mount handle
pub const Vfs = struct {
    remote: []const u8,
    mount_point: []const u8,
    allocator: std.mem.Allocator,

    /// Mount a remote to a local path
    pub fn mount(allocator: std.mem.Allocator, remote: []const u8, mount_point: []const u8, options: MountOptions) !Vfs {
        const request = try std.json.stringifyAlloc(allocator, .{
            .fs = remote,
            .mountPoint = mount_point,
            .mountOpt = .{
                .AllowOther = options.allow_other,
            },
            .vfsOpt = .{
                .CacheMode = options.cache_mode.toRcloneString(),
                .ChunkSize = options.read_chunk_size,
                .CacheMaxAge = @as(i64, @intCast(options.cache_max_age / std.time.ns_per_s)),
            },
        }, .{});
        defer allocator.free(request);

        _ = try c.rpc(allocator, "mount/mount", request);

        return .{
            .remote = try allocator.dupe(u8, remote),
            .mount_point = try allocator.dupe(u8, mount_point),
            .allocator = allocator,
        };
    }

    /// Unmount the VFS
    pub fn unmount(self: *Vfs) void {
        const request = std.json.stringifyAlloc(self.allocator, .{
            .mountPoint = self.mount_point,
        }, .{}) catch return;
        defer self.allocator.free(request);

        _ = c.rpc(self.allocator, "mount/unmount", request) catch {};

        self.allocator.free(self.remote);
        self.allocator.free(self.mount_point);
    }
};

pub const MountOptions = struct {
    cache_mode: CacheMode = .writes,
    read_chunk_size: usize = 32 * 1024 * 1024, // 32MB
    cache_max_age: u64 = 72 * std.time.ns_per_hour,
    allow_other: bool = false,
};
