using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public class RoomSearchItem
{
    public required Room Room { get; init; }
    public required RoomPricingSummary Pricing { get; init; }
}
