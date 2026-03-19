using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Models;
using ROYALHOTEL.Services.Rooms;

namespace ROYALHOTEL.Controllers;

public class HomeController : Controller
{
    private readonly RoomQueryService _roomService;

    public HomeController(RoomQueryService roomService)
    {
        _roomService = roomService;
    }

    public async Task<IActionResult> Index()
    {
        var featuredRooms = await _roomService.GetFeaturedRoomTypesAsync();

        var vm = new HomePageVM
        {
            UserName = "Thu Trang",
            Phone = "0788660087",
            FeaturedRooms = featuredRooms
        };

        ViewBag.FeaturedRooms = featuredRooms;

        return View(vm);
    }
}
