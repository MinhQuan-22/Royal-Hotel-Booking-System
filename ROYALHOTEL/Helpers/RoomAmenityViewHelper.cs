using ROYALHOTEL.Models;

namespace ROYALHOTEL.Helpers;

public static class RoomAmenityViewHelper
{
    public static List<Amenity> GetDisplayAmenities(Room? room, IEnumerable<Amenity>? filterAmenities)
    {
        var amenityList = (filterAmenities ?? Enumerable.Empty<Amenity>())
            .Where(a => a != null && !string.IsNullOrWhiteSpace(a.AmenityKey))
            .ToList();

        var orderMap = amenityList
            .Select((a, index) => new { Key = a.AmenityKey, Index = index })
            .ToDictionary(x => x.Key, x => x.Index, StringComparer.OrdinalIgnoreCase);

        return (room?.RoomAmenities ?? new List<RoomAmenity>())
            .Select(x => x.Amenity)
            .Where(a => a != null && orderMap.ContainsKey(a!.AmenityKey))
            .GroupBy(a => a!.AmenityKey, StringComparer.OrdinalIgnoreCase)
            .Select(g => g.First()!)
            .OrderBy(a => orderMap[a.AmenityKey])
            .ToList();
    }
}
