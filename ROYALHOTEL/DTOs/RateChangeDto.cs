namespace ROYALHOTEL.DTOs;

/// <summary>
/// DTO for room rate change audit log data
/// </summary>
public class RateChangeDto
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public string RoomCode { get; set; } = "";
    public string RoomName { get; set; } = "";
    public decimal OldRate { get; set; }
    public decimal NewRate { get; set; }
    public decimal ChangePercent { get; set; }
    public DateTime ChangedAt { get; set; }
    public string? ChangedBy { get; set; }
}
