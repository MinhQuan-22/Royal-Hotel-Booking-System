using Microsoft.AspNetCore.SignalR;
using ROYALHOTEL.Data;
using Microsoft.EntityFrameworkCore;

namespace ROYALHOTEL.Hubs;

/// <summary>
/// P2-2: SignalR Hub for real-time chat communication.
/// Replaces polling for both user-side admin reply notifications and admin-side new message notifications.
///
/// Groups:
///   - conversation_{id}  : All clients watching a specific conversation (user + admin)
///   - admin              : All admin clients (for new escalation notifications)
/// </summary>
public class ChatHub : Hub
{
    private readonly RoyalHotelDbContext _db;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(RoyalHotelDbContext db, ILogger<ChatHub> logger)
    {
        _db = db;
        _logger = logger;
    }

    /// <summary>
    /// User/Guest subscribes to updates for their conversation.
    /// Called from chat-widget.js after starting a conversation.
    /// </summary>
    public async Task JoinConversation(int conversationId)
    {
        // Verify conversation exists
        var exists = await _db.ChatConversations.AnyAsync(c => c.Id == conversationId);
        if (!exists)
        {
            _logger.LogWarning("ChatHub.JoinConversation: Conversation {Id} not found", conversationId);
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, $"conversation_{conversationId}");
        _logger.LogInformation("ChatHub: Client {ConnectionId} joined conversation_{ConvId}", Context.ConnectionId, conversationId);
    }

    /// <summary>
    /// User leaves conversation group (cleanup on widget close).
    /// </summary>
    public async Task LeaveConversation(int conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conversation_{conversationId}");
    }

    /// <summary>
    /// Admin joins the admin group to receive new escalation notifications.
    /// </summary>
    public Task JoinAdminGroup()
    {
        return Groups.AddToGroupAsync(Context.ConnectionId, "admin");
    }

    /// <summary>
    /// Admin leaves admin group.
    /// </summary>
    public Task LeaveAdminGroup()
    {
        return Groups.RemoveFromGroupAsync(Context.ConnectionId, "admin");
    }
}
