namespace ROYALHOTEL.Services.Booking;

public sealed class ConfirmPaymentResult
{
    public bool Success { get; init; }
    public int? ErrorCode { get; init; }
    public string Message { get; init; } = string.Empty;
}
