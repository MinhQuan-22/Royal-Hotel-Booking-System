using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Background service to automatically delete chat messages daily
/// Requirement: Delete all messages from previous days every day at 3 AM
/// 
/// This service runs daily to delete all chat messages that were created before today.
/// Conversations are preserved, only messages are deleted.
/// </summary>
public class MessageCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<MessageCleanupService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromHours(24); // Run daily

    public MessageCleanupService(
        IServiceProvider serviceProvider,
        ILogger<MessageCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    /// <summary>
    /// Main execution loop - runs daily at 3 AM
    /// </summary>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("MessageCleanupService started");

        // Wait for initial delay (run at 3 AM daily)
        await WaitForNextScheduledRun(stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await DeleteOldMessagesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in MessageCleanupService execution");
            }

            // Wait for next scheduled run (24 hours)
            await Task.Delay(_checkInterval, stoppingToken);
        }

        _logger.LogInformation("MessageCleanupService stopped");
    }

    /// <summary>
    /// Wait until 3 AM for the first run
    /// </summary>
    private async Task WaitForNextScheduledRun(CancellationToken stoppingToken)
    {
        var now = DateTime.UtcNow;
        var nextRun = now.Date.AddHours(3); // 3 AM UTC

        // If it's already past 3 AM today, schedule for 3 AM tomorrow
        if (now.Hour >= 3)
        {
            nextRun = nextRun.AddDays(1);
        }

        var delay = nextRun - now;

        _logger.LogInformation(
            "MessageCleanupService scheduled to run at {NextRun} UTC (in {DelayHours:F2} hours)",
            nextRun, delay.TotalHours);

        if (delay.TotalMilliseconds > 0)
        {
            await Task.Delay(delay, stoppingToken);
        }
    }

    /// <summary>
    /// Delete all messages created before today
    /// Requirement: Delete all messages from previous days
    /// </summary>
    public async Task<CleanupResult> DeleteOldMessagesAsync(CancellationToken stoppingToken = default)
    {
        var startTime = DateTime.UtcNow;
        _logger.LogInformation("Starting daily message cleanup");

        var result = new CleanupResult
        {
            ExecutionTime = startTime
        };

        try
        {
            // Create a scope to get scoped services (DbContext)
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<RoyalHotelDbContext>();

            // Calculate cutoff date (start of today in UTC)
            var todayStart = DateTime.UtcNow.Date;

            _logger.LogInformation(
                "Querying messages with CreatedAt < {TodayStart} (before today)",
                todayStart);

            // Query messages created before today
            var oldMessages = await dbContext.ChatMessages
                .Where(m => m.CreatedAt < todayStart)
                .ToListAsync(stoppingToken);

            result.MessagesFound = oldMessages.Count;

            _logger.LogInformation(
                "Found {Count} messages to delete (created before {TodayStart})",
                oldMessages.Count,
                todayStart);

            if (oldMessages.Count == 0)
            {
                result.Success = true;
                result.Message = "No old messages found to delete";
                return result;
            }

            // Delete messages
            dbContext.ChatMessages.RemoveRange(oldMessages);

            // Save changes
            var deletedCount = await dbContext.SaveChangesAsync(stoppingToken);

            result.MessagesDeleted = oldMessages.Count;
            result.Success = true;
            result.Message = $"Successfully deleted {result.MessagesDeleted} messages";

            _logger.LogInformation(
                "Message cleanup completed: {Deleted} messages deleted, {Changes} changes saved",
                result.MessagesDeleted,
                deletedCount);

            // Log performance metrics
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;
            _logger.LogInformation(
                "Message cleanup execution completed in {DurationMs}ms",
                duration);

            return result;
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message = $"Message cleanup failed: {ex.Message}";

            _logger.LogError(ex, "Fatal error during message cleanup execution");

            return result;
        }
    }

    /// <summary>
    /// Manual trigger for testing purposes
    /// </summary>
    public async Task<CleanupResult> TriggerManualCleanupAsync()
    {
        _logger.LogInformation("Manual message cleanup triggered");
        return await DeleteOldMessagesAsync();
    }
}

/// <summary>
/// Result of message cleanup operation
/// </summary>
public class CleanupResult
{
    public DateTime ExecutionTime { get; set; }
    public int MessagesFound { get; set; }
    public int MessagesDeleted { get; set; }
    public bool Success { get; set; }
    public string Message { get; set; } = "";

    public override string ToString()
    {
        return $@"
Message Cleanup Result:
----------------------
Execution Time: {ExecutionTime:yyyy-MM-dd HH:mm:ss} UTC
Messages Found: {MessagesFound}
Messages Deleted: {MessagesDeleted}
Success: {Success}
Message: {Message}
";
    }
}
