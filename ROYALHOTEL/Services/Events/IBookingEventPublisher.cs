namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Observer Pattern: Subject/Publisher interface
/// Phát sự kiện đến tất cả observers đã đăng ký
/// </summary>
public interface IBookingEventPublisher
{
    Task PublishBookingConfirmedAsync(BookingConfirmedEvent evt);
}
