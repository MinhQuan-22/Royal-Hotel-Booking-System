using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Background service for Task 12.3: Auto-close inactive conversations
/// Validates: Requirements 20.1, 20.2
/// 
/// This service runs daily to automatically close conversations that have been inactive
/// for more than 7 days. Conversations with Status="Open" or "AnsweredByAdmin" are eligible
/// for auto-closure.
/// </summary>
public class ConversationAutoCloseService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ConversationAutoCloseService> _logger;
    private readonly TimeSpan _checkInterval = TimeSpan.FromHours(24); // Run daily
    private const int InactiveDaysThreshold = 7;

    public ConversationAutoCloseService(
        IServiceProvider serviceProvider,
        ILogger<ConversationAutoCloseService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    /// <summary>
    /// Main execution loop - runs daily
    /// </summary>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ConversationAutoCloseService started");

        // Wait for initial delay (run at 2 AM daily)
        await WaitForNextScheduledRun(stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await AutoCloseInactiveConversationsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ConversationAutoCloseService execution");
            }

            // Wait for next scheduled run (24 hours)
            await Task.Delay(_checkInterval, stoppingToken);
        }

        _logger.LogInformation("ConversationAutoCloseService stopped");
    }

    /// <summary>
    /// Wait until 2 AM for the first run
    /// </summary>
    private async Task WaitForNextScheduledRun(CancellationToken stoppingToken)
    {
        var now = DateTime.UtcNow;
        var nextRun = now.Date.AddHours(2); // 2 AM UTC

        // If it's already past 2 AM today, schedule for 2 AM tomorrow
        if (now.Hour >= 2)
        {
            nextRun = nextRun.AddDays(1);
        }

        var delay = nextRun - now;

        _logger.LogInformation(
            "ConversationAutoCloseService scheduled to run at {NextRun} UTC (in {DelayHours:F2} hours)",
            nextRun, delay.TotalHours);

        if (delay.TotalMilliseconds > 0)
        {
            await Task.Delay(delay, stoppingToken);
        }
    }

    /// <summary>
    /// Auto-close conversations that have been inactive for more than 7 days
    /// Validates: Requirements 20.1, 20.2
    /// </summary>
    public async Task<AutoCloseResult> AutoCloseInactiveConversationsAsync(CancellationToken stoppingToken = default)
    {
        var startTime = DateTime.UtcNow;
        _logger.LogInformation("Starting auto-close of inactive conversations");

        var result = new AutoCloseResult
        {
            ExecutionTime = startTime
        };

        try
        {
            // Create a scope to get scoped services (DbContext)
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<RoyalHotelDbContext>();

            // Calculate cutoff date (7 days ago)
            var cutoffDate = DateTime.UtcNow.AddDays(-InactiveDaysThreshold);

            _logger.LogInformation(
                "Querying conversations with Status='Open' or 'AnsweredByAdmin' and UpdatedAt < {CutoffDate}",
                cutoffDate);

            // Query conversations eligible for auto-closure
            // Requirement 20.1: Status="Open" or "AnsweredByAdmin" and UpdatedAt > 7 days ago
            var inactiveConversations = await dbContext.ChatConversations
                .Where(c => (c.Status == "Open" || c.Status == "AnsweredByAdmin")
                         && c.UpdatedAt < cutoffDate)
                .ToListAsync(stoppingToken);

            result.ConversationsFound = inactiveConversations.Count;

            _logger.LogInformation(
                "Found {Count} inactive conversations to close",
                inactiveConversations.Count);

            if (inactiveConversations.Count == 0)
            {
                result.Success = true;
                result.Message = "No inactive conversations found";
                return result;
            }

            // Update each conversation to Closed status
            foreach (var conversation in inactiveConversations)
            {
                try
                {
                    var previousStatus = conversation.Status;
                    var inactiveDays = (DateTime.UtcNow - conversation.UpdatedAt).Days;

                    // Requirement 20.2: Update Status to "Closed" and UpdatedAt
                    conversation.Status = "Closed";
                    conversation.UpdatedAt = DateTime.UtcNow;

                    result.ConversationsClosed++;

                    _logger.LogInformation(
                        "Auto-closed conversation {ConversationCode} (Id={Id}). " +
                        "Previous status: {PreviousStatus}, Inactive for {InactiveDays} days",
                        conversation.ConversationCode,
                        conversation.Id,
                        previousStatus,
                        inactiveDays);
                }
                catch (Exception ex)
                {
                    result.ConversationsFailed++;
                    _logger.LogError(ex,
                        "Error closing conversation {ConversationCode} (Id={Id})",
                        conversation.ConversationCode,
                        conversation.Id);
                }
            }

            // Save all changes
            var changesSaved = await dbContext.SaveChangesAsync(stoppingToken);

            _logger.LogInformation(
                "Auto-close completed: {Closed} conversations closed, {Failed} failed, {Changes} changes saved",
                result.ConversationsClosed,
                result.ConversationsFailed,
                changesSaved);

            result.Success = result.ConversationsFailed == 0;
            result.Message = result.Success
                ? $"Successfully closed {result.ConversationsClosed} conversations"
                : $"Closed {result.ConversationsClosed} conversations with {result.ConversationsFailed} failures";

            // Log performance metrics
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;
            _logger.LogInformation(
                "Auto-close execution completed in {DurationMs}ms",
                duration);

            return result;
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message = $"Auto-close failed: {ex.Message}";

            _logger.LogError(ex, "Fatal error during auto-close execution");

            return result;
        }
    }

    /// <summary>
    /// Manual trigger for testing purposes
    /// </summary>
    public async Task<AutoCloseResult> TriggerManualCloseAsync()
    {
        _logger.LogInformation("Manual auto-close triggered");
        return await AutoCloseInactiveConversationsAsync();
    }
}

/// <summary>
/// Result of auto-close operation
/// </summary>
public class AutoCloseResult
{
    public DateTime ExecutionTime { get; set; }
    public int ConversationsFound { get; set; }
    public int ConversationsClosed { get; set; }
    public int ConversationsFailed { get; set; }
    public bool Success { get; set; }
    public string Message { get; set; } = "";

    public override string ToString()
    {
        return $@"
Auto-Close Result:
-----------------
Execution Time: {ExecutionTime:yyyy-MM-dd HH:mm:ss} UTC
Conversations Found: {ConversationsFound}
Conversations Closed: {ConversationsClosed}
Conversations Failed: {ConversationsFailed}
Success: {Success}
Message: {Message}
";
    }
}
