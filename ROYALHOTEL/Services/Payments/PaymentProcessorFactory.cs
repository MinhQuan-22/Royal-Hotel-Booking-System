using ROYALHOTEL.Models;

namespace ROYALHOTEL.Services.Payments;

public abstract class PaymentProcessorFactory
{
    // Factory Method
    public abstract IPaymentProcessor CreatePaymentProcessor();

    // Business method dùng product được tạo ra
    public virtual Task<PaymentTransaction> ProcessAsync(Models.Booking booking)
    {
        var processor = CreatePaymentProcessor();
        return processor.ProcessAsync(booking);
    }
}