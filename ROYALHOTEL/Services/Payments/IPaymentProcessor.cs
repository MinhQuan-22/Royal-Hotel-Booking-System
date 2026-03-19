using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Payments;

public interface IPaymentProcessor
{
    Task<PaymentTransaction> ProcessAsync(Models.Booking booking);
}
