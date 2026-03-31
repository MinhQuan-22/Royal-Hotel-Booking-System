using ROYALHOTEL.Models;

namespace ROYALHOTEL.Helpers;

public static class RoomAmenityViewHelper
{
    public static List<Amenity> GetDisplayAmenities(Room? room, IEnumerable<Amenity>? filterAmenities = null)
    {
        var roomAmenities = (room?.RoomAmenities ?? new List<RoomAmenity>())
            .Select(x => x.Amenity)
            .Where(a => a != null && !string.IsNullOrWhiteSpace(a.Name))
            .GroupBy(a => a!.Id)
            .Select(g => g.First()!)
            .ToList();

        if (filterAmenities == null)
            return roomAmenities.OrderBy(a => a.Name).ToList();

        var filterList = filterAmenities
            .Where(a => a != null && !string.IsNullOrWhiteSpace(a.AmenityKey))
            .ToList();

        var orderMap = filterList
            .Select((a, index) => new { Key = a.AmenityKey, Index = index })
            .ToDictionary(x => x.Key, x => x.Index, StringComparer.OrdinalIgnoreCase);

        return roomAmenities
            .OrderBy(a => orderMap.ContainsKey(a.AmenityKey) ? orderMap[a.AmenityKey] : int.MaxValue)
            .ThenBy(a => a.Name)
            .ToList();
    }
}