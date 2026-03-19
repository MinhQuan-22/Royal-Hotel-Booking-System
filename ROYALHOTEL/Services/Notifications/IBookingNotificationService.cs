namespace ROYALHOTEL.Services.Notifications;

/// <summary>
/// Target interface: Nghiệp vụ notification cho booking
/// </summary>
public interface IBookingNotificationService
{
    Task SendBookingConfirmationAsync(Models.Booking booking);
}
