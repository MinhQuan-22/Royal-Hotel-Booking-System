namespace ROYALHOTEL.Models;

/// <summary>
/// Audit log entity for tracking room rate changes.
/// IsLargeChange = true khi thay đổi vượt quá 50% (yêu cầu đề bài Project 14).
/// Trigger trg_Rooms_RateAudit tự động ghi log khi Rooms.Rate được UPDATE.
/// </summary>
public class RoomRateChangeLog
{
    public int Id { get; set; }
    public int RoomId { get; set; }
    public Room Room { get; set; } = null!;
    public decimal OldRate { get; set; }
    public decimal NewRate { get; set; }

    /// <summary>Phần trăm thay đổi giá: (|NewRate - OldRate| / OldRate) * 100</summary>
    public decimal ChangePercent { get; set; }

    /// <summary>True nếu ChangePercent > 50% — đánh dấu thay đổi lớn cần chú ý</summary>
    public bool IsLargeChange { get; set; }

    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public string? ChangedBy { get; set; }
    public string? Reason { get; set; }
}
