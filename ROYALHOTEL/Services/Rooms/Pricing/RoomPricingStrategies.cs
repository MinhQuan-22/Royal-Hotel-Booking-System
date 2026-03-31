using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

/// <summary>
/// Strategy interface cho các thuật toán điều chỉnh giá phòng.
/// </summary>
public interface IRoomPricingStrategy
{
    /// <summary>
    /// Tính hệ số điều chỉnh giá cho một ngày cụ thể và loại phòng.
    /// Trả về 1.0 nếu không áp dụng rule này.
    /// </summary>
    decimal GetMultiplier(Room room, DateTime date);

    /// <summary>
    /// Độ ưu tiên – số nhỏ được áp dụng trước.
    /// </summary>
    int Priority { get; }
}

/// <summary>
/// Strategy điều chỉnh giá phòng dựa hoàn toàn vào bảng PricingRules trong DB.
/// Hỗ trợ 3 loại rule: "weekend", "holiday", "promotion".
///
/// - weekend : DayOfWeekMask chứa tên thứ trong tuần (e.g. "Sat,Sun")
/// - holiday : StartDate..EndDate xác định khoảng ngày lễ
/// - promotion: StartDate..EndDate + RoomType tùy chọn (null = tất cả phòng)
///
/// Đăng ký là Scoped (phụ thuộc DbContext Scoped). Tải rule 1 lần/request.
/// Admin chỉnh sửa rule trên giao diện → phản ánh ngay ở request tiếp theo.
/// </summary>
public class DbPricingRuleStrategy : IRoomPricingStrategy
{
    public int Priority => 0; // Không dùng Priority của class, rule DB tự có Priority riêng

    private readonly List<PricingRule> _activeRules;

    public DbPricingRuleStrategy(ROYALHOTEL.Data.RoyalHotelDbContext db)
    {
        // Tải toàn bộ rule đang active, sắp xếp theo Priority tăng dần (số nhỏ = ưu tiên cao).
        _activeRules = db.PricingRules
            .Where(r => r.IsActive)
            .OrderBy(r => r.Priority)
            .ToList();
    }

    public decimal GetMultiplier(Room room, DateTime date)
    {
        // Tìm rule ưu tiên cao nhất (Priority nhỏ nhất) khớp với ngày và phòng.
        foreach (var rule in _activeRules)
        {
            if (Matches(rule, room, date))
                return rule.Multiplier;
        }

        return 1m; // Không có rule nào khớp → không điều chỉnh giá
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    private static bool Matches(PricingRule rule, Room room, DateTime date)
    {
        // Kiểm tra RoomType — null = áp dụng mọi loại phòng
        if (rule.RoomType != null &&
            !string.Equals(rule.RoomType, room.RoomType, StringComparison.OrdinalIgnoreCase))
            return false;

        return rule.RuleType switch
        {
            "weekend"   => MatchesWeekend(rule, date),
            "holiday"   => MatchesDateRange(rule, date),
            "promotion" => MatchesDateRange(rule, date),
            _           => false
        };
    }

    /// <summary>
    /// Weekend rule: DayOfWeekMask là chuỗi các thứ ngăn cách bởi dấu phẩy.
    /// Ví dụ: "Sat,Sun" hoặc "Saturday,Sunday" hoặc "6,0" (giá trị DayOfWeek enum).
    /// </summary>
    private static bool MatchesWeekend(PricingRule rule, DateTime date)
    {
        if (string.IsNullOrWhiteSpace(rule.DayOfWeekMask))
            return false;

        // Parse mask thành danh sách các DayOfWeek
        var dayName = date.DayOfWeek.ToString();           // e.g. "Saturday"
        var dayShort = date.DayOfWeek switch               // e.g. "Sat"
        {
            DayOfWeek.Monday    => "Mon",
            DayOfWeek.Tuesday   => "Tue",
            DayOfWeek.Wednesday => "Wed",
            DayOfWeek.Thursday  => "Thu",
            DayOfWeek.Friday    => "Fri",
            DayOfWeek.Saturday  => "Sat",
            DayOfWeek.Sunday    => "Sun",
            _                   => ""
        };
        var dayNum = ((int)date.DayOfWeek).ToString();     // e.g. "6"

        var parts = rule.DayOfWeekMask
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        return parts.Any(p =>
            p.Equals(dayName,  StringComparison.OrdinalIgnoreCase) ||
            p.Equals(dayShort, StringComparison.OrdinalIgnoreCase) ||
            p.Equals(dayNum,   StringComparison.Ordinal));
    }

    /// <summary>
    /// Holiday / Promotion rule: StartDate ≤ date ≤ EndDate.
    /// </summary>
    private static bool MatchesDateRange(PricingRule rule, DateTime date)
    {
        if (rule.StartDate == null || rule.EndDate == null)
            return false;

        var d = date.Date;
        return d >= rule.StartDate.Value.Date && d <= rule.EndDate.Value.Date;
    }
}
