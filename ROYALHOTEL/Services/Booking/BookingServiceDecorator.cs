using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

/// <summary>
/// Abstract Decorator:
/// giữ tham chiếu tới một IBookingService khác và forward toàn bộ lời gọi.
/// Các concrete decorator sẽ kế thừa lớp này để bổ sung hành vi cần thiết.
/// </summary>
public abstract class BookingServiceDecorator : IBookingService
{
    protected readonly IBookingService _inner;

    protected BookingServiceDecorator(IBookingService inner)
    {
        _inner = inner;
    }

    public virtual Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null)
        => _inner.CreateBookingAsync(request, accountId);

    public virtual Task<Models.Booking?> GetBookingByIdAsync(int bookingId)
        => _inner.GetBookingByIdAsync(bookingId);

    public virtual Task<Models.Booking?> GetBookingByCodeAsync(string bookingCode)
        => _inner.GetBookingByCodeAsync(bookingCode);

    public virtual Task<bool> ConfirmPaymentAsync(int bookingId, string paymentMethod)
        => _inner.ConfirmPaymentAsync(bookingId, paymentMethod);

    public virtual Task<List<Models.Booking>> GetBookingsByAccountIdAsync(int accountId)
        => _inner.GetBookingsByAccountIdAsync(accountId);

    public virtual Task<(bool Success, string Message)> CancelBookingAsync(int bookingId, int accountId, bool isAdmin = false)
        => _inner.CancelBookingAsync(bookingId, accountId, isAdmin);
}