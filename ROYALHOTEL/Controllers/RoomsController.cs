using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Services.Rooms;

namespace ROYALHOTEL.Controllers;

public class RoomsController : Controller
{
    private readonly RoomQueryService _service;
    private readonly IRoomRepository _repo;
    private readonly RoyalHotelDbContext _db;

    public RoomsController(RoomQueryService service, IRoomRepository repo, RoyalHotelDbContext db)
    {
        _service = service;
        _repo = repo;
        _db = db;
    }

    public async Task<IActionResult> Index(
        string? checkIn, string? checkOut,
        string? checkInDate, string? checkOutDate,
        int? guests,
        string? sort = "price_asc",
        string[]? roomTypes = null,
        string[]? amenities = null,
        decimal? minPrice = null,
        decimal? maxPrice = null)
    {
        maxPrice ??= 100_000_000m;
        var guestsVal = guests ?? 0;

        var checkInFinal = !string.IsNullOrWhiteSpace(checkIn) ? checkIn : checkInDate;
        var checkOutFinal = !string.IsNullOrWhiteSpace(checkOut) ? checkOut : checkOutDate;

        ViewBag.AllRoomTypes = await _service.GetAllRoomTypesAsync();
        ViewBag.FeaturedRooms = await _service.GetFeaturedRoomTypesAsync();
        ViewBag.FilterAmenities = await _service.GetFilterAmenitiesAsync();

        var rooms = await _service.SearchAsync(new RoomSearchQuery
        {
            CheckIn = DateOnly.TryParse(checkInFinal, out var ci) ? ci : null,
            CheckOut = DateOnly.TryParse(checkOutFinal, out var co) ? co : null,
            Guests = guestsVal,
            Sort = sort,
            RoomTypes = roomTypes,
            AmenityKeys = amenities,
            MinPrice = minPrice,
            MaxPrice = maxPrice
        });

        ViewBag.CheckIn = checkInFinal;
        ViewBag.CheckOut = checkOutFinal;
        ViewBag.Guests = guestsVal;
        ViewBag.Sort = sort;
        ViewBag.MinPrice = minPrice ?? 0;
        ViewBag.MaxPrice = maxPrice;

        ViewBag.SelectedRoomTypes = roomTypes?.ToList() ?? new List<string>();

        return View(rooms);
    }

    public async Task<IActionResult> Detail(int id, string? checkIn, string? checkOut, int guests = 1)
    {
        var room = await _repo.GetByIdAsync(id);
        if (room == null) return NotFound();

        ViewBag.CheckIn = checkIn;
        ViewBag.CheckOut = checkOut;
        ViewBag.Guests = guests;
        ViewBag.FilterAmenities = await _service.GetFilterAmenitiesAsync();

        ViewBag.IsAvailable = true;
        ViewBag.AvailabilityMessage = null;

        if (!string.IsNullOrWhiteSpace(checkIn) && !string.IsNullOrWhiteSpace(checkOut))
        {
            if (DateTime.TryParse(checkIn, out var checkInDate) &&
                DateTime.TryParse(checkOut, out var checkOutDate))
            {
                if (checkOutDate <= checkInDate)
                {
                    ViewBag.IsAvailable = false;
                    ViewBag.AvailabilityMessage = "Ngày trả phòng phải sau ngày nhận phòng.";
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
                        ViewBag.IsAvailable = false;
                        ViewBag.AvailabilityMessage = "Phòng này đã được đặt trong khoảng thời gian anh chọn.";
                    }
                }
            }
        }

        return View(room);
    }
}
