using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Commands.Bookings;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Data;
using ROYALHOTEL.ViewModels;

namespace ROYALHOTEL.Controllers
{
    public class AdminBookingsController : Controller
    {
        private readonly RoyalHotelDbContext _context;
        private readonly IAdminCommandDispatcher _dispatcher;

        public AdminBookingsController(RoyalHotelDbContext context, IAdminCommandDispatcher dispatcher)
        {
            _context = context;
            _dispatcher = dispatcher;
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
                    CoverImageUrl = r.CoverImageUrl,
                    PaymentMethod = b.PaymentMethod,
                    RefundAmount = b.RefundAmount,
                    RefundStatus = b.RefundStatus
                };

            if (!string.IsNullOrWhiteSpace(keyword))
            {
                query = query.Where(x =>
                    x.BookingCode.Contains(keyword) ||
                    (x.RoomName != null && x.RoomName.Contains(keyword)) ||
                    (x.RoomCode != null && x.RoomCode.Contains(keyword)) ||
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

        [HttpGet]
        public async Task<IActionResult> Detail(int id)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            var booking = await _context.Bookings
                .Include(b => b.Room)
                .Include(b => b.PaymentTransactions)
                .FirstOrDefaultAsync(b => b.Id == id);

            if (booking == null)
            {
                TempData["Error"] = "Booking not found.";
                return RedirectToAction(nameof(Index));
            }

            var paymentTxn = booking.PaymentTransactions.FirstOrDefault(t => t.TransactionType == "Payment" && t.Status == "Paid");
            var refundTxn = booking.PaymentTransactions.FirstOrDefault(t => t.TransactionType == "Refund" && t.Status == "Paid");

            var detail = new AdminBookingDetailViewModel
            {
                Id = booking.Id,
                BookingCode = booking.BookingCode,
                RoomId = booking.RoomId,
                RoomName = booking.Room?.Name ?? "",
                RoomCode = booking.Room?.Code ?? "",
                CoverImageUrl = booking.Room?.CoverImageUrl,
                CheckIn = booking.CheckIn,
                CheckOut = booking.CheckOut,
                Guests = booking.Guests,
                Status = booking.Status,
                GuestName = booking.GuestName,
                GuestEmail = booking.GuestEmail,
                GuestPhone = booking.GuestPhone,
                TotalAmount = booking.TotalAmount,
                PaymentMethod = booking.PaymentMethod,
                PaymentTransactionCode = paymentTxn?.TransactionCode,
                RefundTransactionCode = refundTxn?.TransactionCode,
                CancelledAt = booking.CancelledAt,
                CancelReason = booking.CancelReason,
                CancelNote = booking.CancelNote,
                RefundPolicyApplied = booking.RefundPolicyApplied,
                RefundAmount = booking.RefundAmount,
                RefundStatus = booking.RefundStatus,
                RefundProcessedAt = booking.RefundProcessedAt
            };

            return View(detail);
        }

// action to update booking status, only for admin users
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(int id, string status)
        {
            if (!IsAdmin())
            {
                return RedirectToAction("Login", "Account");
            }

            AdminCommandResult result = status switch
            {
                "Confirmed" => await _dispatcher.DispatchAsync(new ConfirmBookingCommand { BookingId = id }),
                "CheckedIn" => await _dispatcher.DispatchAsync(new CheckInBookingCommand { BookingId = id }),
                "CheckedOut" => await _dispatcher.DispatchAsync(new CheckOutBookingCommand { BookingId = id }),
                "Completed" => await _dispatcher.DispatchAsync(new CompleteBookingCommand { BookingId = id }),
                "Cancelled" => await _dispatcher.DispatchAsync(new CancelBookingCommand { BookingId = id }),
                _ => AdminCommandResult.Fail("Invalid status.")
            };

            if (result.Success)
            {
                TempData["Success"] = result.Message;
            }
            else
            {
                TempData["Error"] = result.Message;
            }

            return RedirectToAction(nameof(Detail), new { id = id });
        }
    }
}