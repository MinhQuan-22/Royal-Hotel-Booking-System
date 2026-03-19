namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Observer Pattern: Concrete Subject/Publisher
/// Nhận danh sách observers và notify tất cả khi có sự kiện
/// </summary>
public class BookingEventPublisher : IBookingEventPublisher
{
    private readonly IEnumerable<IBookingEventObserver> _observers;

    public BookingEventPublisher(IEnumerable<IBookingEventObserver> observers)
    {
        _observers = observers;
    }

    public async Task PublishBookingConfirmedAsync(BookingConfirmedEvent evt)
    {
        // Notify tất cả observers
        // Mỗi observer được try/catch riêng để 1 observer fail không ảnh hưởng các observer khác
        foreach (var observer in _observers)
        {
            try
            {
                await observer.HandleBookingConfirmedAsync(evt);
            }
            catch (Exception ex)
            {
                // Log warning nhưng tiếp tục notify các observer còn lại
                Console.WriteLine($"[WARNING] Observer {observer.GetType().Name} failed: {ex.Message}");
            }
        }
    }
}
