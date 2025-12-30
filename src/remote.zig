// SPDX-License-Identifier: AGPL-3.0-or-later
//! Remote operations for cloud storage backends

const std = @import("std");
const c = @import("c.zig");
const Error = @import("main.zig").Error;
const RateLimiter = @import("rate_limit.zig").RateLimiter;

/// Handle to a remote storage backend
pub const Remote = struct {
    name: []const u8,
    allocator: std.mem.Allocator,
    rate_limiter: ?*RateLimiter,

    /// Open a remote by name (e.g., "dropbox:", "gdrive:path/to/folder")
    pub fn open(allocator: std.mem.Allocator, name: []const u8) !Remote {
        return .{
            .name = try allocator.dupe(u8, name),
            .allocator = allocator,
            .rate_limiter = null,
        };
    }

    /// Open a remote with rate limiting
    pub fn openWithRateLimit(allocator: std.mem.Allocator, name: []const u8, limiter: *RateLimiter) !Remote {
        var remote = try open(allocator, name);
        remote.rate_limiter = limiter;
        return remote;
    }

    /// Close the remote handle
    pub fn close(self: *Remote) void {
        self.allocator.free(self.name);
    }

    /// List directory contents
    pub fn list(self: *Remote, path: []const u8, options: ListOptions) !DirIterator {
        if (self.rate_limiter) |rl| {
            try rl.acquire();
        }

        const request = try std.json.stringifyAlloc(self.allocator, .{
            .fs = self.name,
            .remote = path,
            .opt = .{
                .recurse = options.recurse,
            },
        }, .{});
        defer self.allocator.free(request);

        const response = try c.rpc(self.allocator, "operations/list", request);

        return DirIterator{
            .data = response,
            .allocator = self.allocator,
            .index = 0,
        };
    }

    /// Read file contents
    pub fn read(self: *Remote, path: []const u8, buf: []u8, offset: u64) !usize {
        if (self.rate_limiter) |rl| {
            try rl.acquire();
        }

        _ = path;
        _ = buf;
        _ = offset;
        // TODO: Implement via rclone cat operation
        return 0;
    }

    /// Write file contents
    pub fn write(self: *Remote, path: []const u8, data: []const u8, offset: u64) !usize {
        if (self.rate_limiter) |rl| {
            try rl.acquire();
        }

        _ = path;
        _ = data;
        _ = offset;
        // TODO: Implement via rclone rcat operation
        return 0;
    }

    /// Open a file for reading (streaming)
    pub fn openRead(allocator: std.mem.Allocator, remote_path: []const u8) !Reader {
        return Reader{
            .path = try allocator.dupe(u8, remote_path),
            .allocator = allocator,
        };
    }

    /// Open a file for writing (streaming)
    pub fn openWrite(allocator: std.mem.Allocator, remote_path: []const u8) !Writer {
        return Writer{
            .path = try allocator.dupe(u8, remote_path),
            .allocator = allocator,
        };
    }
};

pub const ListOptions = struct {
    tps_limit: u32 = 4,
    tps_burst: u32 = 1,
    recurse: bool = false,
};

pub const DirEntry = struct {
    name: []const u8,
    size: u64,
    is_dir: bool,
    mod_time: i64,
};

pub const DirIterator = struct {
    data: []const u8,
    allocator: std.mem.Allocator,
    index: usize,

    pub fn next(self: *DirIterator) ?DirEntry {
        _ = self;
        // TODO: Parse JSON response
        return null;
    }

    pub fn deinit(self: *DirIterator) void {
        self.allocator.free(self.data);
    }
};

pub const Reader = struct {
    path: []const u8,
    allocator: std.mem.Allocator,

    pub fn read(self: *Reader, buf: []u8) !usize {
        _ = self;
        _ = buf;
        return 0;
    }

    pub fn close(self: *Reader) void {
        self.allocator.free(self.path);
    }
};

pub const Writer = struct {
    path: []const u8,
    allocator: std.mem.Allocator,

    pub fn writeAll(self: *Writer, data: []const u8) !void {
        _ = self;
        _ = data;
    }

    pub fn close(self: *Writer) void {
        self.allocator.free(self.path);
    }
};
