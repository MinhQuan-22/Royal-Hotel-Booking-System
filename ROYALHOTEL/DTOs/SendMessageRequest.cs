using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.DTOs;

/// <summary>
/// Request DTO for sending a chat message
/// </summary>
public class SendMessageRequest
{
    public int? ConversationId { get; set; }
    public string MessageText { get; set; } = "";
    public string? GuestName { get; set; }
    public string? GuestEmail { get; set; }
    
    [MaxLength(20)]
    public string? GuestPhone { get; set; }
}
