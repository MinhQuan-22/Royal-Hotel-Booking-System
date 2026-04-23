using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Rooms;

public class RoomIndexPageRequest
{
    public string? CheckIn { get; set; }
    public string? CheckOut { get; set; }
    public int? Guests { get; set; }
    public string? Sort { get; set; }
    public string[]? RoomTypes { get; set; }
    public string[]? Amenities { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
}

public class RoomIndexPageData
{
    public List<Room> Rooms { get; set; } = new();
    public List<Room> FeaturedRooms { get; set; } = new();
    public List<Amenity> FilterAmenities { get; set; } = new();
    public List<string> AllRoomTypes { get; set; } = new();
    public Dictionary<int, RoomPricingSummary> FeaturedPricingMap { get; set; } = new();
    public Dictionary<int, RoomPricingSummary> RoomPricingMap { get; set; } = new();
    public HashSet<int> TopBookedRoomIds { get; set; } = new();
    public string? CheckIn { get; set; }
    public string? CheckOut { get; set; }
    public int Guests { get; set; }
    public string Sort { get; set; } = "price_asc";
    public decimal MinPrice { get; set; }
    public decimal MaxPrice { get; set; } = 100_000_000m;
    public List<string> SelectedRoomTypes { get; set; } = new();
}

public class RoomDetailPageData
{
    public required Room Room { get; init; }
    public List<Amenity> FilterAmenities { get; init; } = new();
    public required RoomPricingSummary PricingSummary { get; init; }
    public string? CheckIn { get; init; }
    public string? CheckOut { get; init; }
    public int Guests { get; init; }
    public bool IsAvailable { get; init; } = true;
    public string? AvailabilityMessage { get; init; }
}

public interface IRoomPageService
{
    Task<RoomIndexPageData> BuildIndexPageAsync(RoomIndexPageRequest request);
    Task<RoomDetailPageData?> BuildDetailPageAsync(int id, string? checkIn, string? checkOut, int guests);
}

public class RoomPageService : IRoomPageService
{
    private readonly RoomQueryService _roomQueryService;
    private readonly IRoomRepository _roomRepository;
    private readonly RoyalHotelDbContext _db;
    private readonly RoomPricingService _pricingService;

    public RoomPageService(
        RoomQueryService roomQueryService,
        IRoomRepository roomRepository,
        RoyalHotelDbContext db,
        RoomPricingService pricingService)
    {
        _roomQueryService = roomQueryService;
        _roomRepository = roomRepository;
        _db = db;
        _pricingService = pricingService;
    }

    public async Task<RoomIndexPageData> BuildIndexPageAsync(RoomIndexPageRequest request)
    {
        var sort = string.IsNullOrWhiteSpace(request.Sort) ? "price_asc" : request.Sort;
        var maxPrice = request.MaxPrice ?? 100_000_000m;
        var guests = request.Guests ?? 0;

        var pricingCheckIn = ParseDateOrNull(request.CheckIn);
        var pricingCheckOut = ParseDateOrNull(request.CheckOut);

        var allRoomTypes = await _roomQueryService.GetAllRoomTypesAsync();
        var featuredRooms = await _roomQueryService.GetFeaturedRoomTypesAsync();
        var filterAmenities = await _roomQueryService.GetFilterAmenitiesAsync();
        
        // Get top 3 booked specific rooms from stored procedure
        var topBookedRoomIds = await _roomQueryService.GetTopBookedRoomsAsync();

        var rooms = await _roomQueryService.SearchAsync(new RoomSearchQuery
        {
            CheckIn = DateOnly.TryParse(request.CheckIn, out var ci) ? ci : null,
            CheckOut = DateOnly.TryParse(request.CheckOut, out var co) ? co : null,
            Guests = guests,
            Sort = sort,
            RoomTypes = request.RoomTypes,
            AmenityKeys = request.Amenities,
            MinPrice = request.MinPrice,
            MaxPrice = maxPrice
        });

        // Reorder rooms: push top-booked specific rooms to the front
        // Rooms with ID in topBookedRoomIds appear first, then others
        rooms = rooms
            .OrderByDescending(r => topBookedRoomIds.Contains(r.Id))
            .ToList();

        return new RoomIndexPageData
        {
            Rooms = rooms,
            FeaturedRooms = featuredRooms,
            FilterAmenities = filterAmenities,
            AllRoomTypes = allRoomTypes,
            FeaturedPricingMap = _pricingService.BuildPricingMap(featuredRooms, pricingCheckIn, pricingCheckOut),
            RoomPricingMap = _pricingService.BuildPricingMap(rooms, pricingCheckIn, pricingCheckOut),
            TopBookedRoomIds = topBookedRoomIds,
            CheckIn = request.CheckIn,
            CheckOut = request.CheckOut,
            Guests = guests,
            Sort = sort ?? "price_asc",
            MinPrice = request.MinPrice ?? 0m,
            MaxPrice = maxPrice,
            SelectedRoomTypes = request.RoomTypes?.ToList() ?? new List<string>()
        };
    }

    public async Task<RoomDetailPageData?> BuildDetailPageAsync(int id, string? checkIn, string? checkOut, int guests)
    {
        var room = await _roomRepository.GetByIdAsync(id);
        if (room == null)
            return null;

        var pricingCheckIn = ParseDateOrNull(checkIn);
        var pricingCheckOut = ParseDateOrNull(checkOut);
        var filterAmenities = await _roomQueryService.GetFilterAmenitiesAsync();
        var pricingSummary = _pricingService.Calculate(room, pricingCheckIn, pricingCheckOut);

        var isAvailable = true;
        string? availabilityMessage = null;

        if (!string.IsNullOrWhiteSpace(checkIn) && !string.IsNullOrWhiteSpace(checkOut))
        {
            if (DateTime.TryParse(checkIn, out var checkInDate) &&
                DateTime.TryParse(checkOut, out var checkOutDate))
            {
                if (checkOutDate <= checkInDate)
                {
                    isAvailable = false;
                    availabilityMessage = "Ngày trả phòng phải sau ngày nhận phòng.";
                }
                else
                {
                    var hasConfirmedOverlap = await _db.Bookings.AnyAsync(b =>
                        b.RoomId == id &&
                        (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
                        checkInDate < b.CheckOut &&
                        checkOutDate > b.CheckIn);

                    if (hasConfirmedOverlap)
                    {
                        isAvailable = false;
                        availabilityMessage = "Phòng này đã được đặt trong khoảng thời gian anh chọn.";
                    }
                }
            }
        }

        return new RoomDetailPageData
        {
            Room = room,
            FilterAmenities = filterAmenities,
            PricingSummary = pricingSummary,
            CheckIn = checkIn,
            CheckOut = checkOut,
            Guests = guests,
            IsAvailable = isAvailable,
            AvailabilityMessage = availabilityMessage
        };
    }

    private static DateTime? ParseDateOrNull(string? value)
    {
        if (DateTime.TryParse(value, out var date))
            return date.Date;

        return null;
    }
}
