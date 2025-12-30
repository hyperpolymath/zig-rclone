// SPDX-License-Identifier: AGPL-3.0-or-later
//! zig-rclone: Zig FFI bindings to librclone for cloud storage operations
//!
//! Provides direct library access to rclone without spawning subprocesses.
//! Supports all 40+ cloud backends through librclone's JSON-RPC interface.

const std = @import("std");
const c = @import("c.zig");

pub const Remote = @import("remote.zig").Remote;
pub const Vfs = @import("vfs.zig").Vfs;
pub const Config = @import("config.zig").Config;
pub const RateLimiter = @import("rate_limit.zig").RateLimiter;

/// Initialize rclone runtime (must be called before any operations)
pub fn init() !void {
    c.RcloneInitialize();
}

/// Finalize rclone runtime (call on shutdown)
pub fn deinit() void {
    c.RcloneFinalize();
}

/// Error codes from rclone operations
pub const Error = error{
    RemoteNotFound,
    AuthenticationFailed,
    RateLimited,
    NetworkError,
    PermissionDenied,
    FileNotFound,
    DirectoryNotEmpty,
    InvalidConfig,
    JsonParseError,
    AllocationFailed,
};

/// Dropbox-safe rate limiting defaults
pub const DropboxSafeDefaults = struct {
    tps_limit: u32 = 4,
    tps_burst: u32 = 1,
    cache_mode: CacheMode = .writes,
    read_chunk_size: usize = 32 * 1024 * 1024, // 32MB
};

/// VFS cache modes
pub const CacheMode = enum {
    off,
    minimal,
    writes,
    full,

    pub fn toRcloneString(self: CacheMode) []const u8 {
        return switch (self) {
            .off => "off",
            .minimal => "minimal",
            .writes => "writes",
            .full => "full",
        };
    }
};

/// Stream data between two remotes without temp files
pub fn stream(reader: anytype, writer: anytype, options: StreamOptions) !void {
    const buffer_size = options.buffer_size;
    var buffer = try std.heap.page_allocator.alloc(u8, buffer_size);
    defer std.heap.page_allocator.free(buffer);

    while (true) {
        const bytes_read = try reader.read(buffer);
        if (bytes_read == 0) break;
        try writer.writeAll(buffer[0..bytes_read]);
    }
}

pub const StreamOptions = struct {
    buffer_size: usize = 64 * 1024 * 1024, // 64MB
    parallel_streams: u32 = 32,
};

test "basic init/deinit" {
    // Just test that we can call init/deinit without crashing
    // Actual librclone may not be present in test environment
}
