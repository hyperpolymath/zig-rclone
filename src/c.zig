// SPDX-License-Identifier: AGPL-3.0-or-later
//! Raw C bindings to librclone via @cImport
//!
//! librclone uses JSON-RPC over C strings for all operations.
//! This module wraps the low-level RcloneRPC function.

const std = @import("std");

// librclone C interface
pub const RcloneRPCResult = extern struct {
    Output: [*:0]u8,
    Status: c_int,
};

pub extern fn RcloneRPC(method: [*:0]const u8, input: [*:0]const u8) RcloneRPCResult;
pub extern fn RcloneInitialize() void;
pub extern fn RcloneFinalize() void;
pub extern fn RcloneFreeString(str: [*:0]u8) void;

/// Execute an rclone RPC command and return the result
pub fn rpc(allocator: std.mem.Allocator, method: []const u8, input: []const u8) ![]const u8 {
    const method_z = try allocator.dupeZ(u8, method);
    defer allocator.free(method_z);

    const input_z = try allocator.dupeZ(u8, input);
    defer allocator.free(input_z);

    const result = RcloneRPC(method_z, input_z);
    defer RcloneFreeString(result.Output);

    if (result.Status != 0) {
        return error.RpcFailed;
    }

    const output_len = std.mem.len(result.Output);
    const output = try allocator.alloc(u8, output_len);
    @memcpy(output, result.Output[0..output_len]);

    return output;
}
