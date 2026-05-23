using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Rooms;
using ROYALHOTEL.Services.Catalog;

namespace ROYALHOTEL.Controllers;

public class HomeController : Controller
{
    private readonly RoomQueryService _roomService;
    private readonly IHotelCatalogService _catalogService;

    public HomeController(RoomQueryService roomService, IHotelCatalogService catalogService)
    {
        _roomService = roomService;
        _catalogService = catalogService;
    }

    public async Task<IActionResult> Index()
    {
        var featuredRooms = await _roomService.GetFeaturedRoomTypesAsync();
        var hotels = await _roomService.GetAllHotelsAsync();

        // Load ảnh đại diện từ MongoDB HotelCatalog cho branch cards
        var hotelImageMap = new Dictionary<int, string>();
        try
        {
            foreach (var h in hotels)
            {
                var catalog = await _catalogService.GetByHotelIdAsync(h.Id);
                var img = catalog?.Images?.FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(img))
                    hotelImageMap[h.Id] = img;
            }
        }
        catch
        {
            // MongoDB không khả dụng → branch cards hiển thị không có ảnh (graceful degradation)
        }

        var vm = new HomePageVM
        {
            UserName = "Thu Trang",
            Phone = "0788660087",
            FeaturedRooms = featuredRooms
        };

        ViewBag.FeaturedRooms = featuredRooms;
        ViewBag.Hotels = hotels;
        ViewBag.HotelImageMap = hotelImageMap;  // Dictionary<int, string> hotelId → imageUrl

        return View(vm);
    }


    public IActionResult About()
    {
        return View();
    }

    public async Task<IActionResult> Contact()
    {
        var hotels = await _roomService.GetAllHotelsAsync();
        ViewBag.Hotels = hotels;
        return View();
    }
}
