using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using System.Security.Claims;

namespace ROYALHOTEL.Middleware
{
    /// <summary>
    /// Manual test runner for RateLimiterMiddleware.
    /// Run this file to verify rate limiting behavior.
    /// </summary>
    public class RateLimiterMiddlewareTest
    {
        public static async Task Main(string[] args)
        {
            Console.WriteLine("=== RateLimiterMiddleware Test ===\n");

            await TestIpRateLimit();
            await TestUserRateLimit();
            await TestNonChatEndpoint();

            Console.WriteLine("\n=== All Tests Completed ===");
        }

        /// <summary>
        /// Test 1: IP-based rate limiting (20 requests per minute)
        /// </summary>
        private static async Task TestIpRateLimit()
        {
            Console.WriteLine("Test 1: IP-based rate limiting (20 req/min)");
            Console.WriteLine("--------------------------------------------");

            var cache = new MemoryCache(new MemoryCacheOptions());
            var logger = LoggerFactory.Create(builder => builder.AddConsole())
                .CreateLogger<RateLimiterMiddleware>();

            var middleware = new RateLimiterMiddleware(
                next: (context) => Task.CompletedTask,
                cache: cache,
                logger: logger
            );

            var ipAddress = "192.168.1.100";
            int successCount = 0;
            int blockedCount = 0;

            // Send 25 requests from the same IP
            for (int i = 1; i <= 25; i++)
            {
                var context = CreateHttpContext("/api/chat/send", ipAddress, userId: null);
                await middleware.InvokeAsync(context);

                if (context.Response.StatusCode == 200)
                {
                    successCount++;
                    Console.WriteLine($"  Request {i}: ✓ Allowed (200)");
                }
                else if (context.Response.StatusCode == 429)
                {
                    blockedCount++;
                    Console.WriteLine($"  Request {i}: ✗ Blocked (429)");
                }
            }

            Console.WriteLine($"\nResult: {successCount} allowed, {blockedCount} blocked");
            Console.WriteLine($"Expected: 20 allowed, 5 blocked");
            Console.WriteLine($"Status: {(successCount == 20 && blockedCount == 5 ? "✓ PASS" : "✗ FAIL")}\n");
        }

        /// <summary>
        /// Test 2: User-based rate limiting (30 requests per minute for authenticated users)
        /// </summary>
        private static async Task TestUserRateLimit()
        {
            Console.WriteLine("Test 2: User-based rate limiting (30 req/min for authenticated users)");
            Console.WriteLine("-----------------------------------------------------------------------");

            var cache = new MemoryCache(new MemoryCacheOptions());
            var logger = LoggerFactory.Create(builder => builder.AddConsole())
                .CreateLogger<RateLimiterMiddleware>();

            var middleware = new RateLimiterMiddleware(
                next: (context) => Task.CompletedTask,
                cache: cache,
                logger: logger
            );

            var ipAddress = "192.168.1.200";
            var userId = "user123";
            int successCount = 0;
            int blockedCount = 0;

            // Send 35 requests from authenticated user
            for (int i = 1; i <= 35; i++)
            {
                var context = CreateHttpContext("/api/chat/send", ipAddress, userId);
                await middleware.InvokeAsync(context);

                if (context.Response.StatusCode == 200)
                {
                    successCount++;
                    if (i <= 5 || i > 30)
                    {
                        Console.WriteLine($"  Request {i}: ✓ Allowed (200)");
                    }
                }
                else if (context.Response.StatusCode == 429)
                {
                    blockedCount++;
                    if (i <= 35)
                    {
                        Console.WriteLine($"  Request {i}: ✗ Blocked (429)");
                    }
                }
            }

            Console.WriteLine($"\nResult: {successCount} allowed, {blockedCount} blocked");
            Console.WriteLine($"Expected: 30 allowed, 5 blocked");
            Console.WriteLine($"Status: {(successCount == 30 && blockedCount == 5 ? "✓ PASS" : "✗ FAIL")}\n");
        }

        /// <summary>
        /// Test 3: Non-chat endpoints should not be rate limited
        /// </summary>
        private static async Task TestNonChatEndpoint()
        {
            Console.WriteLine("Test 3: Non-chat endpoints bypass rate limiting");
            Console.WriteLine("------------------------------------------------");

            var cache = new MemoryCache(new MemoryCacheOptions());
            var logger = LoggerFactory.Create(builder => builder.AddConsole())
                .CreateLogger<RateLimiterMiddleware>();

            var middleware = new RateLimiterMiddleware(
                next: (context) => Task.CompletedTask,
                cache: cache,
                logger: logger
            );

            var ipAddress = "192.168.1.300";
            int successCount = 0;

            // Send 30 requests to non-chat endpoint
            for (int i = 1; i <= 30; i++)
            {
                var context = CreateHttpContext("/api/rooms", ipAddress, userId: null);
                await middleware.InvokeAsync(context);

                if (context.Response.StatusCode == 200)
                {
                    successCount++;
                }
            }

            Console.WriteLine($"  Sent 30 requests to /api/rooms");
            Console.WriteLine($"\nResult: {successCount} allowed, 0 blocked");
            Console.WriteLine($"Expected: 30 allowed, 0 blocked");
            Console.WriteLine($"Status: {(successCount == 30 ? "✓ PASS" : "✗ FAIL")}\n");
        }

        /// <summary>
        /// Helper method to create a mock HttpContext for testing
        /// </summary>
        private static HttpContext CreateHttpContext(string path, string ipAddress, string? userId)
        {
            var context = new DefaultHttpContext();
            context.Request.Path = path;
            context.Connection.RemoteIpAddress = System.Net.IPAddress.Parse(ipAddress);

            // Set up authenticated user if userId is provided
            if (!string.IsNullOrEmpty(userId))
            {
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, userId),
                    new Claim(ClaimTypes.Name, $"User_{userId}")
                };
                var identity = new ClaimsIdentity(claims, "TestAuth");
                context.User = new ClaimsPrincipal(identity);
            }

            return context;
        }
    }
}
