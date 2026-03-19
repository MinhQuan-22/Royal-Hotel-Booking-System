namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Event data: Chứa thông tin về booking đã được confirmed
/// </summary>
public class BookingConfirmedEvent
{
    public Models.Booking Booking { get; }

    public BookingConfirmedEvent(Models.Booking booking)
    {
        Booking = booking;
    }
}
