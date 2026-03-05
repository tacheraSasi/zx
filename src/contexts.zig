const std = @import("std");

const Request = @import("runtime/core/Request.zig");
const Response = @import("runtime/core/Response.zig");

/// Context passed to proxy middleware functions.
/// Use `state.set()` to pass typed data to downstream route/page handlers.
pub const ProxyContext = struct {
    request: Request,
    response: Response,
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,

    //TODO: move these to single _inner ptr
    _aborted: bool = false,
    _state_ptr: ?*const anyopaque = null,

    pub fn init(request: Request, response: Response, allocator: std.mem.Allocator, arena: std.mem.Allocator) ProxyContext {
        return .{
            .request = request,
            .response = response,
            .allocator = allocator,
            .arena = arena,
        };
    }

    /// Set typed state data to be passed to downstream route/page handlers.
    /// (e.g., `zx.RouteCtx(AppCtx, MyState)` or `zx.PageCtx(AppCtx, MyState)`).
    pub fn state(self: *ProxyContext, value: anytype) void {
        const T = @TypeOf(value);
        const ptr = self.arena.create(T) catch return;
        ptr.* = value;
        self._state_ptr = @ptrCast(ptr);
    }

    /// Abort the request chain - no further handlers (proxies, page, route) will be called
    /// Use this when the proxy has fully handled the request (e.g., returned an error response)
    pub fn abort(self: *ProxyContext) void {
        self._aborted = true;
    }

    /// Continue to the next handler in the chain
    /// This is a no-op (chain continues by default), but makes intent explicit
    pub fn next(self: *ProxyContext) void {
        _ = self;
        // No-op - chain continues by default unless abort() is called
    }

    /// Check if the request chain was aborted
    pub fn isAborted(self: *const ProxyContext) bool {
        return self._aborted;
    }
};
