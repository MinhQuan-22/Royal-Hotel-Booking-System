namespace ROYALHOTEL.Services.Payments;

public static class PaymentProcessorFactory
{
    public static IPaymentProcessor Create(string paymentMethod)
    {
        return paymentMethod switch
        {
            "bank_transfer" => new BankTransferProcessor(),
            "card" => new VisaProcessor(),
            "visa" => new VisaProcessor(),
            _ => throw new ArgumentException($"Unsupported payment method: {paymentMethod}")
        };
    }
}