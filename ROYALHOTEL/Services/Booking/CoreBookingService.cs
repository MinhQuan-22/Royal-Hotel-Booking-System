using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;
using ROYALHOTEL.Services.Payments;
using ROYALHOTEL.Services.Events;
using ROYALHOTEL.Services.Rooms;

namespace ROYALHOTEL.Services.Booking;

public class CoreBookingService : IBookingService
{
    private readonly RoyalHotelDbContext _context;
    private readonly IBookingEventPublisher _bookingEventPublisher;
    private readonly RoomPricingService _roomPricingService;

    public CoreBookingService(
        RoyalHotelDbContext context,
        IBookingEventPublisher bookingEventPublisher,
        RoomPricingService roomPricingService)
    {
        _context = context;
        _bookingEventPublisher = bookingEventPublisher;
        _roomPricingService = roomPricingService;
    }

    public async Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null)
    {
        // Core logic only: calculate price, create booking record, save to DB
        var room = await _context.Rooms
            .FirstOrDefaultAsync(r => r.Id == request.RoomId);

        if (room == null)
            throw new InvalidOperationException("Phòng không tồn tại.");

        var pricingSummary = _roomPricingService.Calculate(
            room,
            request.CheckInDate,
            request.CheckOutDate);

        var pricePerNight = pricingSummary.DisplayPricePerNight;
        var totalAmount = pricingSummary.TotalAmount;

        var booking = new Models.Booking
        {
            BookingCode = await GenerateBookingCodeAsync(),
            RoomId = room.Id,
            CheckIn = request.CheckInDate,
            CheckOut = request.CheckOutDate,
            Guests = request.Guests,
            GuestName = request.GuestName?.Trim(),
            GuestEmail = request.GuestEmail?.Trim(),
            GuestPhone = request.GuestPhone?.Trim(),
            PricePerNight = pricePerNight,
            TotalAmount = totalAmount,
            Status = "Pending",
            AccountId = accountId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        return booking;
    }

    public async Task<Models.Booking?> GetBookingByIdAsync(int bookingId)
    {
        return await _context.Bookings
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.Id == bookingId);
    }

    public async Task<Models.Booking?> GetBookingByCodeAsync(string bookingCode)
    {
        return await _context.Bookings
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.BookingCode == bookingCode);
    }

    public async Task<bool> ConfirmPaymentAsync(int bookingId, string paymentMethod)
    {
        var booking = await _context.Bookings
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null)
            return false;

        if (booking.Status != "Pending")
            return false;

        // Chỉ tại thời điểm thanh toán mới chốt xem phòng còn trống không
        var hasConfirmedOverlap = await _context.Bookings.AnyAsync(b =>
            b.Id != booking.Id &&
            b.RoomId == booking.RoomId &&
            (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
            booking.CheckIn < b.CheckOut &&
            booking.CheckOut > b.CheckIn);

        // Nếu đã có người khác chốt trước thì booking Pending này không còn hợp lệ.
        // Xóa luôn để không xuất hiện trong lịch sử booking của khách và danh sách admin.
        if (hasConfirmedOverlap)
        {
            _context.Bookings.Remove(booking);
            await _context.SaveChangesAsync();
            return false;
        }

        // Factory Method Pattern: chọn Concrete Creator phù hợp
        var factory = CreatePaymentFactory(paymentMethod);
        var transaction = await factory.ProcessAsync(booking);

        // Nếu sau này có processor trả Failed thì không confirm booking
        if (!string.Equals(transaction.Status, "Paid", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        booking.PaymentMethod = paymentMethod;
        booking.Status = "Confirmed";

        _context.PaymentTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        // Observer Pattern: Publish event thay vì gọi trực tiếp email service
        // Publisher sẽ notify tất cả observers (email, audit log, etc.)
        try
        {
            var evt = new BookingConfirmedEvent(booking);
            await _bookingEventPublisher.PublishBookingConfirmedAsync(evt);
        }
        catch (Exception ex)
        {
            // Log error nhưng không làm fail payment
            Console.WriteLine($"[WARNING] Không thể publish booking confirmed event {booking.BookingCode}: {ex.Message}");
        }

        return true;
    }

    private PaymentProcessorFactory CreatePaymentFactory(string paymentMethod)
    {
        return paymentMethod switch
        {
            "bank_transfer" => new BankTransferPaymentFactory(),
            "card" => new VisaPaymentFactory(),
            "visa" => new VisaPaymentFactory(),
            _ => throw new ArgumentException($"Unsupported payment method: {paymentMethod}")
        };
    }

    private async Task<string> GenerateBookingCodeAsync()
    {
        var today = DateTime.Now.ToString("yyyyMMdd");
        var prefix = $"RH-{today}-";

        var todayCount = await _context.Bookings.CountAsync(b =>
            b.BookingCode.StartsWith(prefix));

        var nextNumber = todayCount + 1;
        return $"{prefix}{nextNumber:D3}";
    }

    public async Task<List<Models.Booking>> GetBookingsByAccountIdAsync(int accountId)
    {
        return await _context.Bookings
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .Where(b => b.AccountId == accountId)
            .OrderByDescending(b => b.CreatedAt)
            .ThenByDescending(b => b.Id)
            .ToListAsync();
    }

    public async Task<(bool Success, string Message)> CancelBookingAsync(int bookingId, int accountId, bool isAdmin = false)
    {
        var booking = await _context.Bookings
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.Id == bookingId);

        if (booking == null)
            return (false, "Booking không tồn tại.");

        // Check ownership
        if (!isAdmin && booking.AccountId != accountId)
            return (false, "Bạn không có quyền hủy booking này.");

        // Check status
        if (booking.Status == "CheckedIn" || booking.Status == "CheckedOut" || booking.Status == "Cancelled")
            return (false, $"Không thể hủy booking có trạng thái {booking.Status}.");

        // Update status
        booking.Status = "Cancelled";

        // Optionally mark payment transactions as cancelled
        foreach (var txn in booking.PaymentTransactions.Where(t => t.Status == "Paid"))
        {
            txn.Status = "Cancelled";
        }

        await _context.SaveChangesAsync();

        return (true, "Hủy booking thành công.");
    }
}