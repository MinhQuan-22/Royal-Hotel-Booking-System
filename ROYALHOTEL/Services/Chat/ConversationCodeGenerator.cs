using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Service for generating unique conversation codes in format CHAT-YYYYMMDD-XXXXX
/// Thread-safe implementation that handles concurrent conversation creation
/// </summary>
public class ConversationCodeGenerator
{
    private readonly RoyalHotelDbContext _dbContext;
    private static readonly SemaphoreSlim _semaphore = new SemaphoreSlim(1, 1);

    public ConversationCodeGenerator(RoyalHotelDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Generates a unique conversation code in format CHAT-YYYYMMDD-XXXXX
    /// This method is thread-safe and handles concurrent requests
    /// </summary>
    /// <returns>A unique conversation code</returns>
    public async Task<string> GenerateCodeAsync()
    {
        // Use semaphore to ensure only one thread generates a code at a time
        // This prevents race conditions when multiple threads try to generate codes simultaneously
        await _semaphore.WaitAsync();
        try
        {
            var today = DateTime.UtcNow.Date;
            var datePrefix = $"CHAT-{today:yyyyMMdd}";

            // Query database for existing codes on the same day
            // Use a transaction to ensure consistency
            var existingCodes = await _dbContext.ChatConversations
                .Where(c => c.ConversationCode.StartsWith(datePrefix))
                .Select(c => c.ConversationCode)
                .ToListAsync();

            // Find the highest counter for today
            int maxCounter = 0;
            foreach (var code in existingCodes)
            {
                // Extract the counter part (last 5 digits)
                var parts = code.Split('-');
                if (parts.Length == 3 && int.TryParse(parts[2], out int counter))
                {
                    if (counter > maxCounter)
                    {
                        maxCounter = counter;
                    }
                }
            }

            // Increment counter and format with leading zeros
            int newCounter = maxCounter + 1;
            string conversationCode = $"{datePrefix}-{newCounter:D5}";

            return conversationCode;
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
