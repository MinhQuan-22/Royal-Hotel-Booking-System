namespace ROYALHOTEL.DTOs;

/// <summary>
/// Response DTO for chat operations
/// </summary>
public class ChatResponse
{
    public int ConversationId { get; set; }
    public string ResponseText { get; set; } = "";
    public bool ShowContactAdmin { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
