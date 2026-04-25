using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

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

    public virtual Task<ConfirmPaymentResult> ConfirmPaymentAsync(int bookingId, string paymentMethod)
        => _inner.ConfirmPaymentAsync(bookingId, paymentMethod);

    public virtual Task<List<Models.Booking>> GetBookingsByAccountIdAsync(int accountId)
        => _inner.GetBookingsByAccountIdAsync(accountId);

    public virtual Task<(bool Success, string Message)> CancelBookingAsync(int bookingId, int accountId, bool isAdmin = false, string? reason = null, string? note = null)
        => _inner.CancelBookingAsync(bookingId, accountId, isAdmin, reason, note);
}
