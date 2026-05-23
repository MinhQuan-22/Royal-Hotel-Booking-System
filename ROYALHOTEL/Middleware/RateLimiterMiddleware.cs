using Microsoft.Extensions.Caching.Memory;
using System.Security.Claims;

namespace ROYALHOTEL.Middleware
{
    /// <summary>
    /// Middleware that implements rate limiting for chat API endpoints.
    /// Limits requests per IP address (20/min) and per authenticated user (30/min).
    /// Returns HTTP 429 when limits are exceeded.
    /// </summary>
    public class RateLimiterMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IMemoryCache _cache;
        private readonly ILogger<RateLimiterMiddleware> _logger;

        // Rate limit configuration
        private const int IpLimitPerMinute = 20;
        private const int UserLimitPerMinute = 30;
        private const int WindowSeconds = 60;

        // P1-2: Admin polling endpoints (higher limits since they poll frequently)
        private const int AdminPollIpLimitPerMinute = 60;

        public RateLimiterMiddleware(
            RequestDelegate next,
            IMemoryCache cache,
            ILogger<RateLimiterMiddleware> logger)
        {
            _next = next;
            _cache = cache;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Apply rate limiting to chat API endpoints
            bool isChatApi = context.Request.Path.StartsWithSegments("/api/chat");

            // P1-2 Fix: Also apply (lighter) rate limiting to AdminChat polling endpoints
            bool isAdminPoll = context.Request.Path.StartsWithSegments("/AdminChat/PollNewMessages")
                            || context.Request.Path.StartsWithSegments("/AdminChat/PollNewConversations")
                            || context.Request.Path.StartsWithSegments("/AdminChat/PollAdminReplies");

            if (!isChatApi && !isAdminPoll)
            {
                await _next(context);
                return;
            }

            var ipAddress = GetClientIpAddress(context);
            var userId = GetUserId(context);

            // Check rate limits
            if (!await CheckRateLimitAsync(ipAddress, userId, context, isAdminPoll))
            {
                context.Response.StatusCode = 429;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new
                {
                    success = false,
                    error = "Quá nhiều yêu cầu, vui lòng thử lại sau",
                    message = "Rate limit exceeded"
                });
                return;
            }

            await _next(context);
        }

        /// <summary>
        /// Checks if the request is within rate limits for both IP and user.
        /// Uses sliding window algorithm with IMemoryCache.
        /// isAdminPoll: uses higher limit (60/min) for polling endpoints.
        /// </summary>
        private async Task<bool> CheckRateLimitAsync(string ipAddress, string? userId, HttpContext context, bool isAdminPoll = false)
        {
            // P1-2: Use different limits for admin polling vs regular chat API
            int effectiveIpLimit = isAdminPoll ? AdminPollIpLimitPerMinute : IpLimitPerMinute;

            // Check IP-based rate limit (applies to all requests)
            var ipKey = $"ratelimit:{(isAdminPoll ? "admin" : "chat")}:ip:{ipAddress}";
            var ipCount = await GetRequestCountAsync(ipKey);

            if (ipCount >= effectiveIpLimit)
            {
                _logger.LogWarning(
                    "Rate limit exceeded for IP: {IpAddress}. Count: {Count}. Path: {Path}",
                    ipAddress, ipCount, context.Request.Path);
                return false;
            }

            // Check user-based rate limit (applies to authenticated users, only for chat API not polling)
            if (!isAdminPoll && !string.IsNullOrEmpty(userId))
            {
                var userKey = $"ratelimit:chat:user:{userId}";
                var userCount = await GetRequestCountAsync(userKey);

                if (userCount >= UserLimitPerMinute)
                {
                    _logger.LogWarning(
                        "Rate limit exceeded for User: {UserId}. Count: {Count}. Path: {Path}",
                        userId, userCount, context.Request.Path);
                    return false;
                }

                // Increment user counter
                await IncrementRequestCountAsync(userKey);
            }

            // Increment IP counter
            await IncrementRequestCountAsync(ipKey);

            return true;
        }

        /// <summary>
        /// Gets the current request count for a given cache key.
        /// </summary>
        private Task<int> GetRequestCountAsync(string cacheKey)
        {
            if (_cache.TryGetValue(cacheKey, out int count))
            {
                return Task.FromResult(count);
            }
            return Task.FromResult(0);
        }

        /// <summary>
        /// Increments the request count for a given cache key.
        /// Creates a new entry with sliding expiration if it doesn't exist.
        /// </summary>
        private Task IncrementRequestCountAsync(string cacheKey)
        {
            var count = _cache.GetOrCreate(cacheKey, entry =>
            {
                // Set sliding expiration to reset counter after the window
                entry.SlidingExpiration = TimeSpan.FromSeconds(WindowSeconds);
                return 0;
            });

            _cache.Set(cacheKey, count + 1, new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromSeconds(WindowSeconds)
            });

            return Task.CompletedTask;
        }

        /// <summary>
        /// Extracts the client IP address from the HTTP context.
        /// Checks X-Forwarded-For header first (for proxied requests), then RemoteIpAddress.
        /// </summary>
        private string GetClientIpAddress(HttpContext context)
        {
            // Check for X-Forwarded-For header (common in load balancers/proxies)
            var forwardedFor = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
            if (!string.IsNullOrEmpty(forwardedFor))
            {
                // Take the first IP if multiple are present
                var ips = forwardedFor.Split(',', StringSplitOptions.RemoveEmptyEntries);
                if (ips.Length > 0)
                {
                    return ips[0].Trim();
                }
            }

            // Fallback to RemoteIpAddress
            return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        }

        /// <summary>
        /// Extracts the user ID from the authenticated user claims.
        /// Returns null if the user is not authenticated.
        /// </summary>
        private string? GetUserId(HttpContext context)
        {
            if (context.User?.Identity?.IsAuthenticated == true)
            {
                // Try to get user ID from NameIdentifier claim
                var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (!string.IsNullOrEmpty(userIdClaim))
                {
                    return userIdClaim;
                }

                // Fallback to Name claim if NameIdentifier is not present
                return context.User.FindFirst(ClaimTypes.Name)?.Value;
            }

            return null;
        }
    }
}
