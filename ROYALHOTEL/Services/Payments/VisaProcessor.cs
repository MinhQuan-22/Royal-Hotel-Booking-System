using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Payments;

public class VisaProcessor : IPaymentProcessor
{
    public Task<PaymentTransaction> ProcessAsync(Models.Booking booking)
    {
        var transaction = new PaymentTransaction
        {
            BookingId = booking.Id,
            PaymentMethod = "visa",
            Amount = booking.TotalAmount ?? 0,
            Status = "Paid",
            TransactionCode = GenerateTransactionCode(),
            CreatedAt = DateTime.UtcNow
        };

        return Task.FromResult(transaction);
    }

    private string GenerateTransactionCode()
    {
        return $"VISA-{DateTime.Now:yyyyMMddHHmmss}";
    }
}
