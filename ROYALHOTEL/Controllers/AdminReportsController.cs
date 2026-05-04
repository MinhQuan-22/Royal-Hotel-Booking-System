using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.ViewModels;
using ROYALHOTEL.Services.Analytics;
using ROYALHOTEL.Data;
using System.Collections.Generic;

namespace ROYALHOTEL.Controllers
{
    public class AdminReportsController : Controller
    {
        private readonly IAnalyticsService _analyticsService;
        private readonly ILogger<AdminReportsController> _logger;
        private readonly RoyalHotelDbContext _context;

        public AdminReportsController(
            IAnalyticsService analyticsService,
            ILogger<AdminReportsController> logger,
            RoyalHotelDbContext context)
        {
            _analyticsService = analyticsService;
            _logger = logger;
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

        /// <summary>
        /// Displays quarterly revenue analytics with optional filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> QuarterlyRevenue(
            int? hotelId = null,
            int? year = null,
            int? quarter = null)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            // Get hotels for dropdown
            var hotels = await _context.Hotels
                .OrderBy(h => h.Name)
                .Select(h => new { h.Id, h.Name })
                .ToListAsync();
            
            ViewBag.Hotels = hotels;

            var analytics = await _analyticsService.GetQuarterlyRevenueAnalyticsAsync(
                hotelId, year, quarter);

            return View(analytics);
        }

        /// <summary>
        /// Returns quarterly revenue analytics as JSON for API consumption
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> QuarterlyRevenueJson(
            int? hotelId = null,
            int? year = null,
            int? quarter = null)
        {
            if (!IsAdmin())
            {
                return Unauthorized();
            }

            var analytics = await _analyticsService.GetQuarterlyRevenueAnalyticsAsync(
                hotelId, year, quarter);

            return Json(analytics);
        }

        /// <summary>
        /// Displays room rate change history with optional date range filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> RateChangeHistory(
            int roomId,
            DateTime? startDate = null,
            DateTime? endDate = null)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var changes = await _analyticsService.ParseRateChangeLogAsync(
                roomId, startDate, endDate);

            var reportHtml = _analyticsService.FormatRateChangeReport(changes);

            ViewBag.ReportHtml = reportHtml;
            ViewBag.RoomId = roomId;

            return View(changes);
        }
    }
}
