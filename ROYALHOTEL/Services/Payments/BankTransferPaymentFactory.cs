namespace ROYALHOTEL.Services.Payments;

public class BankTransferPaymentFactory : PaymentProcessorFactory
{
    public override IPaymentProcessor CreatePaymentProcessor()
    {
        return new BankTransferProcessor();
    }
}