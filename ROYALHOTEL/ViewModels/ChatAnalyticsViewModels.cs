namespace ROYALHOTEL.ViewModels;

public class RecentEscalationDto
{
    public int Id { get; set; }
    public string ConversationCode { get; set; }
    public string GuestName { get; set; }
    public string EscalationReason { get; set; }
    public DateTime? EscalatedAt { get; set; }
    public string Status { get; set; }
}

public class TopReasonDto
{
    public string Reason { get; set; }
    public int Count { get; set; }
}
