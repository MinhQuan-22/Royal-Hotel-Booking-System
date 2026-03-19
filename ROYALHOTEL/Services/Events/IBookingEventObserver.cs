namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Observer Pattern: Observer interface
/// Các class implement interface này sẽ được notify khi có sự kiện booking
/// </summary>
public interface IBookingEventObserver
{
    Task HandleBookingConfirmedAsync(BookingConfirmedEvent evt);
}
