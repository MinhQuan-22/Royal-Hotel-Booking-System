using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminBookingsController : Controller
    {
        private readonly RoyalHotelDbContext _context;

        public AdminBookingsController(RoyalHotelDbContext context)
        {
            _context = context;
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString("USER_ROLE");
            return role != null && role.ToLower() == "admin";
        }

        [HttpGet]
        public async Task<IActionResult> Index(string? keyword, string? status)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var query =
                from b in _context.Bookings
                join r in _context.Rooms on b.RoomId equals r.Id
                select new AdminBookingItemViewModel
                {
                    Id = b.Id,
                    BookingCode = b.BookingCode,
                    RoomId = r.Id,
                    RoomName = r.Name,
                    RoomCode = r.Code,
                    CheckIn = b.CheckIn,
                    CheckOut = b.CheckOut,
                    Guests = b.Guests,
                    Status = b.Status,
                    GuestName = b.GuestName,
                    GuestEmail = b.GuestEmail,
                    GuestPhone = b.GuestPhone,
                    TotalAmount = b.TotalAmount,
                    CoverImageUrl = r.CoverImageUrl
                };

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                keyword = keyword.Trim();

                query = query.Where(x =>
                    x.BookingCode.Contains(keyword) ||
                    x.RoomName.Contains(keyword) ||
                    x.RoomCode.Contains(keyword) ||
                    (x.GuestName != null && x.GuestName.Contains(keyword)) ||
                    (x.GuestEmail != null && x.GuestEmail.Contains(keyword)));
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(x => x.Status == status);
            }

            var items = await query
                .OrderByDescending(x => x.Id)
                .ToListAsync();

            ViewBag.Keyword = keyword;
            ViewBag.Status = status;
            ViewBag.StatusOptions = new List<string>
            {
                "Confirmed",
                "CheckedIn",
                "CheckedOut",
                "Completed",
                "Cancelled"
            };

            return View(items);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(int id, string status)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var allowedStatuses = new List<string>
            {
                "Confirmed",
                "CheckedIn",
                "CheckedOut",
                "Completed",
                "Cancelled"
            };

            if (string.IsNullOrWhiteSpace(status) || !allowedStatuses.Contains(status))
            {
                TempData["Error"] = "Invalid booking status.";
                return RedirectToAction(nameof(Index));
            }

            var exists = await _context.Bookings
                .AsNoTracking()
                .AnyAsync(x => x.Id == id);

            if (!exists)
            {
                TempData["Error"] = "Booking not found.";
                return RedirectToAction(nameof(Index));
            }

            var booking = new Booking
            {
                Id = id,
                Status = status
            };

            _context.Bookings.Attach(booking);
            _context.Entry(booking).Property(x => x.Status).IsModified = true;

            await _context.SaveChangesAsync();

            TempData["Success"] = "Booking status updated successfully.";
            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Detail(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var item = await
                (from b in _context.Bookings
                join r in _context.Rooms on b.RoomId equals r.Id
                where b.Id == id
                select new AdminBookingDetailViewModel
                {
                    Id = b.Id,
                    BookingCode = b.BookingCode,
                    RoomId = r.Id,
                    RoomName = r.Name,
                    RoomCode = r.Code,
                    CoverImageUrl = r.CoverImageUrl,
                    CheckIn = b.CheckIn,
                    CheckOut = b.CheckOut,
                    Guests = b.Guests,
                    Status = b.Status,
                    GuestName = b.GuestName,
                    GuestEmail = b.GuestEmail,
                    GuestPhone = b.GuestPhone,
                    TotalAmount = b.TotalAmount
                })
                .FirstOrDefaultAsync();

            if (item == null)
            {
                TempData["Error"] = "Booking not found.";
                return RedirectToAction(nameof(Index));
            }

            return View(item);
        }
    }
}