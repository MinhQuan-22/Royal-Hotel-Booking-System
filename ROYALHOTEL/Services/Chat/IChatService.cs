using ROYALHOTEL.DTOs;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Chat;

/// <summary>
/// Interface for chat service that manages conversation lifecycle and orchestrates AI interactions
/// Validates: Requirements 2.4
/// </summary>
public interface IChatService
{
    /// <summary>
    /// Processes a user question through classification, context retrieval, and AI response generation
    /// </summary>
    /// <param name="request">The message request containing question text and conversation info</param>
    /// <param name="userId">The authenticated user ID, or null for guest users</param>
    /// <returns>Chat response with AI answer or escalation message</returns>
    Task<ChatResponse> ProcessQuestionAsync(SendMessageRequest request, int? userId);

    /// <summary>
    /// Escalates a conversation to admin for manual handling
    /// </summary>
    /// <param name="conversationId">The conversation to escalate</param>
    /// <param name="reason">Reason for escalation</param>
    /// <returns>True if escalation successful</returns>
    Task<bool> EscalateConversationAsync(int conversationId, string reason);

    /// <summary>
    /// Closes a conversation
    /// </summary>
    /// <param name="conversationId">The conversation to close</param>
    /// <returns>True if closure successful</returns>
    Task<bool> CloseConversationAsync(int conversationId);

    /// <summary>
    /// Retrieves conversation history for a specific conversation
    /// </summary>
    /// <param name="conversationId">The conversation ID</param>
    /// <param name="userId">The requesting user ID for authorization</param>
    /// <returns>List of chat messages</returns>
    Task<List<ChatMessage>> GetConversationHistoryAsync(int conversationId, int? userId);

    /// <summary>
    /// Retrieves all conversations for a specific user
    /// </summary>
    /// <param name="userId">The user ID</param>
    /// <returns>List of conversations ordered by UpdatedAt descending</returns>
    Task<List<ChatConversation>> GetUserConversationsAsync(int userId);
}
