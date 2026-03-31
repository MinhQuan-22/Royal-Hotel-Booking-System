namespace ROYALHOTEL.Services.Rooms.Configuration;

public sealed class RoomCatalogRegistry
{
    private static readonly Lazy<RoomCatalogRegistry> _instance =
        new(() => new RoomCatalogRegistry());

    public static RoomCatalogRegistry Instance => _instance.Value;

    private RoomCatalogRegistry()
    {
    }

    public IReadOnlyList<string> RoomTypeOrder { get; } =
    [
        "Standard", "Single", "Double", "Deluxe", "Family", "Suite"
    ];

    public IReadOnlyList<string> FilterAmenityOrder { get; } =
    [
        "Spa", "Breakfast", "Pool", "Balcony", "Wifi", "AirportPickup"
    ];

    public string NormalizeRoomType(string? roomType)
    {
        if (string.IsNullOrWhiteSpace(roomType))
            return string.Empty;

        var value = roomType.Trim();
        var matched = RoomTypeOrder.FirstOrDefault(x =>
            x.Equals(value, StringComparison.OrdinalIgnoreCase));

        return matched ?? value;
    }

    public int GetRoomTypeOrder(string? roomType)
    {
        var normalized = NormalizeRoomType(roomType);

        var idx = RoomTypeOrder
            .ToList()
            .FindIndex(x => x.Equals(normalized, StringComparison.OrdinalIgnoreCase));

        return idx == -1 ? int.MaxValue : idx;
    }

    public int GetAmenityOrder(string? amenityKey)
    {
        var idx = FilterAmenityOrder
            .ToList()
            .FindIndex(x => x.Equals(amenityKey, StringComparison.OrdinalIgnoreCase));

        return idx == -1 ? int.MaxValue : idx;
    }
}
