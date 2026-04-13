using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.ViewModels;
using Microsoft.AspNetCore.Http;

namespace ROYALHOTEL.Controllers
{
    public class AdminDashboardController : Controller
    {
        private bool IsAdmin()
        {
            // Kiểm tra quyền Admin dựa trên Session
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        public IActionResult Index()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            // Theo yêu cầu, sử dụng Mock Data cho Dashboard
            var model = new AdminDashboardViewModel
            {
                TotalRooms = 150,
                ActiveRooms = 112,
                TotalBookings = 486,
                PendingBookings = 24,
                TotalAccounts = 98,
                ActivePricingRules = 5,
                TotalRevenue = 24500.75m,
                OccupancyRate = "74.6%"
            };

            return View(model);
        }
    }
}
