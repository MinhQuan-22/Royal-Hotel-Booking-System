using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.ViewModels;
using Microsoft.AspNetCore.Http;
using ROYALHOTEL.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System;
using System.Threading.Tasks;

namespace ROYALHOTEL.Controllers
{
    public class AdminDashboardController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminDashboardController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            // Kiểm tra quyền Admin dựa trên Session
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        public async Task<IActionResult> Index()
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var today = DateTime.Today;

            // 1. Total Revenue (Status = 'Completed')
            var totalRevenue = await _context.Bookings
                .Where(b => b.Status == "Completed")
                .SumAsync(b => b.TotalAmount ?? 0);

            // Total Revenue by Month
            var currentYear = today.Year;
            var currentMonth = today.Month;
            var monthlyRevenue = await _context.Bookings
                .Where(b => b.Status == "Completed" && b.CheckIn.Year == currentYear && b.CheckIn.Month == currentMonth)
                .SumAsync(b => b.TotalAmount ?? 0);

            // 2. Active Rooms
            var activeRoomsCount = await _context.Rooms
                .Where(r => r.Status == "Active")
                .CountAsync();

            // Occupied Rooms today
            var occupiedRoomsToday = await _context.Bookings
                .Where(b => b.CheckIn.Date <= today && b.CheckOut.Date > today && (b.Status == "Confirmed" || b.Status == "CheckedIn"))
                .Select(b => b.RoomId)
                .Distinct()
                .CountAsync();

            var totalRoomsCount = await _context.Rooms.CountAsync();

            // 2. Occupancy Rate
            var occupancyRateVal = activeRoomsCount > 0 ? (occupiedRoomsToday * 100.0 / activeRoomsCount) : 0;
            var occupancyRateStr = occupancyRateVal.ToString("0.00") + "%";

            // 3. Pending Bookings
            var pendingBookingsCount = await _context.Bookings
                .Where(b => b.Status == "Pending")
                .CountAsync();

            // 4. Available Rooms
            var availableRooms = activeRoomsCount - occupiedRoomsToday;

            var totalBookingsCount = await _context.Bookings.CountAsync();
            var cancelledBookingsCount = await _context.Bookings.Where(b => b.Status == "Cancelled").CountAsync();

            var cancellationRateVal = totalBookingsCount > 0 ? (cancelledBookingsCount * 100.0 / totalBookingsCount) : 0;
            var cancellationRateStr = cancellationRateVal.ToString("0.00") + "%";

            var totalAccountsCount = await _context.Accounts.CountAsync();
            var activePricingRulesCount = await _context.PricingRules.Where(p => p.IsActive).CountAsync();

            // Top 3 Highest Revenue Rooms
            var topRevenueRooms = await _context.Rooms
                .GroupJoin(
                    _context.Bookings.Where(b => b.Status == "Completed" && b.CheckIn.Month == currentMonth && b.CheckIn.Year == currentYear),
                    r => r.Id,
                    b => b.RoomId,
                    (r, bookings) => new { Room = r, Bookings = bookings }
                )
                .Select(x => new
                {
                    RoomCode = x.Room.Code,
                    RoomName = x.Room.Name,
                    RoomType = x.Room.RoomType,
                    PricePerNight = x.Room.BasePricePerNight,
                    TotalBookings = x.Bookings.Count(),
                    TotalNights = x.Bookings.Sum(b => EF.Functions.DateDiffDay(b.CheckIn, b.CheckOut)),
                    TotalRevenue = x.Bookings.Sum(b => b.TotalAmount ?? 0)
                })
                .OrderByDescending(x => x.TotalRevenue)
                .Take(3)
                .ToListAsync();

            var topRoomsList = topRevenueRooms.Select(x => new TopRevenueRoomViewModel
            {
                RoomCode = x.RoomCode,
                RoomName = x.RoomName,
                RoomType = x.RoomType,
                PricePerNight = x.PricePerNight,
                TotalBookings = x.TotalBookings,
                RevenueGenerated = x.TotalRevenue,
                OccupancyRate = (x.TotalNights * 100.0 / 30.0).ToString("0.00")
            }).ToList();

            // Top 3 Most Booked Rooms
            var mostBookedRooms = await _context.Rooms
                .GroupJoin(
                    _context.Bookings,
                    r => r.Id,
                    b => b.RoomId,
                    (r, bookings) => new { Room = r, Bookings = bookings }
                )
                .Select(x => new
                {
                    RoomCode = x.Room.Code,
                    RoomName = x.Room.Name,
                    RoomType = x.Room.RoomType,
                    TotalNights = x.Bookings.Sum(b => EF.Functions.DateDiffDay(b.CheckIn, b.CheckOut)),
                    TotalBookings = x.Bookings.Count(),
                    TotalRevenue = x.Bookings.Sum(b => b.Status == "Completed" ? (b.TotalAmount ?? 0) : 0)
                })
                .OrderByDescending(x => x.TotalBookings)
                .Take(3)
                .ToListAsync();

            var mostBookedRoomsList = mostBookedRooms.Select(x => new MostBookedRoomViewModel
            {
                RoomCode = x.RoomCode,
                RoomName = x.RoomName,
                RoomType = x.RoomType,
                TotalNights = x.TotalNights,
                TotalBookings = x.TotalBookings,
                TotalRevenue = x.TotalRevenue
            }).ToList();

            var model = new AdminDashboardViewModel
            {
                TotalRooms = totalRoomsCount,
                ActiveRooms = availableRooms, // Setting available rooms as ActiveRooms for the dashboard view
                TotalBookings = totalBookingsCount,
                PendingBookings = pendingBookingsCount,
                TotalAccounts = totalAccountsCount,
                ActivePricingRules = activePricingRulesCount,
                TotalRevenue = totalRevenue,
                MonthlyRevenue = monthlyRevenue,
                OccupancyRate = occupancyRateStr,
                CancellationRate = cancellationRateStr,
                TopRevenueRooms = topRoomsList,
                MostBookedRooms = mostBookedRoomsList
            };

            return View(model);
        }
    }
}
