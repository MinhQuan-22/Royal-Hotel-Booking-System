namespace ROYALHOTEL.ViewModels
{
    public class AdminBookingDetailViewModel
    {
        public int Id { get; set; }

        public string BookingCode { get; set; } = string.Empty;

        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string RoomCode { get; set; } = string.Empty;
        public string? CoverImageUrl { get; set; }

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }
        public int Guests { get; set; }

        public string Status { get; set; } = string.Empty;

        public string? GuestName { get; set; }
        public string? GuestEmail { get; set; }
        public string? GuestPhone { get; set; }

        public decimal? TotalAmount { get; set; }

        public int Nights
        {
            get
            {
                var nights = (CheckOut - CheckIn).Days;
                return nights <= 0 ? 1 : nights;
            }
        }

        // --- Added Payment INFO & Refund Tracking ---
        public string? PaymentMethod { get; set; }
        public string? PaymentTransactionCode { get; set; }
        public string? RefundTransactionCode { get; set; }
        public DateTime? CancelledAt { get; set; }
        public string? CancelReason { get; set; }
        public string? CancelNote { get; set; }
        public string? RefundPolicyApplied { get; set; }
        public decimal? RefundAmount { get; set; }
        public string? RefundStatus { get; set; }
        public DateTime? RefundProcessedAt { get; set; }
    }
}