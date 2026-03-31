using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

/// <summary>
/// Service tính giá phòng dựa trên tập hợp các chiến lược (Strategy Pattern).
/// Nhận IEnumerable&lt;IRoomPricingStrategy&gt; qua DI – dễ mở rộng thêm rule mới.
/// </summary>
public class RoomPricingService
{
    private readonly IEnumerable<IRoomPricingStrategy> _strategies;

    public RoomPricingService(IEnumerable<IRoomPricingStrategy> strategies)
    {
        _strategies = strategies.OrderBy(s => s.Priority);
    }

    /// <summary>
    /// Tính RoomPricingSummary cho một phòng và khoảng check-in/check-out tuỳ chọn.
    /// Nếu không có checkIn/checkOut thì chỉ trả giá cơ bản.
    /// </summary>
    public RoomPricingSummary Calculate(Room room, DateTime? checkIn, DateTime? checkOut)
    {
        if (checkIn == null || checkOut == null || checkOut <= checkIn)
            return RoomPricingSummary.FromBase(room.BasePricePerNight);

        var nights = (int)(checkOut.Value - checkIn.Value).TotalDays;
        if (nights <= 0)
            return RoomPricingSummary.FromBase(room.BasePricePerNight);

        // Tính giá trung bình mỗi đêm sau khi áp dụng strategy
        var totalPrice = 0m;
        for (var day = 0; day < nights; day++)
        {
            var date = checkIn.Value.AddDays(day);
            var multiplier = GetEffectiveMultiplier(room, date);
            totalPrice += room.BasePricePerNight * multiplier;
        }

        var displayPerNight = Math.Round(totalPrice / nights, 2);

        return new RoomPricingSummary
        {
            BasePricePerNight = room.BasePricePerNight,
            DisplayPricePerNight = displayPerNight,
            TotalAmount = Math.Round(totalPrice, 2),
            Nights = nights
        };
    }

    /// <summary>
    /// Xây dựng dictionary giá phòng theo Id, tiện dùng cho danh sách phòng.
    /// </summary>
    public Dictionary<int, RoomPricingSummary> BuildPricingMap(
        IEnumerable<Room> rooms,
        DateTime? checkIn,
        DateTime? checkOut)
        => rooms.ToDictionary(r => r.Id, r => Calculate(r, checkIn, checkOut));

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    private decimal GetEffectiveMultiplier(Room room, DateTime date)
    {
        // Chỉ áp 1 strategy có priority cao nhất (số nhỏ nhất) đang apply.
        // Nếu không có strategy nào apply thì dùng 1 (không điều chỉnh giá).
        // Hành vi có chủ đích: tránh nhân dồn nhiều hệ số gây giá biến động không kiểm soát.
        return _strategies
            .Where(s => s.GetMultiplier(room, date) != 1m)
            .OrderBy(s => s.Priority)
            .Select(s => s.GetMultiplier(room, date))
            .FirstOrDefault(1m);
    }
}
