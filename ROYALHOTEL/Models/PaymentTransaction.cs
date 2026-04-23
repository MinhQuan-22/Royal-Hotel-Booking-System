namespace ROYALHOTEL.Models;

public class PaymentTransaction
{
    public int Id { get; set; }

    public int BookingId { get; set; }
    public Booking? Booking { get; set; }

    // bank_transfer / card
    public string PaymentMethod { get; set; } = "";

    // Số tiền thanh toán cho giao dịch này
    public decimal Amount { get; set; }

    // Paid / Failed
    public string Status { get; set; } = "Paid";

    // Mã giao dịch mô phỏng, ví dụ: TXN-20260309-001
    public string? TransactionCode { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // --- REFUND LEDGER ---
    public string TransactionType { get; set; } = "Payment"; // Payment hoặc Refund
    public int? ParentTransactionId { get; set; }
    public PaymentTransaction? ParentTransaction { get; set; }
    public string? Note { get; set; }
    public DateTime? ProcessedAt { get; set; }
}