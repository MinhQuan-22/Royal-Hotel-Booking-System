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
    /// Delete messages from CLOSED conversations only.
    /// P5-Fix: Previously deleted ALL old messages regardless of conversation status,
    /// which would destroy context for Open/EscalatedToAdmin conversations.
    /// Now only cleans up messages from conversations that are fully Closed.
    /// </summary>
    public async Task<CleanupResult> DeleteOldMessagesAsync(CancellationToken stoppingToken = default)
    {
        var startTime = DateTime.UtcNow;
        _logger.LogInformation("Starting daily message cleanup (Closed conversations only)");

        var result = new CleanupResult
        {
            ExecutionTime = startTime
        };

        try
        {
            // Create a scope to get scoped services (DbContext)
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<RoyalHotelDbContext>();

            // Calculate cutoff date: only delete messages from conversations closed
            // more than 7 days ago to give admin time to review if needed
            var cutoffDate = DateTime.UtcNow.AddDays(-7);

            _logger.LogInformation(
                "Querying messages from Closed conversations updated before {CutoffDate}",
                cutoffDate);

            // P5-Fix: Get IDs of conversations that are fully Closed AND older than 7 days
            var closedConversationIds = await dbContext.ChatConversations
                .Where(c => c.Status == "Closed" && c.UpdatedAt < cutoffDate)
                .Select(c => c.Id)
                .ToListAsync(stoppingToken);

            if (!closedConversationIds.Any())
            {
                result.Success = true;
                result.MessagesFound = 0;
                result.MessagesDeleted = 0;
                result.Message = "No closed conversations eligible for cleanup";

                _logger.LogInformation("Message cleanup: no eligible closed conversations found");
                return result;
            }

            _logger.LogInformation(
                "Found {ConvCount} closed conversations eligible for message cleanup",
                closedConversationIds.Count);

            // Query messages that belong to those closed conversations
            var oldMessages = await dbContext.ChatMessages
                .Where(m => closedConversationIds.Contains(m.ConversationId))
                .ToListAsync(stoppingToken);

            result.MessagesFound = oldMessages.Count;

            _logger.LogInformation(
                "Found {Count} messages to delete from {ConvCount} closed conversations",
                oldMessages.Count, closedConversationIds.Count);

            if (oldMessages.Count == 0)
            {
                result.Success = true;
                result.Message = "No messages found in closed conversations";
                return result;
            }

            // Delete messages in batches of 500 to avoid large transactions
            const int batchSize = 500;
            int totalDeleted = 0;

            for (int i = 0; i < oldMessages.Count; i += batchSize)
            {
                var batch = oldMessages.Skip(i).Take(batchSize).ToList();
                dbContext.ChatMessages.RemoveRange(batch);
                await dbContext.SaveChangesAsync(stoppingToken);
                totalDeleted += batch.Count;

                _logger.LogInformation(
                    "Message cleanup batch: deleted {BatchCount} messages ({Total}/{Total2} total)",
                    batch.Count, totalDeleted, oldMessages.Count);
            }

            result.MessagesDeleted = totalDeleted;
            result.Success = true;
            result.Message = $"Successfully deleted {result.MessagesDeleted} messages from {closedConversationIds.Count} closed conversations";

            // Log performance metrics
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;
            _logger.LogInformation(
                "Message cleanup completed: {Deleted} messages deleted in {DurationMs}ms",
                result.MessagesDeleted, duration);

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
