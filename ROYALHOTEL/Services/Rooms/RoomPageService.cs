using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Catalog;

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
    public string? SearchText { get; set; }
}

public class RoomIndexPageData
{
    public List<Room> Rooms { get; set; } = new();
    public List<Room> FeaturedRooms { get; set; } = new();
    public List<Amenity> FilterAmenities { get; set; } = new();
    public List<string> AllRoomTypes { get; set; } = new();
    public Dictionary<int, RoomPricingSummary> FeaturedPricingMap { get; set; } = new();
    public Dictionary<int, RoomPricingSummary> RoomPricingMap { get; set; } = new();
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
    private readonly IHotelCatalogService _catalogService;

    public RoomPageService(
        RoomQueryService roomQueryService,
        IRoomRepository roomRepository,
        RoyalHotelDbContext db,
        RoomPricingService pricingService,
        IHotelCatalogService catalogService)
    {
        _roomQueryService = roomQueryService;
        _roomRepository = roomRepository;
        _db = db;
        _pricingService = pricingService;
        _catalogService = catalogService;
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

        // ==========================================================
        // BƯỚC 1: Gọi MongoDB HotelCatalog để lấy room candidates
        // Khi có amenity filter HOẶC text search → đi qua MongoDB trước
        // ==========================================================
        List<int>? roomIdCandidates = null;
        var hasMongoFilter = (request.Amenities != null && request.Amenities.Length > 0) 
                          || !string.IsNullOrWhiteSpace(request.SearchText);
        
        if (hasMongoFilter)
        {
            try
            {
                roomIdCandidates = await _catalogService.SearchRoomCandidatesAsync(
                    new RoomCatalogQuery 
                    { 
                        AmenityKeys = request.Amenities,
                        TextSearch = request.SearchText
                    });
            }
            catch (Exception ex)
            {
                // MongoDB không khả dụng → fallback về SQL filter trực tiếp
                Console.WriteLine($"[WARN] MongoDB search failed, fallback to SQL: {ex.Message}");
                roomIdCandidates = null;
            }
        }

        // ==========================================================
        // BƯỚC 2: Query SQL Server với candidates từ MongoDB
        // ==========================================================
        var rooms = await _roomQueryService.SearchAsync(new RoomSearchQuery
        {
            CheckIn = DateOnly.TryParse(request.CheckIn, out var ci) ? ci : null,
            CheckOut = DateOnly.TryParse(request.CheckOut, out var co) ? co : null,
            Guests = guests,
            Sort = sort,
            RoomTypes = request.RoomTypes,
            AmenityKeys = request.Amenities,
            MinPrice = request.MinPrice,
            MaxPrice = maxPrice,
            RoomIdCandidates = roomIdCandidates
        });

        return new RoomIndexPageData
        {
            Rooms = rooms,
            FeaturedRooms = featuredRooms,
            FilterAmenities = filterAmenities,
            AllRoomTypes = allRoomTypes,
            FeaturedPricingMap = _pricingService.BuildPricingMap(featuredRooms, pricingCheckIn, pricingCheckOut),
            RoomPricingMap = _pricingService.BuildPricingMap(rooms, pricingCheckIn, pricingCheckOut),
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
