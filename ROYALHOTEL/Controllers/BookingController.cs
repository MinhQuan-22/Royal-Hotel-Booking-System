using Microsoft.AspNetCore.Mvc;
using ROYALHOTEL.Services.Booking;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Controllers
{
    public class BookingController : Controller
    {
        private readonly IBookingService _bookingService;

        private const string S_USER_ID = "USER_ID";
        private const string S_USER_ROLE = "USER_ROLE";

        public BookingController(IBookingService bookingService)
        {
            _bookingService = bookingService;
        }

        private int? GetCurrentUserId()
        {
            return HttpContext.Session.GetInt32(S_USER_ID);
        }

        private bool IsAdmin()
        {
            var role = HttpContext.Session.GetString(S_USER_ROLE);
            return string.Equals(role, "admin", StringComparison.OrdinalIgnoreCase);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreateBookingRequest request)
        {
            if (!ModelState.IsValid)
            {
                TempData["DetailErrorMessage"] = "Thông tin đặt phòng không hợp lệ.";
                return RedirectToAction("Detail", "Rooms", new
                {
                    id = request.RoomId,
                    checkIn = request.CheckInDate.ToString("yyyy-MM-dd"),
                    checkOut = request.CheckOutDate.ToString("yyyy-MM-dd"),
                    guests = request.Guests
                });
            }

            try
            {
                var currentUserId = GetCurrentUserId();
                var booking = await _bookingService.CreateBookingAsync(request, currentUserId);

                return RedirectToAction(nameof(Payment), new { bookingId = booking.Id });
            }
            catch (Exception ex)
            {
                TempData["DetailErrorMessage"] = ex.Message;
                return RedirectToAction("Detail", "Rooms", new
                {
                    id = request.RoomId,
                    checkIn = request.CheckInDate.ToString("yyyy-MM-dd"),
                    checkOut = request.CheckOutDate.ToString("yyyy-MM-dd"),
                    guests = request.Guests
                });
            }
        }

        [HttpGet]
        public async Task<IActionResult> Payment(int bookingId)
        {
            var booking = await _bookingService.GetBookingByIdAsync(bookingId);

            if (booking == null)
            {
                TempData["ErrorMessage"] = "Booking không tồn tại hoặc đã không còn hợp lệ.";
                return RedirectToAction(nameof(MyBookings));
            }

            if (string.Equals(booking.Status, "Confirmed", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction(nameof(Success), new { code = booking.BookingCode });
            }

            ViewData["PaymentLocked"] = false;
            return View(booking);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Pay(int bookingId, string paymentMethod)
        {
            if (bookingId <= 0 || string.IsNullOrWhiteSpace(paymentMethod))
            {
                TempData["PaymentErrorMessage"] = "Thông tin thanh toán không hợp lệ.";
                return RedirectToAction(nameof(Payment), new { bookingId });
            }

            // Lấy booking hiện tại trước khi xử lý để:
            // 1) xử lý double-click
            // 2) vẫn render lại đúng trang Payment nếu bị conflict
            var currentBooking = await _bookingService.GetBookingByIdAsync(bookingId);

            if (currentBooking == null)
            {
                TempData["ErrorMessage"] = "Booking không tồn tại hoặc đã không còn hợp lệ.";
                return RedirectToAction(nameof(MyBookings));
            }

            // Nếu request trước đã thành công, request sau chỉ đi tới Success
            if (string.Equals(currentBooking.Status, "Confirmed", StringComparison.OrdinalIgnoreCase))
            {
                return RedirectToAction(nameof(Success), new { code = currentBooking.BookingCode });
            }

            var success = await _bookingService.ConfirmPaymentAsync(bookingId, paymentMethod);

            if (!success)
            {
                // Check lại sau khi xử lý
                var bookingAfterProcess = await _bookingService.GetBookingByIdAsync(bookingId);

                // Nếu booking còn và đã Confirmed, nghĩa là request trước đã thành công
                if (bookingAfterProcess != null &&
                    string.Equals(bookingAfterProcess.Status, "Confirmed", StringComparison.OrdinalIgnoreCase))
                {
                    return RedirectToAction(nameof(Success), new { code = bookingAfterProcess.BookingCode });
                }

                // Nếu booking đã bị xóa vì conflict:
                // render lại ngay trang Payment với snapshot booking cũ + khóa nút thanh toán
                ViewData["PaymentErrorMessage"] =
                    "Phòng này đã được khách khác đặt trong khoảng thời gian anh chọn. Vui lòng chọn lại phòng hoặc ngày khác.";
                ViewData["PaymentLocked"] = true;

                return View("Payment", currentBooking);
            }

            var booking = await _bookingService.GetBookingByIdAsync(bookingId);

            if (booking == null)
            {
                TempData["ErrorMessage"] = "Booking không còn tồn tại sau khi xử lý thanh toán.";
                return RedirectToAction(nameof(MyBookings));
            }

            return RedirectToAction(nameof(Success), new { code = booking.BookingCode });
        }

        [HttpGet]
        public async Task<IActionResult> Success(string? code, string? bookingCode)
        {
            var finalCode = !string.IsNullOrWhiteSpace(code) ? code : bookingCode;

            if (string.IsNullOrWhiteSpace(finalCode))
                return NotFound();

            var booking = await _bookingService.GetBookingByCodeAsync(finalCode);

            if (booking == null)
                return NotFound();

            return View(booking);
        }

        [HttpGet]
        public async Task<IActionResult> MyBookings()
        {
            var userId = GetCurrentUserId();
            if (userId == null)
            {
                TempData["ErrorMessage"] = "Vui lòng đăng nhập để xem lịch sử đặt phòng.";
                return RedirectToAction("Login", "Account");
            }

            var bookings = await _bookingService.GetBookingsByAccountIdAsync(userId.Value);
            return View(bookings);
        }

        [HttpGet]
        public async Task<IActionResult> BookingDetail(string? bookingCode, string? code)
        {
            var finalCode = !string.IsNullOrWhiteSpace(bookingCode) ? bookingCode : code;

            if (string.IsNullOrWhiteSpace(finalCode))
                return NotFound();

            var booking = await _bookingService.GetBookingByCodeAsync(finalCode);

            if (booking == null)
                return NotFound();

            var userId = GetCurrentUserId();
            var isAdmin = IsAdmin();

            if (!isAdmin)
            {
                if (userId == null)
                {
                    TempData["ErrorMessage"] = "Vui lòng đăng nhập để xem booking.";
                    return RedirectToAction("Login", "Account");
                }

                if (booking.AccountId != userId)
                {
                    TempData["ErrorMessage"] = "Bạn không có quyền xem booking này.";
                    return RedirectToAction(nameof(MyBookings));
                }
            }

            return View("Success", booking);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Cancel(int bookingId)
        {
            var userId = GetCurrentUserId();
            if (userId == null)
            {
                TempData["ErrorMessage"] = "Vui lòng đăng nhập.";
                return RedirectToAction("Login", "Account");
            }

            var isAdmin = IsAdmin();
            var (success, message) = await _bookingService.CancelBookingAsync(bookingId, userId.Value, isAdmin);

            if (success)
            {
                TempData["SuccessMessage"] = message;
            }
            else
            {
                TempData["ErrorMessage"] = message;
            }

            return RedirectToAction(nameof(MyBookings));
        }
    }
}