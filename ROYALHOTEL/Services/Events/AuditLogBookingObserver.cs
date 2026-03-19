namespace ROYALHOTEL.Services.Events;

/// <summary>
/// Observer Pattern: Concrete Observer
/// Ghi audit log khi booking được confirmed
/// </summary>
public class AuditLogBookingObserver : IBookingEventObserver
{
    public Task HandleBookingConfirmedAsync(BookingConfirmedEvent evt)
    {
        var booking = evt.Booking;
        
        // Ghi audit log
        Console.WriteLine("=== AUDIT LOG: BOOKING CONFIRMED ===");
        Console.WriteLine($"Booking Code: {booking.BookingCode}");
        Console.WriteLine($"Guest Email: {booking.GuestEmail ?? "N/A"}");
        Console.WriteLine($"Guest Name: {booking.GuestName ?? "N/A"}");
        Console.WriteLine($"Payment Method: {booking.PaymentMethod ?? "N/A"}");
        Console.WriteLine($"Total Amount: {booking.TotalAmount:N0} VNĐ");
        Console.WriteLine($"Confirmed Time: {DateTime.Now:dd/MM/yyyy HH:mm:ss}");
        Console.WriteLine($"Room: {booking.Room?.Name ?? "N/A"}");
        Console.WriteLine("====================================");
        
        return Task.CompletedTask;
    }
}
