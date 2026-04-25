namespace ROYALHOTEL.Models;

/// <summary>
/// Audit log entity for tracking significant room rate changes (>50%)
/// </summary>
public class RoomRateChangeLog
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;
    public decimal OldRate { get; set; }
    public decimal NewRate { get; set; }
    public decimal ChangePercent { get; set; }
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public string? ChangedBy { get; set; }
}
