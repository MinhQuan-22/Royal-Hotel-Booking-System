namespace ROYALHOTEL.Services.Payments;

public class VisaPaymentFactory : PaymentProcessorFactory
{
    public override IPaymentProcessor CreatePaymentProcessor()
    {
        return new VisaProcessor();
    }
}