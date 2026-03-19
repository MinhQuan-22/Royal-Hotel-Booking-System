using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Models;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Services.Rooms;

public class RoomSearchQuery
{
    public DateOnly? CheckIn { get; set; }
    public DateOnly? CheckOut { get; set; }
    public int Guests { get; set; } = 1;

    public IReadOnlyList<string>? RoomTypes { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public IReadOnlyList<string>? AmenityKeys { get; set; }

    public string? Sort { get; set; } = "price_asc";
}

public class RoomQueryService
{
    private static readonly string[] RoomTypeOrder =
    {
        "Standard", "Single", "Double", "Deluxe", "Family", "Suite"
    };

    private static readonly string[] FilterAmenityOrder =
    {
        "Spa", "Breakfast", "Pool", "Balcony", "Wifi", "AirportPickup"
    };

    private readonly IRoomRepository _repo;
    private readonly RoyalHotelDbContext _db;

    public RoomQueryService(IRoomRepository repo, RoyalHotelDbContext db)
    {
        _repo = repo;
        _db = db;
    }

    public async Task<List<string>> GetAllRoomTypesAsync()
    {
        var roomTypes = await _repo.Query()
            .Select(r => r.RoomType)
            .Where(rt => !string.IsNullOrWhiteSpace(rt))
            .ToListAsync();

        return roomTypes
            .Select(NormalizeRoomType)
            .Where(rt => !string.IsNullOrWhiteSpace(rt))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(rt => GetRoomTypeOrder(rt))
            .ThenBy(rt => rt)
            .ToList();
    }

    public async Task<List<Amenity>> GetFilterAmenitiesAsync()
    {
        var amenityKeys = FilterAmenityOrder.ToHashSet(StringComparer.OrdinalIgnoreCase);

        var amenities = await _db.Amenities
            .AsNoTracking()
            .Where(a => amenityKeys.Contains(a.AmenityKey))
            .ToListAsync();

        return amenities
            .OrderBy(a => GetAmenityOrder(a.AmenityKey))
            .ThenBy(a => a.Name)
            .ToList();
    }

    public async Task<List<Room>> GetFeaturedRoomTypesAsync()
    {
        var rooms = await _repo.Query()
            .Where(r => !string.IsNullOrWhiteSpace(r.RoomType))
            .ToListAsync();

        var featured = rooms
            .GroupBy(r => NormalizeRoomType(r.RoomType), StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderBy(x => x.BasePricePerNight)
                          .ThenBy(x => x.Id)
                          .First())
            .OrderBy(r => GetRoomTypeOrder(r.RoomType))
            .ThenBy(r => NormalizeRoomType(r.RoomType))
            .Take(6)
            .ToList();

        return featured;
    }

    public async Task<List<Room>> SearchAsync(RoomSearchQuery q)
    {
        var query = _repo.Query();

        if (q.Guests > 0)
            query = query.Where(r => r.MaxGuests >= q.Guests);

        if (q.RoomTypes != null && q.RoomTypes.Count > 0)
        {
            var selectedTypes = q.RoomTypes
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(NormalizeRoomType)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (selectedTypes.Count > 0)
            {
                query = query.Where(r =>
                    !string.IsNullOrWhiteSpace(r.RoomType) &&
                    selectedTypes.Contains(r.RoomType.Trim()));
            }
        }

        if (q.MinPrice.HasValue)
            query = query.Where(r => r.BasePricePerNight >= q.MinPrice.Value);

        if (q.MaxPrice.HasValue)
            query = query.Where(r => r.BasePricePerNight <= q.MaxPrice.Value);

        if (q.AmenityKeys != null && q.AmenityKeys.Count > 0)
        {
            var selectedAmenityKeys = q.AmenityKeys
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            query = query.Where(r =>
                r.RoomAmenities.Any(ra => selectedAmenityKeys.Contains(ra.Amenity.AmenityKey)));
        }

        if (q.CheckIn.HasValue && q.CheckOut.HasValue)
        {
            var ci = q.CheckIn.Value.ToDateTime(TimeOnly.MinValue);
            var co = q.CheckOut.Value.ToDateTime(TimeOnly.MinValue);

            if (co > ci)
            {
                var blockedRoomIds = await _db.Bookings
                    .AsNoTracking()
                    .Where(b =>
                        (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
                        b.CheckIn < co &&
                        b.CheckOut > ci)
                    .Select(b => b.RoomId)
                    .Distinct()
                    .ToListAsync();

                query = query.Where(r => !blockedRoomIds.Contains(r.Id));
            }
        }

        var sorter = RoomSortStrategyFactory.Create(q.Sort);
        query = sorter.Apply(query);

        return await query.ToListAsync();
    }

    private static string NormalizeRoomType(string? roomType)
    {
        if (string.IsNullOrWhiteSpace(roomType))
            return string.Empty;

        var value = roomType.Trim();

        var matched = RoomTypeOrder.FirstOrDefault(x =>
            x.Equals(value, StringComparison.OrdinalIgnoreCase));

        return matched ?? value;
    }

    private static int GetRoomTypeOrder(string? roomType)
    {
        var normalized = NormalizeRoomType(roomType);

        var idx = Array.FindIndex(RoomTypeOrder, x =>
            x.Equals(normalized, StringComparison.OrdinalIgnoreCase));

        return idx == -1 ? int.MaxValue : idx;
    }

    private static int GetAmenityOrder(string? amenityKey)
    {
        var idx = Array.FindIndex(FilterAmenityOrder, x =>
            x.Equals(amenityKey, StringComparison.OrdinalIgnoreCase));

        return idx == -1 ? int.MaxValue : idx;
    }
}
