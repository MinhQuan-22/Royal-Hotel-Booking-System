using ROYALHOTEL.Models;
using ROYALHOTEL.ViewModels.Booking;

namespace ROYALHOTEL.Services.Booking;

public interface IBookingService
{
    Task<Models.Booking> CreateBookingAsync(CreateBookingRequest request, int? accountId = null);
    Task<Models.Booking?> GetBookingByIdAsync(int bookingId);
    Task<Models.Booking?> GetBookingByCodeAsync(string bookingCode);
    Task<ConfirmPaymentResult> ConfirmPaymentAsync(int bookingId, string paymentMethod);
    Task<List<Models.Booking>> GetBookingsByAccountIdAsync(int accountId);
    Task<(bool Success, string Message)> CancelBookingAsync(int bookingId, int accountId, bool isAdmin = false);
}
