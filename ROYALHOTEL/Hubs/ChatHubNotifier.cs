using Microsoft.AspNetCore.SignalR;

namespace ROYALHOTEL.Hubs;

/// <summary>
/// P2-2: Notifier service injected into controllers/services to push SignalR events.
/// Decouples hub logic from business logic — controllers call this instead of IHubContext directly.
/// </summary>
public class ChatHubNotifier
{
    private readonly IHubContext<ChatHub> _hub;
    private readonly ILogger<ChatHubNotifier> _logger;

    public ChatHubNotifier(IHubContext<ChatHub> hub, ILogger<ChatHubNotifier> logger)
    {
        _hub = hub;
        _logger = logger;
    }

    /// <summary>
    /// Pushes a new admin reply to all clients watching the conversation.
    /// Received by user chat-widget.js to display admin reply without polling.
    /// </summary>
    public async Task NotifyAdminReplyAsync(int conversationId, string messageText, DateTime createdAt)
    {
        try
        {
            await _hub.Clients
                .Group($"conversation_{conversationId}")
                .SendAsync("AdminReply", new
                {
                    conversationId,
                    messageText,
                    createdAt = createdAt.ToString("o"),
                    senderType = "Admin"
                });

            _logger.LogDebug("SignalR: AdminReply pushed to conversation_{ConvId}", conversationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SignalR: Failed to push AdminReply to conversation_{ConvId}", conversationId);
        }
    }

    /// <summary>
    /// Notifies all admin clients that a conversation was closed.
    /// </summary>
    public async Task NotifyConversationClosedAsync(int conversationId)
    {
        try
        {
            await _hub.Clients
                .Group($"conversation_{conversationId}")
                .SendAsync("ConversationClosed", new { conversationId });

            _logger.LogDebug("SignalR: ConversationClosed pushed to conversation_{ConvId}", conversationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SignalR: Failed to push ConversationClosed to conversation_{ConvId}", conversationId);
        }
    }

    /// <summary>
    /// Notifies all admin clients that a new conversation was escalated.
    /// Received by AdminChat Index.cshtml to add the conversation to sidebar without polling.
    /// </summary>
    public async Task NotifyNewEscalationAsync(int conversationId, string conversationCode,
        string guestName, string? guestPhone, string status, string preview)
    {
        try
        {
            await _hub.Clients
                .Group("admin")
                .SendAsync("NewEscalation", new
                {
                    id = conversationId,
                    conversationCode,
                    guestName,
                    guestPhone,
                    status,
                    preview,
                    updatedAt = DateTime.UtcNow.ToString("o")
                });

            _logger.LogDebug("SignalR: NewEscalation pushed to admin group for conversation_{ConvId}", conversationId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SignalR: Failed to push NewEscalation for conversation_{ConvId}", conversationId);
        }
    }

    /// <summary>
    /// Pushes a new user message to admin clients watching the conversation.
    /// </summary>
    public async Task NotifyNewUserMessageAsync(int conversationId, string messageText, DateTime createdAt)
    {
        try
        {
            await _hub.Clients
                .Group($"conversation_{conversationId}")
                .SendAsync("NewUserMessage", new
                {
                    conversationId,
                    messageText,
                    createdAt = createdAt.ToString("o"),
                    senderType = "User"
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SignalR: Failed to push NewUserMessage to conversation_{ConvId}", conversationId);
        }
    }
}
