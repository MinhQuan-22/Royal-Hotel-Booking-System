using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Data;

namespace ROYALHOTEL.Controllers
{
    public class AdminController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        public IActionResult Index()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            return RedirectToAction("Index", "AdminRooms");
        }
    }
}