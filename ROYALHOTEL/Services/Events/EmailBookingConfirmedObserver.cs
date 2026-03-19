using ROYALHOTEL.Services.Notifications;

namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Observer Pattern: Concrete Observer
/// Xử lý việc gửi email khi booking được confirmed
/// Tái sử dụng Adapter Pattern (IBookingNotificationService)
/// </summary>
public class EmailBookingConfirmedObserver : IBookingEventObserver
{
    private readonly IBookingNotificationService _bookingNotificationService;

    public EmailBookingConfirmedObserver(IBookingNotificationService bookingNotificationService)
    {
        _bookingNotificationService = bookingNotificationService;
    }

    public async Task HandleBookingConfirmedAsync(BookingConfirmedEvent evt)
    {
        // Observer nhận event và delegate việc gửi email cho Adapter
        await _bookingNotificationService.SendBookingConfirmationAsync(evt.Booking);
    }
}
