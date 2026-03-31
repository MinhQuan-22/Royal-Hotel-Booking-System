namespace ROYALHOTEL.Models;

public class PricingRule
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string RuleType { get; set; } = "";        // weekend / holiday / promotion
    public string? RoomType { get; set; }             // null = áp dụng mọi loại phòng
    public DateTime? StartDate { get; set; }          // holiday/promotion
    public DateTime? EndDate { get; set; }            // holiday/promotion
    public string? DayOfWeekMask { get; set; }        // ví dụ: "Sat,Sun"
    public decimal Multiplier { get; set; } = 1m;     // 1.15 = tăng 15%, 0.9 = giảm 10%
    public int Priority { get; set; } = 100;          // số nhỏ ưu tiên cao hơn
    public bool IsActive { get; set; } = true;
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public string? UpdatedBy { get; set; }
}

public class PricingRuleHistory
{
    public long Id { get; set; }
    public int? PricingRuleId { get; set; }
    public string ActionType { get; set; } = "";      // create / update / delete
    public string RuleName { get; set; } = "";
    public string RuleType { get; set; } = "";
    public string? RoomType { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? DayOfWeekMask { get; set; }
    public decimal Multiplier { get; set; }
    public int Priority { get; set; }
    public bool IsActive { get; set; }
    public string? Notes { get; set; }

    public DateTime ChangedAt { get; set; }
    public string? ChangedBy { get; set; }
}
