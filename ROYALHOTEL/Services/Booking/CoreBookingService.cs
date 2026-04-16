using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;
using ROYALHOTEL.Services.Events;
using ROYALHOTEL.Services.Rooms;
using System.Data;
using Microsoft.Data.SqlClient;

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
            .AsNoTracking()
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.Id == bookingId);
    }

    public async Task<Models.Booking?> GetBookingByCodeAsync(string bookingCode)
    {
        return await _context.Bookings
            .AsNoTracking()
            .Include(b => b.Room)
            .Include(b => b.PaymentTransactions)
            .FirstOrDefaultAsync(b => b.BookingCode == bookingCode);
    }

    public async Task<ConfirmPaymentResult> ConfirmPaymentAsync(int bookingId, string paymentMethod)
    {
        if (bookingId <= 0)
        {
            return new ConfirmPaymentResult
            {
                Success = false,
                Message = "Booking không hợp lệ."
            };
        }

        if (string.IsNullOrWhiteSpace(paymentMethod))
        {
            return new ConfirmPaymentResult
            {
                Success = false,
                Message = "Phương thức thanh toán không hợp lệ."
            };
        }

        try
        {
            var connection = (SqlConnection)_context.Database.GetDbConnection();

            if (connection.State != ConnectionState.Open)
            {
                await connection.OpenAsync();
            }

            await using var command = new SqlCommand("sp_ConfirmBooking", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.Add(new SqlParameter("@BookingId", SqlDbType.Int)
            {
                Value = bookingId
            });

            command.Parameters.Add(new SqlParameter("@PaymentMethod", SqlDbType.NVarChar, 50)
            {
                Value = paymentMethod
            });

            await command.ExecuteNonQueryAsync();

            _context.ChangeTracker.Clear();

            // Load lại booking mới nhất sau khi SQL xử lý xong
            var booking = await _context.Bookings
                .AsNoTracking()
                .Include(b => b.Room)
                .Include(b => b.PaymentTransactions)
                .FirstOrDefaultAsync(b => b.Id == bookingId);

            if (booking == null)
            {
                return new ConfirmPaymentResult
                {
                    Success = false,
                    Message = "Booking không còn tồn tại sau khi xử lý."
                };
            }

            // Publish event giữ nguyên behavior cũ
            try
            {
                var evt = new BookingConfirmedEvent(booking);
                await _bookingEventPublisher.PublishBookingConfirmedAsync(evt);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[WARNING] Không thể publish booking confirmed event {booking.BookingCode}: {ex.Message}");
            }

            return new ConfirmPaymentResult
            {
                Success = true,
                Message = "Thanh toán thành công. Booking đã được xác nhận."
            };
        }
        catch (SqlException ex)
        {
            return ex.Number switch
            {
                50010 => new ConfirmPaymentResult
                {
                    Success = false,
                    ErrorCode = ex.Number,
                    Message = "Booking không tồn tại."
                },
                50011 => new ConfirmPaymentResult
                {
                    Success = false,
                    ErrorCode = ex.Number,
                    Message = "Chỉ booking ở trạng thái Pending mới được xác nhận."
                },
                50012 => new ConfirmPaymentResult
                {
                    Success = false,
                    ErrorCode = ex.Number,
                    Message = "Phòng hiện không hoạt động hoặc không còn khả dụng."
                },
                50013 => new ConfirmPaymentResult
                {
                    Success = false,
                    ErrorCode = ex.Number,
                    Message = "Phòng này đã được khách khác xác nhận trong khoảng thời gian anh chọn."
                },
                50014 => new ConfirmPaymentResult
                {
                    Success = false,
                    ErrorCode = ex.Number,
                    Message = "Trạng thái booking đã thay đổi trong lúc xử lý."
                },
                _ => throw ex
            };
        }
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
            .AsNoTracking()
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