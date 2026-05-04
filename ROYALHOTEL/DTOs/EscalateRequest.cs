namespace ROYALHOTEL.DTOs;

/// <summary>
/// Request DTO for escalating a conversation to admin
/// </summary>
public class EscalateRequest
{
    public int ConversationId { get; set; }
    public string Reason { get; set; } = "";
}
