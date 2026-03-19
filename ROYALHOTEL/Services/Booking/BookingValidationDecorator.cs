using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

/// <summary>
/// Decorator Pattern: Wraps IBookingService to add validation logic
/// before delegating to the core booking service.
/// </summary>
public class BookingValidationDecorator : IBookingService
{
    private readonly IBookingService _inner;
    private readonly RoyalHotelDbContext _context;

    public BookingValidationDecorator(IBookingService inner, RoyalHotelDbContext context)
    {
        _inner = inner;
        _context = context;
    }

    public async Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null)
    {
        // Validation 1: Room exists and is active
        var room = await _context.Rooms
            .FirstOrDefaultAsync(r => r.Id == request.RoomId && r.IsActive);

        if (room == null)
            throw new InvalidOperationException("Phòng không tồn tại hoặc đang không hoạt động.");

        // Validation 2: CheckOutDate > CheckInDate
        if (request.CheckOutDate <= request.CheckInDate)
            throw new InvalidOperationException("Ngày trả phòng phải sau ngày nhận phòng.");

        // Validation 3: Guests validation (> 0 and <= MaxGuests)
        if (request.Guests <= 0 || request.Guests > room.MaxGuests)
            throw new InvalidOperationException($"Số khách không hợp lệ. Phòng này tối đa {room.MaxGuests} khách.");

        // Validation 4: Overlap check with Confirmed/CheckedIn bookings
        var hasConfirmedOverlap = await _context.Bookings.AnyAsync(b =>
            b.RoomId == request.RoomId &&
            (b.Status == "Confirmed" || b.Status == "CheckedIn") &&
            request.CheckInDate < b.CheckOut &&
            request.CheckOutDate > b.CheckIn);

        if (hasConfirmedOverlap)
            throw new InvalidOperationException("Phòng này đã được đặt trong khoảng thời gian anh chọn.");

        // All validations passed, delegate to core service
        return await _inner.CreateBookingAsync(request, accountId);
    }

    // Forward all other methods to inner service
    public Task<Models.Booking?> GetBookingByIdAsync(int bookingId)
        => _inner.GetBookingByIdAsync(bookingId);

    public Task<Models.Booking?> GetBookingByCodeAsync(string bookingCode)
        => _inner.GetBookingByCodeAsync(bookingCode);

    public Task<bool> ConfirmPaymentAsync(int bookingId, string paymentMethod)
        => _inner.ConfirmPaymentAsync(bookingId, paymentMethod);

    public Task<List<Models.Booking>> GetBookingsByAccountIdAsync(int accountId)
        => _inner.GetBookingsByAccountIdAsync(accountId);

    public Task<(bool Success, string Message)> CancelBookingAsync(int bookingId, int accountId, bool isAdmin = false)
        => _inner.CancelBookingAsync(bookingId, accountId, isAdmin);
}
