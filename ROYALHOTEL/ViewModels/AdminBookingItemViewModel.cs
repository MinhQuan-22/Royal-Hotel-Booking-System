namespace ROYALHOTEL.ViewModels
{
    public class AdminBookingItemViewModel
    {
        public int Id { get; set; }
        public string BookingCode { get; set; } = string.Empty;
        public int RoomId { get; set; }
        public string RoomName { get; set; } = string.Empty;
        public string RoomCode { get; set; } = string.Empty;

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }

        public int Guests { get; set; }
        public string Status { get; set; } = string.Empty;

        public string? GuestName { get; set; }
        public string? GuestEmail { get; set; }
        public string? GuestPhone { get; set; }

        public decimal? TotalAmount { get; set; }
        public string? CoverImageUrl { get; set; }

        public string? PaymentMethod { get; set; }
        public decimal? RefundAmount { get; set; }
        public string? RefundStatus { get; set; }
    }
}