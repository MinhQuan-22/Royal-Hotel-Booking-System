namespace ROYALHOTEL.Services.Rooms;

public class RoomPricingSummary
{
    public decimal BasePricePerNight { get; init; }
    public decimal DisplayPricePerNight { get; init; }
    public decimal? TotalAmount { get; init; }
    public int? Nights { get; init; }
    public bool HasDiscount => DisplayPricePerNight < BasePricePerNight;
    public bool HasPremium => DisplayPricePerNight > BasePricePerNight;

    /// <summary>Tạo RoomPricingSummary chỉ từ giá cơ bản, không có điều chỉnh.</summary>
    public static RoomPricingSummary FromBase(decimal basePricePerNight)
        => new()
        {
            BasePricePerNight = basePricePerNight,
            DisplayPricePerNight = basePricePerNight,
            TotalAmount = null,
            Nights = null
        };
}
