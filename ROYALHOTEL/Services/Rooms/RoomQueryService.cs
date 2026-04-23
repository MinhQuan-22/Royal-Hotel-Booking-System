using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Rooms.Configuration;

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
    private readonly IRoomRepository _repo;
    private readonly RoyalHotelDbContext _db;
    private readonly RoomPricingService _pricingService;
    private readonly RoomCatalogRegistry _catalog = RoomCatalogRegistry.Instance;

    public RoomQueryService(
        IRoomRepository repo,
        RoyalHotelDbContext db,
        RoomPricingService pricingService)
    {
        _repo = repo;
        _db = db;
        _pricingService = pricingService;
    }

    public async Task<List<string>> GetAllRoomTypesAsync()
    {
        var roomTypes = await _repo.Query()
            .Select(r => r.RoomType)
            .Where(rt => !string.IsNullOrWhiteSpace(rt))
            .ToListAsync();

        return roomTypes
            .Select(_catalog.NormalizeRoomType)
            .Where(rt => !string.IsNullOrWhiteSpace(rt))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(rt => _catalog.GetRoomTypeOrder(rt))
            .ThenBy(rt => rt)
            .ToList();
    }

    public async Task<List<Amenity>> GetFilterAmenitiesAsync()
    {
        var amenityKeys = _catalog.FilterAmenityOrder
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var amenities = await _db.Amenities
            .AsNoTracking()
            .Where(a => amenityKeys.Contains(a.AmenityKey))
            .ToListAsync();

        return amenities
            .OrderBy(a => _catalog.GetAmenityOrder(a.AmenityKey))
            .ThenBy(a => a.Name)
            .ToList();
    }

    public async Task<List<Room>> GetFeaturedRoomTypesAsync()
    {
        var rooms = await _repo.Query()
            .Where(r => !string.IsNullOrWhiteSpace(r.RoomType))
            .ToListAsync();

        return rooms
            .GroupBy(r => _catalog.NormalizeRoomType(r.RoomType), StringComparer.OrdinalIgnoreCase)
            .Select(g => g.OrderBy(x => x.BasePricePerNight)
                          .ThenBy(x => x.Id)
                          .First())
            .OrderBy(r => _catalog.GetRoomTypeOrder(r.RoomType))
            .ThenBy(r => _catalog.NormalizeRoomType(r.RoomType))
            .Take(6)
            .ToList();
    }

    public Task<List<Room>> SearchAsync(RoomSearchQuery query)
    {
        return CreateTemplate(query).ExecuteAsync(query);
    }

    /// <summary>
    /// Get top 3 most-booked specific rooms by calling stored procedure sp_GetTopBookedRooms
    /// Core logic is in SQL Server as required by Database Advanced course
    /// </summary>
    public async Task<HashSet<int>> GetTopBookedRoomsAsync()
    {
        try
        {
            // Call stored procedure - core calculation is in SQL Server
            var results = await _db.Database
                .SqlQueryRaw<TopBookedRoomDto>("EXEC dbo.sp_GetTopBookedRooms")
                .ToListAsync();

            // Extract room IDs into HashSet for O(1) lookup in view
            return results
                .Select(r => r.RoomId)
                .ToHashSet();
        }
        catch (SqlException ex)
        {
            // Log error and return empty set - graceful degradation
            Console.WriteLine($"Error calling sp_GetTopBookedRooms: {ex.Message}");
            return new HashSet<int>();
        }
        catch (Exception ex)
        {
            // Handle any other errors gracefully
            Console.WriteLine($"Unexpected error in GetTopBookedRoomsAsync: {ex.Message}");
            return new HashSet<int>();
        }
    }

    private RoomSearchTemplate CreateTemplate(RoomSearchQuery query)
    {
        var hasValidStay = query.CheckIn.HasValue
                        && query.CheckOut.HasValue
                        && query.CheckOut.Value > query.CheckIn.Value;

        return hasValidStay
            ? new StayDateRoomSearchTemplate(_repo, _db, _pricingService)
            : new BasePriceRoomSearchTemplate(_repo, _db, _pricingService);
    }
}
