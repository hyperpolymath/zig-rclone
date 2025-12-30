// SPDX-License-Identifier: AGPL-3.0-or-later
//! rclone configuration management

const std = @import("std");
const c = @import("c.zig");

/// Configuration management for rclone remotes
pub const Config = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Config {
        return .{ .allocator = allocator };
    }

    /// List all configured remotes
    pub fn listRemotes(self: *Config) ![]const []const u8 {
        const response = try c.rpc(self.allocator, "config/listremotes", "{}");
        defer self.allocator.free(response);

        // TODO: Parse JSON response
        return &.{};
    }

    /// Get remote configuration
    pub fn getRemote(self: *Config, name: []const u8) !RemoteConfig {
        const request = try std.json.stringifyAlloc(self.allocator, .{
            .name = name,
        }, .{});
        defer self.allocator.free(request);

        const response = try c.rpc(self.allocator, "config/get", request);
        defer self.allocator.free(response);

        return RemoteConfig{
            .name = try self.allocator.dupe(u8, name),
            .remote_type = "",
            .allocator = self.allocator,
        };
    }

    /// Create a new remote configuration
    pub fn createRemote(self: *Config, name: []const u8, remote_type: []const u8, params: anytype) !void {
        const request = try std.json.stringifyAlloc(self.allocator, .{
            .name = name,
            .type = remote_type,
            .parameters = params,
        }, .{});
        defer self.allocator.free(request);

        _ = try c.rpc(self.allocator, "config/create", request);
    }

    /// Delete a remote configuration
    pub fn deleteRemote(self: *Config, name: []const u8) !void {
        const request = try std.json.stringifyAlloc(self.allocator, .{
            .name = name,
        }, .{});
        defer self.allocator.free(request);

        _ = try c.rpc(self.allocator, "config/delete", request);
    }
};

pub const RemoteConfig = struct {
    name: []const u8,
    remote_type: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *RemoteConfig) void {
        self.allocator.free(self.name);
    }
};
