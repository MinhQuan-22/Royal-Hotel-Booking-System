using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.ViewModels;
using System.Collections.Generic;

namespace ROYALHOTEL.Controllers
{
    public class AdminReportsController : Controller
    {
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

            // Gắn Mock Data trả về cho Admin Reports
            var model = new AdminReportViewModel
            {
                // Room Pricing Trend Mock Data
                PricingLabels = new List<string> { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
                StandardPricingData = new List<int> { 85, 85, 85, 95, 110, 110, 95 },
                DeluxePricingData = new List<int> { 130, 130, 130, 145, 165, 165, 145 },

                // Monthly Revenue Mock Data
                MonthlyRevenueLabels = new List<string> { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
                MonthlyRevenueData = new List<decimal> { 120000, 115000, 130000, 145000, 138000, 150000, 160000, 165000, 140000, 135400, 155000, 175000 },

                // Top 3 Revenue Rooms Mock Data
                TopRevenueRooms = new List<TopRevenueRoom>
                {
                    new TopRevenueRoom { RoomCode = "JR-01", RoomName = "Junior Suite", RoomType = "Suite", TotalBookings = 42, RevenueGenerated = 15800.50m, OccupancyRate = 92.5m },
                    new TopRevenueRoom { RoomCode = "DL-01", RoomName = "Executive Suite", RoomType = "Suite", TotalBookings = 65, RevenueGenerated = 11200.00m, OccupancyRate = 88.0m },
                    new TopRevenueRoom { RoomCode = "PR-01", RoomName = "Premium Room", RoomType = "Family", TotalBookings = 54, RevenueGenerated = 6800.00m, OccupancyRate = 76.2m }
                }
            };

            return View(model);
        }
    }
}
