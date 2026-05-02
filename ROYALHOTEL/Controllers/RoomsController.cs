using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Services.Rooms;

namespace ROYALHOTEL.Controllers;

public class RoomsController : Controller
{
    private readonly IRoomPageService _pageService;

    public RoomsController(IRoomPageService pageService)
    {
        _pageService = pageService;
    }

    public async Task<IActionResult> Index(
        string? checkIn, string? checkOut,
        string? checkInDate, string? checkOutDate,
        int? guests,
        int? hotelId,
        string? sort = "price_asc",
        string[]? roomTypes = null,
        string[]? amenities = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        string? search = null)
    {
        var checkInFinal = !string.IsNullOrWhiteSpace(checkIn) ? checkIn : checkInDate;
        var checkOutFinal = !string.IsNullOrWhiteSpace(checkOut) ? checkOut : checkOutDate;

        var pageData = await _pageService.BuildIndexPageAsync(new RoomIndexPageRequest
        {
            CheckIn = checkInFinal,
            CheckOut = checkOutFinal,
            Guests = guests,
            Sort = sort,
            RoomTypes = roomTypes,
            Amenities = amenities,
            MinPrice = minPrice,
            MaxPrice = maxPrice,
            SearchText = search,
            HotelId = hotelId
        });

        return View(pageData);
    }


    public async Task<IActionResult> Detail(int id, string? checkIn, string? checkOut, int guests = 1)
    {
        var pageData = await _pageService.BuildDetailPageAsync(id, checkIn, checkOut, guests);
        if (pageData == null)
            return NotFound();

        return View(pageData);
    }
}
